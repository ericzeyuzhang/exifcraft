#!/bin/bash

# Demo dry run script for exifcraft
# This script prepares the test environment and runs the image processing in dry-run mode

set -e  # Exit on any error

echo "🧹 Cleaning demo directory..."
rm -rf ./tests/images/demo/*
echo "✅ Demo directory cleaned"

echo "📋 Copying original files to demo..."
cp ./tests/images/original/* ./tests/images/demo/
echo "✅ Original files copied to demo"

echo "🔨 Building project..."
npm run build
echo "✅ Build completed"

echo "🚀 Starting image processing (DRY RUN)..."
node --no-warnings dist/bin/cli.js -d ./tests/images/demo -c ./config.ts --verbose --dry-run
echo "🎉 Demo dry run completed successfully!"
