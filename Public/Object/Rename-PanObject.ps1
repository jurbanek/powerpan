function Rename-PanObject {
<#
.SYNOPSIS
Rename object(s)
.DESCRIPTION
Rename object(s)
.NOTES
Rename-PanObject provides feature coverage for many object types. It should NOT be called by its name. It is intended to be called by its aliases.
Find aliases: Get-Alias | Where-Object { $_.ResolvedCommandName -eq 'Rename-PanObject' }

Two modes: -InputObject mode and -Device mode.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
PanAddress[]
   You can pipe a PanAddress to this cmdlet
PanService[]
   You can pipe a PanService to this cmdlet
.OUTPUTS
PanAddress
.EXAMPLE
$D = Get-PanDevice "fw.lab.local"
Rename-PanAddress -Device $D -Location "vsys1" -Name "MyHostA" -NewName "H-1.1.1.1"
.EXAMPLE
Get-PanDevice "fw.lab.local" | Get-PanAddress -Location "vsys1" -Name "MyHostA" | Rename-PanAddress -NewName "H-1.1.1.1"
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
      [PanObject[]] $InputObject,
      [parameter(Mandatory=$true,ParameterSetName='Device',HelpMessage='Case-sensitive NEW name of object')]
      [parameter(Mandatory=$true,ParameterSetName='InputObject',HelpMessage='Case-sensitive NEW name of object')]
      [String] $NewName
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
            Write-Debug ('{0} (as {1}): InputObject Device: {2} Location: {3} Name: [{4}] {5} NewName: {6} ' -f
               $MyInvocation.MyCommand.Name,$MyInvocation.InvocationName, $InputObjectCur.Device.Name,$InputObjectCur.Location,$InputObjectCur.GetType().Name,$InputObjectCur.Name,$PSBoundParameters.NewName)
            $R = Invoke-PanXApi -Device $InputObjectCur.Device -Config -Rename -XPath $InputObjectCur.XPath -NewName $PSBoundParameters.NewName
            # Check PanResponse
            if($R.Status -eq 'success') {
               # Return newly renamed object to pipeline
               switch ($MyInvocation.InvocationName) {
                  'Rename-PanAddress' { Get-PanAddress -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue}
                  'Rename-PanService' { Get-PanService -Device $InputObjectCur.Device -Location $InputObjectCur.Location -Name $PSBoundParameters.NewName; continue}
                  'Rename-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
               }
            }
            else {
               Write-Error ('Error renaming [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                  $InputObjectCur.GetType().Name,$InputObjectCur.Name,$InputObjectCur.Device.Name,$InputObjectCur.Location,$R.Status,$R.Code,$R.Message)
            }
         } # End foreach InputObjectCur
      } # End ParameterSetName InputObject
      
      # ParameterSetName Device
      elseif($PSCmdlet.ParameterSetName -eq 'Device') {
         foreach($DeviceCur in $PSBoundParameters.Device) {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4} NewName: {5} ' -f 
               $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $DeviceCur.Name, $PSBoundParameters.Location, $PSBoundParameters.Name, $PSBoundParameters.NewName)
            # Given Device ParameterSet, fetch object for its XPath
            switch ($MyInvocation.InvocationName) {
               'Rename-PanAddress' { $Obj = Get-PanAddress -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Rename-PanService' { $Obj = Get-PanService -Device $DeviceCur -Location $PSBoundParameters.Location -Name $PSBoundParameters.Name; continue }
               'Rename-PanAddressGroup' { <# Future $Obj = Get-PanAddressGroup #> continue }
            }

            # Call API
            if($Obj) {
               $R = Invoke-PanXApi -Device $Obj.Device -Config -Rename -XPath $Obj.XPath -NewName $PSBoundParameters.NewName
               if($R.Status -eq 'success') {
                  # Return newly renamed object to pipeline
                  switch ($MyInvocation.InvocationName) {
                     'Rename-PanAddress' { Get-PanAddress -Device $Obj.Device -Location $Obj.Location -Name $PSBoundParameters.NewName; continue }
                     'Rename-PanService' { Get-PanService -Device $Obj.Device -Location $Obj.Location -Name $PSBoundParameters.NewName; continue }
                     'Rename-PanAddressGroup' { <# Future Get-PanAddressGroup #> continue }
                  }
               }
               # Failure on Invoke-PanXApi
               else {
                  Write-Error ('Error renaming [{0}] {1} on {2}/{3} Status: {4} Code: {5} Message: {6}' -f
                     $Obj.GetType().Name, $Obj.Name, $Obj.Device.Name, $Obj.Location, $R.Status, $R.Code, $R.Message)
               }
            }
            # Object by name was not found
            else {
               Write-Warning ('Rename {0} not found on {1}/{2}' -f $PSBoundParameters.Name, $DeviceCur.Name, $PSBoundParameters.Location)
            }
         } # End foreach DeviceCur
      } # End ParameterSetName Device
   } # Process block
   End {
   } # End block
} # Function
