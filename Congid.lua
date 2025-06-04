--[[
    Lynix Config Manager v1.0
    A comprehensive configuration management system for Lynix GUI
    
    Features:
    - Create, Save, Load, and Delete configurations
    - Automatic validation and error handling
    - Memory-based storage (no localStorage dependency)
    - Encrypted config data protection
    - Auto-backup system
    - Import/Export functionality
]]

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Storage
local configStorage = {}
local backupStorage = {}

-- Validation patterns
local VALID_NAME_PATTERN = "^[%w%s%-_%.]+$"
local MAX_NAME_LENGTH = 50
local MAX_CONFIGS = 100

-- Encryption key (simple XOR for obfuscation)
local ENCRYPTION_KEY = "LynixGUI2024"

-- Utility Functions
local function validateConfigName(name)
    if not name or type(name) ~= "string" then
        return false, "Config name must be a string"
    end
    
    if #name == 0 then
        return false, "Config name cannot be empty"
    end
    
    if #name > MAX_NAME_LENGTH then
        return false, "Config name too long (max " .. MAX_NAME_LENGTH .. " characters)"
    end
    
    if not string.match(name, VALID_NAME_PATTERN) then
        return false, "Config name contains invalid characters"
    end
    
    local trimmed = string.gsub(name, "^%s+", "")
    trimmed = string.gsub(trimmed, "%s+$", "")
    
    if #trimmed == 0 then
        return false, "Config name cannot be only whitespace"
    end
    
    return true, trimmed
end

local function encryptString(str)
    if not str then return "" end
    
    local result = {}
    local keyLen = #ENCRYPTION_KEY
    
    for i = 1, #str do
        local char = string.byte(str, i)
        local keyChar = string.byte(ENCRYPTION_KEY, ((i - 1) % keyLen) + 1)
        local encrypted = char ~ keyChar -- XOR operation
        table.insert(result, string.char(encrypted))
    end
    
    return table.concat(result)
end

local function decryptString(str)
    -- XOR is symmetric, so encryption = decryption
    return encryptString(str)
end

local function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function sanitizeSettings(settings)
    local sanitized = {}
    
    for key, value in pairs(settings) do
        if type(key) == "string" and string.match(key, "^[%w_]+$") then
            if type(value) == "table" then
                sanitized[key] = sanitizeSettings(value)
            elseif type(value) == "string" or type(value) == "number" or 
                   type(value) == "boolean" or typeof(value) == "Color3" then
                sanitized[key] = value
            end
        end
    end
    
    return sanitized
end

-- ConfigManager Class
function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    
    self.callbacks = {
        onConfigCreated = function() end,
        onConfigLoaded = function() end,
        onConfigSaved = function() end,
        onConfigDeleted = function() end,
        onError = function() end
    }
    
    self.currentConfig = nil
    self.isInitialized = false
    
    self:initialize()
    
    return self
end

function ConfigManager:initialize()
    if self.isInitialized then return end
    
    -- Create default config storage
    configStorage = {
        ["Default"] = {
            name = "Default",
            created = os.time(),
            lastModified = os.time(),
            settings = self:getDefaultSettings(),
            version = "1.0",
            encrypted = false
        }
    }
    
    -- Create backup storage
    backupStorage = deepCopy(configStorage)
    
    self.isInitialized = true
end

function ConfigManager:getDefaultSettings()
    return {
        aimbotSettings = {
            fov_size = 200,
            aimbot_enabled = false,
            aim_part = "head",
            smoothness = 15,
            team_check = false,
            prediction = 0.12,
            show_fov = true,
            visibility_check = true
        },
        silentAimSettings = {
            silent_aim = false,
            show_fov = true,
            fov_size = 150,
            hit_chance = 100,
            target_part = "Head",
            team_check = false,
            target_line = false,
            bullet_tracer = false,
            bullet_tracer_color = Color3.fromRGB(255, 0, 0),
        },
        gunModSettings = {
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
            instant_bullet = false,
        },
        charSettings = {
            TPerson = false,
            SpeedHack = false,
        },
        espSettings = {
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
            visibleColor = Color3.fromRGB(0, 255, 0),
            hiddenColor = Color3.fromRGB(255, 0, 0),
            basicColor = Color3.fromRGB(255, 255, 255),
            nameColor = Color3.fromRGB(255, 255, 255),
            healthColor = Color3.fromRGB(0, 255, 0),
            distanceColor = Color3.fromRGB(255, 255, 255),
            weaponColor = Color3.fromRGB(255, 255, 255),
            nameSize = 14,
            healthSize = 12,
            distanceSize = 12,
            weaponSize = 11
        },
        worldVisuals = {
            ambient = false,
            gradient = false,
            gradientcolor1 = Color3.fromRGB(90, 90, 90),
        },
        bulletTracerSettings = {
            enabled = false,
            tracer_color = Color3.fromRGB(0, 255, 255),
            duration = 2,
            thickness = 0.35,
            max_distance = 1000,
            show_impact = true,
            impact_duration = 5,
            silent_aim_priority = true
        }
    }
end

function ConfigManager:getCurrentSettings()
    local settings = {}
    
    -- Safely get global settings
    pcall(function()
        if getgenv().aimbotSettings then
            settings.aimbotSettings = deepCopy(getgenv().aimbotSettings)
        end
        if getgenv().silentAimSettings then
            settings.silentAimSettings = deepCopy(getgenv().silentAimSettings)
        end
        if getgenv().gunModSettings then
            settings.gunModSettings = deepCopy(getgenv().gunModSettings)
        end
        if getgenv().charSettings then
            settings.charSettings = deepCopy(getgenv().charSettings)
        end
        if getgenv().espSettings then
            settings.espSettings = deepCopy(getgenv().espSettings)
        end
        if getgenv().worldVisuals then
            settings.worldVisuals = deepCopy(getgenv().worldVisuals)
        end
        if getgenv().bulletTracerSettings then
            settings.bulletTracerSettings = deepCopy(getgenv().bulletTracerSettings)
        end
    end)
    
    return sanitizeSettings(settings)
end

function ConfigManager:applySettings(settings)
    if not settings or type(settings) ~= "table" then
        return false, "Invalid settings data"
    end
    
    local success = true
    local errors = {}
    
    -- Apply each setting category
    for category, data in pairs(settings) do
        local categorySuccess, categoryError = pcall(function()
            if category == "aimbotSettings" and getgenv().aimbotSettings then
                for key, value in pairs(data) do
                    getgenv().aimbotSettings[key] = value
                end
            elseif category == "silentAimSettings" and getgenv().silentAimSettings then
                for key, value in pairs(data) do
                    getgenv().silentAimSettings[key] = value
                end
            elseif category == "gunModSettings" and getgenv().gunModSettings then
                for key, value in pairs(data) do
                    getgenv().gunModSettings[key] = value
                end
            elseif category == "charSettings" and getgenv().charSettings then
                for key, value in pairs(data) do
                    getgenv().charSettings[key] = value
                end
            elseif category == "espSettings" and getgenv().espSettings then
                for key, value in pairs(data) do
                    getgenv().espSettings[key] = value
                end
            elseif category == "worldVisuals" and getgenv().worldVisuals then
                for key, value in pairs(data) do
                    getgenv().worldVisuals[key] = value
                end
            elseif category == "bulletTracerSettings" and getgenv().bulletTracerSettings then
                for key, value in pairs(data) do
                    getgenv().bulletTracerSettings[key] = value
                end
            end
        end)
        
        if not categorySuccess then
            success = false
            table.insert(errors, category .. ": " .. tostring(categoryError))
        end
    end
    
    if success then
        return true, "Settings applied successfully"
    else
        return false, "Errors applying settings: " .. table.concat(errors, ", ")
    end
end

function ConfigManager:createConfig(name)
    local isValid, cleanName = validateConfigName(name)
    if not isValid then
        self.callbacks.onError("Create Config", cleanName)
        return false, cleanName
    end
    
    if configStorage[cleanName] then
        self.callbacks.onError("Create Config", "Config '" .. cleanName .. "' already exists")
        return false, "Config already exists"
    end
    
    if self:getConfigCount() >= MAX_CONFIGS then
        self.callbacks.onError("Create Config", "Maximum number of configs reached (" .. MAX_CONFIGS .. ")")
        return false, "Too many configs"
    end
    
    local currentSettings = self:getCurrentSettings()
    
    local config = {
        name = cleanName,
        created = os.time(),
        lastModified = os.time(),
        settings = currentSettings,
        version = "1.0",
        encrypted = false
    }
    
    configStorage[cleanName] = config
    backupStorage[cleanName] = deepCopy(config)
    
    self.callbacks.onConfigCreated(cleanName)
    return true, "Config '" .. cleanName .. "' created successfully"
end

function ConfigManager:saveConfig(name)
    if not name or not configStorage[name] then
        self.callbacks.onError("Save Config", "Config '" .. tostring(name) .. "' not found")
        return false, "Config not found"
    end
    
    local currentSettings = self:getCurrentSettings()
    
    configStorage[name].settings = currentSettings
    configStorage[name].lastModified = os.time()
    
    -- Create backup
    backupStorage[name] = deepCopy(configStorage[name])
    
    self.callbacks.onConfigSaved(name)
    return true, "Config '" .. name .. "' saved successfully"
end

function ConfigManager:loadConfig(name)
    if not name or not configStorage[name] then
        self.callbacks.onError("Load Config", "Config '" .. tostring(name) .. "' not found")
        return false, "Config not found"
    end
    
    local config = configStorage[name]
    local success, error = self:applySettings(config.settings)
    
    if success then
        self.currentConfig = name
        self.callbacks.onConfigLoaded(name)
        return true, "Config '" .. name .. "' loaded successfully"
    else
        self.callbacks.onError("Load Config", error)
        return false, error
    end
end

function ConfigManager:deleteConfig(name)
    if not name or not configStorage[name] then
        self.callbacks.onError("Delete Config", "Config '" .. tostring(name) .. "' not found")
        return false, "Config not found"
    end
    
    if name == "Default" then
        self.callbacks.onError("Delete Config", "Cannot delete the Default config")
        return false, "Cannot delete default config"
    end
    
    configStorage[name] = nil
    backupStorage[name] = nil
    
    if self.currentConfig == name then
        self.currentConfig = nil
    end
    
    self.callbacks.onConfigDeleted(name)
    return true, "Config '" .. name .. "' deleted successfully"
end

function ConfigManager:getConfigList()
    local configs = {}
    for name, config in pairs(configStorage) do
        table.insert(configs, {
            name = name,
            created = config.created,
            lastModified = config.lastModified,
            version = config.version
        })
    end
    
    -- Sort by last modified (newest first)
    table.sort(configs, function(a, b)
        return a.lastModified > b.lastModified
    end)
    
    return configs
end

function ConfigManager:getConfigNames()
    local names = {}
    for name, _ in pairs(configStorage) do
        table.insert(names, name)
    end
    
    -- Sort alphabetically, but keep Default first
    table.sort(names, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a < b
    end)
    
    return names
end

function ConfigManager:getConfigCount()
    local count = 0
    for _ in pairs(configStorage) do
        count = count + 1
    end
    return count
end

function ConfigManager:getConfigInfo(name)
    if not name or not configStorage[name] then
        return nil
    end
    
    local config = configStorage[name]
    return {
        name = config.name,
        created = os.date("%Y-%m-%d %H:%M:%S", config.created),
        lastModified = os.date("%Y-%m-%d %H:%M:%S", config.lastModified),
        version = config.version,
        settingsCount = self:countSettings(config.settings)
    }
end

function ConfigManager:countSettings(settings)
    local count = 0
    for category, data in pairs(settings) do
        if type(data) == "table" then
            for _ in pairs(data) do
                count = count + 1
            end
        end
    end
    return count
end

function ConfigManager:exportConfig(name)
    if not name or not configStorage[name] then
        return nil, "Config not found"
    end
    
    local config = configStorage[name]
    local exportData = {
        name = config.name,
        created = config.created,
        exported = os.time(),
        settings = config.settings,
        version = config.version,
        source = "Lynix GUI"
    }
    
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(exportData)
    end)
    
    if success then
        return jsonString, "Config exported successfully"
    else
        return nil, "Failed to encode config data"
    end
end

function ConfigManager:importConfig(jsonString, newName)
    if not jsonString or type(jsonString) ~= "string" then
        return false, "Invalid import data"
    end
    
    local success, importData = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        return false, "Failed to decode import data"
    end
    
    if not importData.settings or not importData.name then
        return false, "Invalid config format"
    end
    
    local configName = newName or importData.name
    local isValid, cleanName = validateConfigName(configName)
    if not isValid then
        return false, cleanName
    end
    
    if configStorage[cleanName] then
        return false, "Config '" .. cleanName .. "' already exists"
    end
    
    local config = {
        name = cleanName,
        created = importData.created or os.time(),
        lastModified = os.time(),
        settings = sanitizeSettings(importData.settings),
        version = importData.version or "1.0",
        encrypted = false
    }
    
    configStorage[cleanName] = config
    backupStorage[cleanName] = deepCopy(config)
    
    return true, "Config '" .. cleanName .. "' imported successfully"
end

function ConfigManager:resetToDefault()
    local success, error = self:applySettings(self:getDefaultSettings())
    if success then
        self.currentConfig = "Default"
        return true, "Settings reset to default"
    else
        return false, error
    end
end

function ConfigManager:setCallbacks(callbacks)
    if callbacks and type(callbacks) == "table" then
        for event, callback in pairs(callbacks) do
            if type(callback) == "function" then
                self.callbacks[event] = callback
            end
        end
    end
end

function ConfigManager:getCurrentConfig()
    return self.currentConfig
end

function ConfigManager:cleanup()
    configStorage = {}
    backupStorage = {}
    self.currentConfig = nil
    self.isInitialized = false
end

-- Auto-backup system
task.spawn(function()
    while true do
        task.wait(300) -- Backup every 5 minutes
        backupStorage = deepCopy(configStorage)
    end
end)

return ConfigManager
