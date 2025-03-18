function New-PanSoftware {
    <#
    .SYNOPSIS
    Returns a PanSoftware object.
    .DESCRIPTION
    Returns a PanSoftware object.
    .NOTES
    .INPUTS
    None
    .OUTPUTS
    PanSoftware
    .EXAMPLE
    #>
    [CmdletBinding()]
    param(
       [parameter(
          Mandatory=$true,
          HelpMessage='PanResponse')]
       [PanResponse] $Response,
       [parameter(
          Mandatory=$true,
          HelpMessage='PanDevice')]
       [PanDevice] $Device
    )
 
    # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
    if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
    if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
    # Announce
    Write-Debug ($MyInvocation.MyCommand.Name + ':')
 
    $SoftwareAgg = [System.Collections.Generic.List[PanSoftware]]@()

    foreach($EntryCur in $PSBoundParameters.Response.Result.'sw-updates'.versions.entry) {
        $SoftwareNew = [PanSoftware]::new()
        
        $SoftwareNew.Version = $EntryCur.version
        $SoftwareNew.Filename = $EntryCur.filename
        $SoftwareNew.Size = $EntryCur.size
  
        # ReleasedDt
        # PAN-OS XML-API released-on return format example below, does not include timezone indicator
        # 2025/02/20 21:05:20
        # In firewall local time (not UTC unless firewall TZ is UTC)
        $Regex = '(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)'
        if($EntryCur.'released-on' -match $Regex) {
            $SoftwareNew.ReleasedDt = [DateTime]::new($Matches[1],$Matches[2],$Matches[3],$Matches[4],$Matches[5],$Matches[6],0,0)
        }   
        
        $SoftwareNew.ReleaseNotes = $EntryCur.'release-notes'.'#cdata-section'
        $SoftwareNew.Downloaded = if($EntryCur.downloaded -eq 'yes') {$True} else {$False}
        $SoftwareNew.Uploaded = if($EntryCur.uploaded -eq 'yes') {$True} else {$False}
        $SoftwareNew.Current = if($EntryCur.current -eq 'yes') {$True} else {$False}
        $SoftwareNew.Latest = if($EntryCur.latest -eq 'yes') {$True} else {$False}
        $SoftwareNew.ReleaseType = $EntryCur.'release-type'
        $SoftwareNew.Sha256 = $EntryCur.sha256
        
        $SoftwareNew.Device = $PSBoundParameters.Device

        # Add to aggregate
        $SoftwareAgg.Add($SoftwareNew)
    }

    return $SoftwareAgg | Sort-Object -Property 'Version'
} # Function
 