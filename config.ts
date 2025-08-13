// TypeScript configuration with runtime validation
import type { ExifCraftConfig } from './src/models/types';

const config: ExifCraftConfig = {
  tasks: [
    {
      name: "title", 
      prompt: "Please generate a title with at most 10 words for this image, describing the main subject, scene, or content. The title should be a single sentence. ",
      tags: [
        {
          name: "ObjectName",
          allowOverwrite: true
        },
        {
          name: "ImageDescription", 
          allowOverwrite: true
        },
        {
          name: "XPTitle",
          allowOverwrite: true
        }
      ]
    },
    {
      name: "description",
      prompt: "Please describe this image in a single paragraph with 100-150 words. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ",
      tags: [
        {
          name: "ImageDescription", // TypeScript will provide autocomplete for WriteTags keys
          allowOverwrite: true
        }
      ]
    },
    {
      name: "keywords",
      prompt: "Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ",
      tags: [
        {
          name: "Keywords", // TypeScript will provide autocomplete for WriteTags keys
          allowOverwrite: true
        }
      ]
    }
  ],
  aiModel: {
    provider: "ollama",
    endpoint: "http://erics-mac-mini.local:11434/api/generate",
    model: "llava",
    options: {
      temperature: 0,
      max_tokens: 500
    }
  },
  imageFormats: [".jpg", ".jpeg", ".jpe", ".png", ".webp", ".bmp", ".gif"],
  preserveOriginal: false,
  basePrompt: "As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n"
};

export default config;
