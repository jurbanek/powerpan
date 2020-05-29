class PanResponse {
   [PSCustomObject] $Response
   # Parent PanDevice / Source of response
   [PanDevice] $ParentDevice

   # Default Constructor
   PanResponse() {
   }
   # Constructor accepting...
   PanResponse([PSCustomObject] $Response, [PanDevice] $ParentDevice) {
      $this.Response = $Response
      $this.ParentDevice = $ParentDevice
   }
}