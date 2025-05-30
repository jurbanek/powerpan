function Set-PanDeviceLabelDefault{
<#
.SYNOPSIS
Modify the default Label used by Get-PanDevice
.DESCRIPTION
Modify the default Label used by Get-PanDevice

PS> Set-PanDeviceLabelDefault -Label 'PCI'
PS> Get-PanDevice

   is functionally the same as

PS> Get-PanDevice -Label 'PCI'

If a default Label is not explicitly set, then the default Label defaults to PanDevice(s) created in the
current PowerShell session.
.NOTES
.INPUTS
None
.OUTPUTS
None
.EXAMPLE
PS> Get-PanDevice

By default, Get-PanDevice without additional parameters returns PanDevice(s) created in the current PowerShell
session only.
.EXAMPLE
PS> Set-PanDeviceLabelDefault -Label 'PCI'
PS> Get-PanDevice

Get-PanDevice would return all PanDevice(s) with the 'PCI' label, without having to specify the -Label parameter.
.EXAMPLE
PS> Set-PanDeviceLabelDefault -Label 'PCI','us-central'
PS> Get-PanDevice

Get-PanDevice would return all PanDevice(s) with both 'PCI' and 'us-central' labels. Both labels must match.
Multiple Label(s) (via array) is a logical AND match when selecting PanDevice(s)
.EXAMPLE
PS> Set-PanDeviceLabelDefault -Label $null
PS> Get-PanDevice

Restores Get-PanDevice default behavior of returning PanDevice(s) created in the current PowerShell session only.
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
   param(
      [parameter(Mandatory=$true,Position=0,HelpMessage='Label. Multiple Label(s) (array) is logical AND match')]
      [String[]] $Label
   )

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   if($PSCmdlet.ShouldProcess('PanDeviceDb','Change Get-PanDevice default label(s) to ' + $($PSBoundParameters.Label -join ','))) {
      Set-Variable -Name 'PanDeviceLabelDefault' -Value $PSBoundParameters.Label -Scope 'Global'
   }
} # Function
