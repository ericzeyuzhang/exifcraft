import { promises as fs } from 'fs';
import * as path from 'path';
import { glob } from 'glob';
import { ImageInfo } from '../types';

/**
 * Extract file extension in lowercase
 */
export function getFileExtension(filePath: string): string {
  return path.extname(filePath).toLowerCase();
}

/**
 * Check if file format is supported
 */
export function isSupportedFormat(filePath: string, supportedFormats: string[]): boolean {
  const ext = getFileExtension(filePath);
  return supportedFormats.includes(ext);
}

/**
 * Filter array of file paths to only include supported formats
 */
export function filterSupportedFiles(filePaths: string[], supportedFormats: string[]): string[] {
  return filePaths.filter(filePath => isSupportedFormat(filePath, supportedFormats));
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

/**
 * Get image file information
 */
export async function getImageInfo(imagePath: string): Promise<ImageInfo> {
  try {
    const stat = await fs.stat(imagePath);
    const ext = path.extname(imagePath).toLowerCase();
    const basename = path.basename(imagePath, ext);
    
    return {
      path: imagePath,
      name: basename,
      extension: ext,
      size: stat.size,
      modified: stat.mtime,
      directory: path.dirname(imagePath)
    };
  } catch (error) {
    throw new Error(`Unable to get image information: ${(error as Error).message}`);
  }
}

/**
 * Validate if image file is readable
 */
export async function validateImageFile(imagePath: string): Promise<boolean> {
  try {
    await fs.access(imagePath, fs.constants.R_OK);
    const stat = await fs.stat(imagePath);
    
    if (!stat.isFile()) {
      throw new Error('Not a file');
    }
    
    if (stat.size === 0) {
      throw new Error('File is empty');
    }
    
    return true;
  } catch (error) {
    throw new Error(`Image file validation failed: ${(error as Error).message}`);
  }
}
