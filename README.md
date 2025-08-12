# ExifCraft

An AI-powered EXIF metadata crafting tool that uses local AI models to generate descriptive EXIF tags for images.

## Features

- 🖼️ Support for extensive image formats (JPEG, PNG, TIFF, WebP, HEIC, RAW, etc.)
- 🤖 Integration with local AI models (supports Ollama, OpenAI-compatible APIs, etc.)
- 📝 Configurable prompts and EXIF tag mapping
- 🔧 Flexible CLI parameter configuration
- 📁 Support for batch processing entire directories or specified files
- 💾 Optional original file backup functionality

## Installation

### Prerequisites

- Node.js 14.0.0 or higher
- Local AI model service (such as Ollama)

### Install Dependencies

```bash
npm install
```

### Global Installation (Optional)

```bash
npm install -g .
```

## Configuration

### 1. AI Model Setup

First, set up a local AI model service. Ollama is recommended:

```bash
# Install Ollama (macOS)
brew install ollama

# Start Ollama service
ollama serve

# Download vision model (e.g., llava)
ollama pull llava
```

### 2. Configuration File

The project includes a default configuration file `config.json` that you can modify as needed:

```json
{
  "prompts": [
    {
      "name": "description",
      "prompt": "Please describe this image in detail, including the main objects, scene, colors, composition and other visual elements.",
      "exifTags": ["ImageDescription", "UserComment"]
    },
    {
      "name": "keywords",
      "prompt": "Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc.",
      "exifTags": ["Keywords", "Subject"]
    }
  ],
  "aiModel": {
    "type": "ollama",
    "endpoint": "http://localhost:11434/api/generate",
    "model": "llava",
    "options": {
      "temperature": 0.7,
      "max_tokens": 200
    }
  },
  "imageFormats": [".jpg", ".jpeg", ".jpe", ".png", ".tiff", ".tif", ".webp", ".heic", ".heif", ".raw", ".cr2", ".nef", ".arw", ".bmp", ".gif"],
  "overwriteOriginal": true
}
```

## Usage

### Basic Usage

```bash
# Process all images in specified directory
exifcraft -d /path/to/images

# Process specified image files
exifcraft -f image1.jpg image2.png image3.jpg

# Use custom configuration file
exifcraft -d /path/to/images -c ./my-config.json

# Show verbose output
exifcraft -d /path/to/images -v
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --directory <path>` | Path to image directory | - |
| `-f, --files <paths...>` | Specify image file paths | - |
| `-c, --config <path>` | Configuration file path | `./config.json` |
| `-v, --verbose` | Show verbose output | `false` |

### Usage Examples

```bash
# Example 1: Process single directory
exifcraft -d ./photos -v

# Example 2: Process specific files
exifcraft -f ./photo1.jpg ./photo2.png

# Example 3: Use custom configuration
exifcraft -d ./photos -c ./custom-config.json

# Example 4: Specify different AI model
exifcraft -d ./photos -m llava:13b
```

## Configuration Guide

### Prompt Configuration

Each prompt contains the following fields:

- `name`: Unique identifier for the prompt
- `prompt`: Prompt text sent to the AI model
- `exifTags`: Array of EXIF tag names to write to

### AI Model Configuration

Support for multiple AI model types:

#### Ollama
```json
{
  "type": "ollama",
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llava",
  "options": {
    "temperature": 0.7,
    "max_tokens": 200
  }
}
```

#### OpenAI Compatible API
```json
{
  "type": "openai",
  "endpoint": "https://api.openai.com/v1/chat/completions",
  "model": "gpt-4-vision-preview",
  "options": {
    "apiKey": "your-api-key",
    "temperature": 0.7,
    "max_tokens": 200
  }
}
```

#### Custom API
```json
{
  "type": "custom",
  "endpoint": "http://your-api-endpoint",
  "model": "your-model",
  "options": {
    "headers": {
      "Authorization": "Bearer your-token"
    }
  }
}
```

### Supported EXIF Tags

- `ImageDescription`: Image description
- `UserComment`: User comment
- `Artist`: Artist/author
- `Copyright`: Copyright information
- `Keywords`: Keywords (mapped to ImageDescription)
- `Subject`: Subject (mapped to ImageDescription)

### File Format Configuration

ExifCraft uses a centralized approach to manage supported file formats. All format configuration is done through the `imageFormats` array in `config.json`:

```json
{
  "imageFormats": [
    ".jpg", ".jpeg", ".jpe",
    ".png", ".tiff", ".tif", 
    ".webp", ".heic", ".heif",
    ".raw", ".cr2", ".nef", ".arw",
    ".bmp", ".gif"
  ]
}
```

**Adding new formats:**
1. Edit your `config.json` file
2. Add new extensions to the `imageFormats` array
3. All modules will automatically use the updated format list

**Examples of additional formats you can add:**
- `.avif` - AV1 Image File Format
- `.jxl` - JPEG XL
- `.dng` - Digital Negative (Adobe)
- `.orf` - Olympus RAW Format

### Backup Configuration

ExifCraft uses ExifTool's built-in backup mechanism:

- **`"overwriteOriginal": true`** - Overwrites original files without creating backups (faster)
- **`"overwriteOriginal": false`** - Creates backup files with `_original` suffix before modifying

```json
{
  "overwriteOriginal": false  // Creates backup files like "photo.jpg_original"
}
```

## Important Notes

1. **File Format**: Supports extensive image formats including JPEG, PNG, TIFF, WebP, HEIC, RAW formats, and more
2. **Performance**: High-performance EXIF processing powered by ExifTool
3. **Backup**: Built-in ExifTool backup system - set `overwriteOriginal: false` to create backups
4. **AI Service**: Ensure local AI service is running and accessible
5. **Processing**: Processing large numbers of images may take time, use `-v` option to view progress

## Troubleshooting

### Common Issues

1. **Unable to connect to AI service**
   ```
   Error: Unable to connect to Ollama service, please ensure Ollama is running
   ```
   Solution: Check if Ollama service is started and port is correct

2. **Unsupported image format**
   ```
   Warning: Unsupported file format
   ```
   Solution: Check if the file format is in the supported list, or update imageFormats in config.json

3. **Configuration file error**
   ```
   Error: Configuration file format error
   ```
   Solution: Check if JSON format is correct and required fields exist

## Development

### Project Structure

```
exifcraft/
├── src/                # TypeScript source files
│   ├── bin/
│   │   └── cli.ts      # CLI entry file
│   ├── lib/
│   │   ├── aiClient.ts     # AI model client
│   │   ├── config.ts       # Configuration file handling
│   │   ├── exifWriter.ts   # EXIF writing functionality
│   │   ├── imageUtils.ts   # Image utility functions
│   │   └── processor.ts    # Main processing logic
│   └── types/
│       └── index.ts    # Type definitions
├── dist/               # Compiled JavaScript output
├── config.json         # Default configuration file
├── tsconfig.json       # TypeScript configuration
├── package.json        # Project configuration
└── README.md          # Documentation
```

### Development Scripts

```bash
# Development mode (TypeScript with ts-node)
npm run dev -- -f image.jpg -v

# Build TypeScript to JavaScript
npm run build

# Run compiled version
npm start -- -f image.jpg -v

# Clean build output
npm run clean
```

### TypeScript Features

- **Type Safety**: Full TypeScript support with strict type checking
- **IntelliSense**: Better IDE support and autocomplete
- **Interface Definitions**: Clear contracts for configuration and data structures
- **Source Maps**: Debug TypeScript directly in production builds

### Contributing

Welcome to submit Issues and Pull Requests to improve this project!

## License

MIT License