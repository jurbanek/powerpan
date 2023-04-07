function New-PanRegisteredIp {
   <#
   .SYNOPSIS
   Returns a PanRegisteredIp object.
   .DESCRIPTION
   Returns a PanRegisteredIp object. To apply PanRegisteredIp to NGFW, use Add-, Remove-, Clear- cmdlets.
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   PanRegisteredIp
   .EXAMPLE
   New-PanRegisteredIp -Ip "1.1.1.1" -Tag "MyTag"
   .EXAMPLE
   New-PanRegisteredIp -Ip "2.2.2.2" -Tag @("HerTag","HisTag") -Vsys "vsys1"
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         HelpMessage='IP address')]
      [String] $Ip,
      [parameter(
         Mandatory=$true,
         Position=1,
         HelpMessage='Tag(s)')]
      [String[]] $Tag,
      [parameter(
         Mandatory=$true,
         ParameterSetName='ParentDevice',
         HelpMessage='Optional ParentDevice. Internal use only.')]
      [PanDevice] $Device
   )

   # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Debug ($MyInvocation.MyCommand.Name + ':')

   if($PSCmdlet.ParameterSetName -eq 'ParentDevice') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': ParentDevice specified')
      return [PanRegisteredIp]::new($Ip, $Tag, $Device)
   }
   else {
      return [PanRegisteredIp]::new($Ip, $Tag)
   }
} # Function
