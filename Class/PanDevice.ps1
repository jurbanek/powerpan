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
   [System.Collections.Generic.List[String]] $Location = [System.Collections.Generic.List[String]]@()
   # Location layout updated at runtime. Only needs to be done once per session. Track whether it has been done here.
   $LocationUpdated = $false
   # Vsys layout for cmdlets that operate on multiple vsys. Not persisted to disk. Updated at runtime.
   [String[]] $Vsys = @('vsys1')
   # Vsys layout updated at runtime. Only needs to be done once per session. Track whether it has been done here.
   [Bool] $VsysUpdated = $false
   # Default operational vsys for cmdlets that operate on multiple vsys. Not persisted to disk.
   [String] $VsysDefault = 'vsys1'

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
   }
   # Oblitagory ToString() Method
   [String] ToString() {
      return $this.Name
   } # End method
} # End class PanDevice
