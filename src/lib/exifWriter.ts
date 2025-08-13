import { exiftool, WriteTaskOptions, WriteTags, WriteTaskResult } from 'exiftool-vendored';
import chalk from 'chalk';

/**
 * Write EXIF data to image file
 */
export async function writeExifData(
  imagePath: string,
  tagsToWrite: Partial<WriteTags>,
  preserveOriginal: boolean = false,
  verbose: boolean = false
): Promise<void> {
  try {
    if (Object.keys(tagsToWrite).length === 0) {
      if (verbose) {
        console.log(chalk.yellow(`  No valid EXIF data to write for: ${imagePath}`));
      }
      return;
    }
    
    if (verbose) {
      console.log(`Writing EXIF tags: ${Object.keys(tagsToWrite).join(', ')}`);
    }
    
    // Write tags to the image file
    // Use -overwrite_original_in_place if preserveOriginal is false, otherwise exiftool will create backup
    const options: WriteTaskOptions = { 
      writeArgs: preserveOriginal ? [] : ["-overwrite_original_in_place"]
    };

    const result: WriteTaskResult = await exiftool.write(imagePath, tagsToWrite, options);
    
    if (verbose) {
      console.log(chalk.blue(`  ✓ EXIF data written successfully. Created: ${result.created}, Updated: ${result.updated}, Unchanged: ${result.unchanged}, ${result.warnings ? result.warnings.join(', ') : ''}`));
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
