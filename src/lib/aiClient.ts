import axios, { AxiosResponse } from 'axios';
import { promises as fs } from 'fs';
import { AIModelConfig } from '../types';

interface OllamaResponse {
  response: string;
}

/**
 * Generate AI response using configured AI provider
 */
export async function generateAIResponse(
  imagePath: string, 
  prompt: string, 
  aiConfig: AIModelConfig, 
  verbose: boolean = false
): Promise<string> {
  const { provider, endpoint, model, options = {} } = aiConfig;
  
  switch (provider.toLowerCase()) {
    case 'ollama':
      return await callOllamaAPI(imagePath, prompt, endpoint, model, options, verbose);
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
  imagePath: string, 
  prompt: string, 
  endpoint: string, 
  model: string, 
  options: AIModelConfig['options'], 
  verbose: boolean
): Promise<string> {
  try {
    // Read and encode image to base64
    const imageBuffer = await fs.readFile(imagePath);
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
    
    if (verbose) {
      console.log(`    Calling Ollama API: ${endpoint}`);
      console.log(`    Model: ${requestData.model}`);
    }
    
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
