--[[----------------------------------------------------------------------------

ExportFilter.lua
Main export filter implementation for ExifCraft v2

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'
local LrFileUtils = import 'LrFileUtils'
local LrDate = import 'LrDate'
local bind = LrView.bind

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end
logger:info('ExifCraft v2 Export Filter loaded')

-- Default settings aligned with ExifCraftConfig and config.ts
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://erics-mac-mini.local:11434/api/generate',
    aiModel = 'llava',
    aiApiKey = '',
    aiTemperature = 0,
    aiMaxTokens = 500,
    
    -- Task Configuration (as TaskConfig objects)
    taskTitleEnabled = 'true',
    taskTitleName = 'title',
    taskTitlePrompt = 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ',
    taskTitleTags = 'ImageTitle,ImageDescription,XPTitle,ObjectName,Title',
    
    taskDescriptionEnabled = 'true',
    taskDescriptionName = 'description',
    taskDescriptionPrompt = 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
    taskDescriptionTags = 'ImageDescription,Description,Caption-Abstract',
    
    taskKeywordsEnabled = 'true',
    taskKeywordsName = 'keywords',
    taskKeywordsPrompt = 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
    taskKeywordsTags = 'Keywords',
    
    taskCustomEnabled = 'false',
    taskCustomName = 'Custom Task',
    taskCustomPrompt = 'Analyze this image and provide metadata.',
    taskCustomTags = 'ImageDescription,Caption-Abstract,Keywords',
    
    -- General Configuration
    preserveOriginal = 'false',
    basePrompt = 'As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n',
    imageFormats = '.jpg,.jpeg,.nef,.raf,.cr2,.arw,.dng,.raw,.tiff,.tif,.heic,.heif',
    verbose = 'false',
    dryRun = 'false',
}

-- Export filter provider table
local exportFilterProvider = {
    exportPresetFields = { 
        "aiProvider", "aiEndpoint", "aiModel", "aiApiKey", "aiTemperature", "aiMaxTokens",
        "taskTitleEnabled", "taskTitleName", "taskTitlePrompt", "taskTitleTags",
        "taskDescriptionEnabled", "taskDescriptionName", "taskDescriptionPrompt", "taskDescriptionTags",
        "taskKeywordsEnabled", "taskKeywordsName", "taskKeywordsPrompt", "taskKeywordsTags",
        "taskCustomEnabled", "taskCustomName", "taskCustomPrompt", "taskCustomTags",
        "preserveOriginal", "basePrompt", "imageFormats", "verbose", "dryRun"
    }
}

-- Initialize dialog properties
function exportFilterProvider.startDialog(propertyTable)
    logger:info('Export filter dialog started')
    
    -- Initialize properties with defaults if not already set
    for key, value in pairs(DEFAULT_SETTINGS) do
        if propertyTable[key] == nil then
            propertyTable[key] = value
            logger:info('Initialized property: ' .. tostring(key))
        end
    end
end

-- Clean up when dialog ends
function exportFilterProvider.endDialog(propertyTable)
    logger:info('Export filter dialog ended')
end

-- Create AI Model Configuration UI
local function createAIModelSection(viewFactory)
    return viewFactory:group_box {
        title = "AI Model Configuration",
        spacing = viewFactory:control_spacing(),
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Provider:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'aiProvider',
                items = {
                    { title = "Ollama", value = "ollama" },
                    { title = "OpenAI", value = "openai" },
                    { title = "Gemini", value = "gemini" },
                    { title = "Mock (Testing)", value = "mock" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Endpoint/API:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'aiEndpoint',
                immediate = true,
                width_in_chars = 35,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Model:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'aiModel',
                immediate = true,
                width_in_chars = 25,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "API Key:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'aiApiKey',
                immediate = true,
                width_in_chars = 30,
                fill_horizontal = 1,
                password = true,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Temperature:",
                width = 80,
            },
            
            viewFactory:slider {
                value = bind 'aiTemperature',
                integral = false,
                min = 0.0,
                max = 2.0,
                width = 150,
            },
            
            viewFactory:static_text {
                title = bind 'aiTemperature',
                width = 40,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Max Tokens:",
                width = 80,
            },
            
            viewFactory:slider {
                value = bind 'aiMaxTokens',
                integral = true,
                min = 100,
                max = 4000,
                width = 150,
            },
            
            viewFactory:static_text {
                title = bind 'aiMaxTokens',
                width = 40,
            },
        },
    }
end

-- Create Task Configuration UI
local function createTaskSection(viewFactory)
    return viewFactory:group_box {
        title = "Task Configuration",
        spacing = viewFactory:control_spacing(),
        
        -- Title Task
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Title Task:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'taskTitleEnabled',
                items = {
                    { title = "Enabled", value = "true" },
                    { title = "Disabled", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Title Name:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskTitleName',
                immediate = true,
                width_in_chars = 20,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Title Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskTitlePrompt',
                immediate = true,
                width_in_chars = 40,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Title Tags:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskTitleTags',
                immediate = true,
                width_in_chars = 40,
                fill_horizontal = 1,
            },
        },
        
        -- Description Task
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Description Task:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'taskDescriptionEnabled',
                items = {
                    { title = "Enabled", value = "true" },
                    { title = "Disabled", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Description Name:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskDescriptionName',
                immediate = true,
                width_in_chars = 20,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Description Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskDescriptionPrompt',
                immediate = true,
                width_in_chars = 40,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Description Tags:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskDescriptionTags',
                immediate = true,
                width_in_chars = 40,
                fill_horizontal = 1,
            },
        },
        
        -- Keywords Task
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Keywords Task:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'taskKeywordsEnabled',
                items = {
                    { title = "Enabled", value = "true" },
                    { title = "Disabled", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Keywords Name:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskKeywordsName',
                immediate = true,
                width_in_chars = 20,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Keywords Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskKeywordsPrompt',
                immediate = true,
                width_in_chars = 40,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Keywords Tags:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskKeywordsTags',
                immediate = true,
                width_in_chars = 40,
                fill_horizontal = 1,
            },
        },
        
        -- Custom Task
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Custom Task:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'taskCustomEnabled',
                items = {
                    { title = "Enabled", value = "true" },
                    { title = "Disabled", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Custom Name:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskCustomName',
                immediate = true,
                width_in_chars = 25,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Custom Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskCustomPrompt',
                immediate = true,
                width_in_chars = 40,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Custom Tags:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'taskCustomTags',
                immediate = true,
                width_in_chars = 40,
                fill_horizontal = 1,
            },
        },
    }
end

-- Create General Options UI
local function createGeneralSection(viewFactory)
    return viewFactory:group_box {
        title = "General Options",
        spacing = viewFactory:control_spacing(),
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Preserve Original:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'preserveOriginal',
                items = {
                    { title = "True", value = "true" },
                    { title = "False", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Verbose Logging:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'verbose',
                items = {
                    { title = "True", value = "true" },
                    { title = "False", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Dry Run:",
                width = 80,
            },
            
            viewFactory:popup_menu {
                value = bind 'dryRun',
                items = {
                    { title = "True", value = "true" },
                    { title = "False", value = "false" },
                },
                width_in_chars = 15,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Base Prompt:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'basePrompt',
                immediate = true,
                width_in_chars = 40,
                height_in_lines = 2,
                fill_horizontal = 1,
            },
        },
        
        viewFactory:row {
            spacing = viewFactory:label_spacing(),
            
            viewFactory:static_text {
                title = "Image Formats:",
                width = 80,
            },
            
            viewFactory:edit_field {
                value = bind 'imageFormats',
                immediate = true,
                width_in_chars = 40,
                fill_horizontal = 1,
            },
        },
    }
end

-- Create the UI section for the export dialog
function exportFilterProvider.sectionForFilterInDialog(viewFactory, propertyTable)
    logger:info('Creating ExifCraft AI configuration UI')
    
    local result = {
        title = "ExifCraft AI Metadata",
        synopsis = "AI-powered EXIF metadata generation",
        
        viewFactory:column {
            spacing = viewFactory:control_spacing(),
            
            -- AI Model Configuration
            createAIModelSection(viewFactory),
            
            -- Task Configuration
            createTaskSection(viewFactory),
            
            -- General Options
            createGeneralSection(viewFactory),
        }
    }
    
    logger:info('ExifCraft AI configuration UI created successfully')
    return result
end

-- Load Utils module
local Utils = require 'Utils'

-- Helper function to parse tags string into TagConfig array
local function parseTags(tagsString)
    local tags = {}
    for tag in tagsString:gmatch("[^,]+") do
        table.insert(tags, { name = tag:gsub("^%s*(.-)%s*$", "%1"), allowOverwrite = true })
    end
    return tags
end

-- Helper function to parse CLI output and extract metadata
local function parseCliOutput(output)
    local metadata = {}
    
    -- Try to parse JSON output first
    local dkjson = require 'dkjson'
    local success, parsed = pcall(dkjson.decode, output)
    if success and type(parsed) == 'table' then
        return parsed
    end
    
    -- Fallback to text parsing for simple output
    local lines = {}
    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    for _, line in ipairs(lines) do
        -- Parse title
        local title = line:match("Title:%s*(.+)")
        if title then
            metadata.title = title:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
        end
        
        -- Parse description
        local description = line:match("Description:%s*(.+)")
        if description then
            metadata.description = description:gsub("^%s*(.-)%s*$", "%1")
        end
        
        -- Parse keywords
        local keywords = line:match("Keywords:%s*(.+)")
        if keywords then
            metadata.keywords = keywords:gsub("^%s*(.-)%s*$", "%1")
        end
        
        -- Parse custom task results
        local custom = line:match("Custom:%s*(.+)")
        if custom then
            metadata.custom = custom:gsub("^%s*(.-)%s*$", "%1")
        end
    end
    
    return metadata
end

-- Helper function to write metadata back to Lightroom database
local function writeMetadataToLightroom(photo, metadata, settings)
    if not photo then
        logger:error('No photo object provided for metadata writing')
        return false
    end
    
    local success = pcall(function()
        -- Write AI-generated content to custom metadata fields
        if metadata.title then
            photo:setPropertyForPlugin(_PLUGIN, 'aiTitle', metadata.title)
        end
        
        if metadata.description then
            photo:setPropertyForPlugin(_PLUGIN, 'aiDescription', metadata.description)
        end
        
        if metadata.keywords then
            photo:setPropertyForPlugin(_PLUGIN, 'aiKeywords', metadata.keywords)
        end
        
        if metadata.custom then
            photo:setPropertyForPlugin(_PLUGIN, 'aiCustomTask', metadata.custom)
        end
        
        -- Write processing status and configuration
        photo:setPropertyForPlugin(_PLUGIN, 'aiProcessingStatus', 'completed')
        photo:setPropertyForPlugin(_PLUGIN, 'aiProcessingDate', LrDate.currentTime())
        photo:setPropertyForPlugin(_PLUGIN, 'aiModelUsed', settings.aiModel or 'unknown')
        photo:setPropertyForPlugin(_PLUGIN, 'aiProviderUsed', settings.aiProvider or 'unknown')
        
        -- Write task configuration status
        photo:setPropertyForPlugin(_PLUGIN, 'aiTaskTitleEnabled', settings.taskTitleEnabled or 'false')
        photo:setPropertyForPlugin(_PLUGIN, 'aiTaskDescriptionEnabled', settings.taskDescriptionEnabled or 'false')
        photo:setPropertyForPlugin(_PLUGIN, 'aiTaskKeywordsEnabled', settings.taskKeywordsEnabled or 'false')
        photo:setPropertyForPlugin(_PLUGIN, 'aiTaskCustomEnabled', settings.taskCustomEnabled or 'false')
        
        logger:info('Metadata written to Lightroom for photo: ' .. tostring(photo:getRawMetadata('path')))
    end)
    
    if not success then
        logger:error('Failed to write metadata to Lightroom for photo: ' .. tostring(photo:getRawMetadata('path')))
        return false
    end
    
    return true
end

-- Create configuration JSON for CLI
local function createConfigJson(settings, tempDir)
    logger:info('Creating configuration JSON')
    
    local dkjson = require 'dkjson'
    
    -- Parse image formats
    local imageFormats = {}
    for format in settings.imageFormats:gmatch("[^,]+") do
        table.insert(imageFormats, format:gsub("^%s*(.-)%s*$", "%1")) -- trim whitespace
    end
    
    -- Build AI model configuration
    local aiModelConfig = {
        provider = settings.aiProvider or 'ollama',
        endpoint = settings.aiEndpoint or 'http://erics-mac-mini.local:11434/api/generate',
        model = settings.aiModel or 'llava',
        options = {
            temperature = tonumber(settings.aiTemperature) or 0,
            max_tokens = tonumber(settings.aiMaxTokens) or 500,
        }
    }
    
    -- Add API key if provided
    if settings.aiApiKey and settings.aiApiKey ~= '' then
        aiModelConfig.key = settings.aiApiKey
    end
    
    local config = {
        tasks = {},
        aiModel = aiModelConfig,
        imageFormats = imageFormats,
        preserveOriginal = settings.preserveOriginal == 'true',
        basePrompt = settings.basePrompt or 'As an assistant of photographer, your job is to generate text to describe a photo given the prompt. Please only return the content of your description without any other text. Here is the prompt: \n',
    }
    
    -- Add tasks based on settings (following TaskConfig schema)
    if settings.taskTitleEnabled == 'true' then
        table.insert(config.tasks, {
            name = settings.taskTitleName or 'title',
            tags = parseTags(settings.taskTitleTags or 'ImageTitle,ImageDescription,XPTitle,ObjectName,Title'),
            prompt = settings.taskTitlePrompt or 'Please generate a title with at most 50 characters for this image, describing the main subject, scene, or content. The title should be a single sentence. ',
        })
    end
    
    if settings.taskDescriptionEnabled == 'true' then
        table.insert(config.tasks, {
            name = settings.taskDescriptionName or 'description',
            tags = parseTags(settings.taskDescriptionTags or 'ImageDescription,Description,Caption-Abstract'),
            prompt = settings.taskDescriptionPrompt or 'Please describe this image in a single paragraph with at most 200 characters. The description may include the main objects, scene, colors, composition, atmosphere and other visual elements. ',
        })
    end
    
    if settings.taskKeywordsEnabled == 'true' then
        table.insert(config.tasks, {
            name = settings.taskKeywordsName or 'keywords',
            tags = parseTags(settings.taskKeywordsTags or 'Keywords'),
            prompt = settings.taskKeywordsPrompt or 'Generate 5-10 keywords for this image, separated by commas, describing the theme, style, content, etc. ',
        })
    end
    
    if settings.taskCustomEnabled == 'true' then
        table.insert(config.tasks, {
            name = settings.taskCustomName or 'Custom Task',
            tags = parseTags(settings.taskCustomTags or 'ImageDescription,Caption-Abstract,Keywords'),
            prompt = settings.taskCustomPrompt or 'Analyze this image and provide metadata.',
        })
    end
    
    -- Write config file
    local configPath = LrPathUtils.child(tempDir, 'exifcraft-config.json')
    local configJson = dkjson.encode(config, { indent = true })
    
    local file = io.open(configPath, 'w')
    if file then
        file:write(configJson)
        file:close()
        logger:info('Config written to: ' .. tostring(configPath))
        return configPath
    else
        error('Failed to write config file: ' .. tostring(configPath))
    end
end

-- Main processing function
function exportFilterProvider.postProcessRenderedPhotos(functionContext, filterContext)
    logger:info('=== Starting ExifCraft AI Processing ===')
    
    local exportSession = filterContext.exportSession
    local exportSettings = filterContext.propertyTable
    local renditions = filterContext.renditions
    
    local progressScope = LrProgressScope({
        title = 'ExifCraft AI Processing',
        functionContext = functionContext,
    })
    
    -- Basic validation
    if not exportSettings.aiEndpoint or exportSettings.aiEndpoint == '' then
        LrDialogs.showError('Configuration Error', 'AI endpoint is required')
        progressScope:done()
        return
    end
    
    -- Create temporary directory
    local tempDir = Utils.createTempDirectory('ExifCraft')
    
    local totalPhotos = 0
    local successCount = 0
    local failureCount = 0
    local startTime = os.time()
    
    local success, errorMessage = pcall(function()
        -- Create config file
        local configPath = createConfigJson(exportSettings, tempDir)
        local cliPath = Utils.findCliExecutable()
        
        -- Count photos
        for rendition in renditions:renditions() do
            totalPhotos = totalPhotos + 1
        end
        
        logger:info('Processing ' .. tostring(totalPhotos) .. ' photos')
        progressScope:setPortionComplete(0, totalPhotos)
        
        local processedCount = 0
        for rendition in renditions:renditions() do
            local photo = rendition.photo
            local renderSuccess, pathOrMessage = rendition:waitForRender()
            
            if renderSuccess then
                progressScope:setCaption('Processing: ' .. tostring(LrPathUtils.leafName(pathOrMessage)))
                
                -- Build CLI command with output capture
                local outputFile = LrPathUtils.child(tempDir, 'output_' .. os.time() .. '.json')
                local command = string.format('"%s" -f "%s" -c "%s" --output "%s"', 
                    cliPath, pathOrMessage, configPath, outputFile)
                
                if exportSettings.verbose == 'true' then
                    command = command .. ' -v'
                end
                
                if exportSettings.dryRun == 'true' then
                    command = command .. ' --dry-run'
                end
                
                logger:info('Executing: ' .. tostring(command))
                
                -- Execute CLI
                local exitCode = LrTasks.execute(command)
                
                if exitCode == 0 then
                    logger:info('Successfully processed: ' .. tostring(pathOrMessage))
                    
                    -- Read CLI output and write metadata to Lightroom
                    if LrFileUtils.exists(outputFile) then
                        local file = io.open(outputFile, 'r')
                        if file then
                            local output = file:read('*all') or ""
                            file:close()
                            
                            -- Parse output and write to Lightroom
                            local metadata = parseCliOutput(output)
                            if metadata and next(metadata) then
                                local writeSuccess = writeMetadataToLightroom(photo, metadata, exportSettings)
                                if writeSuccess then
                                    logger:info('Metadata successfully written to Lightroom')
                                else
                                    logger:error('Failed to write metadata to Lightroom')
                                end
                            else
                                logger:warning('No metadata found in CLI output')
                            end
                        else
                            logger:error('Failed to read CLI output file: ' .. tostring(outputFile))
                        end
                        
                        -- Clean up output file
                        LrFileUtils.delete(outputFile)
                    else
                        logger:warning('CLI output file not found: ' .. tostring(outputFile))
                    end
                    
                    successCount = successCount + 1
                else
                    logger:error('Failed to process: ' .. tostring(pathOrMessage) .. ' (exit code: ' .. tostring(exitCode) .. ')')
                    failureCount = failureCount + 1
                end
            else
                logger:error('Render failed: ' .. tostring(pathOrMessage))
                failureCount = failureCount + 1
            end
            
            processedCount = processedCount + 1
            progressScope:setPortionComplete(processedCount, totalPhotos)
        end
    end)
    
    -- Cleanup
    Utils.cleanupTempDirectory(tempDir)
    
    -- Log processing statistics
    Utils.logProcessingStats(totalPhotos, successCount, failureCount, startTime)
    
    progressScope:done()
    
    if not success then
        LrDialogs.showError('ExifCraft Processing Error', tostring(errorMessage))
        logger:error('Processing error: ' .. tostring(errorMessage))
    else
        logger:info('Processing completed. Success: ' .. tostring(successCount) .. ', Failed: ' .. tostring(failureCount))
        
        if failureCount > 0 then
            local message = string.format(
                'Processing completed with some issues:\n\n' ..
                'Successfully processed: %d/%d images\n' ..
                'Failed: %d images\n\n' ..
                'Check the plugin logs for detailed information.',
                successCount, totalPhotos, failureCount
            )
            LrDialogs.showInfo('ExifCraft Processing Summary', message)
        end
    end
    
    logger:info('=== ExifCraft AI Processing Completed ===')
end

return exportFilterProvider