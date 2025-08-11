const fs = require('fs').promises;
const path = require('path');
const { glob } = require('glob');

/**
 * Extract file extension in lowercase
 * @param {string} filePath - File path
 * @returns {string} File extension in lowercase (e.g., '.jpg')
 */
function getFileExtension(filePath) {
  return path.extname(filePath).toLowerCase();
}

/**
 * Check if file format is supported
 * @param {string} filePath - File path
 * @param {string[]} supportedFormats - Array of supported formats from config
 * @returns {boolean} Whether the file format is supported
 */
function isSupportedFormat(filePath, supportedFormats) {
  const ext = getFileExtension(filePath);
  return supportedFormats.includes(ext);
}

/**
 * Filter array of file paths to only include supported formats
 * @param {string[]} filePaths - Array of file paths
 * @param {string[]} supportedFormats - Array of supported formats
 * @returns {string[]} Filtered array of supported files
 */
function filterSupportedFiles(filePaths, supportedFormats) {
  return filePaths.filter(filePath => isSupportedFormat(filePath, supportedFormats));
}

/**
 * Get all image files in directory
 * @param {string} directory - Directory path
 * @param {string[]} supportedFormats - Supported image formats
 * @returns {Promise<string[]>} Array of image file paths
 */
async function getImageFiles(directory, supportedFormats) {
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
    if (error.code === 'ENOENT') {
      throw new Error(`Directory does not exist: ${directory}`);
    }
    throw error;
  }
}



/**
 * Get image file information
 * @param {string} imagePath - Image file path
 * @returns {Promise<Object>} Image file information
 */
async function getImageInfo(imagePath) {
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
    throw new Error(`Unable to get image information: ${error.message}`);
  }
}

/**
 * Validate if image file is readable
 * @param {string} imagePath - Image file path
 * @returns {Promise<boolean>} Whether it's readable
 */
async function validateImageFile(imagePath) {
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
    throw new Error(`Image file validation failed: ${error.message}`);
  }
}

module.exports = {
  // Core utility functions
  getFileExtension,
  isSupportedFormat,
  filterSupportedFiles,
  
  // Image-specific functions
  getImageFiles,
  getImageInfo,
  validateImageFile
};
