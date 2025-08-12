import { promises as fs } from 'fs';
import { ExifCraftConfig } from '../types';

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
  if (!config.tasks || !Array.isArray(config.tasks)) {
    throw new Error('Configuration file must contain tasks array');
  }
  
  if (config.tasks.length === 0) {
    throw new Error('At least one task config must be configured');
  }
  
  for (let i = 0; i < config.tasks.length; i++) {
    const taskConfig = config.tasks[i];
    
    if (!taskConfig.name || typeof taskConfig.name !== 'string') {
      throw new Error(`taskConfig[${i}] must contain a valid name field`);
    }
    
    if (!taskConfig.prompt || typeof taskConfig.prompt !== 'string') {
      throw new Error(`taskConfig[${i}] must contain a valid prompt field`);
    }
    
    if (!taskConfig.tags || !Array.isArray(taskConfig.tags) || taskConfig.tags.length === 0) {
      throw new Error(`taskConfig[${i}] must contain at least one tags`);
    }
    
    // Validate each tag configuration
    for (let j = 0; j < taskConfig.tags.length; j++) {
      const tagConfig = taskConfig.tags[j];
      if (!tagConfig.name) {
        throw new Error(`taskConfig[${i}].tags[${j}] must contain a valid name field`);
      }
      if (typeof tagConfig.allowOverwrite !== 'boolean') {
        throw new Error(`taskConfig[${i}].tags[${j}] must contain a valid allowOverwrite field`);
      }
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


