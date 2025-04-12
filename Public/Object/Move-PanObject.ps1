function Move-PanObject {
<#
.SYNOPSIS
Move object(s) (multiple types) to 
.DESCRIPTION
Move multiple object types from a single cmdlet based on the alias used
.NOTES
Move-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases:
   Move-PanAddress
   ...

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
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be applied')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
      [String] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive name of address object')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='PanAddress input object(s) to be applied as is')]
      [PanAddress[]] $InputObject,
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
         'Move-PanAddress' {'/address'}
         'Move-PanAddressGroup' {'/address-group'}
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
            #  XPath is the destination container (for example, ending in /address)
            #  Element is the source built as <selected-list><source xpath="/path/to/container"><member>name1</member></selected-list><all-errors>no</all-errors>
            #  While Element can contain multiple <source> and multiple <member>, we will build 1:1 for now
            $SrcXPath = '{0}{1}' -f $InputObjectCur.Device.Location.($InputObjectCur.Location),$Suffix
            $Element = "<selected-list><source xpath=`"{0}`"><member>{1}</member></source></selected-list><all-errors>no</all-errors>" -f $SrcXPath,$InputObjectCur.Name
            $DstXPath = '{0}{1}' -f $InputObject.Device.Location.($PSBoundParameters.DstLocation),$Suffix
            
            $Response = Invoke-PanXApi -Device $InputObjectCur.Device -Config -MultiMove -XPath $DstXPath -Element $Element
            # Check PanResponse
            if($Response.Status -eq 'success') {
               # Return newly moved object to pipeline
               switch ($MyInvocation.InvocationName) {
                  'Move-PanAddress' { Get-PanAddress -Device $InputObjectCur.Device -Location $PSBoundParameters.DstLocation -Name $InputObjectCur.Name; continue }
                  'Move-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
               }
            }
            else {
               Write-Error ('Error moving [{0}] {1} on {2}/{3} to DstLocation: {4} Status: {5} Code: {6} Message: {7}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,
                  $PSBoundParameters.DstLocation,$Response.Status,$Response.Code,$Response.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
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
