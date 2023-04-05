function Test-PanDevice {
   <#
   .SYNOPSIS
   Test the API accessibility of a PanDevice.
   .DESCRIPTION
   Test the API accessibility of a PanDevice.
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanResponse
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) to be tested')]
      [PanDevice[]] $Device
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters.Debug) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         Invoke-PanXApi -Device $DeviceCur -Version
      } # foreach
   } # Process block

   End {
   } # End block
} # Function
