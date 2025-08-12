import { exiftool, WriteTaskOptions } from 'exiftool-vendored';
import chalk from 'chalk';
import { ExifData } from '../types';

/**
 * Write EXIF data to image file
 */
export async function writeExifData(
  imagePath: string,
  exifData: ExifData,
  preserveOriginal: boolean = false,
  verbose: boolean = false
): Promise<void> {
  try {
    // Prepare the metadata object for exiftool-vendored
    const metadata: Record<string, string> = {};
    
    // Copy EXIF data directly to metadata object
    for (const [tagName, value] of Object.entries(exifData)) {
      if (value) {
        metadata[tagName] = value;
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
    // Use -overwrite_original_in_place if preserveOriginal is false, otherwise exiftool will create backup
    const writeArgs = preserveOriginal ? [] : ["-overwrite_original_in_place"];
    const options: WriteTaskOptions | undefined = writeArgs.length > 0 ? { writeArgs } : undefined;
    
    await exiftool.write(imagePath, metadata, options);
    
    if (verbose) {
      console.log(chalk.green(`  ✓ EXIF data written successfully`));
    }
    
  } catch (error) {
    throw new Error(`Failed to write EXIF data: ${(error as Error).message}`);
  }
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
