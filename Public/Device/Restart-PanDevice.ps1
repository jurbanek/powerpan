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
            Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0} Cmd: {1}' -f $DeviceCur.Name, $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               # No need for Write-Host since there is no error. Keep in Verbose stream.
               Write-Verbose ('Restart system success')
            }
            else {
               Write-Error ('Restart system failed. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
            # Send response to pipeline
            $Response
         } # if Force -or ShouldProcess
      } # foreach
   } # Process block

   End {
   } # End block
} # Function
