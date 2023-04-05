function Resolve-PanTagColor {
   <#
   .SYNOPSIS
   Resolve PAN-OS tag friendly and raw color values
   .DESCRIPTION
   Resolve PAN-OS tag friendly and raw color values
   .NOTES
   .INPUTS
   None
   .OUTPUTS
   String or System.Collections.Hashtable
   .EXAMPLE
   PS> Resolve-PanTagColor "green","color3"
   Will return an two strings, the first "color2" and the second "blue"
   .EXAMPLE
   PS> Resolve-PanTagColor
   When called with no arguments, returns the entire internal hashtable for mapping friendly names to API values and reverse.

   Hashtable is returned without modification, reflecting how it is retrieved from memory (NOT sorted alphanumerically).
   #>
   [CmdletBinding(DefaultParameterSetName='Empty')]
   [OutputType([String],[Hashtable])]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         ParameterSetName='Filter',
         HelpMessage='Color(s) to resolve')]
      [String[]] $Name
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters.Debug) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce
      Write-Debug ($MyInvocation.MyCommand.Name + ':')

      # Initialize PanDeviceDb
      Initialize-PanDeviceDb

      # Using basic array index would be nice, but since the final intent is to convert back and forth for use with PAN-OS API,
      # being able to resolve string literals back and forth is required
      $PanTagColorMap = @{
         'color1' = 'red'; 'red' = 'color1';
         'color2' = 'green'; 'green' = 'color2';
         'color3' = 'blue'; 'blue' = 'color3';
         'color4' = 'yellow'; 'yellow' = 'color4';
         'color5' = 'copper'; 'copper' = 'color5';
         'color6' = 'orange'; 'orange' = 'color6';
         'color7' = 'purple'; 'purple' = 'color7';
         'color8' = 'gray'; 'gray' = 'color8';
         'color9' = 'light-green'; 'light-green' = 'color9';
         'color10' = 'cyan'; 'cyan' = 'color10';
         'color11' = 'light-gray'; 'light-gray' = 'color11';
         'color12' = 'blue-gray'; 'blue-gray' = 'color12';
         'color13' = 'lime'; 'lime' = 'color13';
         'color14' = 'black'; 'black' = 'color14';
         'color15' = 'gold'; 'gold' = 'color15';
         'color16' = 'brown'; 'brown' = 'color16';
         'color17' = 'olive'; 'olive' = 'color17';
         # color18 is not valid keyword
         'color19' = 'maroon'; 'maroon' = 'color19';
         'color20' = 'red-orange'; 'red-orange' = 'color20';
         'color21' = 'yellow-orange'; 'yellow-orange' = 'color21';
         'color22' = 'forest-green'; 'forest-green' = 'color22';
         'color23' = 'turquoise-blue'; 'turquoise-blue' = 'color23';
         'color24' = 'azure-blue'; 'azure-blue' = 'color24';
         'color25' = 'cerulean-blue'; 'cerulean-blue' = 'color25';
         'color26' = 'midnight-blue'; 'midnight-blue' = 'color26';
         'color27' = 'medium-blue'; 'medium-blue' = 'color27';
         'color28' = 'cobalt-blue'; 'cobalt-blue' = 'color28';
         'color29' = 'violet-blue'; 'violet-blue' = 'color29';
         'color30' = 'blue-violet'; 'blue-violet' = 'color30';
         'color31' = 'medium-violet'; 'medium-violet' = 'color31';
         'color32' = 'medium-rose'; 'medium-rose' = 'color32';
         'color33' = 'lavender'; 'lavender' = 'color33';
         'color34' = 'orchid'; 'orchid' = 'color34';
         'color35' = 'thistle'; 'thistle' = 'color35';
         'color36' = 'peach'; 'peach' = 'color36';
         'color37' = 'salmon'; 'salmon' = 'color37';
         'color38' = 'magenta'; 'magenta' = 'color38';
         'color39' = 'red-violet'; 'red-violet' = 'color39';
         'color40' = 'mahogany'; 'mahogany' = 'color40';
         'color41' = 'burnt-sienna'; 'burnt-sienna' = 'color41';
         'color42' = 'chestnut'; 'chestnut' = 'color42'
      }
   } # Begin Block

   Process {
      if($PSCmdlet.ParameterSetName -eq 'Empty') {
         return $PanTagColorMap
      }
      elseif($PSCmdlet.ParameterSetName -eq 'Filter') {
         foreach($NameCur in $PSBoundParameters['Name']) {
            if($PanTagColorMap.Contains($NameCur)) {
               $PanTagColorMap[$NameCur]
            }
         }
      }
   } # Process block
   End {
   } # End block
} # Function
