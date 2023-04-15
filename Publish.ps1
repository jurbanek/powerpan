# Publish.ps1 to be stored in the root of the module directory
# Inside the live-module directory, create Publish-NNNN\<module-name>\* structure for publishing
$Cfg = @{}
# Module Name must match .psd1/.psm1 file name
$Cfg.Add('ModuleName','PowerPAN')
# Should correspond to module directory given Publish.ps1 location
$Cfg.Add('Root',$PSScriptRoot)
# Temporary "Publish-NNNN" directory for storing files to be published
$Cfg.Add('TmpDirName',$('Publish-' + $(Get-Date -Format yyyyMMdd-HHmmss).ToString()))
# Combine the 
$Cfg.Add('TmpDirPath', (Join-Path $Cfg.Root $Cfg.TmpDirName))
$Cfg.Add('ExcludeRegEx',"$($Cfg.TmpDirName)|\.vscode|\.git")

# Create temporary unique directory for publishing, including directory that matches the module name
New-Item -Path $Cfg.Root -Name ($Cfg.TmpDirName + '/' + $Cfg.ModuleName) -ItemType Directory -Force -ErrorAction Stop | Out-Null

# Copy files in root only, no recurse
Get-ChildItem -Path $Cfg.Root -File | Where-Object {$_.FullName -notmatch $Cfg.ExcludeRegEx} | Copy-Item -Destination (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName)
# Copy sub-directories, with -Recurse on the Copy-Item
Get-ChildItem -Path $Cfg.Root -Directory | Where-Object {$_.FullName -notmatch $Cfg.ExcludeRegEx} | Copy-Item -Destination (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName) -Recurse

$NuGetApiKey = Read-Host -Prompt 'PowerShell Gallery API Key' -AsSecureString
Publish-Module -Path (Join-Path $Cfg.TmpDirPath $Cfg.ModuleName) -NuGetApiKey $(New-Object -TypeName PSCredential -ArgumentList 'user',$NuGetApiKey).GetNetworkCredential().Password -Verbose

Remove-Item -Path $Cfg.TmpDirPath -Recurse -Force
