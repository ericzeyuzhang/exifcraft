#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

console.log('🧪 Testing ExifCraft GUI...');

// Test 1: Check if GUI builds successfully
console.log('📦 Testing GUI build...');
const buildProcess = spawn('npm', ['run', 'gui:build'], {
  stdio: 'inherit',
  cwd: __dirname
});

buildProcess.on('close', (code) => {
  if (code === 0) {
    console.log('✅ GUI build successful!');
    
    // Test 2: Check if main project builds
    console.log('🔧 Testing main project build...');
    const mainBuildProcess = spawn('npm', ['run', 'build'], {
      stdio: 'inherit',
      cwd: __dirname
    });

    mainBuildProcess.on('close', (mainCode) => {
      if (mainCode === 0) {
        console.log('✅ Main project build successful!');
        console.log('\n🎉 All tests passed! GUI is ready to use.');
        console.log('\n📋 Next steps:');
        console.log('1. Run "npm run dev" to start the GUI in development mode');
        console.log('2. Run "npm run electron:build" to build the production app');
        console.log('3. Check GUI_README.md for detailed usage instructions');
      } else {
        console.error('❌ Main project build failed!');
        process.exit(mainCode);
      }
    });
  } else {
    console.error('❌ GUI build failed!');
    process.exit(code);
  }
});

buildProcess.on('error', (error) => {
  console.error('❌ Failed to run GUI build:', error);
  process.exit(1);
});
