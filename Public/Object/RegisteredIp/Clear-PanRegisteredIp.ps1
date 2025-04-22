function Clear-PanRegisteredIp {
   <#
   .SYNOPSIS
   Clears all registered-ip's on a PAN-OS firewall
   .DESCRIPTION
   .NOTES
   This cmdlet removes all registered-ip's a PAN-OS firewall. This cmdlet should be used carefully. If individual registered-ip's need to be removed, use Remove-PanRegisteredIp instead.
   Important to understand that a PAN-OS "registered-ip" is not added to a DAG directly. Instead, a PAN-OS "registered-ip" is tagged with PAN-OS tag(s).
   DAG match criteria is based on PAN-OS tag(s). After tagging a "registered-ip", PAN-OS then computes to which DAG(s) the registered-ip is added.

   "debug object registered-ip clear all" can be used from CLI.
   Unfortunately, debug CLI commands are not available via XML-API. A special uid-message achieves the objective.
   http://api-lab.paloaltonetworks.com/registered-ip.html
   .INPUTS
   .OUTPUTS
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which all registered-ip(s) will be cleared.')]
      [PanDevice[]] $Device
   )

   Begin {
      # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Seed a herestring with XML-API "uid-message" elements needed to unregister all registered-ip(s).
      $Cmd = @'
<uid-message>
 <version>2.0</version>
 <type>update</type>
 <payload>
  <clear>
   <registered-ip>
    <all/>
   </registered-ip>
  </clear>
 </payload>
 </uid-message>

'@
   } # Begin

   Process {
      foreach($DeviceCur in $Device) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Device: ' + $DeviceCur.Name)
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cmd: ' + $Cmd)
         $R = Invoke-PanXApi -Device $DeviceCur -Uid -Cmd $Cmd
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $R.Status)
      }
   } # Process

   End {
   } # End
} # Function
