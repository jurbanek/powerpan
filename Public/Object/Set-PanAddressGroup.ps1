function Set-PanAddressGroup {
<#
.SYNOPSIS
Create or update address group in the device candidate configuration.
.DESCRIPTION
Create an address group object in the device candidate configuration if the name does *not* exist.
Update an address group object in the device candidate configuration if the name already exists.
.NOTES
Two modes: -InputObject mode and -Device mode.

:: InputObject Mode (-InputObject)::
Take one or more objects "as is" and apply them to the candidate configuration to create or update using API action=edit (replace)
The Device and Location (vsys, device-group) are gleaned from object's own Device and Location properties.
Set the object properties as desired and pipe the object to the cmdlet.

:: Device Mode (-Device)::
Device mode is more nuanced. Used to create objects or update objects in candidate configuration.
Device mode does not take an InputObject. Required parameters are -Device, -Location, and -Name.
Remaining parameters are not required by the cmdlet, but may be required by the XML API depending on if the object already exists or not.
This flexibility offers interactive power as not all values have to be specified all the time.

:: Rename & Move ::
Set- cannot be used to rename objects. Use Rename- cmdlet.
Set- cannot be used to move object locations. Use Move- cmdlet.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddressGroup[]
   You can pipe a PanAddressGroup to this cmdlet
.OUTPUTS
PanAddressGroup
.EXAMPLE
Create new on NGFW

$D = Get-PanDevice "fw.lab.local"
Set-PanAddressGroup -Device $D -Location "vsys1" -Name "MyAddressGroup" -Member @('H-1.1.1.1','H-2.2.2.2') -Type "static"

If MyAddressGroup already exists in vsys1, the specified PowerShell parameters will replace their corresponding elements/attributes.
.EXAMPLE
Create new on Panorama

$D = Get-PanDevice "panorama.lab.local"
Set-PanAddressGroup -Device $D -Location "MyDeviceGroup" -Name "MyAddressGroup" -Member @('H-1.1.1.1','H-2.2.2.2') -Type "static"

If MyAddressGroup already exists in MyDeviceGroup, the specified PowerShell parameters will replace their corresponding elements/attributes.
.EXAMPLE
Add a description to an object that already exists.

$D = Get-PanDevice "fw.lab.local"
Set-PanAddressGroup -Device $D -Location "vsys1" -Name "MyAddressGroup" -Description "Updated Description!"

If the object did NOT exist already, the command would error remotely by the API (with details) as additional parameters are required for new objects to be created.
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be applied')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
      [String] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive name of address object')]
      [String] $Name,
      [parameter(ParameterSetName='Device',HelpMessage='Type of the address group: static, dynamic')]
      [ValidateSet('static','dynamic')]
      [String] $Type,
      [parameter(ParameterSetName='Device',HelpMessage='Array of string member names for static group ONLY')]
      [String[]] $Member,
      [parameter(ParameterSetName='Device',HelpMessage='Match filter for dynamic group ONLY')]
      [String] $Filter,
      [parameter(ParameterSetName='Device',HelpMessage='Description')]
      [String] $Description,
      [parameter(ParameterSetName='Device',HelpMessage='One or more tags. Tags must exist already. Will not create tags')]
      [String[]] $Tag,
      [parameter(ParameterSetName='Device',HelpMessage='Disable ability to override (Panorama device-group objects only)')]
      [Bool] $DisableOverride,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) to be created/updated as is')]
      [PanAddressGroup[]] $InputObject
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin Block

   Process {
      # ParameterSetName InputObject
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0}: InputObject Device: {1} XPath: {2}' -f $MyInvocation.MyCommand.Name,$InputObjectCur.Device.Name,$InputObjectCur.XPath)
            # InputObject is always action=edit, requires overlap between XPath and Element (entry.OuterXml)
            Write-Debug ('{0}: InputObject (-Edit)XML: {1}' -f $MyInvocation.MyCommand.Name,$InputObjectCur.XDoc.entry.OuterXml)
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Edit -XPath $InputObjectCur.XPath -Element $InputObjectCur.XDoc.entry.OuterXml
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Send the updated object back to the pipeline for further use or to display
               Get-PanAddressGroup -InputObject $InputObjectCur
            }
            else {
               Write-Error ('Error applying InputObject {0} on {1}/{2} . Status: {3} Code: {4} Message: {5}' -f
                  $InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0}: Device: {1} Location: {2} Name: {3} ' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$PSBoundParameters.Location,$PSBoundParameters.Name)
            # Update Location if past due
            if($PSBoundParameters.Device.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $PSBoundParameters.Device }
            
            # If object already exists, use it. If object does not exist, create a minimimum viable object with a call to ::new($Device,$Location,$Name)
            $Obj = $null
            $Obj = Get-PanAddressGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name
            if($Obj) {
               Write-Debug ('{0}: Found {1} on Device: {2}/{3} at XPath: {4}' -f $MyInvocation.MyCommand.Name,$PSBoundParameters.Name,$DeviceCur.Name,$PSBoundParameters.Location,$Obj.XPath)
            }
            # Object does not exist, build it
            else {
               Write-Debug ('{0}: Cannot find {1} on Device: {2}/{3}. Building' -f $MyInvocation.MyCommand.Name,$PSBoundParameters.Name,$DeviceCur.Name,$PSBoundParameters.Location)
               $Obj = [PanAddressGroup]::new($DeviceCur,$PSBoundParameters.Location,$PSBoundParameters.Name)
            }
               
            # Modify properties directly letting Getter/Setter do heavy XML lifting
            # Device, Location, and Name do not apply
            if($PSBoundParameters.ContainsKey('Type'))            { $Obj.Type = $PSBoundParameters.Type }
            if($PSBoundParameters.ContainsKey('Member'))          { $Obj.Member = $PSBoundParameters.Member }
            if($PSBoundParameters.ContainsKey('Filter'))          { $Obj.Filter = $PSBoundParameters.Filter }
            if($PSBoundParameters.ContainsKey('Description'))     { $Obj.Description = $PSBoundParameters.Description }
            if($PSBoundParameters.ContainsKey('Tag'))             { $Obj.Tag = $PSBoundParameters.Tag }
            if($PSBoundParameters.ContainsKey('DisableOverride')) { $Obj.DisableOverride = $PSBoundParameters.DisableOverride }

            # Call API
            # Replace action=edit, requires overlap between XPath and Element (entry.OuterXml)
            Write-Debug ('{0}: Device (-Edit)XML: {1}' -f $MyInvocation.MyCommand.Name,$Obj.XDoc.entry.OuterXml)
            $R = Invoke-PanXApi -Device $DeviceCur -Config -Edit -XPath $Obj.XPath -Element $Obj.XDoc.entry.OuterXml
            
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Send the updated object back to the pipeline for further use or to display
               Get-PanAddressGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name
            }
            else {
               Write-Error ('Error applying {0} on {1}/{2} . Status: {3} Code: {4} Message: {5}' -f
                  $PSBoundParameters.Name,$DeviceCur.Name,$PSBoundParameters.Location,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach $DeviceCur
      } # End ParameterSetName Device
   } # Process block

   End {
   } # End block
} # Function
