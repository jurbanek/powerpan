function Set-PanAddressHelper {
   <#
   .SYNOPSIS
   .DESCRIPTION
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   PanResponse
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter( Mandatory=$true, HelpMessage='PanAddress object to be applied to candidate configuration')]
      [PanAddress] $Address
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   # Build XPath based on Address location property
   if($PSBoundParameters.Address.Location -match '^panorama\/*$') {
      Write-Error $($MyInvocation.MyCommand.Name + ': Unable to create or update Panorama pushed object ' +
         $PSBoundParameters.Address.Name + ' on firewall directly. Update on Panorama or override on firewall.')
      return
   }
   elseif($PSBoundParameters.Address.Location -match '^local\/shared$') {
      $XPath = "/config/shared/address/entry[@name='{0}']" -f $PSBoundParameters.Address.Name
   }
   elseif($PSBoundParameters.Address.Location -match '^local\/(?<cap1>[\w]+)$') {
      $XPath = "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='{0}']/address/entry[@name='{1}']" -f
         $Matches['cap1'],
         $PSBoundParameters.Address.Name
   }
   else {
      Write-Error $($MyInvocation.MyCommand.Name + ': No object location specified')
      return
   }

   # Build Element contents
   $Element = ""

   # Value is based on Type
   switch($PSBoundParameters.Address.Type) {
      # Using enum inside of switch statement requires wrapping in parentheses. Odd.
      # https://powershell.org/forums/topic/why-cant-my-enum-values-be-specified-as-conditions-for-switch-statement/
      ([PanAddressType]::IpNetmask) { $Element += "<ip-netmask>{0}</ip-netmask>" -f [System.Net.WebUtility]::HtmlEncode($PSBoundParameters.Address.Value); break }
      ([PanAddressType]::IpRange) { $Element += "<ip-range>{0}</ip-range>" -f [System.Net.WebUtility]::HtmlEncode($PSBoundParameters.Address.Value); break }
      ([PanAddressType]::IpWildcard) { $Element += "<ip-wildcard>{0}</ip-wildcard>" -f [System.Net.WebUtility]::HtmlEncode($PSBoundParameters.Address.Value); break }
      ([PanAddressType]::Fqdn) { $Element += "<fqdn>{0}</fqdn>" -f [System.Net.WebUtility]::HtmlEncode($PSBoundParameters.Address.Value); break }
   }

   # Description
   if(-not [String]::IsNullOrEmpty($PSBoundParameters.Address.Description)) {
      $Element += "<description>{0}</description>" -f [System.Net.WebUtility]::HtmlEncode($PSBoundParameters.Address.Description)
   }

   # Tag(s)
   if(-not [String]::IsNullOrEmpty($PSBoundParameters.Address.Tag)) {
      $Element += "<tag>"
      foreach($TagCur in $PSBoundParameters.Address.Tag) {
         $Element += "<member>{0}</member>" -f [System.Net.WebUtility]::HtmlEncode($TagCur)
      }
      $Element += "</tag>"
   }

   Write-Debug $($MyInvocation.MyCommand.Name + ': Device: ' + $PSBoundParameters.Address.Device.Name )
   Write-Debug $($MyInvocation.MyCommand.Name + ': XPath: ' + $XPath )
   Write-Debug $($MyInvocation.MyCommand.Name + ': Element: ' + $Element )

   # Using PAN-OS XML-API action=edit to replace at this node (and not merge). action=set would merge config. We must be able
   # to remove config (like tags and descriptions), so action=edit is required.
   # When using action=edit, the XPath and the Element both contain a reference to the entry itself. Odd but true.
   # Wrap the Element up to this point in another <entry> tag. Would not be needed if using action=set
   $Element = ("<entry name='" + $PSBoundParameters.Address.Name + "'>{0}</entry>") -f $Element

   # Build Invoke-PanXApi call
   return Invoke-PanXApi -Device $PSBoundParameters.Address.Device -Config -Edit -XPath $XPath -Element $Element
}
