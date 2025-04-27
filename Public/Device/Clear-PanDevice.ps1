function Clear-PanDevice {
<#
.SYNOPSIS
Clear (remove) all PanDevice(s) from the PanDeviceDb, removes persistence across PowerShell sessions.
.DESCRIPTION
Clear (remove) all PanDevice(s) from the PanDeviceDb, removes persistence across PowerShell sessions.
.NOTES
.INPUTS
None
.OUTPUTS
None
.EXAMPLE
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
   param(
      [parameter(HelpMessage='Specify -Force to bypass confirmation.')]
      [Switch] $Force
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if($Force -or $PSCmdlet.ShouldProcess('PanDeviceDb', 'Clear (remove) all PanDevice')) {
      Get-PanDevice -All | Remove-PanDevice
   } # if Force -or ShouldProcess
} # Function
