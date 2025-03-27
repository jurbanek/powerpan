$ModuleName = "PowerPAN"
# Presumes file name of 'FunctionName.Tests.ps1'. Not available within Pester InModuleScope block. Use a manually defined $FunctionName instead.
$FunctionName =  $(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.ps1','')
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module $ModuleName | Remove-Module -Force
Import-Module "$Here\..\..\$ModuleName.psm1" -Force

Describe "$FunctionName Unit Tests" -Tag "Unit" {
   InModuleScope $ModuleName {
      # Outer $FunctionName not available within Pester InModuleScope block. Manually define for ease.
      $FunctionName = 'Remove-PanDevice'
      $SessionGuid = 'baab9aad-b846-4662-a6ab-c88e7347b84c'
      # Mock GetPanSessionGuid to always return our forged session guid
      Mock GetPanSessionGuid { return $SessionGuid }
      # Mock ImportPanDeviceDb and ExportPanDeviceDb to neuter them. We are not testing import and export functionality
      Mock ImportPanDeviceDb {}
      Mock ExportPanDeviceDb {}

      $Global:PanDeviceDb = [System.Collections.Generic.List[PanDevice]]@()

      # Function to be used to populate PanDeviceDb multiple times given the removal nature of Remove-PanDevice
      function InitializePanDeviceTest {
         New-PanDevice -Name 'MyFirewall01' -Username 'xmlapiadmin' -Password 'asdf1234' -Label 'AngryBeaver' -ImportMode
         New-PanDevice -Name 'MyFirewall02' -Username 'xmlapiadmin' -Password 'jkl;5678' -Label 'DesignedByApprentices','BuiltWithPride' -ImportMode
         New-PanDevice -Name 'YourFirewall' -Username 'xmlapiadmin' -Password 'zxcv9012' -Label 'AngryBeaver',"session-$(GetPanSessionGuid)" -ImportMode
         New-PanDevice -Name 'TheirFirewall' -Username 'xmlapiadmin' -Password 'tyui4783' -Label 'AngryBeaver','BuiltWithPride',"session-$(GetPanSessionGuid)" -ImportMode
      }

      Context "Parameter Set: Device" {
         InitializePanDeviceTest
         # Additional PanDevice to be removed via -Device Parameter
         $RemoveMePresent = New-PanDevice -Name 'RemoveByDevice' -Username 'xmlapiadmin' -Password 'tyui4783' -Label "session-$(GetPanSessionGuid)" -ImportMode
         # Additional PanDevice to be removed via -Device Parameter, but Device is not added to PanDeviceDb (-NoPersist)
         $RemoveMeNotPresent = New-PanDevice -Name 'RemoveByDevice' -Username 'xmlapiadmin' -Password 'tyui4783' -Label "session-$(GetPanSessionGuid)" -ImportMode -NoPersist

         It "$FunctionName -Device (Assert PanDeviceDb Initialized)" {
            # Using Compare-Object instead of a direct comparison. Encountered situations where the Generic.List was being reordered in later test cases
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall','RemoveByDevice') | Should -Be $null
         }
         It "$FunctionName -Device (Removal)" {
            Remove-PanDevice -Device $RemoveMePresent
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Device (Removal Not Exist in PanDeviceDb)" {
            Remove-PanDevice -Device $RemoveMeNotPresent
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
      }

      Context "Parameter Set: Filter" {
         It "$FunctionName -Session" {
            InitializePanDeviceTest
            Remove-PanDevice -Session
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02') | Should -Be $null
         }
         It "$FunctionName -Label 'BuiltWithPride'" {
            InitializePanDeviceTest
            Remove-PanDevice -Label 'BuiltWithPride'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall') | Should -Be $null
         }
         It "$FunctionName -Name 'YourFirewall'" {
            InitializePanDeviceTest
            Remove-PanDevice -Name 'YourFirewall'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Session -Label 'BuiltWithPride'" {
            InitializePanDeviceTest
            Remove-PanDevice -Session -Label 'BuiltWithPride'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall') | Should -Be $null
         }
         It "$FunctionName -Session -Label 'AngryBeaver' -Name 'TheirFirewall'" {
            InitializePanDeviceTest
            Remove-PanDevice -Session -Label 'AngryBeaver' -Name 'TheirFirewall'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall') | Should -Be $null
         }
         It "$FunctionName -Label 'DesignedByApprentices','BuiltWithPride'" {
            InitializePanDeviceTest
            Remove-PanDevice -Label 'DesignedByApprentices','BuiltWithPride'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Label 'ExxonValdez'" {
            InitializePanDeviceTest
            Remove-PanDevice -Label 'ExxonValdez'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Label 'ExxonValdez','BuiltWithPride'" {
            InitializePanDeviceTest
            Remove-PanDevice -Label 'ExxonValdez','BuiltWithPride'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Name 'Non-Existent'" {
            InitializePanDeviceTest
            Remove-PanDevice -Name 'Non-Existent'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
         It "$FunctionName -Name 'Non-Existent','MyFirewall01'" {
            InitializePanDeviceTest
            Remove-PanDevice -Name 'Non-Existent','MyFirewall01'
            $(Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall02','YourFirewall','TheirFirewall') | Should -Be $null
         }
      } # Context "Parameter Set: Filter"
   } # InModuleScope
} # Describe
