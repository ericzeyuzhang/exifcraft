--[[----------------------------------------------------------------------------

ConfigProvider.lua
Configuration format parsing and validation for ExifCraft

This module handles JSON configuration parsing, default configuration loading,
and configuration format validation.

------------------------------------------------------------------------------]]

local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrPrefs = import 'LrPrefs'

-- Import required modules
local Dkjson = require 'Dkjson'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ConfigProvider = {}

-- Parse persistent configuration JSON back to unified config format
function ConfigProvider.fromJsonString(config_json)
    logger:info('Parsing persistent configuration JSON')
    
    if not config_json or config_json == '' then
        return nil
    end
    
    local success, config = pcall(function()
        return Dkjson.decode(config_json)
    end)
    
    if not success or type(config) ~= 'table' then
        logger:error('Failed to parse persistent configuration JSON: ' .. tostring(config))
        return nil
    end
    
    -- Ensure required fields exist with defaults
    config.tasks = config.tasks or {}
    config.imageFormats = config.imageFormats or {}
    config.aiModel = config.aiModel or {}
    
    logger:info('Successfully parsed persistent configuration JSON in unified format')
    return config
end

-- Load unified default configuration from file
function ConfigProvider.fromDefaultJsonFile()
    local plugin_path = _PLUGIN.path
    local config_path = LrPathUtils.child(plugin_path, 'default-config.json')

    logger:info('Loading unified default configuration from: ' .. config_path)

    local config_json = LrFileUtils.readFile(config_path)
    if not config_json then
        error('Failed to read default-config.json')
    end

    local config = ConfigProvider.fromJsonString(config_json)

    if not config then
        logger:error('Failed to parse default-config.json')
        return nil, nil
    end

    logger:info('Successfully loaded unified default configuration')
    return config, config_json
end

function ConfigProvider.fromPrefs()
    local prefs = LrPrefs.prefsForPlugin()
    local config = ConfigProvider.fromJsonString(prefs.config_json)
    return config, prefs.config_json
end

return ConfigProvider


