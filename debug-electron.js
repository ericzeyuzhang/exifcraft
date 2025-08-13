#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

console.log('🔍 Debugging Electron application...');

// Start Electron with debugging enabled
const electronProcess = spawn('npx', ['electron', '.', '--enable-logging', '--v=1'], {
  stdio: 'inherit',
  cwd: __dirname,
  env: { 
    ...process.env, 
    NODE_ENV: 'development',
    ELECTRON_ENABLE_LOGGING: 'true'
  }
});

electronProcess.on('close', (code) => {
  console.log(`Electron process exited with code ${code}`);
  process.exit(code);
});

electronProcess.on('error', (error) => {
  console.error('Failed to start Electron:', error);
  process.exit(1);
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down...');
  electronProcess.kill();
  process.exit(0);
});
