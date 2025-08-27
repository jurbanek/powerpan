# PowerPAN Changelog

All notable changes to this project will be documented in this file.

## 0.5.6 2025-08-27

### Changed

 - Changed `TimeoutSec` parameter default value to 45 (from 15) within `Invoke-PanXApi`. There is no perfect number, but a few months of usage has led me to believe 45 is a better default value.
  - Some older or slower firewalls frequently take more than 15 seconds to send HTTP response headers. A good example is a check for new software updates with `Invoke-PanSoftware -Check`. The HTTP response headers aren't returned until the PAN hosted update server results are returned and processed.
  - This specific change has zero effect during working conditions. It will however, increase the amount of time it takes to detect an unreachable firewall/Panorama (from 15 to 45 seconds, or just Ctrl-C).
  - PS 7.4+ made a few changes to the way the underlying `Invoke-WebRequest -TimeoutSec` parameter is used (which `Invoke-PanXApi -TimeoutSec` parameter maps to), but not relevant at this time.
   - PS 7.4+ changes: [https://github.com/PowerShell/PowerShell/pull/19558](https://github.com/PowerShell/PowerShell/pull/19558)

## 0.5.5 2025-05-07

### Added

- Added optional `TimeoutSec` parameter to `Invoke-PanXApi`. Used to control the amount of time to wait for initial connection timeout. Underlying defaults of `Invoke-WebRequest` at `100` is far too high. New default is `15`.

### Changed

- Fixed issue where calling `New-PanDevice` could generate and display an an innocuous inconsequential error (but annoying and confusing) related to the Location refresh interval.
- Improved `Write-Verbose` output in `Invoke-PanXApi`

## 0.5.4 2025-05-01

### Added

- `Get-PanDynamicAddressGroup` cmdlet to get runtime members of Dynamic Address Groups (DAG). Required a separate cmdlet for situations where the DAG is defined in Panorama, but the runtime information is needed from a NGFW (which is very common with Panorama deployments). Trying to integrate the functionality into the existing `Get-PanAddressGroup` (not dynamic) made the user-experience too clumsy.

### Changed

- Migrated all cmdlets from `Write-Debug` to `Write-Verbose` to align with PowerShell best practices. To see additional details, just use `-Verbose`.
- Internal redesign of how `[PanObject]` performs `Update-Type`. Derived classes now call static methods like `[PanObject]::AddName(('PanAddress')` to have the `Name` property added. Increases flexibility for some derived classes that need only a subset of properties available in the base class.

## 0.5.3 2025-04-27

### Changed

- Resolved issue in *some* (not all, which is infuriating) Windows PowerShell 5.1 sessions where Windows PowerShell 5.1 was unable to locate and load the `[System.Web.Script.Serialization.JavaScriptSerializer]` class. Explicitly loading it via `Add-Type` now.

## 0.5.2 2025-04-27

### Changed

- Eliminated PowerShell console message errors when importing an empty PanDeviceDb on-disk inventory (the import did work fine, empty). Reworked the logic to avoid the console messages.
  - (Windows PowerShell 5.1 previous workarounds still coming to bite)

## 0.5.1 2025-04-27

### Changed

- `[PanDevice]` `Location` property refresh logic has been updated to be more user friendly.
  - Location mappings (vsys to XPath, device-group to XPath, etc.) now persist to disk when new devices are created and anytime there is a change/diff/update to the Location property.
  - Default update interval is no more than once every 15 minutes. Leave your PowerShell session open for a long time and come back later, the next call that requires a `-Location` parameter will under-the-hood refresh the Location map (in case you've created a new `vsys` or `device-group`).
  - `Get-PanDevice` does *not* exclusively *gate* the logic to `Update-PanDeviceLocation` anymore in an effort to speed up `Get-PanDevice` calls when entering a new PowerShell session.
  - Any cmdlet using `[PanDevice]` `Location` property (anything accepting a `-Location` parameter) first ensures the property has been updated.
  - Create a bunch of device-groups in Panorama and don't want to wait for Location map to be updated? Can force a manual check at any time using `Update-PanDeviceLocation -Device $P -Force`.
- Ran into some odd issues with Windows PowerShell 5.1 during testing when storing the in-memory PanDeviceDb in a `[System.Collections.Generic.List[PanDevice]]` List. Fundamental behavior that's been working for years (and would work, sometimes... during troubleshooting and testing) no longer reliable.
  - Sometimes Windows PowerShell 5.1 and the use of custom classes just gets weird. Getting a bit tired of all the workarounds for Windows PowerShell 5.1.
  - Resolved it by modifying the in-memory PanDeviceDb container to be a standard PowerShell array `@()` instead of a `List`.
  - During heavy addition and removal of elements an array uses more resources (compared to `List` at high add/remove), but computers are fast, it simplifies the code and works well in all PowerShell versions.
- Resolved an issue with exporting the inventory file if PanDeviceDb was empty. Required updates to `Remove-PanDevice` and private `ExportPanDeviceDb`.
- Resolved an issue with on-disk PanDeviceDb Labels not being imported correctly in 0.5.0 by private `ImportPanDeviceDb` -- weren't making it to in-memory PanDeviceDb. Which means there was no Label to serialize on export and on-disk stored Labels *could* have been lost.

## 0.5.0 2025-04-26

Primary focus of `0.5.0` is a re-imagining of the PowerPAN internal data model to store PAN-OS objects (addresses, address groups, service, service groups, and more to come). The changes are non-breaking, but enable *significantly* simpler and faster development while enabling more features by letting `[System.Xml.***]` types/classes "do more of the work".

- Each PowerPAN object representing a PAN-OS address, etc. now includes native XML components. Principally a `[System.Xml.XmlDocument] $XDoc` property represents the object's configuration in XML and a `[String] $XPath` property represents the location of the object within PAN-OS.
- Expected properties like `Name` and `Value` are also available, of course, but have been changed to be `ScriptProperty` that get/set content within the `$XDoc` or `$XPath`. Manipulate the `$XDoc` or `$XPath` and `$Name` and `$Value` update automatically, or visa-versa. They are "linked" together because of the latter being a `ScriptProperty`.
- This simple (and now obvious) redesign of the internal data model should have been done from the beginning. Since *PAN-OS* natively uses XML everywhere, it is useful for *PowerPAN* to keep as much of the XML as possible to *minimize* the code required to parse when fetching and re-create *from-scratch* when sending.

This model was **not** adopted originally because I didn't know much about `[System.Xml.XmlNode]`, `[System.Xml.XmlDocument]`, `[System.Xml.XmlElement]`, the entire `[System.Xml] tree, all their properties, methods, and manners of "how does one *effectively* work with XML" in .NET. Frankly, in 2018 when this side-project started I originally wanted the "XML burden" to be gone as quickly as possible. In reality, my ignorance was making the entire set of project goals significantly harder.

Alas, here we are. New data model available to make additional cmdlet development quicker and easier.

### Added
- `[PanAddress]`, `[PanService]`, `[PanAddressGroup]`, and `[PanServiceGroup]` classes and object types with internal XML driven data structure mirroring the PAN-OS configuration. These inherit from a base `[PanObject]` class.
- `Get-PanObject`, `Set-` specific cmdlets, `Copy-PanObject`, `Move-PanObject`, `Remove-PanObject`, `Rename-PanObject`, `Construct-Pan-Object` and the suite of aliases required for `[PanAddress]`, `[PanService]`, `[PanAddressGroup]`, and `[PanServiceGroup]` object types.
- Improved Panorama support given downstream effects of new data model.
- `[PanDevice]` `Type` property is either `[PanDeviceType]::Panorama` or `[PanDeviceType]::Ngfw`
- []
- `Invoke-PanXApi` support for `-Config -Rename`, `-Config -Move`, `-Config -MultiMove`, `-Config -Clone`, `-Config -MultiClone`
- `Invoke-PanXApi` support for `-Config -Complete` action, a relatively obscure "config action" with little documentation but useful for *simulating* the `?` keyboard press when interactive on the CLI. If curious, see `Update-PanDeviceLocation` how it is used to get the list of device-groups or vsys's without having to download and parse many MiB of configuration.

### Changed
- `[PanDevice]` `Location` is an ordered dictionary (key:value) of device-specific vsys:xpath (NGFW) or device-group:xpath (Panorama) -- including "shared". Not persisted to disk and updated dynamically when the device is used.
  - Used heavily by PowerPAN cmdlets, but also very useful when using `Invoke-PanXApi` for building the `-XPath`. Separately, the data model changes above makes building the `Invoke-PanXApi` `-Element` much easier too.
- Renamed `Update-PanDeviceVsys` to `Update-PanDeviceLocation`. Now supports Panorama device-group (new), NGFW vsys, and shared (new).

## 0.4.0 2025-03-30

### Added

- `Invoke-PanCommit` public cmdlet for committing, validating, and determining if pending changes exist.
- `Invoke-PanHaState` public cmdlet for displaying and changing high-availability *runtime* state and status. A new `[PanHaState]` type also exists.
- `Invoke-PanSoftware` public cmdlet for displaying, checking, downloading, installing, and deleting PAN-OS operating system software updates. A new `[PanSoftware]` type also exists.
- `Get-PanJob` public cmdlet for monitoring the status of jobs (called "tasks" in the GUI). A new `[PanJob]` type also exists.
- Note: `[PanSoftware]` type and `[PanJob]` type both make use of `[DateTimeOffset]` typed property (instead of `[DateTime]`) and `[TimeZoneInfo]` typed property, internally. *Needed to effectively compare dates and times when the computer running the `PowerPAN` module/script is in a different time zone than the devices, or when comparing dates and times across devices in different time zones.
  - PAN-OS XML-API returns job and software related data in the device's local time *without* any time zone or offset qualifiers. Frustrating indeed.
  - The device's time zone can be learned from the configuration (and is as part of `Get-PanJob` and `Get-PanSoftware`).
  - This module determines the device time zone, calculates the correct offset based on Daylight Savings Time and exposes for use as `[DateTimeOffset]` and `[TimeZoneInfo]` typed properties.
  - For more detail, read `help Get-PanJob` or for technical implementation detail, read the comments within `Get-PanJob.ps1`
- Inclusion of [`TimeZoneConverter`](https://www.nuget.org/packages/TimeZoneConverter/) .NET assembly for Windows PowerShell 5.1 time zone mapping of IANA formatted time zone names. See sources for `NewPanJob.ps1` (note no hyphen) and `ConvertFromPanTimeZone.ps1` for nerdy bits.
- Added features in this release were built to make "large scale HA upgrades" feasible -- upgrading hundreds (or more) HA pairs at a time. Previously, needed to make heavy use of `Invoke-PanXApi`. Now the friendlier abstraction cmdlets do a lot more work.
- Additional `-KeyCredential` parameter support in `New-PanDevice` for providing the API key in a more secure way as the password portion of a `[PSCredential]`. Back-end storage in-memory and on-disk remains `[SecureString]`, no changes there.

### Changed

- (BREAKING CHANGE) Within `Invoke-PanXApi -Commit`, the `-Force` parameter was removed. If desiring a "force commit", add `<commit><force></force></commit>` as the commit `$Cmd` or better yet, use the `Invoke-PanCommit` cmdlet instead.
  - The `Invoke-PanXApi -Commit` mode now represents a cleaner mapping to the native PAN-OS XML-API. "Force commit" capabilities are part of the XML-API `cmd` and better represented as a `$Cmd`.
  - `Invoke-PanCommit` provides a friendlier abstraction of "force commit" while keeping the lower-level `Invoke-PanXApi` better aligned to the raw XML-API.
- Re-arranged module's directory and file layout of `.ps1` files. Intent is to align functions with "Policy-Object-Network-Device" GUI tabs. Not perfect, but provides structure. No external effect.
- Changed module's private cmdlets to use *non*-hyphenated names based on PowerShell best practice to distinguish public from private. Since these were private/internal use cmdlets to begin with, there is no external effect.
  - Example: Private cmdlet/function `New-PanResponse` became `NewPanResponse`. And many more.
- Cmdlet commenting and documentation updates.

## 0.3.4 2025-02-21

### Added

- README updates and examples including File/Certificate uploads and `PanDeviceDb` metadata labels.

### Changed

- Updated `NewMultipartFormData` to address an issue when using PowerShell 7.4.
  - In PowerShell 7.4 the web cmdlets default charset was changed to utf-8.
  - `NewMultipartFormData` is a custom MIME encoder for PAN-OS XML-API (see the cmdlet code itself for details).
  - Required including the non- "utf-8" charset in the `ContentType` parameter which makes its way to the HTTP `Content-Type:` header to resolve XML-API upload failures.
  - <https://github.com/PowerShell/PowerShell/pull/18219>

## 0.3.3 2024-09-19

### Changed

 - Problematic PowerShell Gallery push (development moved to MacOS, teething problems). Removed many unnecessary files inadvertently included in 0.3.2.

## 0.3.2 2024-09-19

### Changed

 - ExportPanDeviceDb and ImportPanDeviceDb changed to enable MacOS (tested) and Linux (not tested) support for saving `devices.json` using `HOME` environment variable. Persistent devices across PowerShell sessions now supported on MacOS (and likely Linux).

## 0.3.1 2023-05-04

### Changed

- In-line help fixes
- `README.md` updates and examples

## 0.3.0 2023-05-04

### Added

- PowerShell module auto-load / auto-import support. No longer need to explicitly `Import-Module` before use (must still be installed `Install-Module`).
- Examples to `README.md`

## 0.2.0 2023-04-05

### Added

- `README.md` with basic description (more to come)

### Changed

- `Invoke-PanXApi` change to enable broad support for PowerShell 6+
  - Officially supporting *Windows PowerShell 5.1* and *PowerShell 7.2 LTS*
- Module version change from `0.1` to `0.2.0` in advance of publishing to PowerShell Gallery

## [Alpha] 2023-04-05

### Changed

- Major updates in preparation for publishing to PowerShell Gallery
- PSScriptAnalyzer cleanup
  - `SupportsShouldProcess` additions to many cmdlets
  - Significant formatting and whitespace cleanup

## [Alpha] 2023-04-04

### Added

- New `NewMultipartFormData ` private helpers for building `multipart/form-data` POSTs.

  - PAN-OS XML-API has trouble with quoted `boundary` declaration on the OUTER `Content-Type` header
  - Issue captures the challenge nicely <https://github.com/PowerShell/PowerShell/issues/9241>
  - In PowerShell 7+, Invoke-WebRequest -Form, Invoke-RestMethod -Form DO quote the boundary. Not an option.
  - .NET System.Net.Http.MultipartFormDataContent also DOES quote the boundary. Not an option.
  - Needed something else
- New *capability* in `Invoke-PanXApi` to support `import` mode (uploading files).
  - Tested primarily to upload certificates (as part of a larger project to deploy Let's Encrypt for GlobalProtect portals and gateways)

### Changed

- Updated `Invoke-PanXApi` $PSBoundParameter clarity and in-line help examples

## [Alpha] 2020-10-08

### Added

- New `Get-PanAddress` and `Set-PanAddress` public cmdlets for retrieving and setting PAN-OS address objects, respectively.
- New `[PanAddress]` class to represent PAN-OS address objects.
- New `[PanAddressType]` *enum* type to represent the PAN-OS address object types.
  - `[PanAddressType]::IpNetmask`
  - `[PanAddressType]::IpRange`
  - `[PanAddressType]::IpWildcardMask`
  - `[PanAddressType]::Fqdn`

### Changed

- On `*-PanRegisteredIp` cmdlets the `-Device` parameter is no longer positional, only named. Since the `-Device` parameter is *often* fulfilled through pipeline input (via `Get-PanDevice "192.168.250.250" | Get-PanRegisteredIp ...`), other parameters are now available for the `0` (and `1`) position(s) making the cmdlets more friendly for quick CLI use.
- File and folder hierarchy restructuring (again)
- PowerShell inline help updates

## [Alpha] 2020-08-27

### Added

- New `Resolve-PanTagColor` cmdlet to resolve PAN-OS tag color friendly and raw values. The former is used in the GUI to present friendly names while the latter is used via API, CLI, and found in XML configuration.

### Changed

- PowerShell module (.psm1) logic to support dot-sourcing *classes* in specific order if needed to resolve dependencies. Using the pre-existing module logic, classes were dot-sourced based on their alphanumeric filename sort order. Now, specific classes can be dot-sourced in specific order as needed.
  - For example, if `[PanAddress]` (in `PanAddress.ps1`) depends on `[PanDevice]` (in `PanDevice.ps1`), alphanumerically `PanAddress.ps1` will dot-source first and fail given it references an unknown (at the time) `[PanDevice]` type.
  - To resolve, add `PanDevice.ps1` to be dot-sourced first in module `.psm1`.

## [Alpha] 2020-06-17

### Added

- New `[PanUrlResponse]` class, `PanUrlResponse.Format.ps1xml` format spec, and `Resolve-PanUrlCategory` cmdlet to facilitate resolving URL's to PanDB categories.
  - Uses PANOS XML API instead of <https://urlfiltering.paloaltonetworks.com> (which has annoying CAPTCHA) to map URL to PanDB category.
  - Supports PAN-OS 9.0 multi-category

### Changed

- Numerous PowerShell inline help documentation updates.

## [Alpha] 2020-06-12

### Added

- New `[PanResponse]` class and `NewPanResponse` private cmdlet to standardize on *internal* PAN XML-API response handling
  - `Invoke-PanXApi` now returns `[PanResponse]`, which now includes HTTP response details, along with the results
  - Refactored all relevant cmdlets in light of `[PanResponse]` object property name and structure changes
- New `PanResponse.Format.ps1xml` and `PanDevice.Format.ps1xml` format files to simplify `[PanResponse]` and `[PanDevice]` default object property display
  - <https://blog.mwpreston.net/2020/01/06/working-with-custom-typenames-in-powershell/>
  - <http://ramblingcookiemonster.github.io/Decorating-Objects/>

### Changed

- Changes to near all cmdlets in response to new `[PanResponse]` class. See **Added** section for details.
- Misc. inline documentation updates.

## [Alpha] 2020-06-03

### Added

- New cmdlets `Get-PanLicenseApiKey`, `Set-PanLicenseApiKey`, and `Clear-PanLicenseApiKey`
  - For get, set, and clear of license API key used to auto deactivate VM-Series firewalls within PAN Customer Support Portal
  - Built as part of reinvigorated need to automate the relicensing of a PAN lab environment

### Changed

- Completed `Restart-PanDevice` making it actually perform a restart of the device, not just mock restart.
  - Supports `SupportsShouldProcess` CmdletBinding enabling a confirmation prompt, support for `-WhatIf` and the ability to override the prompt with `-Force`.
- Inline help documentation updates

## [Alpha] 2019-10-17

### Changed

- Renamed `DeviceTag` to `Label`
  - All parameters and references to `DeviceTag` changed to `Label`
  - Avoids word confusion with registered-IP tags and future Panorama managed device tags

## [Alpha] 2019-05-27

### Added

- PanDeviceDb and DeviceTag Implemented
- New cmdlet `New-PanDevice`
  - `New-PanDevice -Name "MyDevice.lab.local" -DeviceTag "Fido","Azure","VM50"`
  - Unserialize JSON and store at `$Global:PanDeviceDb` global variable.
  - `[Guid]` generated and saved to `$Global:PanSessionGuid` global variable. *Only done once per PowerShell session.*
  - `session-[Guid], Fido, Azure, VM50` tags assigned to `[PanDevice].DeviceTag`
    - Consider `Fido` a friendly name, if required.
  - New `[PanDevice]` stored to `$Global:PanDeviceDb`. If already exists (based on `Name`), replace.
  - `$Global:PanDeviceDb` serialized to JSON and saved to disk, stripping `session-[Guid]` tag.

- New cmdlet `Get-PanDevice`
  - `Get-PanDevice` *(No Parameters)*
    - *If* `$Global:PanDefaultDeviceTag` is set (`$Global:PanSessionGuid` is *ignored*)
      - Return `[PanDevice]` from `$Global:PanDeviceDb` where `[PanDevice].DeviceTag` match `$Global:PanDefaultDeviceTag`
    - *Else*
      - Return `PanDevice` from `$Global:PanDeviceDb` where `[PanDevice].DeviceTag` match `$Global:PanSessionGuid`

  - `Get-PanDevice -Name "MyDevice"`
    - Return `[PanDevice]` from `$Global:PanDeviceDb` where `[PanDevice].Name` match `-Name`
    - `-Name` can be `[String[]]`

  - `Get-PanDevice -DeviceTag "MyTag","YourTag"`
    - Return `[PanDevice]` from `$Global:PanDeviceDb` where `[PanDevice].DeviceTag` match `-DeviceTag`
    - `-DeviceTag` can be `[String[]]`
      - Multiple `-DeviceTag` (via String array) is an **OR** match, _not_ an **AND** match. If different logic is required, `| Where-Object { $_.DeviceTag ... }`

- New cmdlet `Get-PanDefaultDeviceTag`
  - *If* `$Global:PanDefaultDeviceTag` is not set, return `session-$($Global:PanSessionGuid)`
  - *Else* return `$Global:PanDefaultDeviceTag`

- New cmdlet `Set-PanDefaultDeviceTag -DeviceTag "MyTag","YourTag"`
  - Set (replace) `$Global:PanDefaultDeviceTag` to `@("MyTag","YourTag")`
  - No `Add-PanDefaultDeviceTag` or `Remove-PanDefaultDeviceTag` append and remove cmdlets implemented. Scripts can manage effectively via `Get-`, `Set`-, and `Clear-`

- New cmdlet `Clear-PanDefaultDeviceTag`
  - Unset `$Global:PanDefaultDeviceTag`, restoring `session-$($Global:PanSessionGuid)` as the default device tag.

- New cmdlet `Import-PanDevice` is *initially* called on *first* call to `Get-PanDevice` and first call to `Add-PanDevice`.
  - Track initial import with `$Global:PanInitImportComplete`
  - Needed to do it early, but *not* too early on PowerPAN module load.
  - Did not want to take chance of Importing and replacing session-created entry

### Changed

- Existing `Write-Verbose` to `Write-Debug` as most were debug style messages anyway.
- `Invoke-PanXApi` to use HTTP Post action (from HTTP Get).
  - PAN XML-API doesn't distinguish between Get and Post
  - Post accommodates larger message sizes
  - Keeps Passwords and API keys out of the Verbose logs
- Reviewed and modified often-resized array logic to use `[System.Collections.Generic.List]` instead of PowerShell native arrays for performance improvement.

## [Alpha] 2019-04-07

### Added

- Add `-Credential` parameter to `New-PanDevice`
  - Need a secure option for adding credentials using New-PanDevice
  - Example with New-PanDevice -Name "MyDevice" -Credential $(New-Credential) -Keygen
  - `[PanDevice]` class constructor has already been built to deal with this case on import via ImportPanDeviceDb
