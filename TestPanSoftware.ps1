Import-Module "/Users/jpfu/Library/Mobile Documents/com~apple~CloudDocs/Repos/powerpan/PowerPAN.psd1"
$VerbosePreference = 'Continue'
$InformationPreference = 'Continue'
$DebugPreference = 'Continue'
<#

TODO:

DONE Get-PanJob
DONE Invoke-PanSoftware
DONE Update Invoke-PanSoftware -Info (add a new parameter) to return [PanSoftware]
DONE Update Invoke-PanSoftware -Check to return [PanSoftware]
DONE Define new [PanSoftware] Class
DONE Define new [PanHaState] Class
DONE Invoke-PanHaState (needed for below workflow)
    - Info, Suspend, Functional
DONE Update PanJob to use DateTimeOffset and TimeZoneInfo


#>

<#
$D = Get-PanDevice "192.168.250.250"


#$Cmd = '<request><system><software><check></check></software></system></request>'
$Cmd = '<show><jobs><all></all></jobs></show>'
$CmdDownload = '<request><system><software><download><version>11.2.5</version></download></software></system></request>'
$R = Invoke-PanXApi -Device $D -Op -Cmd $Cmd
#>

$D = Get-PanDevice "192.168.250.250"
#Get-PanJob -Device $D -All
#Invoke-PanSoftware -Device $D -Install -Version "11.2.4-h5" -Verbose -Debug

# Invoke-PanSoftware -Device $D -Info
#Invoke-PanHaState -Device $D -Info

$Response = Invoke-PanXApi -Device $D -Config -Get -XPath "/config/devices/entry[@name='localhost.localdomain']/deviceconfig/system/timezone"
$PanTz = $Response.result.timezone

# PanSoftware
# Change the PanSoftware class DateTime property to DateTimeOffset (like PanJob)
# Add a TimeZoneInfo property to PanSoftware class (like PanJob)
# Update Invoke-PanSoftware to include the -TimeZoneName property in the call to New-PanSoftware







