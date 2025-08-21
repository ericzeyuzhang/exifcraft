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
        spacing = UIStyleConstants.UI_STYLE_CONSTANTS.spacing.title_to_subtitle,
        fill_horizontal = 1,
        unpack_fn(children),
    }
end

-- Wrap provided content inside a group_box with sensible defaults
-- children: array/table of view items to be placed inside the group box
function ViewUtils.wrapInGroupBox(f, children)
    assert(f ~= nil, 'f is required')
    assert(type(children) == 'table', 'children must be a table (array) of view items')

    local props = {
        title = '',
        spacing = f:control_spacing(),
        fill_horizontal = 1,
    }

    for i = 1, #children do
        table.insert(props, children[i])
    end

    return f:group_box(props)
end

return ViewUtils


