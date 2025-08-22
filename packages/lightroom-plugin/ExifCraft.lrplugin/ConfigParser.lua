--[[----------------------------------------------------------------------------

ConfigParser.lua
Configuration format parsing and validation for ExifCraft

This module handles JSON configuration parsing, default configuration loading,
and configuration format validation.

------------------------------------------------------------------------------]]

local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'

-- Import required modules
local Dkjson = require 'Dkjson'
local SystemUtils = require 'SystemUtils'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ConfigParser = {}

-- Parse persistent configuration JSON back to unified config format
function ConfigParser.parseFromJson(config_json)
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
function ConfigParser.getDefaultConfigJson()
    local plugin_path = _PLUGIN.path
    local config_path = LrPathUtils.child(plugin_path, 'default-config.json')

    logger:info('Loading unified default configuration from: ' .. config_path)

    local config_json = LrFileUtils.readFile(config_path)
    if not config_json then
        error('Failed to read default-config.json')
    end

    local config = ConfigParser.parseFromJson(config_json)

    if not config then
        logger:error('Failed to parse default-config.json')
        return nil
    end

    logger:info('Successfully loaded unified default configuration')
    return config_json
end

-- Normalize property tables to plain tasks and serialize them
function ConfigParser.buildTasksConfig(taskProps)
    -- Normalize property tables to plain tables
    local tasksConfig = {}
    for i, taskProp in ipairs(taskProps or {}) do
        local tags = {}
        if type(taskProp.tags) == 'table' then
            for _, tag in ipairs(taskProp.tags) do
                if type(tag) == 'table' and tag.name and tag.name ~= '' then
                    table.insert(tags, {
                        name = tag.name,
                        allowOverwrite = (tag.allowOverwrite ~= false),
                    })
                end
            end
        end

        tasksConfig[i] = {
            name = taskProp.name or '',
            prompt = taskProp.prompt or '',
            tags = tags,
            enabled = taskProp.enabled and true or false,
        }
    end

    return tasksConfig
end

-- Validate configuration structure
function ConfigParser.validateConfig(config)
    if not config or type(config) ~= 'table' then
        return false, 'Configuration must be a table'
    end
    
    -- Check required top-level fields
    if not config.tasks or type(config.tasks) ~= 'table' then
        return false, 'Configuration must have tasks array'
    end
    
    if not config.imageFormats or type(config.imageFormats) ~= 'table' then
        return false, 'Configuration must have imageFormats array'
    end
    
    if not config.aiModel or type(config.aiModel) ~= 'table' then
        return false, 'Configuration must have aiModel object'
    end
    
    return true, nil
end

-- Encode configuration to JSON string
function ConfigParser.encodeToJson(config)
    local success, result = pcall(function()
        return Dkjson.encode(config, { indent = true })
    end)
    
    if not success then
        logger:error('Failed to encode configuration to JSON: ' .. tostring(result))
        return nil
    end
    
    return result
end

return ConfigParser
