import { contextBridge, ipcRenderer } from 'electron';

// 暴露安全的API给渲染进程
contextBridge.exposeInMainWorld('exifcraftAPI', {
  // 文件选择
  selectFiles: () => ipcRenderer.invoke('select-files'),
  selectFolder: () => ipcRenderer.invoke('select-folder'),
  
  // 图片处理
  processImages: (config: any, filePaths: string[]) => 
    ipcRenderer.invoke('process-images', config, filePaths),
  
  // 配置管理
  saveConfig: (config: any) => ipcRenderer.invoke('save-config', config),
  loadConfig: () => ipcRenderer.invoke('load-config'),
  
  // 事件监听
  onFilesSelected: (callback: (files: string[]) => void) => {
    ipcRenderer.on('files-selected', (event, files) => callback(files));
  },
  
  onFolderSelected: (callback: (folder: string) => void) => {
    ipcRenderer.on('folder-selected', (event, folder) => callback(folder));
  },
  
  // 移除事件监听
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel);
  }
});

// 类型定义
declare global {
  interface Window {
    exifcraftAPI: {
      selectFiles: () => Promise<string[]>;
      selectFolder: () => Promise<string | null>;
      processImages: (config: any, filePaths: string[]) => Promise<any>;
      saveConfig: (config: any) => Promise<any>;
      loadConfig: () => Promise<any>;
      onFilesSelected: (callback: (files: string[]) => void) => void;
      onFolderSelected: (callback: (folder: string) => void) => void;
      removeAllListeners: (channel: string) => void;
    };
  }
}
