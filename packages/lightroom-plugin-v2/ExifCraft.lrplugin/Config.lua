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

-- Default settings
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://erics-mac-mini.local:11434/api/generate',
    aiModel = 'llava',
    aiApiKey = '',
    aiTemperature = 0,
    aiMaxTokens = 500,
    
    -- Task Configuration (legacy - will be replaced by taskList)
    taskTitleEnabled = 'true',
    taskTitleName = 'Title',
    taskTitlePrompt = 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ',
    taskTitleTags = 'ImageTitle,ImageDescription,XPTitle,ObjectName,Title',
    taskTitleAllowOverwrite = 'true',
    
    taskDescriptionEnabled = 'true',
    taskDescriptionName = 'Description',
    taskDescriptionPrompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
    taskDescriptionTags = 'ImageDescription,Description,Caption-Abstract',
    taskDescriptionAllowOverwrite = 'true',
    
    taskKeywordsEnabled = 'true',
    taskKeywordsName = 'Keywords',
    taskKeywordsPrompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
    taskKeywordsTags = 'Keywords',
    taskKeywordsAllowOverwrite = 'true',
    
    taskCustomEnabled = 'false',
    taskCustomName = 'Custom',
    taskCustomPrompt = 'Analyze this image and provide metadata.',
    taskCustomTags = 'ImageDescription,Caption-Abstract,Keywords',
    taskCustomAllowOverwrite = 'true',
    
    -- General Configuration
    preserveOriginal = 'false',
    basePrompt = 'As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n',
    imageFormats = '.jpg,.jpeg,.nef,.raf,.cr2,.arw,.dng,.raw,.tiff,.tif,.heic,.heif',
    -- Image format selections (for UI)
    formatStandard = 'true',
    formatJpg = 'true',
    formatJpeg = 'true', 
    formatHeic = 'true',
    formatHeif = 'true',
    formatRaw = 'true',
    formatNef = 'true',
    formatRaf = 'true',
    formatCr2 = 'true',
    formatArw = 'true',
    formatDng = 'true',
    formatRawExt = 'true',
    formatTiff = 'true',
    formatTif = 'true',
    verbose = 'true',
    dryRun = 'false',
}

-- Supported image formats
local SUPPORTED_FORMATS = {
    '.jpg', '.jpeg', '.nef', '.raf', '.cr2', '.arw', '.dng', '.raw', '.tiff', '.tif', '.heic', '.heif'
}

-- Helper function to normalize boolean values
local function toBoolean(value)
    if type(value) == 'string' then
        return value == 'true'
    end
    return value == true
end

-- Helper function to convert format selections to imageFormats string
local function formatSelectionsToString(config)
    local formats = {}
    
    if toBoolean(config.formatJpg) then table.insert(formats, '.jpg') end
    if toBoolean(config.formatJpeg) then table.insert(formats, '.jpeg') end
    if toBoolean(config.formatHeic) then table.insert(formats, '.heic') end
    if toBoolean(config.formatHeif) then table.insert(formats, '.heif') end
    if toBoolean(config.formatNef) then table.insert(formats, '.nef') end
    if toBoolean(config.formatRaf) then table.insert(formats, '.raf') end
    if toBoolean(config.formatCr2) then table.insert(formats, '.cr2') end
    if toBoolean(config.formatArw) then table.insert(formats, '.arw') end
    if toBoolean(config.formatDng) then table.insert(formats, '.dng') end
    if toBoolean(config.formatRawExt) then table.insert(formats, '.raw') end
    if toBoolean(config.formatTiff) then table.insert(formats, '.tiff') end
    if toBoolean(config.formatTif) then table.insert(formats, '.tif') end
    
    return table.concat(formats, ',')
end

-- Helper function to convert imageFormats string to format selections
local function stringToFormatSelections(imageFormats, config)
    local formats = {}
    for format in imageFormats:gmatch('[^,]+') do
        formats[format:match('^%s*(.-)%s*$')] = true -- trim whitespace
    end
    
    config.formatJpg = tostring(formats['.jpg'] == true)
    config.formatJpeg = tostring(formats['.jpeg'] == true)
    config.formatHeic = tostring(formats['.heic'] == true)
    config.formatHeif = tostring(formats['.heif'] == true)
    config.formatNef = tostring(formats['.nef'] == true)
    config.formatRaf = tostring(formats['.raf'] == true)
    config.formatCr2 = tostring(formats['.cr2'] == true)
    config.formatArw = tostring(formats['.arw'] == true)
    config.formatDng = tostring(formats['.dng'] == true)
    config.formatRawExt = tostring(formats['.raw'] == true)
    config.formatTiff = tostring(formats['.tiff'] == true)
    config.formatTif = tostring(formats['.tif'] == true)
end

-- Load configuration from preferences
local function loadConfiguration()
    local prefs = LrPrefs.prefsForPlugin()
    local config = {}
    
    -- Load default settings
    for key, defaultValue in pairs(DEFAULT_SETTINGS) do
        config[key] = prefs[key] or defaultValue
    end
    
    -- Convert imageFormats string to format selections if needed
    if config.imageFormats and not prefs.formatJpg then
        stringToFormatSelections(config.imageFormats, config)
    end
    
    -- Load saved task list if exists
    if prefs.taskList then
        config.taskList = prefs.taskList
    end
    
    logger:info('Configuration loaded from preferences')
    return config
end

-- Save configuration to preferences
local function saveConfiguration(config)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Convert format selections to imageFormats string
    config.imageFormats = formatSelectionsToString(config)
    
    -- Save default settings
    for key, _ in pairs(DEFAULT_SETTINGS) do
        prefs[key] = config[key]
    end
    
    -- Save dynamic task list
    if config.taskList then
        prefs.taskList = config.taskList
    end
    
    logger:info('Configuration saved to preferences')
end

-- Initialize default task list
local function getDefaultTaskList()
    return {
        { enabled = 'true', name = 'Title', prompt = 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ', tags = {} },
        { enabled = 'true', name = 'Description', prompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ', tags = {} },
        { enabled = 'true', name = 'Keywords', prompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ', tags = {} },
    }
end

-- Initialize task list with proper tag format
local function initializeTaskList(taskList)
    if not taskList then
        return getDefaultTaskList()
    end
    
    for _, task in ipairs(taskList) do
        if type(task.tags) == 'string' then
            -- Convert string tags to array
            local tagsArray = {}
            for tag in task.tags:gmatch('[^,]+') do
                table.insert(tagsArray, tag:match('^%s*(.-)%s*$')) -- trim whitespace
            end
            task.tags = tagsArray
        elseif not task.tags then
            task.tags = {}
        end
    end
    
    return taskList
end

-- Export module
return {
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    SUPPORTED_FORMATS = SUPPORTED_FORMATS,
    toBoolean = toBoolean,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
    getDefaultTaskList = getDefaultTaskList,
    initializeTaskList = initializeTaskList,
}
