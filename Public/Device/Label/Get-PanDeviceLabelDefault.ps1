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
   [OutputType([String])]
   param()

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if( [String]::IsNullOrEmpty($Global:PanDeviceLabelDefault) ) {
      Write-Debug ($MyInvocation.MyCommand.Name + ': $Global:PanDeviceLabelDefault null or empty. Session is default')
      return "session-$(Get-PanSessionGuid)"
   }
   else {
      return $Global:PanDeviceLabelDefault
   }

} # Function
