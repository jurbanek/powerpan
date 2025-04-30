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
   InModuleScope $ModuleName {
      BeforeAll{
         # Outer $FunctionName not available within Pester InModuleScope block. Manually define for ease.
         # $FunctionName = 'Get-PanDevice'
         $SessionGuid = 'baab9aad-b846-4662-a6ab-c88e7347b84c'
         # Mock GetPanSessionGuid to always return our forged session guid
         Mock GetPanSessionGuid { return $SessionGuid }
         # Mock ImportPanDeviceDb and ExportPanDeviceDb to neuter them. We are not testing import and export functionality
         Mock ImportPanDeviceDb {}
         Mock ExportPanDeviceDb {}
         Mock Update-PanDeviceLocation {}

         $Global:PanDeviceDb = @()
         New-PanDevice -Name 'MyFirewall01' -Username 'xmlapiadmin' -Password 'asdf1234' -Label 'AngryBeaver' -ImportMode
         New-PanDevice -Name 'MyFirewall02' -Username 'xmlapiadmin' -Password 'jkl;5678' -Label 'DesignedByApprentices','BuiltWithPride' -ImportMode
         New-PanDevice -Name 'YourFirewall' -Username 'xmlapiadmin' -Password 'zxcv9012' -Label 'AngryBeaver',"session-$(GetPanSessionGuid)" -ImportMode
         New-PanDevice -Name 'TheirFirewall' -Username 'xmlapiadmin' -Password 'tyui4783' -Label 'AngryBeaver','BuiltWithPride',"session-$(GetPanSessionGuid)" -ImportMode
      }

      Context "Parameter Set: Empty" {
         It "$FunctionName with no LabelDefault" {
            Mock Get-PanDeviceLabelDefault { return @("session-$(GetPanSessionGuid)") }
            (Get-PanDevice).Name | Compare-Object -ReferenceObject @('YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName with single valid LabelDefault" {
            Mock Get-PanDeviceLabelDefault { return @('AngryBeaver') }
            (Get-PanDevice).Name | Compare-Object -ReferenceObject @('MyFirewall01','YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName with double valid LabelDefault" {
            Mock Get-PanDeviceLabelDefault { return @('AngryBeaver','BuiltWithPride') }
            (Get-PanDevice).Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName with invalid LabelDefault" {
            Mock Get-PanDeviceLabelDefault { return @('InvalidLabel') }
            (Get-PanDevice).Count | Should -Be 0
         }
      } # Context "Parameter Set: Empty"

      Context "Parameter Set: All" {
         It "$FunctionName All" {
         (Get-PanDevice -All).Count | Should -Be $Global:PanDeviceDb.Count
         }
      } # Context "Parameter Set: All"

      Context "Parameter Set: Filter" {
         It "$FunctionName -Session" {
            (Get-PanDevice -Session).Name | Compare-Object -ReferenceObject @('YourFirewall','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Session -Label 'BuiltWithPride'" {
            (Get-PanDevice -Session -Label 'BuiltWithPride').Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Session -Label 'AngryBeaver' -Name 'TheirFirewall'" {
            (Get-PanDevice -Session -Label 'AngryBeaver' -Name 'TheirFirewall').Name | Compare-Object -ReferenceObject @('TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'BuiltWithPride'" {
            (Get-PanDevice -Label 'BuiltWithPride').Name | Compare-Object -ReferenceObject @('MyFirewall02','TheirFirewall') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'InvalidLabel'" {
            (Get-PanDevice -Label 'InvalidLabel').Count | Should -Be 0
         }
         It "$FunctionName -Label 'DesignedByApprentices','BuiltWithPride'" {
            (Get-PanDevice -Label 'DesignedByApprentices','BuiltWithPride').Name | Compare-Object -ReferenceObject @('MyFirewall02') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Label 'AngryBeaver' -Name 'MyFirewall01'" {
            (Get-PanDevice -Label 'AngryBeaver' -Name 'MyFirewall01').Name | Compare-Object -ReferenceObject @('MyFirewall01') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Name 'MyFirewall01'" {
            (Get-PanDevice -Name 'MyFirewall01').Name | Compare-Object -ReferenceObject @('MyFirewall01') | Should -BeNullOrEmpty
         }
         It "$FunctionName -Name 'MyFirewall01','MyFirewall02'" {
            (Get-PanDevice -Name 'MyFirewall01','MyFirewall02').Name | Compare-Object -ReferenceObject @('MyFirewall01','MyFirewall02') | Should -BeNull
         }
         It "$FunctionName -Name 'InvalidName'" {
            $(Get-PanDevice -Name 'InvalidName').Count | Should -Be 0
         }
      } # Context "Parameter Set: Filter"
   } # InModuleScope
} # Describe
