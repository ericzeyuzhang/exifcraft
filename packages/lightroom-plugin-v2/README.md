# ExifCraft v2 - Lightroom Plugin

AI-powered EXIF metadata generation plugin for Adobe Lightroom, featuring a complete GUI configuration interface.

## Features

- **GUI Configuration**: Configure Ollama endpoint, model, and metadata options directly in Lightroom's Export dialog
- **Cross-Platform Support**: Uses official Lightroom SDK method (WIN_ENV) to detect Windows/macOS and select appropriate CLI binary
- **AI Metadata Generation**: Automatically generate titles, descriptions, and keywords using AI vision models
- **Custom Metadata Fields**: Store AI-generated content in Lightroom's database for searchability
- **Flexible Options**: Choose which metadata to generate and write
- **Preserve Originals**: Option to keep backup copies of original files
- **Progress Tracking**: Real-time progress indication during batch processing
- **Multiple CLI Options**: Includes compiled binaries for Windows/macOS and Node.js fallback

## Installation

1. Ensure you have the ExifCraft CLI installed and accessible
2. Download the latest plugin package
3. Double-click `ExifCraft.lrplugin` to install in Lightroom
4. Restart Lightroom if necessary

## Usage

### 1. Configure Export Filter

1. In Lightroom, go to **File > Export** or press `Cmd+Shift+E`
2. In the Export dialog, scroll down to find **ExifCraft AI Metadata** section
3. Configure your settings:
   - **Ollama Endpoint**: URL to your Ollama instance (default: `http://localhost:11434`)
   - **Model**: Vision model to use (e.g., `llama3.2-vision`)
   - **Temperature**: AI creativity level (0.0-1.0)
   - **Metadata Options**: Choose which fields to generate
   - **Base Prompt**: Customize the AI prompt template

### 2. Export with AI Processing

1. Select your images in Lightroom
2. Click **Export** 
3. The plugin will:
   - Export your images to the specified location
   - Generate AI metadata using your configured model
   - Write EXIF data to the exported files
   - Update Lightroom's database with the generated metadata

### 3. View Generated Metadata

After processing, you can view the AI-generated metadata in Lightroom's Metadata panel:
- **AI Generated Title**
- **AI Generated Description** 
- **AI Generated Keywords**
- **AI Processing Status**

## Configuration Details

### Ollama Settings
- **Endpoint**: Full URL to your Ollama API (e.g., `http://localhost:11434`)
- **Model**: Name of the vision model (must be installed in Ollama)
- **Temperature**: Controls randomness in AI responses (0.0 = deterministic, 1.0 = creative)

### Metadata Options
- **Write Title**: Generates concise image titles
- **Write Description**: Creates detailed image descriptions
- **Write Keywords**: Extracts relevant keywords/tags
- **Preserve Original**: Keeps backup copies of original files
- **Verbose Logging**: Enables detailed processing logs

### AI Prompt Configuration
- **Base Prompt**: Template prompt sent to the AI model
- Default: "Analyze this image and provide metadata."

## Requirements

- Adobe Lightroom Classic (version 3.0+)
- ExifCraft CLI installed and accessible (with JSON config support)
- Ollama with a vision model installed
- Node.js runtime (for CLI execution)

## Troubleshooting

### CLI Not Found
The plugin automatically detects your platform and uses the appropriate CLI binary:
- **Windows**: Uses `bin/win/exifcraft.exe`
- **macOS**: Uses `bin/mac/exifcraft`  
- **Fallback**: Uses Node.js version `bin/node/cli.js` (requires Node.js)
- **Global**: Falls back to globally installed `exifcraft` command

If all fail, ensure ExifCraft CLI is installed globally: `npm install -g exifcraft-cli`

### Ollama Connection Issues
- Verify Ollama is running: `ollama list`
- Check the endpoint URL is correct
- Ensure the specified model is installed: `ollama pull llama3.2-vision`

### Processing Failures
- Check Lightroom's Plugin Manager for error logs
- Enable verbose logging for detailed error information
- Verify image file permissions and formats

## Development

To build and package the plugin:

```bash
# Package the plugin
./package-plugin.sh
```

This creates a distributable `.zip` file in the `dist/` directory.

## Support

For issues and feature requests, please visit the [ExifCraft GitHub repository](https://github.com/yourusername/exifcraft).
