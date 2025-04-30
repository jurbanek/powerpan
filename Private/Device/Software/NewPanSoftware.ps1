function NewPanSoftware {
<#
.SYNOPSIS
Returns a PanSoftware object.
.DESCRIPTION
Returns a PanSoftware object.
.NOTES
.INPUTS
None
.OUTPUTS
PanSoftware
.EXAMPLE
.NOTES
See help for NewPanJob for time zone related context.
#>
    [CmdletBinding()]
    param(
       [parameter(Mandatory=$true,HelpMessage='PanResponse')]
       [PanResponse] $Response,
       [parameter(Mandatory=$true,HelpMessage='PanDevice')]
       [PanDevice] $Device,
       [parameter(Mandatory=$true,HelpMessage='Time zone name (tz database / tzdata format) of PanDevice. Ex. America/Chicago')]
        [String] $TimeZoneName
    )
 
    # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
    if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
    # Announce
    Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

    # Determine TimeZoneInfo from the passed TimeZoneName before main processing loop
    # Offset will be determined for each software given daylight savings impact
    # Use the internal ConvertFromPanTimeZone helper to accommodate cross-platform nuances
    $TimeZoneInfo = ConvertFromPanTimeZone -Name $PSBoundParameters.TimeZoneName
    # If it cannot be found, assume (likely incorrectly) UTC (it's a standard)
    if(-not $TimeZoneInfo) {
        $TimeZoneInfo = [TimeZoneInfo]::FindSystemTimeZoneById('UTC')
    }
 
    # Container for processed software items
    $SoftwareAgg = [System.Collections.Generic.List[PanSoftware]]@()

    foreach($EntryCur in $PSBoundParameters.Response.Response.result.'sw-updates'.versions.entry) {
        $SoftwareNew = [PanSoftware]::new()
        $SoftwareNew.Version = $EntryCur.version
        $SoftwareNew.Filename = $EntryCur.filename
        $SoftwareNew.Size = $EntryCur.size
  
        # Released
        # PAN-OS XML-API released-on return format example below, does not include timezone indicator
        # 2025/02/20 21:05:20
        # In firewall local time
        $Regex = '(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)'
        if($EntryCur.'released-on' -match $Regex) {
            # Calculate the offset for released-on to feed into future DateTimeOffset
            # Need a DateTime to assess whether DST is/was in effect at that DateTime
            $ReleasedDateTime = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
            # If DST in effect, offset is the time zone default offset + 1
            if($TimeZoneInfo.IsDaylightSavingTime($ReleasedDateTime)) {
                $DstModification = New-TimeSpan -Hours 1
                $Offset = $TimeZoneInfo.BaseUtcOffset.Add($DstModification)
            }
            # If DST NOT in effect, offset is the time zone default offset
            else {
                $Offset = $TimeZoneInfo.BaseUtcOffset
            }

            $SoftwareNew.Released = [DateTimeOffset]::new($ReleasedDateTime,$Offset)
        }
        
        $SoftwareNew.ReleaseNotes = $EntryCur.'release-notes'.'#cdata-section'
        $SoftwareNew.Downloaded = if($EntryCur.downloaded -eq 'yes') {$True} else {$False}
        $SoftwareNew.Uploaded = if($EntryCur.uploaded -eq 'yes') {$True} else {$False}
        $SoftwareNew.Current = if($EntryCur.current -eq 'yes') {$True} else {$False}
        $SoftwareNew.Latest = if($EntryCur.latest -eq 'yes') {$True} else {$False}
        $SoftwareNew.ReleaseType = $EntryCur.'release-type'
        $SoftwareNew.Sha256 = $EntryCur.sha256
        $SoftwareNew.Device = $PSBoundParameters.Device

        # Add to aggregate
        $SoftwareAgg.Add($SoftwareNew)
    }

    return $SoftwareAgg | Sort-Object -Property 'Version'
} # Function
 