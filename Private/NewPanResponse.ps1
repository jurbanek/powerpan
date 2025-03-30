function NewPanResponse{
<#
.SYNOPSIS
Returns a PanResponse object. Internal helper cmdlet.
.DESCRIPTION
Returns a PanResponse object. Internal helper cmdlet.
.NOTES
.INPUTS
None
.OUTPUTS
PanResponse
.EXAMPLE
#>
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,Position=0,HelpMessage='Invoke-WebRequest WebResponseObject')]
      [Microsoft.PowerShell.Commands.WebResponseObject] $WebResponse,
      [parameter(HelpMessage='Optional ParentDevice. Internal use only')]
      [PanDevice] $Device
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   $PanResponse = [PanResponse]::new()
   # Populate with WebResponseObject properties (see PanResponse class for more info)
   $PanResponse.WRStatus = $WebResponse.StatusCode
   $PanResponse.WRStatusDescription = $WebResponse.StatusDescription
   $PanResponse.WRHeaders = $WebResponse.Headers
   $PanResponse.WRContent = $WebResponse.Content
   $PanResponse.WRRawContent = $WebResponse.RawContent
   if($PSBoundParameters.Device) {
      $PanResponse.Device = $PSBoundParameters.Device
   }

   if($WebResponse.Headers.'Content-Type' -Match 'application\/xml') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': Content-Type: application/xml')

      # Turn the XML body into an XmlDocument object with XmlDocument doing the parse heavy lifting
      # Interesting note, [xml] is the PowerShell type accelerator (alias) for [System.Xml.XmlDocument]. Let's be verbose.
      $XmlDoc = [System.Xml.XmlDocument]$WebResponse.Content
      # Populate PanResponse with XML body details
      # Status
      $PanResponse.Status = $XmlDoc.response.status
      # Code
      $PanResponse.Code = $XmlDoc.response.code
      # Message
      # Variety A: msg contains no other elements
      # Example: Commits with no pending changes return <msg>There are no changes to commit.</msg> which is mapped to a string.
      if($XmlDoc.response.msg -is [String]) {
         $PanResponse.Message = $XmlDoc.response.msg
      }
      # Variety B: msg contains other nested elements
      # Example: ??? <msg><line>Some Message</line></msg>
      elseif($XmlDoc.response.msg -is [System.Xml.XmlElement]) {
         $PanResponse.Message = $XmlDoc.response.msg.InnerText
      }
      # Result
      $PanResponse.Result = $XmlDoc.response.result
   }
   elseif ($WebResponse.Headers.'Content-Type' -Match 'application\/json') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': Content-Type: application/json')

      # Turn the JSON body into a JSON object
      $JsonContentObj = ConvertFrom-Json -InputObject $WebResponse.Content
      # Populate with JSON body details
      $PanResponse.Status = $JsonContentObj.response.status
      $PanResponse.Code = $JsonContentObj.response.code
      $PanResponse.Message = $JsonContentObj.response.msg
      $PanResponse.Result = $JsonContentObj.response.result
   }

   return $PanResponse
}
