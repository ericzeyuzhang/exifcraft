--[[----------------------------------------------------------------------------

ViewUtils.lua
UI helper functions for ExifCraft

Provides small utilities to build consistent view components.

------------------------------------------------------------------------------]]

local UIStyleConstants = require 'UIStyleConstants'
local LrView = import 'LrView'

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


-- Create a row of format checkboxes from definitions
-- defs: array of { title=string, bind=string, tooltip=string }
function ViewUtils.createFormatCheckboxRow(f, defs)
    assert(f ~= nil, 'viewFactory is required')
    assert(type(defs) == 'table', 'defs must be a table')

    local children = {}
    for _, def in ipairs(defs) do
        table.insert(children, f:checkbox {
            title = def.title,
            font = UIStyleConstants.UI_STYLE_CONSTANTS.field_title.font,
            tooltip = def.tooltip,
            value = LrView.bind(def.bind),
            checked_value = true,
            unchecked_value = false,
        })
    end

    return f:row {
        spacing = f:control_spacing(),
        fill_horizontal = 1,
        unpack_fn(children),
    }
end



return ViewUtils
