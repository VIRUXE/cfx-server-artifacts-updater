#!/usr/bin/env bash

# Made by http://www.github.com/viruxe
# Usage: ./update-artifacts.sh [recommended|optional|latest|critical] [--force] [--yes]

set -euo pipefail

VERSION_FILE=".artifacts_version"
FORCE=false
YES=false
RELEASE_TYPE="recommended"

# Improved argument parsing
for arg in "$@"; do
    case "$arg" in
        --force|-f)
            FORCE=true
            ;;
        --yes|-y)
            YES=true
            ;;
        -*)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
        *)
            RELEASE_TYPE="$arg"
            ;;
    esac
done

echo "Fetching Changelog for 'linux'..."
DATA=$(curl -sfL "https://changelogs-live.fivem.net/api/changelog/versions/linux/server")

if [[ -z "$DATA" ]]; then
    echo "Error: Unable to download changelog from Cfx.re." >&2
    exit 1
fi

VERSION_NUMBER=$(echo "$DATA" | jq -r ".$RELEASE_TYPE")
if [[ "$VERSION_NUMBER" == "null" ]]; then
    echo "Error: Unknown release type '$RELEASE_TYPE'." >&2
    exit 1
fi

DOWNLOAD_URL=$(echo "$DATA" | jq -r ".${RELEASE_TYPE}_download")
TX_ADMIN=$(echo "$DATA" | jq -r ".${RELEASE_TYPE}_txadmin // \"Unknown\"")

echo "Target: '$RELEASE_TYPE' (version '$VERSION_NUMBER', txAdmin '$TX_ADMIN')"

if [[ "$FORCE" == false ]] && [[ -f "$VERSION_FILE" ]]; then
    INSTALLED=$(cat "$VERSION_FILE")
    if [[ "$INSTALLED" == "$VERSION_NUMBER" ]]; then
        echo "Artifacts are already up to date (version '$VERSION_NUMBER'). Use --force to re-download."
        if [[ "$YES" == false ]] && [[ -t 0 ]]; then
            echo -e "\nPress enter to terminate..."
            read -r
        fi
        exit 0
    fi
fi

FILE_NAME="artifacts.tar.xz"
echo "Downloading from: $DOWNLOAD_URL"

if ! curl -L -o "$FILE_NAME" -# "$DOWNLOAD_URL"; then
    echo "Error: Failed to download artifacts." >&2
    exit 1
fi

echo "Extracting archive..."
if ! tar xfJ "$FILE_NAME"; then
    echo "Error: Failed to extract artifacts." >&2
    rm -f "$FILE_NAME"
    exit 1
fi

echo "$VERSION_NUMBER" > "$VERSION_FILE"
rm -f "$FILE_NAME"

echo "Artifacts updated successfully to version '$VERSION_NUMBER'."

if [[ "$YES" == false ]] && [[ -t 0 ]]; then
    echo -e "\nPress enter to terminate..."
    read -r
fi
