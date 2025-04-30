function GetPanSessionGuid {
<#
.SYNOPSIS
PowerPAN private helper function to obtain the PanSessionGuid.
.DESCRIPTION
PowerPAN private helper function to obtain the PanSessionGuid.
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

   if(Test-Path -Path Variable:PanSessionGuid) {
      return $Global:PanSessionGuid
   }
   else {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': $Global:PanSessionGuid not found. Creating' )
      New-Variable -Name 'PanSessionGuid' -Value $(New-Guid).ToString() -Scope 'Global' -Option Constant
      return $Global:PanSessionGuid
   }
} # Function
