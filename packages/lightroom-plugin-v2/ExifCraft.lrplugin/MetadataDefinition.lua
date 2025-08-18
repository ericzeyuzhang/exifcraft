--[[----------------------------------------------------------------------------

MetadataDefinition.lua
Defines custom metadata fields for ExifCraft AI-generated content

This file defines custom metadata fields that can be used to store
AI-generated content and processing status in Lightroom.

------------------------------------------------------------------------------]]

return {
    metadataFieldsForPhotos = {
        -- Standard AI-generated content fields
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
        
        -- Custom task fields
        {
            id = 'aiCustomTask',
            title = 'AI Custom Task Result',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        
        -- Processing status and configuration
        {
            id = 'aiProcessingStatus',
            title = 'AI Processing Status',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiProcessingDate',
            title = 'AI Processing Date',
            dataType = 'date',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiModelUsed',
            title = 'AI Model Used',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiProviderUsed',
            title = 'AI Provider Used',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        
        -- Task-specific fields
        {
            id = 'aiTaskTitleEnabled',
            title = 'AI Task: Title Enabled',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiTaskDescriptionEnabled',
            title = 'AI Task: Description Enabled',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiTaskKeywordsEnabled',
            title = 'AI Task: Keywords Enabled',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
        {
            id = 'aiTaskCustomEnabled',
            title = 'AI Task: Custom Enabled',
            dataType = 'string',
            searchable = true,
            browsable = true,
        },
    },

    schemaVersion = 2,
}
