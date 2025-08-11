const fs = require('fs').promises;
const path = require('path');

/**
 * Load configuration file
 * @param {string} configPath - Configuration file path
 * @returns {Promise<Object>} Configuration object
 */
async function loadConfig(configPath) {
  try {
    const configData = await fs.readFile(configPath, 'utf8');
    const config = JSON.parse(configData);
    
    // Validate configuration format
    validateConfig(config);
    
    return config;
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`Configuration file does not exist: ${configPath}`);
    } else if (error instanceof SyntaxError) {
      throw new Error(`Configuration file format error: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Validate configuration file format
 * @param {Object} config - Configuration object
 */
function validateConfig(config) {
  if (!config.prompts || !Array.isArray(config.prompts)) {
    throw new Error('Configuration file must contain prompts array');
  }
  
  if (config.prompts.length === 0) {
    throw new Error('At least one prompt must be configured');
  }
  
  for (let i = 0; i < config.prompts.length; i++) {
    const prompt = config.prompts[i];
    
    if (!prompt.name || typeof prompt.name !== 'string') {
      throw new Error(`prompt[${i}] must contain a valid name field`);
    }
    
    if (!prompt.prompt || typeof prompt.prompt !== 'string') {
      throw new Error(`prompt[${i}] must contain a valid prompt field`);
    }
    
    if (!prompt.exifTags || !Array.isArray(prompt.exifTags) || prompt.exifTags.length === 0) {
      throw new Error(`prompt[${i}] must contain at least one exifTags`);
    }
  }
  
  if (!config.aiModel || typeof config.aiModel !== 'object') {
    throw new Error('Configuration file must contain aiModel configuration');
  }
  
  if (!config.aiModel.type || !config.aiModel.endpoint) {
    throw new Error('aiModel must contain type and endpoint fields');
  }
  
  // Validate imageFormats if present
  if (config.imageFormats && Array.isArray(config.imageFormats)) {
    const invalidFormats = config.imageFormats.filter(format => 
      typeof format !== 'string' || !format.startsWith('.')
    );
    if (invalidFormats.length > 0) {
      throw new Error(`Invalid image formats found: ${invalidFormats.join(', ')}. Formats must be strings starting with a dot (e.g., '.jpg')`);
    }
  }
}

/**
 * Get default configuration
 * @returns {Object} Default configuration object
 */
function getDefaultConfig() {
  return {
    prompts: [
      {
        name: "description",
        prompt: "Please describe this image in detail.",
        exifTags: ["ImageDescription"]
      }
    ],
    aiModel: {
      type: "ollama",
      endpoint: "http://localhost:11434/api/generate",
      model: "llava"
    },
    imageFormats: [".jpg", ".jpeg", ".png"],
    overwriteOriginal: true
  };
}

module.exports = {
  loadConfig,
  validateConfig,
  getDefaultConfig
};
