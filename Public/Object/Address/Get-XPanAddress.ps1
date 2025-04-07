function Get-XPanAddress {
<#
.SYNOPSIS
Get address objects from a PanDevice
.DESCRIPTION
Get all address objects from a PanDevice or specify the -Filter parameter for a remote (not local) filtered search
.NOTES
The -Filter parameter emulates the PAN-OS filter/search bar which is case-insensitive and searches across address object name, value, description, and tag.

PAN-OS object names are case-sensitive. Case-insensitive search is provided as a nicety.

For additional filtering capabilities, pipe output to Where-Object.

XPath References for base search and filtered search. {0} becomes Filter.ToLower()
Shared
/config/shared/address/entry
/config/shared/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]

Panorama
/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry
/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]

Ngfw
/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry
/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanAddress
.EXAMPLE
Get-PanDevice "192.168.250.250" | Get-XPanAddress
.EXAMPLE
Get-PanDevice -All | Get-XPanAddress -Filter "192.168"
.EXAMPLE
$D = Get-PanDevice "fw.lab.local"
Get-XPanAddress -Device $D | Where-Object {$_.Type -eq 'fqdn' -and $_.Value -like "*amazon*"}
#>
   [CmdletBinding(DefaultParameterSetName='NoFilter')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which address object(s) will be retrieved.')]
      [PanDevice[]] $Device,
      [parameter(
         Position=0,
         ParameterSetName='Filter',
         HelpMessage='Name or value filter for address object(s) to be retrieved. Filter applied remotely (via API) identical to filter bar behavior.')]
      [String] $Filter
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # No local filtering defined. Return everything.
      if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': No Filter Applied')
      }
      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         Write-Debug ($MyInvocation.MyCommand.Name + (': Filter Applied "{0}"' -f $PSBoundParameters.Filter))
      }

      # Track aggregate device aggregate results in Process block
      $AddressAgg = [System.Collections.Generic.List[XPanAddress]]@()
   } # Begin Block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         Write-Debug ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)

         # Ensure Location map is up to date for current device
         Update-PanDeviceLocation -Device $DeviceCur

         # Build XPaths from existing PanDevice.Location, appending to all existing Locations
         # Standard address suffix and voodoo-like filter suffix for remote side searching
         # Suffixes are the same for Panorama and Ngfw
         # Case SENSITIVE ordered hashtables are used
         # Panorama device-groups are case sensitive, so 'grandparent' and 'Grandparent' are two separate DG's, need to support it
         $Search = [System.Collections.Specialized.OrderedDictionary]::new()
         $SearchFilter = [System.Collections.Specialized.OrderedDictionary]::new()
         $XPathSuffix = "/address/entry"
         $XPathSuffixFilter = "/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
         
         foreach($LocationCur in $DeviceCur.Location.GetEnumerator()) {
            $NewXPath = $DeviceCur.Location.($LocationCur.Key) + $XPathSuffix
            $Search.Add($LocationCur.Key, $NewXPath)
            # With the -Filter parameter as input into the contains(translate()) XPath voodoo
            # Note the Filter string is ToLower() to align with the XPath translate()
            if($PSCmdlet.ParameterSetName -eq 'Filter') {
               $NewXPathFilter = ($DeviceCur.Location.($LocationCur.Key) + $XPathSuffixFilter) -f $PSBoundParameters.Filter.ToLower()
               $SearchFilter.Add($LocationCur.Key, $NewXPathFilter)
            }
         }

         # Call the API. The "search XPath" list ($Search or $SearchFilter) is determined by ParameterSetName
         foreach($SearchCur in $(if($PSCmdlet.ParameterSetName -eq 'Filter'){ $SearchFilter.GetEnumerator() } else{ $Search.GetEnumerator() })) {
            Write-Debug ('{0}: Device: {1} Type: {2} Location: {3}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$DeviceCur.Type,$SearchCur.Key)
            Write-Debug ('{0}: XPath: {1}' -f $MyInvocation.MyCommand.Name,$SearchCur.Value)
            $Response = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $SearchCur.Value
            if($Response.Status -eq 'success') {
               foreach($EntryCur in $Response.Result.entry) {
                  # Build a new XPanAddress
                  [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                  # Regardless of "search XPath" used, the base XPath is used to form the XPanAddress object's XPath
                  # to avoid the contains() and translate() substrings
                  $AddressXPath = "{0}[@name='{1}']" -f $Search.($SearchCur.Key),$EntryCur.name
                  $Address = [XPanAddress]::new($XDoc, $AddressXPath, $DeviceCur)
                  # Send to pipeline
                  $Address
                  # Add the new PanAddress object to aggregate for purposes of being counted in Debug (and future feature)
                  $AddressAgg.Add($AddressNew)
               } # foreach entry
            } # if Reponse success
         } # foreach Search/SearchFilter
      } # foreach Device
   } # Process block
   End {
      Write-Debug ('{0}: Final address count: {1}' -f $MyInvocation.MyCommand.Name,$AddressAgg.Count)
   } # End block
} # Function
