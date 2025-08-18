import * as path from 'path';
import * as fs from 'fs';
import { ExifCraftConfig } from '../models/types';

/**
 * Load configuration file (supports both TypeScript .ts and JSON .json formats)
 */
export async function loadConfig(configPath: string): Promise<ExifCraftConfig> {
  try {
    const ext = path.extname(configPath);
    let config: ExifCraftConfig;
    
    if (ext === '.ts') {
      // Load TypeScript configuration
      const configModule = await import(path.resolve(configPath));
      config = configModule.default as ExifCraftConfig;
    } else if (ext === '.json') {
      // Load JSON configuration
      const configContent = fs.readFileSync(configPath, 'utf-8');
      config = JSON.parse(configContent) as ExifCraftConfig;
    } else {
      throw new Error(`Configuration file must be either TypeScript (.ts) or JSON (.json), got: ${ext}`);
    }
    
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
    const invalid = config.imageFormats.filter((f: any) => typeof f !== 'string' || f.length === 0);
    if (invalid.length > 0) {
      throw new Error(`Invalid image formats: ${invalid.join(', ')}. Must be non-empty strings`);
    }
  }
  
  // Validate preserveOriginal
  if (config.preserveOriginal !== undefined && typeof config.preserveOriginal !== 'boolean') {
    throw new Error('preserveOriginal must be boolean');
  }
}


