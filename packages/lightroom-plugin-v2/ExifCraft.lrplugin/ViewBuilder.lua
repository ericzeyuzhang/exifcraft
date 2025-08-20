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



-- Create individual task UI component
local function createTaskItemUI(viewFactory, dialogProps, taskIndex, taskProp)
    return viewFactory:group_box {
        title = taskProp.name,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        bind_to_object = taskProp,
        
        -- Task description
        viewFactory:static_text {
            title = taskProp.description,
            font = '<system/10>',
            fill_horizontal = 1,
        },
        
        -- Enable/disable checkbox
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,
            
            viewFactory:checkbox {
                title = "Enable this task",
                value = LrView.bind('enabled'),
                fill_horizontal = 1,
            },
        },
        
        -- Prompt editing
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
        
        -- Tags display (read-only)
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,
            
            viewFactory:static_text {
                title = "Tags:",
                width = 60,
            },
            
            viewFactory:static_text {
                title = function()
                    local tagNames = {}
                    if taskProp.tags then
                        for _, tag in ipairs(taskProp.tags) do
                            table.insert(tagNames, tag.name)
                        end
                    end
                    return table.concat(tagNames, ', ')
                end,
                font = '<system/10>',
                fill_horizontal = 1,
            },
        },
    }
end

-- Create Task Configuration UI
local function createTaskSection(viewFactory, dialogProps, context)
    -- Initialize tasks if not present
    if not dialogProps.tasks then
        dialogProps.tasks = {}
        for i, task in ipairs(Config.PRESET_TASK_TEMPLATES) do
            -- Create individual property table for each task
            local taskProps = LrBinding.makePropertyTable(context)
            taskProps.id = task.id
            taskProps.name = task.name
            taskProps.description = task.description
            taskProps.prompt = task.prompt
            taskProps.tags = task.tags
            taskProps.enabled = task.enabled
            taskProps.isCustom = task.isCustom
            
            dialogProps.tasks[i] = taskProps
        end
    end

    local taskUIs = {}
    
    -- Create UI for each task
    for i, taskProp in ipairs(dialogProps.tasks) do
        logger:info('Creating task UI for task ' .. i .. ' with name ' .. taskProp.name)
        table.insert(taskUIs, createTaskItemUI(viewFactory, dialogProps, i, taskProp))
    end
    
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        bind_to_object = dialogProps,
        
        -- Section header
        viewFactory:static_text {
            title = "Task Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        -- Instructions
        viewFactory:static_text {
            title = "Select which tasks to enable and customize their prompts. You can edit the prompts for each enabled task.",
            font = '<system/10>',
            fill_horizontal = 1,
        },

        -- Task list
        viewFactory:scrolled_view {
            fill_horizontal = 1,
            height = 550, 
            horizontal_scrolling = false,
            vertical_scrolling = true,
            content = viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                unpackFn(taskUIs),
            },
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
    -- Left column: AI Model Configuration and General Configuration
    local leftColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        createAIModelSection(viewFactory, dialogProps),
        createGeneralSection(viewFactory, dialogProps, supportedFormats, context),
    }
    
    -- Right column: Task Configuration
    local rightColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        createTaskSection(viewFactory, dialogProps, context),
    }
    
    -- Main content with two columns
    local content = viewFactory:column {
        bind_to_object = dialogProps,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        -- Two column layout
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            fill_vertical = 1,
            
            -- Left column (50% width)
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 0.5,
                fill_vertical = 1,
                leftColumn,
            },
            
            -- Right column (50% width)
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 0.5,
                fill_vertical = 1,
                rightColumn,
            },
        },
        
        viewFactory:separator { fill_horizontal = 1 },
        
        -- Bottom buttons row
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
    
    -- Return the layout
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
