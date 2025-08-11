const fs = require('fs').promises;
const path = require('path');
const glob = require('glob');
const chalk = require('chalk');
const { getImageFiles, filterSupportedFiles } = require('./imageUtils');
const { generateAIResponse } = require('./aiClient');
const { writeExifData } = require('./exifWriter');

/**
 * Process image files
 * @param {Object} options - Processing options
 */
async function processImages(options) {
  const { directory, files, config, model, verbose } = options;
  
  // Get list of image files to process
  let imageFiles = [];
  
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
    
    console.log(chalk.yellow(`\n[${i + 1}/${imageFiles.length}] Processing: ${fileName}`));
    
    try {
      await processImage(imagePath, config, model, verbose);
      console.log(chalk.green(`✓ Completed: ${fileName}`));
    } catch (error) {
      console.error(chalk.red(`✗ Processing failed ${fileName}: ${error.message}`));
      if (verbose) {
        console.error(error.stack);
      }
    }
  }
}

/**
 * Process a single image file
 * @param {string} imagePath - Image file path
 * @param {Object} config - Configuration object
 * @param {string} model - AI model name
 * @param {boolean} verbose - Whether to show verbose output
 */
async function processImage(imagePath, config, model, verbose) {
  // Check if file exists
  try {
    await fs.access(imagePath);
  } catch (error) {
    throw new Error(`Image file does not exist: ${imagePath}`);
  }


  
  // Generate AI response for each prompt and write to EXIF
  const exifData = {};
  
  for (const promptConfig of config.prompts) {
    if (verbose) {
      console.log(`  Processing prompt: ${promptConfig.name}`);
    }
    
    try {
      // Call AI model to generate response
      const aiResponse = await generateAIResponse(
        imagePath,
        promptConfig.prompt,
        config.aiModel,
        verbose
      );
      
      if (verbose) {
        console.log(`  AI response: ${aiResponse.substring(0, 100)}${aiResponse.length > 100 ? '...' : ''}`);
      }
      
      // Write response to corresponding EXIF tags
      for (const tagName of promptConfig.exifTags) {
        exifData[tagName] = aiResponse;
      }
      
    } catch (error) {
      console.warn(chalk.yellow(`  Warning: prompt "${promptConfig.name}" processing failed: ${error.message}`));
    }
  }
  
  // Write EXIF data to image file
  if (Object.keys(exifData).length > 0) {
    await writeExifData(imagePath, exifData, config.overwriteOriginal, verbose);
  } else {
    console.warn(chalk.yellow(`  Warning: No EXIF data generated`));
  }
}

module.exports = {
  processImages,
  processImage
};
