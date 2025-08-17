return {
    LrSdkVersion        = 12.0,
    LrToolkitIdentifier = "com.exifcraft.lightroom",
    LrPluginName        = "ExifCraft",
  
    LrInitPlugin = "Init.lua",
  
    LrLibraryMenuItems = {
      { title = "Process with ExifCraft", file = "Process.lua"  },
      { title = "ExifCraft Settings...",  file = "Settings.lua" },
    },
  
    VERSION = { major = 0, minor = 1, revision = 0 },
}