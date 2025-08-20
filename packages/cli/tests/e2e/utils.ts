import { execSync } from 'child_process';
import { exiftool } from 'exiftool-vendored';

export interface ExifData {
  [key: string]: any;
}

export interface AIGeneratedContent {
  title: string[];
  description: string[];
  keywords: string[];
}

/**
 * Read EXIF data from an image file using exiftool-vendored
 */
export async function readExifData(imagePath: string): Promise<ExifData> {
  try {
    const exifData = await exiftool.read(imagePath);
    return exifData || {};
  } catch (error) {
    console.error(`Error reading EXIF data from ${imagePath}:`, error);
    return {};
  }
}

/**
 * Extract AI generated content from CLI output logs
 */
export function extractAIGeneratedContent(logOutput: string): AIGeneratedContent {
  const aiContent: AIGeneratedContent = {
    title: [],
    description: [],
    keywords: []
  };
  
  const lines = logOutput.split('\n');
  let currentTask = '';
  
  for (const line of lines) {
    if (line.includes('-- Processing [title] task...')) {
      currentTask = 'title';
    } else if (line.includes('-- Processing [description] task...')) {
      currentTask = 'description';
    } else if (line.includes('-- Processing [keywords] task...')) {
      currentTask = 'keywords';
    } else if (line.includes('AI response:') && currentTask) {
      const match = line.match(/AI response:\s*(.+)/);
      if (match && match[1]) {
        aiContent[currentTask].push(match[1].trim());
      }
    }
  }
  
  return aiContent;
}

/**
 * Verify that EXIF fields contain expected AI-generated content
 */
export function verifyExifContent(
  exifData: ExifData, 
  aiContent: AIGeneratedContent,
  imageIndex: number = 0
): void {
  // Check if AI content exists for this image
  if (aiContent.title[imageIndex]) {
    const titleFields = ['ImageTitle', 'XPTitle', 'ObjectName', 'Title'];
    const hasTitle = titleFields.some(field => 
      exifData[field] && exifData[field].includes(aiContent.title[imageIndex])
    );
    if (!hasTitle) {
      console.warn(`Title content not found in EXIF for image ${imageIndex}`);
    }
  }
  
  if (aiContent.description[imageIndex]) {
    const descFields = ['ImageDescription', 'Description', 'Caption-Abstract'];
    const hasDescription = descFields.some(field => 
      exifData[field] && exifData[field].includes(aiContent.description[imageIndex])
    );
    if (!hasDescription) {
      console.warn(`Description content not found in EXIF for image ${imageIndex}`);
    }
  }
  
  if (aiContent.keywords[imageIndex]) {
    const keywords = exifData['Keywords'];
    if (keywords && typeof keywords === 'string') {
      const keywordList = keywords.split(',').map(k => k.trim());
      const aiKeywords = aiContent.keywords[imageIndex].split(',').map(k => k.trim());
      const hasKeywords = aiKeywords.some(keyword => 
        keywordList.some(exifKeyword => 
          exifKeyword.toLowerCase().includes(keyword.toLowerCase())
        )
      );
      if (!hasKeywords) {
        console.warn(`Keywords content not found in EXIF for image ${imageIndex}`);
      }
    }
  }
}

/**
 * Get file modification time
 */
export function getFileModTime(filePath: string): number {
  try {
    const stats = execSync(`stat -f "%m" "${filePath}"`, { encoding: 'utf8' });
    return parseInt(stats.trim());
  } catch (error) {
    console.error(`Error getting modification time for ${filePath}:`, error);
    return 0;
  }
}