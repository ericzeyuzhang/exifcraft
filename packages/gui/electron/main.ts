import { app, BrowserWindow, dialog, ipcMain } from 'electron';
import * as path from 'path';
import { Logger, processImages, loadConfig } from 'exifcraft-core';
import * as fs from 'fs';

let mainWindow: BrowserWindow | null = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, '../dist-preload/index.js'),
      nodeIntegration: false,
      contextIsolation: true
    }
  });

  const devUrl = 'http://localhost:5173';
  const prodUrl = `file://${path.join(__dirname, '../dist-renderer/index.html')}`;
  const isDev = process.env.NODE_ENV !== 'production';
  mainWindow.loadURL(isDev ? devUrl : prodUrl);

  if (isDev) {
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  }

  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL) => {
    // eslint-disable-next-line no-console
    console.error('Failed to load URL:', validatedURL, errorCode, errorDescription);
  });
  mainWindow.webContents.on('did-finish-load', () => {
    // eslint-disable-next-line no-console
    console.log('Renderer loaded successfully');
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('selectDirectory', async () => {
  if (!mainWindow) return null;
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openDirectory']
  });
  if (result.canceled || result.filePaths.length === 0) return null;
  return result.filePaths[0];
});

ipcMain.handle('runJob', async (_e, args: { directory?: string; files?: string[]; configPath: string; verbose?: boolean; dryRun?: boolean; }) => {
  const logger = Logger.getInstance({ verbose: !!args.verbose, dryRun: !!args.dryRun });
  logger.setProgressCallback((update) => {
    mainWindow?.webContents.send('progress', update);
  });

  try {
    const config = await loadConfig(args.configPath);
    await processImages({
      directory: args.directory,
      files: args.files,
      config,
      verbose: !!args.verbose,
      dryRun: !!args.dryRun
    }, logger);
    return { ok: true };
  } catch (err) {
    const message = (err as Error).message;
    return { ok: false, message };
  }
});

// Basic helpers for thumbnails
const allowed = new Set([
  'jpg','jpeg','png','webp','heic','heif',
  'tif','tiff',
  'dng','arw','nef','cr2','cr3','raw','raf'
]);

ipcMain.handle('listImages', async (_e, directory: string) => {
  const fs = await import('fs');
  const fsp = fs.promises as typeof import('fs').promises;
  try {
    const entries = await fsp.readdir(directory, { withFileTypes: true });
    const files = entries
      .filter((d) => d.isFile())
      .map((d) => path.join(directory, d.name))
      .filter((p) => allowed.has(path.extname(p).slice(1).toLowerCase()));
    return { ok: true, files };
  } catch (err) {
    return { ok: false, message: (err as Error).message };
  }
});

ipcMain.handle('getThumbnail', async (_e, args: { filePath: string; width?: number; height?: number }) => {
  try {
    const sharp = (await import('sharp')).default;
    const w = args.width ?? 256;
    const h = args.height ?? 256;
    const buf = await sharp(args.filePath).resize(w, h, { fit: 'inside' }).jpeg({ quality: 70 }).toBuffer();
    const base64 = buf.toString('base64');
    return { ok: true, dataUrl: `data:image/jpeg;base64,${base64}` };
  } catch (err) {
    return { ok: false, message: (err as Error).message };
  }
});

ipcMain.handle('importConfig', async (_e, filePath: string) => {
  try {
    const content = await fs.promises.readFile(filePath, 'utf-8');
    const json = JSON.parse(content);
    return { ok: true, config: json };
  } catch (err) {
    return { ok: false, message: (err as Error).message };
  }
});

ipcMain.handle('exportConfig', async (_e, args: { filePath: string; config: any }) => {
  try {
    await fs.promises.writeFile(args.filePath, JSON.stringify(args.config, null, 2), 'utf-8');
    return { ok: true };
  } catch (err) {
    return { ok: false, message: (err as Error).message };
  }
});

ipcMain.handle('selectConfigFile', async () => {
  if (!mainWindow) return null;
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [{ name: 'Config', extensions: ['json', 'jsonc'] }]
  });
  if (result.canceled || result.filePaths.length === 0) return null;
  return result.filePaths[0];
});


