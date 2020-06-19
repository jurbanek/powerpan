function New-PanDevice {
   <#
   .SYNOPSIS
      Creates a new PanDevice object and adds/persists to the PanDeviceDb.
   .DESCRIPTION
      Creates a new PanDevice object and adds/persists to the PanDeviceDb.
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   PanDevice or $false
   .EXAMPLE
   PS> New-PanDevice -Name "fw.lab.local" -Username "admin" -Password "admin123" -Keygen
   .EXAMPLE
   PS> New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen -Label "PCI-Zone-1"
   .EXAMPLE
   PS> New-PanDevice -Name "fw.lab.local" -Key "A1E2I3O4U5"
   .EXAMPLE
   PS> New-PanDevice -Name "acme-edge-fw1.acme.net" -Key "A1E2I3O4U5" -Label "acme-edge-fw1","Azure"
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='Name or IP address of PAN device')]
      [String] $Name,
      [parameter(
         Mandatory=$true,
         Position=1,
         ParameterSetName="UserPass",
         HelpMessage='Username against which API key will be generated. To be stored as secure [PSCredential]')]
      [String] $Username,
      [parameter(
         Mandatory=$true,
         Position=2,
         ParameterSetName="UserPass",
         HelpMessage='Password associated with Username against which API key will be generated. To be stored as secure [PSCredential]')]
      [String] $Password,
      [parameter(
         Mandatory=$true,
         Position=1,
         ParameterSetName="Credential",
         HelpMessage='PowerShell [PSCredential] against which API key will be generated')]
      [PSCredential] $Credential,
      [parameter(
         ParameterSetName="UserPass",
         HelpMessage='When specifying -Username and -Password, use this switch parameter to generate an API key')]
      [parameter(
         ParameterSetName="Credential",
         HelpMessage='When specifying -Credential, use this switch parameter to generate an API key')]
      [Switch] $Keygen,
      [parameter(
         Mandatory=$true,
         Position=1,
         ParameterSetName="Key",
         HelpMessage='Pre-generated API key. To be stored as [SecureString]')]
      [String] $Key,
      [parameter(
         HelpMessage='PowerPAN locally significant label(s) to facilitate session-ease, friendly name, and grouping')]
      [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@(),
      [parameter(
         HelpMessage='Default is to disable x.509 certificate validation. Use this switch parameter to enable x.509 certificate validation')]
      [Switch] $ValidateCertificate = $false,
      [parameter(
         HelpMessage='Default is "https". Choose "http" or "https"')]
      [ValidatePattern("http|https")]
      [String] $Protocol = "https",
      [parameter(
         HelpMessage='Default is 443. Choose 1 - 65535')]
      [ValidateRange(1,65535)]
      [Int] $Port = 443,
      [parameter(
         HelpMessage='Default is to persist created [PanDevice] to PanDeviceDb. Use this switch parameter to not add PanDevice to PanDeviceDb. Commonly enabled with scripts.')]
      [Switch] $NoPersist = $false,
      [parameter(
         HelpMessage='Internal module use only. Use this switch parameter during unserializing to prevent adding session-specific Label.')]
      [Switch] $ImportMode = $false
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   # Update -Label parameter based on -ImportMode parameter
   if($ImportMode.IsPresent) {
      Write-Debug ($MyInvocation.MyCommand.Name + ': ImportMode: Not adding session-based Label')
   }
   else {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Adding session-based Label')
      $Label.Add("session-$(Get-PanSessionGuid)")
   }
   
   # Key parameter set :: -Key parameter present. API key previously generated, does not need to be created.
   if($PSCmdlet.ParameterSetName -eq 'Key') {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Key parameter set')

      # Convert plaintext key to [SecureString] immediately and $null out original.
      $SecureKey = ConvertTo-SecureString -String $Key -AsPlainText -Force
      $Key = $null
      # Create object
      $Device = [PanDevice]::New($Name, $SecureKey, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port)

      # Completed building PanDevice within Key parameter set. Determine whether to add to PanDeviceDb.
      if($NoPersist.IsPresent) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': NoPersist: Not adding to PanDeviceDb')
         return $Device
      }
      else {
         # Determine whether to add to PanDeviceDb with -ImportMode
         if($ImportMode.IsPresent) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': ImportMode: Adding to PanDeviceDb')
            Add-PanDevice -Device $Device -ImportMode
         }
         else {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Adding to PanDeviceDb')
            Add-PanDevice -Device $Device
         }
         return $Device
      }
   } # End Key parameter set

   # UserPass or Credential parameter set, optional -Keygen parameter valid for both parameter sets
   elseif($PSCmdlet.ParameterSetName -eq 'UserPass' -or $PSCmdlet.ParameterSetName -eq 'Credential') {

      # UserPass parameter set :: -Username and -Password present
      if($PSCmdlet.ParameterSetName -eq 'UserPass') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': UserPass parameter set')
         # Convert password to [SecureString] immediately and $null out plaintext password variable
         $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
         $Password = $null

         # Build PSCredential from $UserName and $SecurePassword
         $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword

         # Create base PanDevice object
         $Device = [PanDevice]::New($Name, $Credential, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port)
      }
      # Credential parameter set :: -Credential present
      elseif($PSCmdlet.ParameterSetName -eq 'Credential') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Credential parameter set')

         # Create base PanDevice object
         $Device = [PanDevice]::New($Name, $Credential, $Label, $ValidateCertificate.IsPresent, $Protocol, $Port)
      }

      # Optionally generate API key
      if($Keygen.IsPresent) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Keygen: Generating API key')
         $PanResponse = Invoke-PanXApi -Device $Device -Keygen

         if($PanResponse.Status -eq 'success'){
            Write-Debug ($MyInvocation.MyCommand.Name + ': Keygen: API key generation successful')
            $Device.Key = ConvertTo-SecureString -String $PanResponse.Result.key -AsPlainText -Force

            Write-Debug ($MyInvocation.MyCommand.Name + ': Keygen: Testing generated API key')
            $PanResponse = Invoke-PanXApi -Device $Device -Op -Cmd '<show><system><info></info></system></show>'
            if($PanResponse.Status -eq 'success'){
               Write-Debug ($MyInvocation.MyCommand.Name + ': Keygen: Generated API key tested successfully')
               Write-Debug ("`t" + 'Device Name: ' + $PanResponse.Result.system.devicename)
               Write-Debug ("`t" + 'Family: ' + $PanResponse.Result.system.family)
               Write-Debug ("`t" + 'Model: ' + $PanResponse.Result.system.model)
               if($PanResponse.Result.system.family -eq 'vm') {
                  Write-Debug ("`t" + 'VM-License: ' + $PanResponse.Result.system.'vm-license')
                  Write-Debug ("`t" + 'VM-Mode: ' + $PanResponse.Result.system.'vm-mode')
               }
               Write-Debug ("`t" + 'Serial: ' + $PanResponse.Result.system.serial)
               Write-Debug ("`t" + 'Software Version: ' + $PanResponse.Result.system.'sw-version')
            }
            else { return $false }
         }
         else { return $false }
      }
      # Completed building PanDevice within UserPass or Credential parameter set. Determine whether to add to PanDeviceDb.
      if($NoPersist.IsPresent) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': NoPersist: Not adding to PanDeviceDb')
         return $Device
      }
      else {
         # Determine whether to add to PanDeviceDb with -ImportMode
         if($ImportMode.IsPresent) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': ImportMode: Adding to PanDeviceDb')
            Add-PanDevice -Device $Device -ImportMode
         }
         else {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Adding to PanDeviceDb')
            Add-PanDevice -Device $Device
         }
         return $Device
      }
   } # End UserPass / Credential parameter set
} # End New-PanDevice