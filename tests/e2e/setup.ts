import { beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

const TEST_IMAGES_DIR = path.join(process.cwd(), 'tests/images');
const DEMO_DIR = path.join(TEST_IMAGES_DIR, 'demo');
const ORIGINAL_DIR = path.join(TEST_IMAGES_DIR, 'original');

export const resetTestEnvironment = () => {
  // Ensure demo directory exists
  if (!fs.existsSync(DEMO_DIR)) {
    fs.mkdirSync(DEMO_DIR, { recursive: true });
  }
  
  // Clean demo directory safely
  if (fs.existsSync(DEMO_DIR)) {
    try {
      const demoFiles = fs.readdirSync(DEMO_DIR);
      for (const file of demoFiles) {
        const filePath = path.join(DEMO_DIR, file);
        try {
          // Check if file still exists before trying to delete
          if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
          }
        } catch (error) {
          // Ignore errors if file doesn't exist or can't be deleted
          // This is expected in some cases due to race conditions
        }
      }
    } catch (error) {
      // Ignore errors if directory is empty or doesn't exist
    }
  }
  
  // Copy all files from original to demo
  const originalFiles = fs.readdirSync(ORIGINAL_DIR);
  for (const file of originalFiles) {
    const sourcePath = path.join(ORIGINAL_DIR, file);
    const destPath = path.join(DEMO_DIR, file);
    
    // Copy all files (not just supported formats)
    if (fs.statSync(sourcePath).isFile()) {
      fs.copyFileSync(sourcePath, destPath);
      console.log(`Copied ${file} to demo directory`);
    }
  }
};

export const cleanTestEnvironment = () => {
  // Only clean, don't copy files back
  if (fs.existsSync(DEMO_DIR)) {
    try {
      const demoFiles = fs.readdirSync(DEMO_DIR);
      for (const file of demoFiles) {
        const filePath = path.join(DEMO_DIR, file);
        try {
          // Check if file still exists before trying to delete
          if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
          }
        } catch (error) {
          // Ignore errors if file doesn't exist or can't be deleted
          // This is expected in some cases due to race conditions
        }
      }
    } catch (error) {
      // Ignore errors if directory is empty or doesn't exist
    }
  }
};

// Reset environment before each test
beforeEach(async () => {
  resetTestEnvironment();
});

// Clean up after each test
afterEach(async () => {
  cleanTestEnvironment();
});