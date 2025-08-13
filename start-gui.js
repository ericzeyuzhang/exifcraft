#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

console.log('Starting ExifCraft GUI...');

// Start the Electron app
const electronProcess = spawn('npx', ['electron', '.'], {
  stdio: 'inherit',
  cwd: __dirname
});

electronProcess.on('close', (code) => {
  console.log(`Electron process exited with code ${code}`);
  process.exit(code);
});

electronProcess.on('error', (error) => {
  console.error('Failed to start Electron:', error);
  process.exit(1);
});
