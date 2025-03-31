function Invoke-PanSoftware {
<#
.SYNOPSIS
PAN Software info, check, download operations.
.DESCRIPTION
.NOTES
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanJob or PanSoftware
.EXAMPLE
Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Info

Retrieve what is currently known about PAN-OS software, no update check. Returns content as [PanSoftware] objects.
.EXAMPLE
Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Check

Checks Palo Alto Networks update servers for software updates. Returns content as [PanSoftware] objects.
.EXAMPLE
Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Download -Version "11.2.4-h4"

Begins downloading the specified software version. A [PanJob] representing the download is output to the pipeline. Monitor the job (download) status with Get-PanJob.
.EXAMPLE
Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Install -Version "11.2.4-h4"

Install specified software version. A [PanJob] representing the install is output to the pipeline. Monitor the job (install) status with Get-PanJob.
.EXAMPLE
Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Delete -Version "11.2.4-h4"

Delete specified software version. Does not return a value.
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage='PanDevice against which software operation will be performed.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Info',HelpMessage='Output currently known versions of PAN-OS software.')]
      [Switch] $Info,
      [parameter(Mandatory=$true,ParameterSetName='Check',HelpMessage='Check for updated versions of PAN-OS software. Must be done before install.')]
      [Switch] $Check,
      [parameter(Mandatory=$true,ParameterSetName='Download',HelpMessage='Download the specified version of PAN-OS software.')]
      [Switch] $Download,
      [parameter(ParameterSetName='Download',HelpMessage='After downloading, sync the specified version to HA peer.')]
      [Switch] $SyncToPeer,
      [parameter(Mandatory=$true,ParameterSetName='Install',HelpMessage='Install the specified version of PAN-OS software.')]
      [Switch] $Install,
      [parameter(Mandatory=$true,ParameterSetName='Delete',HelpMessage='Delete the specified version of PAN-OS software.')]
      [Switch] $Delete,
      [parameter(Mandatory=$true,ParameterSetName='Download',HelpMessage='Specify the version of PAN-OS software.')]
      [parameter(Mandatory=$true,ParameterSetName='Install',HelpMessage='Specify the version of PAN-OS software.')]
      [parameter(Mandatory=$true,ParameterSetName='Delete',HelpMessage='Specify the version of PAN-OS software.')]
      [String] $Version
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
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

         # ParameterSetName Info
         if($PSCmdlet.ParameterSetName -eq 'Info') {
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

            $Cmd = '<request><system><software><info></info></software></system></request>'
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Info Cmd: {0}' -f $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               NewPanSoftware -Response $Response -Device $DeviceCur -TimeZoneName $TimeZoneName
            }
            else {
               Write-Error ('Error getting currently known software updates. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         } # End ParameterSetname

         # ParameterSetName Check
         if($PSCmdlet.ParameterSetName -eq 'Check') {
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
            
            $Cmd = '<request><system><software><check></check></software></system></request>'
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Check Cmd: {0}' -f $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               NewPanSoftware -Response $Response -Device $DeviceCur -TimeZoneName $TimeZoneName
            }
            else {
               Write-Error ('Software check not successful. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         } # End ParameterSetName

         # ParameterSetName Download
         if($PSCmdlet.ParameterSetName -eq 'Download') {
            # Take into account SyncToPeer
            if($PSBoundParameters.SyncToPeer.IsPresent) {
               $Cmd = '<request><system><software><download><version>{0}</version><sync-to-peer>yes</sync-to-peer></download></software></system></request>' -f $PSBoundParameters.Version   
            }
            else {
               $Cmd = '<request><system><software><download><version>{0}</version></download></software></system></request>' -f $PSBoundParameters.Version
            }
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Download Cmd: {0}' -f $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               # Inform an interactive user of the JobID using Write-Host given this operation is asynchronous
               Write-Host $Response.Result.msg.line
               # Send a PanJob object down the pipeline
               Get-PanJob -Device $DeviceCur -Id $Response.Result.job
            }
            else {
               Write-Error ('Software download not successful. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         } # End ParameterSetName

         # ParameterSetName Install
         elseif($PSCmdlet.ParameterSetName -eq 'Install') {
            $Cmd = '<request><system><software><install><version>{0}</version></install></software></system></request>' -f $PSBoundParameters.Version
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Install Cmd: {0}' -f $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
               if($Response.Status -eq 'success') {
                  # Inform an interactive user of the JobID using Write-Host given operation is asynchronous
                  Write-Host $Response.Result.msg.line
                  # Send a PanJob object down the pipeline
                  Get-PanJob -Device $DeviceCur -Id $Response.Result.job
               }
               else {
                  Write-Error ('Software install not successful. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
               }
         } # End ParameterSetName

         # ParameterSetName Delete
         elseif($PSCmdlet.ParameterSetName -eq 'Delete') {
            $Cmd = '<delete><software><version>{0}</version></software></delete>' -f $PSBoundParameters.Version
            Write-Debug ($MyInvocation.MyCommand.Name + (': -Delete Cmd: {0}' -f $Cmd))
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
               if($Response.Status -eq 'success') {
                  # No need for Write-Host since there is no error and no asynchronous Job. Keep in Verbose stream.
                  Write-Verbose ('Software delete success: {0}' -f $PSBoundParameters.Version)
               }
               else {
                  Write-Error ('Software delete failed. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
               }
         } # End ParameterSetName
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
