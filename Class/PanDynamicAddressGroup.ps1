class PanDynamicAddressGroup : PanObject {
   # 
   # Defined in the base class
   # [PanDevice] $Device
   # Override the XPath as hidden since it is irrelevant for this class
   hidden [String] $XPath
   # [System.Xml.XmlDocument] $XDoc


   # Constructor accepting XML content with call to base class to do assignment
   PanDynamicAddressGroup([PanDevice] $Device, [System.Xml.XmlDocument] $XDoc) : base() {
      $this.Device = $Device
      # $XPath not necessary
      $this.XDoc = $XDoc
   } # End constructor

   # Static constructor for creating ScriptProperty properties using Update-TypeData
   # Update-TypeData in static contructor is PREFERRED to Add-Member in regular contructor
   # Update-TypeData within static constructor runs ONLY ONCE the first time the type is used is the PowerShell session
   # Contrast with Add-Member within regular constructor runs EVERY TIME a new object is created from the class
   # Be careful choosing where to use linebreaks in the middle of the Update-TypeData cmdlet call. Using linebreaks for getter/setter readability
   static PanDynamicAddressGroup() {
      $TypeName = 'PanDynamicAddressGroup'

      # Define what is unique to derived class only
      # Not calling any base class static methods for adding properties
      # Dynamic Address Groups have an entirely different XML structure
      
      # Name ScriptProperty linking depends on Ngfw/Panorama
      Update-TypeData -TypeName $TypeName -MemberName Name -MemberType ScriptProperty -Value {
      # Getter
         # Different structures depending on NGFW and Panorama
         if($this.Device.Type -eq [PanDeviceType]::Ngfw) {
            return $this.XDoc.SelectSingleNode('/entry/group-name').InnerText
         }
         elseif($this.Device.Type -eq [PanDeviceType]::Panorama) {
            return $this.XDoc.SelectSingleNode('/entry/address-group').GetAttribute('name')
         }
      } -Force
      # No Setter

      # Member ScriptProperty linking depends on Ngfw/Panorama
      Update-TypeData -TypeName $TypeName -MemberName Member -MemberType ScriptProperty -Value {
      # Getter
         # Different structures depending on NGFW and Panorama
         if($this.Device.Type -eq [PanDeviceType]::Ngfw) {
            $MemberAgg = @()
            $MemberList = $this.XDoc.SelectNodes('/entry/member-list/entry')
            foreach($Cur in $MemberList) {
               $MemberAgg += $Cur.GetAttribute('name')
            }
            return $MemberAgg
         }
         elseif($this.Device.Type -eq [PanDeviceType]::Panorama) {
            $MemberAgg = @()
            $MemberList = $this.XDoc.SelectNodes('/entry/address-group/member-list/entry')
            foreach($Cur in $MemberList) {
               $MemberAgg += $Cur.GetAttribute('name')
            }
            return $MemberAgg
         }
      } -Force
      # No Setter

      # Filter ScriptProperty linking depends on Ngfw/Panorama
      Update-TypeData -TypeName $TypeName -MemberName Filter -MemberType ScriptProperty -Value {
      # Getter
         # Different structures depending on NGFW and Panorama
         if($this.Device.Type -eq [PanDeviceType]::Ngfw) {
            return $this.XDoc.SelectSingleNode('/entry/filter').InnerText
         }
         elseif($this.Device.Type -eq [PanDeviceType]::Panorama) {
            return $this.XDoc.SelectSingleNode('/entry/address-group/filter').InnerText
         }
      } -Force
      # No Setter

      # Location ScriptProperty linking depends on Ngfw/Panorama
      Update-TypeData -TypeName $TypeName -MemberName Location -MemberType ScriptProperty -Value {
      # Getter
         # Different structures depending on NGFW and Panorama
         if($this.Device.Type -eq [PanDeviceType]::Ngfw) {
            # If <entry><vsys> exists, it's the InnerText. If the element is missing, it's shared
            if($this.XDoc.SelectSingleNode('/entry/vsys')) {
               return $this.XDoc.SelectSingleNode('/entry/vsys').InnerText
            }
            else {
               return 'shared'
            }
         }
         elseif($this.Device.Type -eq [PanDeviceType]::Panorama) {
            return $this.XDoc.SelectSingleNode('/entry').GetAttribute('name')
         }
      } -Force
      # No Setter
   
   } # static constructor
   
   # ToString() Method
   [String] ToString() {
      return $this.Name
   } # End method

} # End class
