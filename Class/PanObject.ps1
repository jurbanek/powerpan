class PanObject : System.ICloneable {
    [PanDevice] $Device
    [String] $XPath
    [System.Xml.XmlDocument] $XDoc
 
    # Default constructor. If used, must assign properties manually
    PanObject() {
    }

    # Constructor accepting XML content
    PanObject([PanDevice] $Device, [String] $XPath, [System.Xml.XmlDocument] $XDoc) {
        $this.Device = $Device
        $this.XPath = $XPath
        $this.XDoc = $XDoc
    }



    # Static constructor for creating ScriptProperty properties using Update-TypeData
    # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
    # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
    # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
    # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
    static PanObject() {
        # Name ScriptProperty linked to $XDoc.entry.name
        'PanObject' | Update-TypeData -MemberName Name -MemberType ScriptProperty -Value {
        # Getter
            return $this.XDoc.Item('entry').GetAttribute('name')
        } -SecondValue {
        # Setter
            param($Set)
            $this.XDoc.Item('entry').SetAttribute('name',$Set)
        } -Force

        # Tag ScriptProperty linked to $XDoc.entry.tag It's also an array, watch out.
        # <tag><member>tag1</member><member>tag2</member><tag>
        'PanObject' | Update-TypeData -MemberName Tag -MemberType ScriptProperty -Value {
        # Getter
            return $this.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').InnerText
        } -SecondValue {
        # Setter
            param($Set)
            # If <tag> is already present
            if($this.XDoc.Item('entry').Item('tag')) {
                # Clear all <member> (and rebuild later)
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

        # Description ScriptProperty linked to $XDoc.Item('entry').Item('description').InnerText
        'PanObject' | Update-TypeData -MemberName Description -MemberType ScriptProperty -Value {
        # Getter
            return $this.XDoc.Item('entry').Item('description').InnerText
        } -SecondValue {
        # Setter
            param($Set)
            # If <description> element exists
            if($this.XDoc.Item('entry').Item('description')) {
                if([String]::IsNullOrEmpty($Set)) {
                # Remove the <description> element entirely
                $XDescription = $this.XDoc.Item('entry').Item('description')
                $this.XDoc.Item('entry').RemoveChild($XDescription)
                }
                else {
                    $this.XDoc.Item('entry').Item('description').InnerText = $Set
                }
            }
            # No existing <description>
            else {
                # Build a new <description> element
                $XDescription = $this.XDoc.CreateElement('description')
                $XDescription.InnerText = $Set
                $this.XDoc.Item('entry').AppendChild($XDescription)
            }
        } -Force

        # DisableOverride ScriptProperty linked to $XDoc.entry.Item('disable-override').InnerText
        'PanObject' | Update-TypeData -MemberName DisableOverride -MemberType ScriptProperty -Value {
        # Getter
            switch ($this.XDoc.Item('entry').Item('disable-override').InnerText) {
                no       { return $false }
                yes      { return $true }
                default  { return $null }
            }
        } -SecondValue {
        # Setter
            param($Set)
            # If <disable-override> element exists
            if($this.XDoc.Item('entry').Item('disable-override')) {
                if([String]::IsNullOrEmpty($Set)) {
                    # Remove the <disable-override> element entirely
                    $XDisable = $this.XDoc.Item('entry').Item('disable-override')
                    $this.XDoc.Item('entry').RemoveChild($XDisable)
                }
                else {
                    switch($Set) {
                        $false   { $this.XDoc.Item('entry').Item('disable-override').InnerText = 'no' }
                        $true    { $this.XDoc.Item('entry').Item('disable-override').InnerText = 'yes' }
                        # In case someone sets to 'no' or 'yes'
                        no       { $this.XDoc.Item('entry').Item('disable-override').InnerText = 'no' }
                        yes      { $this.XDoc.Item('entry').Item('disable-override').InnerText = 'yes' }
                    }
                }
            }
            # No existing <disable-override>
            else {
                # Build a new <description> element
                $XDisable = $this.XDoc.CreateElement('disable-override')
                switch($Set) {
                    $false   { $XDisable.InnerText = 'no' }
                    $true    { $XDisable.InnerText = 'yes' }
                    # In case someone sets to 'no' or 'yes'
                    no       { $XDisable.InnerText = 'no' }
                    yes      { $XDisable.InnerText = 'yes' }
                }
                $this.XDoc.Item('entry').AppendChild($XDisable)
            }
        } -Force
     
        # Location ScriptProperty linked to $XPath matching 
        #  Panorama 'MyDeviceGroup' part of device-group/entry[@name='MyDeviceGroup']
        #  Ngfw 'vsys1' part of vsys/entry[@name='vsys1']
        # PowerShell regex characters that need escaping [().\^$|?*+{
        'PanObject' | Update-TypeData -MemberName Location -MemberType ScriptProperty -Value {
        # Getter
           # Match includes a capture group to isolate the string literal device-group names or vsys1, vsys2, etc. for actual Location
           # shared
           if($this.XPath -match '/config/shared') { $RegexMatch = "/config/(shared)" }
           # Panorama device-group
           elseif($this.Device.Type -eq [PanDeviceType]::Panorama) { $RegexMatch = "device-group/entry\[@name='(\w+)'\]" }
           # Ngfw vsys
           else { $RegexMatch = "vsys/entry\[@name='(\w+)'\]"}
           # Using PowerShell native -match operator
           if($this.XPath -match $RegexMatch) { return $Matches[1] }
           # Using .NET [Regex]::Match() static method
           # return [Regex]::Match($this.XPath,$RegexMatch).Groups[1].Value
        } -SecondValue {
        # Setter
            param($Set)
            # Replace is the same as Match, but excludes the capture group (parantheses) due to issues encountered
            if($this.XPath -match '/config/shared') {
                # Do nothing
            }
            # Panorama device-group
            if($this.Device.Type -eq [PanDeviceType]::Panorama) {
                $RegexReplace = "device-group/entry\[@name='\w+'\]"
                # Using PowerShell native -replace operator
                $this.XPath = $this.XPath -replace $RegexReplace,("device-group/entry[@name='{0}']" -f $Set)
                # Using .NET [Regex]::Replace() static method
                # $this.XPath = [Regex]::Replace($this.XPath,$RegexReplace,"device-group/entry[@name='{0}']" -f $Set)
            }
            # Ngfw vsys
            else {
                $RegexReplace = "vsys/entry\[@name='\w+'\]"
                # Using PowerShell native -replace operator
                $this.XPath = $this.XPath -replace $RegexReplace,("vsys/entry[@name='{0}']" -f $Set)
                # Using .NET [Regex]::Replace() static method
                # $this.XPath = [Regex]::Replace($this.XPath,$RegexReplace,"vsys/entry[@name='{0}']" -f $Set)
            }
        } -Force
        
        # Overrides ScriptProperty linked to $XDoc.entry.overrides
        'PanObject' | Update-TypeData -MemberName Overrides -MemberType ScriptProperty -Value {
        # Getter
            return $this.XDoc.Item('entry').GetAttribute('overrides')
        } -SecondValue {
        # Setter
            param($Set)
            $this.XDoc.Item('entry').SetAttribute('overrides',$Set)
        } -Force

    } # End static constructor

    # Clone() method as part of ICloneable interface
   [Object] Clone() {
    return [PanObject]::new(
       $this.XDoc.Clone(),
       $this.XPath.Clone(),
       $this.Device
    )
 } # End method
}