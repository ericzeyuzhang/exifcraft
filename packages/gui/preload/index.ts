import { contextBridge, ipcRenderer } from 'electron';

export const api = {
  selectDirectory: (): Promise<string | null> => ipcRenderer.invoke('selectDirectory'),
  runJob: (args: { directory?: string; files?: string[]; configPath: string; verbose?: boolean; dryRun?: boolean; }): Promise<{ ok: boolean; message?: string; }> => ipcRenderer.invoke('runJob', args),
  onProgress: (handler: (payload: { currentIndex: number; total: number; fileName: string; }) => void) => {
    ipcRenderer.on('progress', (_event, payload) => handler(payload));
  },
  listImages: (directory: string): Promise<{ ok: boolean; files?: string[]; message?: string }> => ipcRenderer.invoke('listImages', directory),
  getThumbnail: (args: { filePath: string; width?: number; height?: number }): Promise<{ ok: boolean; dataUrl?: string; message?: string }> => ipcRenderer.invoke('getThumbnail', args),
  importConfig: (filePath: string): Promise<{ ok: boolean; config?: any; message?: string }> => ipcRenderer.invoke('importConfig', filePath),
  exportConfig: (args: { filePath: string; config: any }): Promise<{ ok: boolean; message?: string }> => ipcRenderer.invoke('exportConfig', args),
  selectConfigFile: (): Promise<string | null> => ipcRenderer.invoke('selectConfigFile')
};

declare global {
  interface Window {
    exifcraft: typeof api;
  }
}

contextBridge.exposeInMainWorld('exifcraft', api);


