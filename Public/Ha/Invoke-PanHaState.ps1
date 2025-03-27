function Invoke-PanHaState {
<#
.SYNOPSIS
PAN high-availability state, suspend, and functional operations.
.DESCRIPTION
.NOTES
.INPUTS
PanDevice[]
    You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanHaState
.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Invoke-PanHaState -Info
    
Returns a PanHaState object with high-availability state information.
.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Invoke-PanHaState -Suspend
    
Suspend PAN high-availability. Places device HA in "suspended" state.
.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Invoke-PanHaState -Functional
    
Unsuspend (make functional) PAN high-availability. Device goes through HA startup ending up in "active", "passive", or some other error condition.
#>
    [CmdletBinding(DefaultParameterSetName='Empty')]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage='PanDevice against which high-availability operation will be performed.')]
        [PanDevice[]] $Device,
        [parameter(Mandatory=$true,ParameterSetName='Info',HelpMessage='Output current high-availability state information.')]
        [Switch] $Info,
        [parameter(Mandatory=$true,ParameterSetName='Suspend',HelpMessage='Change PanDevice high-availability state to suspend[ed].')]
        [Switch] $Suspend,
        [parameter(Mandatory=$true,ParameterSetName='Functional',HelpMessage='Change PanDevice high-availability state to functiona.')]
        [Switch] $Functional
    )
    
    Begin {
        # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
        if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
        if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
        # Announce
        Write-Debug ($MyInvocation.MyCommand.Name + ':')
    } # Begin Block
    
    Process {
        foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0}' -f $DeviceCur.Name))

            # ParameterSetName Info
            if($PSCmdlet.ParameterSetName -eq 'Info') {
                $Cmd = '<show><high-availability><all></all></high-availability></show>'
                Write-Debug ($MyInvocation.MyCommand.Name + (': -Info Cmd: {0}' -f $Cmd))
                $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($Response.Status -eq 'success') {
                    NewPanHaState -Device $DeviceCur -Response $Response
                }
                else {
                    Write-Error ('Error retrieving PAN HA state. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
                }
            } # End ParameterSetName

            # ParameterSetName Suspend
            if($PSCmdlet.ParameterSetName -eq 'Suspend') {
                $Cmd = '<request><high-availability><state><suspend></suspend></state></high-availability></request>'
                Write-Debug ($MyInvocation.MyCommand.Name + (': -Suspend Cmd: {0}' -f $Cmd))
                $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($Response.Status -eq 'success') {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': {0}' -f $Response.result))
                }
                else {
                    Write-Error ('Error applying PAN HA suspend operation. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
                }
            } # End ParameterSetName

            # ParameterSetName Functional
            if($PSCmdlet.ParameterSetName -eq 'Functional') {
                $Cmd = '<request><high-availability><state><functional></functional></state></high-availability></request>'
                Write-Debug ($MyInvocation.MyCommand.Name + (': -Functional Cmd: {0}' -f $Cmd))
                $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($Response.Status -eq 'success') {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': {0}' -f $Response.result))
                }
                else {
                    Write-Error ('Error applying PAN HA functional operation. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
                }
            } # End ParameterSetname

        } # foreach Device
    } # Process block
    
    End {
    } # End block
} # Function
