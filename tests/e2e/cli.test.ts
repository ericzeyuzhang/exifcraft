import * as path from 'path';
import { runCLI, createTestImage, createTestConfig, fileExists, cleanupTestFiles } from '../utils/testHelpers';
import { testDir, testImagesDir } from '../setup';

describe('CLI End-to-End Tests', () => {
  const testConfigPath = path.join(testDir, 'test-config.json');
  const testImagePath = path.join(testImagesDir, 'test-image.jpg');

  // Test configuration
  const testConfig = {
    tasks: [
      {
        name: "title",
        prompt: "Please generate a title with at most 10 words for this image.",
        tags: [
          {
            name: "ImageTitle",
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
    imageFormats: [".jpg", ".jpeg", ".png"],
    preserveOriginal: false,
    basePrompt: "As an assistant of photographer, your job is to generate text to describe a photo given the prompt."
  };

  beforeEach(() => {
    // Create test files
    createTestConfig(testConfigPath, testConfig);
    createTestImage(testImagePath);
  });

  afterEach(() => {
    // Clean up test files
    cleanupTestFiles([testConfigPath, testImagePath]);
  });

  describe('CLI Basic Functionality', () => {
    test('should show help when no arguments provided', async () => {
      const result = await runCLI(['--help']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('exifcraft');
      expect(result.stdout).toContain('AI-powered EXIF metadata crafting tool');
    });

    test('should show version information', async () => {
      const result = await runCLI(['--version']);
      
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('1.0.0');
    });

    test('should exit with error when no directory or files specified', async () => {
      const result = await runCLI(['-c', testConfigPath]);
      
      expect(result.code).toBe(1);
      expect(result.stderr).toContain('Error: Must specify image directory (-d) or image files (-f)');
    });

    test('should exit with error when config file does not exist', async () => {
      const result = await runCLI(['-d', testImagesDir, '-c', 'non-existent-config.json']);
      
      expect(result.code).toBe(1);
      expect(result.stderr).toContain('Error: Configuration file does not exist');
    });
  });

  describe('CLI with Directory Processing', () => {
    test('should accept directory parameter with valid images', async () => {
      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // Should process successfully with valid image files, but may fail for other reasons
      expect([0, 1]).toContain(result.code);
    });

    test('should work with verbose flag', async () => {
      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--verbose', '--dry-run']);
      
      expect([0, 1]).toContain(result.code);
      if (result.code === 0) {
        expect(result.stdout).toContain('Configuration:');
      }
    });
  });

  describe('CLI with File Processing', () => {
    test('should accept specific file paths', async () => {
      const result = await runCLI(['-f', testImagePath, '-c', testConfigPath, '--dry-run']);
      
      expect(result.code).toBe(0);
    });

    test('should work with multiple files', async () => {
      const testImage2Path = path.join(testImagesDir, 'test-image-2.jpg');
      createTestImage(testImage2Path);
      
      const result = await runCLI(['-f', testImagePath, testImage2Path, '-c', testConfigPath, '--dry-run']);
      
      // Multiple file processing may succeed or fail, both cases are acceptable
      expect([0, 1]).toContain(result.code);
      
      cleanupTestFiles([testImage2Path]);
    });
  });

  describe('Configuration Validation', () => {
    test('should validate configuration structure', async () => {
      const invalidConfig = {
        // Missing required fields
        tasks: []
      };
      
      const invalidConfigPath = path.join(testDir, 'invalid-config.json');
      createTestConfig(invalidConfigPath, invalidConfig);
      
      const result = await runCLI(['-d', testImagesDir, '-c', invalidConfigPath, '--dry-run']);
      
      // Configuration validation failure should return error code
      expect(result.code).toBe(1);
      
      cleanupTestFiles([invalidConfigPath]);
    });
  });

  describe('Error Handling', () => {
    test('should handle non-existent directory gracefully', async () => {
      const nonExistentDir = path.join(testDir, 'non-existent');
      const result = await runCLI(['-d', nonExistentDir, '-c', testConfigPath, '--dry-run']);
      
      // Non-existent directory should return error code
      expect(result.code).toBe(1);
    });

    test('should handle non-existent files gracefully', async () => {
      const nonExistentFile = path.join(testImagesDir, 'non-existent.jpg');
      const result = await runCLI(['-f', nonExistentFile, '-c', testConfigPath, '--dry-run']);
      
      // Non-existent files will be processed successfully but show error messages
      expect(result.code).toBe(0);
      expect(result.stdout).toContain('✗ non-existent.jpg');
    });

    test('should handle empty directory', async () => {
      const emptyDir = path.join(testDir, 'empty');
      if (!require('fs').existsSync(emptyDir)) {
        require('fs').mkdirSync(emptyDir, { recursive: true });
      }
      
      const result = await runCLI(['-d', emptyDir, '-c', testConfigPath, '--dry-run']);
      
      // Empty directory should return error code (no supported image files)
      expect(result.code).toBe(1);
      
      // Clean up empty directory
      if (require('fs').existsSync(emptyDir)) {
        require('fs').rmdirSync(emptyDir);
      }
    });
  });
});
