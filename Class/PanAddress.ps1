class PanAddress : PanObject, ICloneable {
   # Defined in base class
   # [PanDevice] $Device
   # [String] $XPath
   # [System.Xml.XmlDocument] $XDoc

   # Constructor accepting XML content with call to base class to do assignment
   PanAddress([PanDevice] $Device, [String] $XPath, [System.Xml.XmlDocument] $XDoc) : base() {
      $this.Device = $Device
      $this.XPath = $XPath
      $this.XDoc = $XDoc
   } # End constructor

   # Constructor for building a basic shell from non-XML content. Build/assign XML content in this constructor.
   # Handy for creating shell objects. Goal is to build out a basic shell .XDoc, .XPath, and assign the .Device
   PanAddress([PanDevice] $Device, [String] $Location, [String] $Name) : base() {
      $Suffix = "/address/entry[@name='{0}']" -f $Name
      $XPath =  "{0}{1}" -f $Device.Location.($Location),$Suffix
      # Build a minimum viable XDoc/Api Element with obvious non-common values
      $Xml = "<entry name='{0}'><ip-netmask>0.0.0.0</ip-netmask></entry>" -f $Name
      $XDoc = [System.Xml.XmlDocument]$Xml

      $this.Device = $Device
      $this.XPath = $XPath
      $this.XDoc = $XDoc
   } # End constructor

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static PanAddress() {
      # Call base class static methods to add properties via Update-Type. Do not need to redefine them.
      $TypeName = 'PanAddress'
      [PanObject]::AddName($TypeName)
      [PanObject]::AddTag($TypeName)
      [PanObject]::AddDescription($TypeName)
      [PanObject]::AddDisableOverride($TypeName)
      [PanObject]::AddLocation($TypeName)
      [PanObject]::AddOverrides($TypeName)
      
      # Define what is unique to derived class only

      # Type ScriptProperty linked to $XDoc.entry.ip-netmask or $XDoc.entry.fqdn, etc.
      Update-TypeData -TypeName $TypeName -MemberName Type -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').Item('ip-netmask')) { return 'ip-netmask' }
         elseif($this.XDoc.Item('entry').Item('fqdn')) { return 'fqdn' }
         elseif($this.XDoc.Item('entry').Item('ip-range')) { return 'ip-range' }
         elseif($this.XDoc.Item('entry').Item('ip-wildcard')) { return 'ip-wildcard' }
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
      
      # Value ScriptProperty linked to $XDoc.entry.Item(*type*).InnerText
      Update-TypeData -TypeName $TypeName -MemberName Value -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item($this.Type).InnerText
      } -SecondValue {
         # Setter
         param($Set)
         $this.XDoc.Item('entry').Item($this.Type).InnerText = $Set
      } -Force
            
   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanAddress]::new(
         $this.Device,
         $this.XPath.Clone(),
         $this.XDoc.Clone()
      )
   } # End method

   # ToString() Method
   [String] ToString() {
      return $this.Name
   } # End method

} # End class
