function Invoke-PanXApi {
<#
.SYNOPSIS
Abstracts PAN-OS XML API core modes (actions)
.DESCRIPTION
-Keygen is for generating API key (don't use for normal operations, use New-PanDevice)

-Version is an easy way to verify API access is functioning

-Config -Show retrieves ACTIVE configuration.
-Config -Show only works when provided XPath specifies single node.
-Config -Show can use relative XPath.

-Config -Get retrieves CANDIDATE, uncommitted configuration.
-Config -Get works with single and multiple nodes.
-Config -Get requires absolute XPath.

-Config -Set adds, updates, or merges configuration nodes. -Config -Set actions are non-destructive and are only additive.
-Config -Edit replaces configuration nodes. -Config -Edit actions can be destructive.

-Import -Category "certificate" is for uploading certificates WITHOUT private key (processes just the certificate)
-Import -Category "keypair" is for uploading certificates WITH private key (processes both certificate and private key)
   -File is the path or FileInfo object to the supported (PKCS12, Base64 encoded PEM) certificate on local disk
   -CertName parameter is what is used for PAN-OS certificate name, the certificate filename on local disk is ignored
      -Periods (.) are ignored/removed by PAN-OS. Avoid them in CertName
   -CertPassphrase is used when importing the private key
   -CertVsys is optional. If omitted, the API places the certificate in shared
.NOTES
.INPUTS
PanDevice[]
You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanResponse
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Keygen
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Version
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Op -Cmd "<show><system><info></info></system></show>"
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Commit
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Config -Get -XPath "/config/xpath"
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Config -Set -XPath "/config/xpath" -Element "<outer><inner>value</inner></outer>"
.EXAMPLE
PS> Invoke-PanXApi -Device $Device -Uid -Cmd "<uid-message>...</uid-message>"
.EXAMPLE
Import and process the certificate and private key within, note the -Category keypair
PS> Invoke-PanXApi -Device $Device -Import -Category keypair -File "C:\path\to\cert.p12" -CertName "gp-portal-acme-com" -CertPassphrase "acme1234"

Import and process just the certificate, ignoring the private key, note the -Category certificate. The -CertPassphrase is ignored by API and is not required.
PS> Invoke-PanXApi -Device $Device -Import -Category certificate -File "C:\path\to\cert.p12" -CertName "gp-portal-acme-com" -CertPassphrase "acme1234"
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='None')]
   param(
      # $Device required in all parameter sets.
      [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,HelpMessage='PanDevice against which XML-API will be invoked.')]
      [PanDevice[]] $Device,
      # Begin Keygen parameter set
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Keygen',HelpMessage='Type: keygen')]
      [Switch] $Keygen,
      # Begin Version parameter set
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Version',HelpMessage='Type: version')]
      [Switch] $Version,
      # Begin Op and Uid parameter sets
      [parameter(Mandatory=$true, Position=1,ParameterSetName='Op',HelpMessage='Type: operational commands')]
      [Switch] $Op,
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Uid',HelpMessage='Type: user-id commands')]
      [Switch] $Uid,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Op',HelpMessage='XML formatted operational command')]
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Uid',HelpMessage='XML formatted user-id payload')]
      [String] $Cmd,
      # Begin Commit parameter set
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Commit',HelpMessage='Type: commit commands')]
      [Switch] $Commit,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Commit',HelpMessage='Force commit switch parameter')]
      [Switch] $Force,
      # Begin Config-Set and Config-Get parameter sets
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Get',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Show',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Set',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Edit',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Delete',HelpMessage='Type: config ')]
      [Switch] $Config,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Get',HelpMessage='Retrieve candidate configuration')]
      [Switch] $Get,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Show',HelpMessage='Retrieve active configuration')]
      [Switch] $Show,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Set',HelpMessage='Add or create a new object')]
      [Switch] $Set,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Edit',HelpMessage='Replace existing object (or hierarchy)')]
      [Switch] $Edit,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Delete',HelpMessage='Delete an object')]
      [Switch] $Delete,
      [parameter(Mandatory=$true,ParameterSetName='Config-Get',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Show',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Set',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Edit',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Delete',HelpMessage='Config XPath')]
      [String] $XPath,
      [parameter(ParameterSetName='Config-Get',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-Show',HelpMessage='Config Element')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Set',HelpMessage='Config Element')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Edit',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-Delete',HelpMessage='Config Element')]
      [String] $Element,
      # Begin Import parameter set
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Import-Default',HelpMessage='Type: import')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Import-Cert-Key',HelpMessage='Type: import')]
      [Switch] $Import,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Import-Default',HelpMessage='File path to upload')]
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Import-Cert-Key',HelpMessage='File path to upload')]
      [System.IO.FileInfo] $File,
      [parameter(Mandatory=$true,Position=3,ParameterSetName='Import-Default',HelpMessage='Import category: certificate, software, etc.')]
      [parameter(Mandatory=$true,Position=3,ParameterSetName='Import-Cert-Key',HelpMessage='Import category: certificate, software, etc.')]
      [ValidateSet(
         # Software
         'software',
         # Content
         'anti-virus','content','url-database','signed-url-database',
         # Licenses
         'license',
         # Configuration
         'configuration',
         # Certificates/Keys
         'certificate','high-availability-key','keypair',
         # Response Pages
         'application-block-page','captive-portal-text','file-block-continue-page','file-block-page','global-protect-portal-custom-help-page',
         'global-protect-portal-custom-login-page','global-protect-portal-custom-welcome-page','ssl-cert-status-page','ssl-optout-text',
         'url-block-page','url-coach-text','virus-block-page',
         # Clients
         'global-protect-client',
         # Custom Logo
         'custom-logo'
      )]
      [String] $Category,
      [parameter(Mandatory=$true,ParameterSetName='Import-Cert-Key',HelpMessage='Certificate friendly name')]
      [String] $CertName,
      [parameter(Mandatory=$true,ParameterSetName='Import-Cert-Key',HelpMessage='Certificate format: pkcs12, pem')]
      [ValidateSet('pkcs12','pem')]
      [String] $CertFormat,
      [parameter(ParameterSetName='Import-Cert-Key',HelpMessage='Required when including the certificate private key')]
      [String] $CertPassphrase,
      [parameter(ParameterSetName='Import-Cert-Key',HelpMessage='Optional. If empty, defaults to shared')]
      [String] $CertVsys
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         # API type=keygen
         if ($PSCmdlet.ParameterSetName -eq 'Keygen') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=keygen')
            $PanApiType = 'keygen'
            $InvokeParams = @{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = @{
                  'type' = $PanApiType;
                  'user' = $DeviceCur.Credential.UserName;
                  'password' = $DeviceCur.Credential.GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=keygen

         # API type=version
         elseif ($PSCmdlet.ParameterSetName -eq 'Version') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=version')
            $PanApiType = 'version'
            $InvokeParams = @{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = @{
                  'type' = $PanApiType;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=version

         # API type=op
         elseif ($PSCmdlet.ParameterSetName -eq 'Op') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=op')
            $PanApiType = 'op'
            $PanApiCmd = $PSBoundParameters.Cmd
            $InvokeParams = @{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = @{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=op

         # API type=user-id
         elseif ($PSCmdlet.ParameterSetName -eq 'Uid') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=user-id')
            $PanApiType = 'user-id'
            $PanApiCmd = $PSBoundParameters.Cmd
            $InvokeParams = @{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ); # Uri sub-expression
               'Body' = @{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=user-id

         # API type=commit
         elseif ($PSCmdlet.ParameterSetName -eq 'Commit') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=commit')
            $PanApiType = 'commit'
            if ($Force.IsPresent) {
               $PanApiCmd = '<commit><force></force></commit'
            }
            else {
               $PanApiCmd = '<commit></commit>'
            }
            $InvokeParams = @{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = @{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=commit

         # API type=config
         elseif ($PSCmdlet.ParameterSetName -like 'Config-*') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=config')
            $PanApiType = 'config'
            if ($PSBoundParameters.Get.IsPresent) {
               $PanApiAction = 'get'
            }
            elseif ($PSBoundParameters.Show.IsPresent) {
               $PanApiAction = 'show'
            }
            elseif ($PSBoundParameters.Set.IsPresent) {
               $PanApiAction = 'set'
            }
            elseif ($PSBoundParameters.Edit.IsPresent) {
               $PanApiAction = 'edit'
            }
            elseif ($PSBoundParameters.Delete.IsPresent) {
               $PanApiAction = 'delete'
            }
            Write-Debug ($MyInvocation.MyCommand.Name + ": action=$PanApiAction")

            $PanApiXPath = $PSBoundParameters.XPath
            $PanApiElement = $PSBoundParameters.Element

            # Element is optional for several actions. If present, include in the Uri.
            if (-not [String]::IsNullOrEmpty($PanApiElement)) {
               $InvokeParams = @{
                  'Method' = 'Post';
                  'Uri' = $('{0}://{1}:{2}/api' -f `
                     $DeviceCur.Protocol,
                     $DeviceCur.Name,
                     $DeviceCur.Port
                  ) # Uri sub-expression
                  'Body' = @{
                     'type' = $PanApiType;
                     'action' = $PanApiAction;
                     'xpath' = $PanApiXPath;
                     'element' = $PanApiElement;
                     'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
                  } # Body hash table
               } # InvokeParams hash table
            }
            # Else, do not include element in the Uri
            else {
               $InvokeParams = @{
                  'Method' = 'Post';
                  'Uri' = $('{0}://{1}:{2}/api' -f `
                     $DeviceCur.Protocol,
                     $DeviceCur.Name,
                     $DeviceCur.Port
                  ) # Uri sub-expression
                  'Body' = @{
                     'type' = $PanApiType;
                     'action' = $PanApiAction;
                     'xpath' = $PanApiXPath;
                     'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
                  } # Body hash table
               } # InvokeParams hash table
            }
         } # End API type=config

         # API type=import
         elseif ($PSCmdlet.ParameterSetName -like 'Import-*') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': type=Import')
            $PanApiType = 'import'
            Write-Debug ($MyInvocation.MyCommand.Name + ': category=' + $Category)

            if($PSCmdlet.ParameterSetName -eq 'Import-Default') {
               Write-Debug ($MyInvocation.MyCommand.Name + ": type=Import (Default)")
               $InvokeParams = @{
                  'Method' = 'Post';
                  'Uri' = $('{0}://{1}:{2}/api?key={3}&type={4}&category={5}' -f `
                     $DeviceCur.Protocol,
                     $DeviceCur.Name,
                     $DeviceCur.Port,
                     $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password,
                     $PanApiType,
                     $PSBoundParameters.Category
                  ); # Uri sub-expression
               } # InvokeParams hash table

               # Submit file to NewMultipartFormData for generating Content-Type header and multipart/form-data encoded body
               # Make sure to use -UnquotedBoundary for PAN-OS XML API limitation/workaround. See NewMultipartFormData
               $MPFData = NewMultipartFormData -File $PSBoundParameters.File -UnquotedBoundary
               # Add ContentType header to InvokeParams
               $InvokeParams.Add('ContentType', $MPFData.Header.ContentType)
               $InvokeParams.Add('Body', $MPFData.Body)

            } # end ParameterSetName Import-Default

            elseif($PSCmdlet.ParameterSetName -eq 'Import-Cert-Key') {
               Write-Debug ($MyInvocation.MyCommand.Name + ": type=Import (Cert-Key)")
               $InvokeParams = @{
                  'Method' = 'Post';
                  'Uri' = $('{0}://{1}:{2}/api?key={3}&type={4}&category={5}&certificate-name={6}&format={7}' -f `
                     $DeviceCur.Protocol,
                     $DeviceCur.Name,
                     $DeviceCur.Port,
                     $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password,
                     $PanApiType,
                     $PSBoundParameters.Category,
                     $PSBoundParameters.CertName,
                     $PSBoundParameters.CertFormat
                  ); # Uri sub-expression
               } # InvokeParams hash table

               # Submit file to NewMultipartFormData for generating Content-Type header and multipart/form-data encoded body
               # Make sure to use -UnquotedBoundary for PAN-OS XML API limitation/workaround. See NewMultipartFormData
               $MPFData = NewMultipartFormData -File $PSBoundParameters.File -UnquotedBoundary
               # Add ContentType header to InvokeParams
               $InvokeParams.Add('ContentType', $MPFData.Header.ContentType)
               $InvokeParams.Add('Body', $MPFData.Body)

               # If Certificate passphrase is specified, include it in Uri
               if($PSBoundParameters.ContainsKey('CertPassphrase')){
                  $InvokeParams.Uri += '&passphrase={0}' -f $CertPassphrase
               }
               # If Certificate vsys is specified, include it in Uri. If omitted, API defaults to shared
               if($PSBoundParameters.ContainsKey('CertVsys')){
                  $InvokeParams.Uri += '&vsys={0}' -f $CertVsys
               }
            } # end ParameterSetName Import-Cert-Key
         } # End API type=import

         if($PSCmdlet.ShouldProcess($DeviceCur.Name,'PAN-OS XML-API call')) {
            # Invoke-WebRequest is preferred over Invoke-RestMethod. In PowerShell 5.1, Invoke-RestMethod does not make HTTP response
            # *headers* available. Remedied in PowerShell 6+ with -ResponseHeadersVariable, but PowerShell 5.1 compatibility is needed for now
            # PowerShell 7+ x.509 Validation Policy can be set directly on Invoke-WebRequest
            if($PSVersionTable.PSVersion.Major -ge 7) {
               if ($DeviceCur.ValidateCertificate) {
                  $Response = NewPanResponse -WebResponse (Invoke-WebRequest @InvokeParams -UseBasicParsing) -Device $DeviceCur
               }
               else {
                  # Note the addition of -SkipCertificateCheck, supported in PowerShell 6+
                  $Response = NewPanResponse -WebResponse (Invoke-WebRequest @InvokeParams -UseBasicParsing -SkipCertificateCheck) -Device $DeviceCur
               }
            }
            # PowerShell 5 x.509 Validation Policy set using specific helper cmdlet
            else {
               if ($DeviceCur.ValidateCertificate) {
                  SetX509CertificateValidation -Validate
               }
               else {
                  SetX509CertificateValidation -NoValidate
               }
               $Response = NewPanResponse -WebResponse (Invoke-WebRequest @InvokeParams -UseBasicParsing) -Device $DeviceCur
            }
            Write-Debug ($MyInvocation.MyCommand.Name + (': Status: {0} Code: {1}' -f $Response.Status, $Response.Code))
            return $Response
         }
      } # Process block outermost foreach
   } # Process block

   End {
   } # End block
} # Function
