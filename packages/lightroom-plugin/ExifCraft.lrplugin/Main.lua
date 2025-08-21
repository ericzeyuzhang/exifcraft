--[[----------------------------------------------------------------------------

Main.lua
Main entry point for ExifCraft

This script handles the AI-powered EXIF metadata generation for selected photos
in the Lightroom library, with integrated settings configuration.

------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'

-- Import local modules
do
    local ok, err = pcall(function() return require('Dkjson') end)
    if not ok then
        _G.ExifCraftLogger:error('require Dkjson failed: ' .. tostring(err))
    else
        _G.ExifCraftLogger:info('require Dkjson succeeded')
    end
end
local ConfigManager = require 'ConfigManager'
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
        
        -- Load unified configuration and adapt it for UI
        local config = ConfigManager.loadFromPrefs()
        local adaptedConfig = ConfigManager.transformToDialogProps(config, context)
        local dialogProps = LrBinding.makePropertyTable(context, adaptedConfig)

        -- Create the main dialog UI
        local ui = ViewBuilder.createMainDialog(f, dialogProps, context)
        
        local result = LrDialogs.presentModalDialog {
            title = 'ExifCraft - Configure & Process',
            contents = ui,
            action_verb = 'Process',
            cancel_verb = 'Cancel',
            width = 1000,
            height = 700,
            minimum_width = 1000,
            minimum_height = 700,
            resizable = true,
            window_style = 'palette',
        }
        
        if result == 'ok' then
            -- Build and save configuration from dialog properties
            local config = ConfigManager.buildFromDialogProps(dialogProps)
            ConfigManager.saveToPrefs(config)

            PhotoProcessor.process(config)
        end
    end)
end

-- Main entry point - called by Lightroom when menu item is selected
showUnifiedDialog()


