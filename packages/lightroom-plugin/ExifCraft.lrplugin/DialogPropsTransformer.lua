--[[----------------------------------------------------------------------------

DialogPropsTransformer.lua
Dialog properties transformation for ExifCraft

This module handles the conversion between unified configuration format
and Lightroom dialog properties format, enabling seamless UI interaction.

------------------------------------------------------------------------------]]

local LrBinding = import 'LrBinding'

-- Import required modules
local UIFormatConstants = require 'UIFormatConstants'
local SystemUtils = require 'SystemUtils'
local ConfigParser = require 'ConfigParser'
local PrefsManager = require 'PrefsManager'

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

-- Transform dialog properties to unified configuration
function DialogPropsTransformer.dialogPropsToConfig(dialogProps)
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
    config.tasks = ConfigParser.buildTasksConfig(dialogProps.tasks)

    return config
end

-- Load configuration and transform to dialog properties
function DialogPropsTransformer.loadDialogProps(context)
    local config = PrefsManager.loadConfig()
    return DialogPropsTransformer.configToDialogProps(config, context)
end

-- Transform dialog properties and save as configuration
function DialogPropsTransformer.saveDialogProps(dialogProps)
    local config = DialogPropsTransformer.dialogPropsToConfig(dialogProps)
    return PrefsManager.saveConfig(config)
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
