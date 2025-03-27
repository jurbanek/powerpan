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

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if(Test-Path -Path Variable:PanSessionGuid) {
      return $Global:PanSessionGuid
   }
   else {
      Write-Debug ($MyInvocation.MyCommand.Name + ': $Global:PanSessionGuid not found. Creating' )
      New-Variable -Name 'PanSessionGuid' -Value $(New-Guid).ToString() -Scope 'Global' -Option Constant
      return $Global:PanSessionGuid
   }
} # Function
