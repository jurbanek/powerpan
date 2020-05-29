function Set-PanDefaultLabel{
   <#
   .SYNOPSIS
   Modify the default Label used by Get-PanDevice
   .DESCRIPTION
   Modify the default Label used by Get-PanDevice

   C:\PS> Set-PanDefaultLabel -Label 'PCI'
   C:\PS> Get-PanDevice

      is functionally the same as
   
   C:\PS> Get-PanDevice -Label 'PCI'
   
   If a default Label is not explicitly set, then the default Label defaults to PanDevice(s) created in the
   current PowerShell session.
   .NOTES
   .INPUTS
   .OUTPUTS
   .EXAMPLE
   C:\PS> Get-PanDevice

   By default, Get-PanDevice without additional parameters returns PanDevice(s) created in the current PowerShell
   session only.
   .EXAMPLE
   C:\PS> Set-PanDefaultLabel -Label 'PCI'
   C:\PS> Get-PanDevice

   Get-PanDevice would return all PanDevice(s) with the 'PCI' label, without having to specify the -Label parameter.
   .EXAMPLE
   C:\PS> Set-PanDefaultLabel -Label 'PCI','us-central'
   C:\PS> Get-PanDevice

   Get-PanDevice would return all PanDevice(s) with both 'PCI' and 'us-central' labels. Both labels must match.
   Multiple Label(s) (via array) is a logical AND match when selecting PanDevice(s)
   .EXAMPLE
   C:\PS> Set-PanDefaultLabel -Label $null
   C:\PS> Get-PanDevice

   Restores Get-PanDevice default behavior of returning PanDevice(s) created in the current PowerShell session only.
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='Label. Multiple Label(s) (array) is logical AND match')]
      [String[]] $Label
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   Set-Variable -Name 'PanDefaultLabel' -Value $Label -Scope 'Global'
} # Function