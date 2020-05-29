<#
Generic PowerShell Module Loading Framework for .psm1
Assumes:
   Classes placed in .\Classes\*
      One class per .ps1 file.
      Class name same as .ps1 file: MyClass -> MyClass.ps1
   Public (exported) functions/module members placed in .\Public\*
      One function per .ps1 file.
      Function name same as .ps1 file: Get-MyFunction -> Get-MyFunction.ps1
   Private (helper, NOT exported) functions/module members placed in .\Private\*
      One function per .ps1 file.
      Function name same as .ps1 file: Get-MyFunction -> Get-MyFunction.ps1
   Per convention, optional Pester test files are named <FunctionName>.Tests.ps1
      Pester test files are excluded (-Exclude) from dot-sourcing during module import to avoid Pester-inspired dot-sourcing loop
#>

# Determine class, public, and private function definition files 
# Exclude Pester .Tests.ps1 files to avoid a "Modules can only be nested to 10 levels" import / dot-sourcing loop during Pester tests
$Classes  = @( Get-ChildItem -Path "$PSScriptRoot\Classes\*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue )
$Public  = @( Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue )

# Dot source the .ps1 definition files
foreach($f in @($Classes + $Public + $Private) ) {
    try {
        . $f.FullName
    }
    catch {
        Write-Error ("Failed to import $($f.FullName): $_")
    }
}

# Export the public functions/module members only
Export-ModuleMember -Function $Public.BaseName

# Export the private functions/module members only. For testing only.
Export-ModuleMember -Function $Private.BaseName