function Restart-PanDevice {
   <#
   .SYNOPSIS
   Restart (reboot) a PanDevice.
   .DESCRIPTION
   Restart (reboot) a PanDevice.
   .NOTES
   .INPUTS
   .OUTPUTS
   .EXAMPLE
   #>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) to be restarted.')]
      [PanDevice[]] $Device,
      [parameter(
         HelpMessage='Specify -Force to bypass confirmation.')]
      [Switch] $Force
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # PAN operational command to restart
      $Cmd = '<request><restart><system></system></restart></request>'
   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         if($Force -or $PSCmdlet.ShouldProcess($DeviceCur.Name, 'request restart system')) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
            # $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.response.status)
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.response.InnerXml)
         } # if Force -or ShouldProcess
      } # foreach
   } # Process block

   End {
   } # End block
} # Function