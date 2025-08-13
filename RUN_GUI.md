# 🚀 如何运行ExifCraft GUI

## 快速启动

### 1. 安装依赖（如果还没安装）
```bash
npm install
```

### 2. 启动GUI应用
```bash
npm run dev
```

这个命令会：
- 启动GUI开发服务器（通常在 http://localhost:5173 或 5174）
- 启动Electron应用
- 自动打开GUI窗口

## 如果遇到问题

### 端口被占用
如果看到端口被占用的消息，这是正常的。应用会自动尝试其他端口。

### 手动启动
如果自动启动失败，可以手动启动：

```bash
# 终端1: 启动GUI服务器
npm run gui:dev

# 终端2: 启动Electron
npm run electron:dev
```

### 检查GUI是否正常运行
在浏览器中访问：http://localhost:5173 或 http://localhost:5174

## 使用GUI

1. **选择文件**: 点击 "Select Files" 或 "Select Directory"
2. **配置AI**: 在 "AI Model Settings" 中配置你的AI模型
3. **设置任务**: 在 "Processing Tasks" 中添加处理任务
4. **处理图像**: 点击 "Process Images" 开始处理

## 构建生产版本

```bash
npm run electron:build
```

构建完成后，可执行文件在 `dist-electron` 目录中。

## 故障排除

### GUI无法启动
- 检查Node.js版本 (>=14.0.0)
- 确保所有依赖已安装：`npm install`
- 检查端口是否被占用

### Electron无法连接GUI
- 确保GUI开发服务器正在运行
- 检查控制台错误信息
- 尝试重启应用

### 文件处理失败
- 检查AI模型配置
- 确认文件格式支持
- 查看错误日志
