--[[----------------------------------------------------------------------------

ExportFilter.lua
Main export filter implementation for ExifCraft v2

------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local LrLogger = import 'LrLogger'
local LrColor = import 'LrColor'
local bind = LrView.bind

-- Logger setup
local logger = LrLogger('ExifCraftV2')
logger:enable("logfile")
logger:info('ExifCraft v2 Export Filter loaded')

-- Default settings
local DEFAULT_SETTINGS = {
    ollamaEndpoint = 'http://localhost:11434',
    ollamaModel = 'llama3.2-vision',
    writeTitle = true,
    writeDescription = true,
    writeKeywords = true,
    preserveOriginal = true,
    basePrompt = 'Analyze this image and provide metadata.',
    temperature = 0.7,
    verbose = false,
}

-- Export filter provider table
local exportFilterProvider = {
    exportPresetFields = { 
        "ollamaEndpoint", "ollamaModel", "temperature", 
        "writeTitle", "writeDescription", "writeKeywords", 
        "preserveOriginal", "basePrompt", "verbose"
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

-- Create the UI section for the export dialog
function exportFilterProvider.sectionForFilterInDialog(viewFactory, propertyTable)
    logger:info('Creating ExifCraft AI configuration UI')
    
    local result = {
        title = "ExifCraft AI Metadata",
        synopsis = "AI-powered EXIF metadata generation",
        
        viewFactory:column {
            spacing = viewFactory:control_spacing(),
            
            -- Ollama Settings Group
            viewFactory:group_box {
                title = "Ollama Settings",
                spacing = viewFactory:control_spacing(),
                
                viewFactory:row {
                    spacing = viewFactory:label_spacing(),
                    
                    viewFactory:static_text {
                        title = "Endpoint:",
                        width = 80,
                    },
                    
                    viewFactory:edit_field {
                        value = bind 'ollamaEndpoint',
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
                        value = bind 'ollamaModel',
                        immediate = true,
                        width_in_chars = 25,
                        fill_horizontal = 1,
                    },
                },
                
                viewFactory:row {
                    spacing = viewFactory:label_spacing(),
                    
                    viewFactory:static_text {
                        title = "Temperature:",
                        width = 80,
                    },
                    
                    viewFactory:slider {
                        value = bind 'temperature',
                        integral = false,
                        min = 0.0,
                        max = 2.0,
                        width = 150,
                    },
                    
                    viewFactory:static_text {
                        title = bind 'temperature',
                        width = 40,
                    },
                },
            },
            
            -- Metadata Options Group
            viewFactory:group_box {
                title = "Metadata Options",
                spacing = viewFactory:control_spacing(),
                
                viewFactory:checkbox {
                    title = "Generate Title",
                    value = bind 'writeTitle',
                },
                
                viewFactory:checkbox {
                    title = "Generate Description",
                    value = bind 'writeDescription',
                },
                
                viewFactory:checkbox {
                    title = "Generate Keywords",
                    value = bind 'writeKeywords',
                },
                
                viewFactory:checkbox {
                    title = "Preserve Original Files",
                    value = bind 'preserveOriginal',
                },
            },
            
            -- Advanced Options Group
            viewFactory:group_box {
                title = "Advanced Options",
                spacing = viewFactory:control_spacing(),
                
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
                
                viewFactory:checkbox {
                    title = "Verbose Logging",
                    value = bind 'verbose',
                },
            },
        }
    }
    
    logger:info('ExifCraft AI configuration UI created successfully')
    return result
end

-- Alternative function names that Lightroom might call
function exportFilterProvider.sectionsForTopOfDialog(viewFactory, propertyTable)
    logger:info('Creating export dialog UI sections (alternative)')
    return { exportFilterProvider.sectionForFilterInDialog(viewFactory, propertyTable) }
end

-- Synopsis and section control functions
function exportFilterProvider.hideSections()
    return false
end

function exportFilterProvider.showSections()
    return true
end

function exportFilterProvider.updateExportSettings(propertyTable)
    logger:info('updateExportSettings called')
end

function exportFilterProvider.updateFilterSettings(propertyTable)
    logger:info('updateFilterSettings called')
end

-- Safe Utils loading
local Utils
local success, result = pcall(require, 'Utils')
if success then
    Utils = result
else
    -- Fallback Utils if loading fails
    Utils = {
        createTempDirectory = function(prefix)
            local tempDir = LrPathUtils.getStandardFilePath('temp')
            return LrPathUtils.child(tempDir, (prefix or 'ExifCraft') .. '_' .. os.time())
        end,
        findCliExecutable = function()
            return 'exifcraft'  -- Fallback to global command
        end,
        cleanupTempDirectory = function(tempDir)
            if tempDir and LrFileUtils.exists(tempDir) then
                LrFileUtils.delete(tempDir)
            end
        end,
        logProcessingStats = function(total, success, failed, startTime)
            local duration = os.time() - startTime
            logger:info('Processing stats: ' .. success .. '/' .. total .. ' successful, ' .. failed .. ' failed, ' .. duration .. 's')
        end
    }
end

-- Create configuration JSON for CLI
local function createConfigJson(settings, tempDir)
    logger:info('Creating configuration JSON')
    
    local dkjson = require 'dkjson'
    
    local config = {
        tasks = {},
        aiModel = {
            provider = 'ollama',
            endpoint = settings.ollamaEndpoint or 'http://localhost:11434',
            model = settings.ollamaModel or 'llama3.2-vision',
            options = {
                temperature = tonumber(settings.temperature) or 0.7,
            },
        },
        imageFormats = { 'jpg', 'jpeg', 'tiff', 'tif', 'png', 'dng', 'cr2', 'nef', 'arw' },
        preserveOriginal = settings.preserveOriginal ~= false,
        basePrompt = settings.basePrompt or 'Analyze this image and provide metadata.',
    }
    
    -- Add tasks based on settings
    if settings.writeTitle ~= false then
        table.insert(config.tasks, {
            name = 'Generate Title',
            tags = {{ name = 'ImageDescription', allowOverwrite = true }},
            prompt = 'Generate a concise, descriptive title for this image.',
        })
    end
    
    if settings.writeDescription ~= false then
        table.insert(config.tasks, {
            name = 'Generate Description',
            tags = {{ name = 'Caption-Abstract', allowOverwrite = true }},
            prompt = 'Provide a detailed description of this image.',
        })
    end
    
    if settings.writeKeywords ~= false then
        table.insert(config.tasks, {
            name = 'Generate Keywords',
            tags = {{ name = 'Keywords', allowOverwrite = true }},
            prompt = 'Generate relevant keywords for this image, separated by commas.',
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
    if not exportSettings.ollamaEndpoint or exportSettings.ollamaEndpoint == '' then
        LrDialogs.showError('Configuration Error', 'Ollama endpoint is required')
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