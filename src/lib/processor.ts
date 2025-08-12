import { promises as fs } from 'fs';
import * as path from 'path';
import chalk from 'chalk';
import { getImageFiles, filterSupportedFiles } from './imageUtils';
import { generateAIResponse, convertImageForAI } from './aiClient';
import { writeExifData } from './exifWriter';
import { ProcessingJob, ExifCraftConfig, ExifData } from '../types';
import { Logger } from './logger';

/**
 * Process image files
 */
export async function processImages(job: ProcessingJob, logger: Logger): Promise<void> {
  const { directory, files, config, verbose, dryRun, onProgress, onResult } = job;
  
  // Get list of image files to process
  let imageFiles: string[] = [];
  
  if (directory) {
    imageFiles = await getImageFiles(directory, config.imageFormats);
  } else if (files) {
    imageFiles = filterSupportedFiles(files, config.imageFormats);
  }
  
  if (imageFiles.length === 0) {
    throw new Error('No supported image files found');
  }
  
  if (verbose) {
    console.log(chalk.blue(`Found ${imageFiles.length} image files:`));
    imageFiles.forEach(file => console.log(`  - ${file}`));
  }
  
  // Process each image file
  for (let i = 0; i < imageFiles.length; i++) {
    const imagePath = imageFiles[i];
    const fileName = path.basename(imagePath);
    
    // Update progress if callback is provided
    if (onProgress) {
      onProgress(i + 1, imageFiles.length, fileName);
    }
    
    if (verbose) {
      console.log(chalk.yellow(`\n[${i + 1}/${imageFiles.length}] Processing: ${fileName}`));
    }
    
    try {
      await processImage(imagePath, config, verbose, dryRun, logger);
      if (verbose) {
        console.log(chalk.green(`✓ Completed: ${fileName}`));
      }
      // Report success
      if (onResult) {
        onResult(fileName, true);
      }
    } catch (error) {
      console.error(chalk.red(`✗ Processing failed ${fileName}: ${(error as Error).message}`));
      if (verbose) {
        console.error((error as Error).stack);
      }
      // Report failure
      if (onResult) {
        onResult(fileName, false, (error as Error).message);
      }
    }
  }
}

/**
 * Process a single image file
 */
export async function processImage(
  imagePath: string, 
  config: ExifCraftConfig, 
  verbose: boolean,
  dryRun: boolean,
  logger: Logger
): Promise<void> {
  // Check if file exists
  try {
    await fs.access(imagePath);
  } catch (error) {
    throw new Error(`Image file does not exist: ${imagePath}`);
  }

  // Convert image once for all AI calls
  const imageBuffer = await convertImageForAI(imagePath, verbose, logger);
  
  // Generate AI response for each prompt and write to EXIF
  const exifData: ExifData = {};
  
  for (const tagGenerationConfig of config.tagGeneration) {
    if (verbose) {
      console.log(`  Processing prompt: ${tagGenerationConfig.name}`);
    }
    
    try {
      // Call AI model to generate response
      const aiResponse = await generateAIResponse(
        imageBuffer,
        (config.basePrompt || '') + tagGenerationConfig.prompt,
        config.aiModel,
        verbose,
        logger
      );
      
      logger.showAIResponse(aiResponse);
      
      // Write response to corresponding EXIF tags
      for (const tagName of tagGenerationConfig.tags) {
        exifData[tagName] = aiResponse;
      }
      
    } catch (error) {
      console.warn(chalk.yellow(`  Warning: prompt "${tagGenerationConfig.name}" processing failed: ${(error as Error).message}`));
    }
  }
  
  // Write EXIF data to image file
  if (Object.keys(exifData).length > 0) {
    if (dryRun) {
      if (verbose) {
        console.log(chalk.blue(`  [DRY RUN] Would write EXIF tags: ${Object.keys(exifData).join(', ')}`));
        for (const [tagName, value] of Object.entries(exifData)) {
          console.log(chalk.blue(`    ${tagName}: ${value.substring(0, 100)}${value.length > 100 ? '...' : ''}`));
        }
      }
    } else {
      await writeExifData(imagePath, exifData, config.preserveOriginal, verbose);
    }
  } else {
    console.warn(chalk.yellow(`  Warning: No EXIF data generated`));
  }
}
