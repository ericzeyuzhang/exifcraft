const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
const chalk = require('chalk');

/**
 * Generate AI response
 * @param {string} imagePath - Image file path
 * @param {string} prompt - Prompt text
 * @param {Object} aiConfig - AI model configuration
 * @param {boolean} verbose - Whether to show verbose output
 * @returns {Promise<string>} AI generated response text
 */
async function generateAIResponse(imagePath, prompt, aiConfig, verbose = false) {
  const { type, endpoint, model, options = {} } = aiConfig;
  
  switch (type.toLowerCase()) {
    case 'ollama':
      return await callOllamaAPI(imagePath, prompt, endpoint, model, options, verbose);
    case 'openai':
      return await callOpenAIAPI(imagePath, prompt, endpoint, model, options, verbose);
    case 'custom':
      return await callCustomAPI(imagePath, prompt, endpoint, model, options, verbose);
    default:
      throw new Error(`Unsupported AI model type: ${type}`);
  }
}

/**
 * Call Ollama API
 * @param {string} imagePath - Image file path
 * @param {string} prompt - Prompt text
 * @param {string} endpoint - API endpoint
 * @param {string} model - Model name
 * @param {Object} options - Options
 * @param {boolean} verbose - Whether to show verbose output
 * @returns {Promise<string>} AI response
 */
async function callOllamaAPI(imagePath, prompt, endpoint, model, options, verbose) {
  try {
    // Read and encode image
    const imageBase64 = await encodeImageToBase64(imagePath);
    
    const requestData = {
      model: model || 'llava',
      prompt: prompt,
      images: [imageBase64],
      stream: false,
      options: {
        temperature: options.temperature || 0.7,
        num_predict: options.max_tokens || 200
      }
    };
    
    if (verbose) {
      console.log(`    Calling Ollama API: ${endpoint}`);
      console.log(`    Model: ${requestData.model}`);
    }
    
    const response = await axios.post(endpoint, requestData, {
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
    
  } catch (error) {
    if (error.code === 'ECONNREFUSED') {
      throw new Error(`Unable to connect to Ollama service, please ensure Ollama is running (${endpoint})`);
    } else if (error.response) {
      throw new Error(`Ollama API error: ${error.response.status} - ${error.response.data?.error || error.response.statusText}`);
    } else {
      throw new Error(`Failed to call Ollama API: ${error.message}`);
    }
  }
}

/**
 * Call OpenAI compatible API
 * @param {string} imagePath - Image file path
 * @param {string} prompt - Prompt text
 * @param {string} endpoint - API endpoint
 * @param {string} model - Model name
 * @param {Object} options - Options
 * @param {boolean} verbose - Whether to show verbose output
 * @returns {Promise<string>} AI response
 */
async function callOpenAIAPI(imagePath, prompt, endpoint, model, options, verbose) {
  try {
    const imageBase64 = await encodeImageToBase64(imagePath);
    const mimeType = getMimeType(imagePath);
    
    const requestData = {
      model: model || 'gpt-4-vision-preview',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: prompt
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${imageBase64}`
              }
            }
          ]
        }
      ],
      max_tokens: options.max_tokens || 200,
      temperature: options.temperature || 0.7
    };
    
    if (verbose) {
      console.log(`    Calling OpenAI compatible API: ${endpoint}`);
      console.log(`    Model: ${requestData.model}`);
    }
    
    const headers = {
      'Content-Type': 'application/json'
    };
    
    // If API key is provided, add Authorization header
    if (options.apiKey) {
      headers['Authorization'] = `Bearer ${options.apiKey}`;
    }
    
    const response = await axios.post(endpoint, requestData, {
      headers,
      timeout: 60000
    });
    
    if (response.data?.choices?.[0]?.message?.content) {
      return response.data.choices[0].message.content.trim();
    } else {
      throw new Error('AI API returned abnormal format');
    }
    
  } catch (error) {
    if (error.response) {
      throw new Error(`OpenAI API error: ${error.response.status} - ${error.response.data?.error?.message || error.response.statusText}`);
    } else {
      throw new Error(`Failed to call OpenAI API: ${error.message}`);
    }
  }
}

/**
 * Call custom API
 * @param {string} imagePath - Image file path
 * @param {string} prompt - Prompt text
 * @param {string} endpoint - API endpoint
 * @param {string} model - Model name
 * @param {Object} options - Options
 * @param {boolean} verbose - Whether to show verbose output
 * @returns {Promise<string>} AI response
 */
async function callCustomAPI(imagePath, prompt, endpoint, model, options, verbose) {
  try {
    const imageBase64 = await encodeImageToBase64(imagePath);
    
    // Custom API request format can be adjusted as needed
    const requestData = {
      image: imageBase64,
      prompt: prompt,
      model: model,
      ...options
    };
    
    if (verbose) {
      console.log(`    Calling custom API: ${endpoint}`);
    }
    
    const response = await axios.post(endpoint, requestData, {
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {})
      },
      timeout: 60000
    });
    
    // Assume custom API returns { response: "..." } format
    if (response.data?.response) {
      return response.data.response.trim();
    } else if (typeof response.data === 'string') {
      return response.data.trim();
    } else {
      throw new Error('Custom API returned abnormal format');
    }
    
  } catch (error) {
    if (error.response) {
      throw new Error(`Custom API error: ${error.response.status} - ${error.response.statusText}`);
    } else {
      throw new Error(`Failed to call custom API: ${error.message}`);
    }
  }
}

/**
 * Encode image to Base64
 * @param {string} imagePath - Image file path
 * @returns {Promise<string>} Base64 encoded image data
 */
async function encodeImageToBase64(imagePath) {
  try {
    const imageBuffer = await fs.readFile(imagePath);
    return imageBuffer.toString('base64');
  } catch (error) {
    throw new Error(`Failed to read image file: ${error.message}`);
  }
}

/**
 * Get MIME type of image file
 * @param {string} imagePath - Image file path
 * @returns {string} MIME type
 */
function getMimeType(imagePath) {
  const ext = path.extname(imagePath).toLowerCase();
  const mimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.bmp': 'image/bmp',
    '.tiff': 'image/tiff',
    '.tif': 'image/tiff'
  };
  
  return mimeTypes[ext] || 'image/jpeg';
}

module.exports = {
  generateAIResponse,
  encodeImageToBase64,
  getMimeType
};