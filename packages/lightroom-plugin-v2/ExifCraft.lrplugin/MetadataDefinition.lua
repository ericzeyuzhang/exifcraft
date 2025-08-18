--[[----------------------------------------------------------------------------

MetadataDefinition.lua
Defines custom metadata fields for ExifCraft AI-generated content

------------------------------------------------------------------------------]]

return {
    metadataFieldsForPhotos = {
        {
            id = 'aiTitle',
            title = 'AI Generated Title',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiDescription',
            title = 'AI Generated Description',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiKeywords',
            title = 'AI Generated Keywords',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiProcessingStatus',
            title = 'AI Processing Status',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
    },

    schemaVersion = 1,
}
