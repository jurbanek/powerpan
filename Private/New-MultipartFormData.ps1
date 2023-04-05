<#
   .SYNOPSIS
   Creates multipart/form-data Content-Type Header and Body
   .DESCRIPTION
   Built primarily to workaround limitations in PAN-OS XML-API with quoted boundary in OUTER Content-Type header.

   Returns a PSCustomObject with Header and Body properties which can be used as input to Invoke-WebRequest and
   .NOTES
   In PowerShell 7+, Invoke-WebRequest -Form, Invoke-RestMethod -Form DO quote the boundary. Not an option.
   .NET System.Net.Http.MultipartFormDataContent also DOES quote the boundary. Not an option.
   Needed something else
   Issue below captures the challenge nicely
   https://github.com/PowerShell/PowerShell/issues/9241
   Some additional content
   https://www.reddit.com/r/paloaltonetworks/comments/l47a4h/upload_certificate_via_api/
   https://stackoverflow.com/questions/25075010/upload-multiple-files-from-powershell-script
   https://stackoverflow.com/questions/22491129/how-to-send-multipart-form-data-with-powershell-invoke-restmethod
   .INPUTS
   None
   .OUTPUTS
   PSCustomObject
   .EXAMPLE
   PS> $Data = New-MultipartFormData -File "C:\path\to\file.p12" -UnquotedBoundary
   PS> Invoke-WebRequest -Method Post -Uri 'https://...' -ContentType $Data.Header.ContentType -Body $Data.Body ...

#>
function New-MultipartFormData {
   [CmdletBinding()]
   param(
      [parameter(Mandatory=$true,Position=0,HelpMessage='File(s) to be rendered')]
      [System.IO.FileInfo[]] $File,
      [parameter(HelpMessage='Specified boundary. Optional')]
      [String] $Boundary,
      [parameter(HelpMessage='Special processing for unquoted boundary definition')]
      [Switch] $UnquotedBoundary
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters.Debug) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   # Structure of the returned object
   $MPFData = [PSCustomObject]@{
      'Header' = [PSCustomObject]@{
         'ContentType' = [String]$null
      };
      'Body' = [String]$null
   }

   if($PSBoundParameters.ContainsKey('Boundary')) {
      $Boundary = $PSBoundParameters.Boundary
   }
   else {
      $Boundary = [System.Guid]::NewGuid().ToString()
   }
   Write-Debug ($MyInvocation.MyCommand.Name + ": Using boundary $Boundary")

   # Newline to be used
   $LF = "`r`n"

   # OUTER HTTP Content-Type header (Invoke-WebRequest ContentType parameter, no hyphen)
   # Implementation Note: PAN-OS XML-API does NOT support a quoted boundary on the OUTER Content-Type where the boundary is first defined
   # Works: Content-Type: multipart/form-data; boundary=asdf1234
   # Fails: Content-Type: multipart/form-data; boundary="asdf1234"
   if($PSBoundParameters.UnquotedBoundary.IsPresent) {
      $MPFData.Header.ContentType = "multipart/form-data; boundary=$Boundary"
      Write-Debug ($MyInvocation.MyCommand.Name + ": Unquoted boundary: $($MPFData.Header.ContentType)")
   }
   else {
      $MPFData.Header.ContentType = "multipart/form-data; boundary=`"$Boundary`""
      Write-Debug ($MyInvocation.MyCommand.Name + ": Quoted boundary: $($MPFData.Header.ContentType)")
   }

   # Loop through one or more files
   foreach($FileCur in $PSBoundParameters.File) {
      if(Test-Path -Path $FileCur.FullName -Type Leaf) {
         # Body content. In the body, the boundary is always NOT quoted. No special changes for PAN-OS here
         $MPFData.Body += "--$Boundary$LF"
         $MPFData.Body += "Content-Disposition: form-data; name=`"file`"; filename=`"$($FileCur.Name)`"$LF"
         # Determine MIME type for INNER Content-Type
         $MimeMap = @{
            'pem' = 'application/x-pem-file';
            'p12' = 'application/x-pkcs12';
            'pfx' = 'application/x-pkcs12'
         }
         if($MimeMap.ContainsKey($FileCur.Extension.TrimStart('.'))) {
            $MPFData.Body += 'Content-Type: ' + $MimeMap.$($FileCur.Extension.TrimStart('.')) + "$LF"
         }
         else {
            $MPFData.Body += "Content-Type: application/octet-stream$LF"
         }

         # Required blank line between INNER content header and inner content
         $MPFData.Body += "$LF"

         # File Content
         # Read file as byte array
         $FileCurBin = [System.IO.File]::ReadAllBytes($FileCur.FullName)
         # Convert to string without changing and add to body
         $MPFData.Body += $([System.Text.Encoding]::GetEncoding('iso-8859-1')).GetString($FileCurBin) + "$LF"
      } # end if(Test-Path)
      else {
         Write-Error -Message "$($FileCur.FullName) not found"
      }
   }

   # End INNER content boundary with final two dashes "--" after boundary value, unquoted per standard. No special changes for PAN-OS
   $MPFData.Body += "--$Boundary--$LF"

   # Return $MPFData, including Header(s) and Body
   $MPFData
}
