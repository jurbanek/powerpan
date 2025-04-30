function NewPanHaState {
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
 
    # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
    if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
    # Announce
    Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
 
    $State = [PanHaState]::new()

    # If HA not enabled, not much to do
    if($Response.Response.result.enabled -eq 'no') {
        $State.Enabled = $False
    }
    # HA enabled
    elseif($Response.Response.result.enabled -eq 'yes') {
        $State.Enabled = $True
        $State.LocalState = $Response.Response.result.group.'local-info'.state
        $State.PeerState = $Response.Response.result.group.'peer-info'.state
        $State.RunningSyncEnabled = if($Response.Response.result.group.'running-sync-enabled' -eq 'yes') {$True} else {$False}
        $State.RunningSync = $Response.Response.result.group.'running-sync'
        $State.Device = $PSBoundParameters.Device

        # Local Info
        $State.Local.Mode = $Response.Response.result.group.'local-info'.mode
        $State.Local.Group = $Response.Response.result.group.'local-info'.version
        
        $State.Local.State = $Response.Response.result.group.'local-info'.state
        if($Response.Response.result.group.'local-info'.'state-duration' -ge 0) {
            $State.Local.StateDuration = New-TimeSpan -Seconds $Response.Response.result.group.'local-info'.'state-duration'
        }
        $State.Local.StateReason = $Response.Response.result.group.'local-info'.'state-reason'
        $State.Local.LastErrorState = $Response.Response.result.group.'local-info'.'last-error-state'
        $State.Local.LastErrorReason = $Response.Response.result.group.'local-info'.'last-error-reason'

        $State.Local.PlatformModel = $Response.Response.result.group.'local-info'.'platform-model'
        $State.Local.SerialNum = $Response.Response.result.group.'local-info'.'serial-num'
        $State.Local.MgmtIp = $Response.Response.result.group.'local-info'.'mgmt-ip'
        $State.Local.MgmtIpv6 = $Response.Response.result.group.'local-info'.'mgmt-ipv6'
        $State.Local.Priority = $Response.Response.result.group.'local-info'.priority
        $State.Local.Preemptive = if($Response.Response.result.group.'local-info'.preemptive -eq 'yes') {$True} else {$False}

        if($Response.Response.result.group.'local-info'.'promotion-hold' -ge 0) {
            # promotion-hold in milliseconds. New-TimeSpan -Milliseconds parameter added in PS 7.3, use type Constructor instead
            # $State.Local.PromotionHold = New-TimeSpan -Milliseconds $Response.Response.result.group.'local-info'.'promotion-hold'
            $State.Local.PromotionHold = [TimeSpan]::new(0,0,0,0,$Response.Response.result.group.'local-info'.'promotion-hold')
        }
        if($Response.Response.result.group.'local-info'.'hello-interval' -ge 0) {
            # hello-interval in milliseconds. New-TimeSpan -Milliseconds parameter added in PS 7.3, use type Constructor instead
            # $State.Local.HelloInterval = New-TimeSpan -Milliseconds $Response.Response.result.group.'local-info'.'hello-interval'
            $State.Local.HelloInterval = [TimeSpan]::new(0,0,0,0,$Response.Response.result.group.'local-info'.'hello-interval')
        }
        if($Response.Response.result.group.'local-info'.'heartbeat-interval' -ge 0) {
            # heartbeat-interval in milliseconds. New-TimeSpan -Milliseconds parameter added in PS 7.3, use type Constructor instead
            # $State.Local.HeartbeatInterval = New-TimeSpan -Milliseconds $Response.Response.result.group.'local-info'.'heartbeat-interval'
            $State.Local.HeartbeatInterval = [TimeSpan]::new(0,0,0,0,$Response.Response.result.group.'local-info'.'heartbeat-interval')
        }
        if($Response.Response.result.group.'local-info'.'preempt-hold' -ge 0) {
            $State.Local.PreemptHold = New-TimeSpan -Seconds $Response.Response.result.group.'local-info'.'preempt-hold'
        }
        if($Response.Response.result.group.'local-info'.'monitor-fail-holdup' -ge 0) {
            # monitor-fail-holdup in milliseconds. New-TimeSpan -Milliseconds parameter added in PS 7.3, use type Constructor instead
            # $State.Local.MonitorFailHoldup = New-TimeSpan -Milliseconds $Response.Response.result.group.'local-info'.'monitor-fail-holdup'
            $State.Local.MonitorFailHoldup = [TimeSpan]::new(0,0,0,0,$Response.Response.result.group.'local-info'.'monitor-fail-holdup')
        }
        if($Response.Response.result.group.'local-info'.'addon-master-holdup' -ge 0) {
            # addon-master-holdup in milliseconds. New-TimeSpan -Milliseconds parameter added in PS 7.3, use type Constructor instead
            # $State.Local.AddonMasterHoldup = New-TimeSpan -Milliseconds $Response.Response.result.group.'local-info'.'addon-master-holdup'
            $State.Local.AddonMasterHoldup = [TimeSpan]::new(0,0,0,0,$Response.Response.result.group.'local-info'.'addon-master-holdup')
        }

        $State.Local.MaxFlaps = $Response.Response.result.group.'local-info'.'max-flaps'
        $State.Local.PreemptFlapCount = $Response.Response.result.group.'local-info'.'preempt-flap-cnt'
        $State.Local.NonFuncFlapCount = $Response.Response.result.group.'local-info'.'nonfunc-flap-cnt'
        $State.Local.MgmtHeartbeat = $Response.Response.result.group.'local-info'.'mgmt-hb'
        $State.Local.StateSync = $Response.Response.result.group.'local-info'.'state-sync'
        $State.Local.StateSyncType = $Response.Response.result.group.'local-info'.'state-sync-type'

        $State.Local.BuildRel = $Response.Response.result.group.'local-info'.'build-rel'
        $State.Local.UrlVersion = $Response.Response.result.group.'local-info'.'url-version'
        $State.Local.AppVersion = $Response.Response.result.group.'local-info'.'app-version'
        $State.Local.IotVersion = $Response.Response.result.group.'local-info'.'iot-version'
        $State.Local.AvVersion = $Response.Response.result.group.'local-info'.'av-version'
        $State.Local.ThreatVersion = $Response.Response.result.group.'local-info'.'threat-version'
        $State.Local.VpnClientVersion = $Response.Response.result.group.'local-info'.'vpnclient-version'
        $State.Local.GpClientVersion = $Response.Response.result.group.'local-info'.'gpclient-version'
        $State.Local.Dlp = $Response.Response.result.group.'local-info'.dlp
        $State.Local.BuildCompat = $Response.Response.result.group.'local-info'.'build-compat'
        $State.Local.UrlCompat = $Response.Response.result.group.'local-info'.'url-compat'
        $State.Local.AppCompat = $Response.Response.result.group.'local-info'.'app-compat'
        $State.Local.IotCompat = $Response.Response.result.group.'local-info'.'iot-compat'
        $State.Local.AvCompat = $Response.Response.result.group.'local-info'.'av-compat'
        $State.Local.ThreatCompat = $Response.Response.result.group.'local-info'.'threat-compat'
        $State.Local.VpnClientCompat = $Response.Response.result.group.'local-info'.'vpnclient-compat'
        $State.Local.GpClientCompat = $Response.Response.result.group.'local-info'.'gpclient-compat'

        # Peer Info
        $State.Peer.Mode = $Response.Response.result.group.'peer-info'.mode
        $State.Peer.Group = $Response.Response.result.group.'peer-info'.version

        $State.Peer.State = $Response.Response.result.group.'peer-info'.state
        if($Response.Response.result.group.'peer-info'.'state-duration' -ge 0) {
            $State.Peer.StateDuration = New-TimeSpan -Seconds $Response.Response.result.group.'peer-info'.'state-duration'
        }
        $State.Peer.StateReason = $Response.Response.result.group.'peer-info'.'state-reason'
        $State.Peer.LastErrorState = $Response.Response.result.group.'peer-info'.'last-error-state'
        $State.Peer.LastErrorReason = $Response.Response.result.group.'peer-info'.'last-error-reason'

        $State.Peer.PlatformModel = $Response.Response.result.group.'peer-info'.'platform-model'
        $State.Peer.SerialNum = $Response.Response.result.group.'peer-info'.'serial-num'
        $State.Peer.MgmtIp = $Response.Response.result.group.'peer-info'.'mgmt-ip'
        $State.Peer.MgmtIpv6 = $Response.Response.result.group.'peer-info'.'mgmt-ipv6'
        $State.Peer.Priority = $Response.Response.result.group.'peer-info'.priority
        $State.Peer.Preemptive = if($Response.Response.result.group.'peer-info'.preemptive -eq 'yes') {$True} else {$False}

        $State.Peer.BuildRel = $Response.Response.result.group.'peer-info'.'build-rel'
        $State.Peer.UrlVersion = $Response.Response.result.group.'peer-info'.'url-version'
        $State.Peer.AppVersion = $Response.Response.result.group.'peer-info'.'app-version'
        $State.Peer.IotVersion = $Response.Response.result.group.'peer-info'.'iot-version'
        $State.Peer.AvVersion = $Response.Response.result.group.'peer-info'.'av-version'
        $State.Peer.ThreatVersion = $Response.Response.result.group.'peer-info'.'threat-version'
        $State.Peer.VpnClientVersion = $Response.Response.result.group.'peer-info'.'vpnclient-version'
        $State.Peer.GpClientVersion = $Response.Response.result.group.'peer-info'.'gpclient-version'
        $State.Peer.Dlp = $Response.Response.result.group.'peer-info'.dlp
    }
    
    return $State
} # Function
