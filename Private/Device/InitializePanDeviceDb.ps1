function InitializePanDeviceDb {
<#
.SYNOPSIS
PowerPAN private helper function to initialize the PanDeviceDb.
.DESCRIPTION
PowerPAN private helper function to initialize the PanDeviceDb.
.NOTES
.INPUTS
.OUTPUTS
.EXAMPLE
#>
   [CmdletBinding()]
   param(
   )

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   # Initial import of the PanDeviceDb
   if(-not $Global:PanInitImportComplete) {
      Write-Verbose ('{0}: Performing initial import' -f $MyInvocation.MyCommand.Name)
      $Global:PanInitImportComplete = $true
      ImportPanDeviceDb
      # Setting the refresh interval for refreshing locations on individual devices
      $Global:PanDeviceLocRefSec = 900
   }
   if( [String]::IsNullOrEmpty($Global:PanDeviceDb) ) {
      Write-Verbose ('{0}: Initializing $Global:PanDeviceDb' -f $MyInvocation.MyCommand.Name)
      $Global:PanDeviceDb = @()
   }
}
