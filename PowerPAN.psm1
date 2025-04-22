<#
Generic PowerShell Module Loading Framework for .psm1
Assumes:
   Classes placed in ./Class/*
      One class per .ps1 file.
      Class name same as .ps1 file: MyClass -> MyClass.ps1
      Classes are dot-sourced in alphanumeric filename order. To modify the class dot-source order and/or resolve dependency
      issues, add class filenames to $ClassDotSourceOrder, in desired order. $ClassDotSourceOrder filenames will be dot-sourced
      first, in specified order, before all remaining class filenames.
   Public (exported) functions/module members placed in ./Public/*
      One function per .ps1 file.
      Function name same as .ps1 file: Get-MyFunction -> Get-MyFunction.ps1
   Private (helper, NOT exported) functions/module members placed in ./Private/*
      One function per .ps1 file.
      Function name same as .ps1 file: Get-MyFunction -> Get-MyFunction.ps1
   Per convention, optional Pester test files are named <FunctionName>.Tests.ps1
      Pester test files are excluded (-Exclude) from dot-sourcing during module import to avoid Pester-inspired dot-sourcing loop
#>

# Determine class, public, and private function definition files and prepare them for dot-sourcing
# Exclude Pester .Tests.ps1 files to avoid a "Modules can only be nested to 10 levels" import / dot-sourcing loop during Pester tests
# See note above on $ClassDotSourceOrder and using it to resolve PowerShell class dot-source order dependency issues
$Class = @()
$ClassDotSourceOrder = @('Enum.ps1','PanDevice.ps1','PanResponse.ps1','PanObject.ps1')
foreach($ClassDotSourceOrderCur in $ClassDotSourceOrder) {
   $Class += Get-ChildItem -Path "$PSScriptRoot/Class" -Recurse -Include $ClassDotSourceOrderCur -ErrorAction SilentlyContinue
}
# Exclude classes already loaded. Exclude Pester test files
$Class  += @( Get-ChildItem -Path "$PSScriptRoot/Class/*.ps1" -Recurse -Exclude ($ClassDotSourceOrder + "*.Tests.ps1") -ErrorAction SilentlyContinue )

$Public  = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue )

# Dot source the .ps1 definition files
foreach($f in @($Class + $Public + $Private) ) {
    try {
        . $f.FullName
    }
    catch {
        Write-Error ("Failed to import $($f.FullName): $_")
    }
}

# As of 0.2.1 using Manifest FunctionsToExport() instead of Export-ModuleMember to aid module auto-load
# Export-ModuleMember -Function $Public.BaseName
