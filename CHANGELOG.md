# PowerPAN Changelog

All notable changes to this project will be documented in this file.

## [Pre-Alpha] 2020-06-17

### Added

- New `[PanUrlResponse]` class, `PanUrlResponse.Format.ps1xml` format spec, and `Resolve-PanUrlCategory` cmdlet to facilitate resolving URL's to PanDB categories.
  - Uses PANOS XML API instead of <https://urlfiltering.paloaltonetworks.com> (which has annoying CAPTCHA) to map URL to PanDB category.
  - Supports PAN-OS 9.0 multi-category

### Changed

- Numerous PowerShell inline help documentation updates.

## [Pre-Alpha] 2020-06-12

### Added

- New `[PanResponse]` class and `New-PanResponse` private cmdlet to standardize on *internal* PAN XML-API response handling
  - `Invoke-PanXApi` now returns `[PanResponse]`, which now includes HTTP response details, along with the results
  - Refactored all relevant cmdlets in light of `[PanResponse]` object property name and structure changes
- New `PanResponse.Format.ps1xml` and `PanDevice.Format.ps1xml` format files to simplify `[PanResponse]` and `[PanDevice]` default object property display
  - <https://blog.mwpreston.net/2020/01/06/working-with-custom-typenames-in-powershell/>
  - <http://ramblingcookiemonster.github.io/Decorating-Objects/>

### Changed

- Changes to near all cmdlets in response to new `[PanResponse]` class. See **Added** section for details.
- Misc. inline documentation updates.

## [Pre-Alpha] 2020-06-03

### Added

- New cmdlets `Get-PanLicenseApiKey`, `Set-PanLicenseApiKey`, and `Clear-PanLicenseApiKey`
  - For get, set, and clear of license API key used to auto deactivate VM-Series firewalls within PAN Customer Support Portal
  - Built as part of reinvigorated need to automate the relicensing of a PAN lab environment

### Changed

- Completed `Restart-PanDevice` making it actually perform a restart of the device, not just mock restart.
  - Supports `SupportsShouldProcess` CmdletBinding enabling a confirmation prompt, support for `-WhatIf` and the ability to override the prompt with `-Force`.
- Inline help documentation updates

## [Pre-Alpha] 2019-10-17

### Changed

- Renamed `DeviceTag` to `Label`
  - All parameters and references to `DeviceTag` changed to `Label`
  - Avoids word confusion with registered-IP tags and future Panorama managed device tags

## [Pre-Alpha] 2019-05-27

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

## [Pre-Alpha] 2019-04-07

### Added

- Add `-Credential` parameter to `New-PanDevice`
  - Need a secure option for adding credentials using New-PanDevice
  - Example with New-PanDevice -Name "MyDevice" -Credential $(New-Credential) -Keygen
  - `[PanDevice]` class constructor has already been built to deal with this case on import via Import-PanDeviceDb
