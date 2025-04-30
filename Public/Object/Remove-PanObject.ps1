function Remove-PanObject {
<#
.SYNOPSIS
Remove (delete) object(s)
.DESCRIPTION
Remove (delete) object(s)
.NOTES
Remove-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases.
Find aliases: Get-Alias | Where-Object { $_.ResolvedCommandName -eq 'Remove-PanObject' }

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
$D = Get-PanDevice "fw.lab.local"
Remove-PanAddress -Device $D -Location "vsys1" -Name "MyHostA"
.EXAMPLE
Get-PanDevice "fw.lab.local" | Remove-PanAddress -Location "vsys1" -Name "MyHostA"
.EXAMPLE
Get-PanDevice "fw.lab.local" | Get-PanAddress | Where-Object {$_.Value -match "^10\.16\."} | Remove-PanAddress
.EXAMPLE
Get-PanDevice "fw.lab.local" | Get-PanAddress | Where-Object {"test" -in $_.Tag} | Remove-PanAddress
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice to target')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
      [String] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive name of object')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='Input object(s) to target')]
      [PanObject[]] $InputObject
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
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Verbose ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5}' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,$InputObjectCur.Name)
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Delete -XPath $InputObjectCur.XPath
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Nothing to do on successful delete
            }
            else {
               Write-Error ('Error deleting [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Verbose ('{0} (as {1}): Device: {2} Location: {3} Name: {4}' -f 
               $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location, $PSBoundParameters.Name)
            # Update Location if past due
            if($PSBoundParameters.Device.LocationUpdated.AddSeconds($Global:PanDeviceLocRefSec) -lt (Get-Date)) { Update-PanDeviceLocation -Device $PSBoundParameters.Device }
            
            # Given -Device ParameterSet, fetch the object for its XPath
            switch ($MyInvocation.InvocationName) {
               'Remove-PanAddress'        { $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Remove-PanService'        { $Obj = Get-PanService -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Remove-PanAddressGroup'   { $Obj = Get-PanAddressGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Remove-PanServiceGroup'   { $Obj = Get-PanServiceGroup -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
            }

            # Call API
            if($Obj) {
               $R = Invoke-PanXApi -Device $Obj.Device -Config -Delete -XPath $Obj.XPath
               if($R.Status -eq 'success') {
                  # Nothing to do on successful delete
               }
               else {
                  Write-Error ('Error deleting [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $R.Status, $R.Code, $R.Message)
               }
            }
            # Object by name was not found
            else {
               Write-Warning ('Delete {0} not found on {1}/{2}' -f $PSBoundParameters.Name, $DeviceCur.Name, $PSBoundParameters.Location)
            }
         } # End foreach DeviceCur
      } # End ParameterSetName Device
   } # Process block
   End {
   } # End block
} # Function
