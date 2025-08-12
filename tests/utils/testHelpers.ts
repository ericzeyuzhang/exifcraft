import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';

export interface TestResult {
  code: number;
  stdout: string;
  stderr: string;
}

/**
 * 执行CLI命令
 */
export function runCLI(args: string[]): Promise<TestResult> {
  return new Promise((resolve) => {
    const cliPath = path.join(__dirname, '../../dist/bin/cli.js');
    const child = spawn('node', [cliPath, ...args], {
      cwd: process.cwd(),
      env: { ...process.env, NODE_ENV: 'test' }
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      resolve({
        code: code || 0,
        stdout,
        stderr
      });
    });
  });
}

/**
 * 创建测试图片文件
 */
export function createTestImage(filePath: string, format: 'jpg' | 'png' = 'jpg'): void {
  // 创建一个简单的测试图片文件（这里只是创建一个占位符文件）
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  // 对于测试，我们创建一个小的文本文件来模拟图片
  // 在实际测试中，你可能需要使用真实的图片文件
  fs.writeFileSync(filePath, `Test image file - ${format}`);
}

/**
 * 复制真实文件到测试目录
 */
export function copyRealFileToTestDir(originalFileName: string, testDir: string): string {
  const originalPath = path.join(__dirname, '../images/original', originalFileName);
  const testPath = path.join(testDir, originalFileName);
  
  if (!fs.existsSync(originalPath)) {
    throw new Error(`Original file not found: ${originalPath}`);
  }
  
  // 确保测试目录存在
  if (!fs.existsSync(testDir)) {
    fs.mkdirSync(testDir, { recursive: true });
  }
  
  // 复制文件
  fs.copyFileSync(originalPath, testPath);
  
  return testPath;
}

/**
 * 获取所有原始测试文件
 */
export function getOriginalTestFiles(): string[] {
  const originalDir = path.join(__dirname, '../images/original');
  if (!fs.existsSync(originalDir)) {
    return [];
  }
  
  return fs.readdirSync(originalDir)
    .filter(file => !file.startsWith('.') && file !== '.DS_Store')
    .map(file => file);
}

/**
 * 复制所有真实文件到测试目录
 */
export function copyAllRealFilesToTestDir(testDir: string): string[] {
  const originalFiles = getOriginalTestFiles();
  const copiedPaths: string[] = [];
  
  originalFiles.forEach(file => {
    const copiedPath = copyRealFileToTestDir(file, testDir);
    copiedPaths.push(copiedPath);
  });
  
  return copiedPaths;
}

/**
 * 创建测试配置文件
 */
export function createTestConfig(configPath: string, config: any): void {
  const dir = path.dirname(configPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

/**
 * 检查文件是否存在
 */
export function fileExists(filePath: string): boolean {
  return fs.existsSync(filePath);
}

/**
 * 读取文件内容
 */
export function readFile(filePath: string): string {
  return fs.readFileSync(filePath, 'utf-8');
}

/**
 * 清理测试文件
 */
export function cleanupTestFiles(files: string[]): void {
  files.forEach(file => {
    if (fs.existsSync(file)) {
      fs.unlinkSync(file);
    }
  });
}

/**
 * 清理测试目录
 */
export function cleanupTestDir(testDir: string): void {
  if (fs.existsSync(testDir)) {
    fs.rmSync(testDir, { recursive: true, force: true });
  }
}
