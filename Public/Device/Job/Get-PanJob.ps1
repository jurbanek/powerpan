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
Get-PanDevice "192.168.250.250" | Get-PanJob
Get-PanDevice "192.168.250.250" | Get-PanJob -All

Returns a list of all jobs present on the firewall
.EXAMPLE
Get-PanDevice "192.168.250.250" | Get-PanJob -Id 837

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
        # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
        if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
        # Announce
        Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

        # Retrieve all jobs
        if($PSCmdlet.ParameterSetName -eq 'Empty' -or $PSCmdlet.ParameterSetName -eq 'All') {
            $Cmd = '<show><jobs><all></all></jobs></show>'
            Write-Verbose ($MyInvocation.MyCommand.Name + (': -All Cmd: {0}' -f $Cmd))
        }
        # Return specific job ID
        elseif($PSCmdlet.ParameterSetName -eq 'Id') {
            $Cmd = '<show><jobs><id>{0}</id></jobs></show>' -f $PSBoundParameters.Id
            Write-Verbose ($MyInvocation.MyCommand.Name + (': -Id {0} Cmd: {1}' -f $PSBoundParameters.Id, $Cmd))
        }
        # Return pending jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Pending') {
            $Cmd = '<show><jobs><pending></pending></jobs></show>'
            Write-Verbose ($MyInvocation.MyCommand.Name + (': -Pending Cmd: {0}' -f $Cmd))
        }
        # Return processed jobs
        elseif($PSCmdlet.ParameterSetName -eq 'Processed') {
            $Cmd = '<show><jobs><processed></processed></jobs></show>'
            Write-Verbose ($MyInvocation.MyCommand.Name + (': -Processed Cmd: {0}' -f $Cmd))
        }
    } # Begin Block
 
    Process {
        foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ($MyInvocation.MyCommand.Name + (': Device: {0}' -f $DeviceCur.Name))
            
            # Determine the Device Time Zone name from deviceconfig/system/timezone
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/deviceconfig/system/timezone"
            $R = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPath
            if($R.Status -eq 'success') {
                Write-Verbose ($MyInvocation.MyCommand.Name + (': Device: {0} Time Zone: {1}' -f $DeviceCur.Name, $R.Response.result.timezone))
                $TimeZoneName = $R.Response.result.timezone
            }
            else {
                Write-Verbose ($MyInvocation.MyCommand.Name + (': Device: {0} Unable to determine Device Time Zone, using "UTC"' -f $DeviceCur.Name))
                Write-Error ('Retrieving Device Time Zone not successful Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
                Write-Warning ('Unable to determine Device Time Zone, using "UTC"')
                $TimeZoneName = 'UTC'
            }

            # Get the jobs
            $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($R.Status -eq 'success') {
                NewPanJob -Device $DeviceCur -Response $R -TimeZoneName $TimeZoneName
            }
            else {
                Write-Error ('Retrieving PAN Jobs not successful Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message)
            }

        } # foreach Device
    } # Process block
    End {
    } # End block
} # Function
