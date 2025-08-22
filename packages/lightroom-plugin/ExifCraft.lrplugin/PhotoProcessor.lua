--[[----------------------------------------------------------------------------

Processor.lua
Core processing logic for ExifCraft

This module handles the main photo processing workflow, CLI integration,
and metadata writing to Lightroom.

------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'

-- Import local modules
local SystemUtils = require 'SystemUtils'
local Dkjson = require 'Dkjson'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

-- Create configuration JSON for CLI
local function createConfigJsonForCLI(settings, tempDir)
    logger:info('Creating configuration JSON for CLI')
    
    -- Settings is already in unified format, no conversion needed
    local config_file_path = LrPathUtils.child(tempDir, 'exifcraft_config.json')
    local config_json = Dkjson.encode(settings, { indent = true })
    
    local file = io.open(config_file_path, 'w')
    if file then
        file:write(config_json)
        file:close()
        logger:info('CLI configuration written to: ' .. config_file_path)
        return config_file_path
    else
        error('Failed to write config file: ' .. tostring(config_file_path))
    end
end

-- Parse CLI output and extract metadata
local function parseCliOutput(output)
    logger:info('Parsing CLI output')
    
    if not output or output == '' then
        logger:warning('Empty CLI output')
        return {}
    end
    
    local success, result = pcall(Dkjson.decode, output)
    if not success then
        logger:error('Failed to parse CLI output as JSON: ' .. tostring(result))
        return {}
    end
    
    if type(result) ~= 'table' then
        logger:error('CLI output is not a valid JSON object')
        return {}
    end
    
    logger:info('Successfully parsed CLI output')
    return result
end

-- Write metadata to Lightroom photo
local function writeMetadataToLightroom(photo, metadata)
    logger:info('Writing metadata to Lightroom photo: ' .. tostring(photo:get_raw_metadata('file_name')))
    
    local success = true
    
    -- Write each task result to the appropriate metadata fields
    for taskName, taskResult in pairs(metadata) do
        if type(taskResult) == 'string' and taskResult ~= '' then
            logger:info('Writing ' .. taskName .. ': ' .. taskResult)
            
            -- Map task names to Lightroom metadata fields
            local fieldMap = {
                ['Image Title'] = 'title',
                ['Image Description'] = 'caption',
                ['Keywords'] = 'keywords',
                ['Location'] = 'location',
                ['Subject'] = 'subject',
                ['Photography Style'] = 'style',
                ['Mood/Atmosphere'] = 'mood',
                ['Technical Details'] = 'technicalNotes',
                ['Custom Task 1'] = 'custom1',
                ['Custom Task 2'] = 'custom2',
            }
            
            local fieldName = fieldMap[taskName]
            if fieldName then
                if fieldName == 'keywords' then
                    -- Handle keywords as array
                    local keywords = {}
                    for keyword in taskResult:gmatch('[^,]+') do
                        table.insert(keywords, keyword:match('^%s*(.-)%s*$')) -- trim whitespace
                    end
                    photo:setRawMetadata(fieldName, keywords)
                else
                    photo:setRawMetadata(fieldName, taskResult)
                end
                logger:info('Updated ' .. fieldName .. ' for photo')
            else
                logger:warning('Unknown task name: ' .. taskName)
            end
        end
    end
    
    return success
end

-- Process photos with given settings
local function process(config)
    logger:info('=== Starting ExifCraft Processing ===')
    
    -- Get selected photos
    local catalog = LrApplication.activeCatalog()
    if not catalog then
        logger:error('Failed to get active catalog')
        LrDialogs.show_error('Error', 'Failed to get active catalog')
        return
    end
    
    local photos = catalog:getTargetPhotos() or {}
    logger:info('Found ' .. #photos .. ' selected photo(s)')
    
    if #photos == 0 then
        logger:warn('No photos selected')
        LrDialogs.show_warning('No Photos Selected', 'Please select one or more photos to process.')
        return
    end
    
    -- Basic validation
    if not config.aiModel.endpoint or config.aiModel.endpoint == '' then
        LrDialogs.show_error('Configuration Error', 'AI endpoint is required')
        return
    end
    
    -- Start processing
    LrTasks.startAsyncTask(function()
        local tempDir = SystemUtils.createTempDirectory('ExifCraft')
        
        local totalPhotos = #photos
        local successCount = 0
        local failureCount = 0
        local startTime = os.time()
        
        local progressScope = LrProgressScope({
            title = 'ExifCraft AI Processing',
        })
        
        local success, errorMessage = pcall(function()
            -- Create config file
            local configPath = createConfigJsonForCLI(config, tempDir)
            local cliPath = SystemUtils.findCliExecutable()
            
            logger:info('Processing ' .. totalPhotos .. ' photos')
            progressScope:setPortionComplete(0, totalPhotos)
            
            for i, photo in ipairs(photos) do
                local photoPath = photo:getRawMetadata('path')
                local fileName = photo:getRawMetadata('fileName')
                
                progressScope:setCaption('Processing: ' .. fileName)
                
                -- Check if file exists and is supported
                if not LrFileUtils.exists(photoPath) then
                    logger:error('Photo file not found: ' .. photoPath)
                    failureCount = failureCount + 1
                else
                    -- Check file format
                    local fileExt = LrPathUtils.extension(photoPath):lower():gsub('^%.*', '')
                    local supportedFormats = {}
                    if type(config.imageFormats) == 'table' then
                        for _, format in ipairs(config.imageFormats) do
                            local trimmedFormat = format:lower():match('^%s*(.-)%s*$')
                            trimmedFormat = trimmedFormat:gsub('^%.*', '')
                            table.insert(supportedFormats, trimmedFormat)
                        end
                    end
                    local isSupported = false
                    for _, format in ipairs(supportedFormats) do
                        if fileExt == format then
                            isSupported = true
                            break
                        end
                    end
                    
                    if not isSupported then
                        logger:warning('Unsupported file format: ' .. fileExt .. ' for ' .. fileName)
                        failureCount = failureCount + 1
                    else
                        -- Build CLI command
                        local outputFile = LrPathUtils.child(tempDir, 'output_' .. os.time() .. '_' .. i .. '.json')
                        local command = string.format('"%s" -f "%s" -c "%s" --output "%s"', 
                            cliPath, photoPath, configPath, outputFile)
                        
                        if config.verbose then
                            command = command .. ' -v'
                        end
                        
                        if config.dryRun then
                            command = command .. ' --dry-run'
                        end
                        
                        logger:info('Executing: ' .. command)
                        
                        -- Execute CLI
                        local exitCode = LrTasks.execute(command)
                        
                        if exitCode == 0 then
                            logger:info('Successfully processed: ' .. fileName)
                            
                            -- Read CLI output and write metadata to Lightroom
                            if LrFileUtils.exists(outputFile) then
                                local file = io.open(outputFile, 'r')
                                if file then
                                    local output = file:read('*all') or ""
                                    file:close()
                                    
                                    -- Parse output and write to Lightroom
                                    local metadata = parseCliOutput(output)
                                    if metadata and next(metadata) then
                                        local writeSuccess = writeMetadataToLightroom(photo, metadata)
                                        if writeSuccess then
                                            logger:info('Metadata successfully written to Lightroom')
                                        else
                                            logger:error('Failed to write metadata to Lightroom')
                                        end
                                    else
                                        logger:warning('No metadata found in CLI output')
                                    end
                                else
                                    logger:error('Failed to read CLI output file: ' .. outputFile)
                                end
                                
                                -- Clean up output file
                                LrFileUtils.delete(outputFile)
                            else
                                logger:warning('CLI output file not found: ' .. outputFile)
                            end
                            
                            successCount = successCount + 1
                        else
                            logger:error('Failed to process: ' .. fileName .. ' (exit code: ' .. exitCode .. ')')
                            failureCount = failureCount + 1
                        end
                    end
                end
                
                progressScope:setPortionComplete(i, totalPhotos)
            end
        end)
        
        -- Cleanup
        SystemUtils.cleanupTempDirectory(tempDir)
        
        -- Log processing statistics
        SystemUtils.logProcessingStats(totalPhotos, successCount, failureCount, startTime)
        
        progressScope:done()
        
        if not success then
            LrDialogs.showError('ExifCraft Processing Error', tostring(errorMessage))
            logger:error('Processing error: ' .. tostring(errorMessage))
        else
            logger:info('Processing completed. Success: ' .. successCount .. ', Failed: ' .. failureCount)
            
            if failureCount > 0 then
                local message = string.format(
                    'Processing completed with some issues:\n\n' ..
                    'Successfully processed: %d/%d images\n' ..
                    'Failed: %d images\n\n' ..
                    'Check the plugin logs for detailed information.',
                    successCount, totalPhotos, failureCount
                )
                LrDialogs.showInfo('ExifCraft Processing Summary', message)
            else
                LrDialogs.showInfo('ExifCraft Processing Complete', 
                    string.format('Successfully processed %d image(s)!', successCount))
            end
        end
        
        logger:info('=== ExifCraft Processing Completed ===')
    end)
end

-- Export module
return {
    process = process,
    parse_cli_output = parseCliOutput,
    write_metadata_to_lightroom = writeMetadataToLightroom,
}
