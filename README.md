# PowerPAN - PowerShell Module for Palo Alto Networks NGFW

PowerPAN is a PowerShell module for the Palo Alto Networks NGFW

## Features

- Object model of PAN-OS XML-API and XML configuration as PowerShell cmdlets and objects
  - The objects modeled are few, but those modeled function well
- Persistent secure key/password storage of NGFW (called `PanDevice`) device credentials for use across PowerShell sessions (called `PanDeviceDb` internally, think of it as a simple device inventory).
  - Enables launching PowerShell and immediately "getting to work" *in the shell* without having to write scripts or deal with authentication
- "Anything imaginable" is doable with `Invoke-PanXApi`. The *more specific* cmdlets are mostly targeted at runtime operations and non-policy administrative use case cases.
- Mature models
  - `Invoke-PanXApi` provide low-level abstraction the PAN-OS XML-API. Nearly all other cmdlets call `Invoke-PanXApi` to interact with the XML-API
    - The capabilities of all future planned cmdlets can already be done with `Invoke-PanXApi` and logic, the future cmdlets will just make it easier.
  - `Invoke-PanCommit` to commit, validation, and seeing if pending changes exist.
  - `Invoke-PanSoftware` for PAN-OS operating system information, check, download, delete, and install.
  - `Invoke-PanHaState` to view and change high-availability *operational/runtime* state.
  - `Job` cmdlet to retrieve and view jobs (tasks)
  - `RegisteredIp` cmdlets to add registered-ip's and tag those IP's for use with Dynamic Address Groups (DAG)
  - `AddressObject` cmdlets to interact with PAN-OS address objects
  - `PanDeviceDb` and `PanDevice` cmdlets for managing the persistent secure storage of device credentials between PowerShell sessions
- Panorama Support
  - `Invoke-PanXApi` supports Panorama just fine. Mind Panorama's unique `XPath`'s when using it.
  - Many other cmdlets do not have or have limited Panorama support.
- PowerShell Support
  - Windows PowerShell 5.1
  - PowerShell 7.2 LTS (works on Windows and MacOS, as of 2024-09-18 have not tested Linux yet). PowerShell 7.2 LTS is end of support.
  - PowerShell 7.4 LTS (works on Windows and MacOS, as of 2025-02-21 have not tested Linux yet).
  - Other PowerShell versions will likely work, but will not be tested explicitly

## Status

PowerPAN is broadly considered experimental and incomplete, but certain parts of it do function well for production use cases.

## Install

Available from [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerPAN)

`Install-Module PowerPAN`

## Examples

### Create new PanDevice (add NGFW)

- PanDevice(s) created through `New-PanDevice` **persist** (stored) across subsequent PowerShell sessions
- No need to `New-PanDevice` every time, saves time

```powershell
# Name can be FQDN or IP address. Prompt for PAN-OS username and password using PSCredential (secure input)
New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen

# Retrieve PanDevice, test the API. Test-PanDevice returns a raw PanResponse, by design.
Get-PanDevice fw.lab.local | Test-PanDevice
```

Other examples for creating a new `PanDevice`. See `help New-PanDevice -Full` for full list of examples.

```powershell
# Supply username and password on the command-line (INSECURE input, but supported for non-interactive use cases). IPv4 address is supported as well.
New-PanDevice -Name "10.0.0.250" -Username "admin" -Password "admin123" -Keygen

# Validate NGFW x.509 SSL/TLS certificate is trusted by local PowerShell session. Validation is disabled by default. Per device setting is persists.
New-PanDevice -Name "fw.lab.local" -Credential $(Get-Credential) -Keygen -ValidateCertificate
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

### Jobs / Tasks

```powershell
# Get all jobs
Get-Device '10.0.0.1' | Get-PanJob
# or
Get-Device '10.0.0.1' | Get-PanJob -All

# Get specific job
Get-Device '10.0.0.1' | Get-PanJob -Id 2655

# Get pending jobs (not finished), using -Device and not pipe
$D = Get-Device '10.0.0.1'
Get-PanJob -Device $D -Pending
```

### PAN-OS Software Updates

```powershell
# Software manifest including known and installed versions of PAN-OS
Get-PanDevice fw.lab.local | Invoke-PanSofware -Info

# Check for software updates
Get-PanDevice fw.lab.local | Invoke-PanSofware -Check

# Download, using -Device, not piping
$D = Get-PanDevice fw.lab.local
$Job = Invoke-PanSoftware -Device $D -Download -Version '11.2.5'
Get-PanJob -Id $Job.Id

# Install
$D = Get-PanDevice fw.lab.local
$Job = Invoke-PanSoftware -Device $D -Install -Version '11.2.5'
Get-PanJob -Id $Job.Id
```

### Commit

```powershell
# Standard commit
$D = Get-PanDevice fw.lab.local
$Job = Invoke-PanCommit -Device $D -Commit -Full
# Monitor the job
Get-PanJob -Id $Job.Id

# Partial commit changes from 'admin1'
# See help Invoke-PanCommit for full list of partial scopes supported
$Job = Invoke-PanCommit -Device $D -Commit -Partial -Admin 'admin1'
# Monitor the job
Get-PanJob -Id $Job.Id

# Validate the candidate configuration
$Job = Invoke-PanCommit -Device $D -Validate -Full
# Monitor the job
Get-PanJob -Id $Job.Id

Get-PanDevice fw.lab.local | Invoke-PanCommit -PendingChanges
# returns $True or $Flase depending on whether changes are present in candidate config
```

### High-Availability State

```powershell
# High-Availability info/state
$D = Get-PanDevice fw.lab.local
$State = Invoke-PanHaState -Info
# HA administratively enabled ($True or $False)
$State.Enabled
# Local state 'active' or 'passive'
$State.LocalState
# Peer state 'active' or 'passive'
$State.PeerState
# Full details for local and peer
$State.Local
$State.Peer

# Change device HA operational mode to 'suspended'
Get-PanDevice fw.lab.local | Invoke-PanHaState -Suspend
# And back to functional
Get-PanDevice fw.lab.local | Invoke-PanHaState -Functional
```

### Invoke-PanXApi

`Invoke-PanXApi` abstracts the PAN-OS XML-API and can be used to accomplish everything PowerPAN does not have more specific cmdlets to already achieve

- Returns a `PanResponse` object which includes the raw API responses
- Supports nearly all XML-API operations supported by PAN-OS, including all Config *(Get, Show, Set, Edit, Delete)* and Operational. Read the source or `help Invoke-PanXApi` in-line help for details.
- All `PowerPAN` cmdlets use `Invoke-PanXApi` under the hood to interact with the PAN-OS XML-API
- While Panorama is not supported or limited support by the *more-specific* abstracted cmdlets, Panorama is well-supported by `Invoke-PanXApi`
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
| Version       | `Invoke-PanXApi <...> -Version`   | Easy way to test API,, but consider `Test-PanDevice` |
| Commit        | `Invoke-PanXApi <...> -Commit`   | Commit, but consider `Invoke-PanCommit` |
| Operational   | `Invoke-PanXApi <...> -Op -Cmd '<show><system><info></info></system></show>'` | Operational (exec CLI commands). Not all are valid |
| User-ID       | `Invoke-PanXApi <...> -Uid -Cmd '<uid-message>...</uid-message>'`   | User-ID operations. Registered-IP operations also use this type |
| Keypair       | `Invoke-PanXApi <...> -Import -Category keypair -File 'C:/path/to/cert.p12' -CertName 'gp-acme-com' -CertFormat 'pkcs12' -CertPassphrase 'asdf1234'`| Certificate with private key |
| Certificate   | `Invoke-PanXApi <...> -Import -Category certificate -File 'C:/path/to/cert.cer' -CertName 'ACME-Intermediate' -CertFormat 'pem' -CertPassphrase 'asdf1234'`| Certificate without private key |

### PanDeviceDb / Device Management Labels

One of the key features of PowerPAN is to enable rapid "open a terminal/console session and query my firewall quickly" without having to deal with generating API keys. To that end, device profiles are stored on disk in the user's home/profile directory. The device profile contains an encrypted version of the API key that is only decryptable when executing within the user's profile (using serialized `SecureString`).

**Example:**
Day 1 you create a new PanDevice and then run a few cmdlets against it

```powershell
New-PanDevice -Name '10.0.0.1' -Credential $(Get-Credential) -Keygen

Get-PanDevice '10.0.0.1' | Get-PanRegisteredIp
```

Day 5 you come back, open up your terminal and can reuse the PanDevice from earlier. No need to generate new API keys.

```powershell
Get-PanDevice '10.0.0.1' | Get-PanRegisteredIp
```

Let's say you want to keep the connection string as the IP address, but add a friendly name (a label).

```powershell
Get-PanDevice '10.0.0.1' | Add-PanDeviceLabel 'ACME-3420A'
```

Now you can reference the label when fetching it

```powershell
# Note the -Label argument is required
Get-PanDevice -Label 'ACME-3420A'
```

To see (and fetch) all devices (and their lablels)

```powershell
Get-PanDevice -All
```

More than one label can be added to devices

```powershell
# During creation
New-PanDevice -Name '10.0.0.1' -Credential $(Get-Credential) -Keygen -Label 'ACME-3420A','Site23'
# Or after the fact
Get-PanDevice '10.0.0.1' | Add-PanDeviceLabel 'ACME-3420A','Site23'
```

If multiple devices have the same label, they will be returned together when that label is requested.

- Make some labels unique, use others for grouping. 
- Most PowerPAN cmdlets accept multiple PanDevices as input. Of course, you can always take more control of multi-firewall processing with your own `foreach` loops.

### File Uploads (Useful for uploading Certificates)

Consider using [Posh-ACME](https://poshac.me/docs/v4/) to generate Let's Encrypt (or other ACME compatible CA) certificates and PowerPAN to perform the certificate upload to the firewall and subsequent processing.

Full Posh-ACME workflow is **not** included below. After you generate with Posh-ACME:

```powershell
# Snippet below conveys usage/idea. Production use would include more Posh-ACME, logic, and use of variables instead of string literals.
$D = Get-PanDevice '10.0.0.1'
# Don't be confused by the "PA" prefix of Posh-ACME cmdlets. It does not stand for Palo Alto :)
# Assumes you've already generated with New-PACertificate or Submit-Renewal
$LECert = Get-PACertificate

# Add -Debug and -Verbose if you want to see more detail
# -Category 'keypair' is for certificate including private key. -Category 'certificate' is for certificate only
# Consider appending an ISO8601 date suffix representing issue date on the end, especially when renewing every 30/60 days
$R = Invoke-PanXApi -Device $D -Import -Category 'keypair' -File $LECert.Pfxfile -CertName 'gp.acme.io-20250221' -CertFormat 'pkcs12' -CertPassphrase 'SameUsedbyPoshACME'
if($R.Status -eq 'success') {
  Write-Host ('Upload successful')
}
else {
  Write-Error ('Upload not successful Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message) -ErrorAction Stop
}

# Optionally, update a SSL/TLS Service Profile to use the certificate
$XPath = "/config/shared/ssl-tls-service-profile/entry[@name='{0}']" -f 'GP-Portal-Gateway-Profile'
$Element = "<certificate>{0}</certificate>" -f 'gp.acme.io-20250221'
$R = Invoke-PanXApi -Device $D -Config -Set -XPath $XPath -Element $Element
if($R.Status -eq 'success') {
  Write-Host ('Update successful')
}
else {
  Write-Error ('Update not successful Status: {0} Code: {1} Message: {2}' -f $R.Status,$R.Code,$R.Message) -ErrorAction Stop
}
