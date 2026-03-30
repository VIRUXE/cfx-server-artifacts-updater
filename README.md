# Cfx.re _Server Artifacts_ Updater

![image](https://github.com/VIRUXE/cfx-server-artifacts-updater/assets/1616657/f88ad1a5-fb0b-409a-827e-467b9f5f5449)

A bundle of scripts to easily update your _[Cfx.re](https://cfx.re)_ (FiveM/RedM) server artifacts.

This project provides multiple ways to update your server: **Rust**, **PHP**, **PowerShell**, and **Shell**.

## Features

- **Version Tracking**: Automatically checks if you already have the requested version installed to avoid unnecessary downloads.
- **Progress Bar**: Shows download progress (supported in Rust, Shell, and PowerShell).
- **txAdmin Reporting**: Displays the txAdmin version included in the artifacts.
- **Cross-Platform**: Support for both Windows and Linux.

## Usage

The usage is consistent across all scripts:
`./file.extension [recommended|optional|latest|critical] [--force]`

- **Default**: `recommended`
- **--force / -f**: Force download and extraction even if the version is already up to date.

### Rust (Recommended)
```bash
# Build and run
cargo run -- recommended
```

### Shell
```bash
./update-artifacts.sh recommended
```

### PHP
```bash
php update-artifacts.php latest
```

### PowerShell
```powershell
.\update-artifacts.ps1 critical
```

## Recommended Directory Structure

Just leave one of these scripts outside of your artifacts folder, that you _should_ be using for all your servers.

- fivem
  - **update-artifacts.ext**
  - run.sh (linux-only)
  - artifacts/[alpine (linux-only)] (the name of the directory that contains the artifacts that all the servers run on)
  - server
  - server1
  - server2
