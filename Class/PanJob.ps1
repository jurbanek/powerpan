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

    # Time Enqueued (submitted/entered the job queue)
    [DateTime] $DtEnqueued

    # Time Dequeued (started processing)
    [DateTime] $DtDequeued

    # Time Finished (job completed/finished)
    [DateTime] $DtFinished

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
 