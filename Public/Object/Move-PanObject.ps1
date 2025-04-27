function Move-PanObject {
<#
.SYNOPSIS
Move object(s) to a different Location (shared, vsys1, MyDeviceGroup) on the same Device
.DESCRIPTION
Move object(s) to a different Location (shared, vsys1, MyDeviceGroup) on the same Device
.NOTES
Move-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases.
Find aliases: Get-Alias | Where-Object { $_.ResolvedCommandName -eq 'Move-PanObject' }

Two modes: -InputObject mode and -Device mode.

Note: Objects in a Panorama device-group with DisableOverride: $true (which is <disable-override>yes</disable-override>) cannot be moved to shared
It's enforced by Panorama (and an API error). Update the object and use Set-*, then move as needed.
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
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
      [parameter(Mandatory=$true,ParameterSetName='InputObject',HelpMessage='Case-sensitive destination location for object (vsys1, shared, MyDG, etc.)')]
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
         'Move-PanAddress'       {'/address'}
         'Move-PanService'       {'/service'}
         'Move-PanAddressGroup'  {'/address-group'}
         'Move-PanServiceGroup'  {'/service-group'}
      }
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5} DstLocation: {6} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,
               $InputObjectCur.Name,$PSBoundParameters.DstLocation)

            # Counter-intuitive, but action=multi-move is needed for moving address/address-group/service/service-group objects most effectively. action=move is best for policy rules
            # Within multi-move:
            #  XPath: destination container (for example, ending in /address)
            #  Element: source built as <selected-list><source xpath="/path/to/container"><member>name1</member></selected-list><all-errors>no</all-errors>
            #  While Element can contain multiple <source> and multiple <member>, we will build 1:1 for now
            $DstXPath = '{0}{1}' -f $InputObject.Device.Location.($PSBoundParameters.DstLocation),$Suffix
            $SrcXPath = '{0}{1}' -f $InputObjectCur.Device.Location.($InputObjectCur.Location),$Suffix
            $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$InputObjectCur.Name

            Write-Debug ('{0} as ({1}: Device: {2} Config: MultiMove: XPath: {3} Element: {4}' -f 
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName,$InputObjectCur.Device.Name,$DstXPath,$Element)
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Config -MultiMove -XPath $DstXPath -Element $Element
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Return newly moved object to pipeline
               switch ($MyInvocation.InvocationName) {
                  'Move-PanAddress'       { Get-PanAddress -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
                  'Move-PanService'       { Get-PanService -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
                  'Move-PanAddressGroup'  { Get-PanAddressGroup -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
                  'Move-PanServiceGroup'  { Get-PanServiceGroup -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
               }
            }
            else {
               Write-Error ('Error moving [{0}] {1} on {2}/{3} to DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,
                  $PSBoundParameters.DstLocation,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4} DstLocation: {5} ' -f 
               $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location,
               $PSBoundParameters.Name, $PSBoundParameters.DstLocation)
            # Update Location if past due
            if($PSBoundParameters.Device.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $PSBoundParameters.Device }
            
            # Given -Device ParameterSet, fetch the object for its XPath
            switch ($MyInvocation.InvocationName) {
               'Move-PanAddress'       { $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Move-PanService'       { $Obj = Get-PanService -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Move-PanAddressGroup'  { $Obj = Get-PanAddressGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Move-PanServiceGroup'  { $Obj = Get-PanServiceGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
            }

            # Call API
            if($Obj) {
               $SrcXPath = '{0}{1}' -f $Obj.Device.Location.($Obj.Location),$Suffix
               $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$Obj.Name
               $DstXPath = '{0}{1}' -f $Obj.Device.Location.($PSBoundParameters.DstLocation),$Suffix
               $R = Invoke-PanXApi -Device $Obj.Device -Config -MultiMove -XPath $DstXPath -Element $Element
               if($R.Status -eq 'success') {
                  # Return newly moved object to pipeline
                  switch ($MyInvocation.InvocationName) {
                     'Move-PanAddress'       { Get-PanAddress -Device $Obj.Device -Location $PSBoundParameters.DstLocation -Name $Obj.Name; continue }
                     'Move-PanService'       { Get-PanService -Device $Obj.Device -Location $PSBoundParameters.DstLocation -Name $Obj.Name; continue }
                     'Move-PanAddressGroup'  { Get-PanAddressGroup -Device $Obj.Device -Location $PSBoundParameters.DstLocation -Name $Obj.Name; continue }
                     'Move-PanServiceGroup'  { Get-PanServiceGroup -Device $Obj.Device -Location $PSBoundParameters.DstLocation -Name $Obj.Name; continue }
                  }
               }
               # Failure on Invoke-PanXApi
               else {
                  Write-Error ('Error moving [{0}] {1} on {2}/{3} to DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $PSBoundParameters.DstLocation,
                     $R.Status, $R.Code, $R.Message)
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
