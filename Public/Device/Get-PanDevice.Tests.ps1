$ModuleName = "PowerPAN"
# Presumes file name of 'FunctionName.Tests.ps1'. Not available within Pester InModuleScope block. Use a manually defined $FunctionName instead.
$FunctionName =  $(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1','')
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module $ModuleName | Remove-Module -Force
Import-Module "$Here\..\..\$ModuleName.psm1" -Force

Describe "$FunctionName Unit Tests" -Tag "Unit" {
   InModuleScope $ModuleName {
      # Outer $FunctionName not available within Pester InModuleScope block. Manually define for ease.
      $FunctionName = 'Get-PanDevice'
      $SessionGuid = 'baab9aad-b846-4662-a6ab-c88e7347b84c'
      # Mock Get-PanSessionGuid to always return our forged session guid
      Mock Get-PanSessionGuid { return $SessionGuid }
      # Mock Import-PanDeviceDb and Export-PanDeviceDb to neuter them. We are not testing import and export functionality
      Mock Import-PanDeviceDb {}
      Mock Export-PanDeviceDb {}
   
      $Global:PanDeviceDb = [System.Collections.Generic.List[PanDevice]]@()
      New-PanDevice -Name 'MyFirewall01' -Username 'xmlapiadmin' -Password 'asdf1234' -Label 'AngryBeaver' -ImportMode
      New-PanDevice -Name 'MyFirewall02' -Username 'xmlapiadmin' -Password 'jkl;5678' -Label 'DesignedByApprentices','BuiltWithPride' -ImportMode
      New-PanDevice -Name 'YourFirewall' -Username 'xmlapiadmin' -Password 'zxcv9012' -Label 'AngryBeaver',"session-$(Get-PanSessionGuid)" -ImportMode
      New-PanDevice -Name 'TheirFirewall' -Username 'xmlapiadmin' -Password 'tyui4783' -Label 'AngryBeaver','BuiltWithPride',"session-$(Get-PanSessionGuid)" -ImportMode
   
      Context "Parameter Set: Empty" {
         It "$FunctionName with no DefaultLabel" {
            Mock Get-PanDefaultLabel { return @("session-$(Get-PanSessionGuid)") }
            $(Get-PanDevice).Name | Compare-Object -ReferenceObject @('YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName with single valid DefaultLabel" {
            Mock Get-PanDefaultLabel{ return @('AngryBeaver') }
            $(Get-PanDevice).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName with double valid DefaultLabel" {
            Mock Get-PanDefaultLabel { return @('AngryBeaver','BuiltWithPride') }
            $(Get-PanDevice).Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -Be $null
         }
         It "$FunctionName with invalid DefaultLabel" {
            Mock Get-PanDefaultLabel { return @('InvalidLabel') }
            $(Get-PanDevice).Count | Should -Be 0
         }
      } # Context "Parameter Set: Empty"

      Context "Parameter Set: All" {
         It "$FunctionName All" {
         $(Get-PanDevice -All).Count | Should -Be $Global:PanDeviceDb.Count
         }
      } # Context "Parameter Set: All"

      Context "Parameter Set: Filter" {
         It "$FunctionName -Session" {
            $(Get-PanDevice -Session).Name | Compare-Object -ReferenceObject @('YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Session -Label 'BuiltWithPride'" {
            $(Get-PanDevice -Session -Label 'BuiltWithPride').Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Session -Label 'AngryBeaver' -Name 'TheirFirewall'" {
            $(Get-PanDevice -Session -Label 'AngryBeaver' -Name 'TheirFirewall').Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Label 'BuiltWithPride'" {
            $(Get-PanDevice -Label 'BuiltWithPride').Name | Compare-Object -ReferenceObject @('MyFirewall02','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Label 'InvalidLabel'" {
            $(Get-PanDevice -Label 'InvalidLabel').Count | Should -Be 0
         }
         It "$FunctionName -Label 'DesignedByApprentices','BuiltWithPride'" {
            $(Get-PanDevice -Label 'DesignedByApprentices','BuiltWithPride').Name | Compare-Object -ReferenceObject @('MyFirewall02') | Should -Be $null
         }
         It "$FunctionName -Label 'AngryBeaver' -Name 'MyFirewall01'" {
            $(Get-PanDevice -Label 'AngryBeaver' -Name 'MyFirewall01').Name | Compare-Object -ReferenceObject @('MyFirewall01') | Should -Be $null
         }
         It "$FunctionName -Name 'MyFirewall01'" {
            $(Get-PanDevice -Name 'MyFirewall01').Name | Compare-Object -ReferenceObject @('MyFirewall01') | Should -Be $null
         }
         It "$FunctionName -Name 'MyFirewall01','MyFirewall02'" {
            $(Get-PanDevice -Name 'MyFirewall01','MyFirewall02').Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02') | Should -Be $null
         }
         It "$FunctionName -Name 'InvalidName'" {
            $(Get-PanDevice -Name 'InvalidName').Count | Should -Be 0
         }
      } # Context "Parameter Set: Filter"
   } # InModuleScope
} # Describe