import { contextBridge, ipcRenderer } from 'electron';

// Type definitions
interface TagConfig {
  name: string;
  allowOverwrite: boolean;
}

interface TaskConfig {
  name: string;
  tags: TagConfig[];
  prompt: string;
}

interface AIModelConfig {
  provider: 'ollama' | 'openai' | 'gemini';
  key?: string;
  endpoint: string;
  model: string;
  options?: {
    temperature?: number;
    max_tokens?: number;
  };
}

interface ExifCraftConfig {
  tasks: TaskConfig[];
  aiModel: AIModelConfig;
  imageFormats: string[];
  preserveOriginal: boolean;
  basePrompt?: string;
}

interface JobSetting {
  directory?: string;
  files?: string[];
  config: ExifCraftConfig;
  verbose: boolean;
  dryRun: boolean;
}

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // File operations
  selectFiles: () => ipcRenderer.invoke('select-files'),
  selectDirectory: () => ipcRenderer.invoke('select-directory'),
  
  // Configuration operations
  saveConfig: (config: ExifCraftConfig) => ipcRenderer.invoke('save-config', config),
  loadConfig: () => ipcRenderer.invoke('load-config'),
  getDefaultConfig: () => ipcRenderer.invoke('get-default-config'),
  
  // Processing operations
  processImages: (jobSetting: JobSetting) => ipcRenderer.invoke('process-images', jobSetting),
  
  // Menu events
  onMenuOpenImages: (callback: () => void) => {
    ipcRenderer.on('menu-open-images', callback);
  },
  onMenuOpenDirectory: (callback: () => void) => {
    ipcRenderer.on('menu-open-directory', callback);
  },
  
  // Remove listeners
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel);
  }
});

// Type definitions for the exposed API
declare global {
  interface Window {
    electronAPI: {
      selectFiles: () => Promise<string[]>;
      selectDirectory: () => Promise<string>;
      saveConfig: (config: ExifCraftConfig) => Promise<string | null>;
      loadConfig: () => Promise<ExifCraftConfig | null>;
      getDefaultConfig: () => Promise<ExifCraftConfig>;
      processImages: (jobSetting: JobSetting) => Promise<{ success: boolean; error?: string }>;
      onMenuOpenImages: (callback: () => void) => void;
      onMenuOpenDirectory: (callback: () => void) => void;
      removeAllListeners: (channel: string) => void;
    };
  }
}
