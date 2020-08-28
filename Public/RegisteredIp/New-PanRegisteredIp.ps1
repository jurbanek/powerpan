function New-PanRegisteredIp {
   <#
   .SYNOPSIS
      Returns a PowerPAN.PanRegisteredIp object.
   .DESCRIPTION
      Returns a PowerPAN.PanRegisteredIp object. To apply PanRegisteredIp to NGFW, use Add-, Remove-, Clear- cmdlets.
   .NOTES
   .INPUTS
      None
   .OUTPUTS
      PowerPan.PanRegisteredIp
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
         Position=2,
         ParameterSetName='ParentDevice',
         HelpMessage='Optional ParentDevice. Internal use only.')]
      [PanDevice] $Device
   )

   # If -Debug parameter, change to 'Continue' instead of 'Inquire'
   if($PSBoundParameters['Debug']) {
      $DebugPreference = 'Continue'
   }
   # If -Debug parameter, announce 
   Write-Debug $($MyInvocation.MyCommand.Name + ': ')

   if($PSCmdlet.ParameterSetName -eq 'ParentDevice') {
      Write-Debug $($MyInvocation.MyCommand.Name + ': ParentDevice specified')
      return [PanRegisteredIp]::new($Ip, $Tag, $Device)
   }
   else {
      return [PanRegisteredIp]::new($Ip, $Tag)
   }
}