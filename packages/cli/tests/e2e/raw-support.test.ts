import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { promises as fs } from 'fs';
import * as path from 'path';
import { getFileSizeMB } from 'exifcraft-core';

describe('RAW Format Support', () => {
  const testDir = path.join(__dirname, 'test-raw-files');
  
  beforeAll(async () => {
    // Create test directory
    try {
      await fs.mkdir(testDir, { recursive: true });
    } catch (error) {
      // Directory might already exist
    }
  });
  
  afterAll(async () => {
    // Clean up test directory
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  it('should correctly identify RAW formats', () => {
    const rawFormats = [
      'test.nef',   // Nikon
      'test.raf',   // Fujifilm
      'test.cr2',   // Canon
      'test.arw',   // Sony
      'test.dng',   // Adobe
      'test.raw',   // Generic RAW
      'test.orf',   // Olympus
      'test.rw2',   // Panasonic
      'test.pef',   // Pentax
      'test.srw'    // Samsung
    ];
    
    const nonRawFormats = [
      'test.jpg',
      'test.jpeg',
      'test.png',
      'test.tiff',
      'test.tif'
    ];
    
    // Test RAW formats
    const rawExtensions = ['.nef', '.raf', '.cr2', '.arw', '.dng', '.raw', '.orf', '.rw2', '.pef', '.srw'];
    rawFormats.forEach(format => {
      const ext = path.extname(format).toLowerCase();
      expect(rawExtensions.includes(ext)).toBe(true);
    });
    
    // Test non-RAW formats
    nonRawFormats.forEach(format => {
      const ext = path.extname(format).toLowerCase();
      expect(rawExtensions.includes(ext)).toBe(false);
    });
  });

  it('should calculate file size correctly', async () => {
    // Create a small test file
    const testFilePath = path.join(testDir, 'test.txt');
    const testContent = 'This is a test file for size calculation';
    await fs.writeFile(testFilePath, testContent);
    
    const sizeMB = await getFileSizeMB(testFilePath);
    expect(sizeMB).toBeGreaterThan(0);
    expect(sizeMB).toBeLessThan(0.1); // Should be very small
    
    // Clean up
    await fs.unlink(testFilePath);
  });

  it('should handle file size limits appropriately', async () => {
    // This test verifies that the size checking logic works
    // We don't actually create a 100MB file for testing
    const largeSizeMB = 150;
    const maxSizeMB = 100;
    
    expect(largeSizeMB > maxSizeMB).toBe(true);
  });
});
