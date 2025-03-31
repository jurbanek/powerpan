class PanJob {
    # Job ID
    [Int] $Id
    # Job Type
    [String] $Type
    # Job's user/owner
    [String] $User
    # Job Status
    [String] $Status
    # Job Progress. Commits are a percentage intenger. Other jobs are a date format. Needs to stay a string. Cannot be a [DateTime].
    [String] $Progress
    # Job Result
    [String] $Result
    # Whether job is currently queued
    [String] $Queued
    # Position in Queue
    [Int] $PositionInQueue
    # Is job stoppable
    [String] $Stoppable

    # DateTimeOffset is used for these values. Standard DateTime does not offer an offset.
    # Time Enqueued (submitted/entered the job queue)
    [DateTimeOffset] $Enqueued

    # Time Dequeued (started processing)
    [DateTimeOffset] $Dequeued

    # Time Finished (job completed/finished)
    [DateTimeOffset] $Finished

    # Time Zone, stored as TimeZoneInfo, useful should friendly time zone names be needed
    [TimeZoneInfo] $TimeZoneInfo

    # Multi-line details
    [String] $Details
    # Multi-line warnings
    [String] $Warnings
    
    # Parent PanDevice address references
    [PanDevice] $Device
    
    # Default Constructor
    PanJob() {
    }
 
 } # End class
 