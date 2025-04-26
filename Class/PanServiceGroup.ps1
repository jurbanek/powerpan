class PanServiceGroup : PanObject, ICloneable {
   # Defined in the base class
   # [PanDevice] $Device
   # [String] $XPath
   # [System.Xml.XmlDocument] $XDoc

   # Constructor accepting XML content with call to base class to do assignment
   PanServiceGroup([PanDevice] $Device, [String] $XPath, [System.Xml.XmlDocument] $XDoc) : base() {
      $this.XPath = $XPath
      $this.XDoc = $XDoc
      $this.Device = $Device
   } # End constructor

   # Constructor for building a basic shell from non-XML content. Build/assign XML content in this constructor.
   # Handy for creating shell objects. Goal is to build out a basic shell .XDoc, .XPath, and assign the .Device
   PanServiceGroup([PanDevice] $Device, [String] $Location, [String] $Name) : base() {
      $Suffix = "/service-group/entry[@name='{0}']" -f $Name
      $XPath =  "{0}{1}" -f $Device.Location.($Location),$Suffix
      # Build a minimum viable XDoc/Api Element with obvious non-common values
      $Xml = "<entry name='{0}'><members></members></entry>" -f $Name
      $XDoc = [System.Xml.XmlDocument]$Xml

      $this.XPath = $XPath
      $this.XDoc = $XDoc
      $this.Device = $Device
   } # End constructor

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static PanServiceGroup() {
      # Base class static constructor adds the following standard properties via Update-Type. Do not need to redefine here.
      # Name
      # Tag
      # Description
      # DisableOverride
      # Location
      # Overrides
      
      # Define what is unique to derived class only
      
      # Member ScriptProperty linked to $XDoc.entry.static.member It's also an array, watch out.
      # <members><member>tcp-80</member><member>tcp-443</member><members>
      'PanServiceGroup' | Update-TypeData -MemberName Member -MemberType ScriptProperty -Value {
      # Getter
         return $this.XDoc.Item('entry').Item('members').GetElementsByTagName('member').InnerText
      } -SecondValue {
      # Setter
         param($Set)
         # If <members> is already present
         if($this.XDoc.Item('entry').Item('members')) {
            # Clear all <member> (and rebuild later)
            $this.XDoc.Item('entry').Item('members').RemoveAll()
         }
         # Else <members> is not present
         else {
            # Build and add <members>
            $XMembers = $this.XDoc.CreateElement('members')
            $this.XDoc.Item('entry').AppendChild($XMembers)
         }
         # Build inner <member>'s
         foreach($MemberCur in $Set) {
            $XMember = $this.XDoc.CreateElement('member')
            $XMember.InnerText = $MemberCur
            $this.XDoc.Item('entry').Item('members').AppendChild($XMember)
         }
      } -Force
 
   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanServiceGroup]::new(
         $this.XDoc.Clone(),
         $this.XPath.Clone(),
         $this.Device
      )
   } # End method

   # ToString() Method
   [String] ToString() {
      return $this.Name
   } # End method

} # End class
