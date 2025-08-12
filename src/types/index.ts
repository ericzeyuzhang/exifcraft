/**
 * Type definitions for ExifCraft
 */

import { TagName } from 'exiftool-vendored/dist/Tags';

export interface TaskConfig {
  name: string;
  tags: TagName[];
  prompt: string;
}

export interface AIModelConfig {
  provider: 'ollama' | 'openai' | 'gemini';
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
}

export interface ProcessingJob {
  directory?: string;
  files?: string[];
  config: ExifCraftConfig;
  verbose: boolean;
  dryRun: boolean;
}

export type ExifData = {
  [K in TagName]?: string;
};

// CLI options from commander.js
export interface CLIOptions {
  directory?: string;
  files?: string[];
  config: string;
  verbose: boolean;
  dryRun: boolean;
}