import { promises as fs } from 'fs';
import { ExifCraftConfig, TagGenerationConfig, AIModelConfig } from '../types';

/**
 * Load configuration file
 */
export async function loadConfig(configPath: string): Promise<ExifCraftConfig> {
  try {
    const configData = await fs.readFile(configPath, 'utf8');
    const config = JSON.parse(configData) as ExifCraftConfig;
    
    // Validate configuration format
    validateConfig(config);
    
    return config;
  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    if (err.code === 'ENOENT') {
      throw new Error(`Configuration file does not exist: ${configPath}`);
    } else if (error instanceof SyntaxError) {
      throw new Error(`Configuration file format error: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Validate configuration file format
 */
export function validateConfig(config: any): asserts config is ExifCraftConfig {
  if (!config.tagGeneration || !Array.isArray(config.tagGeneration)) {
    throw new Error('Configuration file must contain tagGeneration array');
  }
  
  if (config.tagGeneration.length === 0) {
    throw new Error('At least one tag generation config must be configured');
  }
  
  for (let i = 0; i < config.tagGeneration.length; i++) {
    const tagGenerationConfig = config.tagGeneration[i];
    
    if (!tagGenerationConfig.name || typeof tagGenerationConfig.name !== 'string') {
      throw new Error(`prompt[${i}] must contain a valid name field`);
    }
    
    if (!tagGenerationConfig.prompt || typeof tagGenerationConfig.prompt !== 'string') {
      throw new Error(`prompt[${i}] must contain a valid prompt field`);
    }
    
    if (!tagGenerationConfig.exifTags || !Array.isArray(tagGenerationConfig.exifTags) || tagGenerationConfig.exifTags.length === 0) {
      throw new Error(`prompt[${i}] must contain at least one exifTags`);
    }
  }
  
  if (!config.aiModel || typeof config.aiModel !== 'object') {
    throw new Error('Configuration file must contain aiModel configuration');
  }
  
  if (!config.aiModel.provider || !config.aiModel.endpoint) {
    throw new Error('aiModel must contain provider and endpoint fields');
  }
  
  // Validate imageFormats if present
  if (config.imageFormats && Array.isArray(config.imageFormats)) {
    const invalidFormats = config.imageFormats.filter((format: any) => 
      typeof format !== 'string' || !format.startsWith('.')
    );
    if (invalidFormats.length > 0) {
      throw new Error(`Invalid image formats found: ${invalidFormats.join(', ')}. Formats must be strings starting with a dot (e.g., '.jpg')`);
    }
  }
  
  // Validate preserveOriginal
  if (config.preserveOriginal !== undefined && typeof config.preserveOriginal !== 'boolean') {
    throw new Error('preserveOriginal must be a boolean value');
  }
}


