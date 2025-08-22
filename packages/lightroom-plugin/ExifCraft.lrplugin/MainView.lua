--[[----------------------------------------------------------------------------

MainView.lua
Top-level view assembly for ExifCraft

This module composes the dialog from section builders and returns the root UI.

------------------------------------------------------------------------------]]

local LrView = import 'LrView'

local unpack_fn = table.unpack or unpack

local SectionView = require 'SectionView'

-- Use global logger
local logger = _G.ExifCraftLogger
if not logger then
    error('Global ExifCraftLogger not found. Make sure Init.lua is loaded first.')
end

local MainView = {}

local function createTwoColumnLayout(f, leftColumn, rightColumn)
    local layoutChildren = {
        f:column { spacing = f:control_spacing(), fill_horizontal = 0.4, fill_vertical = 1, leftColumn },
        f:column { spacing = f:control_spacing(), fill_horizontal = 0.6, fill_vertical = 1, rightColumn },
    }
    return f:row { spacing = f:control_spacing(), fill_horizontal = 1, fill_vertical = 1, unpack_fn(layoutChildren) }
end

function MainView.createMainDialog(f, dialogProps)
    local leftColumnChildren = {
        SectionView.buildAiModelSection(f),
        SectionView.buildGeneralSection(f, dialogProps),
    }

    local leftColumn = f:column { spacing = f:control_spacing(), fill_horizontal = 1, fill_vertical = 1, unpack_fn(leftColumnChildren) }

    local rightColumnChildren = { SectionView.buildTaskSection(f) }
    local rightColumn = f:column { spacing = f:control_spacing(), fill_horizontal = 1, fill_vertical = 1, unpack_fn(rightColumnChildren) }

    local content = f:column {
        bind_to_object = dialogProps,
        spacing = f:control_spacing(),
        fill_horizontal = 1,
        fill_vertical = 1,
        createTwoColumnLayout(f, leftColumn, rightColumn),
        f:separator { fill_horizontal = 1 },
        SectionView.buildBottomActions(f, dialogProps),
    }

    return f:column { fill = 1, fill_horizontal = 1, fill_vertical = 1, content }
end

return MainView


