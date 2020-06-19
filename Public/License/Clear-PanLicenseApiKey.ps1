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
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         $Cmd = '<request><license><api-key><delete></delete></api-key></license></request>'
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.Status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.Message)

         # Output $PanResponse for feedback
         $PanResponse
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function 