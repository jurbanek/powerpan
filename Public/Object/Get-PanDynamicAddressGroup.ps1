function Get-PanDynamicAddressGroup {
<#
.SYNOPSIS
Retrieve PanDynamicAddressGroup from Device
.DESCRIPTION
Retrieve all object(s) on a -Device, scope to a specific -Location(s), scope to a single case-sensitive  -Name, or specify a case-INsensitive
.NOTES
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
PanDynamicAddressGroup[]
   You can pipe a PanService to this cmdlet
.OUTPUTS
PanDynamicAddressGroup
.EXAMPLE
#>
   [CmdletBinding(DefaultParameterSetName='Device')]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]
      [PanDevice[]] $Device,
      [parameter(ParameterSetName='Device',HelpMessage='Limit search to PanDevice locations (shared, vsys1, MyDeviceGroup)')]
      [String[]] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Exact match object name. Matched remotely (API)')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) (PanDynamicAddressGroup) to be retrieved')]
      [PanObject[]] $InputObject
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0} (as {1}):' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName)

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
               if($InputObjectCur.Device.Type -eq [PanDeviceType]::Ngfw) {
                  $Entry = $R.Response.result.'dyn-addr-grp'.entry
               }
               elseif($InputObjectCur.Device.Type -eq [PanDeviceType]::Panorama) {
                  $Entry = $R.Response.result.'dyn-addr-grp'.entry
               }
               Write-Verbose ('{0}: API return entry count: {1}' -f
                  $MyInvocation.MyCommand.Name,$R.Response.result.entry.Count,$Entry.Count)

               $ObjAgg = @()
               foreach($EntryCur in $Entry) {
                  [System.Xml.XmlDocument]$XDoc = $EntryCur.OuterXml
                  $ObjAgg += [PanDynamicAddressGroup]::new($InputObjectCur.Device,$XDoc)
               }
            } 
            else {
               Write-Error ('Error retrieving InputObject {0} on {1} Status: {2} Code: {3} Message: {4}' -f
                  $InputObjectCur.Name,$InputObjectCur.Device.Name,$R.Status,$R.Code,$R.Message)
            }
         } # foreach InputObject
      } # ParameterSetName

      <#
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
                     $Entry = $R.Response.result.entry | Where-Object {$_.loc -ceq $SearchCur.Key -or [String]::IsNullOrEmpty($_.loc) }
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
   #>
   
      } # Process block
   
   End {
      # Send to pipeline
      foreach($ObjCur in $ObjAgg) {
         $ObjCur
      }
   } # End block
} # Function
