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
        -- Handle both property objects and plain tables
        local name = taskProp.name
        local prompt = taskProp.prompt
        local taskTags = taskProp.tags
        local enabled = taskProp.enabled
        
        -- Extract values from property objects if needed
        if type(name) == 'table' and name.value ~= nil then
            name = name.value
        end
        if type(prompt) == 'table' and prompt.value ~= nil then
            prompt = prompt.value
        end
        if type(enabled) == 'table' and enabled.value ~= nil then
            enabled = enabled.value
        end
        
        local tags = {}
        if type(taskTags) == 'table' then
            -- Handle property objects in tags array
            local tagsArray = taskTags.value or taskTags
            for _, tag in ipairs(tagsArray) do
                if type(tag) == 'table' then
                    local tagName = tag.name
                    local tagOverwrite = tag.allowOverwrite
                    
                    -- Extract values from property objects if needed
                    if type(tagName) == 'table' and tagName.value ~= nil then
                        tagName = tagName.value
                    end
                    if type(tagOverwrite) == 'table' and tagOverwrite.value ~= nil then
                        tagOverwrite = tagOverwrite.value
                    end
                    
                    if tagName and tagName ~= '' then
                        table.insert(tags, {
                            name = tagName,
                            allowOverwrite = (tagOverwrite ~= false),
                        })
                    end
                end
            end
        end

        tasksConfig[i] = {
            name = tostring(name or ''),
            prompt = tostring(prompt or ''),
            tags = tags,
            enabled = enabled and true or false,
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

-- Deep clean configuration to remove property objects and ensure JSON serializability
function ConfigParser.deepCleanConfig(config)
    if not config or type(config) ~= 'table' then
        return config
    end
    
    local function cleanValue(value)
        if type(value) ~= 'table' then
            return value
        end
        
        -- Check if this is a property object (has metatable)
        local meta = getmetatable(value)
        if meta then
            -- This is likely a property object, extract the value
            if value.value ~= nil then
                return cleanValue(value.value)
            else
                -- Try to convert property object to plain table
                local cleaned = {}
                for k, v in pairs(value) do
                    -- Skip metatable-related keys and functions
                    if type(k) == 'string' and type(v) ~= 'function' and k ~= '__index' then
                        cleaned[k] = cleanValue(v)
                    end
                end
                return cleaned
            end
        end
        
        -- Clean regular tables recursively
        local cleaned = {}
        for k, v in pairs(value) do
            if type(v) ~= 'function' then
                cleaned[k] = cleanValue(v)
            end
        end
        return cleaned
    end
    
    return cleanValue(config)
end

-- Encode configuration to JSON string
function ConfigParser.encodeToJson(config)
    -- First deep clean the config to remove property objects
    local cleanedConfig = ConfigParser.deepCleanConfig(config)
    
    local success, result = pcall(function()
        return Dkjson.encode(cleanedConfig, { indent = true })
    end)
    
    if not success then
        logger:error('Failed to encode configuration to JSON: ' .. tostring(result))
        return nil
    end
    
    return result
end

return ConfigParser
