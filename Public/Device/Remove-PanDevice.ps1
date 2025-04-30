function Remove-PanDevice {
<#
.SYNOPSIS
Remove a PanDevice from the PanDeviceDb, removes persistence across PowerShell sessions.
.DESCRIPTION
Remove a PanDevice from the PanDeviceDb, removes persistence across PowerShell sessions.
.NOTES
.INPUTS
PanDevice
.OUTPUTS
None
.EXAMPLE
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low',DefaultParameterSetName='Empty')]
   param(
      [parameter(Mandatory=$true,Position=0,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice(s) to be removed from PanDeviceDb.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$false,Position=0,ParameterSetName='Filter',HelpMessage='Case-insensitive exact match for Name. Multiple Name is logical OR match')]
      [String[]] $Name,
      [parameter(Mandatory=$false,ParameterSetName='Filter',HelpMessage='Switch parameter for PanDevice created in CURRENT PowerShell session')]
      [Switch] $Session,
      [parameter(Mandatory=$false,ParameterSetName='Filter',HelpMessage='Case-insensitive exact match for Label. Multiple Label is logical AND match')]
      [String[]] $Label
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

      # Initialize PanDeviceDb
      InitializePanDeviceDb
      # Fetch PanSessionGuid to be used throughout function. Avoids littering Debug logs with excessive calls to GetPanSessionGuid
      $SessionGuid = GetPanSessionGuid
      $DeviceAgg = @()
   } # Begin block

   Process {
      # If PanDeviceDb is NOT populated, there will be nothing to remove.
      if( $Global:PanDeviceDb.Count -eq 0 ) {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': PanDeviceDb empty')
      }

      # ParameterSetName 'Device'
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Device ParameterSetName')
         # Iterate through each PanDevice in $Device argument to confirm the PanDevice is in PanDeviceDb
         # Use cases can arise where PanDevice's are created that don't live in PanDeviceDb. If one of these is passed in for removal
         # from PanDeviceDb, we will silently ignore it
         # Almost always $DeviceAgg will become identical to $Device, except in the use case defined above
         foreach($DeviceCur in $Device) {
            if($DeviceCur.Name -in $Global:PanDeviceDb.Name) {
               $DeviceAgg += $DeviceCur
               Write-Verbose ($MyInvocation.MyCommand.Name + ': ' + $DeviceCur.Name + ' queued for removal')
            }
            else {
               Write-Verbose ($MyInvocation.MyCommand.Name + ': ' + $DeviceCur.Name + ' not found in PanDeviceDb. Ignoring')
            }
         }
      } # elseif ParameterSetName 'Device'

      # ParameterSetName 'Filter'
      # -Session, -Label, -Name can be used to filter individually or together/simultaneously
      #
      # Multiple -Label (via array) is a logical AND hit (all) with NO regular expression support.
      # Multiple -Name (via array) is a logical OR hit (at least one) with regular expression support.
      #
      # When -Session, -Label, -Name are used together, specific behavior (above) still applies, but each in use must hit.
      # Simultaneous use is logical AND (all) for a hit.
      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Filter ParameterSetName')
         # Iterate through each PanDevice in PanDeviceDb
         foreach($DeviceCur in $Global:PanDeviceDb) {
            # Prime the Verdict
            $Verdict = $true
            # If Session filter is enabled and no session match, current PanDevice is not a filter match, break outer loop immediately
            if($Session.IsPresent -and $DeviceCur.Label -notcontains "session-$SessionGuid") {
               $Verdict = $false
               continue
            }
            # If Label filter is enabled and every Label is not a match, current PanDevice is not a filter match, break outer loop immediately
            if(-not [String]::IsNullOrEmpty($Label)) {
               foreach($LabelCur in $Label) {
                  if($DeviceCur.Label -notcontains $LabelCur) {
                     $Verdict = $false
                     break
                  }
               }
               if(-not $Verdict) {
                  continue
               }
            }
            # If Name filter is enabled and at least one Name is not a match, current PanDevice is not a filter match, break outer loop immediately
            if(-not [String]::IsNullOrEmpty($Name)) {
               $Verdict = $false
               foreach($NameCur in $Name) {
                  if($DeviceCur.Name -imatch "^$NameCur`$") {
                     $Verdict = $true
                  }
               }
               if(-not $Verdict) {
                  continue
               }
            }

            # Process the verdict
            if($Verdict) {
               $DeviceAgg += $DeviceCur
               Write-Verbose ($MyInvocation.MyCommand.Name + ': ' + $DeviceCur.Name + ' queued for removal')
            }
         }
      } # elseif ParameterSetName 'Filter'
   } # Process block

   End {
      if($DeviceAgg.Count -gt 0) {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Removing ' + $DeviceAgg.Count + ' from PanDeviceDb' )
         foreach($DeviceCur in $DeviceAgg) {
            if($PSCmdlet.ShouldProcess('PanDeviceDb','Remove ' + $DeviceCur.Name)) {
               # Return an array without the offender
               $Global:PanDeviceDb = $Global:PanDeviceDb | Where-Object {$_.Name -ne $DeviceCur.Name}
            }
         }
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Serializing')
         ExportPanDeviceDb
      }
   } # End block
} # Function
