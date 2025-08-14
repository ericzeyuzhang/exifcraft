import axios, { AxiosResponse } from 'axios';
import { AIModelConfig } from '../models/types';

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
    case 'mock':
      return await callMockAPI(prompt);
    case 'openai':
    case 'gemini':
    default:
      throw new Error(`Unsupported AI model provider: ${provider}. Currently only 'ollama' and 'mock' are implemented.`);
  }
}

/**
 * Mock AI API for integration testing
 */
async function callMockAPI(prompt: string): Promise<string> {
  // Simulate network delay
  await new Promise(resolve => setTimeout(resolve, 100));
  
  // Return different responses based on the prompt content
  if (prompt.toLowerCase().includes('title')) {
    return 'Beautiful sunset over mountains';
  } else if (prompt.toLowerCase().includes('description')) {
    return 'A stunning landscape photograph featuring golden hour light illuminating snow-capped peaks with dramatic clouds in the background';
  } else if (prompt.toLowerCase().includes('keyword')) {
    return 'landscape, nature, mountains, sunset, golden hour, photography, outdoor, scenic, dramatic, beautiful';
  } else {
    return 'Mock AI response for testing purposes';
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
