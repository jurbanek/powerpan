function Remove-PanDeviceLabel {
<#
.SYNOPSIS
Remove label(s) from a PanDevice in PanDeviceDb.
.DESCRIPTION
Remove label(s) from a PanDevice in PanDeviceDb.
.NOTES
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
None
.EXAMPLE
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) to which label operation will be applied')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$false,
         HelpMessage='Label')]
      [String[]] $Label
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      InitializePanDeviceDb

      # If dirty after process block, serialize necessary
      $Dirty = $false

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         if($DeviceCur.Label.Count -eq 0) {
            # No labels on this device. Nothing to do.
            continue
         }
         else {
            # Iterate through each Label parameter
            foreach($LabelCur in $Label) {
               # Iterate through each Label in the current Device
               foreach($DeviceCurLabelCur in $DeviceCur.Label) {
                  # Case-insensitive match (we can't just use Contains())
                  if($LabelCur -imatch ('^' + $DeviceCurLabelCur + '$')) {
                     if($PSCmdlet.ShouldProcess('PanDeviceDb','Remove ' + $DeviceCurLabelCur + ' label from ' + $DeviceCur.Name)) {
                        $DeviceCur.Label.Remove($DeviceCurLabelCur) | Out-Null
                        $Dirty = $true
                        break
                     }
                  }
               }
            }
         }
      } # foreach $Devicecur
   } # Process block

   End {
      if($Dirty) {
         ExportPanDeviceDb
      }
   } # End block
} # Function
