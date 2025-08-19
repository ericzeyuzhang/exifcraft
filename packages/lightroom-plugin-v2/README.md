# ExifCraft v2 - Lightroom Plugin

AI-powered EXIF metadata generation plugin for Adobe Lightroom, featuring integrated configuration and processing in a single unified interface.

## Features

- **Unified Interface**: Configure AI settings and process photos in a single dialog
- **Library Menu Integration**: Access ExifCraft directly from Lightroom's Library module menu
- **Cross-Platform Support**: Uses official Lightroom SDK method (WIN_ENV) to detect Windows/macOS and select appropriate CLI binary
- **AI Metadata Generation**: Automatically generate titles, descriptions, and keywords using AI vision models
- **Standard Metadata Fields**: Store AI-generated content in Lightroom's standard metadata fields (title, caption, keywords)
- **Flexible Configuration**: Choose which metadata to generate and customize AI prompts
- **Preserve Originals**: Option to keep backup copies of original files
- **Progress Tracking**: Real-time progress indication during batch processing
- **Multiple CLI Options**: Includes compiled binaries for Windows/macOS and Node.js fallback

## Installation

1. Ensure you have the ExifCraft CLI installed and accessible
2. Download the latest plugin package
3. Double-click `ExifCraft.lrplugin` to install in Lightroom
4. Restart Lightroom if necessary

## Usage

### Process Photos with AI

1. Select your images in Lightroom's Library module
2. Go to **Library > Process with ExifCraft v2**
3. Configure all settings in the unified dialog:
   - **AI Model Configuration**: Set provider, endpoint, model, and API parameters
   - **Task Configuration**: Choose which metadata tasks to enable and customize prompts
   - **General Options**: Set base prompt, supported formats, and processing options
4. Click **Process** to start AI metadata generation
5. The plugin will:
   - Generate AI metadata using your configured model
   - Write EXIF data to the image files
   - Update Lightroom's database with the generated metadata
   - Show progress and completion summary

### View Generated Metadata

After processing, you can view the AI-generated metadata in Lightroom's Metadata panel:
- **Title**: AI-generated image titles
- **Caption**: AI-generated image descriptions
- **Keywords**: AI-generated keywords/tags

## Configuration Details

### AI Model Settings
- **Provider**: Choose between Ollama, OpenAI, Gemini, or Mock for testing
- **Endpoint**: Full URL to your AI service API
- **Model**: Name of the vision model to use
- **API Key**: Authentication key (if required)
- **Temperature**: Controls randomness in AI responses (0.0 = deterministic, 2.0 = creative)
- **Max Tokens**: Maximum response length

### Task Configuration
- **Title Task**: Generate concise image titles (50 characters max)
- **Description Task**: Create detailed image descriptions (200 characters max)
- **Keywords Task**: Extract relevant keywords/tags
- **Custom Task**: Define your own metadata generation task
- Each task can be enabled/disabled and customized with specific prompts and tag configurations

### General Options
- **Base Prompt**: Template prompt sent to the AI model
- **Image Formats**: Supported file extensions for processing
- **Preserve Original**: Keep backup copies of original files
- **Verbose Logging**: Enable detailed processing logs
- **Dry Run**: Preview mode without making changes

## Requirements

- Adobe Lightroom Classic (version 3.0+)
- ExifCraft CLI installed and accessible (with JSON config support)
- AI service (Ollama, OpenAI, Gemini, etc.) with a vision model
- Node.js runtime (for CLI execution)

## Troubleshooting

### CLI Not Found
The plugin automatically detects your platform and uses the appropriate CLI binary:
- **Windows**: Uses `bin/win/exifcraft.exe`
- **macOS**: Uses `bin/mac/exifcraft`  
- **Fallback**: Uses Node.js version `bin/node/cli.js` (requires Node.js)
- **Global**: Falls back to globally installed `exifcraft` command

If all fail, ensure ExifCraft CLI is installed globally: `npm install -g exifcraft-cli`

### AI Service Connection Issues
- Verify your AI service is running and accessible
- Check the endpoint URL is correct
- Ensure the specified model is available
- Verify API keys are valid (if required)

### Processing Failures
- Check Lightroom's Plugin Manager for error logs
- Enable verbose logging for detailed error information
- Verify image file permissions and formats
- Ensure selected images are supported file types

## Development

To build and package the plugin:

```bash
# Package the plugin
./package-plugin.sh
```

This creates a distributable `.zip` file in the `dist/` directory.

## Support

For issues and feature requests, please visit the [ExifCraft GitHub repository](https://github.com/yourusername/exifcraft).
