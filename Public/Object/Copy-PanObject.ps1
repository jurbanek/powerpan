function Copy-PanObject {
<#
.SYNOPSIS
Copy (clone) object(s) to the same Location (shared, vsys1, MyDeviceGroup) with a NewName
.DESCRIPTION
Copy (clone) object(s) to the same Location (shared, vsys1, MyDeviceGroup) with a NewName
.NOTES
Copy-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases.
Find aliases: Get-Alias | Where-Object { $_.ResolvedCommandName -eq 'Copy-PanObject' }

Two modes: -InputObject mode and -Device mode.

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
.EXAMPLE
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice(s) to target')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
      [String] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive name of object')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) to target')]
      [PanObject[]] $InputObject,
      [parameter(ParameterSetName='Device',HelpMessage='Case-sensitive NewName for object')]
      [parameter(ParameterSetName='InputObject',HelpMessage='Case-sensitive NewName for object')]
      [String] $NewName,
      [parameter(ParameterSetName='Device',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
      [parameter(ParameterSetName='InputObject',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
      [String] $DstLocation
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

      $Suffix = switch($MyInvocation.InvocationName) {
         'Copy-PanAddress'       {'/address'}
         'Copy-PanService'       {'/service'}
         'Copy-PanAddressGroup'  {'/address-group'}
         'Copy-PanServiceGroup'  {'/service-group'}
      }
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Verbose ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5} DstLocation: {6} NewName: {7} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,
               $InputObjectCur.GetType().Name, $InputObjectCur.Name,$PSBoundParameters.DstLocation,$PSBoundParameters.NewName)
            
            # For splat to Invoke-PanXApi
            $InvokeParams = [ordered]@{
               'Device' = $InputObjectCur.Device
               'Config' = $true
            }
            if( ($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) -or $PSBoundParameters.DstLocation ) {
               # BOTH DstLocation and NewName, need to 1) Invoke-PanXApi -Config -MultiClone to clone to new location and 2) Rename-* to NewName
               # JUST DstLocation, 1) Invoke-PanXApi -Config -MultiClone to clone to new location and 2) Rename-* to same name as InputObjectCur
               # -MultiClone switch, the API action appends a "-1" onto the cloned object's name in the destination
               $InvokeParams.Add('MultiClone',$true)
               # Counter-intuitive, but action=multi-clone is needed for cloning address/address-group/service/service-group objects most effectively. action=clone is best for policy rules
               # Within multi-clone:
               #  XPath: destination container (for example, ending in /address)
               #  Element: source built as <selected-list><source xpath="/path/to/container"><member>name1</member></selected-list><all-errors>no</all-errors>
               #  While Element can contain multiple <source> and multiple <member>, we will build 1:1 for now
               $SrcXPath = '{0}{1}' -f $InputObjectCur.Device.Location.($InputObjectCur.Location),$Suffix
               $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$InputObjectCur.Name
               $DstXPath = '{0}{1}' -f $InputObject.Device.Location.($PSBoundParameters.DstLocation),$Suffix
               
               $InvokeParams.Add('XPath',$DstXPath)
               $InvokeParams.Add('Element',$Element)
            }
            # Just NewName, Invoke-PanXApi -Config -Clone only.
            elseif($PSBoundParameters.NewName) {
               # -Clone switch. The API action does NOT append a "-1" onto the object's name.
               $InvokeParams.Add('Clone',$true)
               # Within clone:
               #  XPath: source container (for example, ending in /address)
               #  From: source object full XPath
               #  NewName: new cloned object's name
               $InvokeParams.Add('XPath', $('{0}{1}' -f $InputObjectCur.Device.Location.($InputObjectCur.Location),$Suffix))
               $InvokeParams.Add('From',$InputObjectCur.XPath)
               $InvokeParams.Add('NewName',$PSBoundParameters.NewName)
            }
            else {
               Write-Error ('-NewName, -DstLocation, or both must be provided')
            }
            
            $Msg = '{0} (as {1}: ' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName
            $Msg += foreach($ParamCur in $InvokeParams.GetEnumerator()) {'{0}: {1} ' -f $ParamCur.Key,$ParamCur.Value}
            Write-Verbose ($Msg)
            # Call API with splat
            $R = Invoke-PanXApi @InvokeParams
            # Check PanResponse
            if($R.Status -eq 'success') {
               
               if( ($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) -or $PSBoundParameters.DstLocation ) {
                  # Rename required given -MultiClone to new DstLocation
                  # -MultiClone appends a "-1" onto the same. Name is returned in the <response>
                  # <response status="success" to="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Parent']/address"><member>MyObject-1</member></response>
                  $FromName = $R.Response.member
                  # Based on whether the -NewName was specified
                  $ToName = if($PSBoundParameters.NewName) { $PSBoundParameters.NewName } else { $PSBoundParameters.InputObjectCur.Name }
                  $RenamedObj = $null
                  switch ($MyInvocation.InvocationName) {
                     # Process the rename and return renamed object to to pipeline
                     'Copy-PanAddress'       { $RenamedObj = Rename-PanAddress -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanService'       { $RenamedObj = Rename-PanService -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanAddressGroup'  { $RenamedObj = Rename-PanAddressGroup -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanServiceGroup'  { $RenamedObj = Rename-PanServiceGroup -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                  }
                  if($RenamedObj) {
                     # Return renamed object to pipeline
                     $RenamedObj
                  }
                  else {
                     Write-Error ('Error renaming [{0}] {1} on {2}/{3} after successful copy' -f
                        $InputObjectCur.GetType().Name,$FromName,$InputObjectCur.Device.Name,$PSBoundParameters.DstLocation)
                  }
               }
               # No rename required. Object has different name in same location. Return object to pipeline
               elseif($PSBoundParameters.NewName) {
                  switch ($MyInvocation.InvocationName) {
                     'Copy-PanAddress'       { Get-PanAddress -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanService'       { Get-PanService -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanAddressGroup'  { Get-PanAddressGroup -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanServiceGroup'  { Get-PanServiceGroup -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue }
                  }
               }
            }
            else {
               Write-Error ('Error copying [{0}] {1} on {2}/{3} to NewName: {4} DstLocation: {5} Status: {6} Code: {7} Message: {8}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,
                  $PSBoundParameters.NewName,$PSBoundParameters.DstLocation,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ('{0} (as {1}): Device: {2} Location: {3} Name: {4} DstLocation: {5} NewName: {6} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $PSBoundParameters.Device.Name,$PSBoundParameters.Location,
               $PSBoundParameters.Name,$PSBoundParameters.DstLocation,$PSBoundParameters.NewName)
            # Update Location if past due
            if($PSBoundParameters.Device.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $PSBoundParameters.Device }
            
            # For splat to Invoke-PanXApi
            $InvokeParams = [ordered]@{
               'Device' = $PSBoundParameters.Device
               'Config' = $true
            }
            if( ($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) -or $PSBoundParameters.DstLocation ) {
               # BOTH DstLocation and NewName, need to 1) Invoke-PanXApi -Config -MultiClone to clone to new location and 2) Rename-* to NewName
               # JUST DstLocation, 1) Invoke-PanXApi -Config -MultiClone to clone to new location and 2) Rename-* to same name as InputObjectCur
               # -MultiClone switch, the API action appends a "-1" onto the cloned object's name in the destination
               $InvokeParams.Add('MultiClone',$true)
               # Counter-intuitive, but action=multi-clone is needed for cloning address/address-group/service/service-group objects most effectively. action=clone is best for policy rules
               # Within multi-clone:
               #  XPath: destination container (for example, ending in /address)
               #  Element: source built as <selected-list><source xpath="/path/to/container"><member>name1</member></selected-list><all-errors>no</all-errors>
               #  While Element can contain multiple <source> and multiple <member>, we will build 1:1 for now
               $SrcXPath = '{0}{1}' -f $PSBoundParameters.Device.Location.($PSBoundParameters.Location),$Suffix
               $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$PSBoundParameters.Name
               $DstXPath = '{0}{1}' -f $PSBoundParameters.Device.Location.($PSBoundParameters.DstLocation),$Suffix
               
               $InvokeParams.Add('XPath',$DstXPath)
               $InvokeParams.Add('Element',$Element)
            }
            # Just NewName, Invoke-PanXApi -Config -Clone only
            elseif($PSBoundParameters.NewName) {
               # -Clone switch. The API action does NOT append a "-1" onto the object's name.
               $InvokeParams.Add('Clone',$true)
               # Within clone:
               #  XPath: source container (for example, ending in /address)
               #  From: source object full XPath
               #  NewName: new cloned object's name
               $SrcXPath = '{0}{1}' -f $PSBoundParameters.Device.Location.($PSBoundParameters.Location),$Suffix
               $From = "{0}/entry[@name='{1}']" -f $SrcXPath,$PSBoundParameters.Name
               $InvokeParams.Add('XPath', $SrcXPath)
               $InvokeParams.Add('From',$From)
               $InvokeParams.Add('NewName',$PSBoundParameters.NewName)
            }
            else {
               Write-Error ('-NewName, -DstLocation, or both must be provided')
            }
            
            $Msg = '{0} (as {1}: ' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName
            $Msg += foreach($ParamCur in $InvokeParams.GetEnumerator()) {'{0}: {1} ' -f $ParamCur.Key,$ParamCur.Value}
            Write-Verbose ($Msg)
            # Call API with splat
            $R = Invoke-PanXApi @InvokeParams
            # Check PanResponse
            if($R.Status -eq 'success') {
               
               if( ($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) -or $PSBoundParameters.DstLocation) {
                  # Rename required given -MultiClone to new DstLocation
                  # -MultiClone appends a "-1" onto the same. Name is returned in the <response>
                  # <response status="success" to="/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Parent']/address"><member>MyObject-1</member></response>
                  $FromName = $R.Response.member
                  # Based on whether -NewName was specified
                  $ToName = if($PSBoundParameters.NewName) { $PSBoundParameters.NewName } else { $PSBoundParameters.Name }
                  $RenamedObj = $null
                  switch ($MyInvocation.InvocationName) {
                     # Process the rename and return renamed object to to pipeline
                     'Copy-PanAddress'       { $RenamedObj = Rename-PanAddress -Device $PSBoundParameters.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanService'       { $RenamedObj = Rename-PanService -Device $PSBoundParameters.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanAddressGroup'  { $RenamedObj = Rename-PanAddressGroup -Device $PSBoundParameters.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                     'Copy-PanServiceGroup'  { $RenamedObj = Rename-PanServiceGroup -Device $PSBoundParameters.Device -Location $PSBoundParameters.DstLocation -Name $FromName -NewName $ToName; continue }
                  }
                  if($RenamedObj) {
                     # Return renamed object to pipeline
                     $RenamedObj
                  }
                  else {
                     Write-Error ('Error renaming {0} on {1}/{2} after successful copy' -f
                        $FromName,$PSBoundParameters.Device.Name,$PSBoundParameters.DstLocation)
                  }
               }
               # No rename required. Object has different name in same location. Return object to pipeline
               elseif($PSBoundParameters.NewName) {
                  switch ($MyInvocation.InvocationName) {
                     'Copy-PanAddress'       { Get-PanAddress -Device $PSBoundParameters.Device -Location $PSBoundParameters.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanService'       { Get-PanService -Device $PSBoundParameters.Device -Location $PSBoundParameters.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanAddressGroup'  { Get-PanAddressGroup -Device $PSBoundParameters.Device -Location $PSBoundParameters.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanServiceGroup'  { Get-PanServiceGroup -Device $PSBoundParameters.Device -Location $PSBoundParameters.Location -Name $PSBoundParameters.NewName; continue }
                  }
               }
            }
            else {
               Write-Error ('Error copying {0} on {1}/{2} to NewName: {3} DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                  $PSBoundParameters.Name,$PSBoundParameters.Device.Name,$PSBoundParameters.Location,
                  $PSBoundParameters.NewName,$PSBoundParameters.DstLocation,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach DeviceCur
      } # End ParameterSetName Device
   } # Process block
   End {
   } # End block
} # Function
