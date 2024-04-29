# Cfx.re _Server Artifacts_ Updater

![image](https://github.com/VIRUXE/cfx-server-artifacts-updater/assets/1616657/f88ad1a5-fb0b-409a-827e-467b9f5f5449)

A bundle of scripts to easily update your _[Cfx.re](https://cfx.re)_ (FiveM/RedM) server artifacts.

This was formerly just a PHP script but since not everyone has PHP installed on their systems I decided to convert to PowerShell and Shell.

The usage is the same in any script: `./file.extension (recommended/optional/[latest]/critical)` with the default for no version argument passed being "latest"

Just leave one of these scripts outside of your artifacts folder, that you _should_ be using for all your servers.

Example directory structure:

- fivem
  - **update-artifacts.ext**
  - run.sh (linux-only)
  - artifacts/[alpine (linux-only)] (the name of the directory that contains the artifacts that all the servers run on)
  - server
  - server1
  - server2
