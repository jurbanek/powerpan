function Clear-PanLicenseApiKey {
   <#
   .SYNOPSIS
   Clear (remove) current license API key stored on the PanDevice
   .DESCRIPTION
   License API key is commonly used on VM-Series to automatically remove VM-Series firewalls from the Customer Support Portal
   when the VM-Series licenses are revoked on the VM-Series firewall itself.
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanResponse
   .EXAMPLE
   PS> Clear-PanLicenseApiKey -Device $Device
   .EXAMPLE
   PS> Get-PanDevice -All | Clear-PanLicenseApiKey
   #>
   [CmdletBinding(DefaultParameterSetName='AsSecureString')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which stored license API key will be retrieved.')]
      [PanDevice[]] $Device
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         $Cmd = '<request><license><api-key><delete></delete></api-key></license></request>'
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $R.Status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $R.Message)

         # Output $R for feedback
         $R
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
