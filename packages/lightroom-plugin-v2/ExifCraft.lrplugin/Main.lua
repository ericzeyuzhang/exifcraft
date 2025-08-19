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
            width = 600,
            height = 800,
            resizable = true,
        }
        
        if result == 'ok' then
            -- Save configuration
            Config.saveConfiguration(dialogProps)
            
            -- Start processing with the settings
            PhotoProcessor.processPhotosWithSettings(dialogProps)
        else
            logger:info('Processing cancelled by user')
        end
    end)
end

-- Main entry point - called by Lightroom when menu item is selected
showUnifiedDialog()


