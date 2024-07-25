use reqwest::blocking::get;
use serde::Deserialize;
use std::env;
use std::fs::File;
use std::io::{Read, Write};
use std::process::Command;
use indicatif::{ProgressBar, ProgressStyle};

#[derive(Deserialize)]
struct Changelog {
    recommended         : String,
    optional            : String,
    latest              : String,
    critical            : String,
    recommended_download: String,
    optional_download   : String,
    latest_download     : String,
    critical_download   : String,
    recommended_txadmin : Option<String>,
    optional_txadmin    : Option<String>,
    latest_txadmin      : Option<String>,
    critical_txadmin    : Option<String>
}

const RELEASE_TYPES: [&str; 4] = ["recommended", "optional", "latest", "critical"];

fn check_release_type(release_type: &str) -> bool { RELEASE_TYPES.contains(&release_type) }

fn download_file(url: &str, file_path: &str) -> bool {
    let mut response = match get(url) {
        Ok(res) => res,
        Err(_) => return false,
    };

    let total_size = match response.content_length() {
        Some(size) => size,
        None => return false,
    };

    let pb = ProgressBar::new(total_size);
    pb.set_style(
        match ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})") {
                Ok(style) => style.progress_chars("#>-"),
                Err(err) => {
                    eprintln!("Failed to set progress bar style: {}", err);
                    return false;
                }
            }
    );

    let mut file = match File::create(file_path) { Ok(f) => f, Err(_) => return false };

    let mut buffer = [0; 8192];
    let mut downloaded = 0;

    while let Ok(n) = response.read(&mut buffer) {
        if n == 0 { break; }
        if file.write_all(&buffer[..n]).is_err() { return false; }

        downloaded += n as u64;
        pb.set_position(downloaded);
    }

    pb.finish_with_message("Download complete");
    true
}

fn main() {
    let os = if cfg!(target_os = "windows") { "win32" } else { "linux" };

    println!("Downloading Changelog for '{}'", os);

    let response = get(format!("https://changelogs-live.fivem.net/api/changelog/versions/{}/server", os)).expect("Unable to download changelog data");
    let changelog: Changelog = response.json().expect("Unable to parse JSON");

    let args: Vec<String> = env::args().collect();
    let release_type = if args.len() < 2 {
        println!("Usage: {} <release_type>", args[0]);
        println!("Available release types: {}", RELEASE_TYPES.join(", "));

        loop {
            println!("\nPlease enter the release type (or press Enter to use the default 'latest'):");
            let mut input = String::new();
            std::io::stdin().read_line(&mut input).unwrap();
            let input = input.trim().to_string();

            if input.is_empty() { 
                break "latest".to_string(); 
            } else if check_release_type(&input) {
                break input;
            }
        }
    } else {
        args[1].clone()
    };

    let artifacts_version = match release_type.as_str() {
        "recommended" => &changelog.recommended,
        "optional"    => &changelog.optional,
        "latest"      => &changelog.latest,
        "critical"    => &changelog.critical,
        _             => panic!("Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead."),
    };

    let download_url = match release_type.as_str() {
        "recommended" => &changelog.recommended_download,
        "optional"    => &changelog.optional_download,
        "latest"      => &changelog.latest_download,
        "critical"    => &changelog.critical_download,
        _             => panic!("Unable to get download URL."),
    };

    let txadmin_version = match release_type.as_str() {
        "recommended" => &changelog.recommended_txadmin,
        "optional"    => &changelog.optional_txadmin,
        "latest"      => &changelog.latest_txadmin,
        "critical"    => &changelog.critical_txadmin,
        _             => &None,
    }.as_deref().unwrap_or("Unknown");

    println!("Downloading '{}' artifacts, version '{}' (txAdmin '{}')...", release_type, artifacts_version, txadmin_version);

    let file_name = format!("artifacts.{}", if cfg!(target_os = "windows") { "zip" } else { "tar.xz" });
    if !download_file(download_url, &file_name) {
        println!("Failed to download the artifacts. Aborting...");
        return;
    }

    let mut existing = false;

    println!("Extracting archive...");
    if cfg!(target_os = "windows") {
        if std::fs::metadata("artifacts").is_ok() { existing = true; }

        let mut archive = zip::ZipArchive::new(File::open(&file_name).expect("Unable to open file")).expect("Unable to read zip file");

        // We'll extract the files onto the "artifacts" directory to keep things tidy
        archive.extract("artifacts").expect("Unable to extract files from archive.");
    } else {
        if std::fs::metadata("alpine").is_ok() && std::fs::metadata("run.sh").is_ok() { existing = true; }

        Command::new("tar")
            .args(&["xfJ", &file_name])
            .status()
            .expect("Failed to execute tar command to extract files.");
    }

    println!("{}", if existing {"Artifacts already exist. So they have been overwritten."} else {"Artifacts extracted successfully."});
    
    std::fs::remove_file(&file_name).expect("Failed to delete the downloaded archive. Remove it manually, if you'd like.");

    println!("\nPress enter to terminate...");
    let mut input = String::new();
    std::io::stdin().read_line(&mut input).unwrap();
}
