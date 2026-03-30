<#
	Made by http://www.github.com/viruxe
	
	Usage: .\update-artifacts.ps1 ('recommended'/'optional'/'latest'/'critical') [-Force]
	The 'latest' version will be downloaded if no argument is provided.
#>

Param(
    [Parameter(Position=0)]
    [ValidateSet("recommended", "optional", "latest", "critical")]
    [string]$Version = "recommended",

    [switch]$Force,
    
    [switch]$Yes
)

try {
	$originalProgressPreference = $ProgressPreference
	$ProgressPreference = 'SilentlyContinue'
	$versionFile = ".artifacts_version"
	
    Write-Host "Fetching Changelog for 'win32'..."
	try {
		$data = Invoke-WebRequest -Uri "https://changelogs-live.fivem.net/api/changelog/versions/win32/server" -UseBasicParsing
	} catch {
		throw "Error: Unable to download changelog data."
	}
	
	$changelog = $data.Content | ConvertFrom-Json
	$versionNumber = $changelog.$Version
	
	if (-not $versionNumber) { 
		throw "Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead." 
	}

    $downloadURL = $changelog."${Version}_download"
    $txAdmin = if ($null -ne $changelog."${Version}_txadmin") { $changelog."${Version}_txadmin" } else { "Unknown" }
    
    Write-Host "Target: '$Version' (version '$versionNumber', txAdmin '$txAdmin')"

    if (-not $Force -and (Test-Path $versionFile)) {
        $installed = Get-Content $versionFile -Raw
        if ($installed -eq $versionNumber) {
            Write-Host "Artifacts are already up to date (version '$versionNumber'). Use -Force to re-download."
            if (-not $Yes) {
                Write-Host "`nPress enter to terminate..."
                [void][System.Console]::ReadLine()
            }
            return
        }
    }
    
    if (-not $downloadURL) { 
        throw "Unable to get download URL." 
    }
    
    Write-Host "Downloading from: $downloadURL"
    
    try {
        $filePath = Join-Path -Path (Get-Location) -ChildPath "artifacts.zip"
        Invoke-WebRequest -Uri $downloadURL -OutFile $filePath -UseBasicParsing
    } catch {
        throw "Error: Unable to download the file."
    }

    Write-Host "Extracting archive..."
    
    $extractPath = Join-Path -Path (Get-Location) -ChildPath "artifacts\"

    if (-not (Test-Path $extractPath)) {
        New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    }

    Expand-Archive -LiteralPath $filePath -DestinationPath $extractPath -Force
    Remove-Item $filePath -Force
    Set-Content -Path $versionFile -Value $versionNumber
	
	Write-Host "Artifacts updated successfully to version '$versionNumber'."
} catch {
	Write-Error "Error: An unexpected error occurred. $($_.Exception.Message)"
} finally {
	$ProgressPreference = $originalProgressPreference
    if (-not $Yes) {
        Write-Host "`nPress enter to terminate..."
        [void][System.Console]::ReadLine()
    }
}
