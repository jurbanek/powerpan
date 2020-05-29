function Remove-PanRegisteredIp {
   <#
   .SYNOPSIS
   Unregister PAN-OS registered-ip(s) and tag(s).
   .DESCRIPTION
   Unregister PAN-OS registered-ip(s) and tag(s).
   Unregister with -Ip and -Tag Strings (simultaneously or exclusively) or using a -PanRegisteredIp object (from New-PanRegisteredIp).

   If a single -Ip is passed exclusively, all tags for the IP are unregistered, forcing complete unregistration of the IP.
   If a single -Tag is passed exclusively, the tag is unregistered from all tagged IP's. If an active registered-ip has multiple tags, the other tags will remain registered.
   If both -Ip and -Tag are passed simultaneously, the tag is unregistered from the specified IP only.
   If multiple -Ip and multiple -Tag are passed (via arrays) simultaneously (arrays for both parameters) or exclusively (array for one parameter), the specified tags are removed from the specified IP's.

   If a single -RegisteredIp is passed, the tag(s) within the PanRegisteredIp object are removed from the IP within the PanRegisteredIp object.
   If multiple -RegisteredIp are passed (via array), each PanRegisteredIp object is treated as an individual action (different behavior from passing multiple -Ip and -Tag).
   
   If multiple -Device are passed (via array), the registered-ip and tags unregistration logic is applied to each device individually.
   .NOTES
   PAN-OS registered-ip is not added to a Dynamic Address Group (DAG) directly. Instead, a PAN-OS registered-ip is registered with tag(s). Multiple tags can be registered to a single registered-ip.
   The tag(s) against which a registered-ip can be registered can be defined in Objects > Tags OR arbitrary string values that do not exist in Objects > Tags.
   DAG match criteria is based on tag(s). After registering a registered-ip with tag(s), PAN-OS then dynamically computes to which DAG(s) the registered-ip is added.
   .INPUTS
   .OUTPUTS
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -Ip "1.1.1.1" -Tag "MyTag"
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -Ip "1.1.1.1","2.2.2.2"
   All tags are unregistered from both 1.1.1.1 and 2.2.2.2 registered-ip's.
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -Tag "HerTag","HisTag"
   "HerTag" and "HisTag" are unregistered from every registered-ip.
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -Ip "1.1.1.1","2.2.2.2" -Tag "HerTag","HisTag"
   "HerTag" and "HisTag" are both unregistered from both 1.1.1.1 and 2.2.2.2 registered-ip's.
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -RegisteredIp $(New-PanRegisteredIp -Ip "1.1.1.1" -Tag "HerTag","HisTag")
   "HerTag" and "HisTag" are both removed from 1.1.1.1 registered-ip.
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -RegisteredIp $(New-PanRegisteredIp -Ip "1.1.1.1" -Tag "HerTag","HisTag"),$(New-PanRegisteredIp -Ip "2.2.2.2" -Tag "HerTag")
   "HerTag" and "HisTag" are both unregistered from 1.1.1.1 registered-ip. "HerTag" is unregistered from 2.2.2.2 registered-ip.
   .EXAMPLE
   Remove-PanRegisteredIp -Device $Device -All
   All tags are unregistered from all registered-ip's.
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which IP unregistration and untagging will take place.')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$false,
         ParameterSetName='UnregisterWithStrings',
         HelpMessage='IP address to unregister.')]
      [String[]] $Ip,
      [parameter(
         Mandatory=$false,
         ParameterSetName='UnregisterWithStrings',
         HelpMessage='Tag(s) to unregister from IP address.')]
      [String[]] $Tag,
      [parameter(
         Mandatory=$true,
         Position=1,
         ParameterSetName='UnregisterWithPanRegisteredIp',
         HelpMessage='PanRegisteredIp object to unregister.')]
      [PanRegisteredIp[]] $RegisteredIp,
      [parameter(
         Mandatory=$true,
         ParameterSetName='UnregisterAll',
         HelpMessage='Switch parameter to unregister all tags from all IP addresses.')]
      [Switch] $All
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
   }

   Process {
      foreach($DeviceCur in $Device) {
         # For -RegisteredIp, -Ip/-Tag, -Ip, and -Tag Cases, $RegisteredIpAgg is blueprint for unregistrations.
         # Build and hold the collection of [PanRegisteredIp] that need to be removed.
         $RegisteredIpAgg = [System.Collections.Generic.List[PanRegisteredIp]]@()

         # -All switch parameter indicating all registered-ip's are to be unregistered.
         if($PSCmdlet.ParameterSetName -eq 'UnregisterAll') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Unregistering ALL IP:TAG registration(s)')
            return Clear-PanRegisteredIp -Device $Device
         }
         # -RegisteredIp providing the exact set of unregistration actions.
         elseif($PSCmdlet.ParameterSetName -eq 'UnregisterWithPanRegisteredIp') {
            Write-Debug ($MyInvocation.MyCommand.Name + ': Unregistering IP:TAG registration(s) specified by PanRegisteredIp object(s)')
            $RegisteredIpAgg.Add($RegisteredIp)
         }
         # With Parameter set UnregisterWithStrings, -Ip and -Tag can be used exclusively or simultaneously to achieve different goals.
         elseif($PSCmdlet.ParameterSetName -eq 'UnregisterWithStrings') {
            # -Ip and -Tag parameters simultaneously
            if(-not [String]::IsNullOrEmpty($Ip) -and -not [String]::IsNullOrEmpty($Tag) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': Unregistering IP:TAG registration(s) matching IP && TAG')
               # While Remove-PanRegisteredIp will accept array on -Ip parameter,
               # Get-PanRegisteredIp cannot accept array on its -Ip parameter. Must iterate.
               foreach($IpCur in $Ip) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ": Searching device $($DeviceCur.Name) for registered-ip $IpCur")
                  # $RegisteredIpResult will be a single [PanRegisteredIp], but the IP MAY have MULTIPLE tag registrations.
                  $RegisteredIpResult = $null
                  $RegisteredIpResult = Get-PanRegisteredIp -Device $DeviceCur -Ip $IpCur
                  if(-not [String]::IsNullOrEmpty($RegisteredIpResult) ) {
                     Write-Debug ($MyInvocation.MyCommand.Name + ": registered-ip $IpCur FOUND on device $($DeviceCur.Name)")
                     # Remove-PanRegisteredIp with -Ip and -Tag simultaneously will ONLY unregister tags specified in -Tag parameter, must iterate.
                     # $TagAgg to hold the (sub)set of tags that must be unregistered.
                     $TagAgg = [System.Collections.Generic.List[String]]@()
                     foreach($TagCur in $Tag) {
                        Write-Debug ($MyInvocation.MyCommand.Name + ": Searching for tag $TagCur on registered-ip $IpCur")
                        if($RegisteredIpResult.Tag -contains $TagCur) {
                           Write-Debug ($MyInvocation.MyCommand.Name + ": tag $TagCur FOUND on registered-ip $IpCur")
                           $TagAgg.Add($TagCur)
                        }
                     }
                     # If tags need to be unregistered, build new [PanRegisteredIp] with ONLY necessary tags to unregister.
                     # Add new [PanRegisteredIp] to the blueprint to be unregistered later. 
                     if(-not [String]::IsNullOrEmpty($TagAgg) ) {
                        $RegisteredIpAgg.Add( (New-PanRegisteredIp -Ip $IpCur -Tag $TagAgg) )
                     }
                  } # if $RegisteredIpResult
               } # foreach $IpCur in $Ip
            } # -Ip and -Tag parameters simultaneously

            # -Ip parameter exlusively
            elseif(-not [String]::IsNullOrEmpty($Ip) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': Unregistering IP:TAG registration(s) matching IP only')
               # While Remove-PanRegisteredIp will accept array on -Ip parameter,
               # Get-PanRegisteredIp cannot accept array on its -Ip parameter. Must iterate.
               foreach($IpCur in $Ip) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ": Searching device $($DeviceCur.Name) for registered-ip $IpCur")
                  # $RegisteredIpResult will be a single [PanRegisteredIp] with all tag registrations.
                  $RegisteredIpResult = $null
                  $RegisteredIpResult = Get-PanRegisteredIp -Device $DeviceCur -Ip $IpCur
                  if(-not [String]::IsNullOrEmpty($RegisteredIpResult) ) {
                     Write-Debug ($MyInvocation.MyCommand.Name + ": registered-ip $IpCur FOUND on device $($DeviceCur.Name)")
                     # Add the [PanRegisteredIp] to the blueprint to be unregistered later. 
                     $RegisteredIpAgg.Add($RegisteredIpResult)
                  } # if $RegisteredIpResult
               } # foreach $IpCur in $Ip
            } # -Ip parameter exclusively

            # -Tag parameter exclusively
            elseif(-not [String]::IsNullOrEmpty($Tag) ) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': Unregistering IP:TAG registration(s) matching Tag only')
               # $HashTableAgg placeholder data structure to store @{"10.10.10.10" = @("HisTag","HerTag"); "10.20.20.20" = @("HerTag") }
               # string representations of IP:TAG mappings temporarily. Easy to insert and manipulate.
               $HashTableAgg = @{}
               # While Remove-PanRegisteredIp will accept array on -Tag parameter,
               # Get-PanRegisteredIp cannot accept array on its -Tag parameter. Must iterate.
               foreach($TagCur in $Tag) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ": Searching device $($DeviceCur.Name) for registered-ip's with tag $TagCur")
                  # $RegisteredIpResult will be ZERO OR MORE [PanRegisteredIp] (array), where each [PanRegisteredIp] IP MAY have MULTIPLE tag registrations.
                  $RegisteredIpResult = $null
                  $RegisteredIpResult = @(Get-PanRegisteredIp -Device $DeviceCur -Tag $TagCur)
                  if(-not [String]::IsNullOrEmpty($RegisteredIpResult) ) {
                     foreach($RegisteredIpResultCur in $RegisteredIpResult) {
                        Write-Debug ($MyInvocation.MyCommand.Name + ": registered-ip $($RegisteredIpResultCur.Ip) with tag $TagCur FOUND on device $($DeviceCur.Name)")
                        # IP already a key in hash table, add the tag to the existing array of tags.
                        if($HashTableAgg.Contains($RegisteredIpResultCur.Ip) ) {
                           $HashTableAgg[$RegisteredIpResultCur.Ip] = $HashTableAgg[$RegisteredIpResultCur.Ip] + $TagCur
                        }
                        # IP not a key in hash table, add the new k->v. Value must be added as array despite being a single tag at this point. 
                        else {
                           $HashTableAgg.Add($RegisteredIpResultCur.Ip, @($TagCur))
                        }
                     } # foreach $RegisteredIpResultCur in $RegisteredIpResult
                  } # if $RegisteredIpResult
               } # foreach $TagCur in $Tag

               # Iterate through the $HashTableAgg "converting" to the blueprint $RegisteredIpAgg
               # Hashtable keys are IP addresses, values are an array of tags.
               if(-not [String]::IsNullOrEmpty($HashTableAgg)) {
                  foreach($Entry in $HashTableAgg.GetEnumerator()) {
                     $RegisteredIpAgg.Add( (New-PanRegisteredIp -Ip $Entry.Name -Tag $Entry.Value) )
                  }
               }
            } # -Tag parameter simultaneously
         } # elseif UnregisterWithStrings

         # Convert $RegisteredIpAgg blueprint to XML uid-message and send API request to unregister. 
         # For -RegisteredIp, -Ip/-Tag, -Ip, and -Tag Cases, $RegisteredIpAgg is blueprint for unregistrations.
         if([String]::IsNullOrEmpty($RegisteredIpAgg) ) {
            Write-Debug ($MyInvocation.MyCommand.Name + ": Searches resulted in ZERO unregistrations to process")
         }
         else {
            Write-Debug ($MyInvocation.MyCommand.Name + ": Searches resulted in ONE OR MORE unregistrations to process")
            Write-Debug ($MyInvocation.MyCommand.Name + ": Device: $($DeviceCur.Name)")
            # Seed a herestring with XML-API "uid-message" beginning elements. Rebuild for every new device iteration.
            $CmdCur = @'
<uid-message>
 <version>2.0</version>
 <type>update</type>
 <payload>
  <unregister>

'@
            foreach($RegisteredIpCur in $RegisteredIpAgg) {
               Write-Debug ($MyInvocation.MyCommand.Name + ":    registered-ip: $($RegisteredIpCur.Ip)")
               $CmdCur += "   <entry ip=`"$($RegisteredIpCur.Ip)`">`n"
               $CmdCur += "    <tag>`n"

               foreach($TagCur in $RegisteredIpCur.Tag) {
                  Write-Debug ($MyInvocation.MyCommand.Name + ":       tag: $($TagCur)")
                  $CmdCur += "     <member>$TagCur</member>`n"
               }

               $CmdCur += "    </tag>`n"
               $CmdCur += "   </entry>`n"
            }
            # Complete the XML-API "uid-message" ending elements.
            $CmdCur += @'
  </unregister>
 </payload>
</uid-message>

'@
            Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
            Write-Debug ($MyInvocation.MyCommand.Name + ': Prepared uid-message: ' + $CmdCur)
            $PanResponse = Invoke-PanXApi -Device $DeviceCur -Uid -Cmd $CmdCur
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.response.status)
            Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.response.InnerXml)
         } # else Convert $RegisteredIpAgg blueprint to XML uid-message and send API request to unregister
      } # foreach Device
   } # Process block

   End {
   } # End block 
} # Function