--[[----------------------------------------------------------------------------

Init.lua
Initialization script for ExifCraft v2 plugin

This script runs when the plugin is loaded and sets up global variables
and logging infrastructure.

------------------------------------------------------------------------------]]

local LrLogger = import 'LrLogger'

-- Create and configure the main logger
local logger = LrLogger('ExifCraftV2')
logger:enable("logfile")

-- Log plugin initialization
logger:info('=== ExifCraft v2 Plugin Initialization ===')
logger:info('Plugin path: ' .. _PLUGIN.path)
logger:info('Plugin ID: ' .. _PLUGIN.id)

-- Set up global logger for other modules to use
_G.ExifCraftLogger = logger

logger:info('Plugin initialization completed successfully')
