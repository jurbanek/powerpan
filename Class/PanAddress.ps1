class PanAddress {
   # Address object name
   [String] $Name
   # Address object description
   [String] $Description
   # Address object type
   [String] $Type
   # Address object value
   [String] $Value
   # PAN-OS Tag(s) applied to the object
   [String[]] $Tag
   # Optional Parent PanDevice from which was identified
   [PanDevice] $Device

   # Default Constructor
   PanAddress() {
   }
   <#
   # Constructor accepting...
   PanRegisteredIp([String] $Ip, [String[]] $Tag) {
      $this.Ip = $Ip
      $this.Tag = $Tag
      $this.Device = $null
   }
   # Constructor accepting...
   PanRegisteredIp([String] $Ip, [String[]] $Tag, [PanDevice] $Device) {
      $this.Ip = $Ip
      $this.Tag = $Tag
      $this.Device = $Device
   }
   # Oblitagory ToString() Method
   [String] ToString() {
      return ($this.Ip + '->' + $this.Tag)
   }
   #>
} # End class PanAddress
