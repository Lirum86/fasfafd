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
    if not element then 
        warn("ConfigManager: Element is nil for path " .. tostring(elementPath))
        return 
    end
    
    local config = self.configs[self.currentConfig]
    if not config then 
        warn("ConfigManager: No current config found")
        return 
    end
    
    -- Get value from element (check multiple possible locations)
    local value = element.value
    if value == nil and element.state then
        value = element.state
    end
    if value == nil and element.current then
        value = element.current
    end
    
    if value == nil then
        warn("ConfigManager: No value found for element " .. elementPath)
        return
    end
    
    -- Convert Color3 to RGB table for JSON compatibility
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
    
    print("💾 Saved element: " .. elementPath .. " = " .. tostring(value))
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
    if not self.library then 
        warn("ConfigManager: Library not found")
        return false 
    end
    
    local config = self.configs[self.currentConfig]
    if not config then 
        warn("ConfigManager: Current config not found")
        return false 
    end
    
    print("💾 Saving current state for config: " .. self.currentConfig)
    
    -- Save GUI state
    if self.library.mainFrame then
        local pos = self.library.mainFrame.Position
        config.gui.position = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset}
        config.gui.visible = self.library.isVisible
        config.gui.minimized = self.library.isMinimized
        print("💾 Saved GUI state")
    end
    
    -- Save keybinds
    if self.library.keybinds then
        config.keybinds = {}
        for key, value in pairs(self.library.keybinds) do
            config.keybinds[key] = value
        end
        print("💾 Saved keybinds")
    end
    
    -- Save watermark state
    if self.library.watermarkManager then
        config.watermark.visible = self.library.watermarkManager.isVisible
        if self.library.watermarkManager.container then
            local pos = self.library.watermarkManager.container.Position
            config.watermark.position = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset}
        end
        print("💾 Saved watermark state")
    end
    
    -- Save all registered elements with detailed logging
    local elementsSaved = 0
    if self.library.configElements then
        print("💾 Found " .. #self.library.configElements .. " registered elements")
        
        for path, element in pairs(self.library.configElements) do
            if element then
                print("💾 Processing element: " .. path .. " (type: " .. (element.type or "unknown") .. ")")
                self:saveElementState(path, element)
                elementsSaved = elementsSaved + 1
            else
                warn("ConfigManager: Element is nil for path " .. path)
            end
        end
    else
        warn("ConfigManager: No configElements table found")
    end
    
    config.timestamp = tick()
    
    print("💾 Saved " .. elementsSaved .. " elements total")
    
    -- Add to history for backup
    self:addToHistory(config)
    
    return elementsSaved > 0 -- Return true only if we actually saved some elements
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

-- Persistent Storage System (Roblox File-based)
local PersistentStorage = {}
PersistentStorage.__index = PersistentStorage

function PersistentStorage.new()
    local self = setmetatable({}, PersistentStorage)
    self.fileName = "LynixConfig_" .. LocalPlayer.UserId .. ".json"
    self.folderName = "LynixConfigs"
    return self
end

function PersistentStorage:save(data)
    local success = false
    local jsonData = nil
    
    -- Convert data to JSON
    pcall(function()
        jsonData = HttpService:JSONEncode(data)
    end)
    
    if not jsonData then
        warn("PersistentStorage: Failed to encode data to JSON")
        return false
    end
    
    -- Method 1: Try writefile (Exploit/Executor support)
    success = pcall(function()
        if writefile then
            if not isfolder(self.folderName) then
                makefolder(self.folderName)
            end
            writefile(self.folderName .. "/" .. self.fileName, jsonData)
            return true
        end
    end)
    
    if success then
        print("✅ Config saved to file: " .. self.fileName)
        return true
    end
    
    -- Method 2: Fallback to _G (Session only)
    pcall(function()
        if not _G.LynixConfigs then
            _G.LynixConfigs = {}
        end
        _G.LynixConfigs[LocalPlayer.UserId] = data
        print("⚠️ Config saved to memory (session only)")
        success = true
    end)
    
    -- Method 3: Try DataStore (if in real game)
    if not success then
        pcall(function()
            local DataStoreService = game:GetService("DataStoreService")
            local configStore = DataStoreService:GetDataStore("LynixConfigs")
            configStore:SetAsync(LocalPlayer.UserId .. "_config", data)
            print("✅ Config saved to DataStore")
            success = true
        end)
    end
    
    return success
end

function PersistentStorage:load()
    local data = nil
    
    -- Method 1: Try readfile (Executor support)
    local fileSuccess = pcall(function()
        if readfile and isfile(self.folderName .. "/" .. self.fileName) then
            local fileContent = readfile(self.folderName .. "/" .. self.fileName)
            if fileContent and fileContent ~= "" then
                data = HttpService:JSONDecode(fileContent)
                print("✅ Config loaded from file: " .. self.fileName)
                return true
            end
        end
    end)
    
    if fileSuccess and data then
        return data
    end
    
    -- Method 2: Try _G (Session memory)
    pcall(function()
        if _G.LynixConfigs and _G.LynixConfigs[LocalPlayer.UserId] then
            data = _G.LynixConfigs[LocalPlayer.UserId]
            print("⚠️ Config loaded from memory (session)")
        end
    end)
    
    if data then
        return data
    end
    
    -- Method 3: Try DataStore
    pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local configStore = DataStoreService:GetDataStore("LynixConfigs")
        data = configStore:GetAsync(LocalPlayer.UserId .. "_config")
        if data then
            print("✅ Config loaded from DataStore")
        end
    end)
    
    if data then
        return data
    end
    
    print("❌ No saved config found")
    return nil
end

function PersistentStorage:delete()
    -- Delete from file
    pcall(function()
        if delfile and isfile(self.folderName .. "/" .. self.fileName) then
            delfile(self.folderName .. "/" .. self.fileName)
            print("🗑️ Config file deleted")
        end
    end)
    
    -- Delete from _G
    pcall(function()
        if _G.LynixConfigs and _G.LynixConfigs[LocalPlayer.UserId] then
            _G.LynixConfigs[LocalPlayer.UserId] = nil
            print("🗑️ Config cleared from memory")
        end
    end)
    
    -- Delete from DataStore
    pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local configStore = DataStoreService:GetDataStore("LynixConfigs")
        configStore:RemoveAsync(LocalPlayer.UserId .. "_config")
        print("🗑️ Config cleared from DataStore")
    end)
end

-- Integration methods for GuiLibrary
local function integrateConfigSystem(library)
    -- Add config manager to library
    library.configManager = ConfigManager.new(library)
    library.persistentStorage = PersistentStorage.new()
    library.configElements = {}
    
    -- Check storage capabilities on startup
    library.storageInfo = {
        fileSupport = (writefile and readfile and isfolder and makefolder) ~= nil,
        dataStoreSupport = false,
        memoryOnly = false
    }
    
    -- Test DataStore support
    pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local testStore = DataStoreService:GetDataStore("TestStore")
        library.storageInfo.dataStoreSupport = true
    end)
    
    -- Determine storage method
    if not library.storageInfo.fileSupport and not library.storageInfo.dataStoreSupport then
        library.storageInfo.memoryOnly = true
        warn("ConfigSystem: No persistent storage available - configs will only last during session")
    end
    
    -- Auto-Save aktivieren mit angepasstem Intervall
    library.configManager:setAutoSave(true, 5) -- 5 Sekunden
    
    -- Override createElement to auto-register elements
    local originalCreateElement = library.createElement
    function library:createElement(section, elementType, name, data, callback)
        local element = originalCreateElement(self, section, elementType, name, data, callback)
        
        if element then
            -- Create path: TabName.SectionName.ElementName
            local tabName = section.tab.name
            local sectionName = section.name
            local elementPath = tabName .. "." .. sectionName .. "." .. name
            
            print("🔧 Registering element: " .. elementPath .. " (type: " .. elementType .. ")")
            
            -- Ensure configElements table exists
            if not self.configElements then
                self.configElements = {}
            end
            
            -- Register element with config system
            element.configPath = elementPath -- Store path in element for debugging
            self.configElements[elementPath] = element
            self.configManager:registerElement(elementPath, element)
            
            -- Enhanced callback with immediate save and value tracking
            local originalCallback = callback
            element.originalCallback = originalCallback
            
            element.callback = function(value)
                print("🔄 Element changed: " .. elementPath .. " = " .. tostring(value))
                
                -- Update element value FIRST
                element.value = value
                element.state = value -- Backup storage
                
                -- Execute original callback
                if originalCallback then
                    local success, err = pcall(originalCallback, value)
                    if not success then
                        warn("Callback error for " .. elementPath .. ": " .. tostring(err))
                    end
                end
                
                -- Immediate save after change
                task.spawn(function()
                    task.wait(0.1) -- Small delay for UI updates
                    print("💾 Triggering auto-save for " .. elementPath)
                    self:autoSaveToPersistent()
                end)
            end
            
            print("✅ Successfully registered: " .. elementPath)
        else
            warn("Failed to create element: " .. name)
        end
        
        return element
    end
    
    -- Enhanced auto-save to persistent storage
    function library:autoSaveToPersistent()
        if not self.configManager then return false end
        
        -- Force save current state
        local success = self.configManager:saveCurrentState()
        if not success then
            warn("ConfigSystem: Failed to save current state")
            return false
        end
        
        local configData = self.configManager.configs[self.configManager.currentConfig]
        if not configData then
            warn("ConfigSystem: No config data to save")
            return false
        end
        
        -- Create save package with metadata
        local savePackage = {
            config = configData,
            metadata = {
                timestamp = tick(),
                version = "1.0.0",
                userId = LocalPlayer.UserId,
                userName = LocalPlayer.Name,
                autoSave = true,
                storageMethod = self.storageInfo.fileSupport and "file" or 
                               self.storageInfo.dataStoreSupport and "datastore" or "memory"
            }
        }
        
        -- Save to persistent storage
        local saveSuccess = self.persistentStorage:save(savePackage)
        if saveSuccess then
            print("💾 Auto-saved config at " .. os.date("%H:%M:%S"))
        else
            warn("ConfigSystem: Failed to save config to persistent storage")
        end
        
        return saveSuccess
    end
    
    -- Enhanced auto-load from persistent storage
    function library:autoLoadFromPersistent()
        print("🔄 Attempting to load saved config...")
        
        local savedData = self.persistentStorage:load()
        
        if not savedData then
            print("📝 No saved config found - using defaults")
            return false
        end
        
        if not savedData.config then
            warn("ConfigSystem: Invalid saved data format")
            return false
        end
        
        -- Validate config structure
        if not self.configManager:validateConfig(savedData.config) then
            warn("ConfigSystem: Saved config failed validation - using defaults")
            return false
        end
        
        -- Show load info
        if savedData.metadata then
            local saveTime = savedData.metadata.timestamp
            local timeAgo = saveTime and math.floor(tick() - saveTime) or "unknown"
            print("📂 Loading config saved " .. timeAgo .. " seconds ago")
            print("💾 Storage method: " .. (savedData.metadata.storageMethod or "unknown"))
        end
        
        -- Load the config into ConfigManager
        self.configManager.configs["AutoLoaded"] = savedData.config
        self.configManager.currentConfig = "AutoLoaded"
        
        -- Apply to all registered elements with detailed logging
        if savedData.config.elements and self.configElements then
            local loadedCount = 0
            local totalElements = 0
            
            -- Count total elements
            for _ in pairs(self.configElements) do
                totalElements = totalElements + 1
            end
            
            print("🔄 Attempting to load " .. totalElements .. " elements...")
            
            for elementPath, element in pairs(self.configElements) do
                if savedData.config.elements[elementPath] then
                    local savedElement = savedData.config.elements[elementPath]
                    local value = savedElement.value
                    
                    print("🔄 Loading " .. elementPath .. " = " .. tostring(value))
                    
                    -- Convert RGB table back to Color3
                    if savedElement.type == "colorpicker" and type(value) == "table" and value.r then
                        value = Color3.fromRGB(value.r, value.g, value.b)
                    end
                    
                    -- Update element value
                    element.value = value
                    element.state = value -- Backup storage
                    
                    -- Update UI without triggering callback loops
                    self.configManager:updateElementUI(element, value)
                    
                    -- Trigger original callback for functionality (like speed changes)
                    -- But NOT the enhanced callback to avoid save loops
                    if element.originalCallback then
                        local success, err = pcall(element.originalCallback, value)
                        if not success then
                            warn("Error in original callback for " .. elementPath .. ": " .. tostring(err))
                        end
                    end
                    
                    loadedCount = loadedCount + 1
                    print("✅ Loaded " .. elementPath .. " successfully")
                else
                    print("⚠️ No saved value for " .. elementPath)
                end
            end
            
            print("✅ Loaded " .. loadedCount .. "/" .. totalElements .. " config values")
        else
            warn("ConfigSystem: No elements to load or no saved elements")
        end
        
        -- Load GUI state
        if savedData.config.gui then
            local guiConfig = savedData.config.gui
            
            if guiConfig.position and self.mainFrame then
                local pos = guiConfig.position
                self.mainFrame.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
                print("✅ Loaded GUI position")
            end
            
            if guiConfig.minimized then
                self:hide()
                print("✅ Loaded GUI minimized state")
            end
        end
        
        -- Load keybinds
        if savedData.config.keybinds then
            for key, value in pairs(savedData.config.keybinds) do
                self.keybinds[key] = value
            end
            self:setupKeybinds()
            print("✅ Loaded keybinds")
        end
        
        -- Load watermark state
        if savedData.config.watermark and self.watermarkManager then
            self.watermarkManager:setVisible(savedData.config.watermark.visible)
            if savedData.config.watermark.position and self.watermarkManager.container then
                local pos = savedData.config.watermark.position
                self.watermarkManager.container.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
            end
            print("✅ Loaded watermark state")
        end
        
        -- Success notification
        task.spawn(function()
            task.wait(1.5) -- Wait for GUI to fully load
            self:Notify("Config Loaded", "Previous session restored successfully", "success", 4)
        end)
        
        return true
    end
    
    -- Delayed auto-load (after all elements are created)
    task.spawn(function()
        task.wait(1) -- Wait for all GUI elements to be created
        library:autoLoadFromPersistent()
        
        -- Start continuous auto-save loop
        while library and library.configManager and library.configManager.autoSaveEnabled do
            task.wait(library.configManager.autoSaveInterval or 5)
            if library.configManager.autoSaveEnabled then
                library:autoSaveToPersistent()
            end
        end
    end)
    
    -- Enhanced config methods
    function library:SaveConfig(configName)
        configName = configName or "Manual_" .. os.date("%H_%M_%S")
        
        if self.configManager:createConfig(configName) then
            self.configManager:loadConfig(configName)
            self:autoSaveToPersistent()
            return true
        end
        return false
    end
    
    function library:LoadConfig(configName)
        local success = self.configManager:loadConfig(configName)
        if success then
            self:autoSaveToPersistent()
        end
        return success
    end
    
    function library:DeleteConfig(configName)
        return self.configManager:deleteConfig(configName)
    end
    
    function library:ExportConfig(configName)
        configName = configName or self.configManager.currentConfig
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
        self.configManager:setAutoSave(enabled, interval)
    end
    
    function library:DeleteSavedConfig()
        self.persistentStorage:delete()
        self:Notify("Config Deleted", "Saved configuration has been deleted", "info")
    end
    
    function library:GetStorageInfo()
        return {
            fileSupport = self.storageInfo.fileSupport,
            dataStoreSupport = self.storageInfo.dataStoreSupport,
            memoryOnly = self.storageInfo.memoryOnly,
            currentMethod = self.storageInfo.fileSupport and "File System" or
                           self.storageInfo.dataStoreSupport and "DataStore" or "Memory Only"
        }
    end
    
    -- Override destroy to cleanup and final save
    local originalDestroy = library.destroy
    function library:destroy()
        -- Final save before cleanup
        if self.configManager then
            print("💾 Performing final config save...")
            self:autoSaveToPersistent()
            self.configManager:destroy()
        end
        
        -- Original cleanup
        originalDestroy(self)
        
        print("🧹 Config system cleaned up")
    end
end

-- Export integration function
return {
    ConfigManager = ConfigManager,
    integrate = integrateConfigSystem,
    VERSION = "1.0.0"
}
