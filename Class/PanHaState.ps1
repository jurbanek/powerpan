class PanHaLocalInfo {
    [String] $Mode
    [Int] $Group
    [String] $State
    # API returns State Duration value in seconds
    [TimeSpan] $StateDuration
    [String] $StateReason
    [String] $LastErrorState
    [String] $LastErrorReason
    [String] $PlatformModel
    [String] $SerialNum
    [String] $MgmtIp
    [String] $MgmtIpv6
    [Int] $Priority
    [Bool] $Preemptive
    # API returns Promotion Hold Time value in milliseconds
    [TimeSpan] $PromotionHold
    # API returns Hello Interval value in milliseconds
    [TimeSpan] $HelloInterval
    # API returns Heartbeat Interval value in milliseconds
    [TimeSpan] $HeartbeatInterval
    # API returns Preemption Hold Time in seconds
    [TimeSpan] $PreemptHold
    # API returns Monitor Fail Holdup in milliseconds
    [TimeSpan] $MonitorFailHoldup
    # API returns Additional Master Holdup in milliseconds
    [TimeSpan] $AddonMasterHoldup
    [Int] $MaxFlaps
    [Int] $PreemptFlapCount
    [Int] $NonFuncFlapCount
    [String] $MgmtHeartbeat
    [String] $StateSync
    [String] $StateSyncType
    [String] $BuildRel
    [String] $UrlVersion
    [String] $AppVersion
    [String] $IotVersion
    [String] $AvVersion
    [String] $ThreatVersion
    [String] $VpnClientVersion
    [String] $GpClientVersion
    [String] $Dlp
    [String] $BuildCompat
    [String] $UrlCompat
    [String] $AppCompat
    [String] $IotCompat
    [String] $AvCompat
    [String] $ThreatCompat
    [String] $VpnClientCompat
    [String] $GpClientCompat

    # Default constructor
    PanHaLocalInfo() {
    }

} # End class

class PanHaPeerInfo {
    [String] $Mode
    [Int] $Group
    [String] $State
    # API returns State Duration value in seconds
    [TimeSpan] $StateDuration
    [String] $StateReason
    [String] $LastErrorState
    [String] $LastErrorReason
    [String] $PlatformModel
    [String] $SerialNum
    [String] $MgmtIp
    [String] $MgmtIpv6
    [Int] $Priority
    [Bool] $Preemptive
    [String] $BuildRel
    [String] $UrlVersion
    [String] $AppVersion
    [String] $IotVersion
    [String] $AvVersion
    [String] $ThreatVersion
    [String] $VpnClientVersion
    [String] $GpClientVersion
    [String] $Dlp

    # Default constructor
    PanHaPeerInfo() {
    }

} # End class


class PanHaState {
    # Enabled or not
    [Bool] $Enabled
    [String] $LocalState
    [String] $PeerState
    
    # Nested classes with greater HA detail
    [PanHaLocalInfo] $Local
    [PanHaPeerInfo] $Peer

    [Bool] $RunningSyncEnabled
    [String] $RunningSync

    [PanDevice] $Device
    
    # Default Constructor
    PanHaState() {
        # Call default constructors on nested classes so they are usable
        $this.Local = [PanHaLocalInfo]::new()
        $this.Peer = [PanHaPeerInfo]::new()
    }

} # End class