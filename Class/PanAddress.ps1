class PanAddress : PanObject, ICloneable {
   # Defined in the base class
   # [PanDevice] $Device
   # [System.Xml.XmlDocument] $XDoc
   # [String] $XPath

   # Constructor calling the base class constructor
   PanAddress([System.Xml.XmlDocument] $XDoc, [String] $XPath, [PanDevice] $Device) : base ($XDoc, $XPath, $Device) {
      # Nothing to do here in derived class
   } # End constructor

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static PanAddress() {
      # Base class static constructor adds the following standard properties via Update-Type. Do not need to redefine here.
      # Name
      # Tag
      # Description
      # DisableOverride
      # Location
      # Overrides
      
      # Define what is unique to derived class only

      # Value ScriptProperty linked to $XDoc.entry.Item(*type*).InnerText
      'PanAddress' | Update-TypeData -MemberName Value -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item($this.Type).InnerText
      } -SecondValue {
         # Setter
         param($Set)
         $this.XDoc.Item('entry').Item($this.Type).InnerText = $Set
      } -Force
      
      # Type ScriptProperty linked to $XDoc.entry.ip-netmask or $XDoc.entry.fqdn, etc.
      'PanAddress' | Update-TypeData -MemberName Type -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').GetElementsByTagName('ip-netmask').Count) { return 'ip-netmask' }
         elseif($this.XDoc.Item('entry').GetElementsByTagName('fqdn').Count) { return 'fqdn' }
         elseif($this.XDoc.Item('entry').GetElementsByTagName('ip-range').Count) { return 'ip-range' }
         elseif($this.XDoc.Item('entry').GetElementsByTagName('ip-wildcard').Count) { return 'ip-wildcard' }
      } -SecondValue {
         # Setter
         param($Set)
         # "Renaming" a XmlElement is not easy
         $OldElement = $this.XDoc.Item('entry').Item($this.Type)
         # Create new XmlElement
         $NewElement = $this.XDoc.CreateElement($Set)
         # Deep copy the attributes
         foreach($AttributeCur in $OldElement.Attributes) {
            $NewElement.SetAttribute($AttributeCur.Name,$AttributeCur.Value)
         }
         # Deep copy any ChildNodes
         # Note: #text/"InnerText" <element>InnerText</element> is considered a ChildNode, so the following covers InnerText as well as child elements
         foreach($ChildNodeCur in $OldElement.ChildNodes) {
            $ImportedNode = $this.XDoc.ImportNode($ChildNodeCur.Clone(),$true)
            $NewElement.AppendChild($ImportedNode)
         }
         # Replace/relink the new tree
         $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
      } -Force

      
   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanAddress]::new(
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
