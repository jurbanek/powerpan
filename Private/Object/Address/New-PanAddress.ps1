function New-PanAddress {
   <#
   .SYNOPSIS
   Returns a PanAddress object.
   .DESCRIPTION
   Returns a PanAddress object. To apply PanAddress to NGFW, use Set-, Remove-, Clear- cmdlets.
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   PanAddress
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='Address object name')]
      [String] $Name,
      [parameter(
         Mandatory=$true,
         Position=1,
         HelpMessage='Address object value e.g. "10.1.1.1/32" , "server.acme.com"')]
      [String] $Value,
      [parameter(
         HelpMessage='IpNetmask, IpRange, IpWildcardMask, Fqdn')]
      [PanAddressType] $Type = [PanAddressType]::IpNetmask,
      [parameter(
         HelpMessage='Address object description')]
      [String] $Description = $null,
      [parameter(
         HelpMessage='PAN-OS tag(s) to be added to address object, tags must already exist')]
      [System.Collections.Generic.List[String]] $Tag = [System.Collections.Generic.List[String]]@(),
      [parameter(
         ParameterSetName='ParentDevice',
         HelpMessage='Optional ParentDevice')]
      [PanDevice] $Device,
      [parameter(
         ParameterSetName='ParentDevice',
         HelpMessage='Optional Location within ParentDevice')]
      [String] $Location
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters.Debug) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce
   Write-Debug $($MyInvocation.MyCommand.Name + ': ')

   if($PSCmdlet.ParameterSetName -eq 'ParentDevice') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': ParentDevice specified')
      return [PanAddress]::new($Name, $Value, $Type, $Description, $Tag, $Device, $Location)
   }
   else {
      return [PanAddress]::new($Name, $Value, $Type, $Description, $Tag)
   }
} # Function
