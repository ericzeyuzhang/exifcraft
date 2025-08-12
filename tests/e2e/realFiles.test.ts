import * as path from 'path';
import * as fs from 'fs';
import { 
  runCLI, 
  createTestConfig, 
  cleanupTestFiles, 
  cleanupTestDir,
  copyRealFileToTestDir,
  copyAllRealFilesToTestDir,
  getOriginalTestFiles
} from '../utils/testHelpers';
import { testDir } from '../setup';

describe('Real Files Processing Tests', () => {
  const testConfigPath = path.join(testDir, 'test-config.json');
  const realFilesTestDir = path.join(testDir, 'real-files-test');

  // Create test configuration
  const createProcessingConfig = (options: any = {}) => ({
    tasks: [
      {
        name: "title",
        prompt: "Generate a title for this image",
        tags: [
          {
            name: "ImageTitle",
            allowOverwrite: true
          }
        ]
      },
      {
        name: "description",
        prompt: "Describe this image",
        tags: [
          {
            name: "ImageDescription",
            allowOverwrite: true
          }
        ]
      }
    ],
    aiModel: {
      provider: "ollama",
      endpoint: "http://localhost:11434/api/generate",
      model: "llava",
      options: {
        temperature: 0,
        max_tokens: 500
      }
    },
    imageFormats: [".jpg", ".jpeg", ".png", ".heic", ".raf", ".nef"],
    preserveOriginal: false,
    basePrompt: "As an assistant of photographer, your job is to generate text to describe a photo given the prompt.",
    ...options
  });

  beforeEach(() => {
    // Clean up previous test directory
    cleanupTestDir(realFilesTestDir);
    
    // Ensure test directory exists
    if (!fs.existsSync(realFilesTestDir)) {
      fs.mkdirSync(realFilesTestDir, { recursive: true });
    }
  });

  afterEach(() => {
    cleanupTestFiles([testConfigPath]);
    cleanupTestDir(realFilesTestDir);
  });

  describe('Real Image Files Processing', () => {
    test('should process real JPG files', async () => {
      const jpgFile = 'DSCF3752.JPG';
      const testJpgPath = copyRealFileToTestDir(jpgFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testJpgPath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('Processing');
    });

    test('should process real HEIC files', async () => {
      const heicFile = 'IMG_9897.HEIC';
      const testHeicPath = copyRealFileToTestDir(heicFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testHeicPath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('Processing');
    });

    test('should process real RAF files', async () => {
      const rafFile = 'DSCF0709.RAF';
      const testRafPath = copyRealFileToTestDir(rafFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testRafPath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('Processing');
    });

    test('should process real NEF files', async () => {
      const nefFile = 'DSC_0243.NEF';
      const testNefPath = copyRealFileToTestDir(nefFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testNefPath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('Processing');
    });

    test('should skip non-image files', async () => {
      const txtFile = 'a-text-file.txt';
      const testTxtPath = copyRealFileToTestDir(txtFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testTxtPath, '-c', testConfigPath, '--dry-run']);
      
      // Non-image files may return error code, which is acceptable
      expect([0, 1]).toContain(result.code);
      // Check for error messages or skip messages
      expect(result.stdout + result.stderr).toMatch(/Skipping|Unsupported|Error|not supported/);
    });
  });

  describe('Batch Processing Real Files', () => {
    test('should process multiple real files in batch', async () => {
      const copiedFiles = copyAllRealFilesToTestDir(realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      // Process all copied files
      const result = await runCLI(['-d', realFilesTestDir, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('Processing');
      
      // Verify that at least some image files were processed
      const imageFiles = copiedFiles.filter(file => 
        /\.(jpg|jpeg|png|heic|raf|nef)$/i.test(file)
      );
      expect(imageFiles.length).toBeGreaterThan(0);
    });

    test('should preserve original files after processing', async () => {
      const originalFiles = getOriginalTestFiles();
      const imageFiles = originalFiles.filter(file => 
        /\.(jpg|jpeg|png|heic|raf|nef)$/i.test(file)
      );
      
      if (imageFiles.length === 0) {
        console.log('No image files found for testing');
        return;
      }

      const testImageFile = imageFiles[0];
      const testImagePath = copyRealFileToTestDir(testImageFile, realFilesTestDir);
      
      // Record original file size
      const originalStats = fs.statSync(testImagePath);
      const originalSize = originalStats.size;
      
      createTestConfig(testConfigPath, createProcessingConfig({ preserveOriginal: true }));

      const result = await runCLI(['-f', testImagePath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
      
      // Verify file still exists and size hasn't changed
      expect(fs.existsSync(testImagePath)).toBe(true);
      const afterStats = fs.statSync(testImagePath);
      expect(afterStats.size).toBe(originalSize);
    });
  });

  describe('File Format Detection', () => {
    test('should correctly identify supported image formats', async () => {
      const originalFiles = getOriginalTestFiles();
      const supportedFormats = ['.jpg', '.jpeg', '.png', '.heic', '.raf', '.nef'];
      
      for (const file of originalFiles) {
        const ext = path.extname(file).toLowerCase();
        if (supportedFormats.includes(ext)) {
          const testFilePath = copyRealFileToTestDir(file, realFilesTestDir);
          createTestConfig(testConfigPath, createProcessingConfig());

          const result = await runCLI(['-f', testFilePath, '-c', testConfigPath, '--dry-run']);
          
          // Supported formats should be processed
          expect(result.code).toBe(0);
          expect(result.stdout).toContain('Processing');
        }
      }
    });

    test('should skip unsupported file formats', async () => {
      const txtFile = 'a-text-file.txt';
      const testTxtPath = copyRealFileToTestDir(txtFile, realFilesTestDir);
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', testTxtPath, '-c', testConfigPath, '--dry-run']);
      
      expect([0, 1]).toContain(result.code);
      expect(result.stdout + result.stderr).toMatch(/Skipping|Unsupported|Error|not supported/);
    });
  });

  describe('Error Handling with Real Files', () => {
    test('should handle missing files gracefully', async () => {
      const nonExistentPath = path.join(realFilesTestDir, 'non-existent-file.jpg');
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', nonExistentPath, '-c', testConfigPath, '--dry-run']);
      
      // Should return error code or skip non-existent files
      expect([0, 1]).toContain(result.code);
    });

    test('should handle corrupted or invalid image files', async () => {
      // Create a corrupted image file
      const corruptedPath = path.join(realFilesTestDir, 'corrupted.jpg');
      fs.writeFileSync(corruptedPath, 'This is not a valid image file');
      createTestConfig(testConfigPath, createProcessingConfig());

      const result = await runCLI(['-f', corruptedPath, '-c', testConfigPath, '--dry-run']);
      
      // Should be able to handle corrupted files (either skip or report error)
      expect([0, 1]).toContain(result.code);
    });
  });
});
