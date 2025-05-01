class PanService : PanObject, System.ICloneable {
   # Defined in base class
   # [PanDevice] $Device
   # [String] $XPath
   # [System.Xml.XmlDocument] $XDoc

   # Constructor accepting XML content with call to base class to do assignment
   PanService([PanDevice] $Device, [String] $XPath, [System.Xml.XmlDocument] $XDoc) : base() {
      $this.Device = $Device
      $this.XPath = $XPath
      $this.XDoc = $XDoc
   } # End constructor

   # Constructor for building a basic shell from non-XML content. Build/assign XML content in this constructor.
   # Handy for creating shell objects. Goal is to build out a basic shell .XDoc, .XPath, and assign the .Device
   PanService([PanDevice] $Device, [String] $Location, [String] $Name) : base() {
      $Suffix = "/service/entry[@name='{0}']" -f $Name
      $XPath =  "{0}{1}" -f $Device.Location.($Location),$Suffix
      # Build a minimum viable XDoc/Api Element with obvious non-common values
      $Xml = "<entry name='{0}'><protocol><tcp><port>0</port></tcp></protocol></entry>" -f $Name
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
   static PanService() {
      # Call base class static methods to add properties via Update-Type. Do not need to redefine them.
      $TypeName = 'PanService'
      [PanObject]::AddName($TypeName)
      [PanObject]::AddTag($TypeName)
      [PanObject]::AddDescription($TypeName)
      [PanObject]::AddDisableOverride($TypeName)
      [PanObject]::AddLocation($TypeName)
      [PanObject]::AddOverrides($TypeName)
      
      # Define what is unique to derived class only

      # Protocol ScriptProperty linked to $XDoc.entry.protocol.tcp or udp
      Update-TypeData -TypeName $TypeName -MemberName Protocol -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').Item('protocol').Item('tcp')) { return 'tcp' }
         elseif($this.XDoc.Item('entry').Item('protocol').Item('udp')) { return 'udp' }
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
      Update-TypeData -TypeName $TypeName -MemberName Port -MemberType ScriptProperty -Value {
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
         if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('source-port')) {
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

      # Timeout ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).override.yes.timeout.InnerText
      Update-TypeData -TypeName $TypeName -MemberName Timeout -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         # If <override> doesn't exist, create
         if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override')) {
            $XOverride = $this.XDoc.CreateElement('override')
            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).AppendChild($XOverride)
         }
         if($Set) {
            # If <override><no>, replace with <yes>
            if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')
               $NewElement = $this.XDoc.CreateElement('yes')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
            }
            # If <override><yes> doesn't exist, create
            elseif(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')) {
               $XYes = $this.XDoc.CreateElement('yes')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').AppendChild($XYes)
            }

            # If <override><yes><timeout> doesn't exist, create
            if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout')) {
               $XTimeout = $this.XDoc.CreateElement('timeout')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').AppendChild($XTimeout)
            }

            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout').InnerText = $Set
         }      
         elseif(-not $Set) {
            $XTimeout = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout')
            $XTimeout.ParentNode.RemoveChild($XTimeout)
         }
         
         # If timeout, halfclose-timeout, timewait-timeout are no longer present, change to <override><no>
         if([String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout').InnerText) ) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')
               $NewElement = $this.XDoc.CreateElement('no')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
         }
      } -Force

      # HalfCloseTimeout ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).override.yes.halfclose-timeout.InnerText
      Update-TypeData -TypeName $TypeName -MemberName HalfCloseTimeout -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         # If <override> doesn't exist, create
         if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override')) {
            $XOverride = $this.XDoc.CreateElement('override')
            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).AppendChild($XOverride)
         }
         if($Set) {
            # If <override><no>, replace with <yes>
            if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')
               $NewElement = $this.XDoc.CreateElement('yes')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
            }
            # If <override><yes> doesn't exist, create
            elseif(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')) {
               $XYes = $this.XDoc.CreateElement('yes')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').AppendChild($XYes)
            }

            # If <override><yes><halfclose-timeout> doesn't exist, create
            if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout')) {
               $XTimeout = $this.XDoc.CreateElement('halfclose-timeout')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').AppendChild($XTimeout)
            }

            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout').InnerText = $Set
         }      
         elseif(-not $Set) {
            $XTimeout = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout')
            $XTimeout.ParentNode.RemoveChild($XTimeout)
         }
         
         # If timeout, halfclose-timeout, timewait-timeout are no longer present, change to <override><no>
         if([String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout').InnerText) ) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')
               $NewElement = $this.XDoc.CreateElement('no')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
         }
      } -Force

      # TimeWaitTimeout ScriptProperty linked to $XDoc.entry.protocol.Item(*Protocol*).override.yes.timewait-timeout.InnerText
      Update-TypeData -TypeName $TypeName -MemberName TimeWaitTimeout -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         # If <override> doesn't exist, create
         if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override')) {
            $XOverride = $this.XDoc.CreateElement('override')
            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).AppendChild($XOverride)
         }
         if($Set) {
            # If <override><no>, replace with <yes>
            if($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('no')
               $NewElement = $this.XDoc.CreateElement('yes')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
            }
            # If <override><yes> doesn't exist, create
            elseif(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')) {
               $XYes = $this.XDoc.CreateElement('yes')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').AppendChild($XYes)
            }

            # If <override><yes><timewait-timeout> doesn't exist, create
            if(-not $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout')) {
               $XTimeout = $this.XDoc.CreateElement('timewait-timeout')
               $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').AppendChild($XTimeout)
            }

            $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout').InnerText = $Set
         }      
         elseif(-not $Set) {
            $XTimeout = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout')
            $XTimeout.ParentNode.RemoveChild($XTimeout)
         }
         
         # If timeout, halfclose-timeout, timewait-timeout are no longer present, change to <override><no>
         if([String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('halfclose-timeout').InnerText) -and
            [String]::IsNullOrEmpty($this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes').Item('timewait-timeout').InnerText) ) {
               $OldElement = $this.XDoc.Item('entry').Item('protocol').Item($this.Protocol).Item('override').Item('yes')
               $NewElement = $this.XDoc.CreateElement('no')
               $OldElement.ParentNode.ReplaceChild($NewElement,$OldElement)
         }
      } -Force
   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanService]::new(
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
