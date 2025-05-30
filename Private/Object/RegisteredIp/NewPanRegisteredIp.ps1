function NewPanRegisteredIp {
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
NewPanRegisteredIp -Ip "1.1.1.1" -Tag "MyTag"
.EXAMPLE
NewPanRegisteredIp -Ip "2.2.2.2" -Tag @("HerTag","HisTag") -Vsys "vsys1"
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

   # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
   if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
   # Announce
   Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)

   if($PSCmdlet.ParameterSetName -eq 'ParentDevice') {
      Write-Verbose $($MyInvocation.MyCommand.Name + ': ParentDevice specified')
      return [PanRegisteredIp]::new($Ip, $Tag, $Device)
   }
   else {
      return [PanRegisteredIp]::new($Ip, $Tag)
   }
} # Function
