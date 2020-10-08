function Get-PanSessionGuid {
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

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
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
