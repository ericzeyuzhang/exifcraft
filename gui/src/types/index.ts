// Type definitions for ExifCraft GUI
import { TagName } from 'exiftool-vendored/dist/Tags';

export interface TagConfig {
  name: TagName;
  allowOverwrite: boolean;
}

export interface TaskConfig {
  name: string;
  tags: TagConfig[];
  prompt: string;
}

export interface AIModelConfig {
  provider: 'ollama' | 'openai' | 'gemini';
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

export interface ProcessingResult {
  success: boolean;
  error?: string;
}

export interface FileItem {
  path: string;
  name: string;
  size: number;
  type: string;
  selected: boolean;
}

export interface ProcessingStatus {
  total: number;
  current: number;
  status: 'idle' | 'processing' | 'completed' | 'error';
  message: string;
}
