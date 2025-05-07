function New-PanDevice {
<#
.SYNOPSIS
Creates a new PanDevice object and adds/persists to the PanDeviceDb.
.DESCRIPTION
Creates a new PanDevice object and adds/persists to the PanDeviceDb.
.NOTES
1) Specify a -Name and optional -Label. Labels are useful for providing more memorable names or groupings for devices.
2) Choose an authentication input type (recommend -Credential or -KeyCredential)
3) Specify -Keygen to generate an API key WHEN USING -Credential or -User/-Password
4) Optionally, specify -NoPersist to prevent saving to PanDeviceDb on-disk inventory file (can be desirable with scripting)

AUTHENTICATION
Regardless of how the PanDevice is created, the in-memory and on-disk secrets (password and API key) are stored encrypted.
In-memory as a SecureString. On-disk as a serialized SecureString that is only decryptable by the user account with which it was created.

Authentication metadata can be provided in several ways

Recommended for interactive:
-Credential
-KeyCredential

Recommended for automation/non-interactive
-Key, fed from environment variables (not hardcoded)
-User/-Password, fed from environment variables (not hardcoded)

The -Key, -User/-Password authentication input parameters are supported for insecure convenience. Generally not recommended except for
non-interactive use cases.

TYPE
-Type parameter is generally not required. Type is dynamically determined if -Keygen is specified
.INPUTS
None
.OUTPUTS
PanDevice or $false
.EXAMPLE
# Using PSCredential for username and password, most secure with no username or password visible on command-line, prompted for both.
New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen

# Using PSCredntial for username and password, pre-specify username "admin" on the command-line, prompted for password.
New-PanDevice -Name "fw.lab.local" -Credential "admin" -Keygen

# Specifying both username and password in plaintext. Not prompted for anything. Included for non-interactive support. Avoid where possible.
New-PanDevice -Name "fw.lab.local" -Username "admin" -Password "admin123" -Keygen
.EXAMPLE
# Using PSCredential for API key, most secure with no key visible on command-line, prompted instead. Username is ignored.
New-PanDevice -Name "acme-edge-fw1.acme.net" -KeyCredential $(Get-Credential) -Label "acme-edge-fw1","Azure"

# Or pre-populate the ignored username
New-PanDevice -Name "acme-edge-fw1.acme.net" -KeyCredential "throwaway" -Label "acme-edge-fw1","Azure"

# Specifying API key in plaintext. Not prompted for anything. Included for non-interactive support. Avoid where possible.
New-PanDevice -Name "acme-edge-fw1.acme.net" -Key "A1E2I3O4U5LONGAPIKEY" -Label "acme-edge-fw1","Azure"
.EXAMPLE
# Add some labels while creating
New-PanDevice -Name "acme-edge-fw1.acme.net" -Credential $(Get-Credential) -Label "acme-edge-fw1","Azure"
.EXAMPLE
# Non-interactive example for creating new PanDevice using environment variables and -NoPersist.
# -NoPersist avoids writing the PanDevice to disk for later use.
New-PanDevice -Name $Env:MYPANHOST -Key $Env:MYPANKEY -NoPersist
#>
   [CmdletBinding()]
   # OutputType of [PanDevice] fails given typing issues
   [OutputType([Bool])]
   param(
      [parameter(Mandatory=$true,Position=0,HelpMessage='Name or IP address of PAN device')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=1,ParameterSetName="UserPass",HelpMessage='Non-interactive: Username against which API key will be generated. To be stored as secure [PSCredential]')]
      [String] $Username,
      [parameter(Mandatory=$true,Position=2,ParameterSetName="UserPass",HelpMessage='Non-interactive: Password associated with Username against which API key will be generated. To be stored as secure [PSCredential]')]
      [String] $Password,
      [parameter(Mandatory=$true,Position=1,ParameterSetName="Credential",HelpMessage='Interactive: PowerShell [PSCredential] against which API key will be generated')]
      # "Credential Attribute" to be able to pre-specify a username, like -Credential "John" and be prompted securely for only a password
      # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-5.1#attributes-of-parameters
      [System.Management.Automation.Credential()]
      [PSCredential] $Credential,
      [parameter(ParameterSetName="UserPass",HelpMessage='When specifying -Username and -Password, use this switch parameter to generate an API key')]
      [parameter(ParameterSetName="Credential",HelpMessage='When specifying -Credential, use this switch parameter to generate an API key')]
      [Switch] $Keygen,
      [parameter(Mandatory=$true,Position=1,ParameterSetName="Key",HelpMessage='Non-interactive: Pre-generated API key. To be stored as [SecureString]')]
      [String] $Key,
      [parameter(Mandatory=$true,Position=1,ParameterSetName="KeyCredential",HelpMessage='Interactive: Pre-generated API key. To be stored as [SecureString]. Username portion of PSCredential is ignored.')]
      [System.Management.Automation.Credential()]
      [PSCredential] $KeyCredential,
      [parameter(HelpMessage='PowerPAN locally significant label(s) to facilitate session-ease, friendly name, and grouping')]
      [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@(),
      [parameter(HelpMessage='Default is to disable x.509 certificate validation. Use this switch parameter to enable x.509 certificate validation')]
      [Switch] $ValidateCertificate = $false,
      [parameter(HelpMessage='Default is "https". Choose "http" or "https"')]
      [ValidatePattern("http|https")]
      [String] $Protocol = "https",
      [parameter(HelpMessage='Default is 443. Choose 1 - 65535')]
      [ValidateRange(1,65535)]
      [Int] $Port = 443,
      [parameter(HelpMessage='Ngfw (default) or Panorama')]
      [PanDeviceType] $Type = [PanDeviceType]::Ngfw,
      [parameter(HelpMessage='Default is to persist created PanDevice across PowerShell sessions. Switch parameter to NOT persist across sessions. Commonly enabled with scripts.')]
      [Switch] $NoPersist = $false,
      [parameter(HelpMessage='Internal module use only. Use this switch parameter during unserializing to prevent adding session-specific Label.')]
      [Switch] $ImportMode = $false
   )

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   # Update -Label parameter based on -ImportMode parameter
   if($ImportMode.IsPresent) {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': ImportMode: Not adding session-based Label')
   }
   else {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': Adding session-based Label')
      $Label.Add("session-$(GetPanSessionGuid)")
   }

   # Key parameter set :: -Key parameter present. API key previously generated, does not need to be created.
   # KeyCredential parameter set :: -KeyCredential parameter present. API key previously generated, does not need to be created.
   # For KeyCredential, ignore the Username portion of the PSCredential.
   if($PSCmdlet.ParameterSetName -eq 'Key' -or $PSCmdlet.ParameterSetName -eq 'KeyCredential') {
      if($PSCmdlet.ParameterSetName -eq 'Key') {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Key parameter set')
         # Convert plaintext key to [SecureString] immediately and $null out original.
         $SecureKey = ConvertTo-SecureString -String $Key -AsPlainText -Force
         $Key = $null
      }
      elseif($PSCmdlet.ParameterSetName -eq 'KeyCredential') {
         # With KeyCredential, the PSCredential.Password representing API key is already a [SecureString].
         $SecureKey = $KeyCredential.Password
      }
      # Create PanDevice
      $D = [PanDevice]::New($Name, $SecureKey, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port, $Type)
   }

   # UserPass or Credential parameter set, optional -Keygen parameter valid for both parameter sets
   elseif($PSCmdlet.ParameterSetName -eq 'UserPass' -or $PSCmdlet.ParameterSetName -eq 'Credential') {

      # UserPass parameter set :: -Username and -Password
      if($PSCmdlet.ParameterSetName -eq 'UserPass') {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': UserPass parameter set')
         # Convert password to [SecureString] immediately and $null out plaintext password variable
         $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
         $Password = $null
         # Build PSCredential from $UserName and $SecurePassword
         $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
         # Create base PanDevice object
         $D = [PanDevice]::New($Name, $Credential, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port, $Type)
      }
      # Credential parameter set :: -Credential
      elseif($PSCmdlet.ParameterSetName -eq 'Credential') {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Credential parameter set')
         # Create base PanDevice object
         $D = [PanDevice]::New($Name, $Credential, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port, $Type)
      }

      # Optionally generate API key
      if($Keygen.IsPresent) {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': -Keygen: Generating API key')
         $R = Invoke-PanXApi -Device $D -Keygen

         if($R.Status -eq 'success'){
            Write-Verbose ($MyInvocation.MyCommand.Name + ': -Keygen: API key generation successful')
            $D.Key = ConvertTo-SecureString -String $R.Response.result.key -AsPlainText -Force

            # Test API key
            Write-Verbose ($MyInvocation.MyCommand.Name + ': -Keygen: Testing generated API key')
            $R = Invoke-PanXApi -Device $D -Op -Cmd '<show><system><info></info></system></show>'
            if($R.Status -eq 'success'){
               Write-Verbose ($MyInvocation.MyCommand.Name + ': Keygen: Generated API key tested successfully')
               Write-Verbose ("`t DeviceName: {0} Family: {1} Model: {2}" -f $R.Response.result.system.devicename,$R.Response.result.system.family,$R.Response.result.system.model)
               if($R.Response.result.system.family -eq 'vm') {
                  Write-Verbose ("`t VM-License: {0} VM-Mode: {1}" -f $R.Response.result.system.'vm-license',$R.Response.result.system.'vm-mode')
               }
               Write-Verbose ("`t Serial: {0} Software Version: {1}" -f $R.Response.result.system.serial,$R.Response.result.system.'sw-version')
               if($R.Response.result.system.model -eq 'Panorama') {
                  Write-Verbose ("`t PanDeviceType: {0} (Panorama)" -f [PanDeviceType]::Panorama)
                  $D.Type = [PanDeviceType]::Panorama
               }
               else {
                  Write-Verbose ("`t PanDeviceType: {0} (Ngfw)" -f [PanDeviceType]::Ngfw)
                  $D.Type = [PanDeviceType]::Ngfw
               }
            }
            else { 
               Write-Error ('Error testing generated API key. Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
               return $false
            }
         }
         else {
            Write-Error ('Error generating API key. Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
            return $false 
         }
      } # End optional generate API key
   } # End UserPass / Credential parameter set

   # Specify Persist(ence)
   $D.Persist = -not $PSBoundParameters.NoPersist.IsPresent
   
   # Add to PanDeviceDb first (to ensure PanDeviceDb is initialized), then update the Device's Location(s)
   Add-PanDevice -Device $D -ImportMode:$PSBoundParameters.ImportMode.IsPresent
   # Update Location(s)
   Update-PanDeviceLocation -Device $D -ImportMode:$PSBoundParameters.ImportMode.IsPresent
   # Send to pipeline (but also available via Get-PanDevice)
   return $D
} # End New-PanDevice
