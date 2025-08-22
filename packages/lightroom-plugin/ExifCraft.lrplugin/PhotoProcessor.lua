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
local LrPrefs = import 'LrPrefs'

-- Import local modules
local SystemUtils = require 'SystemUtils'
local Dkjson = require 'Dkjson'
local ConfigParser = require 'ConfigParser'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

-- Create configuration JSON file for CLI from raw JSON string
local function createConfigJsonForCLI(config_json, tempDir)
    logger:info('Creating configuration JSON for CLI from persistent config')
    
    if not config_json or config_json == '' then
        error('Configuration JSON string is empty or nil')
    end
    
    local config_file_path = LrPathUtils.child(tempDir, 'exifcraft_config.json')
    
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

-- Note: parseCliOutput function removed as it's not currently used
-- Will be re-implemented when metadata writing functionality is added

-- Process photos with given settings
local function process()
    logger:info('=== Starting ExifCraft Processing ===')
    
    local config, config_json = ConfigParser.getConfigFromPrefs()
    if not config or not config_json then
        LrDialogs.show_error('Configuration Error', 'No configuration found in preferences')
        return
    end
    
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
            -- Create config file from persistent JSON
            local configPath = createConfigJsonForCLI(config_json, tempDir)
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
                                    
                                    -- TODO: Implement metadata parsing and writing to Lightroom
                                    -- This feature will be implemented in a future version
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
}
