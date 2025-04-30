function Clear-PanDeviceLabelDefault {
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
PS> Clear-PanDeviceLabelDefault
#>
   [CmdletBinding()]
   param()

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   if( -not [String]::IsNullOrEmpty($Global:PanDeviceLabelDefault) ) {
      $Global:PanDeviceLabelDefault = $null
   }

} # Function
