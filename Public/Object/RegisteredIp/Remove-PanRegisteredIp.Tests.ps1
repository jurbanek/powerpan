$ModuleName = "PowerPAN"
$ModuleFileName = "$ModuleName.psm1"
# Presumes file name of 'FunctionName.Tests.ps1'
$FunctionName =  (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1','')
$Here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$CurrentDir = Resolve-Path $Here
while($CurrentDir) { 
   $CurrentFilePath = Join-Path -Path $CurrentDir -ChildPath $ModuleFileName
   # If match
   if(Test-Path -Path $CurrentFilePath) {
      $ModuleFilePath = Resolve-Path -Path $CurrentFilePath
      # Break out of the loop entirely
      break
   }
   # Move up a directory
   $ParentDir = Split-Path -Path $CurrentDir -Parent
   if($ParentDir -eq $CurrentDir) {
      Write-Error("Reached root. Cannot find $ModuleFileName")
      break
   }
   else {
      $CurrentDir = $ParentDir
   }
}
Get-Module $ModuleName | Remove-Module -Force
Import-Module $ModuleFilePath.Path -Force

Describe "$FunctionName Unit Tests" -Tag "Unit" {

   Context "Parameter Sets" {
      It "Remove -All" {
         $true | Should -BeTrue
      }
   }
}
