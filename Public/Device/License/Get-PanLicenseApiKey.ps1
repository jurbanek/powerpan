function Get-PanLicenseApiKey {
<#
.SYNOPSIS
Get current license API key stored on the PanDevice
.DESCRIPTION
License API key is commonly used on VM-Series to automatically remove VM-Series firewalls from the Customer Support Portal
when the VM-Series licenses are revoked on the VM-Series firewall itself.
.NOTES
.INPUTS
PowerPan.PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PSCustomObject
.EXAMPLE
PS> Get-PanLicenseApiKey -Device $Device
Returns license API key as SecureString (default).
.EXAMPLE
PS> Get-PanDevice -All | Get-PanLicenseApiKey -AsPlainText
Returns license API key (or multiple if multiple PanDevice via pipeline) as standard string.
#>
   [CmdletBinding(DefaultParameterSetName='AsSecureString')]
   param(
      [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='PanDevice against which stored license API key will be retrieved.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='AsPlainText',HelpMessage='LicenseApiKey visible as standard String, instead of default SecureString.')]
      [Switch] $AsPlainText
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         $Cmd = '<request><license><api-key><show></show></api-key></license></request>'
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Verbose ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $R.Status)
         Write-Verbose ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $R.Message)

         # Output custom object with PanDevice Name and LicenseApiKey
         if($R.Status -eq 'success') {
            $R.Response.result -Match "API key: (?<key>\S*)" | Out-Null
            $LicenseApiKey = $Matches['key']
            $LicenseApiKeySecure = ConvertTo-SecureString -String $LicenseApiKey -AsPlainText -Force

            # PanDevice Name and SecureString LicenseApiKey
            if($PSCmdlet.ParameterSetName -eq 'AsSecureString') {
               [PSCustomObject]@{
                  Device = $DeviceCur;
                  LicenseApiKey = $LicenseApiKeySecure
               }
            }
            # PanDevice Name and standard string LicenseApiKey
            elseif($PSCmdlet.ParameterSetName -eq 'AsPlainText') {
               [PSCustomObject]@{
                  Device = $DeviceCur;
                  LicenseApiKey = $LicenseApiKey
               }
            }
         }
         # No license API key returned or error, output custom object with PanDevice Name and null
         else {
            [PSCustomObject]@{
               Device = $DeviceCur;
               LicenseApiKey = $null
            }
         }
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
