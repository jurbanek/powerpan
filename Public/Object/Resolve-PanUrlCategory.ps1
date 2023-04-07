function Resolve-PanUrlCategory {
   <#
   .SYNOPSIS
   Resolve/retrieve PanDB URL categorization for a URL.
   .DESCRIPTION
   Resolve/retrieve PanDB URL categorization for a URL. Resolution is provided by PAN-OS.
   .NOTES
   Requires the URL Filtering subscription (license) on the firewall for PanDB (cloud) lookups. Without the URL Filtering subscription
   the firewall returns "cloud-unavailable" for PanDB (cloud) lookups.
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanUrlResponse
   .EXAMPLE
   PS> Get-PanDevice -Name "10.1.1.1" | Resolve-PanUrlCategory -Url "duckduckgo.com","google.com"
   Firewall 10.1.1.1 will resolve duckduckgo.com and google.com to their corresponding URL categories.
   .EXAMPLE
   PS> Get-PanDevice -Name "10.1.1.1","192.168.12.1" | Resolve-PanUrlCategory -Url (Import-Csv -Path "Book1.csv" -Header "url").url
   Both firewalls 10.1.1.1 and 192.168.12.1 will resolve the list of URL's in a CSV file their corresponding URL categories.
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='URL(s) to resolve')]
      [String[]] $Url,
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which PanDB will be queried.')]
      [PanDevice[]] $Device
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb
   } # Begin Block

   Process {
      foreach($DeviceCur in $PSBoundParameters['Device']) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

         foreach($UrlCur in $PSBoundParameters['Url']) {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Url: ' + $UrlCur)
            $Cmd = '<test><url>{0}</url></test>' -f $UrlCur
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)

            $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.Status)
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.Message)

            if($PanResponse.Status -eq 'success') {
               # Two lines of text returned, separated by newline
               $SplitResult = $PanResponse.Result.split("`n")

               # First [0] is the Base Db (management-plane), grab a named capture group 'cat'
               if( $SplitResult[0] -match "$UrlCur (?<cat>[-\w\s]+) \(Base db\)" ) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ': Base Db: ' + $Matches['cat'])
                  $BaseDbCat = $Matches['cat']
               }

               # Second [1] is the Cloud Db (PanDb), grab a named capture group 'cat'
               if( $SplitResult[1] -match "$UrlCur (?<cat>[-\w\s]+) \(Cloud db\)" ) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ': Cloud Db: ' + $Matches['cat'])
                  $CloudDbCat = $Matches['cat']
               }

               # Return a PanUrlResponse
               [PanUrlResponse]::new($UrlCur, @($BaseDbCat.split()), @($CloudDbCat.split()), $DeviceCur)
            }
         } # foreach Url
      } # foreach Device
   } # Process block
   End {
   } # End block
} # Function
