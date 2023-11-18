#!/bin/bash
# Made by http://www.github.com/viruxe
#
# Usage: ./update-artifacts.sh ('recommended'/'optional'/'latest'/'critical')
# The 'latest' version will be downloaded if no argument is provided.

version=${1:-latest}

data=$(curl -s "https://changelogs-live.fivem.net/api/changelog/versions/linux/server")

if [ -z "$data" ]; then
    echo "Unable to Download changelog from cfx."
    exit 1
fi

versionNumber=$(echo $data | jq -r ".$version")
if [ "$versionNumber" == "null" ]; then
    echo "Unknown version. Try 'recommended'/'optional'/'latest'/'critical' instead."
    exit 1
fi

downloadURL=$(echo $data | jq -r ".${version}_download")
if [ "$downloadURL" == "null" ]; then
    echo "Unable to get download URL."
    exit 1
fi

txAdmin=$(echo $data | jq -r ".${version}_txadmin")
if [ "$txAdmin" == "null" ]; then
    txAdmin="Unknown"
fi

fileName=$(basename "$downloadURL")

echo "Downloading '$version' artifacts, version '$versionNumber' (txAdmin '$txAdmin')..."

curl -o "$fileName" -s "$downloadURL"

if [ ! -f "$fileName" ]; then
    echo "Unable to Download."
    exit 1
fi

echo "Extracting..."
tar xfJ "$fileName"
echo "Done."

rm "$fileName"
