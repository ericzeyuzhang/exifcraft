#!/bin/bash

# Package ExifCraft Lightroom Plugin
# This script creates a distributable package of the plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/ExifCraft.lrplugin"
DIST_DIR="$SCRIPT_DIR/dist"

echo "=== Packaging ExifCraft Lightroom Plugin ==="
echo "Plugin directory: $PLUGIN_DIR"
echo "Distribution directory: $DIST_DIR"

# Validate plugin structure first
echo "Validating plugin structure..."
REQUIRED_FILES=(
    "Info.lua"
    "Init.lua"
    "Main.lua"
    "ClearPrefs.lua"
    "ConfigParser.lua"
    "PrefsManager.lua"
    "DialogPropsTransformer.lua"
    "ViewBuilder.lua"
    "PhotoProcessor.lua"
    "default-config.json"
    "Dkjson.lua"
    "SystemUtils.lua"
    "ViewUtils.lua"
    "UIFormatConstants.lua"
    "UIStyleConstants.lua"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PLUGIN_DIR/$file" ]; then
        echo "ERROR: Required file missing: $file"
        exit 1
    fi
    echo "✓ Found: $file"
done

echo "Plugin structure validation passed!"

# Validate Lua syntax (recursively)
echo "Validating Lua syntax..."
while IFS= read -r -d '' file; do
    rel="${file#$PLUGIN_DIR/}"
    echo "Checking syntax: $rel"
    if lua -c "$file" 2>&1 | grep -q "syntax error\|unexpected symbol\|missing symbol"; then
        echo "ERROR: Syntax error in $rel"
        lua -c "$file" 2>&1
        exit 1
    else
        echo "✓ Syntax OK: $rel"
    fi
done < <(find "$PLUGIN_DIR" -type f -name "*.lua" -print0)

echo "Lua syntax validation passed!"

# Create dist directory
mkdir -p "$DIST_DIR"

# Clean previous builds
rm -rf "$DIST_DIR/ExifCraft.lrplugin"

# Copy plugin files
echo "Copying plugin files..."
cp -r "$PLUGIN_DIR" "$DIST_DIR/"


# Create CLI binary directory
mkdir -p "$DIST_DIR/ExifCraft.lrplugin/bin"

# Check if CLI binaries are built and copy them
CLI_MAC_PATH="../cli/dist/bin/mac/exifcraft"
CLI_WIN_PATH="../cli/dist/bin/win/exifcraft.exe"
CLI_NODE_PATH="../cli/dist/cli.js"

COPIED_BINARY=false

# Copy macOS binary
if [ -f "$CLI_MAC_PATH" ]; then
    echo "Copying compiled CLI binary (macOS)..."
    mkdir -p "$DIST_DIR/ExifCraft.lrplugin/bin/mac"
    cp "$CLI_MAC_PATH" "$DIST_DIR/ExifCraft.lrplugin/bin/mac/"
    chmod +x "$DIST_DIR/ExifCraft.lrplugin/bin/mac/exifcraft"
    COPIED_BINARY=true
fi

# Copy Windows binary
if [ -f "$CLI_WIN_PATH" ]; then
    echo "Copying compiled CLI binary (Windows)..."
    mkdir -p "$DIST_DIR/ExifCraft.lrplugin/bin/win"
    cp "$CLI_WIN_PATH" "$DIST_DIR/ExifCraft.lrplugin/bin/win/"
    COPIED_BINARY=true
fi

# Copy Node.js fallback
if [ -f "$CLI_NODE_PATH" ]; then
    echo "Copying Node.js CLI (fallback)..."
    mkdir -p "$DIST_DIR/ExifCraft.lrplugin/bin/node"
    cp "$CLI_NODE_PATH" "$DIST_DIR/ExifCraft.lrplugin/bin/node/"
    chmod +x "$DIST_DIR/ExifCraft.lrplugin/bin/node/cli.js"
    COPIED_BINARY=true
fi

if [ "$COPIED_BINARY" = false ]; then
    echo "Warning: No CLI binary found"
    echo "Please build the CLI first with: cd ../cli && npm run package"
fi

# Auto-increment build version
echo "Auto-incrementing build version..."
INFO_FILE="$PLUGIN_DIR/Info.lua"
if [ -f "$INFO_FILE" ]; then
    # Extract current build number
    CURRENT_BUILD=$(grep -o 'build = [0-9]*' "$INFO_FILE" | grep -o '[0-9]*')
    if [ -n "$CURRENT_BUILD" ]; then
        NEW_BUILD=$((CURRENT_BUILD + 1))
        sed -i '' "s/build = $CURRENT_BUILD/build = $NEW_BUILD/g" "$INFO_FILE"
        echo "Version updated: build $CURRENT_BUILD -> $NEW_BUILD"
        
        # Copy updated file to dist
        cp "$INFO_FILE" "$DIST_DIR/ExifCraft.lrplugin/"
    fi
fi

# Create archive with version info
cd "$DIST_DIR"
CURRENT_BUILD=$(grep -o 'build = [0-9]*' ExifCraft.lrplugin/Info.lua | grep -o '[0-9]*')
ARCHIVE_NAME="ExifCraft-0.0.1-build${CURRENT_BUILD}-$(date +%Y%m%d).zip"
zip -r "$ARCHIVE_NAME" ExifCraft.lrplugin/

echo "Plugin packaged successfully!"
echo "Archive created: $DIST_DIR/$ARCHIVE_NAME"
echo ""
echo "Installation instructions:"
echo "1. Unzip the archive"
echo "2. Double-click ExifCraft.lrplugin to install in Lightroom"
echo "3. Or manually copy to Lightroom's Modules folder"
