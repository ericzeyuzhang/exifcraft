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

-- Preset task templates
local PRESET_TASK_TEMPLATES = {
    {
        id = 'title',
        name = 'Image Title',
        description = 'Generate a concise title for the image',
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
        id = 'description',
        name = 'Image Description',
        description = 'Generate a detailed description of the image',
        prompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
        tags = {
            { name = 'ImageDescription', allowOverwrite = true },
            { name = 'Description', allowOverwrite = true },
            { name = 'Caption-Abstract', allowOverwrite = true }
        },
        enabled = true
    },
    {
        id = 'keywords',
        name = 'Keywords',
        description = 'Generate relevant keywords for the image',
        prompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
        tags = {
            { name = 'Keywords', allowOverwrite = true }
        },
        enabled = true
    },
    {
        id = 'location',
        name = 'Location',
        description = 'Identify and describe the location in the image',
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
        id = 'subject',
        name = 'Subject',
        description = 'Identify the main subject or subjects in the image',
        prompt = 'Identify the main subject(s) in this image. This could be people, animals, objects, or scenes. Describe who or what is the primary focus of the photograph. ',
        tags = {
            { name = 'Subject', allowOverwrite = true },
            { name = 'ObjectName', allowOverwrite = true }
        },
        enabled = false
    },
    {
        id = 'style',
        name = 'Photography Style',
        description = 'Identify the photography style or genre',
        prompt = 'Identify the photography style, genre, or technique used in this image. Consider aspects like composition, lighting, color treatment, and artistic approach (e.g., "portrait", "landscape", "street photography", "macro", "black and white", "vintage", "minimalist"). ',
        tags = {
            { name = 'Style', allowOverwrite = true },
            { name = 'Keywords', allowOverwrite = true }
        },
        enabled = false
    },
    {
        id = 'mood',
        name = 'Mood/Atmosphere',
        description = 'Describe the mood or atmosphere of the image',
        prompt = 'Describe the mood, atmosphere, or emotional tone conveyed by this image. Consider elements like lighting, colors, composition, and subject matter that contribute to the overall feeling (e.g., "peaceful", "dramatic", "nostalgic", "energetic", "mysterious"). ',
        tags = {
            { name = 'Mood', allowOverwrite = true },
            { name = 'Keywords', allowOverwrite = true }
        },
        enabled = false
    },
    {
        id = 'technical',
        name = 'Technical Details',
        description = 'Analyze technical aspects of the photograph',
        prompt = 'Analyze the technical aspects of this photograph. Consider elements like depth of field, shutter speed effects, lighting technique, composition rules, and any notable technical characteristics that make this image distinctive. ',
        tags = {
            { name = 'TechnicalNotes', allowOverwrite = true },
            { name = 'Keywords', allowOverwrite = true }
        },
        enabled = false
    },
    {
        id = 'custom1',
        name = 'Custom Task 1',
        description = 'Custom task for specific needs',
        prompt = 'Enter your custom prompt here...',
        tags = {
            { name = 'Custom1', allowOverwrite = true }
        },
        enabled = false,
        isCustom = true
    },
    {
        id = 'custom2',
        name = 'Custom Task 2',
        description = 'Custom task for specific needs',
        prompt = 'Enter your custom prompt here...',
        tags = {
            { name = 'Custom2', allowOverwrite = true }
        },
        enabled = false,
        isCustom = true
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
    if not tasks or #tasks == 0 then
        return dkjson.encode(PRESET_TASK_TEMPLATES)
    end
    return dkjson.encode(tasks)
end

-- Deserialize tasks from JSON string
local function deserializeTasks(tasksJson)
    if not tasksJson or tasksJson == '' then
        return PRESET_TASK_TEMPLATES
    end
    
    local success, tasks = pcall(dkjson.decode, tasksJson)
    if not success or type(tasks) ~= 'table' then
        logger:warning('Failed to parse tasks JSON, using default tasks')
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
    PRESET_TASK_TEMPLATES = PRESET_TASK_TEMPLATES,
    toBoolean = toBoolean,
    serializeTasks = serializeTasks,
    deserializeTasks = deserializeTasks,
    getEnabledTasks = getEnabledTasks,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
}
