class PanRegisteredIp {
   # IP address representing the registered-ip
   [String] $Ip
   # Tag(s) applied to the registered-ip
   [String[]] $Tag
   # Optional Parent PanDevice from which the tag mapping was identified
   [PanDevice] $ParentDevice

   # Default Constructor
   PanRegisteredIp() {
   }
   # Constructor accepting...
   PanRegisteredIp([String] $Ip, [String[]] $Tag) {
      $this.Ip = $Ip
      $this.Tag = $Tag
      $this.ParentDevice = $null
   }
   # Constructor accepting...
   PanRegisteredIp([String] $Ip, [String[]] $Tag, [PanDevice] $ParentDevice) {
      $this.Ip = $Ip
      $this.Tag = $Tag
      $this.ParentDevice = $ParentDevice
   }
   # Oblitagory ToString() Method
   [String] ToString() {
      return ($this.Ip + '->' + $this.Tag)
   }
} # End class PanRegisteredIp