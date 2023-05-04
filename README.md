# PowerPAN - PowerShell Module for Palo Alto Networks NGFW

PowerPAN is a PowerShell module for the Palo Alto Networks NGFW

## Features

- Object model of PAN-OS XML-API and XML configuration as PowerShell cmdlets and objects
  - The objects modeled are few, but those modeled function well
- Persistent secure storage of NGFW (called `PanDevice`) device credentials for use across PowerShell sessions (called `PanDeviceDb` internally)
  - Enables launching PowerShell and immediately "getting to work" *in the shell* without having to write scripts or deal with authentication
- Mature models
  - `Invoke-PanXApi` to abstract the PAN-OS XML-API. Nearly all other cmdlets call `Invoke-PanXApi` to interact with the XML-API
    - The capabilities of all future planned cmdlets can already be done with `Invoke-PanXApi` and logic, the future cmdlets will just make it easier.
  - `RegisteredIp` cmdlets to add registered-ip's and tag those IP's for use with Dynamic Address Groups (DAG)
  - `AddressObject` cmdlets to interact with PAN-OS address objects
  - `PanDeviceDb` and `PanDevice` cmdlets for managing the persistent secure storage of device credentials between PowerShell sessions
- Panorama Support
  - `Invoke-PanXApi` supports Panorama just fine. Mind Panorama's unique `XPath`'s when using it.
  - Other cmdlets do not yet have native Panorama support
- PowerShell Support
  - Windows PowerShell 5.1
  - PowerShell 7.2 LTS (as of 2023-04-05 have not tested Linux/Mac yet)
  - Other versions will likely work, but these will be tested

## Status

PowerPAN is broadly considered experimental and incomplete, but certain parts of it do function well for production use cases.

## Install

`Install-Module PowerPAN`

## Examples

### Create new PanDevice (add NGFW)

*PanDevice(s) created through New-PanDevice **persist** (stored) across subsequent PowerShell sessions. No need to `New-PanDevice` every time.*

```powershell
# Name can be FQDN or IP address. Prompt for PAN-OS username and password using PSCredential (secure input)
New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen

# Supply username and password on the command-line (INSECURE input, but supported). IPv4 address is supported as well.
New-PanDevice -Name "10.0.0.250" -Username "admin" -Password "admin123" -Keygen

# Validate NGFW x.509 SSL/TLS certificate is trusted by local PowerShell session. Validation is disabled by default. Per device setting is persists.
New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen -ValidateCertificate

# Retrieve PanDevice, test the API (technically, New-PanDevice already tests, but can be used on subsequent PS sessions to verify)
Get-PanDevice fw.lab.local | Test-PanDevice
```

### Retrieve address objects

```powershell
Get-PanDevice fw.lab.local | Get-PanAddress

# For every PanDevice (stored), retrieve their address objects
Get-PanDevice -All | Get-PanAddress
```

### Registered-IP Tagging (to populate Dynamic Address Groups)

*registered-ip's are **not** address objects. They do **not** modify the candidate-config or running-config; they are commitless. The registered-ip tags are frequently used in dyanmic address group (DAG) match criteria.*

```powershell
# Add the tag to the registered-ip. Creates a new registered-ip if doesn't already exist.
Get-PanDevice fw.lab.local | Add-PanRegisteredIp -Ip '1.1.1.1' -Tag 'MyTag'

# Add both tags to both registered-ip's. Creates new registered-ip's if doesn't already exist.
Get-PanDevice -All | Add-PanRegisteredIp -Ip '1.1.1.1','2.2.2.2' -Tag 'ThisTag','ThatTag'

# Remove the registered-ip (which essentially removes all tags from the registered-ip). Can specify more than one registered-ip.
Get-PanDevice fw.lab.local | Remove-PanRegisteredIp -Ip '1.1.1.1'

# Remove the tag from any and all registered-ip where it might be present. Can specify more than one tag.
Get-PanDevice fw.lab.local | Remove-PanRegisteredIp -Tag 'ThisTag'

# Remove the tag from the registered-ip, if present. Other tags on the registered-ip are unaffected.
Get-PanDevice fw.lab.local | Remove-PanRegisteredIp -Ip '1.1.1.1' -Tag 'ThisTag'
```

### Device Management Tags

### Invoke-PanXApi
