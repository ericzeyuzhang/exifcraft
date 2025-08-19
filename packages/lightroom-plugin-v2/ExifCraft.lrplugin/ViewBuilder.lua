--[[----------------------------------------------------------------------------

ViewBuilder.lua
User interface components for ExifCraft v2

This module contains all UI creation functions for the configuration dialog.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local unpackFn = table.unpack or unpack

-- Import Config module
local Config = require 'Config'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

-- Create AI Model Configuration UI
local function createAIModelSection(viewFactory, dialogProps)
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header with prominent styling
        viewFactory:static_text {
            title = "AI Model Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        viewFactory:group_box {
            title = "",
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
        
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                
                viewFactory:static_text {
                    title = "Provider:",
                    width = 80,
                },
                
                viewFactory:popup_menu {
                    value = LrView.bind('aiProvider'),
                    items = {
                        { title = "Ollama", value = "ollama" },
                        { title = "OpenAI", value = "openai" },
                        { title = "Gemini", value = "gemini" },
                        { title = "Mock (Testing)", value = "mock" },
                    },
                    -- width_in_chars = 15,
                    fill_horizontal = 1,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Endpoint/API:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiEndpoint'),
                    immediate = true,
                    -- width_in_chars = 35,
                    fill_horizontal = 1,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Model:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiModel'),
                    immediate = true,
                    -- width_in_chars = 25,
                    fill_horizontal = 1,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "API Key:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiApiKey'),
                    immediate = true,
                    -- width_in_chars = 30,
                    fill_horizontal = 1,
                    password = true,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Temperature:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiTemperature'),
                    immediate = true,
                    width_in_chars = 8,
                    integral = false,
                },
                
                viewFactory:static_text {
                    title = "Max Tokens:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiMaxTokens'),
                    immediate = true,
                    width_in_chars = 8,
                    integral = true,
                },
            },
        },
    }
end

-- Create General Configuration UI
local function createGeneralSection(viewFactory, dialogProps, supportedFormats, context)
    -- Initialize format properties with defaults based on FORMAT_NAMES structure
    for property, _ in pairs(Config.FORMAT_NAMES) do
        dialogProps[property] = true
    end
    
    -- Get group names directly
    local standardGroupName = 'Standard'
    local rawGroupName = 'Raw'
    local tiffGroupName = 'Tiff'
    
    -- Get format properties by group directly from definitions
    local standardFormats = {}
    local rawFormats = {}
    local tiffFormats = {}
    
    for groupName, formatDefs in pairs(Config.FORMAT_DEFINITIONS) do
        for _, formatDef in ipairs(formatDefs) do
            if groupName == 'Standard' then
                table.insert(standardFormats, formatDef.property)
            elseif groupName == 'Raw' then
                table.insert(rawFormats, formatDef.property)
            elseif groupName == 'Tiff' then
                table.insert(tiffFormats, formatDef.property)
            end
        end
    end
    
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header with prominent styling
        viewFactory:static_text {
            title = "General Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:static_text {
                title = "Base Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = LrView.bind('basePrompt'),
                immediate = true,
                -- width_in_chars = 50,
                height_in_lines = 3,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:static_text {
            title = "Image Formats:",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
            
        -- Standard formats group
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = standardGroupName .. ": ",
                value = LrView.bind {
                    keys = standardFormats, 
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = true
                            local anySelected = false
                            for _, prop in ipairs(standardFormats) do
                                if values[prop] then
                                    anySelected = true
                                else
                                    allSelected = false
                                end
                            end
                            
                            if allSelected then
                                return true
                            elseif anySelected then
                                return nil
                            else
                                return false
                            end
                        else
                            return LrBinding.kUnsupportedDirection
                        end
                    end,
                    transform = function(value, fromTable)
                        if fromTable then
                            return value
                        else
                            for _, prop in ipairs(standardFormats) do
                                dialogProps[prop] = value
                            end
                            return LrBinding.kUnsupportedDirection
                        end
                    end,
                },
                checked_value = false,
                unchecked_value = false,
            },
        },

        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatJpg:upper(),
                value = LrView.bind('formatJpg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatJpeg:upper(),
                value = LrView.bind('formatJpeg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatHeic:upper(),
                value = LrView.bind('formatHeic'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatHeif:upper(),
                value = LrView.bind('formatHeif'),
                checked_value = true,
                unchecked_value = false,
            }
        }, 

        viewFactory:separator { fill_horizontal = 1 },

        -- Raw format group 
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = rawGroupName .. ": ",
                value = LrView.bind {
                    keys = rawFormats,
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = true
                            local anySelected = false
                            for _, prop in ipairs(rawFormats) do
                                if values[prop] then
                                    anySelected = true
                                else
                                    allSelected = false
                                end
                            end

                            if allSelected then
                                return true
                            elseif anySelected then
                                return nil
                            else
                                return false
                            end
                        else
                            return LrBinding.kUnsupportedDirection
                        end
                    end,

                    transform = function(value, fromTable)
                        if fromTable then
                            return value
                        else
                            for _, prop in ipairs(rawFormats) do
                                dialogProps[prop] = value
                            end
                            return LrBinding.kUnsupportedDirection
                        end
                    end,
                },
                checked_value = false,
                unchecked_value = false,
            },
        },

        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatDng:upper(),
                value = LrView.bind('formatDng'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatArw:upper(),
                value = LrView.bind('formatArw'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatNef:upper(),
                value = LrView.bind('formatNef'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatCr2:upper(),
                value = LrView.bind('formatCr2'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatCr3:upper(),
                value = LrView.bind('formatCr3'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatRaw:upper(),
                value = LrView.bind('formatRaw'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatRaf:upper(),
                value = LrView.bind('formatRaf'),
                checked_value = true,
                unchecked_value = false,
            },
        },

        viewFactory:separator { fill_horizontal = 1 },

        -- TIFF format group
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = tiffGroupName .. ": ",
                value = LrView.bind {
                    keys = tiffFormats,
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = true
                            local anySelected = false
                            for _, prop in ipairs(tiffFormats) do
                                if values[prop] then
                                    anySelected = true
                                else
                                    allSelected = false
                                end
                            end

                            if allSelected then
                                return true
                            elseif anySelected then
                                return nil
                            else
                                return false
                            end
                        else
                            return LrBinding.kUnsupportedDirection
                        end
                    end,
                    transform = function(value, fromTable)
                        if fromTable then
                            return value
                        else
                            for _, prop in ipairs(tiffFormats) do
                                dialogProps[prop] = value
                            end
                            return LrBinding.kUnsupportedDirection
                        end
                    end,
                },
                checked_value = false,
                unchecked_value = false,
            },
        },

        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatTiff:upper(),
                value = LrView.bind('formatTiff'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = Config.FORMAT_NAMES.formatTif:upper(),
                value = LrView.bind('formatTif'),
                checked_value = true,
                unchecked_value = false,
            },
        },

        viewFactory:separator { fill_horizontal = 1 },
            
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "Preserve Original Files",
                value = LrView.bind('preserveOriginal'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "Verbose Logging",
                value = LrView.bind('verbose'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "Dry Run (Preview Only)",
                value = LrView.bind('dryRun'),
                checked_value = true,
                unchecked_value = false,
            },
        },
    }
end

-- Create the main dialog UI
local function createMainDialog(viewFactory, dialogProps, supportedFormats, context)
    local content = viewFactory:column {
        bind_to_object = dialogProps,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        createAIModelSection(viewFactory, dialogProps),
        createGeneralSection(viewFactory, dialogProps, supportedFormats, context),
        
        viewFactory:separator { fill_horizontal = 1 },
        
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:push_button {
                title = "Reset to Defaults",
                action = function()
                    -- Reset to default settings
                    for key, defaultValue in pairs(Config.DEFAULT_SETTINGS) do
                        dialogProps[key] = defaultValue
                    end
                    
                    logger:info('Settings reset to defaults')
                end,
            },
            
            viewFactory:push_button {
                title = "Test Connection",
                action = function()
                    logger:info('Testing AI connection...')
                    -- This will be implemented later
                end,
            },
        },
    }
    
    -- Return static layout without any scrollable container
    return viewFactory:column {
        fill = 1,
        fill_horizontal = 1,
        fill_vertical = 1,
        content,
    }
end

-- Export module
return {
    createMainDialog = createMainDialog,
}
