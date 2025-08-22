--[[----------------------------------------------------------------------------

ClearPrefs.lua
Clear ExifCraft preferences utility

This script provides functionality to clear all ExifCraft preferences
after user confirmation.

------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'
local LrFunctionContext = import 'LrFunctionContext'
local LrView = import 'LrView'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

logger:info('ClearPrefs.lua loaded')

-- Clear all ExifCraft preferences
local function clearAllPreferences()
    logger:info('Clearing all ExifCraft preferences')
    
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Only clear the specific keys we know about, don't iterate over all keys
    -- This is safer and avoids potential conflicts with LR internal properties
    prefs.config_json = nil
    
    logger:info('All ExifCraft preferences cleared successfully')
end

-- Show confirmation dialog and handle clearing preferences
local function showClearPrefsDialog()
    logger:info('Showing clear preferences confirmation dialog')
    
    LrFunctionContext.callWithContext("showClearPrefsDialog", function(context)
        local f = LrView.osFactory()
        
        -- Create confirmation dialog content
        local contents = f:column {
            spacing = f:control_spacing(),
            
            f:static_text {
                title = "This action will permanently delete all ExifCraft settings and configurations.",
                width = 400,
                height_in_lines = 2,
            },
            
            f:static_text {
                title = "Are you sure you want to continue?",
                width = 400,
                font = "<system/bold>",
            },
            
            f:static_text {
                title = "This operation cannot be undone.",
                width = 400,
                text_color = import('LrColor')(1, 0, 0), -- Red color for warning
            },
        }
        
        -- Show confirmation dialog
        local result = LrDialogs.presentModalDialog {
            title = 'Clear All ExifCraft Settings',
            contents = contents,
            action_verb = 'Clear Settings',
            cancel_verb = 'Cancel',
        }
        
        if result == 'ok' then
            logger:info('User confirmed clearing preferences')
            clearAllPreferences()
            
            -- Show success message
            LrDialogs.message('Settings Cleared', 'All ExifCraft settings have been successfully cleared.', 'info')
        else
            logger:info('User cancelled clearing preferences')
        end
    end)
end

-- Main entry point - called by Lightroom when menu item is selected
showClearPrefsDialog()
