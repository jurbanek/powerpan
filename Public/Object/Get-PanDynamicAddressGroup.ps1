function Get-PanDynamicAddressGroup {
<#
.SYNOPSIS
Retrieve PanDynamicAddressGroup with its dynamic members.
.DESCRIPTION
Retrieve PanDynamicAddressGroup populated with its dynamic members.

The contents of dynamic address groups (DAG) can ony be known at runtime. Use this cmdlet to determine DAG members.

A call to Get-PanAddressGroup (not dynamic one) will get all address groups, static and dynamic. Static groups
have their static members included, dynamic group member property will be empty. This cmdlet is able to runtime
fetch DAG membership.
.NOTES
The primary reason this cmdlet exists is because DAG's can be defined in Panorama but need to be runtime viewed on the
firewalls. Get-PanAddressGroup (not dynamic one) can fetch all address group definitions (including static and dynamic)
but membership is only available for static. After attempting to "hack-in" the ability to fetch DAG membership but it
got too user-experience clumsy when the DAG was defined in Panorama but needed to see the runtime membership on the
firewall. Alas, this cmdlet was born.

Running this cmdlet against Panorama doesn't produce very useful output since Panorama itself does not populate DAG's
This cmdlet should be run against firewalls.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
PanDynamicAddressGroup[]
   You can pipe a PanDynamicAddressGroup to this cmdlet
.OUTPUTS
PanDynamicAddressGroup
.EXAMPLE
$D = Get-PanDevice "fw.lab.local"
Get-PanDynamicAddressGroup -Device $D -Name "MyDAG"
.EXAMPLE
Get-PanDevice "fw.lab.local" |
   Get-PanAddressGroup -Name "MyDAG" |
      Get-PanDynamicAddressGroup

PowerShell one-liner
.EXAMPLE
$P = Get-PanDevice "panorama.lab.local"
$D = Get-PanDevice "fw.lab.local"
# Grab the address group defined in Panorama
$AG = Get-PanAddress -Device $P -Location "Grandparent" -Name "MyDAG"
# But query the firewall for runtime DAG members
$DAG = Get-PanDynamicAddressGroup -Device $D -Name "MyDAG"

This type of example is a primary reason why this cmdlet exists... DAG's can be defined in Panorama
but need to be runtime viewed on the firewalls. Unfortunately, that specific use case can't be
completed as a one-liner.
#>
   [CmdletBinding(DefaultParameterSetName='Device')]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]
      [PanDevice[]] $Device,
      [parameter(ParameterSetName='Device',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [String[]] $Location,
      [parameter(ParameterSetName='Device',HelpMessage='Exact match object name. Matched remotely (API)')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) to be retrieved')]
      [PanObject[]] $InputObject
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   } # Begin Block

   Process {
      # InputObject ParameterSetName
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Verbose ('{0}: InputObject Device: {1} InputObject Name: {2} Type: {3}' -f
               $MyInvocation.MyCommand.Name,$InputObjectCur.Device.Name,$InputObjectCur.Name,$InputObjectCur.GetType())
            
            # InputObject is of type PanObject which will accept more types than acceptable. Check.
            if($InputObjectCur -isnot [PanAddressGroup] -and $InputObjectCur -isnot [PanDynamicAddressgroup]) {
               Write-Error('InputObject must be type [PanAddressGroup] or [PanDynamicAddressGroup]')
               # Next iteration
               continue
            }
            
            $Cmd = '<show><object><dynamic-address-group><name>{0}</name></dynamic-address-group></object></show>' -f $InputObjectCur.Name
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Op -Cmd $Cmd
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Ngfw and Panorama require different parsing
               if($InputObjectCur.Device.Type -eq [PanDeviceType]::Ngfw) {
                  # Ngfw Response
                  # <response cmd="status" status="success">
                  # <result>
                  #   <dyn-addr-grp>
                  #     <entry>
                  #       <vsys>vsys1</vsys>
                  #       <group-name>DAG-Infected</group-name>
                  #       <filter>'infected'</filter>
                  #       <member-list>
                  #         <entry name="1.2.2.2" type="registered-ip"/>
                  #       </member-list>
                  #     </entry>
                  #     <entry>
                  #       <vsys>vsys1</vsys>
                  #       <group-name>DAG-Quarantine</group-name>
                  #       <filter>'infected' or 'risky'</filter>
                  #       <member-list>
                  #         <entry name="H-1.2.3.4" type="address-object"/>
                  #         <entry name="1.2.2.2" type="registered-ip"/>
                  #       </member-list>
                  #     </entry>
                  #     <entry>
                  #       <group-name>DAG-Quarantine-Shared</group-name>
                  #         <filter>'infected' or 'risky'</filter>
                  #         <member-list>
                  #           <entry name="H-1.2.3.4" type="address-object"/>
                  #           <entry name="1.2.2.2" type="registered-ip"/>
                  #         </member-list>
                  #     </entry>
                  #   </dyn-addr-grp>
                  # </result>
                  # </response>

                  $Entry = $R.Response.result.'dyn-addr-grp'.entry
                  Write-Verbose ('{0}: API return entry count: {1}' -f $MyInvocation.MyCommand.Name,$Entry.Count)

                  foreach($EntryCur in $Entry) {
                     $XDoc = [System.Xml.XmlDocument]$EntryCur.OuterXml
                     # Send to pipeline
                     [PanDynamicAddressGroup]::new($InputObjectCur.Device,$XDoc)
                  }
               } # if Ngfw

               elseif($InputObjectCur.Device.Type -eq [PanDeviceType]::Panorama) {
                  # Panorama Response (odd, indeed)
                  # Location is entry name attribute, but need to manually replicate entry Constructor call
                  # DAG Name is address-group name attribute
                  # 
                  # <response status="success">
                  # <result>
                  #   <device-groups>
                  #     <entry name="shared">
                  #      <address-group name="DynamicGroupShared1">
                  #        <filter>'black'</filter>
                  #        <member-list/>
                  #      </address-group>
                  #      <address-group name="DynamicGroupShared2">
                  #        <filter>'black'</filter>
                  #        <member-list/>
                  #      </address-group>
                  #    </entry>
                  #    <entry name="Grandparent">
                  #      <address-group name="DynamicGroupGrandParent1">
                  #        <filter>'black'</filter>
                  #        <member-list/>
                  #      </address-group>
                  #    </entry>
                  #   </device-groups>
                  # </result>
                  # </response>
                  
                  Write-Warning ('{0}: Running this cmdlet against Panorama does not produce reliable output' -f $MyInvocation.MyCommand.Name)
                  
                  $DgEntry = $R.Response.result.'device-groups'.entry
                  Write-Verbose ('{0}: API return device-group entry count: {1}' -f $MyInvocation.MyCommand.Name,$DgEntry.Count)
                  foreach($DgEntryCur in $DgEntry) {
                     foreach($AgCur in $DgEntryCur.'address-group') {
                        Write-Verbose ('{0}: API return device-group: {1} address-group entry count: {2}' -f $MyInvocation.MyCommand.Name,$DgEntryCur.Name,$DgEntryCur.'address-group'.Count)
                        # Create a new entry with name attribute representing the location
                        $S = '<entry name="{0}"></entry>' -f $DgEntryCur.name
                        $XDoc = [System.Xml.XmlDocument]$S
                        # Import the inner <address-group> with deep-copy
                        $ImportedNode = $XDoc.ImportNode($AgCur,$true)
                        # Append
                        $XDoc.Item('entry').AppendChild($ImportedNode) | Out-Null
                        # Send to pipeline
                        [PanDynamicAddressGroup]::new($InputObjectCur.Device,$XDoc)
                     }
                  }
               } # elseif Panorama
            } 
            else {
               Write-Error ('Error retrieving InputObject {0} on {1} Status: {2} Code: {3} Message: {4}' -f
                  $InputObjectCur.Name,$InputObjectCur.Device.Name,$R.Status,$R.Code,$R.Message)
            }
         } # foreach InputObject
      } # InputObject ParameterSetName

      # Device ParameterSetName
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            # Update Location if past due
            if($DeviceCur.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $DeviceCur }
            # If PanDevice Location(s) are missing, move on. Should not happen under normal circumstances but could by accident if users
            # are assigning Locations manually. Splash a nice warning and move on.
            if(-not ($DeviceCur.Location.Count -ge 1)) {
               Write-Warning ('{0}: Device: {1} Location(s) are missing. Manually run Update-PanDeviceLocation' -f
                  $MyInvocation.MyCommand.Name,$DeviceCur.Name)
               # Jump to the next DeviceCur as there is nothing we can do for this DeviceCur
               continue
            }

            # XML API does not provide the ability to server-side search for location, so we will simulate it
            if(-not [String]::IsNullOrEmpty($PSBoundParameters.Name)) {
               $Cmd = '<show><object><dynamic-address-group><name>{0}</name></dynamic-address-group></object></show>' -f $PSBoundParameters.Name
            }
            else {
               $Cmd = '<show><object><dynamic-address-group><all></all></dynamic-address-group></object></show>'
            }

            $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Ngfw and Panorama require different parsing
               # Ngfw
               if($DeviceCur.Type -eq [PanDeviceType]::Ngfw) {
                  if(-not [String]::IsNullOrEmpty($PSBoundParameters.Location)) {
                     # <vsys>vsys1</vsys>, etc
                     $Entry = $R.Response.result.'dyn-addr-grp'.entry | Where-Object {$_.vsys -in $PSBoundParameters.Location}
                     
                     # Special condition for shared, <vsys> will be missing, that's how shared is indicated
                     if('shared' -in $PSBoundParameters.Location) {                        
                        $Entry += $R.Response.result.'dyn-addr-grp'.entry | Where-Object {[String]::IsNullOrEmpty($_.vsys)}
                     }
                  }
                  else {
                     # else Entry stays the same as Location is not defined
                     $Entry = $R.Response.result.'dyn-addr-grp'.entry
                  }

                  Write-Verbose ('{0}: API return entry count: {1} Post-Location Filter count: {2}' -f
                     $MyInvocation.MyCommand.Name,$R.Response.result.'dyn-addr-grp'.entry.Count,$Entry.Count)
                  
                  foreach($EntryCur in $Entry) {
                     [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                     # Send to pipeline
                     [PanDynamicAddressGroup]::new($DeviceCur,$XDoc)
                  }
               }
               # Panorama
               elseif($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
                  Write-Warning ('{0}: Running this cmdlet against Panorama does not produce reliable output' -f $MyInvocation.MyCommand.Name)

                  if(-not [String]::IsNullOrEmpty($PSBoundParameters.Location)) {
                     # Filter based on Location parameter
                     $DgEntry = $R.Response.result.'device-groups'.entry | Where-Object {$_.name -in $PSBoundParameters.Location}
                  }
                  else {
                     # else DgEntry stays the same as Location is not defined
                     $DgEntry = $R.Response.result.'device-groups'.entry
                  }
                  
                  Write-Verbose ('{0}: API return device-group entry count: {1} Post-Location Filter count: {2}' -f
                     $MyInvocation.MyCommand.Name,$R.Response.result.'device-groups'.entry,$DgEntry.Count)
                  
                  foreach($DgEntryCur in $DgEntry) {
                     foreach($AgCur in $DgEntryCur.'address-group') {
                        Write-Verbose ('{0}: API return device-group: {1} address-group entry count: {2}' -f $MyInvocation.MyCommand.Name,$DgEntryCur.Name,$DgEntryCur.'address-group'.Count)
                        # Create a new entry with name attribute representing the location
                        $S = '<entry name="{0}"></entry>' -f $DgEntryCur.name
                        $XDoc = [System.Xml.XmlDocument]$S
                        # Import the inner <address-group> with deep-copy
                        $ImportedNode = $XDoc.ImportNode($AgCur,$true)
                        # Append
                        $XDoc.Item('entry').AppendChild($ImportedNode) | Out-Null
                        # Send to pipeline
                        [PanDynamicAddressGroup]::new($DeviceCur,$XDoc)
                     }
                  }
               }
            }
            # API call not successful 
            else {
               Write-Error ('Error retrieving PanDynamicAddressGroup Cmd: {0} on {1} Status: {2} Code: {3} Message: {4}' -f
                  $Cmd,$DeviceCur.Name,$R.Status,$R.Code,$R.Message)
            }
            
         } # foreach Device
      } # ParameterSetName
   
   } # Process block
   
   End {
   } # End block
} # Function
