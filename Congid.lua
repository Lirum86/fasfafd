
--[[
    Lynix GUI Config System v1.0
    
    Features:
    - Automatic config saving/loading
    - JSON export/import functionality  
    - Element state persistence
    - Multiple config profiles
    - Config validation and error handling
    - Auto-save functionality
    - Config backup system
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Config Manager Class
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(library)
    local self = setmetatable({}, ConfigManager)
    self.library = library
    self.configs = {}
    self.currentConfig = "Default"
    self.autoSaveEnabled = true
    self.autoSaveInterval = 30 -- seconds
    self.lastSave = tick()
    self.configHistory = {} -- For backup/restore
    self.maxHistoryEntries = 10
    self.autoSaveConnection = nil
    
    -- Initialize default config
    self:createDefaultConfig()
    self:startAutoSave()
    
    return self
end

function ConfigManager:createDefaultConfig()
    self.configs[self.currentConfig] = {
        name = self.currentConfig,
        timestamp = tick(),
        version = "1.0.0",
        elements = {},
        gui = {
            position = {0.5, -450, 0.5, -300}, -- UDim2 as table
            visible = true,
            minimized = false
        },
        keybinds = {
            toggle = "RightShift"
        },
        watermark = {
            visible = true,
            position = {1, -340, 0, 20}
        }
    }
end

function ConfigManager:startAutoSave()
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
    end
    
    self.autoSaveConnection = RunService.Heartbeat:Connect(function()
        if self.autoSaveEnabled and tick() - self.lastSave >= self.autoSaveInterval then
            self:saveCurrentState()
            self.lastSave = tick()
        end
    end)
end

function ConfigManager:registerElement(elementPath, element)
    -- elementPath format: "TabName.SectionName.ElementName"
    if not elementPath or not element then
        warn("ConfigManager: Invalid element registration")
        return false
    end
    
    -- Store reference for easy access
    if not self.library.configElements then
        self.library.configElements = {}
    end
    
    self.library.configElements[elementPath] = element
    
    -- Save initial state
    self:saveElementState(elementPath, element)
    
    return true
end

function ConfigManager:saveElementState(elementPath, element)
    if not element or not element.value then return end
    
    local config = self.configs[self.currentConfig]
    if not config then return end
    
    -- Convert Color3 to RGB table for JSON compatibility
    local value = element.value
    if typeof(value) == "Color3" then
        value = {
            r = math.floor(value.R * 255),
            g = math.floor(value.G * 255),
            b = math.floor(value.B * 255)
        }
    end
    
    config.elements[elementPath] = {
        type = element.type,
        value = value,
        timestamp = tick()
    }
end

function ConfigManager:loadElementState(elementPath, element)
    local config = self.configs[self.currentConfig]
    if not config or not config.elements[elementPath] then return false end
    
    local savedElement = config.elements[elementPath]
    local value = savedElement.value
    
    -- Convert RGB table back to Color3
    if savedElement.type == "colorpicker" and type(value) == "table" and value.r then
        value = Color3.fromRGB(value.r, value.g, value.b)
    end
    
    -- Apply the value to the element
    element.value = value
    
    -- Update UI representation based on element type
    self:updateElementUI(element, value)
    
    return true
end

function ConfigManager:updateElementUI(element, value)
    if not element.container then return end
    
    if element.type == "toggle" then
        self:updateToggleUI(element.container, value)
    elseif element.type == "slider" then
        self:updateSliderUI(element.container, value)
    elseif element.type == "dropdown" then
        self:updateDropdownUI(element.container, value)
    elseif element.type == "colorpicker" then
        self:updateColorPickerUI(element.container, value)
    elseif element.type == "keybind" then
        self:updateKeybindUI(element.container, value)
    end
end

function ConfigManager:updateToggleUI(container, value)
    local toggleBG = container:FindFirstChild("Frame")
    if not toggleBG then return end
    
    local toggleButton = toggleBG:FindFirstChild("Frame")
    if not toggleButton then return end
    
    local newPos = value and UDim2.new(0, 27, 0, 2) or UDim2.new(0, 2, 0, 2)
    local newColor = value and self.library.THEME.Primary or self.library.THEME.Border
    
    toggleButton.Position = newPos
    toggleBG.BackgroundColor3 = newColor
end

function ConfigManager:updateSliderUI(container, value)
    local valueLabel = nil
    local sliderFill = nil
    
    -- Find value label and slider fill
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("TextLabel") and string.find(child.Text or "", "^%d") then
            valueLabel = child
        elseif child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
            local fill = child:FindFirstChild("Frame")
            if fill then
                sliderFill = fill
            end
        end
    end
    
    if valueLabel then
        valueLabel.Text = tostring(value)
    end
    
    -- Note: For proper slider update, you'd need min/max values stored
    -- This is a simplified version
end

function ConfigManager:updateDropdownUI(container, value)
    local dropdownBtn = container:FindFirstChild("TextButton")
    if not dropdownBtn then return end
    
    local selectedLabel = dropdownBtn:FindFirstChild("TextLabel")
    if selectedLabel then
        selectedLabel.Text = tostring(value)
    end
end

function ConfigManager:updateColorPickerUI(container, value)
    local colorPreview = nil
    
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
            colorPreview = child
            break
        end
    end
    
    if colorPreview then
        colorPreview.BackgroundColor3 = value
    end
end

function ConfigManager:updateKeybindUI(container, value)
    local keybindBtn = container:FindFirstChild("TextButton")
    if keybindBtn then
        keybindBtn.Text = tostring(value)
    end
end

function ConfigManager:saveCurrentState()
    if not self.library then return false end
    
    local config = self.configs[self.currentConfig]
    if not config then return false end
    
    -- Save GUI state
    if self.library.mainFrame then
        local pos = self.library.mainFrame.Position
        config.gui.position = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset}
        config.gui.visible = self.library.isVisible
        config.gui.minimized = self.library.isMinimized
    end
    
    -- Save keybinds
    if self.library.keybinds then
        config.keybinds = {}
        for key, value in pairs(self.library.keybinds) do
            config.keybinds[key] = value
        end
    end
    
    -- Save watermark state
    if self.library.watermarkManager then
        config.watermark.visible = self.library.watermarkManager.isVisible
        if self.library.watermarkManager.container then
            local pos = self.library.watermarkManager.container.Position
            config.watermark.position = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset}
        end
    end
    
    -- Save all registered elements
    if self.library.configElements then
        for path, element in pairs(self.library.configElements) do
            self:saveElementState(path, element)
        end
    end
    
    config.timestamp = tick()
    
    -- Add to history for backup
    self:addToHistory(config)
    
    return true
end

function ConfigManager:loadConfig(configName)
    if not configName or not self.configs[configName] then
        warn("ConfigManager: Config '" .. tostring(configName) .. "' not found")
        return false
    end
    
    local config = self.configs[configName]
    self.currentConfig = configName
    
    -- Load GUI state
    if config.gui and self.library.mainFrame then
        local pos = config.gui.position
        if pos then
            self.library.mainFrame.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
        end
        
        if config.gui.minimized then
            self.library:hide()
        else
            self.library:show()
        end
    end
    
    -- Load keybinds
    if config.keybinds then
        self.library.keybinds = {}
        for key, value in pairs(config.keybinds) do
            self.library.keybinds[key] = value
        end
        self.library:setupKeybinds()
    end
    
    -- Load watermark state
    if config.watermark and self.library.watermarkManager then
        self.library.watermarkManager:setVisible(config.watermark.visible)
        if config.watermark.position and self.library.watermarkManager.container then
            local pos = config.watermark.position
            self.library.watermarkManager.container.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
        end
    end
    
    -- Load all element states
    if config.elements and self.library.configElements then
        for path, element in pairs(self.library.configElements) do
            if config.elements[path] then
                self:loadElementState(path, element)
                -- Trigger callback with loaded value
                if element.callback then
                    pcall(element.callback, element.value)
                end
            end
        end
    end
    
    self.library:Notify("Config Loaded", "Successfully loaded config: " .. configName, "success")
    return true
end

function ConfigManager:createConfig(configName)
    if not configName or configName == "" then
        warn("ConfigManager: Invalid config name")
        return false
    end
    
    if self.configs[configName] then
        warn("ConfigManager: Config '" .. configName .. "' already exists")
        return false
    end
    
    -- Save current state first
    self:saveCurrentState()
    
    -- Create new config based on current state
    self.configs[configName] = self:deepCopy(self.configs[self.currentConfig])
    self.configs[configName].name = configName
    self.configs[configName].timestamp = tick()
    
    self.library:Notify("Config Created", "Created new config: " .. configName, "success")
    return true
end

function ConfigManager:deleteConfig(configName)
    if not configName or configName == "Default" then
        warn("ConfigManager: Cannot delete default config")
        return false
    end
    
    if not self.configs[configName] then
        warn("ConfigManager: Config '" .. configName .. "' not found")
        return false
    end
    
    -- If deleting current config, switch to default
    if self.currentConfig == configName then
        self:loadConfig("Default")
    end
    
    self.configs[configName] = nil
    self.library:Notify("Config Deleted", "Deleted config: " .. configName, "info")
    return true
end

function ConfigManager:renameConfig(oldName, newName)
    if not oldName or not newName or oldName == "Default" then
        return false
    end
    
    if not self.configs[oldName] or self.configs[newName] then
        return false
    end
    
    self.configs[newName] = self.configs[oldName]
    self.configs[newName].name = newName
    self.configs[oldName] = nil
    
    if self.currentConfig == oldName then
        self.currentConfig = newName
    end
    
    return true
end

function ConfigManager:exportConfig(configName)
    configName = configName or self.currentConfig
    
    if not self.configs[configName] then
        warn("ConfigManager: Config not found for export")
        return nil
    end
    
    -- Save current state before export
    if configName == self.currentConfig then
        self:saveCurrentState()
    end
    
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode({
            config = self.configs[configName],
            metadata = {
                exportDate = tick(),
                version = "1.0.0",
                library = "Lynix GUI"
            }
        })
    end)
    
    if success then
        self.library:Notify("Config Exported", "Config exported to JSON", "success")
        return jsonString
    else
        warn("ConfigManager: Failed to export config - " .. tostring(jsonString))
        self.library:Notify("Export Failed", "Failed to export config", "error")
        return nil
    end
end

function ConfigManager:importConfig(jsonString, configName)
    if not jsonString or jsonString == "" then
        warn("ConfigManager: Invalid JSON string")
        return false
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        warn("ConfigManager: Failed to parse JSON - " .. tostring(data))
        self.library:Notify("Import Failed", "Invalid JSON format", "error")
        return false
    end
    
    if not data.config then
        warn("ConfigManager: Invalid config format")
        self.library:Notify("Import Failed", "Invalid config format", "error")
        return false
    end
    
    configName = configName or data.config.name or "Imported_" .. math.random(1000, 9999)
    
    -- Validate config structure
    if not self:validateConfig(data.config) then
        warn("ConfigManager: Config validation failed")
        self.library:Notify("Import Failed", "Config validation failed", "error")
        return false
    end
    
    self.configs[configName] = data.config
    self.configs[configName].name = configName
    self.configs[configName].timestamp = tick()
    
    self.library:Notify("Config Imported", "Successfully imported: " .. configName, "success")
    return true
end

function ConfigManager:validateConfig(config)
    if type(config) ~= "table" then return false end
    
    -- Check required fields
    local requiredFields = {"elements", "gui", "keybinds"}
    for _, field in ipairs(requiredFields) do
        if not config[field] then
            return false
        end
    end
    
    -- Validate elements structure
    if type(config.elements) ~= "table" then return false end
    
    for path, element in pairs(config.elements) do
        if type(element) ~= "table" or not element.type or element.value == nil then
            return false
        end
    end
    
    return true
end

function ConfigManager:addToHistory(config)
    local historyCopy = self:deepCopy(config)
    table.insert(self.configHistory, 1, historyCopy)
    
    -- Keep only max entries
    while #self.configHistory > self.maxHistoryEntries do
        table.remove(self.configHistory)
    end
end

function ConfigManager:restoreFromHistory(index)
    index = index or 1
    
    if not self.configHistory[index] then
        warn("ConfigManager: No history entry at index " .. tostring(index))
        return false
    end
    
    local historicalConfig = self.configHistory[index]
    local restoreName = "Restored_" .. math.random(1000, 9999)
    
    self.configs[restoreName] = self:deepCopy(historicalConfig)
    self:loadConfig(restoreName)
    
    self.library:Notify("Config Restored", "Restored from history", "success")
    return true
end

function ConfigManager:getConfigList()
    local list = {}
    for name, config in pairs(self.configs) do
        table.insert(list, {
            name = name,
            timestamp = config.timestamp,
            elementCount = 0
        })
        
        -- Count elements
        if config.elements then
            for _ in pairs(config.elements) do
                list[#list].elementCount = list[#list].elementCount + 1
            end
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(list, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return list
end

function ConfigManager:setAutoSave(enabled, interval)
    self.autoSaveEnabled = enabled
    if interval then
        self.autoSaveInterval = math.max(interval, 5) -- Minimum 5 seconds
    end
    
    if enabled then
        self:startAutoSave()
    elseif self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
        self.autoSaveConnection = nil
    end
end

function ConfigManager:deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = self:deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function ConfigManager:destroy()
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
        self.autoSaveConnection = nil
    end
    
    -- Final save
    self:saveCurrentState()
    
    -- Clear data
    self.configs = {}
    self.configHistory = {}
    if self.library then
        self.library.configElements = {}
    end
end

-- Persistent Storage System (Memory-based for Roblox)
local PersistentStorage = {}
PersistentStorage.__index = PersistentStorage

function PersistentStorage.new()
    local self = setmetatable({}, PersistentStorage)
    self.data = {}
    self.saveKey = "LynixGUI_AutoSave_" .. LocalPlayer.UserId
    return self
end

function PersistentStorage:save(data)
    -- In Roblox können wir nicht localStorage verwenden
    -- Stattdessen speichern wir in einem globalen _G table
    if not _G.LynixConfigs then
        _G.LynixConfigs = {}
    end
    _G.LynixConfigs[self.saveKey] = data
    
    -- Optional: Auch in DataStore speichern (falls verfügbar)
    pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local configStore = DataStoreService:GetDataStore("LynixConfigs")
        configStore:SetAsync(LocalPlayer.UserId .. "_config", data)
    end)
end

function PersistentStorage:load()
    -- Versuche aus _G zu laden
    if _G.LynixConfigs and _G.LynixConfigs[self.saveKey] then
        return _G.LynixConfigs[self.saveKey]
    end
    
    -- Fallback: Versuche aus DataStore zu laden
    local success, data = pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local configStore = DataStoreService:GetDataStore("LynixConfigs")
        return configStore:GetAsync(LocalPlayer.UserId .. "_config")
    end)
    
    if success and data then
        return data
    end
    
    return nil
end

-- Integration methods for GuiLibrary
local function integrateConfigSystem(library)
    -- Add config manager to library
    library.configManager = ConfigManager.new(library)
    library.persistentStorage = PersistentStorage.new()
    library.configElements = {}
    
    -- Auto-Save aktivieren (sehr kurzes Intervall für "ständiges" Speichern)
    library.configManager:setAutoSave(true, 3) -- Alle 3 Sekunden
    
    -- Override createElement to auto-register elements
    local originalCreateElement = library.createElement
    function library:createElement(section, elementType, name, data, callback)
        local element = originalCreateElement(self, section, elementType, name, data, callback)
        
        if element then
            -- Create path: TabName.SectionName.ElementName
            local tabName = section.tab.name
            local sectionName = section.name
            local elementPath = tabName .. "." .. sectionName .. "." .. name
            
            -- Register element with config system
            self.configManager:registerElement(elementPath, element)
            
            -- Sofort speichern bei Änderung
            local originalCallback = element.callback
            element.callback = function(value)
                -- Original callback ausführen
                if originalCallback then
                    pcall(originalCallback, value)
                end
                
                -- Sofort speichern
                task.spawn(function()
                    task.wait(0.1) -- Kurz warten für UI-Update
                    self:autoSaveToPersistent()
                end)
            end
        end
        
        return element
    end
    
    -- Auto-Save zu persistentem Speicher
    function library:autoSaveToPersistent()
        if not self.configManager then return end
        
        self.configManager:saveCurrentState()
        local configData = self.configManager.configs[self.configManager.currentConfig]
        
        if configData then
            -- Zusätzliche Metadaten für Auto-Load
            local saveData = {
                config = configData,
                timestamp = tick(),
                autoSave = true,
                version = "1.0.0"
            }
            
            self.persistentStorage:save(saveData)
        end
    end
    
    -- Auto-Load von persistentem Speicher
    function library:autoLoadFromPersistent()
        local savedData = self.persistentStorage:load()
        
        if savedData and savedData.config and savedData.autoSave then
            -- Validiere die geladenen Daten
            if self.configManager:validateConfig(savedData.config) then
                -- Lade die Config
                self.configManager.configs["AutoSaved"] = savedData.config
                self.configManager:loadConfig("AutoSaved")
                
                -- Benachrichtigung (optional)
                task.spawn(function()
                    task.wait(1) -- Warten bis GUI vollständig geladen
                    self:Notify("Auto-Load", "Previous session restored", "success", 3)
                end)
                
                return true
            else
                warn("ConfigManager: Invalid auto-saved config, using defaults")
            end
        end
        
        return false
    end
    
    -- Auto-Load beim Start (nach GUI-Erstellung)
    task.spawn(function()
        task.wait(0.5) -- Warten bis alle Elemente erstellt sind
        library:autoLoadFromPersistent()
        
        -- Dann kontinuierliches Auto-Save starten
        while library and library.configManager do
            task.wait(5) -- Alle 5 Sekunden checken
            if library.configManager and library.configManager.autoSaveEnabled then
                library:autoSaveToPersistent()
            end
        end
    end)
    
    -- Override destroy to cleanup and final save
    local originalDestroy = library.destroy
    function library:destroy()
        -- Finale Speicherung vor dem Zerstören
        if self.configManager then
            self:autoSaveToPersistent()
            self.configManager:destroy()
        end
        originalDestroy(self)
    end
    
    -- Zusätzliche Methoden (falls du sie trotzdem brauchst)
    function library:SaveConfig(configName)
        if configName then
            self.configManager:createConfig(configName)
            self.configManager:loadConfig(configName)
        else
            self.configManager:saveCurrentState()
        end
        self:autoSaveToPersistent()
    end
    
    function library:LoadConfig(configName)
        local success = self.configManager:loadConfig(configName)
        if success then
            self:autoSaveToPersistent()
        end
        return success
    end
    
    function library:ExportConfig(configName)
        return self.configManager:exportConfig(configName)
    end
    
    function library:ImportConfig(jsonString, configName)
        local success = self.configManager:importConfig(jsonString, configName)
        if success then
            self:autoSaveToPersistent()
        end
        return success
    end
    
    function library:GetConfigList()
        return self.configManager:getConfigList()
    end
    
    function library:SetAutoSave(enabled, interval)
        self.configManager:setAutoSave(enabled, interval or 3)
    end
end

-- Export integration function
return {
    ConfigManager = ConfigManager,
    integrate = integrateConfigSystem,
    VERSION = "1.0.0"
}
