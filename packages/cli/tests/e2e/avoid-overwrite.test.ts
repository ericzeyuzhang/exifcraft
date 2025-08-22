import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exiftool } from 'exiftool-vendored';
import { writeExifData, readExifData } from '../../../core/src/lib/exifWriter';

describe('avoidOverwrite functionality', () => {
  const originalImagePath = path.join(__dirname, '../images/original/DSCF3752.JPG');
  const testImagePath = path.join(__dirname, '../images/demo/DSCF3752.JPG');

  beforeAll(async () => {
    // Ensure test image exists
    if (!await fs.access(originalImagePath).then(() => true).catch(() => false)) {
      throw new Error(`Test image not found: ${originalImagePath}`);
    }
    
    // Copy original image to demo directory for testing
    await fs.copyFile(originalImagePath, testImagePath);
  });

  afterAll(async () => {
    // Clean up test files
    try {
      await fs.unlink(testImagePath);
    } catch (error) {
      // Ignore cleanup errors
    }
    await exiftool.end();
  });

  it('should overwrite existing tags when avoidOverwrite is false', async () => {
    // First, write some initial EXIF data
    const initialTags = {
      ImageTitle: 'Initial Title',
      ImageDescription: 'Initial Description'
    };
    
    await writeExifData(testImagePath, initialTags, false, false);
    
    // Verify initial data was written
    const initialRead = await readExifData(testImagePath, ['ImageTitle', 'ImageDescription'], false);
    expect(initialRead.ImageTitle).toBe('Initial Title');
    expect(initialRead.ImageDescription).toBe('Initial Description');
    
    // Now try to write new data with avoidOverwrite: false
    const newTags = {
      ImageTitle: 'New Title',
      ImageDescription: 'New Description'
    };
    
    const avoidOverwriteMap = {
      ImageTitle: false,
      ImageDescription: false
    };
    
    await writeExifData(testImagePath, newTags, false, false, avoidOverwriteMap);
    
    // Verify new data overwrote the old data
    const finalRead = await readExifData(testImagePath, ['ImageTitle', 'ImageDescription'], false);
    expect(finalRead.ImageTitle).toBe('New Title');
    expect(finalRead.ImageDescription).toBe('New Description');
  });

  it('should not overwrite existing non-empty tags when avoidOverwrite is true', async () => {
    // First, write some initial EXIF data
    const initialTags = {
      ImageTitle: 'Initial Title',
      ImageDescription: 'Initial Description'
    };
    
    await writeExifData(testImagePath, initialTags, false, false);
    
    // Now try to write new data with avoidOverwrite: true
    const newTags = {
      ImageTitle: 'New Title',
      ImageDescription: 'New Description'
    };
    
    const avoidOverwriteMap = {
      ImageTitle: true,
      ImageDescription: true
    };
    
    await writeExifData(testImagePath, newTags, false, false, avoidOverwriteMap);
    
    // Verify original data was preserved
    const finalRead = await readExifData(testImagePath, ['ImageTitle', 'ImageDescription'], false);
    expect(finalRead.ImageTitle).toBe('Initial Title');
    expect(finalRead.ImageDescription).toBe('Initial Description');
  });

  it('should write to empty tags even when avoidOverwrite is true', async () => {
    // First, clear any existing EXIF data
    await writeExifData(testImagePath, {
      ImageTitle: '',
      ImageDescription: ''
    }, false, false);
    
    // Now try to write new data with avoidOverwrite: true
    const newTags = {
      ImageTitle: 'New Title',
      ImageDescription: 'New Description'
    };
    
    const avoidOverwriteMap = {
      ImageTitle: true,
      ImageDescription: true
    };
    
    await writeExifData(testImagePath, newTags, false, false, avoidOverwriteMap);
    
    // Verify new data was written to empty tags
    const finalRead = await readExifData(testImagePath, ['ImageTitle', 'ImageDescription'], false);
    expect(finalRead.ImageTitle).toBe('New Title');
    expect(finalRead.ImageDescription).toBe('New Description');
  });
});
