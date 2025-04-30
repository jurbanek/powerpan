function Get-PanObject {
<#
.SYNOPSIS
Retrieve object(s) from Device
.DESCRIPTION
Retrieve all object(s) on a -Device, scope to a specific -Location(s), scope to a single case-sensitive  -Name, or specify a case-INsensitive search -Filter
.NOTES
Provides feature coverage for many object types. Should NOT be called by its name. Intended to be called by its aliases.
Find aliases: Get-Alias | Where-Object { $_.ResolvedCommandName -eq 'Get-PanObject' }

:: At-a-Glance ::
-Name parameter(s) are always case-sensitive in PowerPAN, for getting exact names if you know them
-Filter parameter is case-INsensitive in PowerPAN, just like PAN-OS GUI search bar
-InputObject is a syntactic nicety for refetching an object you already have (see example)

:: Filter ::
The -Filter parameter emulates the PAN-OS filter/search bar which is case-insensitive and searches across address object name, value, description, and tag.
Within PAN-OS itself, names are case-sensitive. PAN-OS search bar provides case-INsensitive search across name, value, description, and tag to be helpful.

For additional filtering capabilities within the local PowerShell session, pipe output to Where-Object (see examples).

:: IMPLEMENTATION NOTES ::
XPath References for base search, -Name search, and -Filter search for PanAddress objects. Other object types have slightly different suffixes and filters.
   Name: {0} becomes Name, as is
   Filter: {0} becomes Filter.ToLower()

Shared
/config/shared/address/entry
/config/shared/address/entry[@name='{0}]
/config/shared/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]

Panorama
/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry
/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry[@name='{0}]
/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]

Ngfw
/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry
/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[@name='{0}']
/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]

:: Panorama <entry loc='MyDeviceGroup' overrides='MyObject'> Attributes ::
Panorama can add two additional attributes to <entry>: loc and overrides
loc:
   - Some XPath queries return the content of the DG and all ancestor DG's (but not shared) weaved together
   - Conceivably to make it easier to "see" what objects are available for use
   - The loc attribute tracks the actual location where the object resides
overrides:
   - In cases where an object with the same name lives in both an ancestor and descendant, the descendant is considered an ovverride
   - The overrides attribute tracks which ancestor is being overriden
   - If MyObj in Child is overriding MyObj in Parent, then <entry name="MyObj" loc="Child" overrides="Parent">stuff</entry>

To perform *server-side* filtering, XPath needs to end in /entry for stuff like /entry[@name='H-1.1.1.1']
/entry with single slashes returns full lineage including ancestors with "loc" and "overrides" attributes
//entry with double slashes returns only the contents of the location *without* "loc" and "overrides" attributes

Returning full lineage is greater data transfer and local processing, but grants visibility into "overrides" without having to compute locally

This cmdlet returns full lineage for overrides visibility, then filters locally only returning specified locations.

:: Panorama Single-Slash and Double-Slash XPath ::
Grandparent device-group contains a H-1.1.1.1 address object
Parent device-group is *empty* and an ancestor of Grandparent
Child device-group is *empty* and an ancestor of Parent

:::: /address (no /entry)::::
action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']/address
Returns: <result><address/></result>
- No /entry on the end of XPath. Empty list as it should be. Panorama display DG container as it really exists
- Works great, but no server-side filtering support

:::: /address/entry ::::
action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']/address/entry
Returns: <result><entry name="H-1.1.1.1" loc="Grandparent"><ip-netmask>1.1.1.1</ip-netmask><disable-override>no</disable-override></entry></result>
- Search in Child DG with /address/entry on the end. Child is actually empty, but an entry returned with loc="Grandparent"
- Might be useful for some cases (like the PAN-OS GUI), but not what we want for PowerPAN

:::: Double Slash ::::
"Double slash" //entry. a.k.a. XPath descendant operator

:::: /address//entry ::::
action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Grandparent']/address//entry
action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Grandparent']/address//entry[@name='H-1.1.1.1']
Both return: <result><entry name="H-1.1.1.1"><ip-netmask>1.1.1.1</ip-netmask><disable-override>no</disable-override></entry></result>
- "Double slash" on //entry. Query Grandparent (where object actually lives). Object is returned without loc attribute.

action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']/address//entry
action=get XPath=/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']/address//entry[@name='H-1.1.1.1']
Both return: <result/>
   - Double "slash" on //entry. Query Child and it returns empty.

:: Single Slash Performance ::
This cmdlet uses single slash /entry to get overrides attribute and filters out ancestors locally.
Originally thought it would be too time consuming to have to transfer and filter so much locally.
Performance tested a three-deep device-group
Grandparent (10,000 address objects)
   Parent
      Child
Pulling all device-groups using single-slash /address/entry (Get-PanAddress -Device $Panorama) is 10,000 objects 3 times for 30,000, throwing out 20,000
Took on average 4.1 seconds with screen paint
Took on average 2.4 seconds without screen paint
Computers are fast. Overrides attribute and code simplicity is worth using single slash.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
PanService[]
   You can pipe a PanService to this cmdlet
PanAddressGroup[]
   You can pipe a PanAddressGroup to this cmdlet
PanServiceGroup[]
   You can pipe a PanServiceGroup to this cmdlet
.OUTPUTS
PanAddress
PanService
PanAddressGroup
PanServiceGroup
.EXAMPLE
Get-PanDevice "10.0.0.1" | Get-PanAddress

Get all addresses in all locations (vsys, device-group, shared) on PanDevice 10.0.0.1.
If it is taking too long on very large devices, use the -Filter parameter for remote filtering to reduce remote and local processing.
.EXAMPLE
$D = Get-PanDevice "fw.lab.local"
Get-PanAddress -Device $D -Location vsys1

Get all addresses in vsys1 on PanDevice fw.lab.local. With no -Location parameter, all locations on the PanDevice are searched.
Panorama device-groups are case-sensitive. The -Location parameter has to be case-sensitive.
.EXAMPLE
Get-PanDevice "fw.lab.local" | Get-PanAddress -Filter "10.16"

Get all addresses that have matching name, value, description, or tag matching the filter string, case insensitive.
Filtering is done remotely and greatly speeds up further local processing of objects.
The filter string is case insensitive, just like the PAN-OS GUI search bar.
No -Location is specified, so all locations are searched on the PanDevice.
.EXAMPLE
$D = Get-PanDevice "panorama.lab.local"
Get-PanAddress -Device $D -Location "shared","Parent","Child" -Name "ImportantHost" | 

Address objects exactly named "ImportantHost" in Panorama shared, Parent device-group, Child device-group.

If an object appears in shared and a device-group, it is an override.
.EXAMPLE
$D = Get-PanDevice "panorama.lab.local"
Get-PanAddress -Device $D -Location "shared","Parent","Child" | Where-Object {$_.Type -eq 'fqdn' -and $_.Value -like "*amazon*"}

All address objects on Panorama shared, Parent device-group, Child device-group that are of type fqdn and value includes "amazon"

On a large Panorma (or NGFW), consider using the -Filter keyword to remotely filter prior to local filtering with Where-Object
.EXAMPLE
# Guaranteed to return 0 or 1 address objects
$A = Get-PanAddress -Device $D -Location vsys1 -Name "H-1.1.1.1"
# Update the tag
$A.Tag = "risky"
# Apply changes to candidate config
$A | Set-PanAddress
# Use -InputObject (via pipe) to verify it "took" without having to respecify -Device, -Location, -Filter, etc.
# Useful when working interactively on PowerShell CLI
$A | Get-PanAddress

To update the local variable as well
$A = $A | Get-PanAddress

Syntactic sugar for fetching an object recently set with less typing.
#>
   [CmdletBinding(DefaultParameterSetName='Device-NoFilter')]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device-NoFilter',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]   
      [parameter(Mandatory=$true,ParameterSetName='Device-Filter',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]
      [parameter(Mandatory=$true,ParameterSetName='Device-Name',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device-Filter',HelpMessage='Case-INsensitive property filter (see notes for detail). Filtered remotely (API)')]
      [String] $Filter,
      [parameter(Mandatory=$true,ParameterSetName='Device-Name',HelpMessage='Exact match object name. Matched remotely (API)')]
      [String] $Name,
      [parameter(ParameterSetName='Device-NoFilter',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [parameter(ParameterSetName='Device-Filter',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [parameter(ParameterSetName='Device-Name',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [String[]] $Location,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) to be retrieved')]
      [PanObject[]] $InputObject
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0} (as {1}):' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName)

      # Terminating error if called directly. Use a supported alias.
      if($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
         $Alias = (Get-Alias | Where-Object {$_.ResolvedCommandName -eq $($MyInvocation.MyCommand.Name)} | Select-Object -ExpandProperty Name) -join ','
         Write-Error ('{0} called directly. {0} MUST be called by an alias: {1}' -f $MyInvocation.MyCommand.Name,$Alias) -ErrorAction Stop
      }

      switch -Wildcard ($PSCmdlet.ParameterSetName) {
         '*-NoFilter'   { Write-Verbose ('{0} (as {1}): No Filter Applied' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName); continue }
         '*-Filter'     { Write-Verbose ('{0} (as {1}): Filter Applied "{2}"' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$PSBoundParameters.Filter); continue }
         '*-Name'       { Write-Verbose ('{0} (as {1}): Exact match Name Applied "{2}"' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$PSBoundParameters.Name); continue}
      }

      # Aggregate to hold objects until End {} block. See note at end
      switch ($MyInvocation.InvocationName) {
         'Get-PanAddress'        { $ObjAgg = [System.Collections.Generic.List[PanAddress]]@(); continue }
         'Get-PanService'        { $ObjAgg = [System.Collections.Generic.List[PanService]]@(); continue }
         'Get-PanAddressGroup'   { $ObjAgg = [System.Collections.Generic.List[PanAddressGroup]]@(); continue }
         'Get-PanServiceGroup'   { $ObjAgg = [System.Collections.Generic.List[PanServiceGroup]]@(); continue }
      }

      # Define XPath suffixes to be appended to PanDevice.Location(s), based on object type
      # Each object type gets it's own set of suffixes, but the same set of suffixes are used whether Panorama or NGFW (which is nice) 
      switch ($MyInvocation.InvocationName) {
         'Get-PanAddress' {
            # NoFilter (no search filter)
            $XPathSuffixBase = "/address/entry"
            # Filter (search filter)
            $XPathSuffixFilter = "/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
            # Name (exact)
            $XPathSuffixName = "/address/entry[@name='{0}']"
            continue
         }
         'Get-PanService' {
            # NoFilter (no search filter)
            $XPathSuffixBase = "/service/entry"
            # Filter (search filter)
            $XPathSuffixFilter = "/service/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/tcp/source-port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/tcp/port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/udp/source-port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/udp/port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/sctp/source-port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(protocol/sctp/port, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
            # Name (exact)
            $XPathSuffixName = "/service/entry[@name='{0}']"
            continue
         }
         'Get-PanAddressGroup' {
            # NoFilter (no search filter)
            $XPathSuffixBase = "/address-group/entry"
            # Filter (search filter)
            $XPathSuffixFilter = "/address-group/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(static, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
            # Name (exact)
            $XPathSuffixName = "/address-group/entry[@name='{0}']"
            continue
         }
         'Get-PanServiceGroup' {
            # NoFilter (no search filter)
            $XPathSuffixBase = "/service-group/entry"
            # Filter (search filter)
            $XPathSuffixFilter = "/service-group/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(members, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
            # Name (exact)
            $XPathSuffixName = "/service-group/entry[@name='{0}']"
            continue
         }
      }
   } # Begin Block

   Process {
      # InputObject ParameterSetName
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Verbose ('{0} (as {1}): InputObject Device: {2} XPath: {3}' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$InputObjectCur.Device.Name,$InputObjectCur.XPath)
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Get -XPath $InputObjectCur.XPath
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Panorama includes ancestors in responses (not ideal, see NOTES) and denotes them as <entry name='name' loc='Ancestor-DG'>
               # Limit <entry> to searched device-group only by matching desired loc attribute, or if in shared loc will not exist as shared has no ancestors
               if($InputObjectCur.Device.Type -eq [PanDeviceType]::Panorama) {
                  $Entry = $R.Response.result.entry | Where-Object {$_.loc -ceq $InputObjectCur.Location -or [String]::IsNullOrEmpty($_.loc)}
               }
               elseif($InputObjectCur.Device.Type -eq [PanDeviceType]::Ngfw) {
                  $Entry = $R.Response.result.entry
               }
               Write-Verbose ('{0} (as {1}): API return entry count: {2} Post-"loc" attribute filter: {3}' -f
                  $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$R.Response.result.entry.Count,$Entry.Count)
               # Build new object based on InvocationName. Only one object given InputObject, no loop required
               [System.Xml.XmlDocument]$XDoc = $Entry.OuterXml
               $XPath = $InputObjectCur.XPath
               switch ($MyInvocation.InvocationName) {
                  'Get-PanAddress'        { $ObjAgg.Add([PanAddress]::new($InputObjectCur.Device, $XPath, $XDoc)); continue }
                  'Get-PanService'        { $ObjAgg.Add([PanService]::new($InputObjectCur.Device, $XPath, $XDoc)); continue }
                  'Get-PanAddressGroup'   { $ObjAgg.Add([PanAddressGroup]::new($InputObjectCur.Device, $XPath, $XDoc)); continue }
                  'Get-PanServiceGroup'   { $ObjAgg.Add([PanServiceGroup]::new($InputObjectCur.Device, $XPath, $XDoc)); continue }
               } # switch
            } 
            else {
               Write-Error ('Error retrieving InputObject [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$R.Status,$R.Code,$R.Message)
            }
         } # foreach InputObject
      } # ParameterSetName
      
      # NoFilter and Filter ParameterSetName
      else {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ('{0} (as {1}): Device: {2}' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$DeviceCur.Name)
            # Update Location if past due
            if($PSBoundParameters.Device.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $PSBoundParameters.Device }
            # If PanDevice Location(s) are missing, move on. Should not happen under normal circumstances but could by accident if users
            # are assigning Locations manually. Splash a nice warning and move on.
            if(-not ($DeviceCur.Location.Count -ge 1)) {
               Write-Warning ('{0} (as {1}): Device: {2} Location(s) are missing. Manually run Update-PanDeviceLocation' -f
                  $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$DeviceCur.Name)
               # Jump to the next DeviceCur as there is nothing we can do for this DeviceCur
               continue
            }

            # Time to build two sets of hashtables based on suffixes defined above and ParameterSet
            # Hashtable Key is the location (vys1,shared,MyDG), Hashtable Value is the usable XPath
            # Search (base) is used when NO -Filter is specified. Also used to build the XPath when passing to object constructor further down
            # SearhCustom is used when -Filter or -Name is specified to specify remote API search specifics (no local filtering)
            # Case SENSITIVE ordered hashtables are used as Panorama device-groups are case sensitive "Grandparent" and "grandparent" to discrete DG's
            $Search = [System.Collections.Specialized.OrderedDictionary]::new()
            $SearchCustom = [System.Collections.Specialized.OrderedDictionary]::new()
            
            # If -Location, limit the searches to the valid Locations specified
            if($PSBoundParameters.Location) {
               foreach($LocationCur in $PSBoundParameters.Location) {
                  # -cin for case-sensitive match
                  if($LocationCur -cin $DeviceCur.Location.Keys) {
                     $NewXPath = $DeviceCur.Location.($LocationCur) + $XPathSuffixBase
                     $Search.Add($LocationCur, $NewXPath)
                     # With the -Filter parameter as format string input into the contains(translate()) XPath voodoo
                     # Note the Filter string is ToLower() to align with the XPath translate()
                     if($PSCmdlet.ParameterSetName -like '*-Filter') {
                        $NewXPathCustom = ($DeviceCur.Location.($LocationCur) + $XPathSuffixFilter) -f $PSBoundParameters.Filter.ToLower()
                        $SearchCustom.Add($LocationCur, $NewXPathCustom)
                     }
                     # With the -Name parameter as format string input into the contains() portion
                     # Note the Name string is as-is, NO ToLower()
                     elseif($PSCmdlet.ParameterSetName -like '*-Name') {
                        $NewXPathCustom = ($DeviceCur.Location.($LocationCur) + $XPathSuffixName) -f $PSBoundParameters.Name
                        $SearchCustom.Add($LocationCur, $NewXPathCustom)
                     }
                  }
               }
               Write-Verbose ('{0} (as {1}): Location Search(Limited): {2}' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,($Search.Keys -join ','))
            }
            
            # No -Location specified, search all Locations on the PanDevice
            else {
               foreach($LocationCur in $DeviceCur.Location.GetEnumerator()) {
                  $NewXPath = $DeviceCur.Location.($LocationCur.Key) + $XPathSuffixBase
                  $Search.Add($LocationCur.Key, $NewXPath)
                  # With the -Filter parameter as input into the contains(translate()) XPath voodoo
                  # Note the Filter string is ToLower() to align with the XPath translate()
                  if($PSCmdlet.ParameterSetName -like '*-Filter') {
                     $NewXPathCustom = ($DeviceCur.Location.($LocationCur.Key) + $XPathSuffixFilter) -f $PSBoundParameters.Filter.ToLower()
                     $SearchCustom.Add($LocationCur.Key, $NewXPathCustom)
                  }
                  # With the -Name parameter as format string input into the contains() portion
                  # Note the Name string is as-is, NO ToLower()
                  elseif($PSCmdlet.ParameterSetName -like '*-Name') {
                     $NewXPathCustom = ($DeviceCur.Location.($LocationCur.Key) + $XPathSuffixName) -f $PSBoundParameters.Name
                     $SearchCustom.Add($LocationCur.Key, $NewXPathCustom)
                  }
               }
            }
            # Finished building the Search and SearchCustom XPaths
   
            # Call the API. The actual search used ($Search or $SearchCustom) is determined by ParameterSetName
            foreach($SearchCur in $(if($PSCmdlet.ParameterSetName -like '*-Filter' -or $PSCmdlet.ParameterSetName -like '*-Name'){ $SearchCustom.GetEnumerator() } else{ $Search.GetEnumerator() })) {
               Write-Verbose ('{0} (as {1}): Device: {2} Type: {3} Location: {4} XPath: {5}' -f
                  $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$DeviceCur.Name,$DeviceCur.Type,$SearchCur.Key,$SearchCur.Value)
               
               $R = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $SearchCur.Value
               
               if($R.Status -eq 'success') {
                  # Panorama includes ancestors in responses (see NOTES) and denotes them as <entry name='name' loc='Ancestor-DG'>
                  # Limit <entry> to searched device-group only by matching desired loc attribute, or if in shared loc will not exist as shared has no ancestors
                  if($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
                     $Entry = $R.Response.result.entry | Where-Object {$_.loc -ceq $SearchCur.Key <#Panorama DG's#> -or [String]::IsNullOrEmpty($_.loc) <#Panorama shared#>}
                  }
                  elseif($DeviceCur.Type -eq [PanDeviceType]::Ngfw) {
                     $Entry = $R.Response.result.entry
                  }
                  Write-Verbose ('{0} (as {1}): API return entry count: {2} Post-"loc" attribute filter: {3}' -f
                     $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$R.Response.result.entry.Count,$Entry.Count)
                  
                  foreach($EntryCur in $Entry) {
                     # Build new object based on InvocationName
                     [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                     # Regardless of "search XPath" used, the base XPath is used to form the object's XPath
                     # to avoid the contains() and translate() substrings
                     $XPath = "{0}[@name='{1}']" -f $Search.($SearchCur.Key),$EntryCur.name
                     switch ($MyInvocation.InvocationName) {
                        'Get-PanAddress'        { $ObjAgg.Add([PanAddress]::new($DeviceCur, $XPath, $XDoc)); continue }
                        'Get-PanService'        { $ObjAgg.Add([PanService]::new($DeviceCur, $XPath, $XDoc)); continue }
                        'Get-PanAddressGroup'   { $ObjAgg.Add([PanAddressGroup]::new($DeviceCur, $XPath, $XDoc)); continue }
                        'Get-PanServiceGroup'   { $ObjAgg.Add([PanServiceGroup]::new($DeviceCur, $XPath, $XDoc)); continue }
                     }
                  } # foreach entry
               } # if Reponse success
               else {
                  Write-Error ('Error retrieving objects on {0}/{1} XPath: {2} Status: {3} Code: {4} Message: {5}' -f
                     $DeviceCur.Name,$SearchCur.Key,$SearchCur.Value,$R.Status,$R.Code,$R.Message)
               }
            } # foreach Search/SearchFilter
         } # foreach Device
      } # ParameterSetName
   } # Process block
   End {
      # Objects are aggrated during Process block and NOT sent to pipeline immediately when they are found. It's for a reason, and a wild one
      # Setup: "MyAddress" currently located in shared
      # Get-PanAddress -Device $D -Name "MyAddress" | Move-PanAddress -DstLocation vsys1
      # If Get-PanAddress were to send to pipeline in Process block:
      #  1) MyAddress would be found in shared and the (shared) MyAddress would be moved to vsys1 successfully
      #  2) Get-PanAddress would then find MyAddress again in vsys1 on the iteration through vsys1 and pipe the (vsys1) MyAddress to Move-PanAddress -DstLocation vsys1
      #       Context: Since the Get-PanAddress call does not specify a -Location (it's optional), all Locations (shared, vsys1, vsys2, etc.) are searched
      #  3) The Move- from vsys1 to vsys1 produces an error.
      # Easiest way to avoid this situation is to aggregate the results in Get- and output at the end. :(
      foreach($ObjCur in $ObjAgg) {
         $ObjCur
      }
   } # End block
} # Function
