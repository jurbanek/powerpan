function Invoke-PanXApi {
<#
.SYNOPSIS
Abstracts PAN-OS XML API core modes (actions)
.DESCRIPTION
-Keygen is for generating API key (don't use for normal operations, use New-PanDevice instead)

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
Invoke-PanXApi -Device $Device -Keygen
.EXAMPLE
Invoke-PanXApi -Device $Device -Version
.EXAMPLE
Invoke-PanXApi -Device $Device -Op -Cmd "<show><system><info></info></system></show>"
.EXAMPLE
Invoke-PanXApi -Device $Device -Commit
.EXAMPLE
Invoke-PanXApi -Device $Device -Config -Get -XPath "/config/xpath"
.EXAMPLE
Invoke-PanXApi -Device $Device -Config -Set -XPath "/config/xpath" -Element "<outer><inner>value</inner></outer>"
.EXAMPLE
Invoke-PanXApi -Device $Device -Uid -Cmd "<uid-message>...</uid-message>"
.EXAMPLE
Import and process the certificate and private key within, note the -Category keypair

Invoke-PanXApi -Device $Device -Import -Category keypair -File "C:\path\to\cert.p12" -CertName "gp-portal-acme-com" -CertPassphrase "acme1234"

Import and process just the certificate, ignoring the private key, note the -Category certificate. The -CertPassphrase is ignored by API and is not required.

Invoke-PanXApi -Device $Device -Import -Category certificate -File "C:\path\to\cert.p12" -CertName "gp-portal-acme-com" -CertPassphrase "acme1234"
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
      # Begin Commit parameter set
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Commit',HelpMessage='Type: commit commands')]
      [Switch] $Commit,
      [parameter(ParameterSetName='Commit',HelpMessage='Only used on partial commits, set to "partial".')]
      [String] $Action,
      # Cmd used by numerous parameter sets
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Op',HelpMessage='XML formatted operational command')]
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Uid',HelpMessage='XML formatted user-id payload')]
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Commit',HelpMessage='XML formatted commit command')]
      [String] $Cmd,
      # Begin Config-* parameter sets
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Get',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Show',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Set',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Edit',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Delete',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Rename',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Move',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-MultiMove',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Clone',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-MultiClone',HelpMessage='Type: config ')]
      [parameter(Mandatory=$true,Position=1,ParameterSetName='Config-Complete',HelpMessage='Type: config ')]
      [Switch] $Config,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Get',HelpMessage='Retrieve candidate configuration')]
      [Switch] $Get,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Show',HelpMessage='Retrieve active configuration')]
      [Switch] $Show,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Set',HelpMessage='Add or create (merge)')]
      [Switch] $Set,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Edit',HelpMessage='Replace existing configuration')]
      [Switch] $Edit,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Delete',HelpMessage='Delete')]
      [Switch] $Delete,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Rename',HelpMessage='Rename')]
      [Switch] $Rename,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Move',HelpMessage='Move')]
      [Switch] $Move,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-MultiMove',HelpMessage='MultiMove')]
      [Switch] $MultiMove,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Clone',HelpMessage='Clone')]
      [Switch] $Clone,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-MultiClone',HelpMessage='MultiClone')]
      [Switch] $MultiClone,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Complete',HelpMessage='Retrieve auto-complete options')]
      [Switch] $Complete,
      [parameter(Mandatory=$true,ParameterSetName='Config-Get',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Show',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Set',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Edit',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Delete',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Rename',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Move',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-MultiMove',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Clone',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-MultiClone',HelpMessage='Config XPath')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Complete',HelpMessage='Config XPath')]
      [String] $XPath,
      [parameter(ParameterSetName='Config-Get',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-Show',HelpMessage='Config Element')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Set',HelpMessage='Config Element')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Edit',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-Delete',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-MultiMove',HelpMessage='Config Element')]
      [parameter(ParameterSetName='Config-MultiClone',HelpMessage='Config Element')]
      [String] $Element,
      [parameter(Mandatory=$true,ParameterSetName='Config-Rename',HelpMessage='Config NewName')]
      [parameter(Mandatory=$true,ParameterSetName='Config-Clone',HelpMessage='Config NewName')]
      [String] $NewName,
      [parameter(Mandatory=$true,ParameterSetName='Config-Move',HelpMessage='Config Where: after, before, top, bottom')]
      [ValidateSet('after','before','top','bottom')]
      [String] $Where,
      [parameter(ParameterSetName='Config-Move',HelpMessage='Config Dst (required with -Where after or -Where before)')]
      [String] $Dst,
      [parameter(Mandatory=$true,ParameterSetName='Config-Clone',HelpMessage='Config From')]
      [String] $From,
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
      [String] $CertVsys,
      # TimeoutSec valid in all ParameterSets with default value
      [parameter(HelpMessage='Max duration of a connection from setup through teardown')]
      [Int] $TimeoutSec = 15
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
   } # Begin block

   Process {
      foreach($DeviceCur in $PSBoundParameters.Device) {
         # API type=keygen
         if ($PSCmdlet.ParameterSetName -eq 'Keygen') {
            Write-Verbose ('{0}: Device: {1} type=keygen' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            $PanApiType = 'keygen'
            $InvokeParams = [ordered]@{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = [ordered]@{
                  'type' = $PanApiType;
                  'user' = $DeviceCur.Credential.UserName;
                  'password' = $DeviceCur.Credential.GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=keygen

         # API type=version
         elseif ($PSCmdlet.ParameterSetName -eq 'Version') {
            Write-Verbose ('{0}: Device: {1} type=version' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            $PanApiType = 'version'
            $InvokeParams = [ordered]@{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = [ordered]@{
                  'type' = $PanApiType;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=version

         # API type=op
         elseif ($PSCmdlet.ParameterSetName -eq 'Op') {
            Write-Verbose ('{0}: Device: {1} type=op' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            $PanApiType = 'op'
            $PanApiCmd = $PSBoundParameters.Cmd
            $InvokeParams = [ordered]@{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = [ordered]@{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=op

         # API type=user-id
         elseif ($PSCmdlet.ParameterSetName -eq 'Uid') {
            Write-Verbose ('{0}: Device: {1} type=user-id' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            $PanApiType = 'user-id'
            $PanApiCmd = $PSBoundParameters.Cmd
            $InvokeParams = [ordered]@{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ); # Uri sub-expression
               'Body' = [ordered]@{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
         } # End API type=user-id

         # API type=commit
         elseif ($PSCmdlet.ParameterSetName -eq 'Commit') {
            Write-Verbose ('{0}: Device: {1} type=commit' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
            $PanApiType = 'commit'
            $PanApiCmd = $PSBoundParameters.Cmd
            $InvokeParams = [ordered]@{
               'Method' = 'Post';
               'Uri' = $('{0}://{1}:{2}/api' -f `
                  $DeviceCur.Protocol,
                  $DeviceCur.Name,
                  $DeviceCur.Port
               ) # Uri sub-expression
               'Body' = [ordered]@{
                  'type' = $PanApiType;
                  'cmd' = $PanApiCmd;
                  'key' = $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password
               } # Body hash table
            } # InvokeParams hash table
            # Add optional "action", if present.
            if($PSBoundParameters.Action) {
               $InvokeParams.Body.Add('action', $PSBoundParameters.Action)
            }
         } # End API type=commit

         # API type=config
         elseif ($PSCmdlet.ParameterSetName -like 'Config-*') {
            $PanApiType = 'config'
            if ($PSBoundParameters.Get.IsPresent) { $PanApiAction = 'get' }
            elseif ($PSBoundParameters.Show.IsPresent) { $PanApiAction = 'show' }
            elseif ($PSBoundParameters.Set.IsPresent) { $PanApiAction = 'set' }
            elseif ($PSBoundParameters.Edit.IsPresent) { $PanApiAction = 'edit' }
            elseif ($PSBoundParameters.Delete.IsPresent) { $PanApiAction = 'delete' }
            elseif ($PSBoundParameters.Rename.IsPresent) { $PanApiAction = 'rename' }
            elseif ($PSBoundParameters.Move.IsPresent) { $PanApiAction = 'move' }
            elseif ($PSBoundParameters.MultiMove.IsPresent) { $PanApiAction = 'multi-move' }
            elseif ($PSBoundParameters.Clone.IsPresent) { $PanApiAction = 'clone' }
            elseif ($PSBoundParameters.MultiClone.IsPresent) { $PanApiAction = 'multi-clone' }
            elseif ($PSBoundParameters.Complete.IsPresent) { $PanApiAction = 'complete' }
            Write-Verbose ('{0}: Device: {1} type=config action={2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$PanApiAction)

            $PanApiXPath = $PSBoundParameters.XPath
            $PanApiElement = $PSBoundParameters.Element
            $PanApiFrom = $PSBoundParameters.From
            $PanApiNewName = $PSBoundParameters.NewName
            $PanApiWhere = $PSBoundParameters.Where
            $PanApiDst = $PSBoundParameters.Dst

            $InvokeParams = [ordered]@{
               'Method' = 'Post'
                  'Uri' = $('{0}://{1}:{2}/api' -f `
                     $DeviceCur.Protocol,
                     $DeviceCur.Name,
                     $DeviceCur.Port
                  )
            }
            $Body = [ordered]@{
               'type' = $PanApiType
               'action' = $PanApiAction
               'xpath' = $PanApiXPath
            }
            if($PanApiElement) { $Body.Add('element', $PanApiElement) }
            if($PanApiFrom) { $Body.Add('from', $PanApiFrom) }
            if($PanApiNewName) { $Body.Add('newname', $PanApiNewName) }
            if($PanApiWhere) { $Body.Add('where', $PanApiWhere) }
            if($PanApiDst) { $Body.Add('dst', $PanApiDst) }
            $Body.Add('key', $(New-Object -TypeName PSCredential -ArgumentList 'user',$DeviceCur.Key).GetNetworkCredential().Password)
            # Add the completed Body
            $InvokeParams.Add('body', $Body)
         } # End API type=config

         # API type=import
         elseif ($PSCmdlet.ParameterSetName -like 'Import-*') {
            Write-Verbose ('{0}: Device: {1} type=import category={2}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$PSBoundParameters.Category)
            $PanApiType = 'import'

            if($PSCmdlet.ParameterSetName -eq 'Import-Default') {
               Write-Verbose ('{0}: Device: {1} type=import (Default)' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
               $InvokeParams = [ordered]@{
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
               Write-Verbose ('{0}: Device: {1} type=import (Cert-Key)' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name)
               $InvokeParams = [ordered]@{
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
                  $InvokeParams.Uri += '&passphrase={0}' -f $PSBoundParameters.CertPassphrase
               }
               # If Certificate vsys is specified, include it in Uri. If omitted, API defaults to shared
               if($PSBoundParameters.ContainsKey('CertVsys')){
                  $InvokeParams.Uri += '&vsys={0}' -f $PSBoundParameters.CertVsys
               }
            } # end ParameterSetName Import-Cert-Key
         } # End API type=import

         if($PSCmdlet.ShouldProcess($DeviceCur.Name,'PAN-OS XML-API call')) {
            # Invoke-WebRequest is preferred over Invoke-RestMethod. In PowerShell 5.1, Invoke-RestMethod does not make HTTP response
            # *headers* available. Remedied in PowerShell 6+ with -ResponseHeadersVariable, but PowerShell 5.1 compatibility is needed for now
            # PowerShell 7+ x.509 Validation Policy can be set directly on Invoke-WebRequest
            if($PSVersionTable.PSVersion.Major -ge 7) {
               # Note the addition of -SkipCertificateCheck, supported in PowerShell 6+
               $R = [PanResponse]::new((Invoke-WebRequest @InvokeParams -UseBasicParsing -SkipCertificateCheck:(-not $DeviceCur.ValidateCertificate) -TimeoutSec $TimeoutSec), $DeviceCur )
            }
            # PowerShell 5 x.509 Validation Policy set using specific helper cmdlet
            else {
               if ($DeviceCur.ValidateCertificate) {
                  SetX509CertificateValidation -Validate
               }
               else {
                  SetX509CertificateValidation -NoValidate
               }
               $R = [PanResponse]::new((Invoke-WebRequest @InvokeParams -UseBasicParsing -TimeoutSec $TimeoutSec), $DeviceCur)
            }
            Write-Verbose ('{0}: Device: {1} Status: {2} Code: {3} Message: {4}' -f $MyInvocation.MyCommand.Name,$DeviceCur.Name,$R.Status,$R.Code,$R.Message)
            return $R
         }
      } # Process block outermost foreach
   } # Process block

   End {
   } # End block
} # Function
