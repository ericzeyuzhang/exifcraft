import { app, BrowserWindow, ipcMain, dialog, Menu } from 'electron';
import * as path from 'path';
import { processImages } from '../lib/processor';
import { loadConfig, validateConfig } from '../lib/configProvider';
import { JobSetting, ExifCraftConfig } from '../types';

let mainWindow: BrowserWindow | null = null;

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, '../assets/icon.png'),
    titleBarStyle: 'default'
  });

  // Load the React app
  if (process.env.NODE_ENV === 'development') {
    // Try multiple ports in case one is occupied
    const ports = [5173, 5174, 5175, 5176, 5177];
    let loaded = false;
    
    for (const port of ports) {
      try {
        await mainWindow.loadURL(`http://localhost:${port}`);
        loaded = true;
        break;
      } catch (error) {
        console.log(`Port ${port} not available, trying next...`);
      }
    }
    
    if (!loaded) {
      console.error('No available port found for GUI server');
      app.quit();
      return;
    }
    
    mainWindow.webContents.openDevTools();
  } else {
    // In production, load from the built GUI files
    const guiPath = path.join(__dirname, '../../gui/dist/index.html');
    mainWindow.loadFile(guiPath);
  }

  // Set up menu
  const template: Electron.MenuItemConstructorOptions[] = [
    {
      label: 'File',
      submenu: [
        {
          label: 'Open Images',
          accelerator: 'CmdOrCtrl+O',
          click: () => {
            mainWindow?.webContents.send('menu-open-images');
          }
        },
        {
          label: 'Open Directory',
          accelerator: 'CmdOrCtrl+Shift+O',
          click: () => {
            mainWindow?.webContents.send('menu-open-directory');
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

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// IPC handlers
ipcMain.handle('select-files', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openFile', 'multiSelections'],
    filters: [
      { name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'heic', 'tiff', 'bmp'] }
    ]
  });
  return result.filePaths;
});

ipcMain.handle('select-directory', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openDirectory']
  });
  return result.filePaths[0];
});

ipcMain.handle('save-config', async (event, config: ExifCraftConfig) => {
  const result = await dialog.showSaveDialog(mainWindow!, {
    filters: [
      { name: 'JSON Files', extensions: ['json'] }
    ]
  });
  
  if (!result.canceled && result.filePath) {
    const { promises: fs } = require('fs');
    await fs.writeFile(result.filePath, JSON.stringify(config, null, 2));
    return result.filePath;
  }
  return null;
});

ipcMain.handle('load-config', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openFile'],
    filters: [
      { name: 'JSON Files', extensions: ['json'] }
    ]
  });
  
  if (!result.canceled && result.filePaths.length > 0) {
    return await loadConfig(result.filePaths[0]);
  }
  return null;
});

ipcMain.handle('process-images', async (event, jobSetting: JobSetting) => {
  try {
    const { Logger } = require('../lib/logger');
    const logger = new Logger();
    await processImages(jobSetting, logger);
    return { success: true };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
  }
});

ipcMain.handle('get-default-config', () => {
  return {
    tasks: [
      {
        name: "title",
        prompt: "Generate a title for this image",
        tags: [
          {
            name: "ImageTitle",
            allowOverwrite: true
          }
        ]
      },
      {
        name: "description",
        prompt: "Describe this image",
        tags: [
          {
            name: "ImageDescription",
            allowOverwrite: true
          }
        ]
      }
    ],
    aiModel: {
      provider: "ollama",
      endpoint: "http://localhost:11434/api/generate",
      model: "llava",
      options: {
        temperature: 0,
        max_tokens: 500
      }
    },
    imageFormats: [".jpg", ".jpeg", ".png", ".heic"],
    preserveOriginal: false,
    basePrompt: "You are a helpful assistant."
  };
});
