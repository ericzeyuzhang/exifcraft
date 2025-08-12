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
  const { directory, files, config, verbose, dryRun } = job;
  
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
  
  // Track processing results
  const successfulFiles: string[] = [];
  const failedFiles: Array<{fileName: string, error: string}> = [];
  
  // Process each image file
  for (let i = 0; i < imageFiles.length; i++) {
    const imagePath = imageFiles[i];
    const fileName = path.basename(imagePath);
    
    // Show progress
    console.log(chalk.yellow(`Processing ${fileName} [${i + 1}/${imageFiles.length}]`));
    
    try {
      await processImage(imagePath, config, verbose, dryRun, logger);
      if (verbose) {
        console.log(chalk.green(`✓ Completed: ${fileName}`));
      }
      // Track success
      successfulFiles.push(fileName);
    } catch (error) {
      console.error(chalk.red(`✗ Processing failed ${fileName}: ${(error as Error).message}`));
      if (verbose) {
        console.error((error as Error).stack);
      }
      // Track failure
      failedFiles.push({ fileName, error: (error as Error).message });
    }
  }
  
  // Show summary
  logger.showSummary({ successfulFiles, failedFiles });
}

/**
 * Process a single image file
 */
async function processImage(
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
  
  for (const taskConfig of config.tasks) {
    if (verbose) {
      console.log(`-- Processing [${taskConfig.name}] task...`);
    }
    
    try {
      // Call AI model to generate response
      const aiResponse = await generateAIResponse(
        imageBuffer,
        (config.basePrompt || '') + taskConfig.prompt,
        config.aiModel
      );
      
      if (verbose) {
        console.log(`   AI response: ${aiResponse.substring(0, 100)}${aiResponse.length > 100 ? '...' : ''}`);
      }
      
      // Write response to corresponding EXIF tags
      for (const tagName of taskConfig.tags) {
        exifData[tagName] = aiResponse;
      }
      
    } catch (error) {
      console.warn(chalk.yellow(`  Warning: prompt "${taskConfig.name}" processing failed: ${(error as Error).message}`));
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
