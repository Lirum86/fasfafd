--[[
    Lynix Config Manager v1.0
    Advanced Configuration System for Lynix GUI
    
    Features:
    - Create, Save, Load, Delete configurations
    - Automatic backup system
    - Error handling and validation
    - Memory-based storage (no localStorage)
    - Export/Import functionality
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Default configuration template
local DEFAULT_CONFIG = {
    -- Aimbot Settings
    aimbot = {
        fov_size = 200,
        aimbot_enabled = false,
        aim_part = "head",
        smoothness = 15,
        team_check = false,
        prediction = 0.12,
        show_fov = true,
        visibility_check = true
    },
    
    -- Silent Aim Settings
    silentAim = {
        silent_aim = false,
        show_fov = true,
        fov_size = 150,
        hit_chance = 100,
        target_part = "Head",
        team_check = false,
        target_line = false,
        bullet_tracer = false,
        bullet_tracer_color = {r = 255, g = 0, b = 0}
    },
    
    -- Gun Mods Settings
    gunMods = {
        no_recoil = false,
        no_spread = false,
        infinite_ammo = false,
        auto_firemode = false,
        bullet_penetration = false,
        no_muzzle_flash = false,
        infinite_stamina = false,
        infinite_adrenaline = false,
        no_suppression_blur = false,
        multi_bullet = false,
        bullet_penetration_bar = false,
        bullet_velocity = false,
        instant_bullet = false
    },
    
    -- Character Settings
    character = {
        TPerson = false,
        SpeedHack = false
    },
    
    -- ESP Settings
    esp = {
        enabled = false,
        boxes = true,
        skeleton = true,
        tracers = true,
        names = true,
        health = true,
        distance = true,
        weapon = true,
        outline = true,
        visibilityCheck = true,
        boxThickness = 1,
        skeletonThickness = 1,
        tracerThickness = 1,
        outlineThickness = 1,
        visibleColor = {r = 0, g = 255, b = 0},
        hiddenColor = {r = 255, g = 0, b = 0},
        basicColor = {r = 255, g = 255, b = 255},
        nameColor = {r = 255, g = 255, b = 255},
        healthColor = {r = 0, g = 255, b = 0},
        distanceColor = {r = 255, g = 255, b = 255},
        weaponColor = {r = 255, g = 255, b = 255},
        nameSize = 14,
        healthSize = 12,
        distanceSize = 12,
        weaponSize = 11
    },
    
    -- World Visuals Settings
    worldVisuals = {
        ambient = false,
        gradient = false,
        gradientcolor1 = {r = 90, g = 90, b = 90},
        gradientcolor2 = {r = 90, g = 90, b = 90}
    },
    
    -- Bullet Tracer Settings
    bulletTracer = {
        enabled = false,
        tracer_color = {r = 0, g = 255, b = 255},
        duration = 2,
        thickness = 0.35,
        max_distance = 1000,
        show_impact = true,
        impact_duration = 5,
        silent_aim_priority = true
    },
    
    -- GUI Settings
    gui = {
        watermark_visible = true,
        toggle_key = "RightShift"
    },
    
    -- Metadata
    meta = {
        name = "Default",
        created = 0,
        modified = 0,
        version = "1.0"
    }
}

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.configs = {}
    self.currentConfig = "Default"
    self.autoSaveEnabled = true
    self.backupConfigs = {}
    self.maxBackups = 5
    
    -- Initialize with default config
    self:createConfig("Default", true)
    
    return self
end

-- Utility Functions
local function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = deepCopy(value)
    end
    return copy
end

local function validateConfigName(name)
    if type(name) ~= "string" then
        return false, "Config name must be a string"
    end
    
    if #name < 1 or #name > 50 then
        return false, "Config name must be 1-50 characters"
    end
    
    if string.match(name, "[^%w%s%-_]") then
        return false, "Config name contains invalid characters"
    end
    
    return true, "Valid config name"
end

local function color3ToTable(color)
    if typeof(color) == "Color3" then
        return {
            r = math.floor(color.R * 255),
            g = math.floor(color.G * 255),
            b = math.floor(color.B * 255)
        }
    end
    return color
end

local function tableToColor3(colorTable)
    if type(colorTable) == "table" and colorTable.r and colorTable.g and colorTable.b then
        return Color3.fromRGB(colorTable.r, colorTable.g, colorTable.b)
    end
    return Color3.fromRGB(255, 255, 255)
end

-- Config Management Functions
function ConfigManager:getCurrentSettings()
    local currentSettings = deepCopy(DEFAULT_CONFIG)
    
    -- Get current settings from global variables
    if getgenv().aimbotSettings then
        currentSettings.aimbot.fov_size = getgenv().aimbotSettings.fov_size or DEFAULT_CONFIG.aimbot.fov_size
        currentSettings.aimbot.aimbot_enabled = getgenv().aimbotSettings.aimbot_enabled or DEFAULT_CONFIG.aimbot.aimbot_enabled
        currentSettings.aimbot.aim_part = getgenv().aimbotSettings.aim_part or DEFAULT_CONFIG.aimbot.aim_part
        currentSettings.aimbot.smoothness = getgenv().aimbotSettings.smoothness or DEFAULT_CONFIG.aimbot.smoothness
        currentSettings.aimbot.team_check = getgenv().aimbotSettings.team_check or DEFAULT_CONFIG.aimbot.team_check
        currentSettings.aimbot.prediction = getgenv().aimbotSettings.prediction or DEFAULT_CONFIG.aimbot.prediction
        currentSettings.aimbot.show_fov = getgenv().aimbotSettings.show_fov or DEFAULT_CONFIG.aimbot.show_fov
        currentSettings.aimbot.visibility_check = getgenv().aimbotSettings.visibility_check or DEFAULT_CONFIG.aimbot.visibility_check
    end
    
    if getgenv().silentAimSettings then
        currentSettings.silentAim.silent_aim = getgenv().silentAimSettings.silent_aim or DEFAULT_CONFIG.silentAim.silent_aim
        currentSettings.silentAim.show_fov = getgenv().silentAimSettings.show_fov or DEFAULT_CONFIG.silentAim.show_fov
        currentSettings.silentAim.fov_size = getgenv().silentAimSettings.fov_size or DEFAULT_CONFIG.silentAim.fov_size
        currentSettings.silentAim.hit_chance = getgenv().silentAimSettings.hit_chance or DEFAULT_CONFIG.silentAim.hit_chance
        currentSettings.silentAim.target_part = getgenv().silentAimSettings.target_part or DEFAULT_CONFIG.silentAim.target_part
        currentSettings.silentAim.team_check = getgenv().silentAimSettings.team_check or DEFAULT_CONFIG.silentAim.team_check
        currentSettings.silentAim.target_line = getgenv().silentAimSettings.target_line or DEFAULT_CONFIG.silentAim.target_line
        currentSettings.silentAim.bullet_tracer = getgenv().silentAimSettings.bullet_tracer or DEFAULT_CONFIG.silentAim.bullet_tracer
        currentSettings.silentAim.bullet_tracer_color = color3ToTable(getgenv().silentAimSettings.bullet_tracer_color) or DEFAULT_CONFIG.silentAim.bullet_tracer_color
    end
    
    if getgenv().gunModSettings then
        for key, value in pairs(getgenv().gunModSettings) do
            if currentSettings.gunMods[key] ~= nil then
                currentSettings.gunMods[key] = value
            end
        end
    end
    
    if getgenv().charSettings then
        for key, value in pairs(getgenv().charSettings) do
            if currentSettings.character[key] ~= nil then
                currentSettings.character[key] = value
            end
        end
    end
    
    if getgenv().espSettings then
        for key, value in pairs(getgenv().espSettings) do
            if currentSettings.esp[key] ~= nil then
                if typeof(value) == "Color3" then
                    currentSettings.esp[key] = color3ToTable(value)
                else
                    currentSettings.esp[key] = value
                end
            end
        end
    end
    
    if getgenv().worldVisuals then
        for key, value in pairs(getgenv().worldVisuals) do
            if currentSettings.worldVisuals[key] ~= nil then
                if typeof(value) == "Color3" then
                    currentSettings.worldVisuals[key] = color3ToTable(value)
                else
                    currentSettings.worldVisuals[key] = value
                end
            end
        end
    end
    
    if getgenv().bulletTracerSettings then
        for key, value in pairs(getgenv().bulletTracerSettings) do
            if currentSettings.bulletTracer[key] ~= nil then
                if typeof(value) == "Color3" then
                    currentSettings.bulletTracer[key] = color3ToTable(value)
                else
                    currentSettings.bulletTracer[key] = value
                end
            end
        end
    end
    
    return currentSettings
end

function ConfigManager:applySettings(settings)
    if not settings or type(settings) ~= "table" then
        return false, "Invalid settings data"
    end
    
    local success, err = pcall(function()
        -- Apply Aimbot Settings
        if settings.aimbot and getgenv().aimbotSettings then
            for key, value in pairs(settings.aimbot) do
                if getgenv().aimbotSettings[key] ~= nil then
                    getgenv().aimbotSettings[key] = value
                end
            end
        end
        
        -- Apply Silent Aim Settings
        if settings.silentAim and getgenv().silentAimSettings then
            for key, value in pairs(settings.silentAim) do
                if getgenv().silentAimSettings[key] ~= nil then
                    if key == "bullet_tracer_color" then
                        getgenv().silentAimSettings[key] = tableToColor3(value)
                    else
                        getgenv().silentAimSettings[key] = value
                    end
                end
            end
        end
        
        -- Apply Gun Mod Settings
        if settings.gunMods and getgenv().gunModSettings then
            for key, value in pairs(settings.gunMods) do
                if getgenv().gunModSettings[key] ~= nil then
                    getgenv().gunModSettings[key] = value
                end
            end
        end
        
        -- Apply Character Settings
        if settings.character and getgenv().charSettings then
            for key, value in pairs(settings.character) do
                if getgenv().charSettings[key] ~= nil then
                    getgenv().charSettings[key] = value
                end
            end
        end
        
        -- Apply ESP Settings
        if settings.esp and getgenv().espSettings then
            for key, value in pairs(settings.esp) do
                if getgenv().espSettings[key] ~= nil then
                    if type(value) == "table" and value.r and value.g and value.b then
                        getgenv().espSettings[key] = tableToColor3(value)
                    else
                        getgenv().espSettings[key] = value
                    end
                end
            end
        end
        
        -- Apply World Visuals Settings
        if settings.worldVisuals and getgenv().worldVisuals then
            for key, value in pairs(settings.worldVisuals) do
                if getgenv().worldVisuals[key] ~= nil then
                    if type(value) == "table" and value.r and value.g and value.b then
                        getgenv().worldVisuals[key] = tableToColor3(value)
                    else
                        getgenv().worldVisuals[key] = value
                    end
                end
            end
        end
        
        -- Apply Bullet Tracer Settings
        if settings.bulletTracer and getgenv().bulletTracerSettings then
            for key, value in pairs(settings.bulletTracer) do
                if getgenv().bulletTracerSettings[key] ~= nil then
                    if type(value) == "table" and value.r and value.g and value.b then
                        getgenv().bulletTracerSettings[key] = tableToColor3(value)
                    else
                        getgenv().bulletTracerSettings[key] = value
                    end
                end
            end
        end
    end)
    
    if not success then
        return false, "Failed to apply settings: " .. tostring(err)
    end
    
    return true, "Settings applied successfully"
end

function ConfigManager:createConfig(name, isDefault)
    local isValid, error = validateConfigName(name)
    if not isValid then
        return false, error
    end
    
    if self.configs[name] and not isDefault then
        return false, "Config with this name already exists"
    end
    
    local currentTime = tick()
    local configData = deepCopy(DEFAULT_CONFIG)
    
    if not isDefault then
        configData = self:getCurrentSettings()
    end
    
    configData.meta.name = name
    configData.meta.created = currentTime
    configData.meta.modified = currentTime
    configData.meta.version = "1.0"
    
    self.configs[name] = configData
    
    return true, "Config '" .. name .. "' created successfully"
end

function ConfigManager:saveConfig(name)
    if not name then
        name = self.currentConfig
    end
    
    if not self.configs[name] then
        return false, "Config '" .. name .. "' does not exist"
    end
    
    local success, err = pcall(function()
        -- Create backup before saving
        if self.configs[name] then
            self:createBackup(name)
        end
        
        local currentSettings = self:getCurrentSettings()
        currentSettings.meta = self.configs[name].meta
        currentSettings.meta.modified = tick()
        
        self.configs[name] = currentSettings
    end)
    
    if not success then
        return false, "Failed to save config: " .. tostring(err)
    end
    
    return true, "Config '" .. name .. "' saved successfully"
end

function ConfigManager:loadConfig(name)
    if not self.configs[name] then
        return false, "Config '" .. name .. "' does not exist"
    end
    
    local success, err = self:applySettings(self.configs[name])
    if not success then
        return false, err
    end
    
    self.currentConfig = name
    return true, "Config '" .. name .. "' loaded successfully"
end

function ConfigManager:deleteConfig(name)
    if name == "Default" then
        return false, "Cannot delete the default config"
    end
    
    if not self.configs[name] then
        return false, "Config '" .. name .. "' does not exist"
    end
    
    -- Create backup before deletion
    self:createBackup(name)
    
    self.configs[name] = nil
    
    if self.currentConfig == name then
        self.currentConfig = "Default"
    end
    
    return true, "Config '" .. name .. "' deleted successfully"
end

function ConfigManager:getConfigList()
    local configList = {}
    for name, _ in pairs(self.configs) do
        table.insert(configList, name)
    end
    
    -- Sort configs with Default first
    table.sort(configList, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a < b
    end)
    
    return configList
end

function ConfigManager:getConfigInfo(name)
    if not self.configs[name] then
        return nil
    end
    
    local config = self.configs[name]
    return {
        name = config.meta.name,
        created = config.meta.created,
        modified = config.meta.modified,
        version = config.meta.version,
        size = #HttpService:JSONEncode(config)
    }
end

function ConfigManager:createBackup(name)
    if not self.configs[name] then
        return false
    end
    
    if not self.backupConfigs[name] then
        self.backupConfigs[name] = {}
    end
    
    local backups = self.backupConfigs[name]
    
    -- Add current config as backup
    table.insert(backups, 1, deepCopy(self.configs[name]))
    
    -- Limit number of backups
    while #backups > self.maxBackups do
        table.remove(backups)
    end
    
    return true
end

function ConfigManager:restoreBackup(name, backupIndex)
    if not self.backupConfigs[name] or not self.backupConfigs[name][backupIndex] then
        return false, "Backup not found"
    end
    
    local backup = self.backupConfigs[name][backupIndex]
    self.configs[name] = deepCopy(backup)
    
    return true, "Backup restored successfully"
end

function ConfigManager:exportConfig(name)
    if not self.configs[name] then
        return nil, "Config '" .. name .. "' does not exist"
    end
    
    local success, jsonData = pcall(function()
        return HttpService:JSONEncode(self.configs[name])
    end)
    
    if not success then
        return nil, "Failed to export config"
    end
    
    return jsonData, "Config exported successfully"
end

function ConfigManager:importConfig(name, jsonData)
    local isValid, error = validateConfigName(name)
    if not isValid then
        return false, error
    end
    
    local success, configData = pcall(function()
        return HttpService:JSONDecode(jsonData)
    end)
    
    if not success then
        return false, "Invalid JSON data"
    end
    
    if type(configData) ~= "table" then
        return false, "Invalid config format"
    end
    
    -- Validate config structure
    if not configData.meta or not configData.meta.name then
        return false, "Invalid config metadata"
    end
    
    configData.meta.name = name
    configData.meta.modified = tick()
    
    self.configs[name] = configData
    
    return true, "Config '" .. name .. "' imported successfully"
end

function ConfigManager:resetToDefault()
    local success, err = self:loadConfig("Default")
    if not success then
        -- Recreate default config if it's corrupted
        self:createConfig("Default", true)
        return self:loadConfig("Default")
    end
    
    return success, err
end

function ConfigManager:getStorageInfo()
    local totalConfigs = 0
    local totalSize = 0
    
    for name, config in pairs(self.configs) do
        totalConfigs = totalConfigs + 1
        local success, jsonData = pcall(function()
            return HttpService:JSONEncode(config)
        end)
        if success then
            totalSize = totalSize + #jsonData
        end
    end
    
    return {
        totalConfigs = totalConfigs,
        totalSize = totalSize,
        averageSize = totalConfigs > 0 and math.floor(totalSize / totalConfigs) or 0,
        maxBackups = self.maxBackups,
        autoSaveEnabled = self.autoSaveEnabled
    }
end

function ConfigManager:cleanup()
    -- Clean up old backups
    for name, backups in pairs(self.backupConfigs) do
        while #backups > self.maxBackups do
            table.remove(backups)
        end
    end
    
    -- Force garbage collection
    collectgarbage("collect")
end

-- Auto-save functionality
function ConfigManager:enableAutoSave(interval)
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
    end
    
    interval = interval or 30 -- Default 30 seconds
    
    self.autoSaveConnection = task.spawn(function()
        while self.autoSaveEnabled do
            task.wait(interval)
            if self.currentConfig and self.configs[self.currentConfig] then
                self:saveConfig(self.currentConfig)
            end
        end
    end)
end

function ConfigManager:disableAutoSave()
    self.autoSaveEnabled = false
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
        self.autoSaveConnection = nil
    end
end

return ConfigManager
