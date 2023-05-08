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

<sub>`PowerPAN' is available from [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerPAN)</sub>

`Install-Module PowerPAN`

## Examples

### Create new PanDevice (add NGFW)

- PanDevice(s) created through `New-PanDevice` **persist** (stored) across subsequent PowerShell sessions
- No need to `New-PanDevice` every time, saves time

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

- registered-ip's are **not** address objects
- They are not visible in the CANDIDATE or ACTIVE config; they are commitless. They persist across reboots (yep).
- registered-ip tags are frequently used in dyanmic address group (DAG) match criteria

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

### Invoke-PanXApi

`Invoke-PanXApi` abstracts the PAN-OS XML-API and can be used to accomplish everything PowerPAN does not have more specific cmdlets to already achieve

- Returns a `PanResponse` object which includes the raw API responses
- Supports nearly all XML-API operations supported by PAN-OS, including all Config *(Get, Show, Set, Edit, Delete)* and Operational. Read the source or in-line help for details.
- All `PowerPAN` cmdlets use `Invoke-PanXApi` under the hood to interact with the PAN-OS XML-API
- While Panorama is not supported by the *more-specific* abstracted cmdlets, Panorama is well-supported by `Invoke-PanXApi`
- To find `XPath`'s
  - Authenticate to standard GUI `https://<fwip>` (or Panorama)
  - New tab to `https://<fwip>/api` (or Panorama) and browse away
  - For more complicated operations workflows, use `https://<fwip>/debug` (or Panorama)
    - Simulate what is needed in standard GUI
    - Monitor the debug
- More at <https://pan.dev/panos/docs/xmlapi/>

```powershell
# Using Get-PanDevice
Get-PanDevice <...> | Invoke-PanXApi <...>
# Or directly, -Device must be a [PanDevice] object
Invoke-PanXApi -Device $Device <...>

# Get all service objects
Invoke-PanXApi -Device $Device -Config -Get -XPath "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']/service"
# Get a specific service object
Invoke-PanXApi -Device $Device -Config -Get -XPath "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']/service/entry[@name='tcp-443']"
```

#### Type

| Type          | PowerPAN | Note |
| ------------- | -------- | ---- |
| Config Show   | `Invoke-PanXApi <...> -Config -Show -XPath '/config/xpath...'` | Retrieves ACTIVE configuration |
| Config Get    | `Invoke-PanXApi <...> -Config -Get -XPath '/config/xpath...'`  | Retrieves CANDIDATE configuration |
| Config Set    | `Invoke-PanXApi <...> -Config -Set -XPath '/config/xpath...' -Element '<example>value</example>'`   | Add, update, merge. Non-destructive, only additive |
| Config Edit   | `Invoke-PanXApi <...> -Config -Edit -XPath '/config/xpath...' -Element '<example>value</example>'`   | Replace configuration node. Can be destructive |
| Config Delete | `Invoke-PanXApi <...> -Config -Delete -XPath '/config/xpath...'`   | Delete configuration. Destructive |
| Version       | `Invoke-PanXApi <...> -Version`   | Easy way to test API |
| Commit       |  `Invoke-PanXApi <...> -Commit`   | Commit |
| Operational   | `Invoke-PanXApi <...> -Op -Cmd '<show><system><info></info></system></show>'`   | Operational (exec CLI commands). Not all are valid |
| User-ID       | `Invoke-PanXApi <...> -Uid -Cmd '<uid-message>...</uid-message>'`   | User-ID operations. Registered-IP operations also use this type |
| Keypair       | `Invoke-PanXApi <...> -Category keypair -File 'C:/path/to/cert.p12' -CertName 'gp-acme-com' -CertFormat 'pkcs12' -CertPassphrase 'asdf1234'`| Certificate with private key |
| Certificate   | `Invoke-PanXApi <...> -Category certificate -File 'C:/path/to/cert.cer' -CertName 'ACME-Intermediate' -CertFormat 'pem' -CertPassphrase 'asdf1234'`| Certificate without private key |

### Device Management Tags
