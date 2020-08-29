function Get-PanAddress {
   <#
   .SYNOPSIS
   Get address objects
   .DESCRIPTION
   .NOTES
   .INPUTS
   PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PanAddress
   .EXAMPLE
   PS> Get-PanDevice | Get-PanAddress

   Retrieves address objects of all types in all locations (shared, vsys1, vsys2, etc.)
   .EXAMPLE
   PS> Get-PanDevice | Get-PanAddress -Location 'shared','vsys2'

   Retrieves address objects of all types in specified 'shared' location and 'vsys2' location.
   .EXAMPLE
   PS> Get-PanDevice | Get-PanAddress -Filter '192.168

   #>
   [CmdletBinding(DefaultParameterSetName='NoFilter')]
   param(
      [parameter(
         Mandatory=$true,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice against which address object(s) will be retrieved.')]
      [PanDevice[]] $Device,
      [parameter( 
         Position=0,
         ParameterSetName='Filter',
         HelpMessage='Name or value filter for address object(s) to be retrieved. Filter applied locally (not via API). Regex supported. Multiple String are logical OR.')]
      [String[]] $Filter,
      [parameter( 
         ParameterSetName='Filter',
         HelpMessage='Location filter (shared, vsys1, etc.) for address object(s) to be retrieved. Filter applied remotely (via API). Multiple String are logical OR.')]
      [String[]] $Location
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
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
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd

         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseStatus: ' + $PanResponse.Status)
         Write-Debug ($MyInvocation.MyCommand.Name + ': PanResponseMsg: ' + $PanResponse.Message)

         # Define here, track an individual device number of registered-ip's.
         $DeviceCurEntryCount = 0

         if($PanResponse.Status -eq 'success') {
            foreach($EntryCur in $PanResponse.Result.entry) {
               # Increment individual device count of registered-ip's.
               $DeviceCurEntryCount += 1
               # Placeholder to aggregate multiple tag values should a single registered-ip have multiple tags.
               $TagMemberAgg = @()
               foreach($TagMemberCur in $EntryCur.tag.member) {
                  $TagMemberAgg += $TagMemberCur
               }
               # Create new PanRegisteredIp object, output to pipeline (fast update for users), save to variable
               New-PanRegisteredIp -Ip $EntryCur.ip -Tag $TagMemberAgg -Device $DeviceCur | Tee-Object -Variable 'RegIpFoo'
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
