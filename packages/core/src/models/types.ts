/**
 * Type definitions for ExifCraft
 */

import { TagName } from 'exiftool-vendored/dist/Tags';

export interface TagConfig {
  name: TagName;
  allowOverwrite: boolean;
}

export interface TaskConfig {
  name: string;
  tags: TagConfig[];
  prompt: string;
  enabled?: boolean;
}

export interface AIModelConfig {
  provider: 'ollama' | 'openai' | 'gemini' | 'mock';
  /** Placeholder for online model (e.g. OpenAI, Gemini) api key */
  key?: string;
  endpoint: string;
  model: string;
  options?: {
    temperature?: number;
    max_tokens?: number;
  };
}

export interface ExifCraftConfig {
  tasks: TaskConfig[];
  aiModel: AIModelConfig;
  imageFormats: string[];
  preserveOriginal: boolean;
  basePrompt?: string;
  // For Lightroom plugin only
  verbose?: boolean;
  // For Lightroom plugin only
  dryRun?: boolean;
}



// CLI options from commander.js
export interface CLIOptions {
  directory?: string;
  files?: string[];
  config: string;
  verbose: boolean;
  dryRun: boolean;
}

// Job settings derived from CLI options
export interface JobSetting extends Omit<CLIOptions, 'config'> {
  config: ExifCraftConfig;
}

// Image processing types
export type ImageConverter = (imagePath: string) => Promise<Buffer>;