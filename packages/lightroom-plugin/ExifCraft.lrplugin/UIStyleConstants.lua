--[[----------------------------------------------------------------------------

UIStyleConstants.lua
UI style constants for ExifCraft

Provides font and layout constants used by the plugin UI.

------------------------------------------------------------------------------]]

local UIStyleConstants = {}

UIStyleConstants.UI_STYLE_CONSTANTS = {
    l1_title = {
        font = '<system/bold>',
        color = 'black',
    },
    l2_title = {
        font = '<system/small/bold>',
        color = 'black',
    },
    l3_title = {
        font = '<system/regular>',
        color = 'black',
    },
    field_title = {
        font = '<system/regular>',
        color = 'black',
    },
    sub_title = {
        font = '<system/small>',
        color = 'grey',
    },
    spacing = {
        title_to_subtitle = 2,
        tight = 2,
        compact = 4,
    },
    dimensions = {
        label_width_default = 80,
        label_width_narrow = 60,
        numeric_field_width_chars = 8,
        confirm_dialog = { width = 420, height = 120 },
    },
    layout = {
        split_left_ratio = 0.4,
        lines = {
            base_prompt = 5,
            task_prompt = 3,
            tags = 1,
        },
    },
}

return UIStyleConstants

