import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';

export const TagConfigSchema = z.object({
  name: z.string(),
  avoidOverwrite: z.boolean()
});

export const TaskConfigSchema = z.object({
  name: z.string().min(1),
  tags: z.array(TagConfigSchema).min(1),
  prompt: z.string().min(1),
  enabled: z.boolean().optional()
});

export const AIProviderEnum = z.enum(['ollama', 'openai', 'gemini', 'mock']);

export const AIModelOptionsSchema = z.object({
  temperature: z.number().min(0).max(2).optional(),
  max_tokens: z.number().int().positive().optional()
}).strict();

export const AIModelConfigSchema = z.object({
  provider: AIProviderEnum,
  key: z.string().optional(),
  endpoint: z.string().url(),
  model: z.string().min(1),
  options: AIModelOptionsSchema.optional()
});

export const ExifCraftConfigSchema = z.object({
  tasks: z.array(TaskConfigSchema).min(1),
  aiModel: AIModelConfigSchema,
  imageFormats: z.array(z.string().min(1)).default(['jpg', 'jpeg', 'png', 'heic', 'tif', 'tiff', 'webp']),
  preserveOriginal: z.boolean().default(true),
  basePrompt: z.string().optional(),
  verbose: z.boolean().optional(),
  dryRun: z.boolean().optional()
}).strict();

export type ExifCraftConfigFromSchema = z.infer<typeof ExifCraftConfigSchema>;

export function generateConfigJsonSchema() {
  const jsonSchema = zodToJsonSchema(ExifCraftConfigSchema, {
    name: 'ExifCraftConfig',
    $refStrategy: 'none'
  });
  return jsonSchema;
}

export function getConfigJsonSchemaWithMeta() {
  const schema = generateConfigJsonSchema();
  return {
    $schema: 'http://json-schema.org/draft-07/schema#',
    $id: 'https://exifcraft.dev/schema.json',
    title: 'ExifCraftConfig',
    description: 'Configuration for ExifCraft',
    ...schema
  };
}


