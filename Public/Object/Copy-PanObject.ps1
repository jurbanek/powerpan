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
.OUTPUTS
PanAddress
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
      [PanAddress[]] $InputObject,
      [parameter(ParameterSetName='Device',HelpMessage='Case-sensitive NewName for object')]
      [parameter(ParameterSetName='InputObject',HelpMessage='Case-sensitive NewName for object')]
      [String] $NewName,
      [parameter(ParameterSetName='Device',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
      [parameter(ParameterSetName='InputObject',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
      [String] $DstLocation
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ('{0} (as {1}):' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName)

      # Terminating error if called directly. Use a supported alias.
      if($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
         $Alias = (Get-Alias | Where-Object {$_.ResolvedCommandName -eq $($MyInvocation.MyCommand.Name)} | Select-Object -ExpandProperty Name) -join ','
         Write-Error ('{0} called directly. {0} MUST be called by an alias: {1}' -f $MyInvocation.MyCommand.Name,$Alias) -ErrorAction Stop
      }

      $Suffix = switch($MyInvocation.InvocationName) {
         'Copy-PanAddress' {'/address'}
         'Copy-PanAddressGroup' {'/address-group'}
      }
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5} NewName: {6} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,
               $InputObjectCur.Name,$PSBoundParameters.NewName)
            
            # For splat to Invoke-PanXApi
            $InvokeParams = [ordered]@{
               'Device' = $InputObjectCur.Device
               'Config' = $true
            }
            # BOTH DstLocation and NewName, need to 1) Invoke-PanXApi -Config -MultiClone to clone to new location and 2) Rename-*
            # JUST DstLocation, Invoke-PanXApi -Config -MultiClone to clone to new location only
            if( ($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) -or $PSBoundParameters.DstLocation ) {
               <#
               # -Clone switch
               $InvokeParams.Add('Clone',$true)
               # Within clone:
               #  XPath: source container (for example, ending in /address)
               #  From: source object full XPath
               #  NewName: new cloned object's name
               $InvokeParams.Add('XPath', $('{0}{1}' -f $InputObjectCur.Device.Location.($InputObjectCur.Location),$Suffix))
               $InvokeParams.Add('From',$InputObjectCur.XPath)
               $InvokeParams.Add('NewName',$PSBoundParameters.NewName)
               #>

               <#
               # -MultiClone switch
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
               #>
            }
            # Just NewName, Invoke-PanXApi -Config -Clone only
            elseif($PSBoundParameters.NewName) {
               # -Clone switch
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
            Write-Debug ($Msg)
            # Call API with splat
            $Response = Invoke-PanXApi @InvokeParams
            # Check PanResponse
            if($Response.Status -eq 'success') {
               
               # Rename required. Process rename in DstLocation renaming to NewName
               if($PSBoundParameters.DstLocation -and $PSBoundParameters.NewName) {
                  $RenamedObj = $null
                  switch ($MyInvocation.InvocationName) {
                     # Process the rename and return renamed object to to pipeline
                     'Copy-PanAddress' { $RenamedObj = Rename-PanAddress -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name -NewName $PSBoundParameters.NewName; continue }
                     'Copy-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }   
                  }
                  if($RenamedObj) {
                     # Return renamed object to pipeline
                     $RenamedObj
                  }
                  else {
                     Write-Error ('Error renaming [{0}] {1} on {2}/{3} after successful copy' -f
                        $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$PSBoundParameters.DstLocation)
                  }
               }
               # No rename required. Object has same name in different location. Return object to pipeline
               elseif($PSBoundParameters.DstLocation) {
                  switch ($MyInvocation.InvocationName) {
                     'Copy-PanAddress' { Get-PanAddress -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
                     'Copy-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
                  }
               }
               # No rename required. Object has different name in same location. Return object to pipeline
               elseif($PSBoundParameters.NewName) {
                  switch ($MyInvocation.InvocationName) {
                     'Copy-PanAddress' { Get-PanAddress -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue }
                     'Copy-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
                  }
               }
            }
            else {
               Write-Error ('Error copying [{0}] {1} on {2}/{3} to DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,
                  $PSBoundParameters.DstLocation,$Response.Status,$Response.Code,$Response.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      ### LEFT OFF HERE
      ### NEED TO REBUILD Device ParameterSETNAME
      ###
      ###

      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4} DstLocation: {5} ' -f 
               $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location,
               $PSBoundParameters.Name, $PSBoundParameters.DstLocation)
            # Given -Device ParameterSet, fetch the object for its XPath
            switch ($MyInvocation.InvocationName) {
               'Move-PanAddress' { $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Move-PanAddressGroup' { <# Future $Obj = Get-PanAddressGroup #> continue }
            }

            # Call API
            if($Obj) {
               $SrcXPath = '{0}{1}' -f $Obj.Device.Location.($Obj.Location),$Suffix
               $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$Obj.Name
               $DstXPath = '{0}{1}' -f $Obj.Device.Location.($PSBoundParameters.DstLocation),$Suffix
               $Response = Invoke-PanXApi -Device $Obj.Device -Config -MultiMove -XPath $DstXPath -Element $Element
               if($Response.Status -eq 'success') {
                  # Return newly moved object to pipeline
                  switch ($MyInvocation.InvocationName) {
                     'Move-PanAddress' { Get-PanAddress -Device $Obj.Device -Location $PSBoundParameters.DstLocation -Name $Obj.Name; continue }
                     'Move-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
                  }
               }
               # Failure on Invoke-PanXApi
               else {
                  Write-Error ('Error moving [{0}] {1} on {2}/{3} to DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $PSBoundParameters.DstLocation,
                     $Response.Status, $Response.Code, $Response.Message)
               }
            }
            # Object by name was not found
            else {
               Write-Warning ('Move {0} not found on {1}/{2}' -f $PSBoundParameters.Name, $DeviceCur.Name, $PSBoundParameters.Location)
            }
         } # End foreach DeviceCur
      } # End ParameterSetName Device
   } # Process block
   End {
   } # End block
} # Function
