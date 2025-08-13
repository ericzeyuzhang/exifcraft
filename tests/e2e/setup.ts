import { beforeAll, afterAll } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';

const TEST_IMAGES_DIR = path.join(__dirname, '../images');
const DEMO_DIR = path.join(TEST_IMAGES_DIR, 'demo');
const ORIGINAL_DIR = path.join(TEST_IMAGES_DIR, 'original');

export const setupTestEnvironment = () => {
  beforeAll(async () => {
    // Ensure demo directory exists
    if (!fs.existsSync(DEMO_DIR)) {
      fs.mkdirSync(DEMO_DIR, { recursive: true });
    }
    
    // Clean demo directory safely
    if (fs.existsSync(DEMO_DIR)) {
      const demoFiles = fs.readdirSync(DEMO_DIR);
      for (const file of demoFiles) {
        const filePath = path.join(DEMO_DIR, file);
        try {
          if (fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
          }
        } catch (error) {
          // Ignore errors if file doesn't exist
          console.warn(`Could not delete ${filePath}:`, error);
        }
      }
    }
    
    // Copy original files to demo
    const originalFiles = fs.readdirSync(ORIGINAL_DIR);
    for (const file of originalFiles) {
      const sourcePath = path.join(ORIGINAL_DIR, file);
      const destPath = path.join(DEMO_DIR, file);
      if (fs.statSync(sourcePath).isFile()) {
        fs.copyFileSync(sourcePath, destPath);
      }
    }
  });

  afterAll(async () => {
    // Clean up demo directory after tests
    if (fs.existsSync(DEMO_DIR)) {
      const demoFiles = fs.readdirSync(DEMO_DIR);
      for (const file of demoFiles) {
        const filePath = path.join(DEMO_DIR, file);
        try {
          if (fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
          }
        } catch (error) {
          // Ignore errors if file doesn't exist
          console.warn(`Could not delete ${filePath}:`, error);
        }
      }
    }
  });
};
