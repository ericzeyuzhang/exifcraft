import { promises as fs } from 'fs';
import * as path from 'path';
import chalk from 'chalk';
import { getImageFiles, filterSupportedFiles, getFileSizeMB, getImageBufferForAI } from './imageUtils';
import { generateAIResponse } from './aiClient';
import { writeExifData } from './exifWriter';
import { JobSetting, ExifCraftConfig } from '../models/types';
import { Logger } from './logger';
import { WriteTags } from 'exiftool-vendored';

/**
 * Process image files
 */
export async function processImages(jobSetting: JobSetting, logger: Logger): Promise<void> {
  const { directory, files, config, verbose, dryRun } = jobSetting;
  
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
    console.log(chalk.yellow(`\nProcessing ${fileName} [${i + 1}/${imageFiles.length}]`));
    
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

  // Check file size
  const fileSizeMB = await getFileSizeMB(imagePath);
  
  if (fileSizeMB > 100) {
    throw new Error(`File too large (${fileSizeMB.toFixed(1)}MB). Maximum supported size is 100MB.`);
  }

  // Read image file for AI processing, converting if necessary
  const imageBuffer = await getImageBufferForAI(imagePath);
  
  if (verbose) {
    console.log(`  File size: ${fileSizeMB.toFixed(1)}MB`);
  }
  
  // Generate AI response for each prompt and write to EXIF
  const tagsToWrite: Partial<WriteTags> = {};
  const avoidOverwriteMap: Record<string, boolean> = {};
  
  for (const taskConfig of config.tasks) {
    // Skip disabled tasks (Lightroom plugin integration)
    if (taskConfig.enabled === false) {
      if (verbose) {
        console.log(`-- Skipping disabled task [${taskConfig.name}]`);
      }
      continue;
    }
    
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
      for (const tagConfig of taskConfig.tags) {
        (tagsToWrite as any)[tagConfig.name] = aiResponse;
        avoidOverwriteMap[tagConfig.name] = tagConfig.avoidOverwrite;
      }
      
    } catch (error) {
      console.warn(chalk.yellow(`  Warning: prompt "${taskConfig.name}" processing failed: ${(error as Error).message}`));
    }
  }
  
  // Write EXIF data to image file
  if (Object.keys(tagsToWrite).length > 0) {
    if (dryRun) {
      if (verbose) {
        console.log(chalk.blue(`  [DRY RUN] Would write EXIF tags: ${Object.keys(tagsToWrite).join(', ')}`));
        for (const [tagName, value] of Object.entries(tagsToWrite)) {
          if (typeof value === 'string') {
            console.log(chalk.blue(`    ${tagName}: ${value.substring(0, 100)}${value.length > 100 ? '...' : ''}`));
          }
        }

      }
    } else {
      await writeExifData(imagePath, tagsToWrite, config.preserveOriginal, verbose, avoidOverwriteMap);
    }
  } else {
    console.warn(chalk.yellow(`  Warning: No EXIF data generated`));
  }
}
