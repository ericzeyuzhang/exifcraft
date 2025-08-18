# ExifCraft v2 Lightroom Plugin 安装指南

## 更新内容

这个版本包含了以下重要更新：

### 🔧 修复和改进
- **升级 Lightroom SDK 到版本 12.0**，支持更新的 Lightroom 版本
- **修复 Post-Process Action 问题**，解决 "Can't Use Post-Process Action" 错误
- **添加详细的 LrLogger 日志输出**，便于调试和问题诊断
- **改进错误处理和用户反馈**
- **增强插件初始化流程**

### 📝 新增日志功能
- 详细的处理过程日志记录
- CLI 执行状态跟踪
- 配置验证日志
- 错误诊断信息

## 安装步骤

### 方法一：自动安装（推荐）
1. 下载 `ExifCraft-v2-20250818.zip` 文件
2. 解压缩文件
3. 双击 `ExifCraft.lrplugin` 文件夹
4. Lightroom 将自动检测并提示安装插件

### 方法二：手动安装
1. 下载并解压缩插件文件
2. 打开 Adobe Lightroom
3. 转到 `文件 > 插件管理器`
4. 点击 `添加` 按钮
5. 浏览并选择 `ExifCraft.lrplugin` 文件夹
6. 点击 `添加插件`

## 使用方法

1. **导出图像时**：
   - 在导出对话框中找到 "ExifCraft AI Metadata" 部分
   - 配置 Ollama 设置（端点和模型）
   - 选择要生成的元数据类型（标题、描述、关键词）
   - 调整 AI 提示和参数

2. **查看日志**：
   - 插件现在会记录详细的处理日志
   - 可以在 Lightroom 的插件日志中查看处理状态
   - 错误信息会更加详细和有用

## 故障排除

### 如果遇到 "Can't Use Post-Process Action" 错误：
1. 确保使用的是最新版本的插件
2. 重启 Lightroom
3. 检查插件日志以获取详细错误信息
4. 确保 Ollama 服务正在运行并可访问

### 查看详细日志：
1. 打开 Lightroom
2. 转到 `帮助 > 插件附加信息`
3. 查找 "ExifCraftV2" 相关的日志条目

### 常见问题：
- **CLI 找不到**：确保 CLI 二进制文件存在于插件的 `bin` 目录中
- **Ollama 连接失败**：检查端点 URL 和 Ollama 服务状态
- **权限问题**：确保插件文件夹有适当的读写权限

## 系统要求

- Adobe Lightroom Classic（版本 6.0 或更高）
- macOS 或 Windows
- Ollama 服务（用于 AI 生成）
- 网络连接（访问 AI 服务）

## 技术支持

如果遇到问题，请：
1. 检查插件日志以获取详细错误信息
2. 确保所有依赖项都已正确安装
3. 重启 Lightroom 并重试

---

**版本**: v2.0.0  
**构建日期**: 2025-08-18  
**SDK 版本**: 12.0