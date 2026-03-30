use anyhow::{Context, Result};
use clap::{Parser, ValueEnum};
use indicatif::{ProgressBar, ProgressStyle};
use reqwest::blocking::get;
use serde::Deserialize;
use std::fs::{self, File};
use std::io::{Read, Write, BufReader};
use tar::Archive;
use xz2::read::XzDecoder;

#[derive(Debug, Clone, ValueEnum)]
enum ReleaseType {
    Recommended,
    Optional,
    Latest,
    Critical,
}

impl Default for ReleaseType {
    fn default() -> Self {
        Self::Recommended
    }
}

impl std::fmt::Display for ReleaseType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", format!("{:?}", self).to_lowercase())
    }
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// The release type to download
    #[arg(value_enum, default_value_t = ReleaseType::Recommended)]
    release_type: ReleaseType,

    /// Force download and extraction even if the version is the same
    #[arg(short, long)]
    force: bool,

    /// Do not wait for user input at the end of the script
    #[arg(short, long)]
    yes: bool,
}

#[derive(Deserialize)]
struct Changelog {
    recommended: String,
    optional: String,
    latest: String,
    critical: String,
    recommended_download: String,
    optional_download: String,
    latest_download: String,
    critical_download: String,
    recommended_txadmin: Option<String>,
    optional_txadmin: Option<String>,
    latest_txadmin: Option<String>,
    critical_txadmin: Option<String>,
}

const VERSION_FILE: &str = ".artifacts_version";

fn get_installed_version() -> Option<String> {
    fs::read_to_string(VERSION_FILE).ok().map(|s| s.trim().to_string())
}

fn save_installed_version(version: &str) -> Result<()> {
    fs::write(VERSION_FILE, version).context("Failed to save version file")
}

fn download_file(url: &str, file_path: &str) -> Result<()> {
    let mut response = get(url).context("Failed to send request")?;
    let total_size = response.content_length();

    let pb = if let Some(size) = total_size {
        ProgressBar::new(size)
    } else {
        ProgressBar::new_spinner()
    };

    let style = if total_size.is_some() {
        ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})")
            .context("Failed to set progress bar style")?
            .progress_chars("#>-")
    } else {
        ProgressStyle::default_spinner()
            .template("{spinner:.green} [{elapsed_precise}] {bytes} downloaded")
            .context("Failed to set spinner style")?
    };

    pb.set_style(style);

    let mut file = File::create(file_path).context("Failed to create file")?;
    let mut buffer = [0; 8192];
    let mut downloaded = 0;

    while let Ok(n) = response.read(&mut buffer) {
        if n == 0 { break; }
        file.write_all(&buffer[..n]).context("Failed to write to file")?;
        downloaded += n as u64;
        pb.set_position(downloaded);
    }

    pb.finish_with_message("Download complete");
    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();
    let os = if cfg!(target_os = "windows") { "win32" } else { "linux" };

    println!("Fetching Changelog for '{}'...", os);

    let response = get(format!("https://changelogs-live.fivem.net/api/changelog/versions/{}/server", os))
        .context("Unable to download changelog data")?;
    let changelog: Changelog = response.json().context("Unable to parse JSON")?;

    let (version, download_url, txadmin_version) = match args.release_type {
        ReleaseType::Recommended => (&changelog.recommended, &changelog.recommended_download, &changelog.recommended_txadmin),
        ReleaseType::Optional => (&changelog.optional, &changelog.optional_download, &changelog.optional_txadmin),
        ReleaseType::Latest => (&changelog.latest, &changelog.latest_download, &changelog.latest_txadmin),
        ReleaseType::Critical => (&changelog.critical, &changelog.critical_download, &changelog.critical_txadmin),
    };

    let txadmin = txadmin_version.as_deref().unwrap_or("Unknown");

    println!("Target: '{}' (version '{}', txAdmin '{}')", args.release_type, version, txadmin);

    if !args.force {
        if let Some(installed) = get_installed_version() {
            if installed == *version {
                println!("Artifacts are already up to date (version '{}'). Use --force to re-download.", version);
                return finish(args.yes);
            }
        }
    }

    let is_windows = cfg!(target_os = "windows");
    let file_name = format!("artifacts.{}", if is_windows { "zip" } else { "tar.xz" });
    println!("Downloading from: {}", download_url);
    download_file(download_url, &file_name)?;

    println!("Extracting archive...");
    if is_windows {
        let file = File::open(&file_name).context("Unable to open archive file")?;
        let mut archive = zip::ZipArchive::new(file).context("Unable to read zip file")?;
        archive.extract("artifacts").context("Unable to extract zip archive.")?;
    } else {
        let tar_xz = File::open(&file_name).context("Unable to open archive file")?;
        let tar = XzDecoder::new(BufReader::new(tar_xz));
        let mut archive = Archive::new(tar);
        archive.unpack(".").context("Unable to extract tar.xz archive.")?;
    }

    save_installed_version(version)?;
    fs::remove_file(&file_name).context("Failed to delete the downloaded archive")?;

    println!("Artifacts updated successfully to version '{}'.", version);

    finish(args.yes)
}

fn finish(yes: bool) -> Result<()> {
    if !yes && (cfg!(target_os = "windows") || std::env::var("TERM").is_ok()) {
        println!("\nPress enter to terminate...");
        let mut input = String::new();
        let _ = std::io::stdin().read_line(&mut input);
    }
    Ok(())
}
