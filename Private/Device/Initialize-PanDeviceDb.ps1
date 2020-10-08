function Initialize-PanDeviceDb {
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

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   # Initial import of the PanDeviceDb
   if(-not $Global:PanInitImportComplete) {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Performing initial import')
      $Global:PanInitImportComplete = $true
      Import-PanDeviceDb

   }
   if( [String]::IsNullOrEmpty($Global:PanDeviceDb) ) {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Initializing $Global:PanDeviceDb')
      # .NET Generic List provides under-the-hood efficiency during add/remove compared to PowerShell native arrays or ArrayList.
      $Global:PanDeviceDb = [System.Collections.Generic.List[PanDevice]]@()
   }
}
