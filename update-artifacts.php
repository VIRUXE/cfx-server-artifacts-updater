<?php
/**
 * Made by http://www.github.com/viruxe
 * 
 * Requirements: openssl and zip extensions
 * 
 * Usage: php update-artifacts.php [recommended|optional|latest|critical] [--force]
 */

declare(strict_types=1);

final class ArtifactsUpdater
{
    private const string VERSION_FILE = ".artifacts_version";
    private readonly string $os;
    private readonly string $artifactsType;
    private readonly bool $force;
    private readonly bool $yes;

    public function __construct(array $argv)
    {
        $this->os = PHP_OS_FAMILY === 'Windows' ? 'win32' : 'linux';
        $this->force = in_array("--force", $argv, true) || in_array("-f", $argv, true);
        $this->yes = in_array("--yes", $argv, true) || in_array("-y", $argv, true);
        
        $type = "recommended";
        foreach (array_slice($argv, 1) as $arg) {
            if (!str_starts_with($arg, "-")) {
                $type = $arg;
                break;
            }
        }
        $this->artifactsType = $type;
    }

    public function run(): void
    {
        echo "Fetching Changelog for '{$this->os}'..." . PHP_EOL;
        $changelog = $this->fetchChangelog();

        $versionNumber = $changelog[$this->artifactsType] ?? $this->error("Unknown version type '{$this->artifactsType}'.");
        $txAdmin = $changelog["{$this->artifactsType}_txadmin"] ?? "Unknown";

        echo "Target: '{$this->artifactsType}' (version '{$versionNumber}', txAdmin '{$txAdmin}')" . PHP_EOL;

        if (!$this->force && $this->isAlreadyInstalled($versionNumber)) {
            echo "Artifacts are already up to date (version '{$versionNumber}'). Use --force to re-download." . PHP_EOL;
            $this->finish();
            return;
        }

        $downloadUrl = $changelog["{$this->artifactsType}_download"] ?? $this->error("Unable to get download URL.");
        $fileName = $this->os === 'win32' ? "artifacts.zip" : "artifacts.tar.xz";

        echo "Downloading from: {$downloadUrl}" . PHP_EOL;
        $this->download($downloadUrl, $fileName);

        echo "Extracting archive..." . PHP_EOL;
        $this->extract($fileName);
        
        file_put_contents(self::VERSION_FILE, $versionNumber);
        @unlink($fileName);

        echo "Artifacts updated successfully to version '{$versionNumber}'." . PHP_EOL;

        $this->finish();
    }

    private function fetchChangelog(): array
    {
        $url = "https://changelogs-live.fivem.net/api/changelog/versions/{$this->os}/server";
        $json = @file_get_contents($url);
        if (!$json) {
            $this->error("Unable to download changelog data from Cfx.re.");
        }
        return json_decode($json, true, 512, JSON_THROW_ON_ERROR);
    }

    private function isAlreadyInstalled(string $version): bool
    {
        if (!file_exists(self::VERSION_FILE)) {
            return false;
        }
        return trim((string)file_get_contents(self::VERSION_FILE)) === $version;
    }

    private function download(string $url, string $destination): void
    {
        $content = @file_get_contents($url);
        if (!$content) {
            $this->error("Failed to download artifacts from '{$url}'.");
        }
        file_put_contents($destination, $content);
    }

    private function extract(string $fileName): void
    {
        if ($this->os === 'win32') {
            $zip = new ZipArchive();
            if ($zip->open($fileName) === true) {
                if (!$zip->extractTo("./artifacts/")) {
                    $this->error("Unable to extract zip. Is the server running?");
                }
                $zip->close();
            } else {
                $this->error("Failed to open zip archive.");
            }
        } else {
            $command = "tar xfJ " . escapeshellarg($fileName);
            shell_exec($command);
        }
    }

    private function finish(): void
    {
        $isTty = $this->os === 'win32' || (function_exists('posix_isatty') && posix_isatty(STDIN));
        if (!$this->yes && $isTty) {
            echo PHP_EOL . "Press enter to terminate...";
            fgets(STDIN);
        }
    }

    private function error(string $message): never
    {
        fwrite(STDERR, "Error: {$message}" . PHP_EOL);
        exit(1);
    }
}

(new ArtifactsUpdater($argv))->run();
