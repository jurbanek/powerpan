$ModuleName = "PowerPAN"
$ModuleFileName = "$ModuleName.psd1"
# Presumes file name of 'FunctionName.Tests.ps1'
$FunctionName =  (Split-Path -Leaf $PSScriptRoot).Replace('.Tests.ps1','')
$Here = Split-Path -Path $PSScriptRoot -Parent
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
   InModuleScope -ModuleName $ModuleName {
      BeforeAll {
         # Outer $FunctionName not available within Pester InModuleScope block. Manually define for ease.
         $FunctionName = 'Remove-PanDevice'
         $SessionGuid = 'baab9aad-b846-4662-a6ab-c88e7347b84c'
         # Mock GetPanSessionGuid to always return our forged session guid
         Mock GetPanSessionGuid -ModuleName $ModuleName { return $SessionGuid }
         # Mock ImportPanDeviceDb and ExportPanDeviceDb to neuter them. We are not testing import and export functionality
         Mock ImportPanDeviceDb -ModuleName $ModuleName {}
         Mock ExportPanDeviceDb -ModuleName $ModuleName {}
         Mock Update-PanDeviceLocation -ModuleName $ModuleName {}

         $Global:PanDeviceDb = @()

         # Function to be used to populate PanDeviceDb multiple times given the removal nature of Remove-PanDevice
         function InitializePanDeviceTest {
            New-PanDevice -Name 'MyFirewall01' -Username 'xmlapiadmin' -Password 'asdf1234' -Label 'AngryBeaver' -ImportMode
            New-PanDevice -Name 'MyFirewall02' -Username 'xmlapiadmin' -Password 'jkl;5678' -Label 'DesignedByApprentices','BuiltWithPride' -ImportMode
            New-PanDevice -Name 'YourFirewall' -Username 'xmlapiadmin' -Password 'zxcv9012' -Label 'AngryBeaver',"session-$(GetPanSessionGuid)" -ImportMode
            New-PanDevice -Name 'TheirFirewall' -Username 'xmlapiadmin' -Password 'tyui4783' -Label 'AngryBeaver','BuiltWithPride',"session-$(GetPanSessionGuid)" -ImportMode
         }
      }

      Context "Parameter Set: Device" {
         # BeforeAll - Run ONCE 
         BeforeAll {
            InitializePanDeviceTest
            # Additional PanDevice to be removed via -Device Parameter
            $RemoveMePresent = New-PanDevice -Name 'RemoveByDevice' -Username 'xmlapiadmin' -Password 'tyui4783' -Label "session-$(GetPanSessionGuid)" -ImportMode
         }
         It "$FunctionName -Device (Assert PanDeviceDb Initialized)" {
            # Using Compare-Object instead of a direct comparison
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall','RemoveByDevice') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Device (Removal)" {
            Remove-PanDevice -Device $RemoveMePresent
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
      }
      Context "Parameter Set: Filter" {
         # BeforeEach - Run before EACH child scope
         BeforeEach {
            $Global:PanDeviceDb = @()
            InitializePanDeviceTest
         }
         It "$FunctionName -Session" {
            Remove-PanDevice -Session
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'BuiltWithPride'" {
            Remove-PanDevice -Label 'BuiltWithPride'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Name 'YourFirewall'" {
            Remove-PanDevice -Name 'YourFirewall'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Session -Label 'BuiltWithPride'" {
            Remove-PanDevice -Session -Label 'BuiltWithPride'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Session -Label 'AngryBeaver' -Name 'TheirFirewall'" {
            Remove-PanDevice -Session -Label 'AngryBeaver' -Name 'TheirFirewall'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'DesignedByApprentices','BuiltWithPride'" {
            Remove-PanDevice -Label 'DesignedByApprentices','BuiltWithPride'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'ExxonValdez'" {
            Remove-PanDevice -Label 'ExxonValdez'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'ExxonValdez','BuiltWithPride'" {
            Remove-PanDevice -Label 'ExxonValdez','BuiltWithPride'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Name 'Non-Existent'" {
            Remove-PanDevice -Name 'Non-Existent'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Name 'Non-Existent','MyFirewall01'" {
            Remove-PanDevice -Name 'Non-Existent','MyFirewall01'
            (Get-PanDevice -All).Name | Compare-Object -ReferenceObject @('MyFirewall02','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
      } # Context "Parameter Set: Filter"
   } # InModuleScope
} # Describe
