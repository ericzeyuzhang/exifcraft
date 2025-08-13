#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

console.log('🚀 Starting ExifCraft GUI in development mode...');

// Start GUI development server
console.log('📦 Starting GUI development server...');
const guiProcess = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  cwd: path.join(__dirname, 'gui'),
  shell: true
});

// Wait a bit for GUI server to start
setTimeout(() => {
  console.log('⚡ Starting Electron...');
  const electronProcess = spawn('npx', ['electron', '.'], {
    stdio: 'inherit',
    cwd: __dirname,
    env: { ...process.env, NODE_ENV: 'development' }
  });

  electronProcess.on('close', (code) => {
    console.log(`Electron process exited with code ${code}`);
    guiProcess.kill();
    process.exit(code);
  });

  electronProcess.on('error', (error) => {
    console.error('Failed to start Electron:', error);
    guiProcess.kill();
    process.exit(1);
  });
}, 3000);

guiProcess.on('error', (error) => {
  console.error('Failed to start GUI server:', error);
  process.exit(1);
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down...');
  guiProcess.kill();
  process.exit(0);
});
