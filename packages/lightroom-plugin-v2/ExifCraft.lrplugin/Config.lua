--[[----------------------------------------------------------------------------

Config.lua
Configuration management for ExifCraft v2

This module handles default settings, configuration loading/saving,
and configuration validation.

------------------------------------------------------------------------------]]

local LrPrefs = import 'LrPrefs'
local dkjson = require 'Dkjson'

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

-- Default settings
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://erics-mac-mini.local:11434/api/generate',
    aiModel = 'llava',
    aiApiKey = '',
    aiTemperature = 0,
    aiMaxTokens = 500,
    
    -- Task Configuration (default tasks matching ExifCraftConfig schema)
    tasks = {
        {
            name = 'title',
            prompt = 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ',
            tags = {
                { name = 'ImageTitle', allowOverwrite = true },
                { name = 'ImageDescription', allowOverwrite = true },
                { name = 'XPTitle', allowOverwrite = true },
                { name = 'ObjectName', allowOverwrite = true },
                { name = 'Title', allowOverwrite = true }
            }
        },
        {
            name = 'description',
            prompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
            tags = {
                { name = 'ImageDescription', allowOverwrite = true },
                { name = 'Description', allowOverwrite = true },
                { name = 'Caption-Abstract', allowOverwrite = true }
            }
        },
        {
            name = 'keywords',
            prompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
            tags = {
                { name = 'Keywords', allowOverwrite = true }
            }
        }
    },
    

    
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

-- Helper function to normalize boolean values
local function toBoolean(value)
    if type(value) == 'string' then
        return value == 'true'
    end
    return value == true
end

-- Serialize tasks to JSON string for preferences storage
local function serializeTasks(tasks)
    if not tasks or #tasks == 0 then
        return dkjson.encode(DEFAULT_SETTINGS.tasks)
    end
    return dkjson.encode(tasks)
end

-- Deserialize tasks from JSON string
local function deserializeTasks(tasksJson)
    if not tasksJson or tasksJson == '' then
        return DEFAULT_SETTINGS.tasks
    end
    
    local success, tasks = pcall(dkjson.decode, tasksJson)
    if not success or type(tasks) ~= 'table' then
        logger:warning('Failed to parse tasks JSON, using default tasks')
        return DEFAULT_SETTINGS.tasks
    end
    
    return tasks
end

-- Get enabled tasks from task configuration
local function getEnabledTasks(tasks)
    local enabledTasks = {}
    for _, task in ipairs(tasks) do
        if task.enabled then
            table.insert(enabledTasks, task)
        end
    end
    return enabledTasks
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
        config.tasks = DEFAULT_SETTINGS.tasks
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
    
    -- Save default settings
    for key, _ in pairs(DEFAULT_SETTINGS) do
        prefs[key] = config[key]
    end
    
    -- Save tasks as JSON string
    if config.tasks then
        prefs.tasksJson = serializeTasks(config.tasks)
    end
    
    logger:info('Configuration saved to preferences')
end

-- Export module
return {
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    FORMAT_DEFINITIONS = FORMAT_DEFINITIONS,
    toBoolean = toBoolean,
    serializeTasks = serializeTasks,
    deserializeTasks = deserializeTasks,
    getEnabledTasks = getEnabledTasks,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
}
