-- ExifCraft.lua（诊断版）
local LrLogger          = import 'LrLogger'
local LrDialogs         = import 'LrDialogs'
local LrTasks           = import 'LrTasks'
local LrApplication     = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'
local LrView            = import 'LrView'
local LrBinding         = import 'LrBinding'
local LrPrefs           = import 'LrPrefs'

local log = LrLogger('ExifCraft')
log:enable('print')      -- 到 lrc_console.log
log:enable('logfile')    -- 到 .../Lightroom/Logs/ExifCraft.log

local prefs = LrPrefs.prefsForPlugin()
prefs.exiftoolPath      = prefs.exiftoolPath      or ''
prefs.enableVerboseLogs = (prefs.enableVerboseLogs ~= nil) and prefs.enableVerboseLogs or true

local function safeCall(name, f)
  LrFunctionContext.callWithContext(name, function(context)
    local ok, err = LrFunctionContext.pcall(function() f(context) end)
    if not ok then
      log:error(string.format('[%s] %s', name, tostring(err)))
      LrDialogs.message('ExifCraft - Error', tostring(err), 'critical')
    end
  end)
end

function processSelectedPhotos()
  -- 强提示：确保你看到这个弹窗
  LrDialogs.message('ExifCraft', 'processSelectedPhotos() entered ✅')

  safeCall('processSelectedPhotos', function()
    log:info('Menu clicked: Process with ExifCraft')
    LrTasks.startAsyncTask(function()
      local catalog = LrApplication.activeCatalog()
      local selected = catalog:getTargetPhotos() or {}
      if #selected == 0 then
        log:warn('No photos selected')
        LrDialogs.message('ExifCraft', 'No photos selected.', 'warning')
        return
      end
      LrDialogs.message('ExifCraft', ('Processing %d photo(s)...'):format(#selected))
      log:info(('Start processing %d photo(s)'):format(#selected))
      log:info('Processing completed.')
      LrDialogs.message('ExifCraft', 'Processing complete.')
    end)
  end)
end

function showSettingsDialog()
  -- 强提示：确保你看到这个弹窗
  LrDialogs.message('ExifCraft', 'showSettingsDialog() entered ⚙️')

  safeCall('showSettingsDialog', function()
    local f = LrView.osFactory()
    local bind = LrBinding.makePropertyTable()
    bind.exiftoolPath      = prefs.exiftoolPath or ''
    bind.enableVerboseLogs = (prefs.enableVerboseLogs == true)

    local c = f:column {
      bind_to_object = bind,
      spacing = f:control_spacing(),
      f:static_text { title = 'ExifCraft Settings', font = '<system/bold>' },
      f:row {
        f:static_text { title = 'ExifTool Path:' },
        f:edit_field  { value = LrView.bind('exiftoolPath'), width_in_chars = 40 },
      },
      f:checkbox {
        title = 'Enable verbose logs',
        value = LrView.bind('enableVerboseLogs'),
      },
      f:spacer { height = 8 },
      f:push_button {
        title = 'Save',
        action = function()
          prefs.exiftoolPath      = bind.exiftoolPath or ''
          prefs.enableVerboseLogs = bind.enableVerboseLogs and true or false
          log:info('Settings saved; exiftoolPath=' .. (prefs.exiftoolPath or ''))
          LrDialogs.message('ExifCraft', 'Settings saved.')
        end
      },
    }

    LrDialogs.presentModalDialog {
      title = 'ExifCraft Settings',
      contents = c,
      actionVerb = 'Close',
      cancelVerb = '< exclude >',
    }
  end)
end

-- 不再 return 函数，让 Info.lua 的 ["function"] 精确触发上面两者