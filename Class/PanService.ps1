class PanService : PanObject, System.ICloneable {
   # Defined in the base class
   # [PanDevice] $Device
   # [System.Xml.XmlDocument] $XDoc
   # [String] $XPath

   # Constructor calling the base class constructor
   PanService([System.Xml.XmlDocument] $XDoc, [String] $XPath, [PanDevice] $Device) : base ($XDoc, $XPath, $Device) {
      # Nothing to do here in derived class
   } # End constructor

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static PanService() {
      # Base class static constructor adds the following standard properties via Update-Type. Do not need to redefine here.
      # Name
      # Tag
      # Description
      # DisableOverride
      # Location
      # Overrides
      
      # Define what is unique to derived class only

      # Protocol ScriptProperty linked to $XDoc.entry.protocol.tcp or udp
      'PanService' | Update-TypeData -MemberName Protocol -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').Item('protocol').GetElementsByTagName('tcp').Count) { return 'tcp' }
         elseif($this.XDoc.Item('entry').Item('protocol').GetElementsByTagName('udp').Count) { return 'udp' }
      } -SecondValue {
         # Setter
         param($Set)
         # "Renaming" a XmlElement is not easy
         $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol)
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

      # Port ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).port.InnerText
      'PanService' | Update-TypeData -MemberName Port -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('port').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('port').InnerText = $Set
      } -Force
            
      # SourcePort ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).source-port.InnerText
      'PanService' | Update-TypeData -MemberName SourcePort -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('source-port').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         # If <source-port> element exists
         if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('source-port').Count) {
            if([String]::IsNullOrEmpty($Set)) {
               # Remove the <source-port> element entirely
               $XSourcePort = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('source-port')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).RemoveChild($XSourcePort)
            }
            else {
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('source-port').InnerText = $Set
            }
         }
         # No existing <source-port>
         else {
            # Build a new <source-port> element
            $XSourcePort = $this.XDoc.CreateElement('source-port')
            $XSourcePort.InnerText = $Set
            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).AppendChild($XSourcePort)
         }
      } -Force
      
      # OverrideTimeout ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).override.Item('yes') or no
      'PanService' | Update-TypeData -MemberName OverrideTimeout -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').GetElementsByTagName('yes').Count) {
            return $true
         }
         elseif($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').GetElementsByTagName('no').Count) {
            return $false
         }
      } -SecondValue {
         # Setter
         param($Set)
         # If <override><yes> already exists
         if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').GetElementsByTagName('yes').Count) {
            if($Set) {
               # Do nothing
            }
            elseif(-not $Set) {
               # Change to <no>
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')
               # Create new XmlElement
               $NewElement = $this.XDoc.CreateElement('no')
               # Replace/relink the new tree
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
            }
         }
         # If <override><no> already exists
         elseif($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').GetElementsByTagName('no').Count) {
            if($Set) {
               # Change to <yes>, no children
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')
               # Create new XmlElement
               $NewElement = $this.XDoc.CreateElement('yes')
               # Replace/relink the new tree
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
            }
            elseif(-not $Set) {
               # Make sure there are no children
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no').RemoveAll()
            }
         }
         # Make sure <override> already exists
         elseif(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).GetElementsByTagName('override').Count) {
            $XOverride = $this.XDoc.CreateElement('override')
            if($Set) { $XValue = $this.XDoc.CreateElement('yes') } else { $XValue = $this.XDoc.CreateElement('no') }
            $XOverride.AppendChild($XValue)
            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).AppendChild($XOverride)
         }
      } -Force

      ### LEFT OFF HERE
      ### timeout, halfclose-timeout, timewait-timeout
      ###

   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanService]::new(
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
