local LrDialogs = import 'LrDialogs'
local LrLogger  = import 'LrLogger'

local log = LrLogger('ExifCraft')
log:enable('print')
log:enable('logfile')

log:info('Init.lua executed')
LrDialogs.message('ExifCraft', 'Init.lua executed ✅ (plugin loaded)')