--[[----------------------------------------------------------------------------

UIStyleConstants.lua
UI style constants for ExifCraft

Provides font and layout constants used by the plugin UI.

------------------------------------------------------------------------------]]

local UI_STYLE_CONSTANTS = {
    L1Title = {
        font = '<system/bold>',
        color = 'black',
    },
    L2Title = {
        font = '<system/small/bold>',
        color = 'black',
    },
    L3Title = {
        font = '<system/regular>',
        color = 'black',
    },
    FieldTitle = {
        font = '<system/regular>',
        color = 'black',
    },
    SubTitle = {
        font = '<system/small>',
        color = 'grey',
    },
    Spacing = {
        titleToSubtitle = 2,
        Tight = 2,
        Compact = 4,
    },
    Dimensions = {
        LabelWidthDefault = 80,
        LabelWidthNarrow = 60,
        NumericFieldWidthChars = 8,
        ConfirmDialog = { width = 420, height = 120 },
    },
    Layout = {
        SplitLeftRatio = 0.4,
        Lines = {
            BasePrompt = 5,
            TaskPrompt = 3,
            Tags = 1,
        },
    },
}

return {
    UI_STYLE_CONSTANTS = UI_STYLE_CONSTANTS,
}


