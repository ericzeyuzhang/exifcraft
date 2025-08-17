local LrDialogs  = import 'LrDialogs'
local LrView     = import 'LrView'
local LrBinding  = import 'LrBinding'
local LrPrefs    = import 'LrPrefs'
local LrFunctionContext = import 'LrFunctionContext'

-- 使用全局日志记录器
local log = _G.ExifCraftLog
if not log then
  error('Global logger ExifCraftLog not found! Info.lua must be loaded first.')
end

log:info('Settings.lua loaded')

local prefs = LrPrefs.prefsForPlugin()
prefs.exiftoolPath      = prefs.exiftoolPath      or ''
prefs.enableVerboseLogs = (prefs.enableVerboseLogs ~= nil) and prefs.enableVerboseLogs or true

-- 定义设置函数
local function showSettings()
  log:info('Opening settings dialog')
  
  LrDialogs.message('ExifCraft', 'Settings.lua entered ⚙️')

  local f    = LrView.osFactory()
  local bind = LrBinding.makePropertyTable()
  bind.exiftoolPath      = prefs.exiftoolPath or ''
  bind.enableVerboseLogs = (prefs.enableVerboseLogs == true)

  local ui = f:column {
    bind_to_object = bind,
    spacing = f:control_spacing(),
    f:static_text { title = 'ExifCraft Settings', font = '<system/bold>' },
    f:static_text { title = 'ExifTool Path:' },
    f:edit_field  { value = LrView.bind('exiftoolPath'), width_in_chars = 40 },
    f:checkbox { title = 'Enable verbose logs', value = LrView.bind('enableVerboseLogs') },
  }

  LrDialogs.presentModalDialog {
    title = 'ExifCraft Settings',
    contents = ui,
    actionVerb = 'Close',
    cancelVerb = '< exclude >',
  }

  prefs.exiftoolPath      = bind.exiftoolPath or ''
  prefs.enableVerboseLogs = bind.enableVerboseLogs and true or false
  
  log:info('Settings saved')
end

-- 使用LrFunctionContext来包装执行
LrFunctionContext.callWithContext('Settings.lua main execution', function(context)
  showSettings()
end)
