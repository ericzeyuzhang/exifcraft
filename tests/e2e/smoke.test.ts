import { describe, it, expect } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import { setupTestEnvironment } from './setup';

describe('Smoke Tests', () => {
  setupTestEnvironment();

  it('should have test environment properly set up', () => {
    const demoDir = path.resolve('./tests/images/demo');
    const originalDir = path.resolve('./tests/images/original');
    
    // Check that directories exist
    expect(fs.existsSync(demoDir)).toBe(true);
    expect(fs.existsSync(originalDir)).toBe(true);
    
    // Check that demo directory has files copied from original
    const demoFiles = fs.readdirSync(demoDir);
    const originalFiles = fs.readdirSync(originalDir);
    
    expect(demoFiles.length).toBeGreaterThan(0);
    expect(demoFiles).toEqual(expect.arrayContaining(originalFiles));
  });

  it('should have exiftool-vendored available', async () => {
    const { exiftool } = require('exiftool-vendored');
    
    try {
      // Test that exiftool-vendored can be imported and used
      expect(exiftool).toBeDefined();
      expect(typeof exiftool.read).toBe('function');
    } catch (error) {
      throw new Error('exiftool-vendored is not available. Please install it first.');
    }
  });

  it('should have config file available', () => {
    const configPath = path.resolve('./config.ts');
    expect(fs.existsSync(configPath)).toBe(true);
  });
});
