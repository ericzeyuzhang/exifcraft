#!/bin/bash

# This script packages the Lightroom plugin by assembling all necessary files.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Packaging ExifCraft Lightroom Plugin..."

# Define paths
ROOT_DIR=$(pwd)
PLUGIN_PACKAGE_DIR=$ROOT_DIR/packages/lightroom-plugin
PLUGIN_SRC_DIR=$PLUGIN_PACKAGE_DIR/src
CLI_BUILD_DIR=$ROOT_DIR/packages/cli/dist/bin
OUTPUT_DIR=$PLUGIN_PACKAGE_DIR/ExifCraft.lrplugin
OUTPUT_BIN_DIR=$OUTPUT_DIR/bin

# 1. Clean up previous build
echo "Cleaning up old build..."
rm -rf "$OUTPUT_DIR"

# 2. Create plugin directory structure
echo "Creating plugin directory structure..."
mkdir -p "$OUTPUT_BIN_DIR"

# 3. Copy Lua files from src
echo "Copying Lua files from src directory..."
cp "$PLUGIN_SRC_DIR/Info.lua" "$OUTPUT_DIR/"
cp "$PLUGIN_SRC_DIR/Init.lua" "$OUTPUT_DIR/"
cp "$PLUGIN_SRC_DIR/Process.lua" "$OUTPUT_DIR/"
cp "$PLUGIN_SRC_DIR/Settings.lua" "$OUTPUT_DIR/"

# 4. Copy CLI executables
echo "Copying CLI executables..."
cp "$CLI_BUILD_DIR/exifcraft-cli-macos" "$OUTPUT_BIN_DIR/exifcraft-macos"
cp "$CLI_BUILD_DIR/exifcraft-cli-win.exe" "$OUTPUT_BIN_DIR/exifcraft-win.exe"

# 5. Set executable permissions
chmod +x "$OUTPUT_BIN_DIR/exifcraft-macos"

echo "
Plugin packaged successfully at: $OUTPUT_DIR
"
