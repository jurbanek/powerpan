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
        BeforeAll {
            Mock ImportPanDeviceDb {}
            Mock ExportPanDeviceDb {}    
            Mock Update-PanDeviceLocation {}
            $D = New-PanDevice -Name "MyDevice" -Username "myuser" -Password "Fake1234" -ImportMode -NoPersist
            $D.Location.Add('shared', "/config/shared")
            $D.Location.Add('vsys1', "/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']")
        }
        
        Context "Construct-PanAddress" {
            It "Default Address Type" {
                $O = Construct-PanAddress -Device $D -Location 'shared' -Name 'MyAddress'
                $O.Type | Should -BeExactly 'ip-netmask'
                $O.XDoc.Item('entry').Item('ip-netmask').Count | Should -BeExactly 1
            }
            It "Change Address Type" {
                $O = Construct-PanAddress -Device $D -Location 'shared' -Name 'MyAddress'
                $O.Type = 'fqdn'
                $O.Value = 'test.acme.com'
                
                $O.Type | Should -BeExactly 'fqdn'
                $O.XDoc.Item('entry').Item('fqdn').Count | Should -BeExactly 1
                $O.Value | Should -BeExactly 'test.acme.com'
                $O.XDoc.Item('entry').Item('fqdn').InnerText | Should -BeExactly 'test.acme.com'
            }
            It "Tag" {
                $O = Construct-PanAddress -Device $D -Location 'shared' -Name 'MyAddress'
                $O.Tag = @('review','risky')

                # Add tags
                $O.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').Count | Should -BeExactly 2
                $O.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').InnerText | Should -BeExactly @('review','risky')

                # Remove tags
                $O.Tag = @()
                $O.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').Count | Should -BeExactly 0
                $O.XDoc.Item('entry').Item('tag').GetElementsByTagName('member').InnerText | Should -BeNullOrEmpty
            }
        }
    }
}