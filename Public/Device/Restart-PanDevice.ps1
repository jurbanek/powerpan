function Restart-PanDevice {
   <#
   .SYNOPSIS
   Restart (reboot) a PanDevice.
   .DESCRIPTION
   Restart (reboot) a PanDevice.
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanResponse
   .EXAMPLE
   PS> Get-PanDevice '10.0.0.1' | Restart-PanDevice
   Prompts for confirmation
   .EXAMPLE
   PS> Get-PanDevice '10.0.0.1' | Restart-PanDevice -Force
   No prompt for confirmation
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
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # PAN operational command to restart
      $Cmd = '<request><restart><system></system></restart></request>'
   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         if($Force -or $PSCmdlet.ShouldProcess($DeviceCur.Name, 'request restart system')) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
            $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.Status)
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.Message)

            # Output $PanResponse for feedback
            $PanResponse
         } # if Force -or ShouldProcess
      } # foreach
   } # Process block

   End {
   } # End block
} # Function
