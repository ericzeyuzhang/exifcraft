// 全局状态
let selectedFiles = [];
let currentConfig = getDefaultConfig();

// 默认配置
function getDefaultConfig() {
    return {
        tasks: [
            {
                name: "title",
                prompt: "Generate a title for this image",
                tags: [{ name: "ImageTitle", allowOverwrite: true }]
            }
        ],
        aiModel: {
            provider: "ollama",
            endpoint: "http://localhost:11434/api/generate",
            model: "llava",
            options: { temperature: 0, max_tokens: 500 }
        },
        imageFormats: [".jpg", ".jpeg", ".png", ".heic"],
        preserveOriginal: false,
        basePrompt: "You are a helpful assistant."
    };
}

// 基础功能实现
document.addEventListener('DOMContentLoaded', () => {
    console.log('ExifCraft GUI loaded');
    
    // 标签页切换
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const tabName = btn.dataset.tab;
            switchTab(tabName);
        });
    });
    
    // 文件选择
    document.getElementById('select-files-btn').addEventListener('click', selectFiles);
    document.getElementById('start-processing-btn').addEventListener('click', startProcessing);
});

function switchTab(tabName) {
    // 更新导航按钮
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tabName);
    });
    
    // 更新内容
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.toggle('active', content.id === `${tabName}-tab`);
    });
}

async function selectFiles() {
    try {
        const files = await window.exifcraftAPI.selectFiles();
        console.log('Selected files:', files);
        showNotification(`选择了 ${files.length} 个文件`, 'success');
    } catch (error) {
        showNotification('选择文件失败: ' + error.message, 'error');
    }
}

async function startProcessing() {
    try {
        showNotification('开始处理...', 'info');
        // 这里添加处理逻辑
    } catch (error) {
        showNotification('处理失败: ' + error.message, 'error');
    }
}

function showNotification(message, type = 'info') {
    const notification = document.getElementById('notification');
    const messageEl = notification.querySelector('.notification-message');
    
    messageEl.textContent = message;
    notification.className = `notification ${type}`;
    notification.classList.add('show');
    
    setTimeout(() => {
        notification.classList.remove('show');
    }, 3000);
}
