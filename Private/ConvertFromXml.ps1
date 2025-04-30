function ConvertFromXml {
<#
.SYNOPSIS
Converts the 'Property' type properties of a System.Xml.* object to a PSCustomObject
.DESCRIPTION
Converts the 'Property' type properties of a System.Xml.* object to a PSCustomObject
.NOTES
Recursive function. Watch out.
.INPUTS
.OUTPUTS
.EXAMPLE
#>
   [CmdletBinding()]
   param(
      [parameter(
         Mandatory=$true,
         Position=0,
         ValueFromPipeline=$true,
         HelpMessage='Xml')]
      [Object] $XmlObject
   )

   Begin {
      # Propagate -Verbose to this module function, https://tinyurl.com/y5dcbb34
      if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
      # Announce
      Write-Verbose ('{0}:' -f $MyInvocation.MyCommand.Name)
      
      $CustomObject = New-Object -TypeName 'PSCustomObject'
   }

   Process {
      foreach($MemberDefCur in ($XmlObject | Get-Member -MemberType 'Property')) {
         if($XmlObject.($MemberDefCur.Name).GetType().Name -like '*Xml*') {
            Add-Member -InputObject $CustomObject -MemberType 'NoteProperty' -Name $MemberDefCur.Name -Value $(ConvertFromXml -XmlObject $XmlObject.($MemberDefCur.Name) )
         }
         else {
            Add-Member -InputObject $CustomObject -MemberType 'NoteProperty' -Name $MemberDefCur.Name -Value $XmlObject.($MemberDefCur.Name)
         }
      }
   }

   End {
      return $CustomObject
   }
}
