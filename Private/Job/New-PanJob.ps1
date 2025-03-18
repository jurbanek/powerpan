function New-PanJob {
    <#
    .SYNOPSIS
    Returns a PanJob object.
    .DESCRIPTION
    Returns a PanJob object.
    .NOTES
    .INPUTS
    None
    .OUTPUTS
    PanJob
    .EXAMPLE
    #>
    [CmdletBinding()]
    param(
       [parameter(
          Mandatory=$true,
          HelpMessage='PanResponse')]
       [PanResponse] $Response,
       [parameter(
          Mandatory=$true,
          HelpMessage='PanDevice')]
       [PanDevice] $Device
    )
 
    # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
    if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
    if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
    # Announce
    Write-Debug ($MyInvocation.MyCommand.Name + ':')
 
    $JobAgg = [System.Collections.Generic.List[PanJob]]@()
    #$JobAgg = @()

    foreach($ResponseJobCur in $PSBoundParameters.Response.Result.job) {
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
        # In firewall local time (not UTC unless firewall TZ is UTC)
        $QRegex = '(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)'
        $QRegexTimeOnly = '(\d+):(\d+):(\d+)'
        
        # DtEnqueue (and nested DtDequeue)
        if($ResponseJobCur.tenq -match $QRegex) {
            $JobNew.DtEnqueued = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
        
            # DtDequeued processing is kept within DtEnqueued if() block because of below.
            # XML-API is pretty silly.
            # tenq format is 2025/02/20 21:05:20
            # tdeq format is 21:05:20
            # There is no date portion in the dequeued value. Ridiculous. We want valid [DateTime] for both Enqueued and Dequeued.
            # Dequeuing is *likely* on the same day as Enqueueing. It's usually immediate or within a few minutes... but also need to verify.
            # Need to account for:
            # Enqueue 2025/02/20 23:59:58
            # Dequeue 00:00:02
            # Need to determine if crossing midnight. Can't just use the Enqueued date portion blindly when creating Dequeued DateTime.
            
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
                    $JobNew.DtDequeued = $([DateTime]::new($EnqYear,$EnqMonth,$EnqDay,$Matches[1],$Matches[2],$Matches[3],0,0)).AddDays(1)
                }
                # Have NOT crossed into next day. 
                else {
                    # Use the Enqueued Y M D and Dequeued Hr Min Sec. No need to add a day.
                    $JobNew.DtDequeued = [DateTime]::new($EnqYear,$EnqMonth,$EnqDay,$Matches[1],$Matches[2],$Matches[3],0,0)
                }
            } # End nested DtDequeued
        } # End DtEnqueued
        
        # DtFinished
        if($ResponseJobCur.tfin -match $QRegex) {
            $JobNew.DtFinished = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
        }
        
        $JobNew.Details = $ResponseJobCur.details.line -join "`n"
        $JobNew.Warnings = $ResponseJobCur.warnings.line -join "`n"
        
        $JobNew.Device = $PSBoundParameters.Device

        # Add to aggregate
        $JobAgg.Add($JobNew)
    }

    return $JobAgg | Sort-Object -Property 'Id'
} # Function
 