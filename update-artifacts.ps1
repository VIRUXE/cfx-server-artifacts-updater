<#
	Made by http://www.github.com/viruxe
	
	Usage: .\update-artifacts.ps1 ('recommended'/'optional'/'latest'/'critical')
	The 'latest' version will be downloaded if no argument is provided.
#>

try {
	$originalProgressPreference = $ProgressPreference
	$ProgressPreference = 'SilentlyContinue'
	
	if ($args.Count -gt 0) {
		$version = $args[0]
	} else {
		$version = "latest"
	}
	
	try {
		$data = Invoke-WebRequest -Uri "https://changelogs-live.fivem.net/api/changelog/versions/win32/server" -UseBasicParsing
	} catch {
		throw "Error: Unable to download changelog data."
	}
	
	$changelog = $data.Content | ConvertFrom-Json
	$versionNumber = $changelog.$version
	
	if (-not $versionNumber) { 
		throw "Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead." 
	} else {
		$downloadURL = $changelog."${version}_download"
		
		if (-not $downloadURL) { 
			throw "Unable to get download URL." 
		} else {
			$txAdmin = $null
			if ($changelog."${version}_txadmin" -ne $null) {
				$txAdmin = $changelog."${version}_txadmin"
			} else {
				$txAdmin = "Unknown"
			}
			
			Write-Host "Downloading '$version' artifacts, version '$versionNumber' (txAdmin '$txAdmin')... "
			
			try {
				$file = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
			} catch {
				throw "Error: Unable to download the file."
			}
			
			if (-not $file) {
				throw "Error: Download failed or file is empty."
			} else {
				Write-Host "Done.`nSaving... "
				
				if ($file.Content.Length -gt 0) {
					$filePath = Join-Path -Path (Get-Location) -ChildPath "server.zip"
					[System.IO.File]::WriteAllBytes($filePath, $file.Content)
					Write-Host "File saved to $filePath"
					
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
						throw "Error: Downloaded file is missing or inaccessible."
					}
				} else {
					throw "Error: File downloaded is empty."
				}
			}
		}
	}
	
	$ProgressPreference = $originalProgressPreference
} catch {
	Write-Host "Error: An unexpected error occurred. $($_.Exception.Message)"
} finally {
	Write-Host
	Write-Host "Press any key to exit..."
	$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}