function SetX509CertificateValidation {
<#
.SYNOPSIS
Require or disable x.509 certificate validation for Invoke-WebRequest, Invoke-RestMethod, and other .NET backed HTTPS calls.
.DESCRIPTION
Change/setting persists for the remainder of the PowerShell session or until changed within the PowerShell session.

New PowerShell sessions are started with the .NET default (requires validation).
.NOTES
.INPUTS
None
.OUTPUTS
None
.PARAMETER Validate
Require x.509 certificate validation validation (trust) for Invoke-WebRequest, Invoke-RestMethod, and other .NET backed HTTPS calls
.PARAMETER NoValidate
Disable x.509 certificate validation validation (trust) for Invoke-WebRequest, Invoke-RestMethod, and other .NET backed HTTPS calls
.EXAMPLE
PS> SetX509CertificateValidation -NoValidate

Disable x.509 certificate validation for subsequent .NET backed HTTPS calls
.EXAMPLE
PS> SetX509CertificateValidation -Validate

Require x.509 certificate validation for subsequent .NET backed HTTPS calls
#>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ParameterSetName='Validate',
         HelpMessage='Switch parameter to enable validation.')]
      [Switch] $Validate,
      [parameter(
         Mandatory=$true,
         Position=0,
         ParameterSetName='NoValidate',
         HelpMessage='Switch parameter to disable validation.')]
      [Switch] $NoValidate
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   ## Disable x.509 certificate validation
   if ($PSBoundParameters.NoValidate.IsPresent -and $PSCmdlet.ShouldProcess('this session','Disable x.509 Certificate Validation')) {
      Write-Debug $($MyInvocation.MyCommand.Name + ': Disabling x.509 Certificate Validation')

      # Method 1 - Works on some older versions of Powershell
      #[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

      # Method 2 - Works on more (including newer) versions of PowerShell.
      if (-not("dummy" -as [type])) {
         add-type -TypeDefinition @"
            using System;
            using System.Net;
            using System.Net.Security;
            using System.Security.Cryptography.X509Certificates;

            public static class Dummy {
               public static bool ReturnTrue(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) {
                  return true;
               }
               public static RemoteCertificateValidationCallback GetDelegate() {
                  return new RemoteCertificateValidationCallback(Dummy.ReturnTrue);
               }
            }
"@ # End type definition
      } # End type definition if*guard*

      [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [dummy]::GetDelegate()
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
   }
   # Enable x.509 certificate validation
   elseif ($PSBoundParameters.Validate.IsPresent -and $PSCmdlet.ShouldProcess('this session','Enable x.509 Certificate Validation')) {
      Write-Debug $($MyInvocation.MyCommand.Name + ': Enabling x.509 Certificate Validation')
      [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
   }
} # End Function
