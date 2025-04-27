function Update-PanDeviceLocation {
<#
.SYNOPSIS
Refresh the PanDevice device-group or vsys (and shared) layout in the PanDevice Location property.
.DESCRIPTION
Refresh the PanDevice device-group (Panorama) or vsys (NGFW) layout (and shared) in the PanDevice Location property. Not saved to disk. Refreshed at runtime.
.NOTES
Update-PanDeviceLocation doe *not* add new device-groups or vsys's. It simply refreshes what already exists on-device into the PanDevice Location property.
Can force a manual update with -Force.
Refresh- is not an approved verb. Update- it is.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
None
.EXAMPLE
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
   param(
      [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='PanDevice(s) on which location layout (vsys, device-group) will be determined')]
      [PanDevice[]] $Device,
      [parameter(HelpMessage='Force location layout update, regardless of elapsed time since last update')]
      [Switch] $Force,
      [parameter(HelpMessage='Internal module use only. Performs location layout update, but does not trigger [re]serialize on changes.')]
      [Switch] $ImportMode
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
      
      # For comparison
      $Now = Get-Date
      $UpdateInterval = New-TimeSpan -Seconds $Global:PanDeviceLocRefSec
      # Seed the need to reserialize as $false
      $Dirty = $false
   } # Begin block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         Write-Debug ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
         if( (-not $PSBoundParameters.Force.IsPresent) -and $DeviceCur.LocationUpdated.AddSeconds($UpdateInterval.TotalSeconds) -gt $Now ) {
            # If PanDevice has been updated and interval has not passed, no need to update again
            Write-Debug ('{0}: Device: {1} locations updated already. Next update after {2}' -f
               $MyInvocation.MyCommand.Name,$DeviceCur.Name,$DeviceCur.LocationUpdated.AddSeconds($UpdateInterval.TotalSeconds))
            # Next iteration of foreach (next PanDevice)
            continue
         }

         # Ordered, case sensitive hashtable. Must initialize this way and *not* with [ordered]@{} to maintain case sensitivity
         $NewLocation = [System.Collections.Specialized.OrderedDictionary]::new()
         # Update shared first as it is the same for both Panorama and Ngfw
         $NewLocation.Add("shared", "/config/shared")

         # For broader compatibility between Panorama and NGFW, using the config action=complete capability with the XML-API
         # Originally, used an "@name" ending XPath to determine vsys and device-group list. Not ideal
         #  $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry/@name"
         # https://live.paloaltonetworks.com/t5/automation-api-discussions/retrieve-device-list-and-vsys-names-using-pan-rest-api/m-p/15238
         if($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/device-group"
            Write-Debug ('{0}: Device: {1} Panorama XPath: {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$XPath)
         }
         else {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys"
            Write-Debug ('{0}: Device: {1} NGFW XPath: {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$XPath)
         }
         
         # Fetch the valid device-group (Panorama) or vsys (NGFW) using config action=complete
         $R = Invoke-PanXApi -Device $DeviceCur -Config -Complete -XPath $XPath
         if($R.Status -eq 'success') {
            # XML-API response to config action=complete is in <response><completions> and NOT <response><result> like everything else
            # The [PanResponse] type does NOT include a named "Completions" property (like it does "Result")
            # We can get at <completions> through the [PanResponse] "WRContent" property (that exists for just this type of obscure purpose)
            #  <response status="success" code="19"><completions>
            #     <completion value="Child" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']"/>
            #     <completion value="Parent" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Parent']"/>
            #     <completion value="Grandparent" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Grandparent']"/>
            #  </completions></response>
            foreach($CompletionCur in $R.Response.completions.completion) {
               # Add each entry's name to an aggregate
               $NewLocation.Add($CompletionCur.value, $CompletionCur.vxpath)
            }

            # Compare New and Existing locations for equivalence to determine if there is a need to reserialize to disk
            if($DeviceCur.Location.Count -ne $NewLocation.Count) {
               # Different number of locations, need to reserialize
               $Dirty = $true
               # Update the PanDevice in memory
               $DeviceCur.Location = $NewLocation
               Write-Debug ('{0}: Device: {1} Location (Update): {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,($NewLocation.keys -join ','))
            }
            else {
               $Keys1 = $DeviceCur.Location.Keys
               $Keys2 = $NewLocation.Keys
               # Different keys or different values, need to reserialize
               foreach($Key1 in $Keys1) {
                  if(-not $Keys2.Contains($Key1)) {
                     $Dirty = $true
                  }
               }
            }

            if($Dirty) { 
               Write-Debug ('{0}: Device: {1} Dirty Location(s) (Updating): {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,($NewLocation.keys -join ','))
               # Update the PanDevice in memory
               $DeviceCur.Location = $NewLocation
            }
            else {
               Write-Debug ('{0}: Device: {1} Location(s) Clean (No Update)' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            }
            # Update LocationUpdated regardless to wait for another interval
            $DeviceCur.LocationUpdated = Get-Date

         } # End if PanResponse success
      } # End foreach DeviceCur
   } # Process block

   End {
      # If Dirty and ImportMode is not in play, reserialize to disk
      if($Dirty -and -not $PSBoundParameters.ImportMode.IsPresent) {
         Write-Debug ('{0}: Dirty. Serializing Required' -f $MyInvocation.MyCommand.Name)
         ExportPanDeviceDb
      }
   } # End block
} # Function
