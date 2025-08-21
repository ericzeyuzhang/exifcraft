--[[----------------------------------------------------------------------------

DefaultConfigProvider.lua
Default configuration provider for ExifCraft

This lightweight module provides access to the unified default configuration.
It's designed to be safely imported by any module without causing circular dependencies.

------------------------------------------------------------------------------]]

local Json = require 'utils.Json'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

-- Load unified default configuration
local function loadDefaultConfig()
    local plugin_path = _PLUGIN.path
    local config_path = LrPathUtils.child(plugin_path, 'default-config.json')
    
    logger:info('Loading unified default configuration from: ' .. config_path)
    
    local json_content = LrFileUtils.readFile(config_path)
    if not json_content then
        error('Failed to read default-config.json')
    end
    
    local ok, config = pcall(Json.decode, json_content)
    if not ok or type(config) ~= 'table' then
        error('Failed to parse default-config.json: ' .. tostring(config))
    end
    
    logger:info('Successfully loaded unified default configuration')
    return config, json_content
end

-- Load the unified configuration at module initialization
local DEFAULT_SETTINGS, DEFAULT_SETTINGS_JSON = loadDefaultConfig()

-- Export module
return {
    -- Unified configuration (works for both CLI and Lightroom)
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    DEFAULT_SETTINGS_JSON = DEFAULT_SETTINGS_JSON,
}
