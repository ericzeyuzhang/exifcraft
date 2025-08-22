--[[----------------------------------------------------------------------------

DialogPropsTransformer.lua
Dialog properties transformation for ExifCraft

This module handles the conversion between unified configuration format
and Lightroom dialog properties format, enabling seamless UI interaction.

------------------------------------------------------------------------------]]

local LrBinding = import 'LrBinding'
local LrPrefs = import 'LrPrefs'

-- Import required modules
local UIFormatConstants = require 'UIFormatConstants'
local SystemUtils = require 'SystemUtils'
local ConfigParser = require 'ConfigParser'
local PrefsManager = require 'PrefsManager'
local Dkjson = require 'Dkjson'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local DialogPropsTransformer = {}

-- Transform unified configuration to dialog properties
function DialogPropsTransformer.configToDialogProps(config, context)
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
    
    -- Tasks: convert to property tables for UI binding
    dialogProps.tasks = {}
    for _, task in ipairs(config.tasks) do
        local taskProps = LrBinding.makePropertyTable(context)
        taskProps.name = task and task.name or ''
        taskProps.prompt = task and task.prompt or ''
        taskProps.tags = task and task.tags or {}
        taskProps.enabled = task and task.enabled or false
        table.insert(dialogProps.tasks, taskProps)
    end
    
    return dialogProps
end


-- Load configuration and transform to dialog properties
function DialogPropsTransformer.loadDialogProps(context)
    logger:info('DialogPropsTransformer: Loading dialog props')
    local config = PrefsManager.loadConfig()
    logger:info('DialogPropsTransformer: Loaded config: ' .. tostring(config))
    return DialogPropsTransformer.configToDialogProps(config, context)
end

-- Persist dialog properties directly to preferences
function DialogPropsTransformer.persistToPrefs(dialogProps)
    if not dialogProps or not next(dialogProps) then
        logger:warn('Attempting to save empty or nil dialogProps, skipping save operation')
        return false
    end
    
    logger:info('DialogPropsTransformer: Persisting dialog props to preferences')

    -- Basic validation before processing
    if not dialogProps.aiProvider or 
       not dialogProps.tasks or #dialogProps.tasks == 0 then
        logger:warn('Dialog properties appear to be incomplete, skipping save operation')
        return false
    end

    -- Build normalized configuration directly for JSON encoding (no intermediate variable)
    local normalizedForJson = {
        aiModel = {
            provider = dialogProps.aiProvider or nil,
            endpoint = dialogProps.aiEndpoint or nil,
            model = dialogProps.aiModel or nil,
            key = (dialogProps.aiApiKey and dialogProps.aiApiKey ~= '') and dialogProps.aiApiKey or nil,
            options = {
                temperature = tonumber(dialogProps.aiTemperature) or 0,
                maxTokens = tonumber(dialogProps.aiMaxTokens) or 500,
            }
        },
        basePrompt = dialogProps.basePrompt or nil,
        preserveOriginal = SystemUtils.toBoolean(dialogProps.preserveOriginal),
        verbose = SystemUtils.toBoolean(dialogProps.verbose),
        dryRun = SystemUtils.toBoolean(dialogProps.dryRun),
        imageFormats = {},
        tasks = {}
    }

    -- Image formats as array
    for _, formatDefs in pairs(UIFormatConstants.UI_FORMAT_CONSTANTS) do
        for _, formatDef in ipairs(formatDefs) do
            local isEnabled = dialogProps[formatDef.property]
            if isEnabled then
                table.insert(normalizedForJson.imageFormats, formatDef.format)
            end
        end
    end

    -- Tasks: normalize property tables to plain tasks
    normalizedForJson.tasks = ConfigParser.buildTasksConfig(dialogProps.tasks or {})
    
    -- Encode to JSON and save directly to preferences
    local success, config_json = pcall(function()
        return Dkjson.encode(normalizedForJson, { indent = true })
    end)
    
    if not success or not config_json then
        logger:error('Failed to encode configuration to JSON: ' .. tostring(config_json))
        return false
    end
    
    local prefs = LrPrefs.prefsForPlugin()
    prefs.config_json = config_json
    logger:info('Configuration persisted directly to preferences as JSON')
    return true
end

-- Reset to default configuration and return dialog properties
function DialogPropsTransformer.resetToDefaults(context)
    local success = PrefsManager.resetToDefaults()
    if success then
        return DialogPropsTransformer.loadDialogProps(context)
    else
        logger:error('Failed to reset to defaults')
        return {}
    end
end

return DialogPropsTransformer
