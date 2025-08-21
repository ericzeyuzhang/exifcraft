--[[----------------------------------------------------------------------------

SystemUtils.lua
System and general-purpose utilities for ExifCraft

Provides helper functions for CLI discovery, temp directory management,
processing statistics, string operations, and basic type conversions.

------------------------------------------------------------------------------]]

local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local SystemUtils = {}

-- Find the appropriate CLI executable for the current platform
function SystemUtils.findCliExecutable()
    logger:info('=== Finding CLI executable ===')
    local pluginDir = _PLUGIN.path
    logger:info('Plugin directory: ' .. tostring(pluginDir))

    -- WIN_ENV is true on Windows in Lightroom SDK
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

-- Create a safe temporary directory
function SystemUtils.createTempDirectory(prefix)
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
function SystemUtils.cleanupTempDirectory(tempDir)
    if tempDir and LrFileUtils.exists(tempDir) then
        logger:info('Cleaning up temporary directory: ' .. tempDir)
        LrFileUtils.delete(tempDir)
    end
end

-- Log processing statistics
function SystemUtils.logProcessingStats(totalPhotos, successCount, failureCount, startTime)
    local endTime = os.time()
    local duration = endTime - startTime

    logger:info('Processing completed:')
    logger:info('  Total photos: ' .. totalPhotos)
    logger:info('  Successful: ' .. successCount)
    logger:info('  Failed: ' .. failureCount)
    logger:info('  Duration: ' .. duration .. ' seconds')

    if totalPhotos > 0 then
        local successRate = (successCount / totalPhotos) * 100
        logger:info('  Success rate: ' .. string.format('%.1f', successRate) .. '%')
    end
end

-- Split string by separator (defaults to whitespace)
function SystemUtils.split(input, sep)
    local result = {}
    sep = sep or "%s"
    for str in string.gmatch(input, '([^' .. sep .. ']+)') do
        table.insert(result, str)
    end
    return result
end

-- Convert a value into a boolean in a permissive way
function SystemUtils.toBoolean(value)
    if type(value) == 'string' then
        return value == 'true'
    end
    return value == true
end

return SystemUtils


