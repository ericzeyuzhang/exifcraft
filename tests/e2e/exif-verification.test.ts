import { describe, it, expect } from 'vitest';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { readExifData, extractAIGeneratedContent } from './utils';

describe('EXIF Verification E2E Tests', () => {
  it('should write AI-generated EXIF data to image files', async () => {
    const configPath = path.join(process.cwd(), 'tests/e2e/test-config.ts');
    const demoDir = path.join(process.cwd(), 'tests/images/demo');
    
    // Build the project first
    execSync('npm run build', { stdio: 'pipe' });
    
    // Run the actual processing command
    const output = execSync(
      `node --no-warnings dist/bin/cli.js -d ${demoDir} -c ${configPath} --verbose`,
      { 
        encoding: 'utf8',
        stdio: 'pipe'
      }
    );

    // Extract AI generated content from logs
    const aiGeneratedContent = extractAIGeneratedContent(output);
    
    // Verify that AI content was generated
    expect(aiGeneratedContent.title.length).toBeGreaterThan(0);
    expect(aiGeneratedContent.description.length).toBeGreaterThan(0);
    expect(aiGeneratedContent.keywords.length).toBeGreaterThan(0);
    
    // Check specific image files for EXIF data
    const testImages = ['DSCF3752.JPG', 'IMAG0062.JPG'];
    
    for (const imageFile of testImages) {
      const imagePath = path.join(demoDir, imageFile);
      
      // Verify file exists and was modified
      expect(fs.existsSync(imagePath)).toBe(true);
      
      // Read EXIF data from the processed image
      const exifData = await readExifData(imagePath);
      
      // Verify that EXIF fields were written
      expect(exifData).toBeDefined();
      
      // Check for specific EXIF fields that should be present
      const expectedFields = [
        'ImageTitle',
        'ImageDescription', 
        'XPTitle',
        'ObjectName',
        'Title',
        'Description',
        'Caption-Abstract',
        'Keywords'
      ];
      
      // At least some of these fields should be present
      const presentFields = expectedFields.filter(field => 
        exifData[field] !== undefined && exifData[field] !== null
      );
      expect(presentFields.length).toBeGreaterThan(0);
      
      // Verify that the written values are not empty
      for (const field of presentFields) {
        const value = exifData[field];
        expect(value).toBeTruthy();
        expect(typeof value).toBe('string');
        expect(value.length).toBeGreaterThan(0);
      }
    }
  });

  it('should preserve original EXIF data while adding new fields', async () => {
    const configPath = path.join(process.cwd(), 'tests/e2e/test-config.ts');
    const demoDir = path.join(process.cwd(), 'tests/images/demo');
    
    // Use the file that was already copied by setup.ts
    const testImage = path.join(demoDir, 'DSCF3752.JPG');
    
    // Read original EXIF data before processing
    const originalExifData = await readExifData(testImage);
    
    // Run processing
    execSync(
      `node --no-warnings dist/bin/cli.js -d ${demoDir} -c ${configPath} --verbose`,
      { stdio: 'pipe' }
    );
    
    // Read EXIF data after processing
    const processedExifData = await readExifData(testImage);
    
    // Verify that original technical EXIF data is preserved
    const technicalFields = [
      'Make',
      'Model', 
      'DateTime',
      'ExposureTime',
      'FNumber',
      'ISO',
      'FocalLength',
      'ImageWidth',
      'ImageHeight'
    ];
    
    for (const field of technicalFields) {
      if (originalExifData[field] !== undefined) {
        expect(processedExifData[field]).toBe(originalExifData[field]);
      }
    }
    
    // Verify that new descriptive fields were added
    const descriptiveFields = [
      'ImageTitle',
      'ImageDescription',
      'Keywords'
    ];
    
    for (const field of descriptiveFields) {
      expect(processedExifData[field]).toBeDefined();
      expect(processedExifData[field]).toBeTruthy();
    }
  });
});
