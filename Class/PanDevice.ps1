class PanDevice {
   # Name or IP address of PAN device
   [String] $Name
   # Username and Password can be used to generate API key.
   [PSCredential] $Credential
   # API key
   [SecureString] $Key
   # Label construct facilitates "friendly name", "grouping", and other to-be-discovered uses. PowerPAN specific label.
   [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@()
   # Whether or not X.509 certificates must be trusted. $false permits self-signed and otherwise untrusted certificates.
   [Bool] $ValidateCertificate = $false
   # Protocol identifier
   [String] $Protocol = 'https'
   # Port number
   [Int] $Port = 443
   # Ngfw or Panorama. Defaults to Ngfw
   [PanDeviceType] $Type = [PanDeviceType]::Ngfw
   # For Ngfw, contains the list of vsys's. For Panorama, the list of device-groups. Not persisted to disk. Updated at runtime.
   # Hashtable keys are vsys1, vsys2. Hashtable values are the XPath's
   [System.Collections.Specialized.OrderedDictionary] $Location = [System.Collections.Specialized.OrderedDictionary]::new()
   # Location layout is updated at runtime. Only needs to be done infrequently. Track the last time it was done.
   # DateTime (without timezone) is fine given this will only be used within the same PowerShell session
   [DateTime] $LocationUpdated

   # Default Constructor
   PanDevice() {
   }
   # Constructor accepting a PSCredential (username/password)
   PanDevice([String] $Name, [PSCredential] $Credential, [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@(),
      [Bool] $ValidateCertificate = $false , [String] $Protocol = 'https', [Int] $Port = 443, [PanDeviceType] $Type = [PanDeviceType]::Ngfw) {
      
      $this.Name = $Name
      $this.Credential = $Credential
      $this.Label = $Label
      $this.ValidateCertificate = $ValidateCertificate
      $this.Protocol = $Protocol
      $this.Port = $Port
      $this.Type = $Type
      $this.Location = [System.Collections.Specialized.OrderedDictionary]::new()
   }
   # Constructor accepting a SecureString (API key only)
   PanDevice([String] $Name, [SecureString] $Key, [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@(),
      [Bool] $ValidateCertificate = $false , [String] $Protocol = 'https', [Int] $Port = 443, [PanDeviceType] $Type = [PanDeviceType]::Ngfw) {
      
      $this.Name = $Name
      $this.Key = $Key
      $this.Label = $Label
      $this.ValidateCertificate = $ValidateCertificate
      $this.Protocol = $Protocol
      $this.Port = $Port
      $this.Type = $Type
      $this.Location = [System.Collections.Specialized.OrderedDictionary]::new()
   }
   # Constructor accepting a PSCredential (username/password) and SecureString (API key)
   PanDevice([String] $Name, [PSCredential] $Credential, [SecureString] $Key, [System.Collections.Generic.List[String]] $Label = [System.Collections.Generic.List[String]]@(),
      [Bool] $ValidateCertificate = $false , [String] $Protocol = 'https', [Int] $Port = 443, [PanDeviceType] $Type = [PanDeviceType]::Ngfw) {
      
      $this.Name = $Name
      $this.Credential = $Credential
      $this.Key = $Key
      $this.Label = $Label
      $this.ValidateCertificate = $ValidateCertificate
      $this.Protocol = $Protocol
      $this.Port = $Port
      $this.Type = $Type
      $this.Location = [System.Collections.Specialized.OrderedDictionary]::new()
   }
   
   # ToString() Method
   [String] ToString() {
      return $this.Name
   } # End method
} # End class PanDevice
