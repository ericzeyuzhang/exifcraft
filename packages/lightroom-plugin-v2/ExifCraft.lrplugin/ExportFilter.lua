--[[----------------------------------------------------------------------------

ExportFilter.lua
Main export filter implementation for ExifCraft v2

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'
local bind = LrView.bind

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end
logger:info('ExifCraft v2 Export Filter loaded')

-- Default settings aligned with ExifCraftConfig
local DEFAULT_SETTINGS = {
    -- AI Model Configuration
    aiProvider = 'ollama',
    aiEndpoint = 'http://localhost:11434',
    aiModel = 'llama3.2-vision',
    aiApiKey = '',
    aiTemperature = 0.7,
    aiMaxTokens = 1000,
    
    -- Task Configuration
    taskTitle = true,
    taskDescription = true,
    taskKeywords = true,
    taskCustom = false,
    taskCustomName = 'Custom Task',
    taskCustomPrompt = 'Analyze this image and provide metadata.',
    taskCustomTags = 'ImageDescription,Caption-Abstract,Keywords',
    
    -- General Configuration
    preserveOriginal = true,
    basePrompt = 'Analyze this image and provide metadata.',
    imageFormats = 'jpg,jpeg,tiff,tif,png,dng,cr2,nef,arw',
    verbose = false,
    dryRun = false,
}

-- Export filter provider table
local exportFilterProvider = {
    exportPresetFields = { 
        "aiProvider", "aiEndpoint", "aiModel", "aiApiKey", "aiTemperature", "aiMaxTokens",
        "taskTitle", "taskDescription", "taskKeywords", "taskCustom", "taskCustomName", "taskCustomPrompt", "taskCustomTags",
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
        
        viewFactory:checkbox {
            title = "Generate Title",
            value = bind 'taskTitle',
        },
        
        viewFactory:checkbox {
            title = "Generate Description",
            value = bind 'taskDescription',
        },
        
        viewFactory:checkbox {
            title = "Generate Keywords",
            value = bind 'taskKeywords',
        },
        
        viewFactory:checkbox {
            title = "Custom Task",
            value = bind 'taskCustom',
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
        
        viewFactory:checkbox {
            title = "Preserve Original Files",
            value = bind 'preserveOriginal',
        },
        
        viewFactory:checkbox {
            title = "Verbose Logging",
            value = bind 'verbose',
        },
        
        viewFactory:checkbox {
            title = "Dry Run (No Changes)",
            value = bind 'dryRun',
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
        endpoint = settings.aiEndpoint or 'http://localhost:11434',
        model = settings.aiModel or 'llama3.2-vision',
        options = {
            temperature = tonumber(settings.aiTemperature) or 0.7,
            max_tokens = tonumber(settings.aiMaxTokens) or 1000,
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
        preserveOriginal = settings.preserveOriginal ~= false,
        basePrompt = settings.basePrompt or 'Analyze this image and provide metadata.',
    }
    
    -- Add standard tasks based on settings
    if settings.taskTitle ~= false then
        table.insert(config.tasks, {
            name = 'Generate Title',
            tags = {{ name = 'ImageDescription', allowOverwrite = true }},
            prompt = 'Generate a concise, descriptive title for this image.',
        })
    end
    
    if settings.taskDescription ~= false then
        table.insert(config.tasks, {
            name = 'Generate Description',
            tags = {{ name = 'Caption-Abstract', allowOverwrite = true }},
            prompt = 'Provide a detailed description of this image.',
        })
    end
    
    if settings.taskKeywords ~= false then
        table.insert(config.tasks, {
            name = 'Generate Keywords',
            tags = {{ name = 'Keywords', allowOverwrite = true }},
            prompt = 'Generate relevant keywords for this image, separated by commas.',
        })
    end
    
    -- Add custom task if enabled
    if settings.taskCustom and settings.taskCustomName and settings.taskCustomName ~= '' then
        local customTags = {}
        for tag in settings.taskCustomTags:gmatch("[^,]+") do
            table.insert(customTags, { name = tag:gsub("^%s*(.-)%s*$", "%1"), allowOverwrite = true })
        end
        
        table.insert(config.tasks, {
            name = settings.taskCustomName,
            tags = customTags,
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
                
                -- Build CLI command
                local command = string.format('"%s" -f "%s" -c "%s"', 
                    cliPath, pathOrMessage, configPath)
                
                if exportSettings.verbose then
                    command = command .. ' -v'
                end
                
                if exportSettings.dryRun then
                    command = command .. ' --dry-run'
                end
                
                logger:info('Executing: ' .. tostring(command))
                
                -- Execute CLI
                local exitCode = LrTasks.execute(command)
                
                if exitCode == 0 then
                    logger:info('Successfully processed: ' .. tostring(pathOrMessage))
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