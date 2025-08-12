import * as fs from 'fs';
import * as path from 'path';
import { getOriginalTestFiles, copyRealFileToTestDir, cleanupTestDir } from './utils/testHelpers';

console.log('🔍 Verifying test setup...\n');

// 检查原始文件目录
const originalDir = path.join(__dirname, 'images/original');
console.log(`📁 Checking original files directory: ${originalDir}`);

if (!fs.existsSync(originalDir)) {
  console.error('❌ Original files directory does not exist!');
  process.exit(1);
}

// 获取所有原始文件
const originalFiles = getOriginalTestFiles();
console.log(`📄 Found ${originalFiles.length} original files:`);

originalFiles.forEach(file => {
  const filePath = path.join(originalDir, file);
  const stats = fs.statSync(filePath);
  const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2);
  console.log(`   - ${file} (${sizeInMB} MB)`);
});

// 按文件类型分类
const fileTypes = originalFiles.reduce((acc, file) => {
  const ext = path.extname(file).toLowerCase();
  if (!acc[ext]) acc[ext] = [];
  acc[ext].push(file);
  return acc;
}, {} as Record<string, string[]>);

console.log('\n📊 File types breakdown:');
Object.entries(fileTypes).forEach(([ext, files]) => {
  console.log(`   - ${ext}: ${files.length} files`);
});

// 测试文件复制功能
console.log('\n🧪 Testing file copy functionality...');
const testDir = path.join(__dirname, 'temp-test-verify');

try {
  // 清理可能存在的测试目录
  cleanupTestDir(testDir);
  
  // 复制一个文件进行测试
  if (originalFiles.length > 0) {
    const testFile = originalFiles[0];
    const copiedPath = copyRealFileToTestDir(testFile, testDir);
    
    if (fs.existsSync(copiedPath)) {
      const originalStats = fs.statSync(path.join(originalDir, testFile));
      const copiedStats = fs.statSync(copiedPath);
      
      if (originalStats.size === copiedStats.size) {
        console.log(`✅ Successfully copied ${testFile} (${(originalStats.size / 1024 / 1024).toFixed(2)} MB)`);
      } else {
        console.error(`❌ File size mismatch for ${testFile}`);
      }
    } else {
      console.error(`❌ Failed to copy ${testFile}`);
    }
  }
  
  // 清理测试目录
  cleanupTestDir(testDir);
  console.log('✅ File copy test completed successfully');
  
} catch (error) {
  console.error('❌ File copy test failed:', error);
  cleanupTestDir(testDir);
  process.exit(1);
}

console.log('\n🎉 Test setup verification completed successfully!');
console.log('\n📝 Next steps:');
console.log('   1. Run: npm test');
console.log('   2. Or run specific test: npm test -- realFiles.test.ts');
console.log('   3. Or run with coverage: npm test -- --coverage');
