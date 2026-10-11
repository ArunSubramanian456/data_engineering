#!/usr/bin/env bash

set -euo pipefail

YEARS=(2024)
MONTHS=({01..12})
TAXI_TYPES=(yellow green)
BASE_URL="https://d37ci6vzurychx.cloudfront.net"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd )"
TARGET_DIR="$REPO_ROOT/data/raw"

failed=0

# download URL to TARGET_FILE via a .part file, so an interrupted run never leaves a truncated file behind
download() {
    local url="$1"
    local target_file="$2"
    local file_name part_file
    file_name="$(basename "$target_file")"
    part_file="${target_file}.part"

    if [[ -f "$target_file" ]]; then
        echo "$file_name already exists. Skipping download."
        return
    fi

    echo "Downloading $file_name..."
    if curl --retry 3 --retry-delay 2 -fSL --progress-bar "$url" -o "$part_file"; then
        mv "$part_file" "$target_file"
        echo "$file_name saved to $target_file"
    else
        echo "Failed to download $file_name. Please check the URL or your internet connection." >&2
        rm -f "$part_file"
        failed=$((failed + 1))
    fi
}

mkdir -p "$TARGET_DIR"

for taxi in "${TAXI_TYPES[@]}"; do
    for year in "${YEARS[@]}"; do
        for month in "${MONTHS[@]}"; do
            file_name="${taxi}_tripdata_${year}-${month}.parquet"
            download "${BASE_URL}/trip-data/${file_name}" "${TARGET_DIR}/${file_name}"
        done
    done
done

download "${BASE_URL}/misc/taxi_zone_lookup.csv" "${TARGET_DIR}/taxi_zone_lookup.csv"

if (( failed > 0 )); then
    echo "$failed download(s) failed." >&2
    exit 1
fi
