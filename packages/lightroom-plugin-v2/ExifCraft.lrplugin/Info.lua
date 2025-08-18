--[[----------------------------------------------------------------------------

Info.lua
ExifCraft v2 - AI-powered EXIF metadata crafting tool for Lightroom

This plugin provides an export filter that uses AI to generate and write
EXIF metadata to images during export, with GUI configuration.

------------------------------------------------------------------------------]]

return {
    LrSdkVersion = 12.0,
    LrSdkMinimumVersion = 6.0,
    LrPluginName = 'ExifCraft v2',
    LrToolkitIdentifier = 'com.exifcraft.lightroom.export.v2',
    LrPluginInfoUrl = 'https://github.com/yourusername/exifcraft',
    
    LrInitPlugin = 'Init.lua',
    LrShutdownPlugin = nil,
    LrEnablePlugin = nil,
    LrDisablePlugin = nil,

    LrExportFilterProvider = {
        title = 'ExifCraft AI Metadata',
        file = 'ExportFilter.lua',
        id = 'ExifCraftFilter',
    },

    LrMetadataProvider = 'MetadataDefinition.lua',

    VERSION = { major = 0, minor = 0, revision = 1, build = 22 },
}
