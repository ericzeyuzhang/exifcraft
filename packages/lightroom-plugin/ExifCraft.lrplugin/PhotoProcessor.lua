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
local ConfigProvider = require 'ConfigProvider'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

-- Utility: join table values as string
local function joinTableValues(tbl, sep)
    local result = {}
    for i, v in ipairs(tbl or {}) do
        result[i] = tostring(v)
    end
    return table.concat(result, sep or ', ')
end

-- Create configuration JSON file for CLI from raw JSON string
local function createConfigJsonForCLI(config_json, tempDir)
    logger:info('Creating configuration JSON for CLI from persistent config')
    logger:info('Temp directory for CLI configuration: ' .. tostring(tempDir))
    
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
    
    local config, config_json = ConfigProvider.fromPrefs()
    if not config or not config_json then
        LrDialogs.message('Configuration Error', 'No configuration found in preferences', 'error')
        return
    end
    
    logger:info('Loaded configuration from preferences')
    logger:info('Config flags - verbose: ' .. tostring(config.verbose) .. ', dryRun: ' .. tostring(config.dryRun))
    if type(config.imageFormats) == 'table' then
        logger:info('Configured image formats: ' .. joinTableValues(config.imageFormats, ', '))
    else
        logger:info('Configured image formats: (none)')
    end
    
    -- Get selected photos
    local catalog = LrApplication.activeCatalog()
    if not catalog then
        logger:error('Failed to get active catalog')
        LrDialogs.message('Error', 'Failed to get active catalog', 'error')
        return
    end
    
    local photos = catalog:getTargetPhotos() or {}
    logger:info('Found ' .. #photos .. ' selected photo(s)')
    
    if #photos == 0 then
        logger:warn('No photos selected')
        LrDialogs.message('No Photos Selected', 'Please select one or more photos to process.', 'warning')
        return
    end

    -- Start processing
    LrTasks.startAsyncTask(function()
        logger:info('Creating temp directory for processing')
        local tempDir = SystemUtils.createTempDirectory('ExifCraft')
        logger:info('Temp directory created: ' .. tostring(tempDir))
        
        local totalPhotos = #photos
        local successCount = 0
        local failureCount = 0
        local startTime = os.time()
        
        local progressScope = LrProgressScope({
            title = 'ExifCraft AI Processing',
        })
        
        -- Pre-fetch photo paths to avoid yielding issues in pcall
        logger:info('Pre-fetching photo paths for ' .. totalPhotos .. ' photos to avoid yielding issues')
        local photoPaths = {}
        for i, photo in ipairs(photos) do
            photoPaths[i] = photo:getRawMetadata('path')
            logger:info('Pre-fetched path for photo ' .. i .. ': ' .. tostring(photoPaths[i]))
        end
        logger:info('Completed pre-fetching paths for all photos')
        
        logger:info('Starting pcall execution for photo processing')
        local success, errorMessage = pcall(function()
            -- Create config file from persistent JSON
            local configPath = createConfigJsonForCLI(config_json, tempDir)
            local cliPath = SystemUtils.findCliExecutable()
            logger:info('Resolved CLI executable path: ' .. tostring(cliPath))
            logger:info('Resolved configuration path: ' .. tostring(configPath))
            
            logger:info('Processing ' .. totalPhotos .. ' photos')
            progressScope:setPortionComplete(0, totalPhotos)
            
            for i, photo in ipairs(photos) do
                local photoStartClock = os.clock()
                local photoPath = photoPaths[i]
                local fileName = LrPathUtils.leafName(photoPath) or ('Photo_' .. i)
                
                progressScope:setCaption('Processing: ' .. fileName)
                logger:info(string.format('Starting photo %d/%d: %s', i, totalPhotos, tostring(fileName)))
                
                -- Check if file exists and is supported
                if not LrFileUtils.exists(photoPath) then
                    logger:error('Photo file not found: ' .. photoPath)
                    failureCount = failureCount + 1
                else
                    -- Check file format
                    local fileExt = LrPathUtils.extension(photoPath):lower():gsub('^%.*', '')
                    logger:info('Detected file extension: ' .. tostring(fileExt))
                    local supportedFormats = {}
                    if type(config.imageFormats) == 'table' then
                        for _, format in ipairs(config.imageFormats) do
                            local trimmedFormat = format:lower():match('^%s*(.-)%s*$')
                            trimmedFormat = trimmedFormat:gsub('^%.*', '')
                            table.insert(supportedFormats, trimmedFormat)
                        end
                    end
                    if i == 1 then
                        logger:info('Supported formats (normalized): ' .. joinTableValues(supportedFormats, ', '))
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
                        logger:info('Skipping unsupported file. Supported formats are: ' .. joinTableValues(supportedFormats, ', '))
                        failureCount = failureCount + 1
                    else
                        -- Build CLI command
                        local command = string.format('"%s" -f "%s" -c "%s"', 
                            cliPath, photoPath, configPath)
                        
                        if config.verbose then
                            command = command .. ' -v'
                        end
                        
                        if config.dryRun then
                            command = command .. ' --dry-run'
                        end
                        
                        logger:info('Executing: ' .. command)
                        
                        -- Execute CLI and capture output
                        local handle = io.popen(command .. ' 2>&1')  -- Redirect stderr to stdout
                        if handle then
                            local output = handle:read("*a") or ""
                            local success, reason, exitCode = handle:close()
                            
                            -- Log CLI output
                            if output and output ~= "" then
                                logger:info('CLI output for ' .. fileName .. ':')
                                -- Split output into lines for better readability
                                for line in output:gmatch("([^\r\n]*)\r?\n?") do
                                    if line and line ~= "" then
                                        logger:info('  > ' .. line)
                                    end
                                end
                            else
                                logger:info('CLI produced no output for ' .. fileName)
                            end
                            
                            -- Determine actual exit code
                            local actualExitCode = 0
                            if not success then
                                if reason == "exit" then
                                    actualExitCode = exitCode or 1
                                else
                                    actualExitCode = 1
                                end
                            end
                            
                            logger:info('CLI finished with exit code: ' .. tostring(actualExitCode))
                            
                            if actualExitCode == 0 then
                                logger:info('Successfully processed: ' .. fileName)
                                successCount = successCount + 1
                            else
                                logger:error('Failed to process: ' .. fileName .. ' (exit code: ' .. actualExitCode .. ')')
                                failureCount = failureCount + 1
                            end
                        else
                            logger:error('Failed to execute CLI command for: ' .. fileName)
                            failureCount = failureCount + 1
                        end
                    end
                end
                
                progressScope:setPortionComplete(i, totalPhotos)
                local photoElapsed = (os.clock() - photoStartClock)
                logger:info(string.format('Finished %s in %.3f seconds (%d/%d)', tostring(fileName), photoElapsed, i, totalPhotos))
                logger:info(string.format('Progress: %d/%d complete', i, totalPhotos))
            end
            logger:info('Completed processing loop for all photos')
        end)
        
        -- Cleanup
        logger:info('Starting cleanup of temp resources')
        SystemUtils.cleanupTempDirectory(tempDir)
        logger:info('Cleanup completed for temp directory: ' .. tostring(tempDir))
        
        -- Log processing statistics
        SystemUtils.logProcessingStats(totalPhotos, successCount, failureCount, startTime)
        
        progressScope:done()
        
        if not success then
            local errorMsg = tostring(errorMessage or 'Unknown error')
            logger:error('Processing error occurred: ' .. errorMsg)
            LrDialogs.message('ExifCraft Processing Error', errorMsg, 'error')
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
                LrDialogs.message('ExifCraft Processing Summary', message, 'info')
            else
                LrDialogs.message('ExifCraft Processing Complete', 
                    string.format('Successfully processed %d image(s)!', successCount), 'info')
            end
        end
        
        logger:info('=== ExifCraft Processing Completed ===')
    end)
end

-- Export module
return {
    process = process,
}
