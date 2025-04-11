function Get-PanObject {
<#
.SYNOPSIS
Retrieve objects (multiple types) from PanDevice
.DESCRIPTION
Get-PanObjectGet all address objects from a PanDevice or specify the -Filter parameter for a remote (not local) filtered search
.NOTES
Get-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases:
   Get-PanAddress
   ...

:: At-a-Glance ::
-Name parameter(s) are always case-sensitive in PowerPAN, for getting exact names if you know them
-Filter parameter is case-INsensitive in PowerPAN, just like PAN-OS GUI search bar
-InputObject is a syntactic nicety for refetching an object you already have (see example)

:: Filter ::
The -Filter parameter emulates the PAN-OS filter/search bar which is case-insensitive and searches across address object name, value, description, and tag.
Within PAN-OS itself, names are case-sensitive. PAN-OS search bar provides case-INsensitive search across name, value, description, and tag to be helpful.

For additional filtering capabilities within the local PowerShell session, pipe output to Where-Object (see example).

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
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
.OUTPUTS
PanAddress
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
      [parameter(Mandatory=$true,ParameterSetName='Device-NoFilter',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be retrieved.')]   
      [parameter(Mandatory=$true,ParameterSetName='Device-Filter',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be retrieved.')]
      [parameter(Mandatory=$true,ParameterSetName='Device-Name',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be retrieved.')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device-Filter',HelpMessage='Case-INsensitive name, value, description, tag filter. Filter applied remotely (via API) identical to GUI filter bar behavior.')]
      [String] $Filter,
      [parameter(Mandatory=$true,ParameterSetName='Device-Name',HelpMessage='Exact match name. Matched remotely (via API).')]
      [String] $Name,
      [parameter(ParameterSetName='Device-NoFilter',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [parameter(ParameterSetName='Device-Filter',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [parameter(ParameterSetName='Device-Name',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [String[]] $Location,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='PanAddress input object(s) to be retrieved')]
      [PanAddress[]] $InputObject
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # No local filtering defined. Return everything.
      if($PSCmdlet.ParameterSetName -like '*-NoFilter') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': No Filter Applied')
      }
      elseif($PSCmdlet.ParameterSetName -like '*-Filter') {
         Write-Debug ($MyInvocation.MyCommand.Name + (': Filter Applied "{0}"' -f $PSBoundParameters.Filter))
      }
      elseif($PSCmdlet.ParameterSetName -like '*-Name') {
         Write-Debug ($MyInvocation.MyCommand.Name + (': Exact match Name Applied "{0}"' -f $PSBoundParameters.Name))
      }
   } # Begin Block

   Process {
      # InputObject ParameterSetName
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0}: InputObject Device: {1} XPath: {2}' -f $MyInvocation.MyCommand.Name,$InputObjectCur.Device.Name,$InputObjectCur.XPath)
            # Ensure Location map is up to date for current device
            Update-PanDeviceLocation -Device $InputObjectCur.Device
            $Response = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Get -XPath $InputObjectCur.XPath
            # Check PanResponse
            if($Response.Status -eq 'success') {
               # Build new object based on InvocationName
               if($MyInvocation.InvocationName -eq 'Get-PanAddress') {
                  [System.Xml.XmlDocument]$XDoc = $Response.Result.entry.OuterXml
                  $XPath = $InputObjectCur.XPath
                  $Obj = [PanAddress]::new($XDoc, $XPath, $InputObjectCur.Device)
                  # Send to pipeline
                  $Obj
               }
               elseif($MyInvocation.InvocationName -eq 'Get-PanAddressGroup') {
                  # Future
               }
            }
            else {
               Write-Error ('Error retrieving InputObject [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$Response.Status,$Response.Code,$Response.Message)
            }
         } # foreach InputObject
      } # ParameterSetName
      
      # NoFilter and Filter ParameterSetName
      else {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            # Ensure Location map is up to date for current device
            Update-PanDeviceLocation -Device $DeviceCur
            
            # Define XPath suffixes to be appended to PanDevice.Location(s), based on object type
            # Each object type gets it's own set of suffixes, but the same set of suffixes are used whether Panorama or NGFW (which is nice) 
            if($MyInvocation.InvocationName -eq 'Get-PanAddress') {
               # NoFilter (no search filter)
               $XPathSuffixBase = "/address/entry"
               # Filter (search filter)
               $XPathSuffixFilter = "/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
               # Name (exact)
               $XPathSuffixName = "/address/entry[@name='{0}']"   
            }
            elseif($MyInvocation.InvocationName -eq 'Get-PanAddressGroup') {

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
               Write-Debug ('{0}: Location Search(Limited): {1}' -f $MyInvocation.MyCommand.Name,($Search.Keys -join ','))
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
               Write-Debug ('{0}: Device: {1} Type: {2} Location: {3}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$DeviceCur.Type,$SearchCur.Key)
               Write-Debug ('{0}: XPath: {1}' -f $MyInvocation.MyCommand.Name,$SearchCur.Value)
               $Response = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $SearchCur.Value
               if($Response.Status -eq 'success') {
                  foreach($EntryCur in $Response.Result.entry) {
                     # Build new object based on InvocationName
                     if($MyInvocation.InvocationName -eq 'Get-PanAddress') {
                        [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                        # Regardless of "search XPath" used, the base XPath is used to form the object's XPath
                        # to avoid the contains() and translate() substrings
                        $XPath = "{0}[@name='{1}']" -f $Search.($SearchCur.Key),$EntryCur.name
                        $Obj = [PanAddress]::new($XDoc, $XPath, $DeviceCur)
                        # Send to pipeline
                        $Obj
                     }
                     elseif($MyInvocation.InvocationName -eq 'Get-PanAddressGroup') {
                        # Future
                     }
                  } # foreach entry
               } # if Reponse success
               else {
                  Write-Error ('Error retrieving objects on {0}/{1} XPath: {2} Status: {3} Code: {4} Message: {5}' -f
                     $DeviceCur.Name,$SearchCur.Key,$SearchCur.Value,$Response.Status,$Response.Code,$Response.Message)
               }
            } # foreach Search/SearchFilter
         } # foreach Device
      } # ParameterSetName
   } # Process block
   End {
   } # End block
} # Function
