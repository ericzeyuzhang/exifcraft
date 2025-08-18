--[[----------------------------------------------------------------------------

Utils.lua
Utility functions for ExifCraft v2

Provides helper functions for CLI execution, output parsing, and error handling.

------------------------------------------------------------------------------]]

local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrLogger = import 'LrLogger'
local dkjson = require 'dkjson'

local logger = LrLogger('ExifCraftV2Utils')
logger:enable("logfile")

local Utils = {}

-- Find the appropriate CLI executable for the current platform
function Utils.findCliExecutable()
    logger:info('=== Finding CLI executable ===')
    local pluginDir = _PLUGIN.path
    logger:info('Plugin directory: ' .. tostring(pluginDir))
    
    -- WIN_ENV is a global variable in Lightroom SDK that's true on Windows
    -- This is the official Adobe-recommended way to detect Windows vs macOS
    local platform = WIN_ENV and "win" or "mac"
    logger:info('Detected platform: ' .. platform)
    
    -- Try platform-specific binary first
    local platformBinary
    if WIN_ENV then
        platformBinary = LrPathUtils.child(pluginDir, 'bin/win/exifcraft.exe')
    else
        platformBinary = LrPathUtils.child(pluginDir, 'bin/mac/exifcraft')
    end
    
    logger:info('Checking platform-specific binary: ' .. platformBinary)
    if LrFileUtils.exists(platformBinary) then
        logger:info('Found platform-specific binary: ' .. platformBinary)
        return platformBinary
    else
        logger:info('Platform-specific binary not found')
    end
    
    -- Try Node.js fallback
    local nodeBinary = LrPathUtils.child(pluginDir, 'bin/node/cli.js')
    logger:info('Checking Node.js fallback: ' .. nodeBinary)
    if LrFileUtils.exists(nodeBinary) then
        logger:info('Found Node.js fallback: ' .. nodeBinary)
        -- For Node.js, we need to prepend 'node' command
        return 'node "' .. nodeBinary .. '"'
    else
        logger:info('Node.js fallback not found')
    end
    
    -- Try global installation
    local globalCmd = WIN_ENV and 'exifcraft.exe' or 'exifcraft'
    logger:info('Falling back to global installation: ' .. globalCmd)
    return globalCmd
end

-- Execute CLI command and capture output
function Utils.executeCliWithOutput(command)
    logger:info('Executing command: ' .. command)
    
    -- Create temporary files for output capture
    local tempDir = LrPathUtils.getStandardFilePath('temp')
    local outputFile = LrPathUtils.child(tempDir, 'exifcraft_output_' .. os.time() .. '.txt')
    local errorFile = LrPathUtils.child(tempDir, 'exifcraft_error_' .. os.time() .. '.txt')
    
    -- Modify command to capture output
    local fullCommand = command .. ' > "' .. outputFile .. '" 2> "' .. errorFile .. '"'
    
    local exitCode = LrTasks.execute(fullCommand)
    
    -- Read output files
    local output = ""
    local errorOutput = ""
    
    if LrFileUtils.exists(outputFile) then
        local file = io.open(outputFile, 'r')
        if file then
            output = file:read('*all') or ""
            file:close()
        end
        LrFileUtils.delete(outputFile)
    end
    
    if LrFileUtils.exists(errorFile) then
        local file = io.open(errorFile, 'r')
        if file then
            errorOutput = file:read('*all') or ""
            file:close()
        end
        LrFileUtils.delete(errorFile)
    end
    
    return exitCode, output, errorOutput
end

-- Parse CLI output to extract generated metadata
function Utils.parseCliOutput(output)
    local metadata = {}
    
    -- Try to parse JSON output first
    local success, parsed = pcall(dkjson.decode, output)
    if success and type(parsed) == 'table' then
        return parsed
    end
    
    -- Fallback to text parsing for simple output
    -- Look for common patterns in CLI output
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
    end
    
    return metadata
end

-- Validate CLI availability and version
function Utils.validateCli(cliPath)
    local command = '"' .. cliPath .. '" --version'
    local exitCode, output, errorOutput = Utils.executeCliWithOutput(command)
    
    if exitCode == 0 then
        logger:info('CLI validation successful: ' .. output)
        return true, output
    else
        logger:error('CLI validation failed. Exit code: ' .. exitCode)
        logger:error('Error output: ' .. errorOutput)
        return false, errorOutput
    end
end

-- Create a safe temporary directory
function Utils.createTempDirectory(prefix)
    local tempBase = LrPathUtils.getStandardFilePath('temp')
    local tempName = (prefix or 'ExifCraft') .. '_' .. os.time() .. '_' .. math.random(1000, 9999)
    local tempDir = LrPathUtils.child(tempBase, tempName)
    
    local success = LrFileUtils.createDirectory(tempDir)
    if success then
        logger:info('Created temporary directory: ' .. tempDir)
        return tempDir
    else
        error('Failed to create temporary directory: ' .. tempDir)
    end
end

-- Clean up temporary directory and all contents
function Utils.cleanupTempDirectory(tempDir)
    if tempDir and LrFileUtils.exists(tempDir) then
        logger:info('Cleaning up temporary directory: ' .. tempDir)
        LrFileUtils.delete(tempDir)
    end
end

-- Validate Ollama endpoint connectivity
function Utils.validateOllamaEndpoint(endpoint)
    -- Simple URL validation
    if not endpoint:match("^https?://") then
        return false, "Endpoint must start with http:// or https://"
    end
    
    -- TODO: Could add actual connectivity test here if needed
    return true, "Endpoint format is valid"
end

-- Format error message for user display
function Utils.formatErrorMessage(operation, error)
    local message = "ExifCraft Error during " .. operation .. ":\n\n"
    
    if type(error) == "string" then
        message = message .. error
    elseif type(error) == "table" and error.message then
        message = message .. error.message
    else
        message = message .. tostring(error)
    end
    
    return message
end

-- Log processing statistics
function Utils.logProcessingStats(totalPhotos, successCount, failureCount, startTime)
    local endTime = os.time()
    local duration = endTime - startTime
    
    logger:info('Processing completed:')
    logger:info('  Total photos: ' .. totalPhotos)
    logger:info('  Successful: ' .. successCount)
    logger:info('  Failed: ' .. failureCount)
    logger:info('  Duration: ' .. duration .. ' seconds')
    
    if totalPhotos > 0 then
        local successRate = (successCount / totalPhotos) * 100
        logger:info('  Success rate: ' .. string.format("%.1f", successRate) .. '%')
    end
end

return Utils
