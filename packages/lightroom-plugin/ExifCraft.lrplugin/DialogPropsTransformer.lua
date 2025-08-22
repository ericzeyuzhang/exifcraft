--[[----------------------------------------------------------------------------

DialogPropsTransformer.lua
Dialog properties transformation for ExifCraft

This module handles the conversion between unified configuration format
and Lightroom dialog properties format, enabling seamless UI interaction.

------------------------------------------------------------------------------]]

local LrPrefs = import 'LrPrefs'
-- LrBinding not required in this module

-- Import required modules
local UIFormatConstants = require 'UIFormatConstants'
local SystemUtils = require 'SystemUtils'
local Dkjson = require 'Dkjson'
local ConfigParser = require 'ConfigParser'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local DialogPropsTransformer = {}

-- Load dialog properties directly from preferences
function DialogPropsTransformer.fromConfig(config, dialogProps)
    logger:info('DialogPropsTransformer: Loading dialog props directly from preferences')

    if not config then
        logger:error('Failed to load configuration')
        return nil
    end

    if not dialogProps then
        logger:error('dialogProps table is required but was nil')
        return nil
    end

    -- Ensure required fields exist with defaults
    config.tasks = config.tasks or {}
    config.imageFormats = config.imageFormats or {}
    config.aiModel = config.aiModel or {}
    
    
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
    
    -- Tasks: flatten to individual properties (task_1_name, task_1_prompt, etc.)
    for i = 1, 5 do
        local task = config.tasks[i]
        if task then
            dialogProps['task_' .. i .. '_name'] = task.name or ''
            dialogProps['task_' .. i .. '_prompt'] = task.prompt or ''
            dialogProps['task_' .. i .. '_enabled'] = task.enabled or false
            
            -- Serialize tags as JSON string for flat storage
            local success, tagsJson = pcall(function()
                return Dkjson.encode(task.tags or {})
            end)
            dialogProps['task_' .. i .. '_tags'] = success and tagsJson or '[]'
        else
            -- Set empty defaults for unused tasks
            dialogProps['task_' .. i .. '_name'] = ''
            dialogProps['task_' .. i .. '_prompt'] = ''
            dialogProps['task_' .. i .. '_enabled'] = false
            dialogProps['task_' .. i .. '_tags'] = '[]'
        end
    end
    
    logger:info('DialogPropsTransformer: Successfully loaded dialog props directly from preferences')
    return nil
end

-- Load dialog properties from preferences or defaults
function DialogPropsTransformer.loadFromPrefsOrDefault(dialogProps)
    logger:info('DialogPropsTransformer: Loading dialog props from preferences or defaults')
    
    -- Try to load from preferences first
    local config, _ = ConfigParser.getConfigFromPrefs()
    
    if not config then
        -- If no config in prefs, load defaults
        logger:info('No config in preferences, loading defaults')
        config, _ = ConfigParser.getDefaultConfig()
        
        if not config then
            logger:error('Failed to load default configuration')
            return nil
        end
    end
    
    return DialogPropsTransformer.fromConfig(config, dialogProps)
end

-- Persist dialog properties directly to preferences
function DialogPropsTransformer.persistToPrefs(dialogProps)
    if not dialogProps or not next(dialogProps) then
        logger:warn('Attempting to save empty or nil dialogProps, skipping save operation')
        return false
    end
    
    logger:info('DialogPropsTransformer: Persisting dialog props to preferences')

    -- Basic validation before processing
    if not dialogProps.aiProvider then
        logger:warn('Dialog properties appear to be incomplete (missing aiProvider), skipping save operation')
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

    -- Tasks: build from flattened properties
    normalizedForJson.tasks = {}
    for i = 1, 5 do
        local taskName = dialogProps['task_' .. i .. '_name']
        local taskPrompt = dialogProps['task_' .. i .. '_prompt']
        local taskEnabled = dialogProps['task_' .. i .. '_enabled']
        local taskTagsJson = dialogProps['task_' .. i .. '_tags']
        
        if taskName and taskName ~= '' then
            local taskTags = {}
            if taskTagsJson and taskTagsJson ~= '[]' then
                local success, tags = pcall(function()
                    return Dkjson.decode(taskTagsJson)
                end)
                if success and type(tags) == 'table' then
                    taskTags = tags
                end
            end
            
            table.insert(normalizedForJson.tasks, {
                name = taskName,
                prompt = taskPrompt or '',
                enabled = SystemUtils.toBoolean(taskEnabled),
                tags = taskTags
            })
        end
    end
    
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

return DialogPropsTransformer
