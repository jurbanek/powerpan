class PanAddress:ICloneable {
   # Address object name
   [String] $Name
   # Address object value
   [String] $Value
   # Address object type
   [PanAddressType] $Type
   # Address object description
   [String] $Description
   # PAN-OS Tag(s) applied to the object
   [System.Collections.Generic.List[String]] $Tag
   # Parent PanDevice address references
   [PanDevice] $Device
   # Location within parent PanDevice address references
   [String] $Location

   # Default Constructor
   PanAddress() {
   }

   # Constructor accepting...
   PanAddress([String] $Name, [String] $Value, [PanAddressType] $Type = [PanAddressType]::IpNetmask, [String] $Description = $null,
         [System.Collections.Generic.List[String]] $Tag = [System.Collections.Generic.List[String]]@(),
         [PanDevice] $Device = $null, [String] $Location = $null) {
      $this.Name = $Name
      $this.Value = $Value
      $this.Type = $Type
      $this.Description = $Description
      $this.Tag = $Tag
      $this.Device = $Device
      $this.Location = $Location
   }

   # Constructor accepting...
   PanAddress([String] $Name, [String] $Value, [PanAddressType] $Type = [PanAddressType]::IpNetmask, [String] $Description = $null,
         [System.Collections.Generic.List[String]] $Tag = [System.Collections.Generic.List[String]]@()) {
      $this.Name = $Name
      $this.Value = $Value
      $this.Type = $Type
      $this.Description = $Description
      $this.Tag = $Tag
   }

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanAddress]::new(
         $this.Name,
         $this.Value,
         $this.Type,
         $this.Description,
         $this.Tag,
         $this.Device,
         $this.Location
      )
   }
} # End class PanAddress
