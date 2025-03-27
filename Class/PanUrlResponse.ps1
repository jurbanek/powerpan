class PanUrlResponse {
   # URL being resolved
   [String] $Url
   # NGFW management plane [multi]category verdict
   [String[]] $BaseDbCat
   # PanDb (cloud) [multi]category verdict
   [String[]] $CloudDbCat
   # PanDevice by which verdicts were obtained
   [PanDevice] $Device

   # Default Constructor
   PanUrlResponse() {
   }

   # Constructor accepting...
   PanUrlResponse([String] $Url, [String[]] $BaseDbCat, [String[]] $CloudDbCat, [PanDevice] $Device){
      $this.Url = $Url
      $this.BaseDbCat = $BaseDbCat
      $this.CloudDbCat = $CloudDbCat
      $this.Device = $Device
   }
}
