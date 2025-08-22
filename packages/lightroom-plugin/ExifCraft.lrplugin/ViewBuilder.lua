--[[----------------------------------------------------------------------------

ViewBuilder.lua
User interface components for ExifCraft

This module contains all UI creation functions for the configuration dialog.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'
local unpack_fn = table.unpack or unpack

-- Import Config modules
local DialogPropsTransformer = require 'DialogPropsTransformer'
local SystemUtils = require 'SystemUtils'
local ViewUtils = require 'ViewUtils'
local UIFormatConstants = require 'UIFormatConstants'
local UIStyleConstants = require 'UIStyleConstants'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ViewBuilder = {}

-- Create AI Model Configuration UI
local function createAIModelSection(f, dialogProps)
    
    -- Build rows as children arrays and expand via unpack_fn to reduce boilerplate
    local providerRowChildren = {
        f:static_text {
            title = "Provider:",
            width = 80,
        },
        f:popup_menu {
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
        f:static_text {
            title = "Endpoint/API:",
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('aiEndpoint'),
            immediate = true,
            -- width_in_chars = 35,
            fill_horizontal = 1,
        },
    }

    local modelRowChildren = {
        f:static_text {
            title = "Model:",
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('aiModel'),
            immediate = true,
            -- width_in_chars = 25,
            fill_horizontal = 1,
        },
    }

    local apiKeyRowChildren = {
        f:static_text {
            title = "API Key:",
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('aiApiKey'),
            immediate = true,
            -- width_in_chars = 30,
            fill_horizontal = 1,
            password = true,
        },
    }

    local tempTokensRowChildren = {
        f:static_text {
            title = "Temperature:",
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('aiTemperature'),
            immediate = false,
            width_in_chars = 8,
            min = 0.0,
            max = 1.0,
            precision = 2,
            increment = 0.1,
        },
        f:static_text {
            title = "Max Tokens:",
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('aiMaxTokens'),
            immediate = false,
            width_in_chars = 8,
            min = 1,
            max = 10000,
            increment = 100,
        },
    }

    return f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(
            f, 
            "AI Model Configuration", 
            "Configure the AI provider, endpoint, and model parameters."),

        f:group_box {
            title = "",
            spacing = f:control_spacing(),
            fill_horizontal = 1,
        
            f:row {
                spacing = f:label_spacing(),
                fill_horizontal = 1,
                unpack_fn(providerRowChildren),
            },
            
            f:row {
                spacing = f:label_spacing(),
                fill_horizontal = 1,
                unpack_fn(endpointRowChildren),
            },
            
            f:row {
                spacing = f:label_spacing(),
                fill_horizontal = 1,
                unpack_fn(modelRowChildren),
            },
            
            f:row {
                spacing = f:label_spacing(),
                fill_horizontal = 1,
                unpack_fn(apiKeyRowChildren),
            },
            
            f:row {
                spacing = f:label_spacing(),
                fill_horizontal = 1,
                unpack_fn(tempTokensRowChildren),
            },
        },
    }
end

-- Create individual task UI component
local function createTaskItemUI(f, dialogProps, taskIndex, taskProp, context)
    -- Build children arrays for each row to reduce duplication
    local headerRowChildren = {
        f:checkbox {
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

        f:edit_field {
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
        f:static_text {
            title = "Prompt:",
            width = 60, -- Reduced width
        },
        f:edit_field {
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
        f:static_text {
            title = "Tags:",
            width = 60, -- Reduced width
        },
        f:edit_field {
            value = LrView.bind {
                key = 'tags',
                transform = function(value, fromTable)
                    if fromTable then
                        -- concat tags into a string
                        local tag_names = {}
                        for _, tag in ipairs(value) do
                            table.insert(tag_names, tag.name)
                        end
                        return table.concat(tag_names, ',')
                    else
                        -- separate tags by commas
                        local tags = {}
                        for _, tag in ipairs(SystemUtils.split(value, ',')) do
                            table.insert(tags, 
                            { name = tag, avoidOverwrite = false })
                        end
                        taskProp.tags = tags
                        return value
                    end
                end,
            },
            immediate = false,
            height_in_lines = 1,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
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

    local groupBox = f:group_box {
        spacing = 2, -- Reduced spacing between elements within task
        fill_horizontal = 1,
        font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
        tooltip = "Task settings for this task.",
        bind_to_object = taskProp,

        f:row {
            spacing = 4,
            unpack_fn(headerRowChildren),
        },

        -- Prompt editing
        f:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            unpack_fn(promptRowChildren),
        },
        
        -- Tags display (read-only)
        f:row {
            spacing = 4, -- Reduced spacing between label and input
            fill_horizontal = 1,
            unpack_fn(tagsRowChildren),
        }
    }
    
    return groupBox

end

-- Create Task Configuration UI
local function createTaskSection(f, dialogProps, context)
    local taskUis = {}
    dialogProps.tasks = dialogProps.tasks or {}
    
    -- Create UI for each task
    for i, taskProp in ipairs(dialogProps.tasks) do
        logger:info('Creating task UI for task ' .. i .. ' with name ' .. taskProp.name)
        table.insert(taskUis, createTaskItemUI(f, dialogProps, i, taskProp, context))
    end
    
    return f:column {
        spacing = 4, -- Reduced spacing between tasks
        fill_horizontal = 1,
        bind_to_object = dialogProps,

        ViewUtils.createSectionHeader(
            f, 
            "Task Configuration", 
            "Select which tasks to enable and customize their prompts. You can edit the prompts for each enabled task."),

        f:column {
            spacing = 4, -- Reduced spacing between tasks
            fill_horizontal = 1,
            unpack_fn(taskUis),
        },
    }
end

-- Create General Configuration UI
local function createGeneralSection(f, dialogProps)
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
        f:static_text {
            title = "Base Prompt:",
            font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font,
            width = 80,
        },
        f:edit_field {
            value = LrView.bind('basePrompt'),
            immediate = true,
            height_in_lines = 5,
            fill_horizontal = 1,
        },
    }

    local otherSettingsChildren = {
        f:checkbox {
            title = "Preserve Original Files",
            value = LrView.bind('preserveOriginal'),
            checked_value = true,
            unchecked_value = false,
        },
        f:checkbox {
            title = "Verbose Logging",
            value = LrView.bind('verbose'),
            checked_value = true,
            unchecked_value = false,
        },
        f:checkbox {
            title = "Dry Run (Preview Only)",
            value = LrView.bind('dryRun'),
            checked_value = true,
            unchecked_value = false,
        },
    }

    return f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(
            f, 
            "General Configuration", 
            "Set base prompts, supported formats, and other options."),
        
        f:row {
            spacing = f:label_spacing(),
            fill_horizontal = 1,

            f:column {
                spacing = f:control_spacing(),
                fill_horizontal = 1,
                unpack_fn(basePromptChildren),
            },
        },
        
        f:column {
            spacing = f:label_spacing(),
            fill_horizontal = 1,

            f:static_text {
                title = "Image Formats:",
                font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font,
                fill_horizontal = 1,
            },

            f:group_box {
                spacing = f:control_spacing(),
                fill_horizontal = 1,
                -- Standard formats group
                f:row {
                    spacing = f:control_spacing(),
                    fill_horizontal = 1,

                    f:checkbox {
                        title = "Standard: ",
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.l3_title.font,
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
                        table.insert(children, f:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return f:row {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        unpack_fn(children),
                    }
                end)(), 

                f:separator { fill_horizontal = 1 },

                -- Raw format group 
                f:row {
                    spacing = f:label_spacing(),
                    fill_horizontal = 1,

                    f:checkbox {
                        title = "Raw: ",
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.l3_title.font,
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
                        table.insert(children, f:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return f:row {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        unpack_fn(children),
                    }
                end)(),
            
                f:separator { fill_horizontal = 1 },

                -- TIFF format group
                f:row {
                    spacing = f:label_spacing(),
                    fill_horizontal = 1,

                    f:checkbox {
                        title = "Tiff: ",
                        font = UIStyleConstants.UI_STYLE_CONSTANTS.l3_title.font,
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
                        table.insert(children, f:checkbox {
                            title = def.title,
                            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
                            tooltip = def.tooltip,
                            value = LrView.bind(def.bind),
                            checked_value = true,
                            unchecked_value = false,
                        })
                    end
                    return f:row {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        unpack_fn(children),
                    }
                end)(),
            },
            
            f:column {
                spacing = f:control_spacing(),
                fill_horizontal = 1,

                f:static_text {
                    title = "Others Settings: ",
                    font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font,
                    fill_horizontal = 1,
                },

                f:row {
                    spacing = f:label_spacing(),
                    fill_horizontal = 1,
                    unpack_fn(otherSettingsChildren),
                },
            },
        },
    }
end

-- Create the main dialog UI
function ViewBuilder.createMainDialog(f, dialogProps, context)
    -- Left and Right columns built via arrays then expanded
    local leftColumnChildren = {
        createAIModelSection(f, dialogProps),
        createGeneralSection(f, dialogProps),
    }

    local leftColumn = f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        unpack_fn(leftColumnChildren),
    }
    
    local rightColumnChildren = {
        createTaskSection(f, dialogProps, context),
    }

    local rightColumn = f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        unpack_fn(rightColumnChildren),
    }
    
    -- Main content with two columns
    local content = f:column {
        bind_to_object = dialogProps,
        spacing = f:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        -- Two column layout
        (function()
            local layoutChildren = {
                -- Left column (40% width)
                f:column {
                    spacing = f:control_spacing(),
                    fill_horizontal = 0.4,
                    fill_vertical = 1,
                    leftColumn,
                },
                -- Right column (60% width)
                f:column {
                    spacing = f:control_spacing(),
                    fill_horizontal = 0.6,
                    fill_vertical = 1,
                    rightColumn,
                },
            }
            return f:row {
                spacing = f:control_spacing(),
                fill_horizontal = 1,
                fill_vertical = 1,
                unpack_fn(layoutChildren),
            }
        end)(),
        
        f:separator { fill_horizontal = 1 },
        
        -- Bottom buttons row (children array + unpack_fn)
        (function()
            local buttons = {}

            table.insert(buttons, f:push_button {
                title = "Reset to Defaults",
                action = function()
                    local confirmChildren = {
                        f:static_text {
                            title = "This will reset all settings and tasks to defaults.",
                            fill_horizontal = 1,
                        },
                        f:static_text {
                            title = "Are you sure you want to continue?",
                            fill_horizontal = 1,
                        },
                    }

                    local confirmContents = f:column {
                        spacing = f:control_spacing(),
                        fill_horizontal = 1,
                        unpack_fn(confirmChildren),
                    }

                    local confirmResult = LrDialogs.presentModalDialog {
                        title = 'Confirm Reset',
                        contents = confirmContents,
                        actionVerb = 'Reset',
                        cancelVerb = 'Cancel',
                        width = 420,
                        height = 120,
                        resizable = false,
                        window_style = 'modal',
                    }
                    if confirmResult == 'cancel' then
                        return
                    end
                    
                    -- Reset to defaults and update dialog props
                    local newDialogProps = DialogPropsTransformer.resetToDefaults(context)
                    
                    -- Update existing dialog props with reset values
                    for key, value in pairs(newDialogProps) do
                        dialogProps[key] = value
                    end
                    
                    logger:info('Settings and tasks reset to defaults via DialogPropsTransformer.resetToDefaults')
                end,
            })

            table.insert(buttons, f:push_button {
                title = "Validate & Save Config",
                action = function()
                    logger:info('ViewBuilder: Saving configuration...')
                    DialogPropsTransformer.persistToPrefs(dialogProps)
                    logger:info('ViewBuilder: Configuration saved')
                    LrDialogs.showBezel('Configuration saved')
                end,
            })

            table.insert(buttons, f:push_button {
                title = "Test Connection",
                action = function()
                    logger:info('ViewBuilder: Testing AI connection...')
                    -- This will be implemented later
                end,
            })

            return f:row {
                spacing = f:control_spacing(),
                fill_horizontal = 1,
                unpack_fn(buttons),
            }
        end)(),
    }
    
    -- Return the layout
    return f:column {
        fill = 1,
        fill_horizontal = 1,
        fill_vertical = 1,
        content,
    }
end

-- Export module
return ViewBuilder
