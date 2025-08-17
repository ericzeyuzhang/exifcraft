local LrDialogs = import 'LrDialogs'
local LrLogger  = import 'LrLogger'
local LrTasks   = import 'LrTasks'
local LrApp     = import 'LrApplication'

local log = LrLogger('ExifCraft')
log:enable('print')
log:enable('logfile')

log:info('Process.lua loaded')

-- 定义处理函数
local function processPhotos()
  LrDialogs.message('ExifCraft', 'Process.lua entered ✅')
  log:info('Process.lua handler entered')

  LrTasks.startAsyncTask(function()
    local catalog = LrApp.activeCatalog()
    local photos  = catalog:getTargetPhotos() or {}
    if #photos == 0 then
      LrDialogs.message('ExifCraft', 'No photos selected.', 'warning')
      log:warn('No photos selected')
      return
    end
    LrDialogs.message('ExifCraft', ('Processing %d photo(s)...'):format(#photos))
    log:info(('Processing %d photo(s)'):format(#photos))
    -- TODO: add your processing logic here
  end)
end

-- 直接调用函数执行逻辑
processPhotos()
