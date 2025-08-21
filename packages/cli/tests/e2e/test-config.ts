// Test-specific configuration with runtime validation
import type { ExifCraftConfig } from '../../src/models/types';
import { TagNames } from 'exiftool-vendored/dist/Tags.js';

const config: ExifCraftConfig = {
  tasks: [
    {
      name: "title", 
      prompt: "Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ",
      tags: [
        {
          name: TagNames.ImageTitle,
          allowOverwrite: true
        },
        {
          name: TagNames.ImageDescription, 
          allowOverwrite: true
        },
        {
          name: TagNames.XPTitle,
          allowOverwrite: true
        }, 
        {
          name: TagNames.ObjectName,
          allowOverwrite: true
        }, 
        {
          name: TagNames.Title,
          allowOverwrite: true
        }
      ]
    },
    {
      name: "description",
      prompt: "Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ",
      tags: [
        {
          name: TagNames.ImageDescription,
          allowOverwrite: true
        }, 
        {
          name: TagNames.Description,
          allowOverwrite: true
        }, 
        {
          name: TagNames['Caption-Abstract'],
          allowOverwrite: true
        }
      ]
    },
    {
      name: "keywords",
      prompt: "Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ",
      tags: [
        {
          name: TagNames.Keywords,
          allowOverwrite: true
        }
      ]
    }
  ],
  aiModel: {
    provider: "mock",
    endpoint: "http://localhost:11434/api/generate", // Not used for mock
    model: "mock-model", // Not used for mock
    options: {
      temperature: 0,
      max_tokens: 500
    }
  },
  imageFormats: ["jpg", "jpeg"],
  preserveOriginal: false,
  basePrompt: "As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n"
};

export default config;
