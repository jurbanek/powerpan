$ModuleName = "PowerPAN"
# Presumes file name of 'FunctionName.Tests.ps1'
# $FunctionName =  $(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1','')
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module $ModuleName | Remove-Module -Force
Import-Module "$Here\..\..\$ModuleName.psm1" -Force

Describe "Remove-PanRegisteredIp Unit Tests" -Tag "Unit" {

   Context "Parameter Sets" {
      It "Remove -All" {
         $true | Should -BeTrue
      }
   }
}