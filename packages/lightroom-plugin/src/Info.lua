return {
    LrSdkVersion        = 12.0,
    LrToolkitIdentifier = "com.exifcraft.lightroom",
    LrPluginName        = "ExifCraft",
  
    -- 插件加载钩子：用来确认插件确实被执行
    LrInitPlugin = "Init.lua",
  
    -- 注意：每个菜单项“只需要” title 与 file；不要写 ["function"]
    LrLibraryMenuItems = {
      { title = "Process with ExifCraft", file = "Process.lua"  },
      { title = "ExifCraft Settings...",  file = "Settings.lua" },
    },
  
    VERSION = { major = 0, minor = 1, revision = 0 },
  }