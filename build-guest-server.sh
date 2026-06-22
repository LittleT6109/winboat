#!/bin/bash
set -e

echo "Building guest server..."

# Variables
export GOOS=windows
export PACKAGE=winboat-server
export VERSION="$(bun -p "require('./package.json').version")"
export COMMIT_HASH="$(git rev-parse --short HEAD)"
export BUILD_TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
export LDFLAGS=(
  "-X 'main.Version=${VERSION}'"
  "-X 'main.CommitHash=${COMMIT_HASH}'"
  "-X 'main.BuildTimestamp=${BUILD_TIMESTAMP}'"
)

echo "Version: ${VERSION}"
echo "Commit Hash: ${COMMIT_HASH}"
echo "Build Timestamp: ${BUILD_TIMESTAMP}"

# Enter build directory
cd guest_server

# Verify nssm.exe integrity
echo "Verifying nssm.exe integrity..."
if [ -f "nssm.exe" ] && [ -f "nssm.sha1.txt" ]; then
    COMPUTED_HASH=$(sha1sum nssm.exe | cut -d' ' -f1)
    EXPECTED_HASH=$(cat nssm.sha1.txt | tr -d '[:space:]')
    
    if [ "$COMPUTED_HASH" = "$EXPECTED_HASH" ]; then
        echo "✓ nssm.exe integrity verified (SHA-1: $COMPUTED_HASH)"
    else
        echo "✗ nssm.exe integrity check FAILED!"
        echo "  Expected: $EXPECTED_HASH"
        echo "  Computed: $COMPUTED_HASH"
        exit 1
    fi
else
    echo "⚠ Warning: nssm.exe or nssm.sha1.txt not found, skipping integrity check"
fi

build_arch() {
    local go_arch="$1"
    local package_arch="$2"
    local zip_name="winboat_guest_server_${package_arch}.zip"

    echo "Building guest server for ${package_arch}..."

    export GOARCH="$go_arch"
    go build -ldflags="${LDFLAGS[*]}" -o winboat_guest_server.exe *.go

    rm -f "$zip_name"
    zip -r "$zip_name" . -x "winboat_guest_server_*.zip"

    echo "Guest server built: guest_server/${zip_name}"
}

build_arch "amd64" "x64"
build_arch "arm64" "arm64"

echo "Guest server builds complete."
