# ExifCraft GUI

基于Electron和React的ExifCraft图形用户界面，支持Mac和Windows平台。

## 功能特性

- 🖼️ **直观的文件选择**: 支持选择单个文件或整个目录
- ⚙️ **可视化配置**: 通过GUI界面配置AI模型和处理任务
- 🔄 **实时处理状态**: 显示处理进度和结果
- 💾 **配置管理**: 保存和加载配置文件
- 🎯 **批量处理**: 支持批量处理多个图像文件
- 🔧 **灵活设置**: 支持dry-run模式和详细输出

## 安装和运行

### 开发模式

1. 安装依赖:
```bash
npm install
```

2. 启动开发服务器:
```bash
# 启动GUI开发服务器
npm run gui:dev

# 在另一个终端启动Electron
npm run electron:dev
```

### 构建应用

1. 构建GUI:
```bash
npm run gui:build
```

2. 构建Electron应用:
```bash
npm run electron:build
```

构建完成后，可执行文件将在 `dist-electron` 目录中。

## 使用说明

### 1. 文件选择
- 点击 "Select Files" 选择单个或多个图像文件
- 点击 "Select Directory" 选择包含图像的目录
- 支持的文件格式: JPG, PNG, HEIC, TIFF, BMP

### 2. 配置设置
- **AI模型设置**: 配置AI提供商、端点、模型等参数
- **处理任务**: 定义要执行的AI任务和对应的EXIF标签
- **通用设置**: 设置基础提示词、是否保留原文件等

### 3. 处理图像
- 选择要处理的文件
- 配置处理选项（dry-run、详细输出）
- 点击 "Process Images" 开始处理

## 配置说明

### AI模型配置
- **Provider**: 选择AI提供商 (Ollama, OpenAI, Gemini)
- **Endpoint**: AI服务的API端点
- **Model**: 使用的AI模型名称
- **API Key**: 在线AI服务的API密钥（Ollama不需要）
- **Temperature**: 生成文本的随机性 (0-2)
- **Max Tokens**: 最大生成令牌数

### 任务配置
每个任务包含：
- **任务名称**: 用于标识任务
- **提示词**: 发送给AI的指令
- **EXIF标签**: 要写入的元数据标签和覆盖设置

### 支持的EXIF标签
- ImageTitle: 图像标题
- ImageDescription: 图像描述
- Keywords: 关键词
- Artist: 艺术家
- Copyright: 版权信息
- 等等...

## 技术架构

### 前端 (React + TypeScript)
- **Material-UI**: 现代化UI组件库
- **Vite**: 快速构建工具
- **TypeScript**: 类型安全

### 后端 (Electron + Node.js)
- **Electron**: 跨平台桌面应用框架
- **IPC通信**: 主进程和渲染进程间的安全通信
- **文件系统访问**: 通过Electron API访问本地文件

### 核心功能
- **图像处理**: 复用现有的ExifCraft核心功能
- **AI集成**: 支持多种AI模型和提供商
- **EXIF操作**: 使用exiftool-vendored进行元数据操作

## 开发指南

### 项目结构
```
exifcraft/
├── src/
│   ├── electron/          # Electron主进程
│   │   ├── main.ts       # 主进程入口
│   │   └── preload.ts    # 预加载脚本
│   ├── lib/              # 核心功能库
│   └── types/            # 类型定义
├── gui/                  # React GUI应用
│   ├── src/
│   │   ├── components/   # React组件
│   │   └── types/        # GUI类型定义
│   └── package.json
└── package.json
```

### 添加新功能
1. 在 `src/lib/` 中添加核心功能
2. 在 `src/electron/main.ts` 中添加IPC处理器
3. 在 `src/electron/preload.ts` 中暴露API
4. 在 `gui/src/components/` 中添加UI组件

## Lightroom插件兼容性

项目已为未来的Adobe Lightroom插件集成做好准备：

- **适配器层**: `src/lib/lightroomAdapter.ts` 提供Lightroom兼容接口
- **配置管理**: 支持Lightroom特定的配置选项
- **批量处理**: 支持Lightroom的批量处理需求
- **错误处理**: 提供详细的错误报告和处理状态

## 故障排除

### 常见问题

1. **GUI无法启动**
   - 检查Node.js版本 (>=14.0.0)
   - 确保所有依赖已正确安装

2. **AI模型连接失败**
   - 检查网络连接
   - 验证API密钥和端点配置
   - 确认AI服务正在运行

3. **文件处理失败**
   - 检查文件权限
   - 确认文件格式支持
   - 查看详细错误日志

### 调试模式
在开发模式下，Electron会自动打开开发者工具，可以查看控制台日志和调试信息。

## 许可证

MIT License
