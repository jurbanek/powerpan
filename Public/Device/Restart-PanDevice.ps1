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
      [parameter(Mandatory=$true,ParameterSetName='Device',Position=0,ValueFromPipeline=$true,HelpMessage='PanDevice(s) to be restarted.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Filter',Position=0,HelpMessage='Name of PanDevice(s) to be restarted.')]
      [String[]] $Name,
      [parameter(HelpMessage='Specify -Force to bypass confirmation.')]
      [Switch] $Force
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

      # PAN operational command to restart
      $Cmd = '<request><restart><system></system></restart></request>'
   } # Begin block

   Process {
      if($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            if($Force -or $PSCmdlet.ShouldProcess($DeviceCur.Name, 'request restart system')) {
               Write-Verbose ('{0}: Device: {1} Cmd: {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name, $Cmd)
               $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
               if($R.Status -eq 'success') {
                  Write-Verbose ('{0}: Device: {1} Restart system success' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
               }
               else {
                  Write-Error ('Device: {0} Restart system failed. Status: {1} Code: {2} Message: {3}' -f $DeviceCur.Name,$R.Status,$R.Code,$R.Message)
               }
               # Send response to pipeline
               $R
            } # if Force -or ShouldProcess
         } # foreach
      } # end ParameterSetName

      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         foreach($NameCur in $PSBoundParameters.Name) {
            $TargetDevice = Get-PanDevice -Name $NameCur
            if(-not $TargetDevice) {
               Write-Error ('{0}: Device Name: {1} Not Found' -f $MyInvocation.MyCommand.Name,$NameCur)
            }
            elseif($Force -or $PSCmdlet.ShouldProcess($TargetDevice.Name, 'request restart system')) {
               Write-Verbose ('{0}: Device: {1} Cmd: {2}' -f $MyInvocation.MyCommand.Name,$TargetDevice.Name,$Cmd)
               $R = Invoke-PanXApi -Device $TargetDevice -Op -Cmd $Cmd
               if($R.Status -eq 'success') {
                  Write-Verbose ('{0}: Device: {1} Restart system success' -f $MyInvocation.MyCommand.Name,$TargetDevice.Name)
               }
               else {
                  Write-Error ('Device: {0} Restart system failed. Status: {1} Code: {2} Message: {3}' -f $TargetDevice.Name,$R.Status,$R.Code,$R.Message)
               }
               # Send response to pipeline
               $R
            } # if Force -or ShouldProcess
         } # foreach
      }
   } # Process block

   End {
   } # End block
} # Function
