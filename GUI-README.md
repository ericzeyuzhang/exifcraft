# ExifCraft GUI 使用指南

## 概述

ExifCraft 现在支持图形用户界面（GUI），提供更直观的操作体验。GUI版本基于Electron构建，支持Mac、Windows和Linux平台。

## 功能特性

### 🖼️ 文件管理
- 拖拽上传图片文件
- 批量选择文件
- 支持多种图片格式（JPG、PNG、HEIC等）
- 文件预览和管理

### ⚙️ 配置设置
- 可视化配置AI模型参数
- 自定义任务和标签
- 配置保存和加载
- 实时配置验证

### 🔄 处理控制
- 一键开始批量处理
- 实时处理进度显示
- 处理日志查看
- 错误处理和重试

### 📊 结果展示
- 处理结果可视化
- 成功/失败状态显示
- 结果导出功能
- 历史记录管理

## 安装和运行

### 开发模式运行

```bash
# 安装依赖
npm install

# 启动开发模式
npm run electron:dev
```

### 构建可执行文件

```bash
# 构建应用
npm run electron:build

# 构建特定平台
npm run dist
```

构建后的文件将保存在 `release` 目录中。

## 使用说明

### 1. 启动应用

运行应用后，你会看到一个现代化的界面，包含四个主要标签页：

- **文件管理**: 选择和管理要处理的图片文件
- **配置设置**: 配置AI模型和处理参数
- **处理控制**: 开始处理并监控进度
- **处理结果**: 查看处理结果和统计信息

### 2. 选择文件

在"文件管理"标签页中：

1. 点击"选择文件"按钮选择单个或多个图片文件
2. 或者直接将文件拖拽到拖拽区域
3. 支持的文件格式：JPG、JPEG、PNG、HEIC、HEIF

### 3. 配置设置

在"配置设置"标签页中：

#### AI模型配置
- **AI提供商**: 选择Ollama、OpenAI或Google Gemini
- **API端点**: 输入API服务地址
- **模型名称**: 指定使用的模型
- **温度**: 控制输出的随机性（0-2）

#### 任务配置
- 添加自定义任务
- 设置任务名称和提示词
- 配置EXIF标签映射

#### 其他设置
- **保留原始文件**: 是否备份原文件
- **基础提示词**: 设置AI的基础指令

### 4. 开始处理

在"处理控制"标签页中：

1. 确保已选择文件和配置
2. 点击"开始处理"按钮
3. 监控处理进度和日志
4. 处理完成后查看结果

### 5. 查看结果

在"处理结果"标签页中：

- 查看每个文件的处理状态
- 导出处理结果
- 清空历史记录

## 配置示例

### 基础配置

```json
{
  "aiModel": {
    "provider": "ollama",
    "endpoint": "http://localhost:11434/api/generate",
    "model": "llava",
    "options": {
      "temperature": 0,
      "max_tokens": 500
    }
  },
  "tasks": [
    {
      "name": "title",
      "prompt": "Generate a title for this image",
      "tags": [
        {
          "name": "ImageTitle",
          "allowOverwrite": true
        }
      ]
    }
  ],
  "preserveOriginal": false,
  "basePrompt": "You are a helpful assistant."
}
```

## 快捷键

- `Cmd/Ctrl + O`: 选择文件
- `Cmd/Ctrl + Shift + O`: 选择文件夹
- `Cmd/Ctrl + Q`: 退出应用

## 故障排除

### 常见问题

1. **应用无法启动**
   - 确保已安装所有依赖：`npm install`
   - 检查Node.js版本（需要14.0.0+）

2. **AI模型连接失败**
   - 检查API端点是否正确
   - 确保AI服务正在运行
   - 验证网络连接

3. **文件处理失败**
   - 检查文件格式是否支持
   - 确保文件路径没有特殊字符
   - 查看处理日志获取详细错误信息

4. **配置保存失败**
   - 检查文件权限
   - 确保目标目录可写

### 日志查看

在开发模式下，可以按 `F12` 打开开发者工具查看详细日志。

## 技术架构

### 前端技术栈
- **Electron**: 跨平台桌面应用框架
- **HTML5/CSS3**: 现代化用户界面
- **JavaScript**: 交互逻辑
- **Font Awesome**: 图标库

### 后端集成
- 复用现有的CLI逻辑
- IPC通信确保安全性
- 异步处理提升性能

## 开发指南

### 项目结构

```
src/
├── electron/          # Electron主进程
│   ├── main.ts       # 主进程逻辑
│   ├── preload.ts    # 预加载脚本
│   └── index.ts      # 入口文件
├── renderer/         # 渲染进程
│   ├── index.html    # 主界面
│   ├── styles.css    # 样式文件
│   └── renderer.js   # 渲染逻辑
└── lib/              # 共享库
    ├── processor.ts  # 处理逻辑
    ├── configProvider.ts
    └── ...
```

### 开发命令

```bash
# 开发模式
npm run electron:dev

# 构建
npm run electron:build

# 打包
npm run dist
```

### 自定义开发

1. **修改界面**: 编辑 `src/renderer/` 下的文件
2. **添加功能**: 在 `src/electron/main.ts` 中添加IPC处理器
3. **样式调整**: 修改 `src/renderer/styles.css`
4. **逻辑扩展**: 在 `src/renderer/renderer.js` 中添加交互逻辑

## 贡献指南

欢迎贡献代码和功能改进！

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 许可证

MIT License
