# ExifCraft

AI-powered EXIF metadata crafting tool for images

## Features

- AI-powered image analysis and metadata generation
- Support for JPG and JPEG image formats
- Configurable AI models (Ollama, OpenAI, Gemini)
- Batch processing capabilities
- Dry-run mode for preview
- Preserve original files option

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
          allowOverwrite: true
        }
      ]
    },
    {
      name: "description", 
      prompt: "Describe this image",
      tags: [
        {
          name: "ImageDescription", // TypeScript provides autocomplete for all available EXIF tags
          allowOverwrite: true
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
  imageFormats: [".jpg", ".jpeg"],
  preserveOriginal: false,
  basePrompt: "You are a helpful assistant."
};

export default config;
```

## Development

### Building

```bash
npm run build
```



## License

MIT
