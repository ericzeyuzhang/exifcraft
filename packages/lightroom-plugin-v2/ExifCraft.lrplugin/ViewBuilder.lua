--[[----------------------------------------------------------------------------

ViewBuilder.lua
User interface components for ExifCraft

This module contains all UI creation functions for the configuration dialog.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local unpackFn = table.unpack or unpack

-- Import Config module
local ConfigManager = require 'ConfigManager'
local TaskSerializer = require 'TaskSerializer'
local Utils = require 'utils.SystemUtils'
local ViewUtils = require 'utils.ViewUtils'
local UIFormatConstants = require 'constants.ui.UIFormatConstants'
local UIStyleConstants = require 'constants.ui.UIStyleConstants'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ViewBuilder = {}

-- Adapt unified configuration format to UI dialog properties format
function ViewBuilder.buildDialogProps(config)
    return ConfigManager.transformToPropertyTables(config)
end

-- Create AI Model Configuration UI
local function createAIModelSection(viewFactory, dialogProps)
    
    -- Build rows as children arrays and expand via unpackFn to reduce boilerplate
    local providerRowChildren = {
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
    }

    local endpointRowChildren = {
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
    }

    local modelRowChildren = {
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
    }

    local apiKeyRowChildren = {
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
    }

    local tempTokensRowChildren = {
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
    }

    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(
            viewFactory, 
            "AI Model Configuration", 
            "Configure the AI provider, endpoint, and model parameters."),

        viewFactory:group_box {
            title = "",
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
        
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                unpackFn(providerRowChildren),
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                unpackFn(endpointRowChildren),
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                unpackFn(modelRowChildren),
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                unpackFn(apiKeyRowChildren),
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,
                unpackFn(tempTokensRowChildren),
            },
        },
    }
end

-- Create individual task UI component
local function createTaskItemUI(viewFactory, dialogProps, taskIndex, taskProp, context)
    -- Build children arrays for each row to reduce duplication
    local headerRowChildren = {
        viewFactory:checkbox {
            title = "Enable",
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
    }

    local promptRowChildren = {
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
    }

    local tagsRowChildren = {
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
            font = UIStyleConstants.UI_STYLE_CONSTANTS.FieldTitle.font,
            tooltip = "Comma-separated tag names.",
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

    local groupBox = viewFactory:group_box {
        spacing = 2, -- Reduced spacing between elements within task
        fill_horizontal = 1,
        font = UIStyleConstants.UI_STYLE_CONSTANTS.FieldTitle.font,
        tooltip = "Task settings for this task.",
        bind_to_object = taskProp,

        viewFactory:row {
            spacing = 4,
            unpackFn(headerRowChildren),
        },

        -- Prompt editing
        viewFactory:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            unpackFn(promptRowChildren),
        },
        
        -- Tags display (read-only)
        viewFactory:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            unpackFn(tagsRowChildren),
        }
    }
    
    return groupBox

end

-- Create Task Configuration UI
local function createTaskSection(viewFactory, dialogProps, context)
    dialogProps.tasks = ConfigManager.transformToDialogProps(dialogProps.tasks, context)

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

        ViewUtils.createSectionHeader(
            viewFactory, 
            "Task Configuration", 
            "Select which tasks to enable and customize their prompts. You can edit the prompts for each enabled task."),

        viewFactory:column {
            spacing = 4, -- Reduced spacing between tasks
            fill_horizontal = 1,
            unpackFn(taskUIs),
        },
    }
end

-- Create General Configuration UI
local function createGeneralSection(viewFactory, dialogProps)
    -- Initialize format properties only if not already set from loaded config
    for _, formatDefs in pairs(UIFormatConstants.UI_FORMAT_CONSTANTS) do
        for _, formatDef in ipairs(formatDefs) do
            if dialogProps[formatDef.property] == nil then
                dialogProps[formatDef.property] = true
            end
        end
    end
    
    -- Get format properties by group directly from FORMAT_DEFINITIONS
    local standardFormats = {}
    local rawFormats = {}
    local tiffFormats = {}
    
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Standard) do
        table.insert(standardFormats, formatDef.property)
    end
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Raw) do
        table.insert(rawFormats, formatDef.property)
    end
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Tiff) do
        table.insert(tiffFormats, formatDef.property)
    end
    
    -- Build children arrays for Base Prompt and Other Settings
    local basePromptChildren = {
        viewFactory:static_text {
            title = "Base Prompt:",
            font = UIStyleConstants.UI_STYLE_CONSTANTS.L2Title.font,
            width = 80,
        },
        viewFactory:edit_field {
            value = LrView.bind('basePrompt'),
            immediate = true,
            height_in_lines = 5,
            fill_horizontal = 1,
        },
    }

    local otherSettingsChildren = {
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
    }

    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(
            viewFactory, 
            "General Configuration", 
            "Set base prompts, supported formats, and other options."),
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                unpackFn(basePromptChildren),
            },
        },
        
        viewFactory:column {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:static_text {
                title = "Image Formats:",
                font = UIStyleConstants.UI_STYLE_CONSTANTS.L2Title.font,
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
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.L3Title.font,
                        tooltip = "Toggle selection of all standard formats.",
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

                (function()
                    local defs = {
                        { title = "jpg",  bind = 'formatJpg',  tooltip = "Enable processing for JPG files." },
                        { title = "jpeg", bind = 'formatJpeg', tooltip = "Enable processing for JPEG files." },
                        { title = "heic", bind = 'formatHeic', tooltip = "Enable processing for HEIC files." },
                        { title = "heif", bind = 'formatHeif', tooltip = "Enable processing for HEIF files." },
                    }
                    local children = {}
                    for _, def in ipairs(defs) do
                        table.insert(children, viewFactory:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.FieldTitle.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return viewFactory:row {
                        spacing = viewFactory:control_spacing(),
                        fill_horizontal = 1,
                        unpackFn(children),
                    }
                end)(), 

                viewFactory:separator { fill_horizontal = 1 },

                -- Raw format group 
                viewFactory:row {
                    spacing = viewFactory:label_spacing(),
                    fill_horizontal = 1,

                    viewFactory:checkbox {
                        title = "Raw: ",
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.L3Title.font,
                        tooltip = "Toggle selection of all RAW formats.",
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

                (function()
                    local defs = {
                        { title = "dng", bind = 'formatDng', tooltip = "Enable processing for DNG files." },
                        { title = "arw", bind = 'formatArw', tooltip = "Enable processing for ARW files." },
                        { title = "nef", bind = 'formatNef', tooltip = "Enable processing for NEF files." },
                        { title = "cr2", bind = 'formatCr2', tooltip = "Enable processing for CR2 files." },
                        { title = "cr3", bind = 'formatCr3', tooltip = "Enable processing for CR3 files." },
                        { title = "raw", bind = 'formatRaw', tooltip = "Enable processing for RAW files." },
                        { title = "raf", bind = 'formatRaf', tooltip = "Enable processing for RAF files." },
                    }
                    local children = {}
                    for _, def in ipairs(defs) do
                        table.insert(children, viewFactory:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.FieldTitle.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return viewFactory:row {
                        spacing = viewFactory:control_spacing(),
                        fill_horizontal = 1,
                        unpackFn(children),
                    }
                end)(),
            
                viewFactory:separator { fill_horizontal = 1 },

                -- TIFF format group
                viewFactory:row {
                    spacing = viewFactory:label_spacing(),
                    fill_horizontal = 1,

                    viewFactory:checkbox {
                        title = "Tiff: ",
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.L3Title.font,
                        tooltip = "Toggle selection of all TIFF formats.",
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
                (function()
                    local defs = {
                        { title = "tiff", bind = 'formatTiff', tooltip = "Enable processing for TIFF files." },
                        { title = "tif",  bind = 'formatTif',  tooltip = "Enable processing for TIF files." },
                    }
                    local children = {}
                    for _, def in ipairs(defs) do
                        table.insert(children, viewFactory:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.FieldTitle.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return viewFactory:row {
                        spacing = viewFactory:control_spacing(),
                        fill_horizontal = 1,
                        unpackFn(children),
                    }
                end)(),
            },
            
            viewFactory:column {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Others Settings: ",
                    font = UIStyleConstants.UI_STYLE_CONSTANTS.L2Title.font,
                    fill_horizontal = 1,
                },

                viewFactory:row {
                    spacing = viewFactory:label_spacing(),
                    fill_horizontal = 1,
                    unpackFn(otherSettingsChildren),
                },
            },
        },
    }
end

-- Create the main dialog UI
function ViewBuilder.createMainDialog(viewFactory, dialogProps, context)
    -- Left and Right columns built via arrays then expanded
    local leftColumnChildren = {
        createAIModelSection(viewFactory, dialogProps),
        createGeneralSection(viewFactory, dialogProps),
    }

    local leftColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        unpackFn(leftColumnChildren),
    }
    
    local rightColumnChildren = {
        createTaskSection(viewFactory, dialogProps, context),
    }

    local rightColumn = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        unpackFn(rightColumnChildren),
    }
    
    -- Main content with two columns
    local content = viewFactory:column {
        bind_to_object = dialogProps,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        -- Two column layout
        (function()
            local layoutChildren = {
                -- Left column (40% width)
                viewFactory:column {
                    spacing = viewFactory:control_spacing(),
                    fill_horizontal = 0.4,
                    fill_vertical = 1,
                    leftColumn,
                },
                -- Right column (60% width)
                viewFactory:column {
                    spacing = viewFactory:control_spacing(),
                    fill_horizontal = 0.6,
                    fill_vertical = 1,
                    rightColumn,
                },
            }
            return viewFactory:row {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                fill_vertical = 1,
                unpackFn(layoutChildren),
            }
        end)(),
        
        viewFactory:separator { fill_horizontal = 1 },
        
        -- Bottom buttons row (children array + unpackFn)
        (function()
            local buttons = {}

            table.insert(buttons, viewFactory:push_button {
                title = "Reset to Defaults",
                action = function()
                    local confirmChildren = {
                        viewFactory:static_text {
                            title = "This will reset all settings and tasks to defaults.",
                            fill_horizontal = 1,
                        },
                        viewFactory:static_text {
                            title = "Are you sure you want to continue?",
                            fill_horizontal = 1,
                        },
                    }

                    local confirmContents = viewFactory:column {
                        spacing = viewFactory:control_spacing(),
                        fill_horizontal = 1,
                        unpackFn(confirmChildren),
                    }

                    local confirmResult = LrDialogs.presentModalDialog {
                        title = 'Confirm Reset',
                        contents = confirmContents,
                        actionVerb = 'Reset',
                        cancelVerb = 'Cancel',
                        width = 420,
                        height = 120,
                        resizable = false,
                        windowStyle = 'modal',
                    }
                    if confirmResult == 'cancel' then
                        return
                    end
                    local newProps = ConfigManager.resetToDefaults(context)
                    for k, v in pairs(newProps) do
                        dialogProps[k] = v
                    end
                    logger:info('Settings and tasks reset to defaults via ConfigManager.resetToDefaults')
                end,
            })

            table.insert(buttons, viewFactory:push_button {
                title = "Validate & Save Config",
                action = function()
                    -- Build, validate and save configuration in one operation
                    local config = ConfigManager.buildFromDialogProps(dialogProps)
                    ConfigManager.saveToPrefs(config)
                    LrDialogs.showBezel('Configuration saved')
                end,
            })

            table.insert(buttons, viewFactory:push_button {
                title = "Test Connection",
                action = function()
                    logger:info('Testing AI connection...')
                    -- This will be implemented later
                end,
            })

            return viewFactory:row {
                spacing = viewFactory:control_spacing(),
                fill_horizontal = 1,
                unpackFn(buttons),
            }
        end)(),
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
return ViewBuilder
