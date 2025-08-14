import { exiftool, WriteTaskOptions, WriteTags, WriteTaskResult, Tags } from 'exiftool-vendored';
import chalk from 'chalk';

/**
 * Read existing EXIF data from image file
 */
export async function readExifData(
  imagePath: string,
  tagNames: string[],
  verbose: boolean = false
): Promise<Partial<Tags>> {
  try {
    if (verbose) {
      console.log(`Reading EXIF tags: ${tagNames.join(', ')}`);
    }
    
    const result = await exiftool.read(imagePath, tagNames);
    
    if (verbose) {
      console.log(chalk.blue(`  ✓ EXIF data read successfully`));
    }
    
    return result;
  } catch (error) {
    throw new Error(`Failed to read EXIF data: ${(error as Error).message}`);
  }
}

/**
 * Check if a tag value exists and is non-empty
 */
function isTagValueNonEmpty(value: any): boolean {
  if (value === undefined || value === null) {
    return false;
  }
  
  if (typeof value === 'string') {
    return value.trim().length > 0;
  }
  
  if (Array.isArray(value)) {
    return value.length > 0 && value.some(item => isTagValueNonEmpty(item));
  }
  
  return true;
}

/**
 * Write EXIF data to image file with allowOverwrite support
 */
export async function writeExifData(
  imagePath: string,
  tagsToWrite: Partial<WriteTags>,
  preserveOriginal: boolean = false,
  verbose: boolean = false,
  allowOverwriteMap?: Record<string, boolean>
): Promise<void> {
  try {
    if (Object.keys(tagsToWrite).length === 0) {
      if (verbose) {
        console.log(chalk.yellow(`  No valid EXIF data to write for: ${imagePath}`));
      }
      return;
    }
    
    // Filter tags based on allowOverwrite settings
    const filteredTags: Partial<WriteTags> = {};
    const tagsToCheck = Object.keys(tagsToWrite);
    
    if (allowOverwriteMap && Object.keys(allowOverwriteMap).length > 0) {
      // Read existing EXIF data to check for non-empty values
      const existingTags = await readExifData(imagePath, tagsToCheck, false);
      
      for (const [tagName, newValue] of Object.entries(tagsToWrite)) {
        const allowOverwrite = allowOverwriteMap[tagName];
        
        if (allowOverwrite === undefined) {
          // If allowOverwrite is not specified, default to true
          (filteredTags as any)[tagName] = newValue;
          continue;
        }
        
        if (allowOverwrite) {
          // Always overwrite if allowOverwrite is true
          (filteredTags as any)[tagName] = newValue;
          if (verbose) {
            console.log(`  ✓ Will overwrite ${tagName}`);
          }
        } else {
          // Check if existing value is non-empty
          const existingValue = existingTags[tagName as keyof Tags];
          if (!isTagValueNonEmpty(existingValue)) {
            (filteredTags as any)[tagName] = newValue;
            if (verbose) {
              console.log(`  ✓ Will write ${tagName} (existing value is empty)`);
            }
          } else {
            if (verbose) {
              console.log(`  ⚠ Skipping ${tagName} (existing value is non-empty and allowOverwrite is false)`);
            }
          }
        }
      }
    } else {
      // No allowOverwrite settings, write all tags
      Object.assign(filteredTags, tagsToWrite);
    }
    
    if (Object.keys(filteredTags).length === 0) {
      if (verbose) {
        console.log(chalk.yellow(`  No tags to write after filtering`));
      }
      return;
    }
    
    if (verbose) {
      console.log(`Writing EXIF tags: ${Object.keys(filteredTags).join(', ')}`);
    }
    
    // Write tags to the image file
    // Use -overwrite_original_in_place if preserveOriginal is false, otherwise exiftool will create backup
    const options: WriteTaskOptions = { 
      writeArgs: preserveOriginal ? [] : ["-overwrite_original_in_place"]
    };

    const result: WriteTaskResult = await exiftool.write(imagePath, filteredTags, options);
    
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
