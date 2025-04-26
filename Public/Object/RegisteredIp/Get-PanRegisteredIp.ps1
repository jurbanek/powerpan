function Get-PanRegisteredIp {
   <#
   .SYNOPSIS
   Get current registered IP address (PAN-OS "registered-ip") and tag mappings
   .DESCRIPTION
   .NOTES
   PAN-OS "registered-ip" is tagged with PAN-OS tag(s). The tag(s) do not have to exist in Objects > Tags.
   DAG match criteria is based on PAN-OS tag(s). After tagging a "registered-ip", PAN-OS then computes to which DAG(s) the registered-ip is added.
   .INPUTS
   .OUTPUTS
   PowerPan.PanRegisteredIp
   .EXAMPLE
   Get-PanRegisteredIp -Device $Device
   .EXAMPLE
   Get-PanRegisteredIp -Device $Device -Ip "10.1.1.1"
   .EXAMPLE
   Get-PanRegisteredIp -Device $Device -Tag "HerTag"

   #>
   [CmdletBinding(DefaultParameterSetName='NoFilter')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which registered-ip(s) will be retrieved')]
      [PanDevice[]] $Device,
      [parameter(
         Mandatory=$true,
         Position=0,
         ParameterSetName='FilterIp',
         HelpMessage='IP address filter of registered-ip to be retrieved. Filter is applied remotely. No regex supported')]
      [String] $Ip,
      [parameter(
         Mandatory=$true,
         ParameterSetName='FilterTag',
         HelpMessage='Tag filter for registered-ip(s) to be retrieved. Filter is applied remotely. No regex supported')]
      [String] $Tag
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # No local filtering defined. Return everything.
      if($PSCmdlet.ParameterSetName -eq 'NoFilter') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': No Filter Applied')
         $Cmd = '<show><object><registered-ip><all/></registered-ip></object></show>'
      }
      # Filter $Ip is present, adjust our operational Cmd.
      elseif($PSCmdlet.ParameterSetName -eq 'FilterIp') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': IP Filter Applied')
         $Cmd = "<show><object><registered-ip><ip>$Ip</ip></registered-ip></object></show>"
      }
      # Only $Tag is defined. Can be an array.
      elseif($PSCmdlet.ParameterSetName -eq 'FilterTag') {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Tag Filter Applied')
         $Cmd = "<show><object><registered-ip><tag><entry name='$Tag'/></tag></registered-ip></object></show>"
      }

      # Define here, track aggregate device aggregate results in Process block.
      $PanRegIpAgg = [System.Collections.Generic.List[PanRegisteredIp]]@()
   } # Begin Block

   Process {
      foreach($DeviceCur in $Device) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $R = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $R.Status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $R.Message)

         # Define here, track an individual device number of registered-ip's.
         $DeviceCurEntryCount = 0

         if($R.Status -eq 'success') {
            foreach($EntryCur in $R.Response.result.entry) {
               # Increment individual device count of registered-ip's.
               $DeviceCurEntryCount += 1
               # Placeholder to aggregate multiple tag values should a single registered-ip have multiple tags.
               $TagMemberAgg = @()
               foreach($TagMemberCur in $EntryCur.tag.member) {
                  $TagMemberAgg += $TagMemberCur
               }
               # Create new PanRegisteredIp object, output to pipeline (fast update for users), save to variable
               NewPanRegisteredIp -Ip $EntryCur.ip -Tag $TagMemberAgg -Device $DeviceCur | Tee-Object -Variable 'RegIpFoo'
               # Add the new PanRegisteredIp to aggregate. Will be counted in End block. Available for future feature as well
               $PanRegIpAgg.Add($RegIpFoo)
            }
         }
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name + ' registered-ip count: ' + $DeviceCurEntryCount)
      } # foreach Device
   } # Process block
   End {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Final registered-ip count: ' + $PanRegIpAgg.Count)
   } # End block
} # Function
