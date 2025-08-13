import axios, { AxiosResponse } from 'axios';
import { promises as fs } from 'fs';
import * as path from 'path';
// @ts-ignore
import heicConvert from 'heic-convert';
import { AIModelConfig } from '../models';
import { Logger } from './logger';

/**
 * Convert image to compatible format for AI processing
 */
export async function convertImageForAI(imagePath: string, verbose: boolean = false, logger: Logger): Promise<Buffer> {
  const imageBuffer = await fs.readFile(imagePath);
  
  // Convert HEIC/HEIF to JPEG for Ollama compatibility
  // TODO: Add support for TIFF (.tiff, .tif) and RAW formats (.raw, .cr2, .nef, .arw) in future versions
  const lowerPath = imagePath.toLowerCase();
  const isHeic = lowerPath.endsWith('.heic') || lowerPath.endsWith('.heif');
  
  if (isHeic) {
    if (verbose) {
      console.log(`Converting ${path.extname(imagePath)} to JPEG for Ollama compatibility`);
    }
    return await heicConvert({
      buffer: imageBuffer,
      format: 'JPEG',
      quality: 0.9
    });
  }
  
  return imageBuffer;
}

interface OllamaResponse {
  response: string;
}

/**
 * Generate AI response using configured AI provider
 */
export async function generateAIResponse(
  imageBuffer: Buffer, 
  prompt: string, 
  aiConfig: AIModelConfig, 
): Promise<string> {
  const { provider, endpoint, model, options = {} } = aiConfig;
  
  switch (provider.toLowerCase()) {
    case 'ollama':
      return await callOllamaAPI(imageBuffer, prompt, endpoint, model, options);
    case 'openai':
    case 'gemini':
    default:
      throw new Error(`Unsupported AI model provider: ${provider}. Currently only 'ollama' is implemented.`);
  }
}

/**
 * Call Ollama API
 */
async function callOllamaAPI(
  imageBuffer: Buffer, 
  prompt: string, 
  endpoint: string, 
  model: string, 
  options: AIModelConfig['options'], 
): Promise<string> {
  try {
    const imageBase64 = imageBuffer.toString('base64');
    
    const requestData = {
      model: model || 'llava',
      prompt: prompt,
      images: [imageBase64],
      stream: false,
      options: {
        temperature: options?.temperature || 0.7,
        num_predict: options?.max_tokens || 200
      }
    };
    
    const response: AxiosResponse<OllamaResponse> = await axios.post(endpoint, requestData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 60000 // 60 second timeout
    });
    
    if (response.data && response.data.response) {
      return response.data.response.trim();
    } else {
      throw new Error('AI API returned abnormal format');
    }
    
  } catch (error: any) {
    if (error.code === 'ECONNREFUSED') {
      throw new Error(`Unable to connect to Ollama service, please ensure Ollama is running (${endpoint})`);
    } else if (error.response) {
      throw new Error(`Ollama API error: ${error.response.status} - ${error.response.data?.error || error.response.statusText}`);
    } else {
      throw new Error(`Failed to call Ollama API: ${error.message}`);
    }
  }
}
