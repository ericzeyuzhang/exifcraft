import { promises as fs } from 'fs';
import * as path from 'path';
import { glob } from 'glob';

/**
 * Filter array of file paths to only include supported formats
 */
export function filterSupportedFiles(filePaths: string[], supportedFormats: string[]): string[] {
  return filePaths.filter(filePath => {
    const ext = path.extname(filePath).toLowerCase();
    return supportedFormats.includes(ext);
  });
}

/**
 * Get all image files in directory
 */
export async function getImageFiles(directory: string, supportedFormats: string[]): Promise<string[]> {
  try {
    // Check if directory exists
    const stat = await fs.stat(directory);
    if (!stat.isDirectory()) {
      throw new Error(`Specified path is not a directory: ${directory}`);
    }
    
    // Build glob pattern
    const extensions = supportedFormats.map(ext => ext.replace('.', '')).join(',');
    const pattern = path.join(directory, `**/*.{${extensions}}`);
    
    // Search files
    const files = await glob(pattern, { 
      nocase: true,  // Ignore case
      absolute: true // Return absolute paths
    });
    
    return files.sort(); // Sort alphabetically
    
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      throw new Error(`Directory does not exist: ${directory}`);
    }
    throw error;
  }
}
