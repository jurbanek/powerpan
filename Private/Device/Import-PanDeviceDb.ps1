function Import-PanDeviceDb {
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
      Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "$StoredJsonPath file does not exist. Nothing to get")
   }
   else {
      Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "$StoredJsonPath file found. Getting contents")

      $StoredDevicesCustomObjs = Get-Content -Path $StoredJsonPath | ConvertFrom-Json

      if($StoredDevicesCustomObjs.Count -eq 0) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "No valid contents found")
      }
      else {
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "$($StoredDevicesCustomObjs.Count) devices found. Creating")

         # $NewDevices to hold unserialized [PanDevices] through iteration
         # .NET Generic List provides under-the-hood efficiency during add/remove compared to PowerShell native arrays or ArrayList.
         $NewDevices = [System.Collections.Generic.List[PanDevice]]@()

         foreach($Cur in $StoredDevicesCustomObjs) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Device Name: $($Cur.Name)")

            # If no stored label, avoid sending $null to the constructor. Causes trouble down the road when calling Label.Add(), Label.Contains() and other methods.
            if([String]::IsNullOrEmpty($Cur.Label)) {
               $Cur.Label = [System.Collections.Generic.List[String]]@()
            }

            # Username, Password, and Key are defined, build a new [PanDevice] with all three
            if( -not [String]::IsNullOrEmpty($Cur.Username) -and -not [String]::IsNullOrEmpty($Cur.Password) -and -not [String]::IsNullOrEmpty($Cur.Key) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Building [PanDevice] $($Cur.Name) with Username, Password, and Key")
               # Create [PSCredential] from Username and encrypted string Password
               $Credential = New-Object -TypeName PSCredential -ArgumentList $Cur.Username,$(ConvertTo-SecureString -String $Cur.Password)
               # Create [SecureString] from from encrypted string Key
               $Key = ConvertTo-SecureString -String $Cur.Key
               # Create new [PanDevice] using some original retrieved values and just created [PSCredential] and [SecureString]
               $NewDevices.Add( [PanDevice]::New($Cur.Name, $Credential, $Key, $Cur.Label, $Cur.ValidateCertificate, $Cur.Protocol, $Cur.Port) )
            }

            # Only Username and Password defined, build new [PanDevice] with just Username and Password
            elseif( -not [String]::IsNullOrEmpty($Cur.Username) -and -not [String]::IsNullOrEmpty($Cur.Password) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Building [PanDevice] $($Cur.Name) with Username and Password")
               # Create [PSCredential] from Username and encrypted string Password
               $Credential = New-Object -TypeName PSCredential -ArgumentList $Cur.Username,$(ConvertTo-SecureString -String $Cur.Password)
               # Create new [PanDevice] using some original retrieved values and just created [PSCredential]
               $NewDevices.Add( [PanDevice]::New($Cur.Name, $Credential, $Cur.Label, $Cur.ValidateCertificate, $Cur.Protocol, $Cur.Port) )
            }

            # Only Key defined, build new [PanDevice] with just Key
            elseif( -not [String]::IsNullOrEmpty($Cur.Key) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Building [PanDevice] $($Cur.Name) with Key")
               # Create [SecureString] from from encrypted string Key
               $Key = ConvertTo-SecureString -String $Cur.Key
               # Create new [PanDevice] using some original retrieved values and just created [SecureString]
               $NewDevices.Add( [PanDevice]::New($Cur.Name, $Key, $Cur.Label, $Cur.ValidateCertificate, $Cur.Protocol, $Cur.Port) )
            }

         } # foreach

         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Imported $($NewDevices.Count) device$(if($NewDevices.Count -ne 1){'s'}). Adding to PanDeviceDb")
         Add-PanDevice -Device $NewDevices -ImportMode
      } # NewDevices else
   }
} # Function
