--[[----------------------------------------------------------------------------

Main.lua
Main entry point for ExifCraft v2

This script handles the AI-powered EXIF metadata generation for selected photos
in the Lightroom library, with integrated settings configuration.

------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'

-- Import local modules
local Config = require 'Config'
local ViewBuilder = require 'ViewBuilder'
local PhotoProcessor = require 'PhotoProcessor'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

logger:info('Main.lua loaded')

-- Show unified settings and processing dialog
local function showUnifiedDialog()
    logger:info('Showing unified settings and processing dialog')
    
    LrFunctionContext.callWithContext("showUnifiedDialog", function(context)
        local f = LrView.osFactory()
        local dialogProps = LrBinding.makePropertyTable(context)
        
        -- Load configuration
        local settings = Config.loadConfiguration()
        
        -- Initialize bindings with loaded settings
        for key, value in pairs(settings) do
            dialogProps[key] = value
        end
        
        -- Create the main dialog UI  
        local supportedFormats = {}
        for _, formatDefs in pairs(Config.FORMAT_DEFINITIONS) do
            for _, formatDef in ipairs(formatDefs) do
                table.insert(supportedFormats, formatDef.format)
            end
        end
        local ui = ViewBuilder.createMainDialog(f, dialogProps, supportedFormats, context)
        
        local result = LrDialogs.presentModalDialog {
            title = 'ExifCraft v2 - Configure & Process',
            contents = ui,
            actionVerb = 'Process',
            cancelVerb = 'Cancel',
            width = 1000,
            height = 700,
            minimum_width = 1000,
            minimum_height = 700,
            resizable = true,
            windowStyle = 'palette',
        }
        
        if result == 'ok' then
            -- Convert property tables back to regular tables for saving
            local configToSave = {}
            for key, value in pairs(dialogProps) do
                if key == 'tasks' then
                    -- Convert task property tables to regular tables
                    configToSave.tasks = {}
                    for i, taskProp in ipairs(dialogProps.tasks) do
                        configToSave.tasks[i] = {
                            id = taskProp.id,
                            name = taskProp.name,
                            prompt = taskProp.prompt,
                            tags = taskProp.tags,
                            enabled = taskProp.enabled,
                            isCustom = taskProp.isCustom
                        }
                    end
                else
                    configToSave[key] = value
                end
            end
            
            -- Save configuration
            Config.saveConfiguration(configToSave)
            
            -- Start processing with the settings
            PhotoProcessor.processPhotosWithSettings(configToSave)
        else
            logger:info('Processing cancelled by user')
        end
    end)
end

-- Main entry point - called by Lightroom when menu item is selected
showUnifiedDialog()


