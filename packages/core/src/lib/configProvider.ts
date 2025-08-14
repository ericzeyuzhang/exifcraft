import * as path from 'path';
import { ExifCraftConfig } from '../models/types';

/**
 * Load TypeScript configuration file
 */
export async function loadConfig(configPath: string): Promise<ExifCraftConfig> {
  try {
    const ext = path.extname(configPath);
    
    if (ext !== '.ts') {
      throw new Error(`Configuration file must be a TypeScript file (.ts), got: ${ext}`);
    }
    
    // Load TypeScript configuration
    const configModule = await import(path.resolve(configPath));
    const config = configModule.default as ExifCraftConfig;
    
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
  // Validate tasks
  if (!Array.isArray(config.tasks) || config.tasks.length === 0) {
    throw new Error('Configuration must contain at least one task');
  }
  
  // Validate each task
  config.tasks.forEach((task: any, i: number) => {
    if (!task.name || !task.prompt || !Array.isArray(task.tags) || task.tags.length === 0) {
      throw new Error(`Task[${i}] must have name, prompt, and at least one tag`);
    }
    
    // Validate tags
    task.tags.forEach((tag: any, j: number) => {
      if (!tag.name || typeof tag.allowOverwrite !== 'boolean') {
        throw new Error(`Task[${i}].tag[${j}] must have name and allowOverwrite`);
      }
    });
  });
  
  // Validate AI model
  if (!config.aiModel?.provider || !config.aiModel?.endpoint) {
    throw new Error('AI model must have provider and endpoint');
  }
  
  // Validate image formats
  if (config.imageFormats && Array.isArray(config.imageFormats)) {
    const invalid = config.imageFormats.filter((f: any) => typeof f !== 'string' || !f.startsWith('.'));
    if (invalid.length > 0) {
      throw new Error(`Invalid formats: ${invalid.join(', ')}. Must start with '.'`);
    }
  }
  
  // Validate preserveOriginal
  if (config.preserveOriginal !== undefined && typeof config.preserveOriginal !== 'boolean') {
    throw new Error('preserveOriginal must be boolean');
  }
}


