class PanResponse {
   <#
   Decision to include $WRContent... properties in this class came through inconsistencies in the PAN-OS XML-API
   which necessitated the need to get at more raw response data.
   In one example, submitting an operational command via API:
      <request><license><fetch><auth-code>1234-valid-authcode-needed</auth-code></fetch></license></request>
   the API does *not* return valid XML, but *does* set the Content-Type: application/xml and returns the raw string:
      VM Device License installed. Restarting pan services.
   Running this through the XML constructors (based on Content-Type: application/xml) produces errors. Code/cmdlets performing this
   admittedly obscure request operation can at least access and test for response using $WrStatus and $WrContent.
   There will no doubt be other inconsistencies and examples in the future where untouched responses are desirable.
   #>

   # WebRequest/HTTP Status - comes directly from WebRequestObject
   [Int] $WRStatus
   # WebRequest/HTTP Status Description - comes directly from WebRequestObject
   [String] $WRStatusDescription
   # WebRequest/HTTP Headers - comes directly from WebRequestObject. The *headers*
   [Object] $WRHeaders
   # WebRequest/HTTP Content - comes directly from WebRequestObject. The raw content *body*
   [String] $WRContent
   # WebRequest/HTTP RawContent - comes directly from WebRequestObject. The raw content *headers* AND *body*
   [String] $WRRawContent

   # PAN API response body status, examples "success" or "error"
   [String] $Status
   # PAN API response body "code", used to further describe successes and errors
   [Int] $Code
   # PAN API response body "message", commonly populated during errors
   [String] $Message
   # PAN API response body "result" -- the "goods", commonly populated during successes
   [Object] $Result
   # Parent PanDevice / Source of response
   [PanDevice] $Device

   # Default Constructor
   PanResponse() {
   }
}
