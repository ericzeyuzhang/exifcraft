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
local dkjson = require 'Dkjson'

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

-- Helper function to create task UI for a single task
local function createTaskUI(viewFactory, dialogProps, taskIndex, task)
    return viewFactory:group_box {
        title = "",
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        bind_to_object = task,
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:static_text {
                title = "Name:",
                width = 60,
            },
            
            viewFactory:edit_field {
                value = LrView.bind('name'),
                immediate = true,
                -- width_in_chars = 50,
                height_in_lines = 1,
                fill_horizontal = 1,
            },

            viewFactory:push_button {
                title = "Delete",
                width = 80,
                action = function()
                    table.remove(dialogProps.tasks, taskIndex)
                end,
            },
        },

        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,
            
            viewFactory:static_text {
                title = "Prompt:",
                width = 60,
            },
            
            viewFactory:edit_field {
                value = LrView.bind('prompt'),
                immediate = true,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },

        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,
            
            viewFactory:static_text {
                title = "Tags:",
                width = 60,
            },

            viewFactory:edit_field {
                value = LrView.bind('name'),
                immediate = true,
                height_in_lines = 1,
                fill_horizontal = 1,
            },
        },
    }
end

-- Create Task Configuration UI
local function createTaskSection(viewFactory, dialogProps)
    -- Initialize tasks if not present
    if not dialogProps.tasks then
        dialogProps.tasks = Config.DEFAULT_SETTINGS.tasks
    end

    local taskUIs = {}
    
    -- Create UI for each task
    for i, task in ipairs(dialogProps.tasks or {}) do
        logger:info('Creating task UI for task ' .. i, 'with name ' .. task.name)
        table.insert(taskUIs, createTaskUI(viewFactory, dialogProps, i, task))
    end
    
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header
        viewFactory:static_text {
            title = "Task Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },

        -- Task list
        viewFactory:scrolled_view {
            fill_horizontal = 1,
            height = 300, 
            horizontal_scrolling = false,
            vertical_scrolling = true,
            content = viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                unpackFn(taskUIs),
            },
        },

        viewFactory:push_button {
            title = "Add Task",
            action = function()
                table.insert(dialogProps.tasks, {
                    name = 'New Task',
                    prompt = 'Enter prompt here...',
                    tags = 'Enter tags here...',
                })
            end,
        },
    }
end

-- Create General Configuration UI
local function createGeneralSection(viewFactory, dialogProps, supportedFormats, context)
    -- Initialize format properties with defaults
    for _, formatDefs in pairs(Config.FORMAT_DEFINITIONS) do
        for _, formatDef in ipairs(formatDefs) do
            dialogProps[formatDef.property] = true
        end
    end
    
    -- Get format properties by group directly from FORMAT_DEFINITIONS
    local standardFormats = {}
    local rawFormats = {}
    local tiffFormats = {}
    
    for _, formatDef in ipairs(Config.FORMAT_DEFINITIONS.Standard) do
        table.insert(standardFormats, formatDef.property)
    end
    for _, formatDef in ipairs(Config.FORMAT_DEFINITIONS.Raw) do
        table.insert(rawFormats, formatDef.property)
    end
    for _, formatDef in ipairs(Config.FORMAT_DEFINITIONS.Tiff) do
        table.insert(tiffFormats, formatDef.property)
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
                title = "Standard: ",
                font = '<system/bold/10>',
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
                title = "jpg",
                font = '<system/bold/10>',
                value = LrView.bind('formatJpg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "jpeg",
                font = '<system/bold/10>',
                value = LrView.bind('formatJpeg'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "heic",
                font = '<system/bold/10>',
                value = LrView.bind('formatHeic'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "heif",
                font = '<system/bold/10>',
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
                title = "Raw: ",
                font = '<system/bold/10>',
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
                title = "dng",
                font = '<system/bold/10>',
                value = LrView.bind('formatDng'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "arw",
                font = '<system/bold/10>',
                value = LrView.bind('formatArw'),
                checked_value = true,
                unchecked_value = false,
            },
            
            viewFactory:checkbox {
                title = "nef",
                font = '<system/bold/10>',
                value = LrView.bind('formatNef'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "cr2",
                font = '<system/bold/10>',
                value = LrView.bind('formatCr2'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "cr3",
                font = '<system/bold/10>',
                value = LrView.bind('formatCr3'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "raw",
                font = '<system/bold/10>',
                value = LrView.bind('formatRaw'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "raf",
                font = '<system/bold/10>',
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
                title = "Tiff: ",
                font = '<system/bold/10>',
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
                title = "tiff",
                font = '<system/bold/10>',
                value = LrView.bind('formatTiff'),
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:checkbox {
                title = "tif",
                font = '<system/bold/10>',
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
        createTaskSection(viewFactory, dialogProps),
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
                    
                    -- Reset tasks to default
                    dialogProps.tasks = Config.DEFAULT_SETTINGS.tasks
                    
                    logger:info('Settings and tasks reset to defaults')
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
