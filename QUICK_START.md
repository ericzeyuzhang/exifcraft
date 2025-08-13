# ExifCraft GUI 快速启动指南

## 🚀 5分钟快速开始

### 1. 安装依赖
```bash
npm install
```

### 2. 启动GUI应用
```bash
# 开发模式（推荐用于测试）
npm run dev

# 或者分别启动
npm run gui:dev
npm run electron:dev
```

### 3. 使用应用

#### 选择文件
1. 点击 "Select Files" 选择图像文件
2. 或点击 "Select Directory" 选择包含图像的目录
3. 支持格式：JPG, PNG, HEIC, TIFF, BMP

#### 配置AI模型
1. 展开 "AI Model Settings"
2. 选择提供商（Ollama, OpenAI, Gemini）
3. 输入端点URL和模型名称
4. 配置温度和最大令牌数

#### 设置处理任务
1. 展开 "Processing Tasks"
2. 点击 "Add Task" 添加新任务
3. 输入任务名称和提示词
4. 配置要写入的EXIF标签

#### 处理图像
1. 选择要处理的文件
2. 配置处理选项
3. 点击 "Process Images" 开始处理

## 🔧 配置示例

### Ollama配置
```json
{
  "provider": "ollama",
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llava",
  "options": {
    "temperature": 0,
    "max_tokens": 500
  }
}
```

### OpenAI配置
```json
{
  "provider": "openai",
  "endpoint": "https://api.openai.com/v1/chat/completions",
  "model": "gpt-4-vision-preview",
  "key": "your-api-key-here",
  "options": {
    "temperature": 0.7,
    "max_tokens": 1000
  }
}
```

## 📁 项目结构概览

```
exifcraft/
├── gui/                    # React GUI应用
├── src/
│   ├── electron/          # Electron主进程
│   ├── lib/              # 核心功能
│   └── types/            # 类型定义
├── GUI_README.md          # 详细文档
└── PROJECT_SUMMARY.md     # 项目总结
```

## 🎯 主要功能

- ✅ **文件管理**: 拖拽选择，批量处理
- ✅ **AI配置**: 可视化模型配置
- ✅ **任务管理**: 动态创建处理任务
- ✅ **实时状态**: 处理进度和结果反馈
- ✅ **配置保存**: 导入导出配置文件

## 🐛 常见问题

### Q: GUI无法启动？
A: 确保已安装所有依赖：`npm install`

### Q: AI模型连接失败？
A: 检查网络连接和API配置

### Q: 文件处理失败？
A: 检查文件权限和格式支持

## 📚 更多信息

- 详细文档：`GUI_README.md`
- 项目总结：`PROJECT_SUMMARY.md`
- 源代码：`src/` 和 `gui/src/`

## 🆘 获取帮助

- 查看控制台错误信息
- 检查网络连接
- 验证配置文件格式
- 参考详细文档
