function Update-PanDeviceVsys {
   <#
   .SYNOPSIS
   Updates the PanDevice vsys layout within PanDeviceDb.
   .DESCRIPTION
   Updates to the vsys layout do not persist across PowerShell sessions. The setting/layout is not saved to disk and is updated (refreshed) at runtime.
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   None
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) on which vsys layout will be determined and then PanDeviceDb updated')]
      [PanDevice[]] $Device
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb

   } # Begin block

   Process {

      foreach($DeviceCur in $Device) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry/@name"
         $DeviceCurVsysAgg = @()

         # Fetch a list of vsys names (not display-name)
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPath
         if($PanResponse.Status -eq 'success') {
            foreach($EntryCur in $PanResponse.Result.entry) {
               # Add each entry's name to an aggregate. In most firewalls there is a single entry with name 'vsys1'
               $DeviceCurVsysAgg += $EntryCur.name
            }

            # Update the PanDevice in PanDeviceDb
            $DeviceCur.Vsys = $DeviceCurVsysAgg
            $DeviceCur.VsysUpdated = $true
         }
      }
   } # Process block

   End {
   } # End block
} # Function
