function NewPanJob {
<#
.SYNOPSIS
Creates and returns PanJob object(s) from a PanResponse.
.DESCRIPTION
Creates and returns PanJob object(s) from a PanResponse.
.NOTES
.INPUTS
None
.OUTPUTS
PanJob
.EXAMPLE
.NOTES
Note on PanJob use of DateTimeOffset (instead of DateTime) and TimeZoneInfo

PAN-OS XML-API returns job enqueue/dequeue/finish times in the firewall's local time without a time zone or offset in the string. "2025/03/24 18:00:13"
PAN-OS "show clock" via API or CLI includes the time zone short string like "CST" or "CDT", the latter if DST is in effect. Not good enough.
PAN-OS "tz database" format name, kept in deviceconfig/system/timezone uses IANA style (like "America/Chicago" suitable for lookup in standard "tz database")
PAN-OS does not return an offset from UTC (like -06:00:00) anywhere I can find, via API or CLI, across jobs or any other constructs.

Per world standards, when DST in effect for a time zone an hour is added to the offset.
America/Chicago without DST is -06:00:00. America/Chicago during DST is -05:00:00 (a "plus one" hour, minus six plus one is minus five)

PowerShell side
No .NET native "DateTime with Time Zone" type exists. Common .NET approach is to use DateTimeOffset with TimeZoneInfo, as needed.
DateTime objects do NOT have an internal time zone or offset defined, but do have a "Kind" property to indicate whether Local or UTC. Not good enough.
DateTimeOffset objects also do NOT have an internal time zone, but DO have a TimeSpan property to capture an offset (from UTC).
Construct a DateTimeOffset object with a DateTime and an offset (type TimeSpan) achieves the desired result. Optionally, store the TimeZoneInfo object.
Furthermore, there is a cross-platform challenge where PowerShell 5.1 only supports "Windows style" time zone names like "Central Standard Time".
PowerShell 6+ supports "Windows style" and IANA style like 'America/Chicago".

Putting it together
From XML-API job related time properties, parse and build a DateTime object (e.g. $JobDateTime) (which does not have Time Zone or offset)
From XML-API, GET the firewall's "tz database" format time zone name from deviceconfig/system/timezone
Map the "tz database" name to a TimeZoneInfo object
    For PowerShell 6+, using $TimeZoneInfo = [TimeZoneInfo]::FindSystemTimeZoneById('America/Chicago')
    For Powershell 5.1, using an external assembly TimeZoneConverter (via helper cmdlet) to map PAN-OS IANA style to closest Windows approximation.
        https://www.nuget.org/packages/TimeZoneConverter/
        https://github.com/mattjohnsonpint/TimeZoneConverter
The $TimeZoneInfo.BaseUtcOffset is a TimeSpan representing the offset from UTC
Call $TimeZoneInfo.IsDaylightSavingTime($JobDateTime) and determine if DST is/was in effect during that exact DateTime
    If DST, add one hour to the offset when constructing the DateTimeOffset object
Construct the DateTimeOffset from DateTime $JobDateTime and the correct offset (TimeSpan, which may or may not include adding one hour for DST)
Optionally, store the TimeZoneInfo object as well should ever want to display friendly name
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
 
    # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
    if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
    if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
    # Announce
    Write-Debug ($MyInvocation.MyCommand.Name + ':')

    # Determine TimeZoneInfo from the passed TimeZoneName before main processing loop
    # Offset will be determined for each software given daylight savings impact
    # Use the internal ConvertFromPanTimeZone helper to accommodate cross-platform nuances
    $TimeZoneInfo = ConvertFromPanTimeZone -Name $PSBoundParameters.TimeZoneName
    # If it cannot be found, assume (likely incorrectly) UTC (it's a standard)
    if(-not $TimeZoneInfo) {
        $TimeZoneInfo = [TimeZoneInfo]::FindSystemTimeZoneById('UTC')
    }

    # Container for processed job items
    $JobAgg = [System.Collections.Generic.List[PanJob]]@()

    foreach($ResponseJobCur in $PSBoundParameters.Response.Response.result.job) {
        $JobNew = [PanJob]::new()
        $JobNew.Id = $ResponseJobCur.id
        $JobNew.Type = $ResponseJobCur.type
        $JobNew.User = $ResponseJobCur.user
        $JobNew.Status = $ResponseJobCur.status
        $JobNew.Progress = $ResponseJobCur.progress
        $JobNew.Result = $ResponseJobCur.result
        $JobNew.Queued = $ResponseJobCur.queued
        $JobNew.PositionInQueue = $ResponseJobCur.positionInQ
        $JobNew.Stoppable = $ResponseJobCur.stoppable
        
        # PAN-OS XML-API queued return format example below, does not include timezone indicator
        # 2025/02/20 21:05:20
        # In firewall local time and does not include an offset or time zone information
        $QRegex = '(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)'
        $QRegexTimeOnly = '(\d+):(\d+):(\d+)'
        
        # Enqueue (and nested Dequeue)
        if($ResponseJobCur.tenq -match $QRegex) {
            # Calculate the offset for Enqueued to feed into future DateTimeOffset
            # Need a DateTime to assess whether DST is/was in effect at that DateTime
            $EnqDateTime = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
            # If DST in effect, offset is the time zone default offset + 1
            if($TimeZoneInfo.IsDaylightSavingTime($EnqDateTime)) {
                $DstModification = New-TimeSpan -Hours 1
                $Offset = $TimeZoneInfo.BaseUtcOffset.Add($DstModification)
            }
            # If DST NOT in effect, offset is the time zone default offset
            else {
                $Offset = $TimeZoneInfo.BaseUtcOffset
            }
            
            $JobNew.Enqueued = [System.DateTimeOffset]::new($EnqDateTime,$Offset)
        
            # Dequeued processing is kept within Enqueued if() block because of below.
            # XML-API is pretty silly.
            # tenq format is 2025/02/20 21:05:20
            # tdeq format is 21:05:20
            # There is no date portion in the dequeued value. Ridiculous. We want valid [DateTimeOffset] for both Enqueued and Dequeued.
            # Dequeuing is *likely* on the same day as Enqueueing. It's usually immediate or within a few minutes... but also need to verify.
            # Need to account for:
            # Enqueue 2025/02/20 23:59:58
            # Dequeue 00:00:02
            # Need to determine if crossing midnight. Can't just use the Enqueued date portion blindly when creating Dequeued DateTimeOffset.
            
            # Save the earlier Enqueued Y M D values from -matches before running a new -match against Dequeued
            $EnqYear = $Matches[1]
            $EnqMonth = $Matches[2]
            $EnqDay = $Matches[3]
            # Save the earlier H for determining if we have crossed a date bounday.
            $EnqHour = $Matches[4]
 
            # Run regex against Dequeued which contains time only
            if($ResponseJobCur.tdeq -match $QRegexTimeOnly) {
                # Matches[1] should now contain the Dequeued Hour. If Dequeued Hour less than Enqueued Hour we can have crossed into the next day.
                if($Matches[1] -lt $EnqHour) {
                    # Build the DateTime using Enqueued Y M D and Dequeued Hr Min Sec... then add a day.
                    $DeqDateTime = $([DateTime]::new($EnqYear,$EnqMonth,$EnqDay,$Matches[1],$Matches[2],$Matches[3],0,0)).AddDays(1)
                }
                # Have NOT crossed into next day. 
                else {
                    # Use the Enqueued Y M D and Dequeued Hr Min Sec. No need to add a day.
                    $DeqDateTime = [DateTime]::new($EnqYear,$EnqMonth,$EnqDay,$Matches[1],$Matches[2],$Matches[3],0,0)
                }

                # If DST in effect, offset is the time zone default offset + 1
                if($TimeZoneInfo.IsDaylightSavingTime($DeqDateTime)) {
                    $DstModification = New-TimeSpan -Hours 1
                    $Offset = $TimeZoneInfo.BaseUtcOffset.Add($DstModification)
                }
                # If DST NOT in effect, offset is the time zone default offset
                else {
                    $Offset = $TimeZoneInfo.BaseUtcOffset
                }
                $JobNew.Dequeued = [System.DateTimeOffset]::new($DeqDateTime,$Offset)

            } # End nested Dequeued
        } # End Enqueued
        
        # Finished
        if($ResponseJobCur.tfin -match $QRegex) {
            $FinDateTime = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
            # If DST in effect, offset is the time zone default offset + 1
            if($TimeZoneInfo.IsDaylightSavingTime($FinDateTime)) {
                $DstModification = New-TimeSpan -Hours 1
                $Offset = $TimeZoneInfo.BaseUtcOffset.Add($DstModification)
            }
            # If DST NOT in effect, offset is the time zone default offset
            else {
                $Offset = $TimeZoneInfo.BaseUtcOffset
            }

            $JobNew.Finished = [System.DateTimeOffset]::new($FinDateTime,$Offset)
        } # End Finished

        $JobNew.TimeZoneInfo = $TimeZoneInfo
        $JobNew.Details = $ResponseJobCur.details.line -join "`n"
        $JobNew.Warnings = $ResponseJobCur.warnings.line -join "`n"
        $JobNew.Device = $PSBoundParameters.Device

        # Add to aggregate
        $JobAgg.Add($JobNew)
    }

    return $JobAgg | Sort-Object -Property 'Id'
} # Function
