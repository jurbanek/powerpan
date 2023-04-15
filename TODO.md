# PowerPAN Todo

## Auto-Load PowerShell Module

- Enable auto-loading of module to avoid having to `Import-Module`, even after install.
- Look at `.psd1` `FunctionsToExport = @()`, likely have to generate/replace as part of `Publish.ps1`

## Let's Encrypt Certificates for GlobalProtect Portal(s) and Gateway(s)

- Requires certificate upload support in `Invoke-PanXApi` (Completed)

## Address Objects

- `Set-PanAddress` and `Get-PanAddress` completed
- Build `Rename-PanAddress`, `Remove-PanAddress`, and `Move-PanAddress`
- Build Panorama support
  - Abstract Panorama as `[PanDevice]`
  - Abstract Panorama *Device Group* within a `[PanAddress]` object `Location` property

## WildFire API Client

- Submit files to WildFire
- Submit URL's to WildFire
- Submit hashes to WildFire for verdict

## *Consider* refactor `-Device` Selection

- Holding off as current `Get-PanDevice | Do-Something` works very well
- Consider refactor *existing* cmdlets to accept:
  - `-Name "MyDevice"` parameter to resolve `[PanDevice]` based on name/IP (should be `[String[]]`)
  - `-Label "MyLabel"` parameter to resolve `[PanDevice]` based on `PanDevice.Label` property (should be `[String[]]`)
  - `-Device $Device` parameter to accept native `[PanDevice[]]` (already done)
  - *No* `-Name`, `-Label`, or `-Device` parameter implies `$Global:PanDeviceLabelDefault` or `-Label "session-[Guid]"`, in order
  - `-Name`, `-Label`, and *none* dispatch to `Get-PanDevice`, no extensive local cmdlet logic

## Use Cases

### Highest traffic flows over an interval

- Interval is a parameter.
- Parse PAN-OS session table frequently over the course of the interval.
- When PAN-OS sessions are stored in PowerShell memory, they must be hashed and a hash value stored as well.
  - The PAN-OS session ID is re-used. Given a long enough interval, session 12486 will belong to disparate TCP virtual circuits.
- Consider parameters to aggregate based on app-id, source user, source IP, destination IP, source port, destination port

### Output a list of objects with "n" or fewer references

- Objects to include addresses, address groups, security profiles, etc.
- To be useful would need to support Panorama.
- Any way to graph and visualize relationships?

### Remove all objects with 0 references

### Realtime Interface Throughput Monitor

- a la Pan(w)chrome
- Limit to curses like update with real-time interface monitor.

### Add log forwarding profile to every security rule without an existing log forwarding profile

### `Get-PanLog`

- Application discovery for Foot Locker. Get-PanLog and specify DateTime or range, specify source/destination (check API limits), then perform additional filtering in PowerShell `| Sort-Object - Property appid -Unique`

### `Invoke-PanEdlRefresh`

- Refresh is not an approved verb
- Command to force an EDL refresh, useful when making changes to MineMeld and not waiting for built-in refresh

### Expedition Panorama Post-Import Object Revert and Move

- Objects (address, service, etc.) imported into child device group are net-new or overrides of parent device group objects.
- Overrides need to be reverted.
- Net-new need to be moved to parent device group.

### PAN-Configurator

- Consider porting PAN-Configurator to PowerShell and exposing non-XML related advanced functions for layman admins. Review PAN-Configurator for inspiration.
