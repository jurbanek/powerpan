function Construct-PanObject {
<#
.SYNOPSIS
Creates a new object locally, NOT on the Device. Use in place of calling ::new() constructors.
.DESCRIPTION
Creates a new object locally, NOT on the Device. Use in place of calling ::new() constructors.
Workaround to PowerShell GitHub issue 2449.
.NOTES
Most users should NEVER have to use this cmdlet and should almost always use Set- instead.
It is present for advanced scripting purposes only as a workaround to PowerShell issue 2449 affecting
script based modules and class availability outside the module.

Intended to be used to create objects instead of calling their ::new() class constructors directly as
the class constructors are not available outside the module.
PowerShell GitHub issue 2449 https://github.com/PowerShell/PowerShell/issues/2449

Uses an unapproved Construct- verb instead of New- by design to distinguish its unique semantics.

:: Usage ::
# Instead of this (does not work given issue 2449)
$A = [PanAddress]::new($Name,$Device,$Location)
# Do this
$A = Construct-PanAddress -Name $Name -Device $Device -Location $Location

# Instead of this
$S = [PanService]::new($Name,$Device,$Location)
# Do this
$S = Construct-PanService -Name $Name -Device $Device -Location $Location

Creates a minimally viable object. Finish the object by assigning values to the object's properties.

# For a [PanAddress], like below
$A = Construct-PanAddress -Name $Name -Device $Device -Location $Location
$A.Type = 'ip-netmask'
$A.Value = '10.0.0.100'
.INPUTS
None
.OUTPUTS
PanAddress
PanService
PanAddressGoup
PanServiceGroup
.EXAMPLE
$D = Get-PanDevice -Name "fw.lab.local"
$A = Construct-PanAddress "MyAddress" -Device $D -Location "vsys1"
$A.Type = 'ip-netmask'
$A.Value = '10.0.0.100'
$A.Description = 'My Description'
$A.Tag = @('review')
$A | Set-PanAddress

The example can be used to create an object *without* immediately creating/updating it on the Device.
Mostly for advanced scripting purposes.

For normal usage, just use Set-PanAddress directly like below which will create/update the PanAddress on the Device.

Set-PanAddress -Device $D -Location "vsys1" -Name "MyAddress" -Type "ip-netmask" -Value "10.0.0.100" -Description "My Description" -Tag @("review")
#>
    [CmdletBinding()]
    param(
        [parameter(ParameterSetName='NonXML',Mandatory=$true,HelpMessage='PanDevice')]
        [parameter(ParameterSetName='XML',Mandatory=$true,HelpMessage='PanDevice')]
        [PanDevice] $Device,
        [parameter(ParameterSetName='NonXML',Mandatory=$true,HelpMessage='Case-sensitive location: vsys1, shared, DeviceGroupA, etc.')]
        [String] $Location,
        [parameter(ParameterSetName='NonXML',Mandatory=$true,HelpMessage='Case-sensitive name of object')]
        [String] $Name,
        [parameter(ParameterSetName='XML',Mandatory=$true,HelpMessage='Object full XPath including entry[@name]')]
        [String] $XPath,
        [parameter(ParameterSetName='XML',Mandatory=$true,HelpMessage='XmlDocument representing object from <entry> to </entry>')]
        [System.Xml.XmlDocument] $XDoc
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
        if($PSCmdlet.ParameterSetName -eq 'NonXML') {
            Write-Debug ('{0} (as {1}): Device: {2} Location: {3} Name: {4}' -f 
                $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $PSBoundParameters.Device.Name, $PSBoundParameters.Location, $PSBoundParameters.Name)
            switch($MyInvocation.InvocationName) {
                # Call constructors *not requiring* XML content
                'Construct-PanAddress'      { [PanAddress]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
                'Construct-PanService'      { [PanService]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
                'Construct-PanAddressGroup' { [PanAddressGroup]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
                'Construct-PanServiceGroup' { [PanServiceGroup]::new($PSBoundParameters.Device,$PSBoundParameters.Location,$PSBoundParameters.Name); continue }
            }
        }
        elseif($PSCmdlet.ParameterSetName -eq 'XML') {
            Write-Debug ('{0} (as {1}): Device: {2} XPath: {3} XDoc: {4}' -f 
                $MyInvocation.MyCommand.Name, $MyInvocation.InvocationName, $PSBoundParameters.Device.Name, $PSBoundParameters.XPath, $PSBoundParameters.XDoc.OuterXml)
            switch($MyInvocation.InvocationName) {
                # Call constructors *requiring* XML content
                'Construct-PanAddress'      { [PanAddress]::new($PSBoundParameters.Device,$PSBoundParameters.XPath,$PSBoundParameters.XDoc); continue }
                'Construct-PanService'      { [PanService]::new($PSBoundParameters.Device,$PSBoundParameters.XPath,$PSBoundParameters.XDoc); continue }
                'Construct-PanAddressGroup' { [PanAddressGroup]::new($PSBoundParameters.Device,$PSBoundParameters.XPath,$PSBoundParameters.XDoc); continue } 
                'Construct-PanServiceGroup' { [PanServiceGroup]::new($PSBoundParameters.Device,$PSBoundParameters.XPath,$PSBoundParameters.XDoc); continue } 
            }
        }
    } # Process block
    
    End {
    } # End block
} # Function
