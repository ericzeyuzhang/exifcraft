#!/bin/bash

# Demo script for exifcraft
# Usage: ./demo.sh [--dry-run]

set -e  # Exit on any error

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 Running in DRY RUN mode"
fi

echo "🧹 Cleaning demo directory..."
rm -rf ./tests/images/demo/*
echo "✅ Demo directory cleaned"

echo "📋 Copying original files to demo..."
cp ./tests/images/original/* ./tests/images/demo/
echo "✅ Original files copied to demo"

echo "🔨 Building project..."
npm run build
echo "✅ Build completed"

echo "🚀 Starting image processing..."
if [ "$DRY_RUN" = true ]; then
  node --no-warnings dist/bin/cli.js -d ./tests/images/demo -c ./config.ts --verbose --dry-run
  echo "🎉 Demo dry run completed successfully!"
else
  node --no-warnings dist/bin/cli.js -d ./tests/images/demo -c ./config.ts --verbose
  echo "🎉 Demo completed successfully!"
fi
