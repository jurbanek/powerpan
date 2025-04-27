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
      [parameter(Mandatory=$true,ParameterSetName='Device',Position=0,ValueFromPipeline=$true,HelpMessage='PanDevice(s) to be tested')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Filter',Position=0,HelpMessage='Name of PanDevice(s) to be tested')]
      [String[]] $Name
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      InitializePanDeviceDb

   } # Begin block

   Process {
      if($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Invoke-PanXApi -Device $DeviceCur -Version
         }
      } # end ParameterSetName
      
      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         foreach($NameCur in $PSBoundParameters.Name) {
            $TargetDevice = Get-PanDevice -Name $NameCur
            if($TargetDevice) {
               Invoke-PanXApi -Device $TargetDevice -Version
            }
            else {
               Write-Error ('Device Name: {0} Not Found' -f $NameCur)
            }
         }
      } # end ParameterSetName
   } # Process block

   End {
   } # End block
} # Function
