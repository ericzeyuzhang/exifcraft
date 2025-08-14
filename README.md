# ExifCraft

AI-powered EXIF metadata crafting tool for images

## Features

- AI-powered image analysis and metadata generation
- Support for multiple image formats:
  - **Standard formats**: JPG, JPEG, TIFF
  - **RAW formats**: NEF (Nikon), RAF (Fujifilm), CR2 (Canon), ARW (Sony), DNG (Adobe), RAW, ORF (Olympus), RW2 (Panasonic), PEF (Pentax), SRW (Samsung)
- Configurable AI models (Ollama, OpenAI, Gemini)
- Batch processing capabilities
- Dry-run mode for preview
- Preserve original files option
- **allowOverwrite control** - Prevent overwriting existing non-empty EXIF tags
- **Large file handling** - Automatic size checks and warnings for RAW files

## Installation

```bash
npm install
```

## Usage

### Basic Usage

```bash
# Process all images in a directory
npm run dev -d /path/to/images -c config.ts

# Process specific files
npm run dev -f image1.jpg image2.jpeg -c config.ts

# Dry run mode (preview without modifying files)
npm run dev -d /path/to/images -c config.ts --dry-run

# Verbose output
npm run dev -d /path/to/images -c config.ts --verbose
```

### Configuration

Create a `config.ts` file with your settings. This provides full TypeScript type checking and autocomplete for EXIF tags:

```typescript
import type { ExifCraftConfig } from './src/models/types';

const config: ExifCraftConfig = {
  tasks: [
    {
      name: "title",
      prompt: "Generate a title for this image",
      tags: [
        {
          name: "ImageTitle", // TypeScript provides autocomplete for all available EXIF tags
          allowOverwrite: true  // Will overwrite existing non-empty values
        }
      ]
    },
    {
      name: "description", 
      prompt: "Describe this image",
      tags: [
        {
          name: "ImageDescription", // TypeScript provides autocomplete for all available EXIF tags
          allowOverwrite: false  // Will NOT overwrite existing non-empty values
        }
      ]
    }
  ],
  aiModel: {
    provider: "ollama",
    endpoint: "http://localhost:11434/api/generate",
    model: "llava",
    options: {
      temperature: 0,
      max_tokens: 500
    }
  },
  imageFormats: [".jpg", ".jpeg", ".nef", ".raf", ".cr2", ".arw", ".dng", ".raw", ".tiff", ".tif"],
  preserveOriginal: false,
  basePrompt: "You are a helpful assistant."
};

export default config;
```

### allowOverwrite Feature

The `allowOverwrite` field controls whether existing non-empty EXIF tags should be overwritten:

- **`allowOverwrite: true`** - Always overwrite the tag, even if it already has a non-empty value
- **`allowOverwrite: false`** - Only write to the tag if it's currently empty or doesn't exist

This is useful for:
- Preserving manually added metadata while filling in missing fields
- Preventing accidental overwrites of important existing EXIF data
- Selective updates where you only want to fill gaps in metadata

**Example behavior:**
- If `ImageTitle` already contains "My Photo" and `allowOverwrite: false`, the new AI-generated title will be skipped
- If `ImageTitle` is empty and `allowOverwrite: false`, the new AI-generated title will be written
- If `allowOverwrite: true`, the new AI-generated title will always overwrite the existing value

## Development

### Building

```bash
npm run build
```

## License

MIT
