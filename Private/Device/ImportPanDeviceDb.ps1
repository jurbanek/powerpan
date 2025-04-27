function ImportPanDeviceDb {
<#
.SYNOPSIS
PowerPAN private helper function to get JSON contents and unserialize into PanDevice objects.
.DESCRIPTION
PowerPAN private helper function to get JSON contents and unserialize into PanDevice objects.
.NOTES
.INPUTS
.OUTPUTS
.EXAMPLE
#>
   [CmdletBinding()]
   param(
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   # Detect PowerShell Core automatic variables for MacOS and Linux
   if($IsMacOS -or $IsLinux) {
      $StoredJsonPath = $Env:HOME + '/.powerpan/device.json'
   }
   # Otherwise Windows PowerShell and PowerShell Core on Windows will both have same environment variable name
   else {
      $StoredJsonPath = $Env:USERPROFILE + '/.powerpan/device.json'
   }

   if(-not (Test-Path -Path $StoredJsonPath -PathType Leaf)) {
      Write-Debug ('{0}: {1} file does not exist. Nothing to get' -f $MyInvocation.MyCommand.Name,$StoredJsonPath)
   }
   else {
      # Get the content and convert from JSON to a usable PowerShell object
      Write-Debug ('{0}: {1} file found. Getting contents' -f $MyInvocation.MyCommand.Name,$StoredJsonPath)
      
      # Need to account for rare corner-case where Locations have same name, but different CASE
      # Imagine the following JSON blob for Location
      # [
      #  { 
      #     "Location": {
      #        "shared": "/config/shared",
      #        "Parent": "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Parent']",     
      #        "parent": "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='parent']",
      #        "Child": "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='Child']",
      #        "child": "/config/devices/entry[@name='localhost.localdomain']/device-group/entry[@name='child']"
      #  }
      # ] 
      # "Parent" and "parent" are different device-groups, but ConvertFrom-Json considers them the SAME key by default
      # To avoid errors in PowerShell 7+, the ConvertFrom-Json -AsHashTable switch is needed
      # Unfortunately, Windows Powershell 5.1 does NOT have -AsHashTable switch, so we have to hack something together
      # 5.1 error: ConvertFrom-Json : Cannot convert the JSON string because a dictionary that was converted from the string contains the duplicated keys 'parent' and 'Parent' 
      # https://github.com/PowerShell/PowerShell/issues/5199
      if($PSVersionTable.PSVersion.Major -ge 7) {
         $StoredDevice = Get-Content -Path $StoredJsonPath | ConvertFrom-Json -AsHashtable
      }
      else {
         # System.Web.Script.Serialization.JavaScriptSerializer is available in 5.1 and will handle such keys
         # Not available in PowerShell 7+ which is fine. Only needs to work in 5.1
         $Serializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
         $StoredDevice = $Serializer.DeserializeObject((Get-Content -Path $StoredJsonPath))         
      }
      
      if($StoredDevice.Count -eq 0) {
         Write-Debug ('{0}: No valid contents found' -f $MyInvocation.MyCommand.Name)
      }
      else {
         Write-Debug ('{0}: {1} devices found. Creating PanDevice objects' -f $MyInvocation.MyCommand.Name,$StoredDevice.Count)

         # $DeviceAgg to hold unserialized [PanDevices] through iteration
         $DeviceAgg = @()

         foreach($StoredCur in $StoredDevice) {
            Write-Debug ('{0}: Device Name: {1}' -f $MyInvocation.MyCommand.Name,$StoredCur.Name)
            # Label
            # If no stored label, avoid sending $null to the constructor. Causes trouble down the road when calling Label.Add(), Label.Contains() and other methods.
            if([String]::IsNullOrEmpty($StoredCur.Label)) {
               $Label = [System.Collections.Generic.List[String]]::new()
            }
            else {
               $Label = $StoredCur.Label
            }
            # Set the PanDeviceType, if not stored (older versions), default to Ngfw
            $Type = if($StoredCur.Type) { $StoredCur.Type } else { [PanDeviceType]::Ngfw }
            # Location
            $Location = [System.Collections.Specialized.OrderedDictionary]::new()
            if($StoredCur.Location.Count) {
               foreach($KeyCur in $StoredCur.Location.Keys) {
                  $Location.Add($KeyCur, $StoredCur.Location.($KeyCur))
               }
            }
            # Username, Password, and Key are defined, build a new [PanDevice] with all three
            if( -not [String]::IsNullOrEmpty($StoredCur.Username) -and -not [String]::IsNullOrEmpty($StoredCur.Password) -and -not [String]::IsNullOrEmpty($StoredCur.Key) ) {
               Write-Debug ('{0}: Building {1} with Username, Password, Key' -f $MyInvocation.MyCommand.Name,$StoredCur.Name)
               # Create [PSCredential] from Username and encrypted string Password
               $Credential = New-Object -TypeName PSCredential -ArgumentList $StoredCur.Username,$(ConvertTo-SecureString -String $StoredCur.Password)
               # Create [SecureString] from from encrypted string Key
               $Key = ConvertTo-SecureString -String $StoredCur.Key
               # Create new [PanDevice] using some original retrieved values and just created [PSCredential] and [SecureString]
               $NewDevice = [PanDevice]::New($StoredCur.Name, $Credential, $Key, $Label, $StoredCur.ValidateCertificate, $StoredCur.Protocol, $StoredCur.Port, $Type)
               # Assign Location built from earlier Json content and add to DeviceAgg
               $NewDevice.Location = $Location
               # Since we are importing, naturally, Persist will be enabled
               $NewDevice.Persist = $true
            }

            # Only Username and Password defined, build new [PanDevice] with just Username and Password
            elseif( -not [String]::IsNullOrEmpty($StoredCur.Username) -and -not [String]::IsNullOrEmpty($StoredCur.Password) ) {
               Write-Debug ('{0}: Building {1} with Username, Password' -f $MyInvocation.MyCommand.Name,$StoredCur.Name)
               # Create [PSCredential] from Username and encrypted string Password
               $Credential = New-Object -TypeName PSCredential -ArgumentList $StoredCur.Username,$(ConvertTo-SecureString -String $StoredCur.Password)
               # Create new [PanDevice] using some original retrieved values and just created [PSCredential]
               $NewDevice = [PanDevice]::New($StoredCur.Name, $Credential, $Label, $StoredCur.ValidateCertificate, $StoredCur.Protocol, $StoredCur.Port, $Type)
               # Assign Location built from earlier Json content and add to DeviceAgg
               $NewDevice.Location = $Location
               # Since we are importing, naturally, Persist will be enabled
               $NewDevice.Persist = $true
            }

            # Only Key defined, build new [PanDevice] with just Key
            elseif( -not [String]::IsNullOrEmpty($StoredCur.Key) ) {
               Write-Debug ('{0}: Building {1} with Key' -f $MyInvocation.MyCommand.Name,$StoredCur.Name)
               # Create [SecureString] from from encrypted string Key
               $Key = ConvertTo-SecureString -String $StoredCur.Key
               # Create new [PanDevice] using some original retrieved values and just created [SecureString]
               $NewDevice = [PanDevice]::New($StoredCur.Name, $Key, $Label, $StoredCur.ValidateCertificate, $StoredCur.Protocol, $StoredCur.Port, $Type)
               # Assign Location built from earlier Json content and add to DeviceAgg
               $NewDevice.Location = $Location
               # Since we are importing, naturally, Persist will be enabled
               $NewDevice.Persist = $true
            }

            $DeviceAgg += $NewDevice
         } # foreach StoredCur

         Write-Debug ('{0}: Imported {1} device(s). Adding to PanDeviceDb' -f $MyInvocation.MyCommand.Name,$DeviceAgg.Count)
         Add-PanDevice -Device $DeviceAgg -ImportMode
      } # DeviceAgg else
   }
} # Function
