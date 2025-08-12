import { app, BrowserWindow, ipcMain, dialog, Menu } from 'electron';
import * as path from 'path';
import { processImages } from '../lib/processor';
import { loadConfig, validateConfig } from '../lib/configProvider';
import { Logger } from '../lib/logger';

let mainWindow: BrowserWindow | null = null;
const logger = Logger.getInstance({ verbose: true, dryRun: false });

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    titleBarStyle: 'default',
    show: false
  });

  mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

  mainWindow.once('ready-to-show', () => {
    mainWindow?.show();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // 开发模式下打开开发者工具
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }
}

// 创建菜单
function createMenu(): void {
  const template: Electron.MenuItemConstructorOptions[] = [
    {
      label: 'File',
      submenu: [
        {
          label: 'Open Images',
          accelerator: 'CmdOrCtrl+O',
          click: async () => {
            const result = await dialog.showOpenDialog(mainWindow!, {
              properties: ['openFile', 'multiSelections'],
              filters: [
                { name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'heic', 'heif'] }
              ]
            });
            
            if (!result.canceled && result.filePaths.length > 0) {
              mainWindow?.webContents.send('files-selected', result.filePaths);
            }
          }
        },
        {
          label: 'Open Folder',
          accelerator: 'CmdOrCtrl+Shift+O',
          click: async () => {
            const result = await dialog.showOpenDialog(mainWindow!, {
              properties: ['openDirectory']
            });
            
            if (!result.canceled && result.filePaths.length > 0) {
              mainWindow?.webContents.send('folder-selected', result.filePaths[0]);
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Exit',
          accelerator: process.platform === 'darwin' ? 'Cmd+Q' : 'Ctrl+Q',
          click: () => {
            app.quit();
          }
        }
      ]
    },
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' }
      ]
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// IPC 处理器
ipcMain.handle('select-files', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openFile', 'multiSelections'],
    filters: [
      { name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'heic', 'heif'] }
    ]
  });
  
  return result.canceled ? [] : result.filePaths;
});

ipcMain.handle('select-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openDirectory']
  });
  
  return result.canceled ? null : result.filePaths[0];
});

ipcMain.handle('process-images', async (event, config: any, filePaths: string[]) => {
  try {
    // 验证配置
    validateConfig(config);
    
    // 创建处理任务
    const jobSetting = {
      files: filePaths,
      directory: undefined,
      config: config,
      verbose: true,
      dryRun: false
    };
    
    // 处理图片
    await processImages(jobSetting, logger);
    
    return {
      success: true,
      message: 'Processing completed successfully'
    };
  } catch (error) {
    logger.showError('Error processing images:', error instanceof Error ? error : new Error(String(error)));
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

ipcMain.handle('save-config', async (event, config: any) => {
  try {
    const result = await dialog.showSaveDialog(mainWindow!, {
      defaultPath: 'exifcraft-config.json',
      filters: [
        { name: 'JSON Files', extensions: ['json'] }
      ]
    });
    
    if (!result.canceled && result.filePath) {
      const fs = require('fs').promises;
      await fs.writeFile(result.filePath, JSON.stringify(config, null, 2));
      return { success: true, path: result.filePath };
    }
    
    return { success: false };
  } catch (error) {
    logger.showError('Error saving config:', error instanceof Error ? error : new Error(String(error)));
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

ipcMain.handle('load-config', async () => {
  try {
    const result = await dialog.showOpenDialog(mainWindow!, {
      properties: ['openFile'],
      filters: [
        { name: 'JSON Files', extensions: ['json'] }
      ]
    });
    
    if (!result.canceled && result.filePaths.length > 0) {
      const fs = require('fs').promises;
      const configData = await fs.readFile(result.filePaths[0], 'utf8');
      const config = JSON.parse(configData);
      return { success: true, config };
    }
    
    return { success: false };
  } catch (error) {
    logger.showError('Error loading config:', error instanceof Error ? error : new Error(String(error)));
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

app.whenReady().then(() => {
  createWindow();
  createMenu();
  
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
