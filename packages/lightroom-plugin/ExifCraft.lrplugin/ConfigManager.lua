--[[----------------------------------------------------------------------------

ConfigManager.lua
Configuration management for ExifCraft

This module handles configuration loading/saving and orchestrates
other configuration-related modules.

------------------------------------------------------------------------------]]

local LrPrefs = import 'LrPrefs'
local LrBinding = import 'LrBinding'

-- Import configuration modules
local Dkjson = require 'Dkjson'
local DefaultConfigProvider = require 'DefaultConfigProvider'
local UIFormatConstants = require 'UIFormatConstants'
local SystemUtils = require 'SystemUtils'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ConfigManager = {}

-- Normalize property tables to plain tasks and serialize them
local function buildTasksConfig(taskProps)
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

-- Parse persistent configuration JSON back to unified config format (internal)
local function parseFromJson(configJson)
    logger:info('Parsing persistent configuration JSON')
    
    if not configJson or configJson == '' then
        return nil
    end
    
    local success, config = pcall(function()
        return Dkjson.decode(configJson)
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

-- Load configuration from preferences
function ConfigManager.loadFromPrefs()
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Handle cold start - initialize with defaults
    if not prefs.configJson or prefs.configJson == '' then
        prefs.configJson = DefaultConfigProvider.DEFAULT_SETTINGS_JSON
        logger:info('Initialized default configuration as JSON')
    end
    
    -- Load from JSON configuration
    local config = parseFromJson(prefs.configJson)
    if config then
        logger:info('Configuration loaded from JSON preferences')
    else
        logger:error('Failed to parse JSON configuration, falling back to defaults')
    end

    return config
end

-- Save configuration to preferences
function ConfigManager.saveToPrefs(config)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Ensure all tasks have unique IDs before saving
    if config.tasks then
        for i, task in ipairs(config.tasks) do
            if not task.id then
                task.id = tostring(i)
            end
        end
    end
    
    -- Create and save JSON configuration (config is already in unified format)
    local configJson = Dkjson.encode(config, { indent = true })
    prefs.configJson = configJson
    
    logger:info('Configuration saved to preferences as JSON')
end

-- Build a unified configuration from dialog properties (internal)
function ConfigManager.buildFromDialogProps(dialogProps)
    local config = {}

    -- AI model configuration (nested structure)
    config.aiModel = {
        provider = dialogProps.aiProvider,
        endpoint = dialogProps.aiEndpoint,
        model = dialogProps.aiModel,
        key = dialogProps.aiApiKey ~= '' and dialogProps.aiApiKey or nil,
        options = {
            temperature = tonumber(dialogProps.aiTemperature) or 0,
            maxTokens = tonumber(dialogProps.aiMaxTokens) or 500,
        }
    }

    -- General settings (flattened structure)
    config.basePrompt = dialogProps.basePrompt
    config.preserveOriginal = SystemUtils.toBoolean(dialogProps.preserveOriginal)
    config.verbose = SystemUtils.toBoolean(dialogProps.verbose)
    config.dryRun = SystemUtils.toBoolean(dialogProps.dryRun)

    -- Image formats as array
    local selectedFormats = {}
    for _, formatDefs in pairs(UIFormatConstants.UI_FORMAT_CONSTANTS) do
        for _, formatDef in ipairs(formatDefs) do
            local isEnabled = dialogProps[formatDef.property]
            if isEnabled then
                table.insert(selectedFormats, formatDef.format)
            end
        end
    end
    config.imageFormats = selectedFormats

    -- Tasks: normalize property tables to plain tasks
    config.tasks = buildTasksConfig(dialogProps.tasks)

    return config
end

function ConfigManager.transformToDialogProps(config, context)
    if not config then
        return {}
    end
    
    local dialogProps = {}
    
    -- AI Model Configuration: flatten nested structure
    if config.aiModel then
        dialogProps.aiProvider = config.aiModel.provider
        dialogProps.aiEndpoint = config.aiModel.endpoint
        dialogProps.aiModel = config.aiModel.model
        dialogProps.aiApiKey = config.aiModel.key or ''
        
        if config.aiModel.options then
            dialogProps.aiTemperature = config.aiModel.options.temperature or 0
            dialogProps.aiMaxTokens = config.aiModel.options.maxTokens or 500
        else
            dialogProps.aiTemperature = 0
            dialogProps.aiMaxTokens = 500
        end
    end
    
    -- General settings: direct mapping
    dialogProps.basePrompt = config.basePrompt
    dialogProps.preserveOriginal = config.preserveOriginal
    dialogProps.verbose = config.verbose
    dialogProps.dryRun = config.dryRun
    
    -- Image formats: convert array to individual boolean properties
    local enabledFormats = {}
    if type(config.imageFormats) == 'table' then
        for _, format in ipairs(config.imageFormats) do
            enabledFormats[format] = true
        end
    end
    
    -- Set format boolean properties based on FORMAT_DEFINITIONS
    for _, formatDefs in pairs(UIFormatConstants.UI_FORMAT_CONSTANTS) do
        for _, formatDef in ipairs(formatDefs) do
            dialogProps[formatDef.property] = enabledFormats[formatDef.format] or false
        end
    end
    
    dialogProps.tasks = {}
    for i, task in ipairs(config.tasks) do
        local taskProps = LrBinding.makePropertyTable(context)
        taskProps.id = (task and task.id) or tostring(i)
        taskProps.name = task and task.name or ''
        taskProps.prompt = task and task.prompt or ''
        taskProps.tags = task and task.tags or {}
        taskProps.enabled = task and task.enabled or false
        table.insert(dialogProps.tasks, taskProps)
    end
    
    return dialogProps
end

-- Reset preferences to default JSON and return dialog properties built from it
function ConfigManager.resetToDefaults(context)
    local prefs = LrPrefs.prefsForPlugin()
    prefs.configJson = DefaultConfigProvider.DEFAULT_SETTINGS_JSON
    logger:info('Reset configuration to defaults in preferences')

    local config = parseFromJson(prefs.configJson)
    return ConfigManager.transformToDialogProps(config, context)
end

-- Export module
return ConfigManager
