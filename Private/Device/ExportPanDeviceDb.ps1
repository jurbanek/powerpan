function ExportPanDeviceDb {
<#
.SYNOPSIS
PowerPAN private helper function to serialize and store PanDevice objects from PanDeviceDb to JSON.
.DESCRIPTION
PowerPAN private helper function to serialize and store PanDevice objects from PanDeviceDb to JSON.
.NOTES
.INPUTS
.OUTPUTS
.EXAMPLE
#>
   [CmdletBinding()]
   param(
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ('{0}:' -f $MyInvocation.MyCommand.Name)
      
      # Detect PowerShell Core automatic variables for MacOS and Linux
      if($IsMacOS -or $IsLinux) {
         $StoredDirectoryPath = $Env:HOME + '/.powerpan'
         $StoredJsonPath = $Env:HOME + '/.powerpan/device.json'
      }
      # Otherwise Windows PowerShell and PowerShell Core on Windows will both have same environment variable name
      else {
         $StoredDirectoryPath = $Env:USERPROFILE + '/.powerpan'
         $StoredJsonPath = $Env:USERPROFILE + '/.powerpan/device.json'
      }
      
      if(-not (Test-Path -Path $StoredDirectoryPath -PathType Container)) {
         Write-Debug ('{0}: {1} directory does not exist. Creating' -f $MyInvocation.MyCommand.Name,$StoredDirectoryPath)
         New-Item -Path $StoredDirectoryPath -ItemType Directory -Force | Out-Null
      }
      if(-not (Test-Path -Path $StoredJsonPath -PathType Leaf)) {
         Write-Debug ('{0}: {1} file does not exist. Creating' -f $MyInvocation.MyCommand.Name,$StoredJsonPath)
         Set-Content -Path $StoredJsonPath -Value $null -Force | Out-Null
      }

      # Aggregate devices through each iteration of Process block (and foreach within Process block itself)
      # .NET Generic List provides under-the-hood efficiency during add/remove compared to PowerShell native arrays or ArrayList.
      # List type is [PSObject] -- objects are changed from [PanDevice] to custom objects on the way out to export.
      $StoredDeviceAgg = [System.Collections.Generic.List[PSObject]]::new()
   } # Begin Block

   Process {
      foreach ($DeviceCur in ($Global:PanDeviceDb | Where-Object {$_.Persist -eq $true} )) {
         Write-Debug ('{0}: Name: {1}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
         # Build a custom hash table suitable for serializing to JSON in PowerShell End block
         # *Cannot* serialize the raw [PanDevice] object direclty. Needs some massaging to get
         # the Credential.Password [SecureString] and Key [SecureString] to their encrypted serializable/storable form.
         $CustomObj = @{
            'Name' =                $DeviceCur.Name
            'Username' =            $DeviceCur.Credential.UserName
            'ValidateCertificate' = $DeviceCur.ValidateCertificate
            'Protocol' =            $DeviceCur.Protocol
            'Port' =                $DeviceCur.Port
            'Type' =                $DeviceCur.Type
            'Location' =            $DeviceCur.Location
         } # End hash table

         # Add the Credential.Password
         if([String]::IsNullOrEmpty($DeviceCur.Credential.Password)) {
            $CustomObj.Add('Password', $null)
         }
         else {
            # Encrypted serialized/storable form
            $CustomObj.Add('Password', $($DeviceCur.Credential.Password | ConvertFrom-SecureString))
         }

         # Add the Key
         if([String]::IsNullOrEmpty($DeviceCur.Key)) {
            $CustomObj.Add('Key', $null)
         }
         else {
            # Encrypted serialized/storable form
            $CustomObj.Add('Key', $($DeviceCur.Key | ConvertFrom-SecureString))
         }

         # Add the Label
         if([String]::IsNullOrEmpty($DeviceCur.Label)) {
            $CustomObj.Add('Label', $null)
         }
         else {
            # Exclude "session-" labels
            $CustomObj.Add('Label', $($DeviceCur.Label | Where-Object {$_ -notmatch '^session-'} ) )
         }

         # Add the current $CustomObj to the array of $StoredDeviceAgg to be written to storage
         $StoredDeviceAgg.Add($CustomObj)
      }
   } # Process Block

   End {
      if(-not [String]::IsNullorEmpty($StoredDeviceAgg) ) {
         Write-Debug ('{0}: Storing {1} device(s) to {2}' -f $MyInvocation.MyCommand.Name,$StoredDeviceAgg.Count,$StoredJsonPath)
         # Serialize and write to storage
         ConvertTo-Json -InputObject $StoredDeviceAgg -Depth 10 | Set-Content -Path $StoredJsonPath -Force | Out-Null
      }
      elseif([String]::IsNullOrEmpty($StoredDeviceAgg) -and (($Global:PanDeviceDb | Where-Object {$_.Persist -eq $true} | Measure-Object).Count -eq 0)) {
         # Despite an empty StoredDeviceAgg, double-check $Global:PanDeviceDb before clearing out on-disk inventory
         Write-Debug ('{0}: Storing 0 devices. Wiping {1}' -f $MyInvocation.MyCommand.Name,$StoredJsonPath)
         # Serialize and clear out the file
         Set-Content -Path $StoredJsonPath -Value $null -Force | Out-Null
      }
   } # End Block
} # Function
