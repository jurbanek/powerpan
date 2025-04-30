function Get-PanDevice {
<#
.SYNOPSIS
Retrieve PanDevice(s) from the PanDeviceDb
.DESCRIPTION
Retrieve PanDevice(s) from the PanDeviceDb
.NOTES
Multiple -Label (via array) is a logical AND match with NO regular expression support.
Multiple -Name (via array) is a logical OR match with regular expression support.

When -Session, -Label, -Name are used together, specific parameter AND/OR match behavior
still applies, but each parameter in use must match (AND across all in use parameters)
.INPUTS
None
.OUTPUTS
PanDevice[]
.EXAMPLE
Get-PanDevice -Name "firewall-01.acme.local"

Returns PanDevice with case-insensitive match on -Name
.EXAMPLE
Get-PanDevice -Name "firewall-01.acme.local","firewall-02.acme.local"

Returns PanDevice with case-insensitive match on -Name.
Multiple -Name (via array) are logical OR match to facilitate precise multi-select based on PanDevice Name.
For more complex match logic use Get-PanDevice -All | Where-Object ...
.EXAMPLE
Get-PanDevice -Session

Returns PanDevice(s) created in current PowerShell session.
.EXAMPLE
Get-PanDevice -Label "east-us-1","PCI"

Returns PanDevice(s) with "east-us-1" AND "PCI" Labels. Multiple -Label (via array) are an AND match.
For more complex match logic use Get-PanDevice -All | Where-Object ...
.EXAMPLE
Get-PanDevice -All

Returns all PanDevice(s) within the PanDeviceDb.
Complex match criteria can be crafted using Get-PanDevice -All | Where-Object ...
.EXAMPLE
Get-PanDevice -Session -Name "firewall-01.acme.local"

Matches -Session AND -Name parameters, both parameters must result in match.
.EXAMPLE
Get-PanDevice -Name "firewall-01.acme.local" -Label "PCI"

Matches -Name AND -Label parameters, both parameters must result in match.
.EXAMPLE
Get-PanDevice

With no parameters, returns the "default" PanDevice(s) based on $Global:PanDeviceLabelDefault.
If $Global:PanDeviceLabelDefault is empty, returns PanDevice(s) created in current PowerShell session.
#>
   [CmdletBinding(DefaultParameterSetName='Empty')]
   param(
      [parameter(Position=0,Mandatory=$false,ParameterSetName='Filter',HelpMessage='Case-insensitive exact match for Name. Multiple Name is logical OR match')]
      [String[]] $Name,
      [parameter(Mandatory=$false,ParameterSetName='Filter',HelpMessage='Switch parameter for PanDevice created in CURRENT PowerShell session')]
      [Switch] $Session,
      [parameter(Mandatory=$false,ParameterSetName='Filter',HelpMessage='Case-insensitive exact match for Label. Multiple Label is logical AND match')]
      [String[]] $Label,
      [parameter(Mandatory=$true,ParameterSetName='All',HelpMessage='Switch parameter for ALL PanDevice')]
      [Switch] $All
   )

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   # Initialize PanDeviceDb
   InitializePanDeviceDb

   # Fetch PanSessionGuid to be used throughout function. Avoids littering Debug logs with excessive calls to GetPanSessionGuid
   $SessionGuid = GetPanSessionGuid
   # Fetch PanDeviceLabelDefault to be used throughout function. Avoids littering Debug logs with excessive calls to Get-PanDeviceLabelDefaul
   $LabelDefault = Get-PanDeviceLabelDefault

   # If the PanDeviceDb is NOT populated, no need to continue evaluating ParameterSets, answer is always empty
   if([String]::IsNullOrEmpty($Global:PanDeviceDb)) {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': PanDeviceDb empty')
      $DeviceAgg = @()
   }

   # ParameterSetName 'Empty'
   # Peference (most to least) is PanDeviceLabelDefault, then session- label.
   elseif($PSCmdlet.ParameterSetName -eq 'Empty') {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': Empty ParameterSetName')
      $DeviceAgg = @()

      # If PanDeviceLabelDefault is only the session- label (see function calls above to populate these variables), then there are no PanDeviceLabelDefault(s)
      # Send back only the session- matches. More common scenario and thus evaluated first.
      if($LabelDefault -eq "session-$SessionGuid") {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': No PanDeviceLabelDefault(s) found. Using session-' + $SessionGuid )
         foreach($DeviceCur in ($Global:PanDeviceDb | Where-Object { $_.Label -contains "session-$SessionGuid"})) {
            $DeviceAgg += $DeviceCur
         }
      }
      # PanDeviceLabelDefault has content
      else {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Using PanDeviceLabelDefault(s)')

         # For each PanDevice, prime Verdict as $true. Iterate through PanDeviceLabelDefault(s) and look for matches one at a time.
         # If no match, $Verdict becomes false and the PanDevice will not be added to the aggregate to be returned.
         # If all PanDeviceLabelDefault(s) are found, $Verdict stays $true and PanDevice will be added to aggregate to be returned.
         foreach($DeviceCur in $Global:PanDeviceDb) {
            $Verdict = $true
            foreach($LabelCur in $LabelDefault) {
               if($DeviceCur.Label -notcontains $LabelCur) {
                  $Verdict = $false
                  break
               }
            }
            if($Verdict) {
               $DeviceAgg += $DeviceCur
            }
         } # foreach $DeviceCur
      }
   } # elseif ParameterSetName 'Empty'

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
      $DeviceAgg = @()
      # Iterate through each PanDevice in PanDeviceDb
      foreach($DeviceCur in $Global:PanDeviceDb) {
         # Prime the Verdict
         $Verdict = $true
         # If Session filter is enabled and no session match, current PanDevice is not a filter match, break outer loop immediately
         if($PSBoundParameters.Session.IsPresent -and $DeviceCur.Label -notcontains "session-$SessionGuid") {
            $Verdict = $false
            continue
         }
         # If Label filter is enabled and every Label is not a match, current PanDevice is not a filter match, break outer loop immediately
         if(-not [String]::IsNullOrEmpty($PSBoundParameters.Label)) {
            foreach($LabelCur in $PSBoundParameters.Label) {
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
         if(-not [String]::IsNullOrEmpty($PSBoundParameters.Name)) {
            $Verdict = $false
            foreach($NameCur in $PSBoundParameters.Name) {
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
         }
      }
   } # ParameterSetName 'Filter'

   # ParameterSetName 'All'
   elseif($PSCmdlet.ParameterSetName -eq 'All') {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': All ParameterSetName')
      $DeviceAgg = $Global:PanDeviceDb
   } # ParameterSetName 'All'

   return $DeviceAgg
} # Function
