local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'

-- 初始化全局日志记录器
local globalLog = LrLogger('ExifCraft')
globalLog:enable('print')
globalLog:enable('logfile')

-- 将日志记录器设为全局变量，供其他文件使用
_G.ExifCraftLog = globalLog

globalLog:info('ExifCraft Plugin loaded')
globalLog:info('Plugin initialized')

LrDialogs.message('ExifCraft', 'Init.lua executed ✅ (plugin loaded)')