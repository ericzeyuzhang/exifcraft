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
local function createAIModelSection(viewFactory, bind)
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header with prominent styling
        viewFactory:static_text {
            title = "AI Model Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        viewFactory:separator { fill_horizontal = 1 },
        
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

-- Create Task Configuration UI
local function createTaskSection(viewFactory, bind, context)
    -- Create a version counter to force UI refresh when tasks change
    if not bind.taskVersion then
        bind.taskVersion = 0
    end
    
    -- Function to refresh the task UI
    local function refreshTaskUI()
        bind.taskVersion = bind.taskVersion + 1
    end
    
    -- Function to create a single task UI
    local function createTaskUI(taskIndex, taskData)
        -- Create individual property table for this task
        local taskProps = LrBinding.makePropertyTable(context)
        taskProps.enabled = taskData.enabled or 'true'
        taskProps.name = taskData.name or 'New Task'
        taskProps.prompt = taskData.prompt or 'Describe what you want to generate for this image.'
        taskProps.tags = taskData.tags or {}
        
        -- Initialize tag input field for this task
        if not bind['tagInput' .. taskIndex] then
            bind['tagInput' .. taskIndex] = ''
        end
        if not bind['tagRemoveInput' .. taskIndex] then
            bind['tagRemoveInput' .. taskIndex] = ''
        end
        
        local taskContent = viewFactory:column {
            bind_to_object = taskProps,
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Status:",
                    width = 80,
                },
                
                viewFactory:popup_menu {
                    value = LrView.bind('enabled'),
                    items = {
                        { title = "Enabled", value = "true" },
                        { title = "Disabled", value = "false" },
                    },
                    -- width_in_chars = 15,
                    fill_horizontal = 1,
                },
                
                viewFactory:push_button {
                    title = "Remove",
                    action = function()
                        -- Remove this task from the list and refresh UI
                        table.remove(bind.taskList, taskIndex)
                        logger:info('Task ' .. taskIndex .. ' removed')
                        refreshTaskUI()
                    end,
                    width = 80,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Name:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('name'),
                    immediate = true,
                    -- width_in_chars = 20,
                    fill_horizontal = 1,
                },
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Prompt:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('prompt'),
                    immediate = true,
                    -- width_in_chars = 40,
                    height_in_lines = 2,
                    fill_horizontal = 1,
                },
            },
            
            -- Tags section with add/remove functionality
            viewFactory:static_text {
                title = "Tags:",
                font = '<system/bold>',
            },
            
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:edit_field {
                    value = LrView.bind('tagInput' .. taskIndex),
                    immediate = true,
                    -- width_in_chars = 30,
                    fill_horizontal = 1,
                },
                
                viewFactory:push_button {
                    title = "Add",
                    action = function()
                        local tagName = bind['tagInput' .. taskIndex]:match('^%s*(.-)%s*$') -- trim
                        if tagName and tagName ~= '' then
                            table.insert(taskProps.tags, tagName)
                            bind['tagInput' .. taskIndex] = ''
                            logger:info('Tag added: ' .. tagName)
                        end
                    end,
                    width = 60,
                },
            },
            
            -- Display current tags
            viewFactory:static_text {
                title = function()
                    local tags = taskProps.tags
                    if #tags == 0 then
                        return "No tags added"
                    else
                        return "Current tags: " .. table.concat(tags, ", ")
                    end
                end,
                font = '<system/small>',
            },
            
            -- Remove tag button
            viewFactory:row {
                spacing = viewFactory:label_spacing(),
                fill_horizontal = 1,

                viewFactory:static_text {
                    title = "Remove tag:",
                    width = 80,
                },
                
                viewFactory:edit_field {
                    value = LrView.bind('tagRemoveInput' .. taskIndex),
                    immediate = true,
                    -- width_in_chars = 20,
                    fill_horizontal = 1,
                },
                
                viewFactory:push_button {
                    title = "Remove",
                    action = function()
                        local tagToRemove = bind['tagRemoveInput' .. taskIndex]:match('^%s*(.-)%s*$') -- trim
                        if tagToRemove and tagToRemove ~= '' then
                            for i, tag in ipairs(taskProps.tags) do
                                if tag == tagToRemove then
                                    table.remove(taskProps.tags, i)
                                    bind['tagRemoveInput' .. taskIndex] = ''
                                    logger:info('Tag removed: ' .. tagToRemove)
                                    break
                                end
                            end
                        end
                    end,
                    width = 80,
                },
            },
        }
        
        return viewFactory:group_box {
            title = "Task " .. taskIndex,
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            taskContent,
        }
    end
    
    -- Create task list container that refreshes when taskVersion changes
    local taskContainer = viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- This will be re-evaluated when taskVersion changes
        function()
            local taskChildren = {}
            
            -- Add existing tasks
            for i, taskData in ipairs(bind.taskList or {}) do
                table.insert(taskChildren, createTaskUI(i, taskData))
            end
            
            -- Add button to create new task
            local addTaskButton = viewFactory:push_button {
                title = "+ Add New Task",
                action = function()
                    -- Add a new task to the list and refresh UI
                    table.insert(bind.taskList, {
                        enabled = 'true',
                        name = 'New Task',
                        prompt = 'Describe what you want to generate for this image.',
                        tags = {}
                    })
                    logger:info('New task added')
                    refreshTaskUI()
                end,
                fill_horizontal = 1,
            }
            
            table.insert(taskChildren, addTaskButton)
            return unpackFn(taskChildren)
        end,
    }
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header with prominent styling
        viewFactory:static_text {
            title = "Task Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        viewFactory:separator { fill_horizontal = 1 },
        
        viewFactory:group_box {
            title = "",
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
            taskContainer,
        },
    }
end

-- Create General Configuration UI
local function createGeneralSection(viewFactory, bind, supportedFormats)
    return viewFactory:column {
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        
        -- Section header with prominent styling
        viewFactory:static_text {
            title = "General Configuration",
            font = '<system/bold/14>',
            fill_horizontal = 1,
        },
        
        viewFactory:separator { fill_horizontal = 1 },
        
        viewFactory:group_box {
            title = "",
            spacing = viewFactory:control_spacing(),
            fill_horizontal = 1,
        
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
            font = '<system/bold>',
        },
        
        -- Standard Formats Group
        viewFactory:static_text {
            title = "Standard Formats:",
            font = '<system/bold/12>',
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "JPG",
                value = LrView.bind('formatJpg'),
            },
            
            viewFactory:checkbox {
                title = "JPEG", 
                value = LrView.bind('formatJpeg'),
            },
            
            viewFactory:checkbox {
                title = "HEIC",
                value = LrView.bind('formatHeic'),
            },
            
            viewFactory:checkbox {
                title = "HEIF",
                value = LrView.bind('formatHeif'),
            },
        },
        
        -- RAW Formats Group
        viewFactory:static_text {
            title = "RAW Formats:",
            font = '<system/bold/12>',
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "NEF (Nikon)",
                value = LrView.bind('formatNef'),
            },
            
            viewFactory:checkbox {
                title = "RAF (Fujifilm)",
                value = LrView.bind('formatRaf'),
            },
            
            viewFactory:checkbox {
                title = "CR2 (Canon)",
                value = LrView.bind('formatCr2'),
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "ARW (Sony)",
                value = LrView.bind('formatArw'),
            },
            
            viewFactory:checkbox {
                title = "DNG (Adobe)",
                value = LrView.bind('formatDng'),
            },
            
            viewFactory:checkbox {
                title = "RAW (Generic)",
                value = LrView.bind('formatRawExt'),
            },
        },
        
        -- TIFF Formats Group
        viewFactory:static_text {
            title = "TIFF Formats:",
            font = '<system/bold/12>',
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "TIFF",
                value = LrView.bind('formatTiff'),
            },
            
            viewFactory:checkbox {
                title = "TIF",
                value = LrView.bind('formatTif'),
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            fill_horizontal = 1,

            viewFactory:checkbox {
                title = "Preserve Original Files",
                value = LrView.bind('preserveOriginal'),
            },
            
            viewFactory:checkbox {
                title = "Verbose Logging",
                value = LrView.bind('verbose'),
            },
            
            viewFactory:checkbox {
                title = "Dry Run (Preview Only)",
                value = LrView.bind('dryRun'),
            },
        },
        },
    }
end

-- Create the main dialog UI
local function createMainDialog(viewFactory, bind, supportedFormats, context)
    local content = viewFactory:column {
        bind_to_object = bind,
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        
        createAIModelSection(viewFactory, bind),
        createTaskSection(viewFactory, bind, context),
        createGeneralSection(viewFactory, bind, supportedFormats),
        
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
                        bind[key] = defaultValue
                    end
                    bind.taskList = Config.getDefaultTaskList()
                    
                    -- Ensure format selections are properly set
                    bind.formatJpg = 'true'
                    bind.formatJpeg = 'true'
                    bind.formatHeic = 'true'
                    bind.formatHeif = 'true'
                    bind.formatNef = 'true'
                    bind.formatRaf = 'true'
                    bind.formatCr2 = 'true'
                    bind.formatArw = 'true'
                    bind.formatDng = 'true'
                    bind.formatRawExt = 'true'
                    bind.formatTiff = 'true'
                    bind.formatTif = 'true'
                    
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
    createAIModelSection = createAIModelSection,
    createTaskSection = createTaskSection,
    createGeneralSection = createGeneralSection,
    createMainDialog = createMainDialog,
}
