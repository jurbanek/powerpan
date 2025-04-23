function New-PanObject {
<#
.SYNOPSIS
Creates a new shell object instead of calling ::new() constructors. Does NOT create object on Device.
.DESCRIPTION
Creates a new shell object instead of calling ::new() constructors to workaround PowerShell issue 2449. Does NOT create object on Device.
.NOTES
***Most users should NEVER have to use this and should almost always use Set- instead***
It is present for advanced scripting purposes only as a workaround to PowerShell issue 2449 affecting
Script based modules and class availability outside the module.

This cmdlet (advanced function, technically) is intended to be used to create objects instead of calling
their class constructors directly as the class constructors are not available outside the module.
PowerShell issue 2449 https://github.com/PowerShell/PowerShell/issues/2449

:: Usage ::
$A = [PanAddress]::new($Name,$Device,$Location) # Instead of this (does not work given issue 2449)
$A = New-PanAddress -Name $Name -Device $Device -Location $Location # Do this

$S = [PanService]::new($Name,$Device,$Location) # Instead of this
$S = New-PanService -Name $Name -Device $Device -Location $Location # Do this

It creates a *shell* of an object. Finish the object by assigning values to the object's properties.

For a [PanAddress], like below

$A = New-PanAddress -Name $Name -Device $Device -Location $Location
$A.Type = 'ip-netmask'
$A.Value = '10.0.0.100'
.INPUTS
None
.OUTPUTS
PanAddress
PanService
.EXAMPLE
$D = Get-PanDevice -Name "fw.lab.local"
$A = New-PanAddress "MyAddress" -Device $D -Location "vsys1"
$A.Type = 'ip-netmask'
$A.Value = '10.0.0.100'
$A | Set-PanAddress

The above example can be used to create an object without immediately applying it with Set-PanAddress,
mostly for advanced scripting purposes.

For normal usage, just use Set-PanAddress directly like below which will apply the PanAddress to the Device

Set-PanAddress -Device $D -Location "vsys1" -Name "MyAddress" -Type "ip-netmask" -Value "10.0.0.100"
#>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,HelpMessage='PanDevice')]
        [PanDevice] $Device,
        [parameter(Mandatory=$true,HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
        [String] $Location,
        [parameter(Mandatory=$true,HelpMessage='Case-sensitive name of object')]
        [String] $Name
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
        Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4}' -f 
            $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $PSBoundParameters.Device.Name, $PSBoundParameters.Location, $PSBoundParameters.Name)
        switch($MyInvocation.InvocationName) {
            # Call constructors not requiring XML content
            'New-PanAddress' { [PanAddress]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
            'New-PanService' { [PanService]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
            'New-PanAddressGroup' { continue } # Future 
        }        
    } # Process block
    
    End {
    } # End block
} # Function
