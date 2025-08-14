import { promises as fs } from 'fs';
import * as path from 'path';
import { exiftool } from 'exiftool-vendored';
import { ImageConverter } from '../models/types';

// Use require to avoid TypeScript type issues with heic-convert
const heicConvert = require('heic-convert');

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

/**
 * Get file size in MB
 */
export async function getFileSizeMB(filePath: string): Promise<number> {
  const stats = await fs.stat(filePath);
  return stats.size / (1024 * 1024);
}

/**
 * Convert HEIC image to JPEG format for AI processing
 */
export async function convertHeicToJpeg(heicPath: string): Promise<Buffer> {
  try {
    console.log('  Converting HEIC to JPEG...');
    
    // Read the HEIC file
    const heicBuffer = await fs.readFile(heicPath);
    
    // Convert HEIC to JPEG using heic-convert
    const jpegBuffer = await heicConvert({
      buffer: heicBuffer,
      format: 'JPEG',
      quality: 0.85
    });
    
    console.log('  Successfully converted HEIC to JPEG');
    return jpegBuffer;
  } catch (error) {
    throw new Error(`Failed to convert HEIC to JPEG: ${(error as Error).message}`);
  }
}

/**
 * Convert HEIC format with fallback logic - try preview extraction first, then convert
 */
async function convertHeicWithFallback(imagePath: string): Promise<Buffer> {
  try {
    return await convertRawToJpeg(imagePath);
  } catch (error) {
    console.log('  Preview extraction failed, converting HEIC to JPEG...');
    return await convertHeicToJpeg(imagePath);
  }
}

/**
 * Convert RAW image to JPEG format for AI processing
 */
export async function convertRawToJpeg(imagePath: string): Promise<Buffer> {
  try {
    // Try to extract preview image using exiftool
    console.log('  Extracting preview image from file...');
    
    // Try different preview tags in order of preference
    const previewTags = ['PreviewImage', 'JpgFromRaw', 'ThumbnailImage'];
    
    for (const tag of previewTags) {
      try {
        const previewBuffer = await exiftool.extractBinaryTagToBuffer(tag, imagePath);
        
        if (previewBuffer && previewBuffer.length > 0) {
          console.log(`  Successfully extracted ${tag}`);
          return previewBuffer; // Return the preview buffer directly
        }
      } catch (tagError) {
        // Continue to next tag if this one fails
        continue;
      }
    }
    
    throw new Error('No preview image found in file');
  } catch (error) {
    throw new Error(`Failed to convert image to JPEG: ${(error as Error).message}. This format may not be supported.`);
  }
}



/**
 * Map of file extensions to their corresponding converter functions
 */
const imageConverters: Record<string, ImageConverter> = {
  // RAW formats - extract preview using exiftool
  '.nef': convertRawToJpeg,   // Nikon
  '.raf': convertRawToJpeg,   // Fujifilm
  '.cr2': convertRawToJpeg,   // Canon
  '.arw': convertRawToJpeg,   // Sony
  '.dng': convertRawToJpeg,   // Adobe
  '.raw': convertRawToJpeg,   // Generic RAW
  '.orf': convertRawToJpeg,   // Olympus
  '.rw2': convertRawToJpeg,   // Panasonic
  '.pef': convertRawToJpeg,   // Pentax
  '.srw': convertRawToJpeg,   // Samsung
  
  // HEIC formats - try preview extraction first, fallback to conversion
  '.heic': convertHeicWithFallback,
  '.heif': convertHeicWithFallback
};

/**
 * Get image buffer for AI processing, converting RAW or HEIC if necessary
 */
export async function getImageBufferForAI(imagePath: string): Promise<Buffer> {
  const ext = path.extname(imagePath).toLowerCase();
  const converter = imageConverters[ext];
  
  if (converter) {
    return await converter(imagePath);
  } else {
    // For unsupported formats, try to read directly
    return await fs.readFile(imagePath);
  }
}
