/**
 * Type definitions for ExifCraft
 */

import { TagName } from 'exiftool-vendored/dist/Tags';

export interface PromptConfig {
  name: string;
  prompt: string;
  exifTags: TagName[];
}

export interface AIModelOptions {
  temperature?: number;
  max_tokens?: number;
  // Placeholder for OpenAI/Gemini specific options
  apiKey?: string;
  headers?: Record<string, string>;
}

export interface AIModelConfig {
  provider: AIModelProvider;
  endpoint: string;
  model: string;
  options?: AIModelOptions;
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

export interface ImageInfo {
  path: string;
  name: string;
  extension: string;
  size: number;
  modified: Date;
  directory: string;
}

export interface CLIOptions {
  directory?: string;
  files?: string[];
  config: string;
  model: string;
  verbose: boolean;
}

// ExifTool write options
export interface WriteOptions {
  writeArgs?: string[];
}

// Utility types
export type SupportedImageFormat = 
  | '.jpg' | '.jpeg' | '.jpe'
  | '.png' 
  | '.tiff' | '.tif'
  | '.webp'
  | '.heic' | '.heif'
  | '.raw' | '.cr2' | '.nef' | '.arw' | '.dng' | '.orf' | '.rw2' | '.pef' | '.srw'
  | '.bmp'
  | '.gif';

export type AIModelProvider = 'ollama' | 'openai' | 'gemini';

export type LogLevel = 'info' | 'warn' | 'error' | 'success';
