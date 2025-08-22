--[[----------------------------------------------------------------------------

SectionView.lua
Section builders for ExifCraft

This module provides functions to build each section of the settings dialog.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local unpack_fn = table.unpack or unpack

local ViewUtils = require 'ViewUtils'
local UIFormatConstants = require 'UIFormatConstants'
local UIStyleConstants = require 'UIStyleConstants'
local DialogPropsProvider = require 'DialogPropsProvider'
local SystemUtils = require 'SystemUtils'
local Dkjson = require 'Dkjson'
local ConfigProvider = require 'ConfigProvider'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local SectionView = {}

-- AI Model Configuration
function SectionView.buildAiModelSection(f)
    local providerRowChildren = {
        f:static_text { title = "Provider:", width = 80 },
        f:popup_menu {
            value = LrView.bind('aiProvider'),
            items = {
                { title = "Ollama", value = "ollama" },
                { title = "OpenAI", value = "openai" },
                { title = "Gemini", value = "gemini" },
                { title = "Mock (Testing)", value = "mock" },
            },
            fill_horizontal = 1,
        },
    }

    local endpointRowChildren = {
        f:static_text { title = "Endpoint/API:", width = 80 },
        f:edit_field { value = LrView.bind('aiEndpoint'), immediate = true, fill_horizontal = 1 },
    }

    local modelRowChildren = {
        f:static_text { title = "Model:", width = 80 },
        f:edit_field { value = LrView.bind('aiModel'), immediate = true, fill_horizontal = 1 },
    }

    local apiKeyRowChildren = {
        f:static_text { title = "API Key:", width = 80 },
        f:edit_field { value = LrView.bind('aiApiKey'), immediate = true, fill_horizontal = 1, password = true },
    }

    local tempTokensRowChildren = {
        f:static_text { title = "Temperature:", width = 80 },
        f:edit_field { value = LrView.bind('aiTemperature'), immediate = false, width_in_chars = 8, min = 0.0, max = 1.0, precision = 2, increment = 0.1 },
        f:static_text { title = "Max Tokens:", width = 80 },
        f:edit_field { value = LrView.bind('aiMaxTokens'), immediate = false, width_in_chars = 8, min = 1, max = 10000, increment = 100 },
    }

    return f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(f, "AI Model Configuration", "Configure the AI provider, endpoint, and model parameters."),

        f:group_box {
            title = "",
            spacing = f:control_spacing(),
            fill_horizontal = 1,

            f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(providerRowChildren) },
            f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(endpointRowChildren) },
            f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(modelRowChildren) },
            f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(apiKeyRowChildren) },
            f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(tempTokensRowChildren) },
        },
    }
end


-- Single Task group UI (flattened keys)
local function buildTaskItem(f, taskIndex)
    local taskNameKey = 'task_' .. taskIndex .. '_name'
    local taskPromptKey = 'task_' .. taskIndex .. '_prompt'
    local taskEnabledKey = 'task_' .. taskIndex .. '_enabled'
    local taskTagsKey = 'task_' .. taskIndex .. '_tags'

    local headerRowChildren = {
        f:checkbox { title = "Enable", value = LrView.bind(taskEnabledKey), checked_value = true, unchecked_value = false },
        f:edit_field {
            value = LrView.bind(taskNameKey),
            immediate = false,
            fill_horizontal = 1,
            enabled = LrView.bind(taskEnabledKey),
        },
    }

    local promptRowChildren = {
        f:static_text { title = "Prompt:", width = 60 },
        f:edit_field {
            value = LrView.bind(taskPromptKey),
            immediate = false,
            height_in_lines = 3,
            fill_horizontal = 1,
            enabled = LrView.bind(taskEnabledKey),
        },
    }

    local tagsRowChildren = {
        f:static_text { title = "Tags:", width = 60 },
        f:edit_field {
            value = LrView.bind {
                key = taskTagsKey,
                transform = function(value, fromTable)
                    if fromTable then
                        local success, tags = pcall(function() return Dkjson.decode(value or '[]') end)
                        if success and type(tags) == 'table' then
                            local tag_names = {}
                            for _, tag in ipairs(tags) do
                                if tag.name then table.insert(tag_names, tag.name) end
                            end
                            return table.concat(tag_names, ',')
                        end
                        return ''
                    else
                        local tags = {}
                        for _, tag_name in ipairs(SystemUtils.split(value, ',')) do
                            local trimmed = tag_name:gsub("^%s*(.-)%s*$", "%1")
                            if trimmed ~= '' then table.insert(tags, { name = trimmed, avoidOverwrite = false }) end
                        end
                        local success, jsonString = pcall(function() return Dkjson.encode(tags) end)
                        return success and jsonString or '[]'
                    end
                end,
            },
            immediate = false,
            height_in_lines = 1,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
            tooltip = "Comma-separated tag names.",
            fill_horizontal = 1,
            enabled = LrView.bind(taskEnabledKey),
        },
    }

    return f:group_box {
        spacing = 2,
        fill_horizontal = 1,
        font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
        tooltip = "Task settings for this task.",

        f:row { spacing = 4, unpack_fn(headerRowChildren) },
        f:row { spacing = 4, fill_horizontal = 1, unpack_fn(promptRowChildren) },
        f:row { spacing = 4, fill_horizontal = 1, unpack_fn(tagsRowChildren) },
    }
end

function SectionView.buildTaskSection(f)
    local taskUis = {}
    for i = 1, 5 do
        logger:info('Creating task UI for task ' .. i)
        table.insert(taskUis, buildTaskItem(f, i))
    end

    return f:column {
        spacing = 4,
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(f, "Task Configuration", "Select which tasks to enable and customize their prompts. You can edit the prompts for each enabled task."),

        f:column { spacing = 4, fill_horizontal = 1, unpack_fn(taskUis) },
    }
end


function SectionView.buildGeneralSection(f, dialogProps)
    if dialogProps then
        for _, formatDefs in pairs(UIFormatConstants.UI_FORMAT_CONSTANTS) do
            for _, formatDef in ipairs(formatDefs) do
                if dialogProps[formatDef.property] == nil then dialogProps[formatDef.property] = true end
            end
        end
    end

    local standardFormats, rawFormats, tiffFormats = {}, {}, {}
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Standard) do table.insert(standardFormats, formatDef.property) end
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Raw) do table.insert(rawFormats, formatDef.property) end
    for _, formatDef in ipairs(UIFormatConstants.UI_FORMAT_CONSTANTS.Tiff) do table.insert(tiffFormats, formatDef.property) end

    local basePromptChildren = {
        f:static_text { title = "Base Prompt:", font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font, width = 80 },
        f:edit_field { value = LrView.bind('basePrompt'), immediate = true, height_in_lines = 5, fill_horizontal = 1 },
    }

    local otherSettingsChildren = {
        f:checkbox { title = "Preserve Original Files", value = LrView.bind('preserveOriginal'), checked_value = true, unchecked_value = false },
        f:checkbox { title = "Verbose Logging", value = LrView.bind('verbose'), checked_value = true, unchecked_value = false },
        f:checkbox { title = "Dry Run (Preview Only)", value = LrView.bind('dryRun'), checked_value = true, unchecked_value = false },
    }

    return f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,

        ViewUtils.createSectionHeader(f, "General Configuration", "Set base prompts, supported formats, and other options."),

        f:row {
            spacing = f:label_spacing(),
            fill_horizontal = 1,
            f:column { spacing = f:control_spacing(), fill_horizontal = 1, unpack_fn(basePromptChildren) },
        },

        f:column {
            spacing = f:label_spacing(),
            fill_horizontal = 1,
            f:static_text { title = "Image Formats:", font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font, fill_horizontal = 1 },

            f:group_box {
                spacing = f:control_spacing(),
                fill_horizontal = 1,

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
                                    local allSelected, anySelected = true, false
                                    for _, prop in ipairs(standardFormats) do
                                        if values[prop] then anySelected = true else allSelected = false end
                                    end
                                    if allSelected then return true elseif anySelected then return nil else return false end
                                else
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                            transform = function(value, fromTable)
                                if fromTable then return value else
                                    if dialogProps then for _, prop in ipairs(standardFormats) do dialogProps[prop] = value end end
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                        },
                        checked_value = false,
                        unchecked_value = false,
                    },
                },

                ViewUtils.createFormatCheckboxRow(f, {
                    { title = "jpg",  bind = 'formatJpg',  tooltip = "Enable processing for JPG files." },
                    { title = "jpeg", bind = 'formatJpeg', tooltip = "Enable processing for JPEG files." },
                    { title = "heic", bind = 'formatHeic', tooltip = "Enable processing for HEIC files." },
                    { title = "heif", bind = 'formatHeif', tooltip = "Enable processing for HEIF files." },
                }),

                f:separator { fill_horizontal = 1 },

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
                                    local allSelected, anySelected = true, false
                                    for _, prop in ipairs(rawFormats) do
                                        if values[prop] then anySelected = true else allSelected = false end
                                    end
                                    if allSelected then return true elseif anySelected then return nil else return false end
                                else
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                            transform = function(value, fromTable)
                                if fromTable then return value else
                                    if dialogProps then for _, prop in ipairs(rawFormats) do dialogProps[prop] = value end end
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                        },
                        checked_value = false,
                        unchecked_value = false,
                    },
                },

                ViewUtils.createFormatCheckboxRow(f, {
                    { title = "dng", bind = 'formatDng', tooltip = "Enable processing for DNG files." },
                    { title = "arw", bind = 'formatArw', tooltip = "Enable processing for ARW files." },
                    { title = "nef", bind = 'formatNef', tooltip = "Enable processing for NEF files." },
                    { title = "cr2", bind = 'formatCr2', tooltip = "Enable processing for CR2 files." },
                    { title = "cr3", bind = 'formatCr3', tooltip = "Enable processing for CR3 files." },
                    { title = "raw", bind = 'formatRaw', tooltip = "Enable processing for RAW files." },
                    { title = "raf", bind = 'formatRaf', tooltip = "Enable processing for RAF files." },
                }),

                f:separator { fill_horizontal = 1 },

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
                                    local allSelected, anySelected = true, false
                                    for _, prop in ipairs(tiffFormats) do
                                        if values[prop] then anySelected = true else allSelected = false end
                                    end
                                    if allSelected then return true elseif anySelected then return nil else return false end
                                else
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                            transform = function(value, fromTable)
                                if fromTable then return value else
                                    if dialogProps then for _, prop in ipairs(tiffFormats) do dialogProps[prop] = value end end
                                    return LrBinding.kUnsupportedDirection
                                end
                            end,
                        },
                        checked_value = false,
                        unchecked_value = false,
                    },
                },

                ViewUtils.createFormatCheckboxRow(f, {
                    { title = "tiff", bind = 'formatTiff', tooltip = "Enable processing for TIFF files." },
                    { title = "tif",  bind = 'formatTif',  tooltip = "Enable processing for TIF files." },
                }),
            },

            f:column {
                spacing = f:control_spacing(),
                fill_horizontal = 1,
                f:static_text { title = "Others Settings: ", font = UIStyleConstants.UI_STYLE_CONSTANTS.l2_title.font, fill_horizontal = 1 },
                f:row { spacing = f:label_spacing(), fill_horizontal = 1, unpack_fn(otherSettingsChildren) },
            },
        },
    }
end


function SectionView.buildBottomActions(f, dialogProps)
    local buttons = {}

    table.insert(buttons, f:push_button {
        title = "Reset to Defaults",
        action = function()
            local confirmChildren = {
                f:static_text { title = "This will reset all settings and tasks to defaults.", fill_horizontal = 1 },
                f:static_text { title = "Are you sure you want to continue?", fill_horizontal = 1 },
            }

            local confirmContents = f:column { spacing = f:control_spacing(), fill_horizontal = 1, unpack_fn(confirmChildren) }

            logger:info('SectionView: Presenting modal dialog for reset to defaults')
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
            if confirmResult == 'cancel' then return end
            local config, _ = ConfigProvider.fromDefaultJsonFile()
            DialogPropsProvider.fromConfig(config, dialogProps)
        end,
    })

    table.insert(buttons, f:push_button {
        title = "Validate & Save Config",
        action = function()
            logger:info('ViewBuilder: Saving configuration...')
            DialogPropsProvider.persistToPrefs(dialogProps)
            logger:info('ViewBuilder: Configuration saved')
            LrDialogs.showBezel('Configuration saved')
        end,
    })

    table.insert(buttons, f:push_button {
        title = "Test Connection",
        action = function()
            logger:info('ViewBuilder: Testing AI connection...')
            -- Placeholder for future implementation
        end,
    })

    return f:row { spacing = f:control_spacing(), fill_horizontal = 1, unpack_fn(buttons) }
end


return SectionView


