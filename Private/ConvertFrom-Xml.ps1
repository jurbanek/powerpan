function ConvertFrom-Xml {
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

   $CustomObject = New-Object -TypeName 'PSCustomObject'

   foreach($MemberDefCur in ($XmlObject | Get-Member -MemberType 'Property')) {
      if($XmlObject.($MemberDefCur.Name).GetType().Name -like '*Xml*') {
         Add-Member -InputObject $CustomObject -MemberType 'NoteProperty' -Name $MemberDefCur.Name -Value $(ConvertFrom-Xml -XmlObject $XmlObject.($MemberDefCur.Name) )
      }
      else {
         Add-Member -InputObject $CustomObject -MemberType 'NoteProperty' -Name $MemberDefCur.Name -Value $XmlObject.($MemberDefCur.Name)
      }
   }
   return $CustomObject
}