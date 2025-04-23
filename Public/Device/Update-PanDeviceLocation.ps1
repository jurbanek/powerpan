function Update-PanDeviceLocation {
<#
.SYNOPSIS
Refresh the PanDevice device-group or vsys (and shared) layout in the PanDevice Location property.
.DESCRIPTION
Refresh the PanDevice device-group (Panorama) or vsys (NGFW) layout (and shared) in the PanDevice Location property. Not saved to disk. Refreshed at runtime.
.NOTES
Update-PanDeviceLocation doe *not* add new device-groups or vsys's. It simply refreshes what already exists on-device into the PanDevice Location property.
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
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) on which location layout (vsys, device-group) will be determined')]
      [PanDevice[]] $Device
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         Write-Debug ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
         if($DeviceCur.LocationUpdated) {
            # If PanDevice has been updated this PowerShell session, no need to update again
            Write-Debug ('{0}: Device location updated already' -f $MyInvocation.MyCommand.Name)
            # Next iteration of foreach (next PanDevice)
            continue
         }

         # Ordered, case sensitive hashtable. Must initialize this way and *not* with [ordered]@{} to maintain case sensitivity
         $DeviceCurLocation = [System.Collections.Specialized.OrderedDictionary]::new()
         # Update shared first as it is the same for both Panorama and Ngfw
         $DeviceCurLocation.Add("shared", "/config/shared")

         # For broader compatibility between Panorama and NGFW, using the config action=complete capability with the XML-API
         # Originally, used an "@name" ending XPath to determine vsys and device-group list. Not ideal
         #  $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry/@name"
         # https://live.paloaltonetworks.com/t5/automation-api-discussions/retrieve-device-list-and-vsys-names-using-pan-rest-api/m-p/15238
         if($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/device-group"
            Write-Debug ('{0}: Panorama XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPath)
         }
         else {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys"
            Write-Debug ('{0}: NGFW XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPath)
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
            $CustomResponse = [System.Xml.XmlDocument]$R.WRContent
            foreach($CompletionCur in $CustomResponse.response.completions.completion) {
               # Add each entry's name to an aggregate
               $DeviceCurLocation.Add($CompletionCur.value, $CompletionCur.vxpath)
            }

            # Update the PanDevice
            if($PSCmdlet.ShouldProcess('PanDeviceDb','Update ' + $DeviceCur.Name + ' vsys/device-group layout')) {
               $DeviceCur.Location = $DeviceCurLocation
               Write-Debug ('{0}: Device: {1} Location (Update): {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,($DeviceCurLocation.keys -join ','))
               $DeviceCur.LocationUpdated = $true
            }
         } # End if PanResponse success
      } # End foreach DeviceCur
   } # Process block

   End {
   } # End block
} # Function
