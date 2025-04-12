function Remove-PanObject {
<#
.SYNOPSIS
Remove (delete) object(s) (multiple types)
.DESCRIPTION
Remove (delete) multiple object types from a single cmdlet based on the alias used
.NOTES
Remove-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases:
   Remove-PanAddress
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
      [parameter(Mandatory=$true,ParameterSetName='Device',ValueFromPipeline=$true,HelpMessage='PanDevice against which address object(s) will be applied')]
      [PanDevice[]] $Device,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
      [String] $Location,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive name of address object')]
      [String] $Name,
      [parameter(Mandatory=$true,Position=0,ParameterSetName='InputObject',ValueFromPipeline=$true,HelpMessage='PanAddress input object(s) to be applied as is')]
      [PanAddress[]] $InputObject
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
   } # Begin Block

   Process {
      # ParameterSetName InputObject, applies for every $MyInvocation.InvocationName (any alias)
      if($PSCmdlet.ParameterSetName -eq 'InputObject') {
         foreach($InputObjectCur in $PSBoundParameters.InputObject) {
            Write-Debug ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5}' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,$InputObjectCur.Name)
            $Response = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Delete -XPath $InputObjectCur.XPath
            # Check PanResponse
            if($Response.Status -eq 'success') {
               # Nothing to do on successful delete
            }
            else {
               Write-Error ('Error deleting [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$Response.Status,$Response.Code,$Response.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4}' -f 
               $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location, $PSBoundParameters.Name)
            # Given -Device ParameterSet, fetch the object for its XPath
            switch ($MyInvocation.InvocationName) {
               'Remove-PanAddress' { $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue}
               'Remove-PanAddressGroup' { <# Future $Obj = Get-PanAddressGroup #> continue }
            }

            # Call API
            if($Obj) {
               $Response = Invoke-PanXApi -Device $Obj.Device -Config -Delete -XPath $Obj.XPath
               if($Response.Status -eq 'success') {
                  # Nothing to do on successful delete
               }
               else {
                  Write-Error ('Error deleting [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $Response.Status, $Response.Code, $Response.Message)
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
