--[[----------------------------------------------------------------------------

ViewBuilder.lua
User interface components for ExifCraft v2

This module contains all UI creation functions for the configuration dialog.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local unpackFn = table.unpack or unpack

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
    -- Import Config module for format types
    local Config = require 'Config'
    
    -- Create property table for UI binding
    -- local formatProps = LrBinding.makePropertyTable(context)
    
    -- Initialize format properties with defaults based on new FORMAT_TYPES structure
    for property, _ in pairs(Config.FORMAT_TYPES) do
        dialogProps[property] = true
    end
    
    -- Initialize group properties (Select All checkboxes)
    for _, groupProperty in pairs(Config.GROUP_PROPERTIES) do
        dialogProps[groupProperty] = true
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
            
        -- standard formats group
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "Standard Formats: ",
                value = LrView.bind {
                    keys = {'formatJpg', 'formatJpeg', 'formatHeic', 'formatHeif'}, 
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = values.formatJpg and values.formatJpeg and values.formatHeic and values.formatHeif
                            local anySelected = values.formatJpg or values.formatJpeg or values.formatHeic or values.formatHeif
                            
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
                            dialogProps.formatJpg = value
                            dialogProps.formatJpeg = value
                            dialogProps.formatHeic = value
                            dialogProps.formatHeif = value
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
                title = "JPG",
                value = LrView.bind('formatJpg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "JPEG",
                value = LrView.bind('formatJpeg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "HEIC",
                value = LrView.bind('formatHeic'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "HEIF",
                value = LrView.bind('formatHeif'),
                checked_value = true,
                unchecked_value = false,
            }
        }, 

        viewFactory:separator { fill_horizontal = 1 },

        -- raw format group 
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "Raw Formats: ",
                value = LrView.bind {
                    keys = {'formatDng', 'formatArw', 'formatNef', 'formatCr2', 'formatCr3', 'formatRaw'},
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = values.formatDng and values.formatArw and values.formatNef and values.formatCr2 and values.formatCr3 and values.formatRaw
                            local anySelected = values.formatDng or values.formatArw or values.formatNef or values.formatCr2 or values.formatCr3 or values.formatRaw

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
                            dialogProps.formatDng = value
                            dialogProps.formatArw = value
                            dialogProps.formatNef = value
                            dialogProps.formatCr2 = value
                            dialogProps.formatCr3 = value
                            dialogProps.formatRaw = value
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
                title = "DNG",
                value = LrView.bind('formatDng'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "ARW",
                value = LrView.bind('formatArw'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "NEF",
                value = LrView.bind('formatNef'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "CR2",
                value = LrView.bind('formatCr2'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "CR3",
                value = LrView.bind('formatCr3'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "Raw",
                value = LrView.bind('formatRaw'),
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
                title = "TIFF Formats: ",
                value = LrView.bind {
                    keys = {'formatTiff', 'formatTif'},
                    operation = function(_, values, fromTable)
                        if fromTable then
                            local allSelected = values.formatTiff and values.formatTif
                            local anySelected = values.formatTiff or values.formatTif

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
                            dialogProps.formatTiff = value
                            dialogProps.formatTif = value
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
                title = "TIFF",
                value = LrView.bind('formatTiff'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "TIF",
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
                    local Config = require 'Config'
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
