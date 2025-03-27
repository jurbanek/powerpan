function Add-PanDeviceLabel {
<#
.SYNOPSIS
Add label(s) to a PanDevice in PanDeviceDb.
.DESCRIPTION
Add label(s) to a PanDevice in PanDeviceDb.
.NOTES
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
None
.EXAMPLE
#>
   [CmdletBinding()]
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
      Write-Debug ($MyInvocation.MyCommand.Name + ':')# If -Debug parameter, change to 'Continue' instead of 'Inquire'

      # Initialize PanDeviceDb
      InitializePanDeviceDb

      # If dirty after process block, serialize necessary
      $Dirty = $false

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         foreach($LabelCur in $Label) {
            # No existing label(s). Just add.
            if($DeviceCur.Label.Count -eq 0) {
               $DeviceCur.Label.Add($LabelCur) | Out-Null
               $Dirty = $true
            }
            # Only add unique label(s). Do not add a duplicate.
            else {
               # Cannot use Contains() as we desire a case-insensitive match. Another loop required.
               $Match = $false
               foreach($DeviceCurLabelCur in $DeviceCur.Label) {
                  if($LabelCur -imatch ('^' + $DeviceCurLabelCur + '$')) {
                     $Match = $true
                     break
                  }
               }
               if(-not $Match) {
                  $DeviceCur.Label.Add($LabelCur) | Out-Null
                  $Dirty = $true
               }
            }
         } # foreach $LabelCur in $Label
      } # foreach $DeviceCur
   } # Process block

   End {
      if($Dirty) {
         ExportPanDeviceDb
      }
   } # End block
} # Function
