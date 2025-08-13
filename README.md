# ExifCraft

AI-powered EXIF metadata crafting tool for images

## Features

- AI-powered image analysis and metadata generation
- Support for multiple image formats (JPG, PNG, HEIC, etc.)
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
npm run dev -d /path/to/images -c config.json

# Process specific files
npm run dev -f image1.jpg image2.png -c config.json

# Dry run mode (preview without modifying files)
npm run dev -d /path/to/images -c config.json --dry-run

# Verbose output
npm run dev -d /path/to/images -c config.json --verbose
```

### Configuration

Create a `config.json` file with your settings:

```json
{
  "tasks": [
    {
      "name": "title",
      "prompt": "Generate a title for this image",
      "tags": [
        {
          "name": "ImageTitle",
          "allowOverwrite": true
        }
      ]
    },
    {
      "name": "description", 
      "prompt": "Describe this image",
      "tags": [
        {
          "name": "ImageDescription",
          "allowOverwrite": true
        }
      ]
    }
  ],
  "aiModel": {
    "provider": "ollama",
    "endpoint": "http://localhost:11434/api/generate",
    "model": "llava",
    "options": {
      "temperature": 0,
      "max_tokens": 500
    }
  },
  "imageFormats": [".jpg", ".jpeg", ".png", ".heic"],
  "preserveOriginal": false,
  "basePrompt": "You are a helpful assistant."
}
```

## Development

### Building

```bash
npm run build
```



## License

MIT
