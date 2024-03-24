<#
    Made by http://www.github.com/viruxe
    
    Usage: .\update-artifacts.ps1 ('recommended'/'optional'/'latest'/'critical')
    The 'latest' version will be downloaded if no argument is provided.
#>

$originalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

$version = $args.Count -gt 0 ? $args[0] : "latest"

try {
    $data = Invoke-WebRequest -Uri "https://changelogs-live.fivem.net/api/changelog/versions/win32/server" -UseBasicParsing
} catch {
    Write-Host "Error: Unable to download changelog data."
    exit
}

$changelog = $data.Content | ConvertFrom-Json
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

$txAdmin = $changelog."${version}_txadmin" -ne $null ? $changelog."${version}_txadmin" : "Unknown"

Write-Host "Downloading '$version' artifacts, version '$versionNumber' (txAdmin '$txAdmin')... "

try {
    $file = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
} catch {
    Write-Host "Error: Unable to download the file."
    exit
}

if (-not $file) {
    Write-Host "Error: Download failed or file is empty."
    exit
}

Write-Host "Done.`nSaving... "
if ($file.Content.Length -gt 0) {
    $filePath = Join-Path -Path (Get-Location) -ChildPath "server.zip"
    [System.IO.File]::WriteAllBytes($filePath, $file.Content)
    Write-Host "File saved to $filePath"
} else {
    Write-Host "Error: File downloaded is empty."
    exit
}

$filePath = Join-Path -Path (Get-Location) -ChildPath "server.zip"
if (Test-Path $filePath) {
    Write-Host "Extracting... "
    $extractPath = Join-Path -Path (Get-Location) -ChildPath "artifacts\"

    if (-not (Test-Path $extractPath)) {
        Write-Host "Creating artifacts directory..."
        New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    }

    Expand-Archive -LiteralPath $filePath -DestinationPath $extractPath -Force
    Write-Host "Extraction complete."
    Remove-Item $filePath -Force
} else {
    Write-Host "Error: Downloaded file is missing or inaccessible."
    exit
}

$ProgressPreference = $originalProgressPreference

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
