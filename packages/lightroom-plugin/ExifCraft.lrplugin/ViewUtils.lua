--[[----------------------------------------------------------------------------

ViewUtils.lua
UI helper functions for ExifCraft

Provides small utilities to build consistent view components.

------------------------------------------------------------------------------]]

local UIStyleConstants = require 'UIStyleConstants'

local unpack_fn = table.unpack or unpack

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ViewUtils = {}

-- Create a section header with an optional subtitle
-- Returns a column containing a prominent title and an optional subtitle
function ViewUtils.createSectionHeader(f, mainTitle, subTitle)
    assert(f ~= nil, 'viewFactory is required')
    assert(type(mainTitle) == 'string' and mainTitle ~= '', 'mainTitle must be a non-empty string')

    local children = {
        f:static_text {
            title = mainTitle,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.l1_title.font,
            fill_horizontal = 1,
        },
    }

    if subTitle and subTitle ~= '' then
        table.insert(children, f:static_text {
            title = subTitle,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.sub_title.font,
            fill_horizontal = 1,
        })
    end

    return f:column {
        spacing = UIStyleConstants.UI_STYLE_CONSTANTS.spacing.tight,
        fill_horizontal = 1,
        unpack_fn(children),
    }
end



return ViewUtils
