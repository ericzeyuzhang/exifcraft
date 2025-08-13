/**
 * Lightroom Plugin Adapter
 * This module provides compatibility layer for Adobe Lightroom plugin integration
 */

import { ExifCraftConfig, JobSetting } from '../types';
import { processImages } from './processor';
import { loadConfig, validateConfig } from './configProvider';

export interface LightroomPluginConfig {
  // Lightroom specific configuration
  lightroomVersion: string;
  pluginVersion: string;
  // ExifCraft configuration
  exifCraftConfig: ExifCraftConfig;
}

export interface LightroomJobRequest {
  // Files from Lightroom
  filePaths: string[];
  // Lightroom catalog info
  catalogPath?: string;
  // Processing options
  dryRun?: boolean;
  verbose?: boolean;
}

export interface LightroomJobResponse {
  success: boolean;
  processedFiles: string[];
  failedFiles: Array<{ path: string; error: string }>;
  metadata: {
    totalFiles: number;
    processedCount: number;
    failedCount: number;
  };
}

/**
 * Process images for Lightroom plugin
 */
export async function processForLightroom(
  request: LightroomJobRequest,
  config: LightroomPluginConfig
): Promise<LightroomJobResponse> {
  try {
    // Convert Lightroom request to ExifCraft job setting
    const jobSetting: JobSetting = {
      files: request.filePaths,
      config: config.exifCraftConfig,
      verbose: request.verbose || false,
      dryRun: request.dryRun || false
    };

    // Process images using existing ExifCraft processor
    const { Logger } = require('./logger');
    const logger = new Logger();
    await processImages(jobSetting, logger);

    // Return success response
    return {
      success: true,
      processedFiles: request.filePaths,
      failedFiles: [],
      metadata: {
        totalFiles: request.filePaths.length,
        processedCount: request.filePaths.length,
        failedCount: 0
      }
    };
  } catch (error) {
    // Return error response
    return {
      success: false,
      processedFiles: [],
      failedFiles: request.filePaths.map(path => ({
        path,
        error: error instanceof Error ? error.message : 'Unknown error'
      })),
      metadata: {
        totalFiles: request.filePaths.length,
        processedCount: 0,
        failedCount: request.filePaths.length
      }
    };
  }
}

/**
 * Get default Lightroom plugin configuration
 */
export function getDefaultLightroomConfig(): LightroomPluginConfig {
  return {
    lightroomVersion: '12.0',
    pluginVersion: '1.0.0',
    exifCraftConfig: {
      tasks: [
        {
          name: "title",
          prompt: "Generate a title for this image",
          tags: [
            {
              name: "ImageTitle",
              allowOverwrite: true
            }
          ]
        },
        {
          name: "description",
          prompt: "Describe this image",
          tags: [
            {
              name: "ImageDescription",
              allowOverwrite: true
            }
          ]
        }
      ],
      aiModel: {
        provider: "ollama",
        endpoint: "http://localhost:11434/api/generate",
        model: "llava",
        options: {
          temperature: 0,
          max_tokens: 500
        }
      },
      imageFormats: [".jpg", ".jpeg", ".png", ".heic"],
      preserveOriginal: false,
      basePrompt: "You are a helpful assistant."
    }
  };
}

/**
 * Validate Lightroom plugin configuration
 */
export function validateLightroomConfig(config: LightroomPluginConfig): boolean {
  // Basic validation
  if (!config.lightroomVersion || !config.pluginVersion) {
    return false;
  }

  // Validate ExifCraft configuration
  try {
    validateConfig(config.exifCraftConfig);
    return true;
  } catch {
    return false;
  }
}

/**
 * Export functions for Lightroom plugin
 */
export const lightroomAdapter = {
  processForLightroom,
  getDefaultLightroomConfig,
  validateLightroomConfig
};
