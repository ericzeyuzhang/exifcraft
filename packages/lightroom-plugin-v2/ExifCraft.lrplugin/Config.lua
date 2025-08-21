--[[----------------------------------------------------------------------------

Config.lua
Configuration management for ExifCraft v2

This module handles default settings, configuration loading/saving,
and configuration validation.

------------------------------------------------------------------------------]]

local LrPrefs = import 'LrPrefs'


-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end


-- Format definitions by group
local FORMAT_DEFINITIONS = {
    Standard = {
        { property = 'formatJpg', format = 'jpg' },
        { property = 'formatJpeg', format = 'jpeg' },
        { property = 'formatHeic', format = 'heic' },
        { property = 'formatHeif', format = 'heif' }
    },
    Raw = {
        { property = 'formatNef', format = 'nef' },
        { property = 'formatRaf', format = 'raf' },
        { property = 'formatCr2', format = 'cr2' },
        { property = 'formatCr3', format = 'cr3' },
        { property = 'formatArw', format = 'arw' },
        { property = 'formatDng', format = 'dng' },
        { property = 'formatRaw', format = 'raw' }
    },
    Tiff = {
        { property = 'formatTiff', format = 'tiff' },
        { property = 'formatTif', format = 'tif' }
    }
}

-- Preset task templates
local PRESET_TASK_TEMPLATES = {
    {
        name = 'Image Title',
        prompt = 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ',
        tags = {
            { name = 'ImageTitle', allowOverwrite = true },
            { name = 'XPTitle', allowOverwrite = true },
            { name = 'ObjectName', allowOverwrite = true },
            { name = 'Title', allowOverwrite = true }
        },
        enabled = true
    },
    {
        name = 'Image Description',
        prompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
        tags = {
            { name = 'ImageDescription', allowOverwrite = true },
            { name = 'Description', allowOverwrite = true },
            { name = 'Caption-Abstract', allowOverwrite = true }
        },
        enabled = true
    },
    {
        name = 'Keywords',
        prompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
        tags = {
            { name = 'Keywords', allowOverwrite = true }
        },
        enabled = true
    },
    {
        name = 'Location',
        prompt = 'Identify the location, place, or setting shown in this image. If it\'s a recognizable landmark, city, or specific location, please provide the name. If it\'s a generic location, describe the type of place (e.g., "mountain landscape", "urban street", "beach"). ',
        tags = {
            { name = 'Location', allowOverwrite = true },
            { name = 'SubLocation', allowOverwrite = true },
            { name = 'City', allowOverwrite = true },
            { name = 'State', allowOverwrite = true },
            { name = 'Country', allowOverwrite = true }
        },
        enabled = false
    },
    {
        name = 'Subject',
        prompt = 'Identify the main subject(s) in this image. This could be people, animals, objects, or scenes. Describe who or what is the primary focus of the photograph. ',
        tags = {
            { name = 'Subject', allowOverwrite = true },
            { name = 'ObjectName', allowOverwrite = true }
        },
        enabled = false
    },
}

-- Default settings
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://erics-mac-mini.local:11434/api/generate',
    aiModel = 'llava',
    aiApiKey = '',
    aiTemperature = 0,
    aiMaxTokens = 500,
    
    -- Task Configuration (using preset templates)
    tasks = PRESET_TASK_TEMPLATES,
    
    -- General Configuration
    basePrompt = 'As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n',
    preserveOriginal = false,
    verbose = true,
    dryRun = false,
    
    -- Format Settings (all enabled by default)
    formatJpg = true,
    formatJpeg = true,
    formatHeic = true,
    formatHeif = true,
    formatNef = true,
    formatRaf = true,
    formatCr2 = true,
    formatCr3 = true,
    formatArw = true,
    formatDng = true,
    formatRaw = true,
    formatTiff = true,
    formatTif = true,
}

local LAYOUT_SETTINGS = {
    L1Title = {
        font = '<system/bold>',
        color = 'black',
    },
    L2Title = {
        font = '<system/regular>',
        color = 'black',
    },
    L3Title = {
        font = '<system/regular>',
        color = 'black',
    },
    FieldTitle = { 
        font = '<system/regular>',
        color = 'black',
    },
    SubTitle = {
        font = '<system/small>',
        color = 'grey',
    },
}

-- Helper function to normalize boolean values
local function toBoolean(value)
    if type(value) == 'string' then
        return value == 'true'
    end
    return value == true
end

-- Get enabled tasks from task configuration
local function getEnabledTasks(tasks)
    local enabledTasks = {}
    for _, task in ipairs(tasks) do
        if task.enabled then
            -- Convert to the format expected by the CLI
            local cliTask = {
                name = task.name,
                prompt = task.prompt,
                tags = {}
            }
            
            -- Convert tags array to simple string array
            if task.tags then
                for _, tag in ipairs(task.tags) do
                    table.insert(cliTask.tags, tag.name)
                end
            end
            
            table.insert(enabledTasks, cliTask)
        end
    end
    return enabledTasks
end

-- Serialize tasks to JSON string for preferences storage
local function serializeTasks(tasks)
    -- Percent-encode helper to avoid delimiter collisions
    local function enc(s)
        if s == nil then return '' end
        s = tostring(s)
        s = s:gsub('%%', '%%25')
        s = s:gsub('\n', '%%0A')
        s = s:gsub('|', '%%7C')
        s = s:gsub(',', '%%2C')
        return s
    end

    local source = (tasks and #tasks > 0) and tasks or PRESET_TASK_TEMPLATES
    local lines = {}
    for i, task in ipairs(source) do
        -- Ensure stable id
        local id = task.id or tostring(i)

        -- Collapse tags to comma-joined names
        local tagNames = {}
        if type(task.tags) == 'table' then
            for _, tag in ipairs(task.tags) do
                table.insert(tagNames, enc(tag.name or ''))
            end
        end
        local tagsStr = table.concat(tagNames, ',')

        local fields = {
            enc(id),
            enc(task.name or ''),
            enc(task.prompt or ''),
            tagsStr,
            task.enabled and '1' or '0',
            task.isCustom and '1' or '0',
        }
        table.insert(lines, table.concat(fields, '|'))
    end

    -- Custom header marks delimiter-based format
    return 'TASKS1\n' .. table.concat(lines, '\n')
end

-- Deserialize tasks from JSON string
local function deserializeTasks(tasksJson)
    if not tasksJson or tasksJson == '' then
        return PRESET_TASK_TEMPLATES
    end

    -- Only support delimiter-based format
    if tasksJson:sub(1, 7) ~= 'TASKS1\n' then
        logger:warning('Unknown tasks format, using default tasks')
        return PRESET_TASK_TEMPLATES
    end

    local function dec(s)
        s = s or ''
        s = s:gsub('%%0A', '\n')
        s = s:gsub('%%2C', ',')
        s = s:gsub('%%7C', '|')
        s = s:gsub('%%25', '%%')
        return s
    end

    local body = tasksJson:sub(8)
    local tasks = {}
    local index = 0

    for line in body:gmatch('[^\n]+') do
        index = index + 1
        -- Split by '|' preserving empty fields
        local parts = {}
        local startPos = 1
        while true do
            local sepPos = line:find('|', startPos, true)
            if not sepPos then
                table.insert(parts, line:sub(startPos))
                break
            end
            table.insert(parts, line:sub(startPos, sepPos - 1))
            startPos = sepPos + 1
        end

        -- Ensure 6 fields
        for i = #parts + 1, 6 do parts[i] = '' end

        local id = dec(parts[1])
        local name = dec(parts[2])
        local prompt = dec(parts[3])
        local tagsField = parts[4]
        local enabledStr = parts[5]
        local isCustomStr = parts[6]

        -- Rebuild tags from comma-separated names
        local tags = {}
        if tagsField and tagsField ~= '' then
            for t in tagsField:gmatch('[^,]+') do
                local tagName = dec(t)
                if tagName ~= '' then
                    table.insert(tags, { name = tagName, allowOverwrite = true })
                end
            end
        end

        local task = {
            id = (id ~= '' and id) or tostring(index),
            name = name,
            prompt = prompt,
            tags = tags,
            enabled = enabledStr == '1',
            isCustom = isCustomStr == '1',
        }
        table.insert(tasks, task)
    end

    if #tasks == 0 then
        return PRESET_TASK_TEMPLATES
    end
    return tasks
end

-- Load configuration from preferences
local function loadConfiguration()
    local prefs = LrPrefs.prefsForPlugin()
    local config = {}
    
    -- Load default settings
    for key, defaultValue in pairs(DEFAULT_SETTINGS) do
        config[key] = prefs[key] or defaultValue
    end
    
    -- Load tasks from preferences or use defaults
    local tasksJson = prefs.tasksJson
    if tasksJson and tasksJson ~= '' then
        config.tasks = deserializeTasks(tasksJson)
    else
        config.tasks = PRESET_TASK_TEMPLATES
    end
    
    -- Ensure all tasks have unique IDs
    for i, task in ipairs(config.tasks) do
        if not task.id then
            task.id = tostring(i)
        end
    end
    
    -- Prefer persisted imageFormats if present
    if prefs.imageFormats and prefs.imageFormats ~= '' then
        config.imageFormats = prefs.imageFormats
    end

    -- Set default imageFormats if not exists
    if not config.imageFormats then
        local formats = {}
        for _, formatDefs in pairs(FORMAT_DEFINITIONS) do
            for _, formatDef in ipairs(formatDefs) do
                table.insert(formats, formatDef.format)
            end
        end
        config.imageFormats = table.concat(formats, ',')
    end
    
    logger:info('Configuration loaded from preferences')
    return config
end

-- Save configuration to preferences
local function saveConfiguration(config)
    local prefs = LrPrefs.prefsForPlugin()

    -- Persist all keys provided (except tasks which is handled separately)
    for key, value in pairs(config) do
        if key ~= 'tasks' then
            prefs[key] = value
        end
    end

    -- Save tasks as JSON string
    if config.tasks then
        prefs.tasksJson = serializeTasks(config.tasks)
    end

    logger:info('Configuration saved to preferences')
end

-- Build a persistable configuration table from dialog properties
local function buildPersistentConfigFromDialogProps(dialogProps)
    local persistent = {}

    -- AI model fields
    persistent.aiProvider = dialogProps.aiProvider
    persistent.aiEndpoint = dialogProps.aiEndpoint
    persistent.aiModel = dialogProps.aiModel
    persistent.aiApiKey = dialogProps.aiApiKey

    -- Numeric options (ensure numbers)
    local temperature = dialogProps.aiTemperature
    local maxTokens = dialogProps.aiMaxTokens
    if type(temperature) == 'string' then
        temperature = tonumber(temperature)
    end
    if type(maxTokens) == 'string' then
        maxTokens = tonumber(maxTokens)
    end
    persistent.aiTemperature = temperature or 0
    persistent.aiMaxTokens = maxTokens or 500

    -- General settings
    persistent.basePrompt = dialogProps.basePrompt
    persistent.preserveOriginal = toBoolean(dialogProps.preserveOriginal)
    persistent.verbose = toBoolean(dialogProps.verbose)
    persistent.dryRun = toBoolean(dialogProps.dryRun)

    -- Image formats booleans and derived string
    local selectedFormats = {}
    for _, formatDefs in pairs(FORMAT_DEFINITIONS) do
        for _, formatDef in ipairs(formatDefs) do
            local isEnabled = dialogProps[formatDef.property]
            -- Persist the checkbox state as well
            persistent[formatDef.property] = isEnabled and true or false
            if isEnabled then
                table.insert(selectedFormats, formatDef.format)
            end
        end
    end
    persistent.imageFormats = table.concat(selectedFormats, ',')

    -- Tasks: convert property tables to plain tables
    if type(dialogProps.tasks) == 'table' then
        persistent.tasks = {}
        for i, taskProp in ipairs(dialogProps.tasks) do
            local task = {
                id = taskProp.id or tostring(i),
                name = taskProp.name,
                prompt = taskProp.prompt,
                tags = taskProp.tags,
                enabled = taskProp.enabled and true or false,
                isCustom = taskProp.isCustom and true or false,
            }
            table.insert(persistent.tasks, task)
        end
    end

    return persistent
end

-- Validate a persistable configuration table
local function validateConfig(config)
    local errors = {}

    -- AI provider
    local allowedProviders = { ollama = true, openai = true, gemini = true, mock = true }
    if not config.aiProvider or not allowedProviders[config.aiProvider] then
        table.insert(errors, 'Invalid AI provider')
    end

    -- Endpoint
    if not config.aiEndpoint or config.aiEndpoint == '' then
        table.insert(errors, 'AI endpoint is required')
    end

    -- Model
    if not config.aiModel or config.aiModel == '' then
        table.insert(errors, 'AI model is required')
    end

    -- Temperature
    local t = tonumber(config.aiTemperature)
    if t == nil or t < 0 or t > 1 then
        table.insert(errors, 'Temperature must be a number between 0 and 1')
    end

    -- Max tokens
    local mt = tonumber(config.aiMaxTokens)
    if mt == nil or mt < 1 or mt > 100000 then
        table.insert(errors, 'Max tokens must be a positive integer (<= 100000)')
    end

    -- Tasks
    if type(config.tasks) ~= 'table' or #config.tasks == 0 then
        table.insert(errors, 'At least one task is required')
    else
        local anyEnabled = false
        for _, task in ipairs(config.tasks) do
            if task.enabled then
                anyEnabled = true
                if not task.name or task.name == '' then
                    table.insert(errors, 'Enabled task must have a name')
                end
                if not task.prompt or task.prompt == '' then
                    table.insert(errors, 'Enabled task must have a prompt')
                end
            end
        end
        if not anyEnabled then
            table.insert(errors, 'At least one task must be enabled')
        end
    end

    if #errors > 0 then
        return false, table.concat(errors, '\n')
    end
    return true, nil
end

-- Export module
return {
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    FORMAT_DEFINITIONS = FORMAT_DEFINITIONS,
    PRESET_TASK_TEMPLATES = PRESET_TASK_TEMPLATES,
    LAYOUT_SETTINGS = LAYOUT_SETTINGS,
    toBoolean = toBoolean,
    serializeTasks = serializeTasks,
    deserializeTasks = deserializeTasks,
    getEnabledTasks = getEnabledTasks,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
    buildPersistentConfigFromDialogProps = buildPersistentConfigFromDialogProps,
    validateConfig = validateConfig,
}
