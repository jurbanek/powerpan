function Test-PanDevice {
   <#
   .SYNOPSIS
   Test the API accessibility of a PanDevice.
   .DESCRIPTION
   Test the API accessibility of a PanDevice.
   .NOTES
   .INPUTS
   PowerPan.PanDevice[]
      You can pipe a PanDevice to this cmdlet
   .OUTPUTS
   PSCustomObject
   .EXAMPLE
   #>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         HelpMessage='PanDevice(s) to be tested')]
      [PanDevice[]] $Device
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb

   } # Begin block

   Process {
      foreach($DeviceCur in $Device) {
         $PanResponse = Invoke-PanXApi -Device $DeviceCur -Version
         if($PanResponse.response.status -eq 'success') {
            [PSCustomObject]@{
               'Name' = $DeviceCur.Name;
               'Status' = 'success';
               'Model' = $PanResponse.response.result.model;
               'Serial' = $PanResponse.response.result.serial;
               'Swversion' = $PanResponse.response.result.'sw-version';
               'Multivsys' = $PanResponse.response.result.'multi-vsys'
            }
         }
         else {
            [PSCustomObject]@{
               'Name' = $DeviceCur.Name;
               'Status' = 'error';
               'Model' = $null;
               'Serial' = $null;
               'Swversion' = $null;
               'Multivsys' = $null
            }
         }
      } # foreach
   } # Process block

   End {
   } # End block
} # Function