<#
Publish.ps1 to be stored in the root of the module directory
Process
- Refresh/update manifest (.psd1) @FunctionsToExport()
- Inside the live-module directory, create Publish-NNNN\<module-name>\* structure for publishing
- Copy necessary files
- Publish to PSGallery, prompting for PSGallery API key
- Cleanup Publish-NNNN
#>

$Cfg = @{}
# Module Name must match .psd1/.psm1 file name
$Cfg.Add('ModuleName','PowerPAN')
# Should correspond to module directory given Publish.ps1 location
$Cfg.Add('Root',$PSScriptRoot)
# Temporary "Publish-NNNN" directory for storing files to be published
$Cfg.Add('TmpDirName',$('Publish-' + $(Get-Date -Format yyyyMMdd-HHmmss).ToString()))
$Cfg.Add('TmpDirPath', (Join-Path $Cfg.Root $Cfg.TmpDirName))
# Excluding the temporary directory intself, Pester tests, vscode, git, Mac related
$Cfg.Add('ExcludeRegEx',"$($Cfg.TmpDirName)|TestPowerPAN\.ps1|\.Tests\.ps1|\.vscode|\.git|\.DS_Store")
# Initialize, to be populated
$Cfg.Add('FunctionsToExport',@())
$Cfg.Add('FormatsToProcess',@())

<#*************************************
* UPDATE Manifest FunctionstoExport() *
*************************************#>
# Get all Public function files, one function per file, filename matches function name, update the manifest
foreach($File in Get-ChildItem -Path "$($Cfg.Root)/Public/*.ps1" -Recurse -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue) {
   $Cfg.FunctionsToExport += $File.BaseName
}
Update-ModuleManifest -Path "$($Cfg.Root)/$($Cfg.ModuleName).psd1" -FunctionsToExport $Cfg.FunctionsToExport

<#*************************************
* UPDATE Manifest FormatsToProcess() *
*************************************#>
# Get all Formats within Format/*, one per file, update the manifest to include relative path "Format/File.Format.ps1xml"
foreach($File in Get-ChildItem -Path "$($Cfg.Root)/Format/*.ps1xml" -Recurse -ErrorAction SilentlyContinue) {
   $Cfg.FormatsToProcess += "Format/$($File.Name)"
}
Update-ModuleManifest -Path "$($Cfg.Root)/$($Cfg.ModuleName).psd1" -FormatsToProcess $Cfg.FormatsToProcess

<#***********************
* CLONE TO Publish-NNNN *
***********************#>
# Create temporary unique directory for publishing, including directory that matches the module name
New-Item -Path $Cfg.Root -Name "$($Cfg.TmpDirName)/$($Cfg.ModuleName)" -ItemType Directory -Force -ErrorAction Stop | Out-Null

# Copy files in root only, no recurse
Get-ChildItem -Path $Cfg.Root -File | Where-Object {$_.FullName -notmatch $Cfg.ExcludeRegEx} | Copy-Item -Destination (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName)
# Copy sub-directories, with -Recurse on the Copy-Item
Get-ChildItem -Path $Cfg.Root -Directory | Where-Object {$_.FullName -notmatch $Cfg.ExcludeRegEx} | Copy-Item -Destination (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName) -Recurse

<#**********************
* PUBLISH to PSGallery *
**********************#>
$NuGetApiKey = Read-Host -Prompt 'PowerShell Gallery API Key' -AsSecureString
Publish-Module -Path (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName) -NuGetApiKey $(New-Object -TypeName PSCredential -ArgumentList 'user',$NuGetApiKey).GetNetworkCredential().Password -Verbose

<#**********************
* CLEANUP Publish-NNNN *
**********************#>
Remove-Item -Path $Cfg.TmpDirPath -Recurse -Force
