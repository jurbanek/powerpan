class PanSoftware {
    # PAN-OS Version
    [String] $Version
    # PAN-OS Version Filename
    [String] $Filename
    # Size (MiB)
    [Int] $Size
    # Release Date
    [DateTimeOffset] $Released
    # TimeZoneInfo to further qualify the DateTimeOffset if needed
    [TimeZoneInfo] $TimeZoneInfo
    # Released Notes
    [String] $ReleaseNotes
    # Downloaded and able to be installed
    [Bool] $Downloaded
    # Uploaded (by user) and able to be installed
    [Bool] $Uploaded
    # Currently installed
    [Bool] $Current
    # Latest version of PAN-OS
    [Bool] $Latest
    # Release Type. "Base" for base releases
    [String] $ReleaseType
    # SHA256 Hash
    [String] $Sha256 

    # Parent PanDevice address references
    [PanDevice] $Device
    
    # Default Constructor
    PanSoftware() {
    }
 
 } # End class
 