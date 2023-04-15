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

### Device Management

#### 1

#### 2

#### 3

### Device Management Tags

#### 1

#### 2

#### 3

### Invoke-PanXApi

#### 1

#### 2

#### 3

### Registered-IP Tagging

#### 1

#### 2

#### 3
