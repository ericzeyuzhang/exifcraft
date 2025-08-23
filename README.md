# ExifCraft - AI-powered EXIF Metadata Crafting Tool

A monorepo containing the core functionality and CLI interface for AI-powered EXIF metadata crafting.

## Project Structure

This project is organized as a monorepo with the following packages:

### `packages/core` - Core Functionality
- **Purpose**: Contains all the core business logic for image processing, AI integration, and EXIF operations
- **Exports**: All core functions, types, and utilities
- **Dependencies**: External libraries for AI, EXIF processing, and image conversion
- **Usage**: Can be imported by other packages (CLI, etc.)

### `packages/cli` - Command Line Interface
- **Purpose**: Provides a command-line interface for the core functionality
- **Dependencies**: `exifcraft-core` + CLI-specific libraries (commander, chalk)
- **Usage**: Global npm package for command-line usage

## Installation

### Development Setup

```bash
# Clone the repository
git clone <repository-url>
cd exifcraft

# Install dependencies
npm install

# Build all packages
npm run build

# Run CLI in development mode
npm run dev:cli -- --help
```

### Using the CLI

```bash
# Install globally (after building)
npm install -g ./packages/cli

# Or run directly
npm run dev:cli -- -d /path/to/images -c config.ts
```

## Development

### Building Individual Packages

```bash
# Build core package only
npm run build:core

# Build CLI package only
npm run build:cli

# Build all packages
npm run build
```

### Testing

```bash
# Run tests for all packages
npm run test

# Run tests for specific package
cd packages/cli && npm run test
```

## Architecture Benefits

1. **Separation of Concerns**: Core logic is separated from interface code
2. **Reusability**: Core package can be used by multiple interfaces (CLI, etc.)
3. **Maintainability**: Each package has a clear responsibility
4. **Scalability**: Easy to add new interfaces as needed

## Future Extensions

This architecture supports future development of:
- **Web Interface**: Browser-based interface
- **API Server**: REST API for the core functionality

## Configuration

The CLI package includes a sample configuration file (`config.ts`) that demonstrates how to configure the AI model and EXIF tag generation.

## License

MIT
