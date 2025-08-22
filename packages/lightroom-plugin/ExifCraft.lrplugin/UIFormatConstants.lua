--[[----------------------------------------------------------------------------

UIFormatConstants.lua
UI format constants used for UI rendering and configuration

Defines available image formats grouped for UI presentation.

------------------------------------------------------------------------------]]

local UIFormatConstants = {}

UIFormatConstants.UI_FORMAT_CONSTANTS = {
    Standard = {
        { property = 'formatJpg',  format = 'jpg'  },
        { property = 'formatJpeg', format = 'jpeg' },
        { property = 'formatHeic', format = 'heic' },
        { property = 'formatHeif', format = 'heif' },
    },
    Raw = {
        { property = 'formatNef', format = 'nef' },
        { property = 'formatRaf', format = 'raf' },
        { property = 'formatCr2', format = 'cr2' },
        { property = 'formatCr3', format = 'cr3' },
        { property = 'formatArw', format = 'arw' },
        { property = 'formatDng', format = 'dng' },
        { property = 'formatRaw', format = 'raw' },
    },
    Tiff = {
        { property = 'formatTiff', format = 'tiff' },
        { property = 'formatTif',  format = 'tif'  },
    },
}


return UIFormatConstants
