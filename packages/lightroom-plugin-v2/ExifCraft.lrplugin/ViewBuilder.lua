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
local Utils = require 'Utils'

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
            font = Config.LAYOUT_SETTINGS.L1Title.font,
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
                    immediate = false,
                    width_in_chars = 8,
                    min = 0.0,
                    max = 1.0,
                    precision = 2,
                    increment = 0.1,
                },
                
                viewFactory:static_text {
                    title = "Max Tokens:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('aiMaxTokens'),
                    immediate = false,
                    width_in_chars = 8,
                    min = 1,
                    max = 10000,
                    increment = 100,
                },
            },
        },
    }
end

-- Create individual task UI component
local function createTaskItemUI(viewFactory, dialogProps, taskIndex, taskProp, context)

    local groupBox = viewFactory:group_box {
        spacing = 2, -- Reduced spacing between elements within task
        fill_horizontal = 1,
        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
        bind_to_object = taskProp,

        viewFactory:row {
            spacing = 4,
            viewFactory:checkbox {
                title = "Enabled",
                value = LrView.bind {
                    key = 'enabled',
                    transform = function(value, fromTable)
                        if fromTable then
                            logger:info('Task ' .. taskProp.name .. ' checkbox enabled state: ' .. tostring(value))
                            return value
                        else
                            logger:info('Task ' .. taskProp.name .. ' checkbox changed to: ' .. tostring(value))
                            return value
                        end
                    end,
                },
                checked_value = true,
                unchecked_value = false,
            },

            viewFactory:edit_field {
                value = LrView.bind('name'),
                immediate = false,
                fill_horizontal = 1,
                enabled = LrView.bind('enabled'), -- Enable/disable based on checkbox
                validate = function(value)
                    if value == '' then
                        return false, 'Enter task name...', 'Name is required'
                    end
                    return true, value, nil
                end,
            },
        },

        -- Prompt editing
        viewFactory:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            
            viewFactory:static_text {
                title = "Prompt:",
                width = 60, -- Reduced width
            },
            
            viewFactory:edit_field {
                value = LrView.bind('prompt'),
                immediate = false,
                height_in_lines = 3,
                fill_horizontal = 1,
                enabled = LrView.bind('enabled'), -- Enable/disable based on checkbox
                validate = function(value)
                    if value == '' then
                        return false, 'Enter task prompt...', 'Prompt is required'
                    end
                    return true, value, nil
                end,
            },
        },
        
        -- Tags display (read-only)
        viewFactory:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            
            viewFactory:static_text {
                title = "Tags:",
                width = 60, -- Reduced width
            },
            
            viewFactory:edit_field {
                value = LrView.bind {
                    key = 'tags',
                    transform = function(value, fromTable)
                        if fromTable then
                            -- concat tags into a string
                            local tagNames = {}
                            for _, tag in ipairs(value) do
                                table.insert(tagNames, tag.name)
                            end
                            return table.concat(tagNames, ',')
                        else
                            -- separate tags by commas
                            local tags = {}
                            for _, tag in ipairs(Utils.split(value, ',')) do
                                table.insert(tags, 
                                { name = tag, allowOverwrite = true })
                            end
                            taskProp.tags = tags
                            return value
                        end
                    end,
                },
                immediate = false,
                height_in_lines = 1,
                font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                fill_horizontal = 1,
                enabled = LrView.bind('enabled'), -- Enable/disable based on checkbox
                validate = function(value)
                    if value == '' then
                        return false, 'Enter task tags...', 'Tags are required'
                    end
                    return true, value, nil
                end,
            },
        }
    }
    
    return groupBox

end

-- Create Task Configuration UI
local function createTaskSection(viewFactory, dialogProps, context)
    -- Normalize tasks into property tables to ensure bindings work
    local sourceTasks = dialogProps.tasks or Config.PRESET_TASK_TEMPLATES
    local normalizedTasks = {}
    for i, task in ipairs(sourceTasks) do
        local taskProps = LrBinding.makePropertyTable(context)
        taskProps.id = (task and task.id) or tostring(i)
        taskProps.name = task and task.name or ''
        taskProps.prompt = task and task.prompt or ''
        taskProps.tags = task and task.tags or {}
        taskProps.enabled = task and task.enabled or false
        taskProps.isCustom = task and task.isCustom or false
        normalizedTasks[i] = taskProps
    end
    dialogProps.tasks = normalizedTasks

    local taskUIs = {}
    
    -- Create UI for each task
    for i, taskProp in ipairs(dialogProps.tasks) do
        logger:info('Creating task UI for task ' .. i .. ' with name ' .. taskProp.name)
        table.insert(taskUIs, createTaskItemUI(viewFactory, dialogProps, i, taskProp, context))
    end
    
    return viewFactory:column {
        spacing = 4, -- Reduced spacing between tasks
        fill_horizontal = 1,
        bind_to_object = dialogProps,
        
        -- Section header
        viewFactory:static_text {
            title = "Task Configuration",
            font = Config.LAYOUT_SETTINGS.L1Title.font,
            fill_horizontal = 1,
        },
        
        -- Instructions
        viewFactory:static_text {
            title = "Select which tasks to enable and customize their prompts. You can edit the prompts for each enabled task.",
            font = Config.LAYOUT_SETTINGS.SubTitle.font,
            fill_horizontal = 1,
        },

        viewFactory:column {
            spacing = 4, -- Reduced spacing between tasks
            fill_horizontal = 1,
            unpackFn(taskUIs),
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
            font = Config.LAYOUT_SETTINGS.L1Title.font,
            fill_horizontal = 1,
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Base Prompt:",
                    font = Config.LAYOUT_SETTINGS.L2Title.font,
                    width = 80,
                },

                viewFactory:edit_field {
                    value = LrView.bind('basePrompt'),
                    immediate = true,
                    -- width_in_chars = 50,
                    height_in_lines = 5,
                    fill_horizontal = 1,
                },
            },
        },
        
        viewFactory:column {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:static_text {
                title = "Image Formats:",
                font = Config.LAYOUT_SETTINGS.L2Title.font,
                fill_horizontal = 1,
            },

            viewFactory:group_box {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                -- Standard formats group
                viewFactory:row {
                    spacing = viewFactory:control_spacing(),
                    fill_horizontal = 1,

                    viewFactory:checkbox {
                        title = "Standard: ",
                        font = Config.LAYOUT_SETTINGS.L3Title.font,
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
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatJpg'),
                        checked_value = true,
                        unchecked_value = false,
                    },
                    
                    viewFactory:checkbox {
                        title = "jpeg",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatJpeg'),
                        checked_value = true,
                        unchecked_value = false,
                    },
                    
                    viewFactory:checkbox {
                        title = "heic",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatHeic'),
                        checked_value = true,
                        unchecked_value = false,
                    },
                    
                    viewFactory:checkbox {
                        title = "heif",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
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
                        font = Config.LAYOUT_SETTINGS.L3Title.font,
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
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatDng'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "arw",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatArw'),
                        checked_value = true,
                        unchecked_value = false,
                    },
                    
                    viewFactory:checkbox {
                        title = "nef",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatNef'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "cr2",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatCr2'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "cr3",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatCr3'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "raw",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatRaw'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "raf",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
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
                        font = Config.LAYOUT_SETTINGS.L3Title.font,
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
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatTiff'),
                        checked_value = true,
                        unchecked_value = false,
                    },

                    viewFactory:checkbox {
                        title = "tif",
                        font = Config.LAYOUT_SETTINGS.FieldTitle.font,
                        value = LrView.bind('formatTif'),
                        checked_value = true,
                        unchecked_value = false,
                    },
                },
            },
            
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Others Settings: ",
                    font = Config.LAYOUT_SETTINGS.L2Title.font,
                    fill_horizontal = 1,
                },

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
                    -- Reset to default settings (except tasks)
                    for key, defaultValue in pairs(Config.DEFAULT_SETTINGS) do
                        if key ~= 'tasks' then
                            dialogProps[key] = defaultValue
                        end
                    end

                    -- Rebuild tasks as property tables to keep bindings alive
                    local rebuiltTasks = {}
                    for i, task in ipairs(Config.PRESET_TASK_TEMPLATES) do
                        local taskProps = LrBinding.makePropertyTable(context)
                        taskProps.id = task.id or tostring(i)
                        taskProps.name = task.name
                        taskProps.prompt = task.prompt
                        taskProps.tags = task.tags
                        taskProps.enabled = task.enabled
                        taskProps.isCustom = task.isCustom
                        rebuiltTasks[i] = taskProps
                    end
                    dialogProps.tasks = rebuiltTasks

                    logger:info('Settings and tasks reset to defaults (bindings rebuilt)')
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

-- Example function showing how to create a resizable dialog with equal-width columns
local function createResizableTwoColumnDialog(viewFactory, dialogProps, context)
    -- Left column content
    local leftColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        viewFactory:static_text {
            title = "Left Column",
            fill_horizontal = 1,
        },
        
        viewFactory:edit_field {
            value = LrView.bind('leftColumnText'),
            immediate = true,
            height_in_lines = 10,
            fill_horizontal = 1,
        },
    }
    
    -- Right column content
    local rightColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        viewFactory:static_text {
            title = "Right Column",
            fill_horizontal = 1,
        },
        
        viewFactory:edit_field {
            value = LrView.bind('rightColumnText'),
            immediate = true,
            height_in_lines = 10,
            fill_horizontal = 1,
        },
    }
    
    -- Main content with resizable two-column layout
    local content = viewFactory:column {
        bind_to_object = dialogProps,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        -- Resizable two column layout
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            fill_vertical = 1,
            
            -- Left column (always 50% width)
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 0.5,  -- This ensures equal width distribution
                fill_vertical = 1,
                leftColumn,
            },
            
            -- Right column (always 50% width)
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 0.5,  -- This ensures equal width distribution
                fill_vertical = 1,
                rightColumn,
            },
        },
        
        -- Bottom buttons
        viewFactory:row {
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            
            viewFactory:push_button {
                title = "OK",
                action = function()
                    -- Handle OK action
                end,
            },
            
            viewFactory:push_button {
                title = "Cancel",
                action = function()
                    -- Handle Cancel action
                end,
            },
        },
    }
    
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
    createResizableTwoColumnDialog = createResizableTwoColumnDialog,
}
