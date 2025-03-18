function Invoke-PanSoftware {
   <#
   .SYNOPSIS
   Check, download and install PAN software
   .DESCRIPTION
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PSCustomObject
   .EXAMPLE
   Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Check

   Checks Palo Alto Networks update servers for software. [PanResponse] which includes versions and statuses is output to pipeline.
   .EXAMPLE
   Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Download -Version "11.2.4-h4"

   Checks Palo Alto Networks update servers for software (to update local software DB) and immediately begins downloading the specified version.

   A JobID representing the download is output to the pipeline. Monitor the job (download) status with Get-PanJob.
   .EXAMPLE
   Get-PanDevice "10.0.0.1" | Invoke-PanSoftware -Install -Version "11.2.4-h4"

   Installs software version. 

   A JobID representing the install is output to the pipeline. Monitor the job (install) status with Get-PanJob
   #>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage='PanDevice against which software operations will run.')]
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
      [parameter(Mandatory=$true,ParameterSetName='Download',HelpMessage='Specify the version of PAN-OS software.')]
      [parameter(Mandatory=$true,ParameterSetName='Install',HelpMessage='Specify the version of PAN-OS software.')]
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
            $Cmd = '<request><system><software><info></info></software></system></request>'
            Write-Debug ($MyInvocation.MyCommand.Name + ': Curently known software updates.')
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
                        
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               New-PanSoftware -Response $Response -Device $DeviceCur
            }
            else {
               Write-Error ('Error getting currently known software updates. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         }

         # ParameterSetName Check
         if($PSCmdlet.ParameterSetName -eq 'Check') {
            $Cmd = '<request><system><software><check></check></software></system></request>'
            Write-Debug ($MyInvocation.MyCommand.Name + ': Checking for software updates can take up to a minute.')
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
                        
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               New-PanSoftware -Response $Response -Device $DeviceCur
            }
            else {
               Write-Error ('Software check not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         }

         # ParameterSetName Download
         if($PSCmdlet.ParameterSetName -eq 'Download') {
            # Take into account SyncToPeer
            if($PSBoundParameters.SyncToPeer.IsPresent) {
               $Cmd = '<request><system><software><download><version>{0}</version><sync-to-peer></sync-to-peer></download></software></system></request>' -f $PSBoundParameters.Version   
            }
            else {
               $Cmd = '<request><system><software><download><version>{0}</version></download></software></system></request>' -f $PSBoundParameters.Version
            }
            
            Write-Debug ($MyInvocation.MyCommand.Name + ': Downloading software update.')
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
            
            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            if($Response.Status -eq 'success') {
               # Inform an interactive user of the JobID
               Write-Host $Response.Result.msg.line
               # Send a PanJob object down the pipeline
               Get-PanJob -Device $DeviceCur -Id $Response.Result.job
            }
            else {
               Write-Error ('Software download not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
            }
         } # End ParameterSetName CheckDownload

         # ParameterSetName Install
         elseif($PSCmdlet.ParameterSetName -eq 'Install') {
            $Cmd = '<request><system><software><install><version>{0}</version></install></software></system></request>' -f $PSBoundParameters.Version
            Write-Debug ($MyInvocation.MyCommand.Name + ': Installing software update.')
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)

            $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
               if($Response.Status -eq 'success') {
                  # Inform an interactive user of the JobID
                  Write-Host $Response.Result.msg.line
                  # Send a PanJob object down the pipeline
                  Get-PanJob -Device $DeviceCur -Id $Response.Result.job
               }
               else {
                  Write-Error ('Software install not successful Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
               }
         } # End ParameterSetName Install
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
