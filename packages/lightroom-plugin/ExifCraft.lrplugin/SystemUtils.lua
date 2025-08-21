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
    local plugin_dir = _PLUGIN.path
    logger:info('Plugin directory: ' .. tostring(plugin_dir))

    -- WIN_ENV is true on Windows in Lightroom SDK
    local platform = WIN_ENV and "win" or "mac"
    logger:info('Detected platform: ' .. platform)

    -- Try platform-specific binary first
    local platform_binary
    if WIN_ENV then
        platform_binary = LrPathUtils.child(plugin_dir, 'bin/win/exifcraft.exe')
    else
        platform_binary = LrPathUtils.child(plugin_dir, 'bin/mac/exifcraft')
    end

    logger:info('Checking platform-specific binary: ' .. platform_binary)
    if LrFileUtils.exists(platform_binary) then
        logger:info('Found platform-specific binary: ' .. platform_binary)
        return platform_binary
    else
        logger:info('Platform-specific binary not found')
    end

    -- Try Node.js fallback
    local node_binary = LrPathUtils.child(plugin_dir, 'bin/node/cli.js')
    logger:info('Checking Node.js fallback: ' .. node_binary)
    if LrFileUtils.exists(node_binary) then
        logger:info('Found Node.js fallback: ' .. node_binary)
        -- For Node.js, we need to prepend 'node' command
        return 'node "' .. node_binary .. '"'
    else
        logger:info('Node.js fallback not found')
    end

    -- Try global installation
    local global_cmd = WIN_ENV and 'exifcraft.exe' or 'exifcraft'
    logger:info('Falling back to global installation: ' .. global_cmd)
    return global_cmd
end

-- Create a safe temporary directory
function SystemUtils.createTempDirectory(prefix)
    local temp_base = LrPathUtils.get_standard_file_path('temp')
    local temp_name = (prefix or 'ExifCraft') .. '_' .. os.time() .. '_' .. math.random(1000, 9999)
    local temp_dir = LrPathUtils.child(temp_base, temp_name)

    local success = LrFileUtils.create_directory(temp_dir)
    if success then
        logger:info('Created temporary directory: ' .. temp_dir)
        return temp_dir
    else
        error('Failed to create temporary directory: ' .. temp_dir)
    end
end

-- Clean up temporary directory and all contents
function SystemUtils.cleanupTempDirectory(temp_dir)
    if temp_dir and LrFileUtils.exists(temp_dir) then
        logger:info('Cleaning up temporary directory: ' .. temp_dir)
        LrFileUtils.delete(temp_dir)
    end
end

-- Log processing statistics
function SystemUtils.logProcessingStats(total_photos, success_count, failure_count, start_time)
    local end_time = os.time()
    local duration = end_time - start_time

    logger:info('Processing completed:')
    logger:info('  Total photos: ' .. total_photos)
    logger:info('  Successful: ' .. success_count)
    logger:info('  Failed: ' .. failure_count)
    logger:info('  Duration: ' .. duration .. ' seconds')

    if total_photos > 0 then
        local success_rate = (success_count / total_photos) * 100
        logger:info('  Success rate: ' .. string.format('%.1f', success_rate) .. '%')
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

 

