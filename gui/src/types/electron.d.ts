// Electron API type declarations
import { ExifCraftConfig, JobSetting } from './index';

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
