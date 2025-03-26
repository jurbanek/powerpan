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
        [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='PanDevice against which job(s) will be retrieved.')]
        [PanDevice[]] $Device,
        [parameter(ParameterSetName='All',HelpMessage='Retrieve all jobs in history.')]
        [Switch] $All,
        [parameter(ParameterSetName='Id',HelpMessage='Retrieve specific job ID in history.')]
        [Int] $Id,
        [parameter(ParameterSetName='Pending',HelpMessage='Retrieve only pending jobs in history.')]
        [Switch] $Pending,
        [parameter(ParameterSetName='Processed',HelpMessage='Retrieve only processed jobs in history.')]
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
            $Cmd = '<show><jobs><all></all></jobs></show>'
            Write-Debug ($MyInvocation.MyCommand.Name + (': -All Cmd: {0}' -f $Cmd))
        }
        # Return specific job ID
        elseif($PSCmdlet.ParameterSetName -eq 'Id') {
            $Cmd = '<show><jobs><id>{0}</id></jobs></show>' -f $PSBoundParameters.Id
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Id {0} Cmd: {1}' -f $PSBoundParameters.Id, $Cmd))
        }
        # Return pending jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Pending') {
            $Cmd = '<show><jobs><pending></pending></jobs></show>'
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Pending Cmd: {0}' -f $Cmd))
        }
        # Return processed jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Processed') {
            $Cmd = '<show><jobs><processed></processed></jobs></show>'
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Processed Cmd: {0}' -f $Cmd))
        }
    } # Begin Block
 
    Process {
        foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0}' -f $DeviceCur.Name))
            
            # Determine the Device Time Zone name from deviceconfig/system/timezone
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/deviceconfig/system/timezone"
            $Response = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPath
            if($Response.Status -eq 'success') {
                Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0} Time Zone: {1}' -f $DeviceCur.Name, $Response.Result.timezone))
                $TimeZoneName = $Response.Result.timezone
            }
            else {
                Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0} Unable to determine Device Time Zone, using "UTC"' -f $DeviceCur.Name))
                Write-Error ('Retrieving Device Time Zone not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
                Write-Warning ('Unable to determine Device Time Zone, using "UTC"')
                $TimeZoneName = 'UTC'
            }

            # Get the jobs
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
                New-PanJob -Device $DeviceCur -Response $Response -TimeZoneName $TimeZoneName
            }
            else {
                Write-Error ('Retrieving PAN Jobs not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }

        } # foreach Device
    } # Process block
    End {
    } # End block
} # Function
