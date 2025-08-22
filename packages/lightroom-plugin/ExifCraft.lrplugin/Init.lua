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

-- Set up global logger for other modules to use
_G.ExifCraftLogger = logger

logger:info('Plugin initialization completed successfully')
