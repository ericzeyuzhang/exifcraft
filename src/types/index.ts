/**
 * Type definitions for ExifCraft
 */

import { TagName } from 'exiftool-vendored/dist/Tags';

export interface PromptConfig {
  name: string;
  prompt: string;
  exifTags: TagName[];
}

export interface AIModelConfig {
  provider: AIModelProvider;
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
  prompts: PromptConfig[];
  aiModel: AIModelConfig;
  imageFormats: string[];
  overwriteOriginal: boolean;
}

export interface ProcessingOptions {
  directory?: string;
  files?: string[];
  config: ExifCraftConfig;
  verbose: boolean;
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
}



export type AIModelProvider = 'ollama' | 'openai' | 'gemini';
