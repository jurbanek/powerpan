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
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
      
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
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "$StoredDirectoryPath directory does not exist. Creating.")
         New-Item -Path $StoredDirectoryPath -ItemType Directory -Force | Out-Null
      }
      if(-not (Test-Path -Path $StoredJsonPath -PathType Leaf)) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "$StoredJsonPath file does not exist. Creating.")
         Set-Content -Path $StoredJsonPath -Value $null -Force | Out-Null
      }

      # Aggregate devices through each iteration of Process block (and foreach within Process block itself)
      # .NET Generic List provides under-the-hood efficiency during add/remove compared to PowerShell native arrays or ArrayList.
      # List type is [PSObject] -- objects are changed from [PanDevice] to custom objects on the way out to export.
      $StoredDeviceAgg = [System.Collections.Generic.List[PSObject]]@()
   } # Begin Block

   Process {
      foreach ($DeviceCur in $Global:PanDeviceDb) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Device Name: $($DeviceCur.Name)")
         # Build a custom hash table suitable for serializing to JSON in PowerShell End block
         # *Cannot* serialize the raw [PanDevice] object direclty. Needs some massaging to get
         # the Credential.Password [SecureString] and Key [SecureString] to their encrypted serializable/storable form.
         $CustomObj = @{
            'Name' = $DeviceCur.Name;
            'Username' = $DeviceCur.Credential.UserName;
            'ValidateCertificate' = $DeviceCur.ValidateCertificate;
            'Protocol' = $DeviceCur.Protocol;
            'Port' = $DeviceCur.Port
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
         Write-Debug ($MyInvocation.MyCommand.Name + ': ' + "Storing $($StoredDeviceAgg.Count) device$(if($StoredDeviceAgg.Count -ne 1){'s'}) to $StoredJsonPath")
         # Serialize and write to storage
         ConvertTo-Json -InputObject $StoredDeviceAgg | Set-Content -Path $StoredJsonPath -Force | Out-Null
      }
   } # End Block
} # Function
