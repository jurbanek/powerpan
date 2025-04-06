function Update-PanDeviceLocation {
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

      # Initialize PanDeviceDb
      InitializePanDeviceDb

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

         # Originally used an "@name" ending XPath (link below)
         # https://live.paloaltonetworks.com/t5/automation-api-discussions/retrieve-device-list-and-vsys-names-using-pan-rest-api/m-p/15238
         # $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry/@name"
         # For broader compatibility between Panorama and NGFW instead using the config action=complete capability with the XML-API
         if($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/device-group"
            Write-Debug ('{0}: Panorama XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPath)
         }
         else {
            $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys"
            Write-Debug ('{0}: NGFW XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPath)
         }
         
         $DeviceCurLocationAgg = @()

         # Fetch the valid vsys (NGFW) or device-group (Panorama) using the relatively obscure config action=complete
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Config -Complete -XPath $XPath
         if($PanResponse.Status -eq 'success') {
            # XML-API response to config action=complete is in <response><completions> and NOT <response><result> like everything else
            # The [PanResponse] type does NOT include a named "Completions" property (like it does "Result")
            # We can get at <completions> through the [PanResponse] "WRContent" property (that exists for just this type of obscure purpose)
            #  <response status="success" code="19"><completions>
            #     <completion value="Child" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']"/>
            #     <completion value="Parent" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Parent']"/>
            #     <completion value="Grandparent" vxpath="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Grandparent']"/>
            #  </completions></response>
            $CustomResponse = [System.Xml.XmlDocument]$PanResponse.WRContent
            foreach($CompletionCur in $CustomResponse.response.completions.completion) {
               # Add each entry's name to an aggregate. In most firewalls there is a single entry with name 'vsys1'
               $DeviceCurLocationAgg += $CompletionCur.value
            }

            # Update the PanDevice in PanDeviceDb
            if($PSCmdlet.ShouldProcess('PanDeviceDb','Update ' + $DeviceCur.Name + ' vsys/device-group layout')) {
               $DeviceCur.Location = $DeviceCurLocationAgg
               Write-Debug ('{0}: Device: {1} Location (Update): {2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,($DeviceCurLocationAgg -join ','))
               $DeviceCur.LocationUpdated = $true
            }
         }
      }
   } # Process block

   End {
   } # End block
} # Function
