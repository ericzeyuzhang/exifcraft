--[[----------------------------------------------------------------------------

PrefsManager.lua
Lightroom preferences management for ExifCraft

This module handles loading/saving configuration from/to Lightroom preferences,
providing a clean interface for preference operations.

------------------------------------------------------------------------------]]

local LrPrefs = import 'LrPrefs'

-- Import required modules
local ConfigParser = require 'ConfigParser'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local PrefsManager = {}

-- Load configuration from Lightroom preferences
function PrefsManager.loadConfig()
    local prefs = LrPrefs.prefsForPlugin()

    -- Handle cold start - initialize with defaults
    if not prefs.config_json or prefs.config_json == '' then
        logger:info('PrefsManager: Cold start: No configuration found in preferences (config_json: ' .. tostring(prefs.config_json) .. ')')
        prefs.config_json = ConfigParser.getDefaultConfigJson()
        logger:info('PrefsManager: Cold start: Initialized default configuration as JSON')
    end
    
    -- Load from JSON configuration
    local config = ConfigParser.parseFromJson(prefs.config_json)
    if config then
        logger:info('Configuration loaded from JSON preferences')
        logger:info('Config Json: ' .. prefs.config_json)
    else
        logger:error('Failed to parse JSON configuration, falling back to defaults')
    end

    return config
end

-- Save configuration to Lightroom preferences
function PrefsManager.saveConfig(config)
    if not config then
        logger:error('Cannot save nil configuration')
        return false
    end
    
    -- Validate configuration before saving
    local valid, error_msg = ConfigParser.validateConfig(config)
    if not valid then
        logger:error('Configuration validation failed: ' .. (error_msg or 'Unknown error'))
        return false
    end
    
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Create and save JSON configuration
    local config_json = ConfigParser.encodeToJson(config)
    if not config_json then
        logger:error('Failed to encode configuration to JSON')
        return false
    end
    
    prefs.config_json = config_json
    logger:info('Configuration saved to preferences as JSON: ' .. config_json)
    return true
end

-- Reset preferences to default configuration
function PrefsManager.resetToDefaults()
    local prefs = LrPrefs.prefsForPlugin()
    prefs.config_json = ConfigParser.getDefaultConfigJson()
    logger:info('Reset configuration to defaults in preferences')
end

-- Get raw JSON configuration from preferences
function PrefsManager.getRawConfigJson()
    local prefs = LrPrefs.prefsForPlugin()
    return prefs.config_json
end

-- Set raw JSON configuration in preferences (use with caution)
function PrefsManager.setRawConfigJson(config_json)
    local prefs = LrPrefs.prefsForPlugin()
    prefs.config_json = config_json
    logger:info('Raw configuration JSON set in preferences')
end

return PrefsManager
