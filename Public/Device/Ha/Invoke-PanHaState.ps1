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
        [parameter(Mandatory=$true,ParameterSetName='Info',HelpMessage='Current PanDevice high-availability state information.')]
        [Switch] $Info,
        [parameter(Mandatory=$true,ParameterSetName='Suspend',HelpMessage='Change PanDevice high-availability state to suspend[ed].')]
        [Switch] $Suspend,
        [parameter(Mandatory=$true,ParameterSetName='Functional',HelpMessage='Change PanDevice high-availability state to functional.')]
        [Switch] $Functional
    )
    
    Begin {
        # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
        if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
        # Announce
        Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
    } # Begin Block
    
    Process {
        foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ($MyInvocation.MyCommand.Name + (': Device: {0}' -f $DeviceCur.Name))

            # ParameterSetName Info or Empty
            if($PSCmdlet.ParameterSetName -eq 'Info' -or $PSCmdlet.ParameterSetName -eq 'Empty') {
                $Cmd = '<show><high-availability><all></all></high-availability></show>'
                Write-Verbose ($MyInvocation.MyCommand.Name + (': -Info Cmd: {0}' -f $Cmd))
                $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($R.Status -eq 'success') {
                    # Send PanHaState object down pipeline
                    NewPanHaState -Device $DeviceCur -Response $R
                }
                else {
                    Write-Error ('Error retrieving PAN HA state. Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
                }
            } # End ParameterSetName

            # ParameterSetName Suspend
            if($PSCmdlet.ParameterSetName -eq 'Suspend') {
                $Cmd = '<request><high-availability><state><suspend></suspend></state></high-availability></request>'
                Write-Verbose ($MyInvocation.MyCommand.Name + (': -Suspend Cmd: {0}' -f $Cmd))
                $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($R.Status -eq 'success') {
                    Write-Verbose ($MyInvocation.MyCommand.Name + (': {0}' -f $R.Response.result))
                }
                else {
                    Write-Error ('Error applying PAN HA suspend operation. Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
                }
            } # End ParameterSetName

            # ParameterSetName Functional
            if($PSCmdlet.ParameterSetName -eq 'Functional') {
                $Cmd = '<request><high-availability><state><functional></functional></state></high-availability></request>'
                Write-Verbose ($MyInvocation.MyCommand.Name + (': -Functional Cmd: {0}' -f $Cmd))
                $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($R.Status -eq 'success') {
                    Write-Verbose ($MyInvocation.MyCommand.Name + (': {0}' -f $R.Response.result))
                }
                else {
                    Write-Error ('Error applying PAN HA functional operation. Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
                }
            } # End ParameterSetname
        } # foreach Device
    } # Process block
    
    End {
    } # End block
} # Function
