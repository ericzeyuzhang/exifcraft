--[[----------------------------------------------------------------------------

Info.lua
ExifCraft v2 - AI-powered EXIF metadata crafting tool for Lightroom

This plugin provides library menu items that use AI to generate and write
EXIF metadata to images, with integrated configuration.

------------------------------------------------------------------------------]]

return {
    LrSdkVersion = 12.0,
    LrSdkMinimumVersion = 6.0,
    LrPluginName = 'ExifCraft v2',
    LrToolkitIdentifier = 'com.exifcraft.lightroom.v2',
    LrPluginInfoUrl = 'https://github.com/yourusername/exifcraft',
    
    LrInitPlugin = 'Init.lua',
    LrShutdownPlugin = nil,
    LrEnablePlugin = nil,
    LrDisablePlugin = nil,

    -- Library module menu (Library > Plug-in Extras)
    LrLibraryMenuItems = {
        { title = "Process with ExifCraft v2", file = "Main.lua" },
    },

    -- File menu (File > Plug-in Extras)
    LrExportMenuItems = {
        { title = "Process with ExifCraft v2", file = "Main.lua" },
    },

    VERSION = { major = 0, minor = 0, revision = 1, build = 122 },
}
