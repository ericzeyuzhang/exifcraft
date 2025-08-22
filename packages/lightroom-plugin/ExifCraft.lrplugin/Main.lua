--[[----------------------------------------------------------------------------

Main.lua
Main entry point for ExifCraft

This script handles the AI-powered EXIF metadata generation for selected photos
in the Lightroom library, with integrated settings configuration.

------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'
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
local PrefsManager = require 'PrefsManager'
local DialogPropsTransformer = require 'DialogPropsTransformer'
local UIStyleConstants = require 'UIStyleConstants'
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
        
        logger:info('Main.lua: Loading dialog props')
        local loadedProps = DialogPropsTransformer.loadFromPrefs(context)
        local dialogProps = LrBinding.makePropertyTable(context)
        for k, v in pairs(loadedProps) do
            dialogProps[k] = v
        end

        logger:info('Main.lua: starting to build main dialog')
        -- Create the main dialog UI
        local ui = ViewBuilder.createMainDialog(f, dialogProps, context)

        logger:info('Main.lua: presenting main dialog')
        local result = LrDialogs.presentModalDialog {
            title = 'ExifCraft - Configure & Process',
            contents = ui,
            action_verb = 'Process',
            cancel_verb = 'Cancel',
            width = UIStyleConstants.UI_STYLE_CONSTANTS.dimensions.main_dialog.width,
            height = UIStyleConstants.UI_STYLE_CONSTANTS.dimensions.main_dialog.height,
            minimum_width = UIStyleConstants.UI_STYLE_CONSTANTS.dimensions.main_dialog.minimum_width,
            minimum_height = UIStyleConstants.UI_STYLE_CONSTANTS.dimensions.main_dialog.minimum_height,
            resizable = true,
        }
        
        if result == 'ok' then
            logger:info('Main.lua: user clicked ok')
            -- Save user changes to preferences
            DialogPropsTransformer.persistToPrefs(dialogProps)
            
            -- Reload the saved configuration in correct format for processing
            logger:info('Main.lua: loading config')
            local processConfig = PrefsManager.loadConfig()
            logger:info('Main.lua: processing photos')
            PhotoProcessor.process(processConfig)
        end
    end)
end

-- Main entry point - called by Lightroom when menu item is selected
showUnifiedDialog()


