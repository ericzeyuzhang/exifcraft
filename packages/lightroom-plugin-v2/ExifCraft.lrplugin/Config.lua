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
}

-- Format type constants with all metadata
local FORMAT_TYPES = {
    -- Property-based format definitions for direct access
    formatJpg = { group = 'Standard', extension = '.jpg', displayName = 'JPG', groupDisplayName = 'Standard Formats' },
    formatJpeg = { group = 'Standard', extension = '.jpeg', displayName = 'JPEG', groupDisplayName = 'Standard Formats' },
    formatHeic = { group = 'Standard', extension = '.heic', displayName = 'HEIC', groupDisplayName = 'Standard Formats' },
    formatHeif = { group = 'Standard', extension = '.heif', displayName = 'HEIF', groupDisplayName = 'Standard Formats' },
    
    formatNef = { group = 'Raw', extension = '.nef', displayName = 'NEF', groupDisplayName = 'RAW Formats' },
    formatRaf = { group = 'Raw', extension = '.raf', displayName = 'RAF', groupDisplayName = 'RAW Formats' },
    formatCr2 = { group = 'Raw', extension = '.cr2', displayName = 'CR2', groupDisplayName = 'RAW Formats' },
    formatArw = { group = 'Raw', extension = '.arw', displayName = 'ARW', groupDisplayName = 'RAW Formats' },
    formatDng = { group = 'Raw', extension = '.dng', displayName = 'DNG', groupDisplayName = 'RAW Formats' },
    formatRawExt = { group = 'Raw', extension = '.raw', displayName = 'RAW', groupDisplayName = 'RAW Formats' },
    
    formatTiff = { group = 'Tiff', extension = '.tiff', displayName = 'TIFF', groupDisplayName = 'TIFF Formats' },
    formatTif = { group = 'Tiff', extension = '.tif', displayName = 'TIF', groupDisplayName = 'TIFF Formats' },
}

-- Group property mappings for Select All functionality
local GROUP_PROPERTIES = {
    Standard = 'formatStandard',
    Raw = 'formatRaw', 
    Tiff = 'formatTiffGroup'
}

-- Generate supported formats list from FORMAT_TYPES
local function generateSupportedFormats()
    local formats = {}
    for property, formatData in pairs(FORMAT_TYPES) do
        table.insert(formats, formatData.extension)
    end
    return formats
end

local SUPPORTED_FORMATS = generateSupportedFormats()

-- Helper function to normalize boolean values
local function toBoolean(value)
    if type(value) == 'string' then
        return value == 'true'
    end
    return value == true
end

-- Helper function to convert format selections to imageFormats string
local function formatSelectionsToString(formatProps)
    local formats = {}
    
    for property, formatData in pairs(FORMAT_TYPES) do
        if formatProps[property] then
            table.insert(formats, formatData.extension)
        end
    end
    
    return table.concat(formats, ',')
end

-- Helper function to convert imageFormats string to format selections
local function stringToFormatSelections(imageFormats, formatProps)
    local formats = {}
    for format in imageFormats:gmatch('[^,]+') do
        formats[format:match('^%s*(.-)%s*$')] = true -- trim whitespace
    end
    
    -- Set format properties based on FORMAT_TYPES
    for property, formatData in pairs(FORMAT_TYPES) do
        formatProps[property] = formats[formatData.extension] == true
    end
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
local function saveConfiguration(config, formatProps)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Convert format selections to imageFormats string
    if formatProps then
        config.imageFormats = formatSelectionsToString(formatProps)
    end
    
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
    FORMAT_TYPES = FORMAT_TYPES,
    GROUP_PROPERTIES = GROUP_PROPERTIES,
    toBoolean = toBoolean,
    loadConfiguration = loadConfiguration,
    saveConfiguration = saveConfiguration,
    formatSelectionsToString = formatSelectionsToString,
    stringToFormatSelections = stringToFormatSelections,
}
