#!/bin/bash
set -e

# Configuration
FFMPEG_REPO="https://github.com/FFmpeg/FFmpeg.git"
FFMPEG_TAG="n6.1"
WORK_DIR="ffmpeg_build"
PATCH_FILE="../patches/0001-Add-Rig-Mode-implementation.patch"

echo "=== Starting FFmpeg Build with V360 Rig Mode Extension ==="

# Check requirements
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed"
    exit 1
fi

# Create build directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone FFmpeg if not exists
if [ ! -d "FFmpeg" ]; then
    echo "Cloning FFmpeg ($FFMPEG_TAG)..."
    git clone --depth 1 --branch "$FFMPEG_TAG" "$FFMPEG_REPO" FFmpeg
else
    echo "FFmpeg directory exists, skipping clone."
fi

cd FFmpeg

# Apply patch
echo "Applying custom patches..."
# Reset to clean state just in case
git reset --hard HEAD
git clean -fd

if git am "$PATCH_FILE"; then
    echo "Patch applied successfully."
else
    echo "Error applying patch. Attempting manual file copy..."
    git am --abort || true
    cp ../../src/vf_v360.c libavfilter/
    cp ../../src/v360.h libavfilter/
    echo "Files copied manually."
fi

# Configure
echo "Configuring build..."
./configure \
    --prefix="$PWD/../build_output" \
    --enable-gpl \
    --enable-version3 \
    --enable-libx264 \
    --enable-filter=v360 \
    --disable-doc \
    --disable-ffplay \
    --disable-ffprobe

# Build
echo "Building... (This may take a while)"
make -j$(nproc)

echo "=== Build Complete! ==="
echo "Binary location: $PWD/ffmpeg"
