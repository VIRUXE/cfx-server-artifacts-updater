<?php
/*
	Made by http://www.github.com/viruxe
	
	Windows - an "artifacts" folder gets created
	Linux - will just extract the files onto the current working folder
	
	Usage: artifacts.php ('recommended'/'optional'/'latest'/'critical')
	The latest version will be downloaded if no argument is provided.
*/
$os      = strtoupper(substr(PHP_OS, 0, 3)) === 'WIN' ? "win32" : "linux";  // Detect Operating System to select which archive we should get
$version = $argv[1] ?? "latest";

print("Downloading Changelog for '$os'... ");

$data = file_get_contents("https://changelogs-live.fivem.net/api/changelog/versions/$os/server");

if ($data)
	print("Done.\n");
else
	die("Unable to Download.");

$changelog = json_decode($data, true);

$versionNumber = $changelog[$version] ?? die("Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead.");
$downloadURL   = $changelog["{$version}_download"] ?? die("Unable to get download URL.");
$txAdmin       = $changelog["{$version}_txadmin"] ?? "Unknown";
$fileName      = basename($downloadURL);

print("Downloading '$version' artifacts, version '$versionNumber' (txAdmin '$txAdmin')... ");

$file = file_get_contents($downloadURL);
if ($file) {
	print("Done.\nSaving... ");
	file_put_contents($fileName, $file);
	print("Done.\n");
} else
	die("Unable to Download.");

if($os === "win32") {
	$archive = new ZipArchive;
	
	print("Opening Archive... ");
	if ($archive->open($fileName)) {
		print("Done.\nExtracting... ");
		print(@$archive->extractTo("./artifacts/") ? "Done." : "Unable to extract. Is the server running?") . PHP_EOL;
		$archive->close();
	} else
		die("Unable to open.");
} else {
	$command = "tar xfJ $fileName";
	print("Executed '$command'. Verify the current working directory.\n");
	shell_exec($command);
}
unlink($fileName);