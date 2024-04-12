<?php
/*
	Made by http://www.github.com/viruxe

	Requirements: openssl and zip extensions
	
	Windows - an "artifacts" folder gets created
	Linux - will just extract the files onto the current working folder
	
	Usage: artifacts.php ('recommended'/'optional'/'latest'/'critical')
	The latest version will be downloaded if no argument is provided.
*/
$os = PHP_OS_FAMILY === 'Windows' ? 'win32' : 'linux';

print("Downloading Changelog for '$os'... ");

$changelogManifestJson = file_get_contents("https://changelogs-live.fivem.net/api/changelog/versions/$os/server");
	
if($changelogManifestJson) print("Done.\n"); else die("Unable to Download.");

$changelog = json_decode($changelogManifestJson, true);
	
$artifactsType = $argv[1] ?? "latest";
$versionNumber = $changelog[$artifactsType] ?? die("Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead.");
$downloadURL   = $changelog["{$artifactsType}_download"] ?? die("Unable to get download URL.");
$txAdmin       = $changelog["{$artifactsType}_txadmin"] ?? "Unknown";
$fileName      = basename($downloadURL);

print("Downloading '$artifactsType' artifacts, version '$versionNumber' (txAdmin '$txAdmin')... ");

$fileContents = file_get_contents($downloadURL);

if($fileContents) {
	print("Done.\nSaving... ");
	file_put_contents($fileName, $fileContents);
	print("Done.\n");
} else
	die("Unable to Download.");

if($os === "win32") {
	$archive = new ZipArchive;
	
	print("Opening Archive... ");
	if($archive->open($fileName)) {
		print("Done.\nExtracting... ");
		print(@$archive->extractTo("./artifacts/") ? "Done." : "Unable to extract. Is the server running?") . PHP_EOL;
		$archive->close();
	} else
		die("Unable to open.");
} else {
	$command = "tar xfJ $fileName";
	shell_exec($command);
	print("Executed '$command'. Verify the current working directory.\n");
}