function Get-XPanAddress {
<#
.SYNOPSIS
Get address objects
.DESCRIPTION
.NOTES
The -Filter parameter emulates the PAN-OS filter/search bar which is case-insensitive and searches across address object name, value, description, and tag.

PAN-OS object names are case-sensitive. Case-insensitive search is provided as a nicety.

For additional filtering capabilities, pipe output to Where-Object.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanAddress
.EXAMPLE
PS> Get-PanDevice "192.168.250.250" | Get-XPanAddress

.EXAMPLE
PS> Get-PanDevice -All | Get-XPanAddress -Filter "192.168"

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

      $XPathShared = [ordered]@{
         NoFilter = "/config/shared/address/entry";
         Filter = "/config/shared/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]";
      }
      $XPathPanorama = [ordered]@{
         NoFilter = "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry";
         Filter =   "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]";
      }
      $XPathNgfw = [ordered]@{
         NoFilter = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry";
         Filter = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]";
      }

      # Define here, track aggregate device aggregate results in Process block.
      $AddressAgg = [System.Collections.Generic.List[XPanAddress]]@()
   } # Begin Block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         Write-Debug ('{0}: Device: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)

         # Ensure Location map is up to date for current device
         Update-PanDeviceLocation -Device $DeviceCur

         # Determine necessary location xpath(s). Includes objects from Panorama (per vsys), shared, and local (per vsys)
         # Stored as key-value where key is the location and value is the xpath. Using [ordered] to preserve enumeration order later
         # Note to achieve case-insensitivity on the -Filter parameter (given PAN-OS case-sensitive)
         #  1) The xpaths are heavily modified (see above) with some wild contains() and translate()
         #  2) The -Filter contents is submitted via API as lower-case using ToLower()
         
         # A @{} syntactic sugar hashtable in PowerShell is case INsensitive
         # Using a called out [System.Collections.Specialized.OrderedDictionary] here for case sensitivity
         # Panorama device-groups are case sensitive, so 'grandparent' and 'Grandparent' are two separate DG's, need to support it
         # $XPathsToRun will become a hashtable of hashtables
         $XPathsToRun = [System.Collections.Specialized.OrderedDictionary]::new()
         
         # Add Shared
         $Paths = [ordered]@{}
         $Paths.Add('NoFilter', $XPathShared.NoFilter)
         if($PSCmdlet.ParameterSetName -eq 'Filter') {
            $Paths.Add('Filter', ($XPathShared.Filter -f $PSBoundParameters.Filter.ToLower()))
         }
         $XPathsToRun.Add('shared', $Paths)
         
         # Panorama paths, per Location (device-group)
         if($DeviceCur.Type -eq [PanDeviceType]::Panorama) {
            foreach($LocationCur in $DeviceCur.Location) {
               $Paths = [ordered]@{}
               $Paths.Add('NoFilter', ($XPathPanorama.NoFilter -f $LocationCur))
               if($PSCmdlet.ParameterSetName -eq 'Filter') {
                  $Paths.Add('Filter', ($XPathPanorama.Filter -f $LocationCur,$PSBoundParameters.Filter.ToLower()))
               }
               $XPathsToRun.Add($LocationCur, $Paths)
            }
         }
         
         # Ngfw paths, per Location (vsys)
         if($DeviceCur.Type -eq [PanDeviceType]::Ngfw) {
            foreach($LocationCur in $DeviceCur.Location) {
               $Paths = [ordered]@{}
               $Paths.Add('NoFilter', ($XPathNgfw.NoFilter -f $LocationCur))
               if($PSCmdlet.ParameterSetName -eq 'Filter') {
                  $Paths.Add('Filter', ($XPathNgfw.Filter -f $LocationCur,$PSBoundParameters.Filter.ToLower()))
               }
               $XPathsToRun.Add($LocationCur, $Paths)
            }
         }

         # Call the API for the XPathsToRun monster
         foreach($XPathCur in $XPathsToRun.GetEnumerator()) {
            # $XPathCur is a hashtable, not a string
            Write-Debug ('{0}: Device: {1} Type: {2} Location: {3}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$DeviceCur.Type,$XPathCur.Name)
            
            if($PSCmdlet.ParameterSetName -eq 'Filter') {
               Write-Debug ('{0}: XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPathCur.Value.Filter)
               $InvokeXPath = $XPathCur.Value.Filter
            }
            else {
               Write-Debug ('{0}: XPath: {1}' -f $MyInvocation.MyCommand.Name,$XPathCur.Value.NoFilter)
               $InvokeXPath = $XPathCur.Value.NoFilter
            }
            $Response = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $InvokeXPath
            if($Response.Status -eq 'success') {
               foreach($EntryCur in $Response.Result.entry) {
                  # Build a new XPanAddress
                  [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                  # Regardless of Filter or NoFilter version used in $InvokeXPath, will use NoFilter for the XPath
                  # used in the PanAddress object to avoid the Filter contains() and translate() nonsense
                  $AddressXPath = "{0}[@name='{1}']" -f $XPathCur.Value.NoFilter,$EntryCur.name
                  $Address = [XPanAddress]::new($XDoc, $AddressXPath, $DeviceCur)
                  # Send to pipeline
                  $Address
                  # Add the new PanAddress object to aggregate for purposes of being counted in Debug (and future feature)
                  $AddressAgg.Add($AddressNew)
               } # foreach entry
            }
            
         } # foreach xpath
      } # foreach Device
   } # Process block
   End {
      Write-Debug ('{0}: Final address count: {1}' -f $MyInvocation.MyCommand.Name,$AddressAgg.Count)
   } # End block
} # Function
