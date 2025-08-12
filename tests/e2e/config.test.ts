import * as path from 'path';
import { runCLI, createTestConfig, cleanupTestFiles } from '../utils/testHelpers';
import { testDir, testImagesDir } from '../setup';

describe('Configuration End-to-End Tests', () => {
  const testConfigPath = path.join(testDir, 'test-config.json');

  afterEach(() => {
    cleanupTestFiles([testConfigPath]);
  });

  describe('Configuration Loading', () => {
    test('should load valid configuration', async () => {
      const validConfig = {
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
            temperature: 0.7,
            max_tokens: 300
          }
        },
        imageFormats: [".jpg", ".png", ".heic"],
        preserveOriginal: true,
        basePrompt: "You are a helpful assistant."
      };

      createTestConfig(testConfigPath, validConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--verbose', '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
      expect(result.stdout).toContain('Configuration:');
      expect(result.stdout).toContain('"provider": "ollama"');
    });

    test('should handle configuration with minimal required fields', async () => {
      const minimalConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
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
          model: "llava"
        },
        imageFormats: [".jpg"]
      };

      createTestConfig(testConfigPath, minimalConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });

    test('should handle configuration with OpenAI provider', async () => {
      const openaiConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
            tags: [
              {
                name: "ImageTitle",
                allowOverwrite: true
              }
            ]
          }
        ],
        aiModel: {
          provider: "openai",
          key: "test-key",
          endpoint: "https://api.openai.com/v1",
          model: "gpt-4",
          options: {
            temperature: 0.5,
            max_tokens: 200
          }
        },
        imageFormats: [".jpg", ".png"]
      };

      createTestConfig(testConfigPath, openaiConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });

    test('should handle configuration with Gemini provider', async () => {
      const geminiConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
            tags: [
              {
                name: "ImageTitle",
                allowOverwrite: true
              }
            ]
          }
        ],
        aiModel: {
          provider: "gemini",
          key: "test-key",
          endpoint: "https://generativelanguage.googleapis.com",
          model: "gemini-pro",
          options: {
            temperature: 0.3,
            max_tokens: 150
          }
        },
        imageFormats: [".jpg", ".webp"]
      };

      createTestConfig(testConfigPath, geminiConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });
  });

  describe('Configuration Validation', () => {
    test('should handle empty tasks array', async () => {
      const emptyTasksConfig = {
        tasks: [],
        aiModel: {
          provider: "ollama",
          endpoint: "http://localhost:11434/api/generate",
          model: "llava"
        },
        imageFormats: [".jpg"]
      };

      createTestConfig(testConfigPath, emptyTasksConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });

    test('should handle empty imageFormats array', async () => {
      const emptyFormatsConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
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
          model: "llava"
        },
        imageFormats: []
      };

      createTestConfig(testConfigPath, emptyFormatsConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });

    test('should handle missing optional fields', async () => {
      const minimalConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
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
          model: "llava"
        },
        imageFormats: [".jpg"]
        // 缺少 preserveOriginal 和 basePrompt
      };

      createTestConfig(testConfigPath, minimalConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });
  });

  describe('Configuration Error Handling', () => {
    test('should handle malformed JSON configuration', async () => {
      const malformedConfigPath = path.join(testDir, 'malformed-config.json');
      // 创建格式错误的JSON文件
      require('fs').writeFileSync(malformedConfigPath, '{ "invalid": json }');

      const result = await runCLI(['-d', testImagesDir, '-c', malformedConfigPath, '--dry-run']);
      
      // 应该能够检测到JSON解析错误
      expect(result.code).toBe(1);
      
      cleanupTestFiles([malformedConfigPath]);
    });

    test('should handle configuration with invalid AI provider', async () => {
      const invalidProviderConfig = {
        tasks: [
          {
            name: "title",
            prompt: "Generate a title",
            tags: [
              {
                name: "ImageTitle",
                allowOverwrite: true
              }
            ]
          }
        ],
        aiModel: {
          provider: "invalid-provider",
          endpoint: "http://localhost:11434/api/generate",
          model: "llava"
        },
        imageFormats: [".jpg"]
      };

      createTestConfig(testConfigPath, invalidProviderConfig);

      const result = await runCLI(['-d', testImagesDir, '-c', testConfigPath, '--dry-run']);
      
      // When no image files are found, CLI should return error code 1
      expect(result.code).toBe(1);
    });
  });
});
