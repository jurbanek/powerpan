$ModuleName = "PowerPAN"
# Presumes file name of 'FunctionName.Tests.ps1'
# $FunctionName =  $(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1','')
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module $ModuleName | Remove-Module -Force
Import-Module "$Here\..\..\$ModuleName.psm1" -Force

Describe -Name "New-PanDevice Unit Tests" -Tag "Unit" {

   Context "Parameter Sets" {
      $DevName = "10.1.1.1"
      $DevKey = "LUFRPT1aNTZhR0IrcmxBOEtKa3FnbzVIa2xQOE93U3c9UlRRMEhDeEJDUEVocHhCTnExU0J4YW5hM01hcVRzT0doNUR3NWdvYWVJWT0="
      $TestDevice = New-PanDevice -Name $DevName -Key $DevKey
      It "-Key :: Should be stored as a [SecureString]" {
         $TestDevice.Key | Should -BeOfType [SecureString]
      }
      It "-Key :: Should be reversible to original value" {
         $(New-Object -TypeName PSCredential -ArgumentList 'user',$TestDevice.Key).GetNetworkCredential().Password | Should -BeExactly $DevKey
      }
   }
}