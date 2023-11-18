<#
    Made by http://www.github.com/viruxe
    
    Usage: .\update-artifacts.ps1 ('recommended'/'optional'/'latest'/'critical')
    The 'latest' version will be downloaded if no argument is provided.
#>

$originalProgressPreference = $ProgressPreference
$ProgressPreference         = 'SilentlyContinue'

$version = if ($args.Count -gt 0) { $args[0] } else { "latest" }

try {
    $data = Invoke-WebRequest -Uri "https://changelogs-live.fivem.net/api/changelog/versions/win32/server" -UseBasicParsing
} catch {
    Write-Host "Error: Unable to download changelog data."
    exit
}

$changelog     = $data.Content | ConvertFrom-Json
$versionNumber = $changelog.$version

if (-not $versionNumber) { 
    Write-Host "Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead." 
    exit
}

$downloadURL = $changelog."${version}_download"
if (-not $downloadURL) { 
    Write-Host "Unable to get download URL." 
    exit
}

$txAdmin = $changelog."${version}_txadmin"
if (-not $txAdmin) { $txAdmin = "Unknown" }

Write-Host "Downloading '$version' artifacts, version '$versionNumber' (txAdmin '$txAdmin')... "

try {
    $file = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
} catch {
    Write-Host "Error: Unable to download the file."
    exit
}

$fileName = [System.IO.Path]::GetFileName($downloadURL)

if (-not $file) {
    Write-Host "Error: Download failed or file is empty."
    exit
}

Write-Host "Done.`nSaving... "
[System.IO.File]::WriteAllBytes($fileName, $file.Content)
Write-Host "Done."

Write-Host "Opening Archive... "
if (Test-Path $fileName) {
    Write-Host "Done.`nExtracting... "
    $extractPath = "./artifacts/"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-Archive -LiteralPath $fileName -DestinationPath $extractPath -Force
    Write-Host "Done."
} else {
    Write-Host "Error: Downloaded file is missing or inaccessible."
    exit
}
Remove-Item $fileName

$ProgressPreference = $originalProgressPreference

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
