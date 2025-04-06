function Get-PanAddress {
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
   PS> Get-PanDevice "192.168.250.250" | Get-PanAddress

   .EXAMPLE
   PS> Get-PanDevice -All | Get-PanAddress -Filter "192.168"

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
         $XPathFromPanorama = "/config/panorama/vsys/entry[@name='{0}']/address/entry"
         $XPathFromShared = "/config/shared/address/entry"
         $XPathFromLocal = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry"
      }
      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Filter Applied "' + $PSBoundParameters['Filter'] + '"')
         $XPathFromPanorama = "/config/panorama/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]"
         $XPathFromShared= "/config/shared/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{0}' ))]"
         $XPathFromLocal = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[(contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-netmask, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-range, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(fqdn, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(ip-wildcard, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(description, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' )) or (contains(translate(tag, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'{1}' ))]"
      }
      # Define here, track aggregate device aggregate results in Process block.
      $PanAddressAgg = [System.Collections.Generic.List[PanAddress]]@()
   } # Begin Block

   Process {
      foreach($DeviceCur in $PSBoundParameters['Device']) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

         # Ensure Location map is up to date for current device
         Update-PanDeviceLocation -Device $DeviceCur

         # Determine necessary location xpath(s). Includes objects from Panorama (per vsys), shared, and local (per vsys)
         # Stored as key-value where key is the location and value is the xpath. Using [ordered] to preserve enumeration order later
         # Note to achieve case-insensitivity on the -Filter parameter (given PAN-OS case-sensitive)
         #  1) The xpaths are heavily modified (see above) with some wild contains() and translate()
         #  2) The -Filter contents is submitted via API as lower-case using ToLower()
         $XPathsToRun = [ordered]@{}
         # Add Panorama-sourced object xpath(s) per vsys. Panorama can push objects to each vsys.
         foreach($VsysCur in $DeviceCur.Vsys) {
            if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
               $XPathsToRun.Add( "panorama/$VsysCur", $XPathFromPanorama -f $VsysCur)
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
               $XPathsToRun.Add( "panorama/$VsysCur", ($XPathFromPanorama -f $VsysCur,$PSBoundParameters['Filter'].ToLower()))
            }
         }
         # Add local Shared xpath
         if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
            $XPathsToRun.Add( "local/shared", $XPathFromShared)
         }
         elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
            $XPathsToRun.Add( "local/shared", ($XPathFromShared -f $PSBoundParameters['Filter'].ToLower()))
         }
         # Add local xpath(s) per vsys.
         foreach($VsysCur in $DeviceCur.Vsys) {
            if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
               $XPathsToRun.Add( "local/$VsysCur", $XPathFromLocal -f $VsysCur)
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
               $XPathsToRun.Add( "local/$VsysCur", ($XPathFromLocal -f $VsysCur,$PSBoundParameters['Filter'].ToLower()))
            }
         }

         # Call API for determined xpath(s)
         foreach($XPathCur in $XPathsToRun.GetEnumerator()) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name + ' ' + $XPathCur.Name + ' ' + $XPathCur.Value)
            $PanResponse = Invoke-PanXApi -Device $DeviceCur -Config -Get -XPath $XPathCur.Value

            if($PanResponse.Status -eq 'success') {
               foreach($EntryCur in $PanResponse.Result.entry) {
                  # Determine type and value
                  # Use .InnerText for value to accommodate cases where element has attributes like 'dirtyId' if part of candidate config
                  if($EntryCur.'ip-netmask') {
                     $Type = [PanAddressType]::IpNetmask
                     if($EntryCur.'ip-netmask'.HasChildNodes) {
                        $Value = $EntryCur.'ip-netmask'.InnerText
                     }
                     else {
                        $Value = $EntryCur.'ip-netmask'
                     }
                  }
                  elseif($EntryCur.'ip-range') {
                     $Type = [PanAddressType]::IpRange
                     if($EntryCur.'ip-range'.HasChildNodes) {
                        $Value = $EntryCur.'ip-range'.InnerText
                     }
                     else {
                        $Value = $EntryCur.'ip-range'
                     }
                  }
                  elseif($EntryCur.'ip-wildcard') {
                     $Type = [PanAddressType]::IpWildcardMask
                     if($EntryCur.'ip-wildcard'.HasChildNodes) {
                        $Value = $EntryCur.'ip-wildcard'.InnerText
                     }
                     else {
                        $Value = $EntryCur.'ip-wildcard'
                     }
                  }
                  elseif($EntryCur.fqdn) {
                     $Type = [PanAddressType]::Fqdn
                     if($EntryCur.fqdn.HasChildNodes) {
                        $Value = $EntryCur.fqdn.InnerText
                     }
                     else {
                        $Value = $EntryCur.fqdn
                     }
                  }

                  # Determine description
                  # Use .InnerText for value to accommodate cases where element has attributes like 'dirtyId' if part of candidate config
                  if($EntryCur.description.HasChildNodes) {
                     $Description = $EntryCur.description.InnerText
                  }
                  else {
                     $Description = $EntryCur.description
                  }

                  # Determine tag member(s)
                  # Use .InnerText for value to accommodate cases where element has attributes like 'dirtyId' if part of candidate config
                  $Member = @()
                  foreach($MemberCur in $EntryCur.tag.member) {
                     if($MemberCur.HasChildNodes) {
                        $Member += $MemberCur.InnerText
                     }
                     else {
                        $Member += $MemberCur
                     }
                  }

                  # Create new PanAddress object, output to pipeline (fast update for users), save to variable
                  NewPanAddress -Name $EntryCur.name -Value $Value -Type $Type -Description $Description -Tag $Member -Device $DeviceCur -Location $XPathCur.Name | Tee-Object -Variable 'AddressFoo'

                  # Add the new PanAddress object to aggregate. Will be counted in End block. Available for future feature as well
                  $PanAddressAgg.Add($AddressFoo)
               } # foreach entry
            }
         } # foreach xpath
      } # foreach Device
   } # Process block
   End {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Final address count: ' + $PanAddressAgg.Count)
   } # End block
} # Function
