# 测试文档

本文档说明了如何使用真实文件进行测试，确保原始文件的 EXIF 信息不被修改。

## 目录结构

```
tests/
├── images/
│   └── original/          # 存放原始测试文件
│       ├── DSCF3752.JPG   # 真实JPG文件
│       ├── IMG_9897.HEIC  # 真实HEIC文件
│       ├── DSCF0709.RAF   # 真实RAF文件
│       ├── DSC_0243.NEF   # 真实NEF文件
│       ├── IMAG0062.JPG   # 真实JPG文件
│       └── a-text-file.txt # 非图片文件（用于测试跳过功能）
├── e2e/
│   ├── realFiles.test.ts  # 专门测试真实文件的测试
│   ├── processing.test.ts # 现有的处理测试（已更新）
│   ├── cli.test.ts        # CLI测试
│   └── config.test.ts     # 配置测试
├── utils/
│   └── testHelpers.ts     # 测试工具函数（已更新）
├── verify-setup.ts        # 验证测试设置
└── README.md             # 本文档
```

## 测试文件管理

### 原始文件保护

所有测试都遵循以下原则：
1. **原始文件永不修改**：`tests/images/original/` 目录下的文件永远不会被修改
2. **测试时复制文件**：每次测试都会将需要的文件复制到临时目录
3. **测试后清理**：测试完成后自动清理临时文件和目录

### 支持的文件格式

当前测试支持以下图片格式：
- **JPG/JPEG**：最常见的图片格式
- **HEIC**：iOS设备常用的高效图片格式
- **RAF**：Fujifilm相机原始格式
- **NEF**：Nikon相机原始格式
- **PNG**：支持透明度的图片格式

## 新增的测试工具函数

### `copyRealFileToTestDir(originalFileName, testDir)`
复制单个真实文件到测试目录。

```typescript
const testPath = copyRealFileToTestDir('DSCF3752.JPG', '/tmp/test-dir');
// 返回: '/tmp/test-dir/DSCF3752.JPG'
```

### `copyAllRealFilesToTestDir(testDir)`
复制所有真实文件到测试目录。

```typescript
const copiedPaths = copyAllRealFilesToTestDir('/tmp/test-dir');
// 返回: ['/tmp/test-dir/file1.jpg', '/tmp/test-dir/file2.heic', ...]
```

### `getOriginalTestFiles()`
获取所有原始测试文件的文件名列表。

```typescript
const files = getOriginalTestFiles();
// 返回: ['DSCF3752.JPG', 'IMG_9897.HEIC', 'DSCF0709.RAF', ...]
```

### `cleanupTestDir(testDir)`
清理测试目录及其所有内容。

```typescript
cleanupTestDir('/tmp/test-dir');
// 删除整个目录及其内容
```

## 测试用例

### 1. 真实文件处理测试 (`realFiles.test.ts`)

这个测试文件专门用于测试真实图片文件的处理：

#### 单个文件处理
```typescript
test('should process real JPG files', async () => {
  const jpgFile = 'DSCF3752.JPG';
  const testJpgPath = copyRealFileToTestDir(jpgFile, realFilesTestDir);
  createTestConfig(testConfigPath, createProcessingConfig());

  const result = await runCLI(['-f', testJpgPath, '-c', testConfigPath, '--dry-run']);
  
  expect(result.code).toBe(0);
  expect(result.stdout).toContain('Processing');
});
```

#### 批量处理
```typescript
test('should process multiple real files in batch', async () => {
  const copiedFiles = copyAllRealFilesToTestDir(realFilesTestDir);
  createTestConfig(testConfigPath, createProcessingConfig());

  const result = await runCLI(['-d', realFilesTestDir, '-c', testConfigPath, '--dry-run']);
  
  expect(result.code).toBe(0);
  expect(result.stdout).toContain('Processing');
});
```

#### 文件完整性验证
```typescript
test('should preserve original files after processing', async () => {
  const testImagePath = copyRealFileToTestDir(testImageFile, realFilesTestDir);
  
  // 记录原始文件信息
  const originalStats = fs.statSync(testImagePath);
  const originalSize = originalStats.size;
  
  const result = await runCLI(['-f', testImagePath, '-c', testConfigPath, '--dry-run']);
  
  // 验证文件完整性
  expect(fs.existsSync(testImagePath)).toBe(true);
  const afterStats = fs.statSync(testImagePath);
  expect(afterStats.size).toBe(originalSize);
});
```

### 2. 集成测试 (`processing.test.ts`)

现有的处理测试已经更新，包含了真实文件的集成测试：

```typescript
describe('Real Files Integration', () => {
  test('should process real image files with different formats', async () => {
    const originalFiles = getOriginalTestFiles();
    const imageFiles = originalFiles.filter(file => 
      /\.(jpg|jpeg|png|heic|raf|nef)$/i.test(file)
    );
    
    // 测试前几个图片文件
    const testFiles = imageFiles.slice(0, 3);
    const copiedPaths: string[] = [];

    for (const file of testFiles) {
      const copiedPath = copyRealFileToTestDir(file, realFilesTestDir);
      copiedPaths.push(copiedPath);
    }

    // 逐个处理文件
    for (const filePath of copiedPaths) {
      const result = await runCLI(['-f', filePath, '-c', testConfigPath, '--dry-run']);
      expect([0, 1]).toContain(result.code);
      expect(result.stdout).toContain('Processing');
    }
  });
});
```

## 运行测试

### 验证测试设置

在运行测试之前，建议先验证设置：

```bash
npx ts-node tests/verify-setup.ts
```

这将检查：
- 原始文件目录是否存在
- 所有原始文件是否可访问
- 文件复制功能是否正常工作

### 运行特定测试

#### 运行真实文件测试
```bash
npm test -- --testNamePattern="Real Files Processing Tests"
```

#### 运行集成测试
```bash
npm test -- --testNamePattern="Real Files Integration"
```

#### 运行所有图片处理测试
```bash
npm test -- --testPathPattern="realFiles.test.ts|processing.test.ts"
```

### 运行完整测试套件
```bash
npm test
```

### 运行测试并生成覆盖率报告
```bash
npm test -- --coverage
```

## 添加新的测试文件

如果你想添加新的真实文件进行测试：

1. **将文件放入原始目录**：
   ```bash
   cp your-image.jpg tests/images/original/
   ```

2. **更新验证脚本**（可选）：
   编辑 `tests/verify-setup.ts` 来包含新文件的信息。

3. **运行验证**：
   ```bash
   npx ts-node tests/verify-setup.ts
   ```

4. **运行测试**：
   ```bash
   npm test -- --testNamePattern="Real Files"
   ```

## 测试最佳实践

### 1. 文件大小考虑
- 大文件（>50MB）可能需要更长的处理时间
- 测试时使用 `--dry-run` 模式避免实际修改文件
- 考虑在CI/CD环境中使用较小的测试文件

### 2. 错误处理
- 测试应该能够处理各种错误情况
- 使用 `expect([0, 1]).toContain(result.code)` 来接受不同的返回码
- 检查 `stdout` 和 `stderr` 来验证错误信息

### 3. 清理资源
- 始终在 `afterEach` 中清理测试文件
- 使用 `cleanupTestDir` 确保完全清理
- 避免在测试中修改原始文件

### 4. 性能考虑
- 大型文件测试可能需要较长时间
- 考虑并行运行独立的测试
- 使用 `--maxWorkers` 控制并发数

## 故障排除

### 常见问题

1. **文件不存在错误**
   ```
   Error: Original file not found: /path/to/file.jpg
   ```
   解决：确保文件存在于 `tests/images/original/` 目录中

2. **权限错误**
   ```
   Error: EACCES: permission denied
   ```
   解决：检查文件权限，确保测试进程有读取权限

3. **磁盘空间不足**
   ```
   Error: ENOSPC: no space left on device
   ```
   解决：清理磁盘空间，或减少同时运行的测试数量

### 调试技巧

1. **查看详细输出**：
   ```bash
   npm test -- --verbose
   ```

2. **运行单个测试**：
   ```bash
   npm test -- --testNamePattern="should process real JPG files"
   ```

3. **检查测试文件**：
   ```bash
   ls -la tests/images/original/
   ```

4. **验证文件复制**：
   ```bash
   npx ts-node tests/verify-setup.ts
   ```

## 贡献指南

当添加新的测试时，请遵循以下规范：

1. **使用真实文件**：优先使用真实的图片文件而不是模拟文件
2. **保护原始文件**：确保原始文件永远不会被修改
3. **清理资源**：测试完成后清理所有临时文件
4. **文档更新**：更新本文档以反映新的测试功能
5. **错误处理**：测试应该能够优雅地处理各种错误情况

通过遵循这些指南，我们可以确保测试的可靠性和可维护性，同时保护珍贵的原始图片文件。
