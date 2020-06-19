function Clear-PanDefaultLabel {
   <#
   .SYNOPSIS
   PowerPAN function to clear (reset to default) the current default Label(s) for auto-selecting PanDevice(s) from the PanDeviceDb.
   .DESCRIPTION
   PowerPAN function to clear (reset to default) the current default Label(s) for auto-selecting PanDevice(s) from the PanDeviceDb.

   If a default Label is not explicitly set, then the default Label itself defaults to PanDevice(s) created in the
   current PowerShell session.
   .NOTES
   .INPUTS
   .OUTPUTS
   .EXAMPLE
   PS> Clear-PanDefaultLabel
   #>
   [CmdletBinding()]
   param()

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if( -not [String]::IsNullOrEmpty($Global:PanDefaultLabel) ) {
      $Global:PanDefaultLabel = $null
   }

} # Function