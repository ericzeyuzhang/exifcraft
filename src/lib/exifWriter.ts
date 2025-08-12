import { exiftool } from 'exiftool-vendored';
import chalk from 'chalk';
import { ExifData, WriteOptions } from '../types';

/**
 * Write EXIF data to image file
 */
export async function writeExifData(
  imagePath: string, 
  exifData: ExifData, 
  overwriteOriginal: boolean = true, 
  verbose: boolean = false
): Promise<void> {
  try {
    // Prepare the metadata object for exiftool-vendored
    const metadata: Record<string, string> = {};
    
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
    const options: WriteOptions | undefined = writeArgs.length > 0 ? { writeArgs } : undefined;
    
    await exiftool.write(imagePath, metadata, options);
    
    if (verbose) {
      console.log(chalk.green(`  ✓ EXIF data written successfully`));
    }
    
  } catch (error) {
    throw new Error(`Failed to write EXIF data: ${(error as Error).message}`);
  }
}

/**
 * Read EXIF data from image file
 */
export async function readExifData(imagePath: string): Promise<Record<string, any>> {
  try {
    const metadata = await exiftool.read(imagePath);
    return metadata;
  } catch (error) {
    throw new Error(`Failed to read EXIF data: ${(error as Error).message}`);
  }
}

/**
 * Map internal tag names to exiftool tag names
 */
function mapExifTag(tagName: string): string | null {
  const tagMapping: Record<string, string> = {
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

/**
 * Clean up exiftool resources
 * Should be called when the application exits
 */
export async function cleanup(): Promise<void> {
  try {
    await exiftool.end();
  } catch (error) {
    console.warn(chalk.yellow(`Warning: Error during exiftool cleanup: ${(error as Error).message}`));
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
