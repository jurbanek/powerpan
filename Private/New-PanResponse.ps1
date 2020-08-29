function New-PanResponse{
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
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='Invoke-WebRequest WebResponseObject')]
      [Microsoft.PowerShell.Commands.WebResponseObject] $WebResponse,
      [parameter(
         HelpMessage='Optional ParentDevice. Internal use only')]
      [PanDevice] $Device
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug $($MyInvocation.MyCommand.Name + ': ')

   $PanResponse = [PanResponse]::new()
   # Populate with WebResponseObject properties (see PanResponse class for more info)
   $PanResponse.WRStatus = $WebResponse.StatusCode
   $PanResponse.WRStatusDescription = $WebResponse.StatusDescription
   $PanResponse.WRHeaders = $WebResponse.Headers
   $PanResponse.WRContent = $WebResponse.Content
   $PanResponse.WRRawContent = $WebResponse.RawContent
   if($PSBoundParameters['Device']) {
      $PanResponse.Device = $PSBoundParameters['Device']
   }

   if($WebResponse.Headers.'Content-Type' -Match 'application\/xml') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': Content-Type: application/xml')

      # Turn the XML body into an XML object
      $XmlContentObj = [xml]$WebResponse.Content
      # Populate with XML body details
      $PanResponse.Status = $XmlContentObj.response.status
      $PanResponse.Code = $XmlContentObj.response.code
      $PanResponse.Message = $XmlContentObj.response.msg
      $PanResponse.Result = $XmlContentObj.response.result
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
