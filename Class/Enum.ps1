# Defining enum using PowerShell enum keyword prevents the type from being used on CLI in PowerShell 5.1
# Using Add-Type to build enum type in C# allows type to be used on CLI, requires testing on PowerShell > 5.1
# For example (works with Add-Type but not native PowerShell enum keyword)
# PS> Get-PanDevice "192.168.250.250" | Get-PanAddress | Where-Object {$_.Type -eq [PanAddressType]::Fqdn}

Add-Type @'
public enum PanAddressType {
   IpNetmask = 1,
   IpRange = 2,
   IpWildcardMask = 3,
   Fqdn = 4
}
'@

Add-Type @'
public enum PanDeviceType {
   Ngfw = 1,
   Panorama = 2
}
'@

<#
enum PanAddressType {
   IpNetmask = 0
   IpRange = 1
   IpWildcardMask = 2
   Fqdn = 3
}
#>
