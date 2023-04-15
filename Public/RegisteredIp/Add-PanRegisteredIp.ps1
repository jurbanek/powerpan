function Add-PanRegisteredIp {
   <#
   .SYNOPSIS
   Register PAN-OS registered-ip(s) with tag(s).
   .DESCRIPTION
   Register PAN-OS registered-ip(s) with tag(s).
   Register with -Ip and -Tag Strings or using a -PanRegisteredIp object (from New-PanRegisteredIp).
   If multiple -Device are passed (via array), the registered-ip and tagging is applied to every device.
   If multiple -Ip and -Tag are passed (via arrays), every -Ip is tagged with every -Tag.
   If multiple -RegisteredIp are passed (via array), each -RegisteredIp represents a complete registration action.
   .NOTES
   PAN-OS registered-ip is not added to a Dynamic Address Group (DAG) directly. Instead, a PAN-OS registered-ip is registered with tag(s). Multiple tags can be registered to a single registered-ip.
   The tag(s) against which a registered-ip can be registered can be defined in Objects > Tags OR arbitrary string values that do not exist in Objects > Tags.
   DAG match criteria is based on tag(s). After registering a registered-ip with tag(s), PAN-OS then dynamically computes to which DAG(s) the registered-ip is added.
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanResponse
   .EXAMPLE
   PS. Add-PanRegisteredIp -Device $Device -Ip "1.1.1.1" -Tag "MyTag"
   .EXAMPLE
   PS> Add-PanRegisteredIp -Device $Device -Ip "1.1.1.1","2.2.2.2" -Tag "HerTag","HisTag"
   "HerTag" and "HisTag" are both applied to both 1.1.1.1 and 2.2.2.2 registered-ip's.
   .EXAMPLE
   PS> Add-PanRegisteredIp -Device $Device -RegisteredIp $(New-PanRegisteredIp -Ip "1.1.1.1" -Tag "HerTag","HisTag")
   "HerTag" and "HisTag" are both applied to 1.1.1.1 registered-ip.
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which IP registration and tagging will take place')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$true,
         Position=0,
         ParameterSetName='RegisterWithStrings',
         HelpMessage='IP address to register')]
      [String[]] $Ip,
      [parameter(
         Mandatory=$true,
         Position=1,
         ParameterSetName='RegisterWithStrings',
         HelpMessage='Tag(s) to apply to IP address')]
      [String[]] $Tag,
      [parameter(
         Mandatory=$true,
         Position=0,
         ParameterSetName='RegisterWithPanRegisteredIp',
         HelpMessage='PanRegisteredIp object to apply')]
      [PanRegisteredIp[]] $RegisteredIp
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   }

   Process {
      foreach($DeviceCur in $Device) {
         # Seed a herestring with XML-API "uid-message" beginning elements. Rebuild for every new device iteration.
         $CmdCur = @'
<uid-message>
 <version>2.0</version>
 <type>update</type>
 <payload>
  <register>

'@
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)

         if($PSCmdlet.ParameterSetName -eq 'RegisterWithStrings') {
            foreach($IpCur in $Ip) {
               Write-Debug ($MyInvocation.MyCommand.Name + ":    registered-ip: $IpCur")
               $CmdCur += "   <entry ip=`"$IpCur`">`n"
               $CmdCur += "    <tag>`n"

               foreach($TagCur in $Tag) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ":       tag: $TagCur")
                  $CmdCur += "     <member>$TagCur</member>`n"
               }

               $CmdCur += "    </tag>`n"
               $CmdCur += "   </entry>`n"
            }
         }
         elseif($PSCmdlet.ParameterSetName -eq 'RegisterWithPanRegisteredIp') {
            foreach($RegisteredIpCur in $RegisteredIp) {
               Write-Debug ($MyInvocation.MyCommand.Name + ":    registered-ip: $($RegisteredIpCur.Ip)")
               $CmdCur += "   <entry ip=`"$($RegisteredIpCur.Ip)`">`n"
               $CmdCur += "    <tag>`n"

               foreach($RegisteredIpCurTagCur in $RegisteredIpCur.Tag) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ":       tag: $RegisteredIpCurTagCur")
                  $CmdCur += "     <member>$RegisteredIpCurTagCur</member>`n"
               }

               $CmdCur += "    </tag>`n"
               $CmdCur += "   </entry>`n"
            }
         }
         # Complete the XML-API "uid-message" ending elements.
         $CmdCur += @'
  </register>
 </payload>
</uid-message>

'@
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $Device.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Prepared uid-message: ' + $CmdCur)
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Uid -Cmd $CmdCur
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.Status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.Message)
      } # foreach Device
   } # Process block

   End {
   } # End block
} # Function
