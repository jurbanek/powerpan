function Get-PanLicenseApiKey{
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
   Get-PanLicenseApiKey -Device $Device

   Returns license API key as SecureString (default).
   .EXAMPLE
   Get-PanDevice -All | Get-PanLicenseApiKey -AsPlainText

   Returns license API key (or multiple if multiple PanDevice via pipeline) as standard string.
   #>
   [CmdletBinding(DefaultParameterSetName='AsSecureString')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which stored license API key will be retrieved.')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$true,
         ParameterSetName='AsPlainText',
         HelpMessage='LicenseApiKey visible as standard String, instead of default SecureString.')]
      [Switch] $AsPlainText
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         $Cmd = '<request><license><api-key><show></show></api-key></license></request>'
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.response.status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.response.InnerXml)

         # Output custom object with PanDevice Name and LicenseApiKey
         if($PanResponse.response.status -eq 'success') {
            $PanResponse.response.result -match "API key: (?<key>\S*)" | Out-Null
            $LicenseApiKey = $Matches['key']
            $LicenseApiKeySecure = ConvertTo-SecureString -String $LicenseApiKey -AsPlainText -Force

            # PanDevice Name and SecureString LicenseApiKey 
            if($PSCmdlet.ParameterSetName -eq 'AsSecureString') {
               [PSCustomObject]@{
                  Name = $DeviceCur.Name;
                  LicenseApiKey = $LicenseApiKeySecure
               }
            }
            # PanDevice Name and standard string LicenseApiKey
            elseif($PSCmdlet.ParameterSetName -eq 'AsPlainText') {
               [PSCustomObject]@{
                  Name = $DeviceCur.Name;
                  LicenseApiKey = $LicenseApiKey
               }
            }
         }
         # No license API key returned or error, output custom object with PanDevice Name and null
         else {
            [PSCustomObject]@{
               Name = $DeviceCur.Name;
               LicenseApiKey = $null
            }
         }
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function