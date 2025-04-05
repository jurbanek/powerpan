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

      # TODO: Panorama xpaths not correct? Need fix when rebuilding cmdlet for Panorama/DG support. Placeholder for now.
      $XPathPanorama = [ordered]@{
         NoFilter = "/config/panorama/vsys/entry[@name='{0}']/address/entry";
         Filter = "/config/panorama/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]";
      }
      $XPathShared = [ordered]@{
         NoFilter = "/config/shared/address/entry";
         Filter = "/config/shared/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]";
      }
      $XPathLocal = [ordered]@{
         NoFilter = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry";
         Filter = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]";
      }

      # Define here, track aggregate device aggregate results in Process block.
      $PanAddressAgg = [System.Collections.Generic.List[XPanAddress]]@()
   } # Begin Block

   Process {
      foreach($DeviceCur in $PSBoundParameters['Device']) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

         # Ensure Vsys map is up to date for current device
         Update-PanDeviceVsys -Device $DeviceCur

         # Determine necessary location xpath(s). Includes objects from Panorama (per vsys), shared, and local (per vsys)
         # Stored as key-value where key is the location and value is the xpath. Using [ordered] to preserve enumeration order later
         # Note to achieve case-insensitivity on the -Filter parameter (given PAN-OS case-sensitive)
         #  1) The xpaths are heavily modified (see above) with some wild contains() and translate()
         #  2) The -Filter contents is submitted via API as lower-case using ToLower()
         $XPathsToRun = [ordered]@{}
         # Add Panorama-sourced object xpath(s) per vsys. Panorama can push objects to each vsys.
         foreach($VsysCur in $DeviceCur.Vsys) {
            $Paths = [ordered]@{}
            $Paths.Add('NoFilter', ($XPathPanorama.NoFilter -f $VsysCur))
            if($PSCmdlet.ParameterSetName -eq 'Filter') {
               $Paths.Add('Filter', ($XPathPanorama.Filter -f $VsysCur,$PSBoundParameters.Filter.ToLower()))
            }
            $XPathsToRun.Add("panorama/$VsysCur", $Paths)
         }

         # Add local Shared xpath
         $Paths = [ordered]@{}
         $Paths.Add('NoFilter', $XPathShared.NoFilter)
         if($PSCmdlet.ParameterSetName -eq 'Filter') {
            $Paths.Add('Filter', ($XPathShared.Filter -f $PSBoundParameters.Filter.ToLower()))
         }
         $XPathsToRun.Add("local/shared", $Paths)

         # Add local xpath(s) per vsys.
         foreach($VsysCur in $DeviceCur.Vsys) {
            $Paths = [ordered]@{}
            $Paths.Add('NoFilter', ($XPathLocal.NoFilter -f $VsysCur))
            if($PSCmdlet.ParameterSetName -eq 'Filter') {
               $Paths.Add('Filter', ($XPathLocal.Filter -f $VsysCur,$PSBoundParameters.Filter.ToLower()))
            }
            $XPathsToRun.Add("local/$VsysCur", $Paths)
         }

         # Call API for determined xpath(s)
         foreach($XPathCur in $XPathsToRun.GetEnumerator()) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: {0} SearchType: {1}' -f $DeviceCur.Name,$XPathCur.Name)
            
            if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
               Write-Debug ($MyInvocation.MyCommand.Name + ': XPath: {0}' -f $XPathCur.Value.NoFilter)
               $PanResponse = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPathCur.Value.NoFilter
               if($PanResponse.Status -eq 'success') {
                  foreach($EntryCur in $PanResponse.Result.entry) {
                     # Build a new XPanAddress
                     [System.Xml.XmlDocument]$XDocNew = $EntryCur.OuterXml
                     $XPathNew = "{0}[@name='{1}']" -f $XPathCur.Value.NoFilter,$EntryCur.name
                     $AddressNew = [XPanAddress]::new($XDocNew, $XPathNew, $DeviceCur)
                     # Send to pipeline
                     $AddressNew
                     # Add the new PanAddress object to aggregate for purposes of being counted in Debug (and future feature)
                     $PanAddressAgg.Add($AddressNew)
                  } # foreach entry
               }
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
               Write-Debug ($MyInvocation.MyCommand.Name + ': XPath: {0}' -f $XPathCur.Value.Filter)
               $PanResponse = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPathCur.Value.Filter
               if($PanResponse.Status -eq 'success') {
                  foreach($EntryCur in $PanResponse.Result.entry) {
                     # Build a new XPanAddress
                     [System.Xml.XmlDocument]$XDocNew = $EntryCur.OuterXml
                     # Search used $XPathCur.Value.Filter XPath, BUT the address object XPath property to use the NoFilter version
                     # to represent the object's XPath directly without the additional filter nonsense
                     $XPathNew = "{0}[@name='{1}']" -f $XPathCur.Value.NoFilter,$EntryCur.name
                     $AddressNew = [XPanAddress]::new($XDocNew, $XPathNew, $DeviceCur)
                     # Send to pipeline
                     $AddressNew
                     # Add the new PanAddress object to aggregate for purposes of being counted in Debug (and future feature)
                     $PanAddressAgg.Add($AddressNew)
                  } # foreach entry
               }
            }
         } # foreach xpath
      } # foreach Device
   } # Process block
   End {
      Write-Debug ($MyInvocation.MyCommand.Name + (': Final address count: {0}' -f $PanAddressAgg.Count))
   } # End block
} # Function
