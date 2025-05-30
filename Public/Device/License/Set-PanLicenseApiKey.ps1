function Set-PanLicenseApiKey {
<#
.SYNOPSIS
Set current license API key stored on the PanDevice
.DESCRIPTION
License API key is commonly used on VM-Series to automatically remove VM-Series firewalls from the Customer Support Portal
when the VM-Series licenses are revoked on the VM-Series firewall itself.
.NOTES
.INPUTS
PowerPan.PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanResponse
.EXAMPLE
PS> Set-PanLicenseApiKey -Device $Device -LicenseApiKey $SecureKey
Where $SecureKey is a SecureString
.EXAMPLE
PS> Get-PanDevice -All | Set-PanLicenseApiKey -LicenseApiKeyAsPlainText $StringKey
Where $StringKey is a standard string
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
   param(
      [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='PanDevice against which stored license API key will be set.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='AsSecureString',HelpMessage='SecureString license API key to apply to PanDevice.')]
      [SecureString] $LicenseApiKey,
      [parameter(Mandatory=$true,ParameterSetName='AsPlainText',HelpMessage='Plaintext string license API key to apply to PanDevice.')]
      [String] $LicenseApiKeyAsPlainText
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         # Note the {0} to be used with the -f format operator
         $Cmd = '<request><license><api-key><set><key>{0}</key></set></api-key></license></request>'

         if($PSCmdlet.ParameterSetName -eq 'AsSecureString') {
            # Barrel of fun turning the SecureString into a String
            $Cmd = $Cmd -f $(New-Object -TypeName PSCredential -ArgumentList 'user',$PSBoundParameters['LicenseApiKey']).GetNetworkCredential().Password
         }
         elseif($PSCmdlet.ParameterSetName -eq 'AsPlainText') {
            $Cmd = $Cmd -f $PSBoundParameters['LicenseApiKeyAsPlainText']
         }

         if($PSCmdlet.ShouldProcess($DeviceCur.Name,'Set PAN-OS Licensing API key ')) {
            Write-Verbose ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
            Write-Verbose ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
            $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

            Write-Verbose ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $R.Status)
            Write-Verbose ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $R.Message)
            
            # Output $R for feedback
            $R
         }
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
