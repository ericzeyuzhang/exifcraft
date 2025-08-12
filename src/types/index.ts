/**
 * Type definitions for ExifCraft
 */

export interface PromptConfig {
  name: string;
  prompt: string;
  exifTags: string[];
}

export interface AIModelOptions {
  temperature?: number;
  max_tokens?: number;
  apiKey?: string;
  headers?: Record<string, string>;
}

export interface AIModelConfig {
  type: 'ollama' | 'openai' | 'custom';
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
  model: string;
  verbose: boolean;
}

export interface ExifData {
  [tagName: string]: string;
}

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

export interface AIResponse {
  response: string;
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

export type AIModelType = 'ollama' | 'openai' | 'custom';

export type LogLevel = 'info' | 'warn' | 'error' | 'success';
