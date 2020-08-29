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
   # Parent PanDevice address references
   [PanDevice] $Device
   # Location within parent PanDevice address references
   [String] $Location

   # Default Constructor
   PanAddress() {
   }
} # End class PanAddress
