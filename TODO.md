# PowerPAN Todo

## Add `Add-PanDeviceLabel` and `Remove-PanDeviceLabel`

- Accepts `-Device` and `-Label`
- For adding and removal labels without having to recreate PanDevice's
- Finished updating `[PanDevice].Label` class property to be of type `[System.Collections.Generic.List[String]]`
- When building `Add-` and `Remove-` cmdlets, use the .Add() and .Remove() methods native to `[System.Collections.Generic.List]`

## *Consider* refactor `-Device` Selection

- Holding off as current `Get-PanDevice | Do-Something` works very well
- Consider refactor *existing* cmdlets to accept:
  - `-Name "MyDevice"` parameter to resolve `[PanDevice]` based on name/IP (should be `[String[]]`)
  - `-Label "MyLabel"` parameter to resolve `[PanDevice]` based on `PanDevice.Label` property (should be `[String[]]`)
  - `-Device $Device` parameter to accept native `[PanDevice[]]` (already done)
  - *No* `-Name`, `-Label`, or `-Device` parameter implies `$Global:PanDefaultLabel` or `-Label "session-[Guid]"`, in order
  - `-Name`, `-Label`, and *none* dispatch to `Get-PanDevice`, no extensive local cmdlet logic

## Build PowerPan.Format.ps1xml for `Test-PanDevice`

- Create a type <http://ramblingcookiemonster.github.io/Decorating-Objects/>
- Use api `type=version` instead of executing a `show system info`

## Build `Restart-PanDevice`

- Cannot reboot firewalls through Panorama currently, only as part of firewall upgrade.
- Confirm PAN-OS *Restart* or *Reboot* verb. Verify PowerShell approved verb?
- Require a confirmation by default. Add  `-NoConfirm` parameter.

## Use Cases

### Highest traffic flows over an interval

- Interval is a parameter.
- Parse PAN-OS session table frequently over the course of the interval.
- When PAN-OS sessions are stored in PowerShell memory, they must be hashed and a hash value stored as well.
  - The PAN-OS session ID is re-used. Given a long enough interval, session 12486 will belong to disparate TCP virtual circuits.
- Consider parameters to aggregate based on app-id, source user, source ip, dest ip, source port, dest port

### Output a list of objects with "n" or fewer references

- Objects to include addresses, address groups, security profiles, etc.
- To be useful would need to support Panorama.
- Any way to graph and visualize relationships?

### Remove all objects with 0 references

### Realtime Interface Throughput Monitor

- a la Pan(w)chrome
- Limit to curses like update with realtime interface monitor.

### Add log forwarding profile to every security rule without an existing log forwarding profile

### `Get-PanLog`

- Application discovery for Foot Locker. Get-PanLog and specify DateTime or range, specify source/dest (check API limits), then perform additional filtering in PowerShell | Sort-Object - Property appid -Unique

### `Get-PanUrlCategory`

- Foot Locker use case to use PANOS XML API instead of <https://urlfiltering.paloaltonetworks.com> (which has annoying CAPTCHA) to map URL to PAN-DB category.
- Consider CSV input (script method only)
- Consider CSV output (script method only)

### `Invoke-PanEdlRefresh`

- Refresh is not an approved verb
- Command to force an EDL refresh, useful when making changes to MineMeld and not waiting for built-in refresh

### WildFire API Client

- Submit files to WildFire
- Submit URL's to WildFire
- Submit hashes to WildFire for verdict

### Expedition Panorama Post-Import Object Revert and Move

- Objects (address, service, etc.) imported into child device group are net-new or overrides of parent device group objects.
- Overrides need to be reverted.
- Net-new need to be moved to parent device group.

### PAN-Configurator

- Consider porting PAN-Configurator to PowerShell and exposing non-XML related advanced functions for layman admins. Review PAN-Configurator for inspiration.
