--[[----------------------------------------------------------------------------

ViewUtils.lua
UI helper functions for ExifCraft

Provides small utilities to build consistent view components.

------------------------------------------------------------------------------]]

local UIStyleConstants = require 'constants.ui.UIStyleConstants'

local unpackFn = table.unpack or unpack

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local ViewUtils = {}

-- Create a section header with an optional subtitle
-- Returns a column containing a prominent title and an optional subtitle
function ViewUtils.createSectionHeader(viewFactory, mainTitle, subTitle)
    assert(viewFactory ~= nil, 'viewFactory is required')
    assert(type(mainTitle) == 'string' and mainTitle ~= '', 'mainTitle must be a non-empty string')

    local children = {
        viewFactory:static_text {
            title = mainTitle,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.L1Title.font,
            fill_horizontal = 1,
        },
    }

    if subTitle and subTitle ~= '' then
        table.insert(children, viewFactory:static_text {
            title = subTitle,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.SubTitle.font,
            fill_horizontal = 1,
        })
    end

    return viewFactory:column {
        spacing = UIStyleConstants.UI_STYLE_CONSTANTS.Spacing.titleToSubtitle,
        fill_horizontal = 1,
        unpackFn(children),
    }
end

-- Wrap provided content inside a group_box with sensible defaults
-- children: array/table of view items to be placed inside the group box
function ViewUtils.wrapInGroupBox(viewFactory, children)
    assert(viewFactory ~= nil, 'viewFactory is required')
    assert(type(children) == 'table', 'children must be a table (array) of view items')

    local props = {
        title = '',
        spacing = viewFactory:control_spacing(),
        fill_horizontal = 1,
    }

    for i = 1, #children do
        table.insert(props, children[i])
    end

    return viewFactory:group_box(props)
end

return ViewUtils


