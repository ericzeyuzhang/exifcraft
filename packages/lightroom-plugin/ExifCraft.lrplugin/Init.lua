--[[----------------------------------------------------------------------------

Init.lua
Initialization script for ExifCraft plugin

This script runs when the plugin is loaded and sets up global variables
and logging infrastructure.

------------------------------------------------------------------------------]]

local LrLogger = import 'LrLogger'

-- Create and configure the main logger
local logger = LrLogger('ExifCraft')
logger:enable("logfile")

-- Log plugin initialization
logger:info('=== ExifCraft Plugin Initialization ===')
logger:info('Plugin path: ' .. _PLUGIN.path)
logger:info('Plugin ID: ' .. _PLUGIN.id)
logger:info('Main entry point: Main.lua')
if type(package) == 'table' and type(package.path) == 'string' then
    logger:info('Initial package.path: ' .. tostring(package.path))
else
    logger:info('Initial package.path not available (package is nil)')
end

-- Ensure Lua can require modules from this plugin directory
do
    if type(package) == 'table' and type(package.path) == 'string' then
        local pluginPath = _PLUGIN.path
        local additions = pluginPath .. '/?.lua;' .. pluginPath .. '/?/init.lua'
        if not string.find(package.path, pluginPath, 1, true) then
            package.path = package.path .. ';' .. additions
            logger:info('Updated package.path for plugin modules')
        end
    else
        logger:info('Skipping package.path update because package is not available')
    end
end

if type(package) == 'table' and type(package.path) == 'string' then
    logger:info('Updated package.path: ' .. tostring(package.path))
else
    logger:info('Updated package.path not available (package is nil)')
end

-- Set up global logger for other modules to use
_G.ExifCraftLogger = logger

logger:info('Plugin initialization completed successfully')
