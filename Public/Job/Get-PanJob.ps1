function Get-PanJob {
<#
.SYNOPSIS
Get list of PAN job(s) 
.DESCRIPTION
.NOTES
.INPUTS
PanDevice[]
    You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanJob
.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Get-PanJob
PS> Get-PanDevice "192.168.250.250" | Get-PanJob -All

Returns a list of all jobs present on the firewall

.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Get-PanJob -Id 837

Returns the details for job ID 837.

#>
    [CmdletBinding(DefaultParameterSetName='Empty')]
    param(
        [parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage='PanDevice against which job(s) will be retrieved.')]
        [PanDevice[]] $Device,
        [parameter(
            ParameterSetName='All',
            HelpMessage='Retrieve all jobs in history.')]
        [Switch] $All,
        [parameter(
            ParameterSetName='Id',
            HelpMessage='Retrieve specific job ID in history.')]
        [Int] $Id,
        [parameter(
            ParameterSetName='Pending',
            HelpMessage='Retrieve only pending jobs in history.')]
        [Switch] $Pending,
        [parameter(
            ParameterSetName='Processed',
            HelpMessage='Retrieve only processed jobs in history.')]
        [Switch] $Processed
    )
 
    Begin {
        # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
        if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
        if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
        # Announce
        Write-Debug ($MyInvocation.MyCommand.Name + ':')

        # Retrieve all jobs
        if($PSCmdlet.ParameterSetName -eq 'Empty' -or $PSCmdlet.ParameterSetName -eq 'All') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': All Jobs')
            $Cmd = '<show><jobs><all></all></jobs></show>'
        }
        # Return specific job ID
        elseif($PSCmdlet.ParameterSetName -eq 'Id') {
        Write-Debug ($MyInvocation.MyCommand.Name + ': Job ID ' + $PSBoundParameters.Id)
            $Cmd = '<show><jobs><id>{0}</id></jobs></show>' -f $PSBoundParameters.Id
        }
        # Return pending jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Pending') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Pending Jobs')
            $Cmd = '<show><jobs><pending></pending></jobs></show>'
        }
        # Return processed jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Processed') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Processed Jobs')
            $Cmd = '<show><jobs><processed></processed></jobs></show>'
        }
    } # Begin Block
 
    Process {
        foreach($DeviceCur in $PSBoundParameters['Device']) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

            # Ensure Vsys map is up to date for current device
            Update-PanDeviceVsys -Device $DeviceCur

            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
                New-PanJob -Device $DeviceCur -Response $Response
            }
            else {
                Write-Error ('Retrieing PAN Jobs not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }

        } # foreach Device
    } # Process block
    End {
    } # End block
 } # Function
 