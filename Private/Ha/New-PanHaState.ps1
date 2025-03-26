function New-PanHaState {
    <#
    .SYNOPSIS
    Returns a PanHaState object.
    .DESCRIPTION
    Returns a PanHaState object.
    .NOTES
    .INPUTS
    None
    .OUTPUTS
    PanHaState
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
 
    $State = [PanHaState]::new()

    $State.Enabled = if($Response.result.enabled -eq 'yes') {$True} else {$False}
    $State.LocalState = $Response.result.group.'local-info'.state
    $State.PeerState = $Response.result.group.'peer-info'.state
    $State.RunningSyncEnabled = if($Response.result.group.'running-sync-enabled' -eq 'yes') {$True} else {$False}
    $State.RunningSync = $Response.result.group.'running-sync'
    $State.Device = $PSBoundParameters.Device

    # Local Info
    $State.Local.Mode = $Response.result.group.'local-info'.mode
    $State.Local.Group = $Response.result.group.'local-info'.version
    
    $State.Local.State = $Response.result.group.'local-info'.state
    if($Response.result.group.'local-info'.'state-duration' -ge 0) {
        $State.Local.StateDuration = New-TimeSpan -Seconds $Response.result.group.'local-info'.'state-duration'
    }
    $State.Local.StateReason = $Response.result.group.'local-info'.'state-reason'
    $State.Local.LastErrorState = $Response.result.group.'local-info'.'last-error-state'
    $State.Local.LastErrorReason = $Response.result.group.'local-info'.'last-error-reason'

    $State.Local.PlatformModel = $Response.result.group.'local-info'.'platform-model'
    $State.Local.SerialNum = $Response.result.group.'local-info'.'serial-num'
    $State.Local.MgmtIp = $Response.result.group.'local-info'.'mgmt-ip'
    $State.Local.MgmtIpv6 = $Response.result.group.'local-info'.'mgmt-ipv6'
    $State.Local.Priority = $Response.result.group.'local-info'.priority
    $State.Local.Preemptive = if($Response.result.group.'local-info'.preemptive -eq 'yes') {$True} else {$False}

    if($Response.result.group.'local-info'.'promotion-hold' -ge 0) {
        $State.Local.PromotionHold = New-TimeSpan -Milliseconds $Response.result.group.'local-info'.'promotion-hold'
    }
    if($Response.result.group.'local-info'.'hello-interval' -ge 0) {
        $State.Local.HelloInterval = New-TimeSpan -Milliseconds $Response.result.group.'local-info'.'hello-interval'
    }
    if($Response.result.group.'local-info'.'heartbeat-interval' -ge 0) {
        $State.Local.HeartbeatInterval = New-TimeSpan -Milliseconds $Response.result.group.'local-info'.'heartbeat-interval'
    }
    if($Response.result.group.'local-info'.'preempt-hold' -ge 0) {
        $State.Local.PreemptHold = New-TimeSpan -Seconds $Response.result.group.'local-info'.'preempt-hold'
    }
    if($Response.result.group.'local-info'.'monitor-fail-holdup' -ge 0) {
        $State.Local.MonitorFailHoldup = New-TimeSpan -Milliseconds $Response.result.group.'local-info'.'monitor-fail-holdup'
    }
    if($Response.result.group.'local-info'.'addon-master-holdup' -ge 0) {
        $State.Local.AddonMasterHoldup = New-TimeSpan -Milliseconds $Response.result.group.'local-info'.'addon-master-holdup'
    }

    $State.Local.MaxFlaps = $Response.result.group.'local-info'.'max-flaps'
    $State.Local.PreemptFlapCount = $Response.result.group.'local-info'.'preempt-flap-cnt'
    $State.Local.NonFuncFlapCount = $Response.result.group.'local-info'.'nonfunc-flap-cnt'
    $State.Local.MgmtHeartbeat = $Response.result.group.'local-info'.'mgmt-hb'
    $State.Local.StateSync = $Response.result.group.'local-info'.'state-sync'
    $State.Local.StateSyncType = $Response.result.group.'local-info'.'state-sync-type'

    $State.Local.BuildRel = $Response.result.group.'local-info'.'build-rel'
    $State.Local.UrlVersion = $Response.result.group.'local-info'.'url-version'
    $State.Local.AppVersion = $Response.result.group.'local-info'.'app-version'
    $State.Local.IotVersion = $Response.result.group.'local-info'.'iot-version'
    $State.Local.AvVersion = $Response.result.group.'local-info'.'av-version'
    $State.Local.ThreatVersion = $Response.result.group.'local-info'.'threat-version'
    $State.Local.VpnClientVersion = $Response.result.group.'local-info'.'vpnclient-version'
    $State.Local.GpClientVersion = $Response.result.group.'local-info'.'gpclient-version'
    $State.Local.Dlp = $Response.result.group.'local-info'.dlp
    $State.Local.BuildCompat = $Response.result.group.'local-info'.'build-compat'
    $State.Local.UrlCompat = $Response.result.group.'local-info'.'url-compat'
    $State.Local.AppCompat = $Response.result.group.'local-info'.'app-compat'
    $State.Local.IotCompat = $Response.result.group.'local-info'.'iot-compat'
    $State.Local.AvCompat = $Response.result.group.'local-info'.'av-compat'
    $State.Local.ThreatCompat = $Response.result.group.'local-info'.'threat-compat'
    $State.Local.VpnClientCompat = $Response.result.group.'local-info'.'vpnclient-compat'
    $State.Local.GpClientCompat = $Response.result.group.'local-info'.'gpclient-compat'

    # Peer Info
    $State.Peer.Mode = $Response.result.group.'peer-info'.mode
    $State.Peer.Group = $Response.result.group.'peer-info'.version

    $State.Peer.State = $Response.result.group.'peer-info'.state
    if($Response.result.group.'peer-info'.'state-duration' -ge 0) {
        $State.Peer.StateDuration = New-TimeSpan -Seconds $Response.result.group.'peer-info'.'state-duration'
    }
    $State.Peer.StateReason = $Response.result.group.'peer-info'.'state-reason'
    $State.Peer.LastErrorState = $Response.result.group.'peer-info'.'last-error-state'
    $State.Peer.LastErrorReason = $Response.result.group.'peer-info'.'last-error-reason'

    $State.Peer.PlatformModel = $Response.result.group.'peer-info'.'platform-model'
    $State.Peer.SerialNum = $Response.result.group.'peer-info'.'serial-num'
    $State.Peer.MgmtIp = $Response.result.group.'peer-info'.'mgmt-ip'
    $State.Peer.MgmtIpv6 = $Response.result.group.'peer-info'.'mgmt-ipv6'
    $State.Peer.Priority = $Response.result.group.'peer-info'.priority
    $State.Peer.Preemptive = if($Response.result.group.'peer-info'.preemptive -eq 'yes') {$True} else {$False}

    $State.Peer.BuildRel = $Response.result.group.'peer-info'.'build-rel'
    $State.Peer.UrlVersion = $Response.result.group.'peer-info'.'url-version'
    $State.Peer.AppVersion = $Response.result.group.'peer-info'.'app-version'
    $State.Peer.IotVersion = $Response.result.group.'peer-info'.'iot-version'
    $State.Peer.AvVersion = $Response.result.group.'peer-info'.'av-version'
    $State.Peer.ThreatVersion = $Response.result.group.'peer-info'.'threat-version'
    $State.Peer.VpnClientVersion = $Response.result.group.'peer-info'.'vpnclient-version'
    $State.Peer.GpClientVersion = $Response.result.group.'peer-info'.'gpclient-version'
    $State.Peer.Dlp = $Response.result.group.'peer-info'.dlp

    return $State
} # Function
 