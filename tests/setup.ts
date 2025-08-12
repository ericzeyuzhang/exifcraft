import * as fs from 'fs';
import * as path from 'path';

// 创建测试用的临时目录
const testDir = path.join(__dirname, 'temp');
const testImagesDir = path.join(testDir, 'images');

// 确保测试目录存在
if (!fs.existsSync(testDir)) {
  fs.mkdirSync(testDir, { recursive: true });
}

if (!fs.existsSync(testImagesDir)) {
  fs.mkdirSync(testImagesDir, { recursive: true });
}

// 全局测试清理函数
global.afterAll(async () => {
  // 清理测试文件
  if (fs.existsSync(testDir)) {
    fs.rmSync(testDir, { recursive: true, force: true });
  }
});

// 导出测试路径
export { testDir, testImagesDir };
