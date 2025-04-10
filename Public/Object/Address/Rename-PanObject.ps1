function Rename-PanObject {
<#
.SYNOPSIS
Rename address object in candidate configuration
.DESCRIPTION
Rename address object in candidate configuration
.NOTES
There are two modes, -InputObject mode and -Device mode.

Rename-PanObject is intended to be called by it's aliases (Remove-PanAddress, Remove-PanService, etc.)
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
.OUTPUTS
PanAddress
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
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive NEW name of address object')]
      [parameter(Mandatory=$true,ParameterSetName='InputObject',HelpMessage='Case-sensitive NEW name of address object')]
      [String] $NewName
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ('{0} (as {1}):' -f $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName)
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5} NewName: {6} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,$InputObjectCur.Name,$PSBoundParameters.NewName)
            $Response = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Rename -XPath $InputObjectCur.XPath -NewName $PSBoundParameters.NewName
            # Check PanResponse
            if($Response.Status -eq 'success') {
               # Return newly renamed object to pipeline
               if($PSBoundParameters.InputObject.GetType().Name -eq 'PanAddress') {
                  Get-PanAddress -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName
               }
               elseif($PSBoundParameters.InputObject.GetType().Name -eq 'PanAddressGroup') {
                  # Future planning
                  # Get-PanAddressGroup...
               }
            }
            else {
               Write-Error ('Error renaming [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$Response.Status,$Response.Code,$Response.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4} NewName: {5} ' -f 
               $MyInvocation.MyCommand.Name, $MyInvoCation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location, $PSBoundParameters.Name, $PSBoundParameters.NewName)
            # Rename-PanAddress
            if($MyInvocation.InvocationName -eq 'Rename-PanAddress') {
               $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name
            }
            elseif($MyInvocation.InvocationName -eq 'Rename-PanAddressGroup') {
               # Future planning
               # $Obj = Get-PanAddressGroup...
            }

            # Call API
            if($Obj) {
               $Response = Invoke-PanXApi -Device $Obj.Device -Config -Rename -XPath $Obj.XPath -NewName $PSBoundParameters.NewName
               if($Response.Status -eq 'success') {
                  # Return newly renamed object to pipeline
                  if($Obj.GetType().Name -eq 'PanAddress') {
                     Get-PanAddress -Device $Obj.Device -Location $Obj.Location -Name $PSBoundParameters.NewName
                  }
                  elseif($Obj.GetType().Name -eq 'PanAddressGroup') {
                     # Future planning
                     # Get-PanAddressGroup...
                  }
               }
               # Failure on Invoke-PanXApi
               else {
                  Write-Error ('Rename [{0}] {1} failed on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $Response.Status, $Response.Code, $Response.Message)
               }
            }
            # Object by name was not found
            else {
               Write-Warning ('Rename {0} not found on {1}/{2}' -f $PSBoundParameters.Name, $DeviceCur.Name, $PSBoundParameters.Location)
            }
         } # End foreach DeviceCur
      } # End ParameterSetName Device
      #>
   } # Process block
   End {
   } # End block
} # Function
