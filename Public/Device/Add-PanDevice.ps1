function Add-PanDevice {
<#
.SYNOPSIS
Add a PanDevice to the PanDeviceDb, providing persistence across PowerShell sessions.
.DESCRIPTION
Add a PanDevice to the PanDeviceDb, providing persistence across PowerShell sessions.
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
      [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,HelpMessage='PanDevice(s) to be added to PanDeviceDb.')]
      [PanDevice[]] $Device,
      [parameter(HelpMessage='Internal module use only. Adds PanDevice(s) to PanDeviceDb, but does not [re]serialize.')]
      [Switch] $ImportMode
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      InitializePanDeviceDb

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         $i = 0
         $Match = $false
         # Iterate looking for existing match based on Name. Need to avoid duplicate entries
         while(($i -lt $Global:PanDeviceDb.Count) -and -not $Match) {
            if($Global:PanDeviceDb[$i].Name -imatch ('^' + $DeviceCur.Name + '$')) {
               # Case-insensitive match based on [PanDevice].Name, replace it in PanDeviceDb
               Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Device Name: $($DeviceCur.Name) match found at `$Global:PanDeviceDb[$i]. Replacing")
               $Global:PanDeviceDb[$i] = $DeviceCur
               # Given match, call off the search
               $Match = $true
            }
            $i++
         }
         # If no match after full search, no risk of duplicating, so append
         if(-not $Match) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Device Name: $($DeviceCur.Name) match not found. Appending")
            $Global:PanDeviceDb += $DeviceCur
         }
      }
   } # Process block

   End {
      # -ImportMode do not [re]serialize
      if($ImportMode.IsPresent) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': ImportMode: Not [re]serializing')
         return
      }
      # Default behavior is to serialize after updates to PanDeviceDb
      else {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Serializing')
         ExportPanDeviceDb
      }
   } # End block
} # Function
