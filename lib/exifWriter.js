const { exiftool } = require('exiftool-vendored');
const chalk = require('chalk');
const { isSupportedFormat } = require('./imageUtils');

/**
 * Write EXIF data to image file
 * @param {string} imagePath - Image file path
 * @param {Object} exifData - EXIF data to write
 * @param {boolean} overwriteOriginal - Whether to overwrite original file without backup
 * @param {boolean} verbose - Whether to show verbose output
 */
async function writeExifData(imagePath, exifData, overwriteOriginal = true, verbose = false) {
  try {
    // Prepare the metadata object for exiftool-vendored
    const metadata = {};
    
    // Map our internal EXIF data structure to exiftool format
    for (const [tagName, value] of Object.entries(exifData)) {
      const mappedTag = mapExifTag(tagName);
      if (mappedTag && value) {
        metadata[mappedTag] = value;
      }
    }
    
    if (Object.keys(metadata).length === 0) {
      if (verbose) {
        console.log(chalk.yellow(`  No valid EXIF data to write for: ${imagePath}`));
      }
      return;
    }
    
    if (verbose) {
      console.log(`  Writing EXIF tags: ${Object.keys(metadata).join(', ')}`);
    }
    
    // Write metadata to the image file
    // Use -overwrite_original_in_place if overwriteOriginal is true, otherwise exiftool will create backup
    const writeArgs = overwriteOriginal ? ["-overwrite_original_in_place"] : [];
    
    await exiftool.write(imagePath, metadata, writeArgs.length > 0 ? { writeArgs } : undefined);
    
    if (verbose) {
      console.log(chalk.green(`  ✓ EXIF data written successfully`));
    }
    
  } catch (error) {
    throw new Error(`Failed to write EXIF data: ${error.message}`);
  }
}

/**
 * Read EXIF data from image file
 * @param {string} imagePath - Image file path
 * @returns {Promise<Object>} EXIF data object
 */
async function readExifData(imagePath) {
  try {
    const metadata = await exiftool.read(imagePath);
    return metadata;
  } catch (error) {
    throw new Error(`Failed to read EXIF data: ${error.message}`);
  }
}

/**
 * Map internal tag names to exiftool tag names
 * @param {string} tagName - Internal tag name
 * @returns {string|null} Exiftool tag name or null if not supported
 */
function mapExifTag(tagName) {
  const tagMapping = {
    // Standard EXIF tags
    'ImageDescription': 'ImageDescription',
    'Artist': 'Artist',
    'Copyright': 'Copyright',
    'Software': 'Software',
    
    // User comment (exiftool handles encoding automatically)
    'UserComment': 'UserComment',
    
    // Keywords and subject - map to appropriate fields
    'Keywords': 'Keywords',
    'Subject': 'Subject',
    
    // Additional common tags
    'Make': 'Make',
    'Model': 'Model',
    'DateTime': 'DateTime',
    'DateTimeOriginal': 'DateTimeOriginal',
    'DateTimeDigitized': 'DateTimeDigitized'
  };
  
  return tagMapping[tagName] || null;
}

// isSupportedFormat is now imported from fileUtils

/**
 * Clean up exiftool resources
 * Should be called when the application exits
 */
async function cleanup() {
  try {
    await exiftool.end();
  } catch (error) {
    console.warn(chalk.yellow(`Warning: Error during exiftool cleanup: ${error.message}`));
  }
}

// Handle process exit to clean up resources
process.on('exit', () => {
  exiftool.end(false); // Synchronous cleanup on exit
});

process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await cleanup();
  process.exit(0);
});

module.exports = {
  writeExifData,
  readExifData,
  isSupportedFormat,
  cleanup
};