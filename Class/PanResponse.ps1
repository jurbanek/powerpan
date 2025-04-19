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

   # Constructor
   PanResponse([Microsoft.PowerShell.Commands.WebResponseObject] $WebResponse, [PanDevice] $Device) {
      $this.WRStatus = $WebResponse.StatusCode
      $this.WRStatusDescription = $WebResponse.StatusDescription
      $this.WRHeaders = $WebResponse.Headers
      $this.WRContent = $WebResponse.Content
      $this.WRRawContent = $WebResponse.RawContent
      
      $this.Device = $Device
      
      if($WebResponse.Headers.'Content-Type' -Match 'application\/xml') {
         Write-Debug $($MyInvocation.MyCommand.Name + ': Content-Type: application/xml')
         # Turn the XML body into an XmlDocument object with XmlDocument doing the parse heavy lifting
         # Interesting note, [xml] is the PowerShell type accelerator (alias) for [System.Xml.XmlDocument]. Let's be verbose.
         $XmlDoc = [System.Xml.XmlDocument]$WebResponse.Content
         # Populate PanResponse with XML body details
         # Status
         $this.Status = $XmlDoc.response.status
         # Code
         $this.Code = $XmlDoc.response.code
         # Message
         # Variety A: msg contains no other elements
         # Example: Commits with no pending changes return <msg>There are no changes to commit.</msg> which is mapped to a string.
         if($XmlDoc.response.msg -is [String]) {
            $this.Message = $XmlDoc.response.msg
         }
         # Variety B: msg contains other nested elements
         # Example: ??? <msg><line>Some Message</line></msg>
         elseif($XmlDoc.response.msg -is [System.Xml.XmlElement]) {
            $this.Message = $XmlDoc.response.msg.InnerText
         }
         # Result
         $this.Result = $XmlDoc.response.result
      }
      elseif ($WebResponse.Headers.'Content-Type' -Match 'application\/json') {
         Write-Debug $($MyInvocation.MyCommand.Name + ': Content-Type: application/json')
   
         # Turn the JSON body into a JSON object
         $JsonContentObj = ConvertFrom-Json -InputObject $WebResponse.Content
         # Populate with JSON body details
         $this.Status = $JsonContentObj.response.status
         $this.Code = $JsonContentObj.response.code
         $this.Message = $JsonContentObj.response.msg
         $this.Result = $JsonContentObj.response.result
      }
   }
}
