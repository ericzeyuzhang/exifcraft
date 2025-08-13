/**
 * Type definitions for ExifCraft
 */

import { WriteTags } from 'exiftool-vendored';

export interface TagConfig {
  name: keyof WriteTags;
  allowOverwrite: boolean;
}

export interface TaskConfig {
  name: string;
  tags: TagConfig[];
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

export interface JobSetting {
  directory?: string;
  files?: string[];
  config: ExifCraftConfig;
  verbose: boolean;
  dryRun: boolean;
}

// CLI options from commander.js
export interface CLIOptions {
  directory?: string;
  files?: string[];
  config: string;
  verbose: boolean;
  dryRun: boolean;
}