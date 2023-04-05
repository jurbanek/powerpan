function Set-PanAddress {
   <#
   .SYNOPSIS
   Create or update PanAddress objects in the candidate configuration
   .DESCRIPTION
   Set-PanAddress will update an existing address object, or create new if none exists already.

   .NOTES
   Set-PanAddress cannot be used to rename objects. Use Rename- cmdlet
   Set-PanAddress cannot be used to move object locations. Use Move- cmdlet

   Cmdlet accepts two different pipeline inputs offering flexibility
      PanDevice[] pipeline input
         Pipe output of Get-PanDevice and operate on a single address object at a time
      PanAddress[] pipeline input
         Pipe output of Get-PanAddress (or other) and operate on one or more address objects at a time
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   PanAddress[]
      You can pipe a PanAddress to this cmdlet
   .OUTPUTS
   PanAddress
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Set-PanAddress -Name "H-1.1.1.1" -Value "1.1.1.1"

   Creates an ip-netmask (default) address object with name "H-1.1.1.1" and value "1.1.1.1".
   If address object with specified name already exists, the value is updated to "1.1.1.1".
   If address object with specified name already exists and the value is incompatible with the type, an error will be generated.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Set-PanAddress -Name "FQDN-raw.githubusercontent.com" -Value "raw.githubusercontent.com" -Type Fqdn

   Creates a fqdn address object with name "FQDN-raw.githubusercontent.com" and value "raw.githubusercontent.com".
   If address object with specified name already exists, the value is updated to "raw.githubusercontent.com".
   If address object with specified name already exists and the value is incompatible with the type, an error will be generated.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Set-PanAddress -Name "H-1.1.1.1" -Description "Updated description for H-1.1.1.1 address object!"

   Updates just the description property of an already existing address object named "H-1.1.1.1".
   If there is no existing address object named "H-1.1.1.1" an error will be generated. New address objects require a value.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Get-PanAddress "H-" | Set-PanAddress -Description "Updated description for all address objects with H-".

   Set-PanAddress accepts either PanDevice or PanAddress via pipeline for easier mid-pipeline filtering.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Get-PanAddress -Filter "H-" | Where-Object {$_.Name -match "^H-192\."} | Set-PanAddress -Description "Updated description for all address STARTING with H-192."

   Get-PanAddress -Filter parameter applies filter REMOTELY (via API) and reduces the number of objects processed by the PAN-OS API.
   Where-Object applies filtering capabilities LOCALLY and provides far more advanced filtering capabilities.
   Consider using both, simultaneously if needed, to optimize flexilibility and speed.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250","192.168.250.251" | Set-PanAddress -Name "H-1.1.1.1" -Tag "Sanctioned","MyCorp"

   Overwrite tag configuration on address object "H-1.1.1.1" to have only "Sanctioned" and "MyCorp" tags on 192.168.250.250 and 192.168.250.251 devices.
   Previous tags will be overwritten.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250","192.168.250.251" | Get-PanAddress | Set-PanAddress -Tag "" -Description ""

   Removes all tags and all descriptions from all address objects on 192.168.250.250 and 192.168.250.251 devices..
   Passing an empty string "" to both -Tag and -Description parameters will explicitly remove Tag(s) and Descriptions from the address object(s).
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Get-PanAddress | % { $_.Tag.Add("in") | Out-Null; $_ | Set-PanAddress }

   PS> foreach( $AddrCur in (Get-PanDevice "192.168.250.250" | Get-PanAddress)) { $AddrCur.Tag.Add("in") | Out-Null; $AddrCur | Set-PanAddress }

   Add a single tag to all address objects using either foreach-object (%) or standard foreach. Both are equivalent.
   The Out-Null is to eat the Boolean value returned by Add() method and keep the output clean.
   In event the tag is already on the object, the PAN-OS API will return an error, but processing continues for subsequent address objects.
   .EXAMPLE
   PS> Get-PanDevice "192.168.250.250" | Get-PanAddress | % { $_.Tag.Remove("in") | Out-Null; $_ | Set-PanAddress }

   PS> foreach( $AddrCur in (Get-PanDevice "192.168.250.250" | Get-PanAddress)) { $AddrCur.Tag.Remove("in") | Out-Null; $AddrCur | Set-PanAddress }

   Remove a single tag from all address objects using either foreach-object (%) or standard foreach. Both are equivalent.
   The Out-Null is to eat the Boolean value returned by Remove() method and keep the output clean.
   In event the tag is not already on the object, the PAN-OS API will return an error, but processing continues for subsequent address objects.
   #>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
   param(
      [parameter( Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='Device', HelpMessage='PanDevice against which object will be created or updated')]
      [PanDevice[]] $Device,
      [parameter( Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='Object', HelpMessage='PanAddress object to be updated')]
      [PanAddress[]] $Address,
      # $Name parameter only available in "Device" ParameterSetName, *not* in "Object" ParameterSetName. To rename the object, use a Rename- cmdlet
      [parameter( Mandatory=$true, Position=0, ParameterSetName='Device', HelpMessage='Address object name')]
      [String] $Name,
      # $Value parameter available in "Device" and "Object" ParameterSetName. Not mandatory, unless creating an object -- such a check will occur later in code.
      # Only a positional parameter in "Device"
      [parameter( Position=1, ParameterSetName='Device', HelpMessage='Address object value e.g. "10.1.1.1/32" , "server.acme.com"')]
      [parameter( ParameterSetName='Object', HelpMessage='Address object value e.g. "10.1.1.1/32" , "server.acme.com"')]
      [String] $Value,
      [parameter( ParameterSetName='Device', HelpMessage='IpNetmask, IpRange, IpWildcardMask, Fqdn')]
      [parameter( ParameterSetName='Object', HelpMessage='IpNetmask, IpRange, IpWildcardMask, Fqdn')]
      [PanAddressType] $Type = [PanAddressType]::IpNetmask,
      [parameter( ParameterSetName='Device', HelpMessage='Address object description')]
      [parameter( ParameterSetName='Object', HelpMessage='Address object description')]
      [String] $Description = $null,
      [parameter( ParameterSetName='Device', HelpMessage='PAN-OS tag(s) to be added to address object, tags must already exist')]
      [parameter( ParameterSetName='Object', HelpMessage='PAN-OS tag(s) to be added to address object, tags must already exist')]
      [System.Collections.Generic.List[String]] $Tag = [System.Collections.Generic.List[String]]@(),
      [parameter( ParameterSetName='Device', HelpMessage='Device location')]
      [String] $Location = $null
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters.Debug) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce
      Write-Debug $($MyInvocation.MyCommand.Name + ': ')
   }

   # Two rather different ParameterSets require different iteration logic
   Process {
      # Device ParameterSet, when PanDevice is present from call or from pipeline
      if($PSCmdlet.ParameterSetName -eq 'Device') {
         Write-Debug $($MyInvocation.MyCommand.Name + ': Device ParameterSetName')
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug $($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

            # Determine if there is a current object with this exact Name. If so, update only properties specified by caller
            $PanObject = Get-PanAddress -Device $DeviceCur -Filter $PSBoundParameters.Name | Where-Object {$_.Name -ceq $PSBoundParameters.Name}
            if($PanObject) {
               Write-Debug $($MyInvocation.MyCommand.Name + ': Object "' + $PSBoundParameters.Name + '" found, updating')
               # Update object properties only for those arguments specified. Parameters with default values (like Type in this function) do NOT populate PSBoundParameters
               if($PSBoundParameters.Value) { $PanObject.Value = $PSBoundParameters.Value }
               if($PSBoundParameters.Type) { $PanObject.Type = $PSBoundParameters.Type }
               if($PSBoundParameters.Description.Count) { $PanObject.Description = $PSBoundParameters.Description }
               if($PSBoundParameters.Tag.Capacity) { $PanObject.Tag = $PSBoundParameters.Tag }
               if($PSBoundParameters.Location) {
                  Write-Warning $($MyInvocation.MyCommand.Name + ': Ignoring location parameter "' + $PSBoundParameters.Location + '" for existing object "' +
                     $PanObject.Name + '" on device "' + $DeviceCur.Name + '" To move, use Move- cmdlet.')
               }
            }
            # No object with the exact Name. Create one
            else {
               Write-Debug $($MyInvocation.MyCommand.Name + ': Object "' + $PSBoundParameters.Name + '" not found, creating')
               # Verify a Value has been specified to continue creating object.
               if([String]::IsNullOrEmpty($PSBoundParameters.Value)) {
                  Write-Error $($MyInvocation.MyCommand.Name + ': Unable to create an object without a Value')
                  # Break current loop iteration, continue to next Device
                  continue
               }
               # Create a minimum viable object. Then update only the properties specified by caller
               $PanObject = New-PanAddress -Name $PSBoundParameters.Name -Value $PSBoundParameters.Value -Device $DeviceCur
               if($PSBoundParameters.Type) { $PanObject.Type = $PSBoundParameters.Type }
               if($PSBoundParameters.Description.Count) { $PanObject.Description = $PSBoundParameters.Description }
               if($PSBoundParameters.Tag.Capacity) { $PanObject.Tag = $PSBoundParameters.Tag }
               if($PSBoundParameters.Location) {
                  $PanObject.Location = $PSBoundParameters.Location
               }
               else {
                  $PanObject.Location = 'local/' + $PSBoundParameters.Device.VsysDefault
               }
            }

            if($PSCmdlet.ShouldProcess($PanObject.Device.Name,'Create/Update ' + $PanObject.Name)) {
               # Call to helper which returns a PanResponse
               $PanResponse = Set-PanAddressHelper -Address $PanObject
               # When successful send object to pipeline as confirmation. Failures will have errors written
               if($PanResponse.Status -eq 'success') { $PanObject }
               else {
                  Write-Error $($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name + ' Object: ' + $PanObject.Name + ' Message: ' + $PanResponse.Message)
               }
            }
         } # end foreach
      } # end ParameterSetName Device

      # Object ParameterSet, when PanAddress is specified from call or pipeline
      elseif($PSCmdlet.ParameterSetName -eq 'Object') {
         Write-Debug $($MyInvocation.MyCommand.Name + ': Object ParameterSetName')
         foreach($AddressCur in $PSBoundParameters.Address) {
            # AddressCur tracks the current passed-by-reference address
            # AddressCurClone is a clone used to merge in additional requested changes from other parameters. Don't want to change original Address object passed-by-reference
            Write-Debug $($MyInvocation.MyCommand.Name + ': Object: ' + $AddressCur.Name)

            # Update object properties only for those arguments specified. Parameters with default values (like Type in this function) do NOT populate PSBoundParameters
            $AddressCurClone = $AddressCur.Clone()
            if($PSBoundParameters.Value) { $AddressCurClone.Value = $PSBoundParameters.Value }
            if($PSBoundParameters.Type) { $AddressCurClone.Type = $PSBoundParameters.Type }
            if($PSBoundParameters.Description.Count) { $AddressCurClone.Description = $PSBoundParameters.Description }
            if($PSBoundParameters.Tag.Capacity) { $AddressCurClone.Tag = $PSBoundParameters.Tag }
            # Location paramater not possible within Object ParameterSet based on Parameter() block definitions. To move objects, use Move- cmdlet

            if($PSCmdlet.ShouldProcess($AddressCurClone.Device.Name,'Create/Update ' + $AddressCurClone.Name)) {
               # Call to helper which returns a PanResponse
               $PanResponse = Set-PanAddressHelper -Address $AddressCurClone
               # When successful send object to pipeline as confirmation. Failures will have errors written
               if($PanResponse.Status -eq 'success') { $AddressCurClone }
               else {
                  Write-Error $($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name + ' Object: ' + $AddressCurClone.Name + ' Message: ' + $PanResponse.Message)
               }
            }
         } # end foreach
      } # end ParameterSetName Object
   }

   End {
   }
} # Function
