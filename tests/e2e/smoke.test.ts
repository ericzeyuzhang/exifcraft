import { describe, it, expect, beforeEach } from 'vitest';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { resetTestEnvironment } from './setup';

describe('Smoke Tests', () => {
  beforeEach(async () => {
    // Reset environment before each test to ensure clean state
    resetTestEnvironment();
  });

  it('should build the project successfully', () => {
    expect(() => {
      execSync('npm run build', { stdio: 'pipe' });
    }).not.toThrow();
  });

  it('should have required test files', () => {
    const demoDir = path.join(process.cwd(), 'tests/images/demo');
    const originalDir = path.join(process.cwd(), 'tests/images/original');
    
    expect(fs.existsSync(demoDir)).toBe(true);
    expect(fs.existsSync(originalDir)).toBe(true);
    
    const demoFiles = fs.readdirSync(demoDir);
    const originalFiles = fs.readdirSync(originalDir);
    
    expect(demoFiles.length).toBeGreaterThan(0);
    expect(originalFiles.length).toBeGreaterThan(0);
    
    // Check that all files from original are copied to demo
    expect(demoFiles.length).toBe(originalFiles.length);
    
    // Check for key image files (JPG and JPEG)
    const keyImageFiles = ['DSCF3752.JPG', 'IMAG0062.JPG'];
    
    for (const file of keyImageFiles) {
      expect(demoFiles).toContain(file);
      expect(originalFiles).toContain(file);
    }
    
    // Verify that non-supported formats are also copied (for testing filter functionality)
    const nonSupportedFiles = ['DSCF0709.RAF', 'DSC_0243.NEF', 'IMG_9897.HEIC', 'a-text-file.txt'];
    for (const file of nonSupportedFiles) {
      expect(demoFiles).toContain(file);
      expect(originalFiles).toContain(file);
    }
  });

  it('should have valid configuration file', () => {
    const configPath = path.join(process.cwd(), 'config.ts');
    expect(fs.existsSync(configPath)).toBe(true);
    
    // Try to load the config to ensure it's valid
    expect(() => {
      require(configPath);
    }).not.toThrow();
  });
});
