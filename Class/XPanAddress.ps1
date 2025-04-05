class XPanAddress {
   [PanDevice] $Device
   [System.Xml.XmlDocument] $XDoc
   [String] $XPath

   # Constructor
   XPanAddress([System.Xml.XmlDocument] $XDoc, [String] $XPath, [PanDevice] $Device) {
      $this.Device = $Device
      $this.XDoc = $XDoc
      $this.XPath = $XPath
   }

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static XPanAddress() {
      # Name ScriptProperty linked to $XDoc.entry.name
      'XPanAddress' | Update-TypeData -MemberName Name -MemberType ScriptProperty -Value {
            # Getter
            return $this.XDoc.Item('entry').GetAttribute('name')
         } -SecondValue {
            # Setter
            param($Set)
            $this.XDoc.Item('entry').SetAttribute('name',$Set)
         } -Force
      
      # Value ScriptProperty linked to $XDoc.entry.Item(*type*).InnerText
      'XPanAddress' | Update-TypeData -MemberName Value -MemberType ScriptProperty -Value {
            # Getter
            return $this.XDoc.Item('entry').Item($this.Type).InnerText
         } -SecondValue {
            # Setter
            param($Set)
            $this.XDoc.Item('entry').Item($this.Type).InnerText = $Set
         } -Force
      
      # Type ScriptProperty linked to $XDoc.entry.ip-netmask or $XDoc.entry.fqdn, etc.
      'XPanAddress' | Update-TypeData -MemberName Type -MemberType ScriptProperty -Value {
         # Getter
         if($this.XDoc.Item('entry').Item('ip-netmask').Count) { return 'ip-netmask' }
         elseif($this.XDoc.Item('entry').Item('fqdn').Count) { return 'fqdn' }
         elseif($this.XDoc.Item('entry').Item('ip-range').Count) { return 'ip-range' }
         elseif($this.XDoc.Item('entry').Item('ip-wildcard').Count) { return 'ip-wildcard' }
      } -Force
      # No Setter for Type. Changing type can be done by creating a new object.

      # Tag ScriptProperty linked to $XDoc.entry.Item('tag'). It's also an array, watch out.
      # <tag><member>tag1</member><member>tag2</member><tag>
      'XPanAddress' | Update-TypeData -MemberName Tag -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         # If <tag> is already present
         if($this.XDoc.Item('entry').Item('tag').Count) {
            # Clear all <member> and rebuild
            $this.XDoc.Item('entry').Item('tag').RemoveAll()
         }
         # Else <tag> is not present
         else {
            # Build and add <tag>
            $XTag = $this.XDoc.CreateElement('tag')
            $this.XDoc.Item('entry').AppendChild($XTag)
         }
         # Build inner <member>'s
         foreach($TagCur in $Set) {
            $XMember = $this.XDoc.CreateElement('member')
            $XMember.InnerText = $TagCur
            $this.XDoc.Item('entry').Item('tag').AppendChild($XMember)
         }
      } -Force

      # Description ScriptProperty linked to $XDoc.entry.Item('description').InnerText
      'XPanAddress' | Update-TypeData -MemberName Description -MemberType ScriptProperty -Value {
         # Getter
         return $this.XDoc.Item('entry').Item('description').InnerText
      } -SecondValue {
         # Setter
         param($Set)
         if($this.XDoc.Item('entry').Item('description').Count) {
            $this.XDoc.Item('entry').Item('description').InnerText = $Set
         }
         else {
            # Build a new <description> element
            $XDescription = $this.XDoc.CreateElement('description')
            $XDescription.InnerText = $Set
            $this.XDoc.Item('entry').AppendChild($XDescription)
         }
      } -Force
      
      # Location ScriptProperty linked to $XPath matching 'vsys1' part of vsys/entry[@name='vsys1']
      # PowerShell regex characters that need escaping [().\^$|?*+{
      'XPanAddress' | Update-TypeData -MemberName Location -MemberType ScriptProperty -Value {
            # Getter
            # Match includes a capture group to isolate the string literal vsys1, vsys2, etc. for actual Location
            $RegexMatch = "vsys/entry\[@name='(\w+)'\]"
            # Using PowerShell native -match operator
            if($this.XPath -match $RegexMatch) { return $Matches[1] }
            # Using .NET [Regex]::Match() static method
            # return [Regex]::Match($this.XPath,$RegexMatch).Groups[1].Value
         } -SecondValue {
            # Setter
            param($Set)
            # Replace is the same as Match, but excludes the capture group (parantheses) due to issues encountered
            $RegexReplace = "vsys/entry\[@name='\w+'\]"
            # Using PowerShell native -replace operator
            $this.XPath = $this.XPath -replace $RegexReplace,("vsys/entry[@name='{0}']" -f $Set)
            # Using .NET [Regex]::Replace() static method
            # $this.XPath = [Regex]::Replace($this.XPath,$RegexReplace,"vsys/entry[@name='{0}']" -f $Set)
         } -Force
   }

} # End class
