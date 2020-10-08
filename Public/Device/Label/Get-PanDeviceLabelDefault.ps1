function Get-PanDeviceLabelDefault {
   <#
   .SYNOPSIS
   Return the default label used by Get-PanDevice
   .DESCRIPTION
   Return the default label used by Get-PanDevice

   See Set-PanDeviceLabelDefault for details.
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   System.String
   .EXAMPLE
   PS> Get-PanDeviceLabelDefault
   #>
   [CmdletBinding()]
   param()

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if( [String]::IsNullOrEmpty($Global:PanDeviceLabelDefault) ) {
      Write-Debug ($MyInvocation.MyCommand.Name + ': $Global:PanDeviceLabelDefault null or empty. Session is default')
      return "session-$(Get-PanSessionGuid)"
   }
   else {
      return $Global:PanDeviceLabelDefault
   }

} # Function
