function Select-PanDeviceVsysDefault {
   <#
   .SYNOPSIS
   Select default operational vsys for a PanDevice for use with cmdlets that operate on multiple vsys.
   .DESCRIPTION
   Changes to default operational vsys setting does not persist across PowerShell sessions. The setting is not saved to disk.
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   None
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) on which default operational vsys will be selected')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='Default operational vsys')]
      [String] $Vsys
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         $DeviceCur.VsysDefault = $PSBoundParameters.Vsys
      }
   } # Process block

   End {
   } # End block
} # Function
