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

-- Centralized format definitions by group (with both property and format names)
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

-- Generate format name lookup table
local function generateFormatNames()
    local formatNames = {}
    for groupName, formatDefs in pairs(FORMAT_DEFINITIONS) do
        for _, formatDef in ipairs(formatDefs) do
            formatNames[formatDef.property] = formatDef.format
        end
    end
    return formatNames
end





-- Generate supported formats list
local function generateSupportedFormats()
    local formats = {}
    for groupName, formatDefs in pairs(FORMAT_DEFINITIONS) do
        for _, formatDef in ipairs(formatDefs) do
            table.insert(formats, '.' .. formatDef.format)
        end
    end
    return formats
end



-- Generate all derived data structures
local FORMAT_NAMES = generateFormatNames()
local SUPPORTED_FORMATS = generateSupportedFormats()

-- Default settings
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://erics-mac-mini.local:11434/api/generate',
    aiModel = 'llava',
    aiApiKey = '',
    aiTemperature = 0,
    aiMaxTokens = 500,
    
    -- Task Configuration
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

-- Load configuration from preferences
local function loadConfiguration()
    local prefs = LrPrefs.prefsForPlugin()
    local config = {}
    
    -- Load default settings
    for key, defaultValue in pairs(DEFAULT_SETTINGS) do
        config[key] = prefs[key] or defaultValue
    end
    
    -- Set default imageFormats if not exists
    if not config.imageFormats then
        config.imageFormats = table.concat(SUPPORTED_FORMATS, ',')
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
    
    logger:info('Configuration saved to preferences')
end

-- Export module
return {
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    SUPPORTED_FORMATS = SUPPORTED_FORMATS,
    FORMAT_NAMES = FORMAT_NAMES,
    FORMAT_DEFINITIONS = FORMAT_DEFINITIONS,
    toBoolean = toBoolean,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
}
