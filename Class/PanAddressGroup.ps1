class PanAddressGroup : PanObject, ICloneable {
   # Defined in base class
   # [PanDevice] $Device
   # [String] $XPath
   # [System.Xml.XmlDocument] $XDoc

   # Constructor accepting XML content with call to base class to do assignment
   PanAddressGroup([PanDevice] $Device, [String] $XPath, [System.Xml.XmlDocument] $XDoc) : base() {
      $this.Device = $Device
      $this.XPath = $XPath
      $this.XDoc = $XDoc
   } # End constructor

   # Constructor for building a basic shell from non-XML content. Build/assign XML content in this constructor.
   # Handy for creating shell objects. Goal is to build out a basic shell .XDoc, .XPath, and assign the .Device
   PanAddressGroup([PanDevice] $Device, [String] $Location, [String] $Name) : base() {
      $Suffix = "/address-group/entry[@name='{0}']" -f $Name
      $XPath =  "{0}{1}" -f $Device.Location.($Location),$Suffix
      # Build a minimum viable XDoc/Api Element with obvious non-common values
      $Xml = "<entry name='{0}'><static></static></entry>" -f $Name
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
   static PanAddressGroup() {
      # Call base class static methods to add properties via Update-Type. Do not need to redefine them.
      $TypeName = 'PanAddressGroup'
      [PanObject]::AddName($TypeName)
      [PanObject]::AddTag($TypeName)
      [PanObject]::AddDescription($TypeName)
      [PanObject]::AddDisableOverride($TypeName)
      [PanObject]::AddLocation($TypeName)
      [PanObject]::AddOverrides($TypeName)

      # Define what is unique to derived class only

      # Type ScriptProperty linked to $XDoc.entry.static or $XDoc.entry.dynamic, etc.
      Update-TypeData -TypeName $TypeName -MemberName Type -MemberType ScriptProperty -Value {
      # Getter
         if($this.XDoc.Item('entry').Item('static')) { return 'static' }
         elseif($this.XDoc.Item('entry').Item('dynamic')) { return 'dynamic' }
      } -SecondValue {
      # Setter
         param($Set)
         if($this.Type -eq $Set) {
            # Do nothing if setting to same type
         }
         else {
            # Clear out the current <static> or <dynamic> element and rebuild based on $Set
            # No need to deep copy since <static> and <dynamic> have entirely different children
            $OldChild = $this.Item('entry').Item($this.Type)
            $OldChild.ParentNode.RemoveChild($OldChild)

            $NewChild = $this.XDoc.CreateElement($Set)
            $this.XDoc.Item('entry').AppendChild($NewChild)
         }
      } -Force
      
      # Member ScriptProperty linked to $XDoc.entry.static.member It's also an array, watch out.
      # <static><member>A-1</member><member>A-2</member><static>
      Update-TypeData -TypeName $TypeName -MemberName Member -MemberType ScriptProperty -Value {
      # Getter
         return $this.XDoc.Item('entry').Item('static').GetElementsByTagName('member').InnerText
      } -SecondValue {
      # Setter
         param($Set)
         # If <static> is already present
         if($this.XDoc.Item('entry').Item('static')) {
            # Clear all <member> (and rebuild later)
            $this.XDoc.Item('entry').Item('static').RemoveAll()
         }
         # Else <static> is not present
         else {
            # Build and add <static>
            $XStatic = $this.XDoc.CreateElement('static')
            $this.XDoc.Item('entry').AppendChild($XStatic)
         }
         # Build inner <member>'s
         foreach($MemberCur in $Set) {
            $XMember = $this.XDoc.CreateElement('member')
            $XMember.InnerText = $MemberCur
            $this.XDoc.Item('entry').Item('static').AppendChild($XMember)
         }
      } -Force
 
      # Filter ScriptProperty linked to $XDoc.entry.dynamic.filter.InnerText
      Update-TypeData -TypeName $TypeName -MemberName Filter -MemberType ScriptProperty -Value {
      # Getter
         return $this.XDoc.Item('entry').Item('dynamic').Item('filter').InnerText
      } -SecondValue {
      # Setter
         param($Set) 
         # If <dynamic> is not already present
         if(-not $this.XDoc.Item('entry').Item('dynamic')) {
            # Build and add <dynamic>
            $XDynamic = $this.XDoc.CreateElement('dynamic')
            $this.XDoc.Item('entry').AppendChild($XDynamic)         
         }
         # If <filter> element exists
         if($this.XDoc.Item('entry').Item('dynamic').Item('filter')) {
            if([String]::IsNullOrEmpty($Set)) {
               # Remove the <filter> element entirely
               $XFilter = $this.XDoc.Item('entry').Item('dynamic').Item('filter')
               $this.XDoc.Item('entry').RemoveChild($XFilter)
            }
            else {
               $this.XDoc.Item('entry').Item('dynamic').Item('filter').InnerText = $Set
            }
         }
         # No existing <filter>
         else {
            # Build a new <filter> element
            $XFilter = $this.XDoc.CreateElement('filter')
            $XFilter.InnerText = $Set
            $this.XDoc.Item('entry').Item('dynamic').AppendChild($XFilter)
         }
      } -Force
   } # End static constructor

   # Clone() method as part of ICloneable interface
   [Object] Clone() {
      return [PanAddressGroup]::new(
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
