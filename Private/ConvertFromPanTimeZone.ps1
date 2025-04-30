function ConvertFromPanTimeZone {
<#
.SYNOPSIS
Returns a TimeZoneInfo object from a PAN time zone string. Internal helper cmdlet.
.DESCRIPTION
Returns a TimeZoneInfo object from a PAN time zone string. Internal helper cmdlet.
.NOTES
PowerShell 6+ and the corresponding .NET 6+ have robust cross-platform time zone support within the TimeZoneInfo
class supporting both the Windows time zone style "AUS Eastern Standard Time" and IANA style 'Australia/Sydney'.
https://devblogs.microsoft.com/dotnet/date-time-and-time-zone-enhancements-in-net-6/#time-zone-conversion-apis

Windows PowerShell 5.1 and corresponding .NET 4.5/4.6 TimeZoneInfo class IN CONSTRAST only support Windows style
"AUS Eastern Standard Time" time zones.

PAN-OS configuration stores an IANA style, posing a problem for Windows PowerShell 5.1.

This helper cmdlet accepts a time zone string and returns a TimeZoneInfo object.

When used on PowerShell 6+, the native [TimeZoneInfo]::FindSystemTimeZoneById() will be used

When used on PowerShell 5.1, an additional external assembly (TimeZoneConverter.dll) will be loaded at runtime
and used. TimeZoneConverter will map IANA style time zone names to the only supported Windows time zone names
when running on Windows PowerShell 5.1. The TimeZoneConverter NuGet package (and assembly) is how many
developers worked around the limitation prior to .NET 6+.

https://www.nuget.org/packages/TimeZoneConverter/
https://github.com/mattjohnsonpint/TimeZoneConverter
.INPUTS
None
.OUTPUTS
TimeZoneInfo
.EXAMPLE
# Running on PowerShell 6+ returns a TimeZoneInfo object for 'America/Chicago'
ConvertFromPanTimeZone -Name 'America/Chicago'
.EXAMPLE
# Running on Windows PowerShell 5.1 returns a TimeZoneInfo object for 'Central Standard Time'
# (thanks to TimeZoneConverter)
ConvertFromPanTimeZone -Name 'America/Chicago'
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,Position=0,HelpMessage='PAN-OS time zone name')]
      [String] $Name
   )

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   # PowerShell 6+ (PowerPAN supports 7+ LTS releases)
   if($PSVersionTable.PSVersion.Major -ge 7) {
      Write-Verbose ($MyInvocation.MyCommand.Name + ': PowerShell 6+')
      # Use .NET native FindSystemTimeZoneById to return a TimeZoneInfo object
      return [TimeZoneInfo]::FindSystemTimeZoneById($PSBoundParameters.Name)
   }
   # PowerShell 5.1
   else {
      # If the assemply is already loaded, don't load it again
      Write-Verbose ($MyInvocation.MyCommand.Name + ': < PowerShell 6+ (likely 5.1)')
      if(([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.FullName -like 'TimeZoneConverter*'}).Count -gt 0) {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': TimeZoneConverter assembly already loaded')
      }
      # TimeZoneConvert assembly NOT loaded, load it
      else {
         Write-Verbose ($MyInvocation.MyCommand.Name + ': Loading TimeZoneConverter assembly')
         # Assembly included in the module, use ModuleBase to get there
         $AssemblyDllPath = (Get-Module -Name 'PowerPAN').ModuleBase + '/Assembly/timezoneconverter.7.0.0/net462/TimeZoneConverter.dll'
         Add-Type -Path $AssemblyDllPath
      }
      # Use [TimeZoneConvert.TZConvert]::GetTimeZoneInfo() capabilities to return a TimeZoneInfo object
      return [TimeZoneConverter.TZConvert]::GetTimeZoneInfo($Name)
   }
}
