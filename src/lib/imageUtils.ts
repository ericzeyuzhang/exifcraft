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
    
    // Read directory contents
    const files = await fs.readdir(directory);
    const imageFiles: string[] = [];
    
    for (const file of files) {
      const filePath = path.join(directory, file);
      const stat = await fs.stat(filePath);
      
      if (stat.isFile()) {
        const ext = path.extname(file).toLowerCase();
        if (supportedFormats.includes(ext)) {
          imageFiles.push(filePath);
        }
      }
    }
    
    return imageFiles.sort(); // Sort alphabetically
    
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      throw new Error(`Directory does not exist: ${directory}`);
    }
    throw error;
  }
}
