local LrDialogs = import 'LrDialogs'
local LrTasks   = import 'LrTasks'
local LrApp     = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'

-- 使用全局日志记录器
local log = _G.ExifCraftLog
if not log then
  error('Global logger ExifCraftLog not found! Info.lua must be loaded first.')
end

log:info('Process.lua loaded')

-- 定义处理函数
local function processPhotos()
  log:info('Processing photos...')
  
  LrDialogs.message('ExifCraft', 'Process.lua entered ✅')

  LrTasks.startAsyncTask(function()
    local catalog = LrApp.activeCatalog()
    if not catalog then
      log:error('Failed to get active catalog')
      return
    end
    
    local photos = catalog:getTargetPhotos() or {}
    log:info(('Found %d photo(s)'):format(#photos))
    
    if #photos == 0 then
      log:warn('No photos selected')
      LrDialogs.message('ExifCraft', 'No photos selected.', 'warning')
      return
    end
    
    LrDialogs.message('ExifCraft', ('Processing %d photo(s)...'):format(#photos))
    log:info(('Processing %d photo(s)'):format(#photos))
    
    -- TODO: add your processing logic here
    log:info('Processing completed')
  end)
end

-- 使用LrFunctionContext来包装执行
LrFunctionContext.callWithContext('Process.lua main execution', function(context)
  processPhotos()
end)
