const fs = require('fs-extra');
const path = require('path');

async function copyRendererFiles() {
  const sourceDir = path.join(__dirname, '../src/renderer');
  const targetDir = path.join(__dirname, '../dist/renderer');
  
  try {
    // 确保目标目录存在
    await fs.ensureDir(targetDir);
    
    // 复制所有文件
    await fs.copy(sourceDir, targetDir);
    
    console.log('✅ Renderer files copied successfully');
  } catch (error) {
    console.error('❌ Error copying renderer files:', error);
    process.exit(1);
  }
}

copyRendererFiles();
