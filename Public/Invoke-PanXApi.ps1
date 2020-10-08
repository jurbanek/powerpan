function Invoke-PanXApi {
   <#
   .SYNOPSIS
   .DESCRIPTION
   .NOTES
   Config "show" actions retrieve active configuration.
   Config "get" actions retrieve candidate, uncommitted configuration.

   Config "show" actions only work when provided XPath specifies single node.
   Config "get" actions work with single and multiple nodes.

   Config "show" actions can use relative XPath.
   Config "get" actions require absolute XPath.

   Config "set" is to add, update, or merge configuration nodes. Config "set" actions are non-destructive and are only additive.
   Config "edit" replaces configuration nodes. Config "edit" actions can be destructive.
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
   #>
   [CmdletBinding()]
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
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Get',HelpMessage='Config get mode switch parameter')]
      [Switch] $Get,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Show',HelpMessage='Config show mode switch parameter')]
      [Switch] $Show,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Set',HelpMessage='Config set mode switch parameter')]
      [Switch] $Set,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Edit',HelpMessage='Config edit mode switch parameter')]
      [Switch] $Edit,
      [parameter(Mandatory=$true,Position=2,ParameterSetName='Config-Delete',HelpMessage='Config delete mode switch parameter')]
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
      [String] $Element
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         # Set environment's x.509 Certificate Validation Policy
         if ($DeviceCur.ValidateCertificate) {
            Set-X509CertificateValidation -Validate
         }
         else {
            Set-X509CertificateValidation -NoValidate
         }

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
            $PanApiCmd = $Cmd
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
            $PanApiCmd = $Cmd
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
            if ($Get.IsPresent) {
               $PanApiAction = 'get'
            }
            elseif ($Show.IsPresent) {
               $PanApiAction = 'show'
            }
            elseif ($Set.IsPresent) {
               $PanApiAction = 'set'
            }
            elseif ($Edit.IsPresent) {
               $PanApiAction = 'edit'
            }
            elseif ($Delete.IsPresent) {
               $PanApiAction = 'delete'
            }
            Write-Debug ($MyInvocation.MyCommand.Name + ": action=$PanApiAction")

            $PanApiXPath = $XPath
            $PanApiElement = $Element

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

         # Call PAN-OS XML-API with PowerShell built-in Invoke-WebRequest, include some debug
         # Invoke-WebRequest is preferred over Invoke-RestMethod. In PowerShell 5.1, Invoke-RestMethod does not make HTTP response
         # *headers* available. Remedied in PowerShell 6+ with -ResponseHeadersVariable, but PowerShell 5.1 compatibility is needed for now
         $PanResponse = New-PanResponse -WebResponse (Invoke-WebRequest @InvokeParams -UseBasicParsing) -Device $DeviceCur
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponse Status ' + $PanResponse.Status + ', Code ' + $PanResponse.Code)
         return $PanResponse

      } # Process block outermost foreach
   } # Process block

   End {
   } # End block
} # Function
