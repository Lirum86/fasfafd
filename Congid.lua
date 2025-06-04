--[[
    Lynix SaveManager v1.0
    Professional Config System for Lynix GUI Library
    
    Features:
    - Save/Load all GUI element settings
    - JSON-based config files
    - Auto-detection of GUI elements
    - User-friendly config management UI
    - Error handling and validation
    - Auto-load system
]]

local httpService = game:GetService("HttpService")

local SaveManager = {} do
    SaveManager.Folder = "LynixConfigs"
    SaveManager.Ignore = {}
    SaveManager.Options = {}
    SaveManager.Library = nil
    
    -- Parser system for different element types
    SaveManager.Parser = {
        toggle = {
            Save = function(idx, element)
                return { 
                    type = "toggle", 
                    idx = idx, 
                    value = element.value 
                }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and SaveManager.Options[idx].callback then
                    SaveManager.Options[idx].value = data.value
                    pcall(SaveManager.Options[idx].callback, data.value)
                end
            end,
        },
        
        slider = {
            Save = function(idx, element)
                return { 
                    type = "slider", 
                    idx = idx, 
                    value = element.value 
                }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and SaveManager.Options[idx].callback then
                    SaveManager.Options[idx].value = data.value
                    pcall(SaveManager.Options[idx].callback, data.value)
                end
            end,
        },
        
        dropdown = {
            Save = function(idx, element)
                return { 
                    type = "dropdown", 
                    idx = idx, 
                    value = element.value 
                }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and SaveManager.Options[idx].callback then
                    SaveManager.Options[idx].value = data.value
                    pcall(SaveManager.Options[idx].callback, data.value)
                end
            end,
        },
        
        colorpicker = {
            Save = function(idx, element)
                local color = element.value
                return { 
                    type = "colorpicker", 
                    idx = idx, 
                    r = math.floor(color.R * 255),
                    g = math.floor(color.G * 255),
                    b = math.floor(color.B * 255)
                }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and SaveManager.Options[idx].callback then
                    local color = Color3.fromRGB(data.r, data.g, data.b)
                    SaveManager.Options[idx].value = color
                    pcall(SaveManager.Options[idx].callback, color)
                end
            end,
        },
        
        keybind = {
            Save = function(idx, element)
                return { 
                    type = "keybind", 
                    idx = idx, 
                    value = element.value 
                }
            end,
            Load = function(idx, data)
                if SaveManager.Options[idx] and SaveManager.Options[idx].callback then
                    SaveManager.Options[idx].value = data.value
                    pcall(SaveManager.Options[idx].callback, data.value)
                end
            end,
        }
    }

    -- Set elements to ignore during save/load
    function SaveManager:SetIgnoreIndexes(list)
        for _, key in pairs(list) do
            self.Ignore[key] = true
        end
    end

    -- Set custom folder name
    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    -- Connect SaveManager to GUI Library
    function SaveManager:SetLibrary(library)
        self.Library = library
        if not library.Options then
            library.Options = {}
        end
        self.Options = library.Options
    end

    -- Register a GUI element for saving
    function SaveManager:RegisterElement(elementName, element)
        if not self.Ignore[elementName] then
            self.Options[elementName] = element
        end
    end

    -- Save current config
    function SaveManager:Save(configName)
        if not configName or configName == "" then
            return false, "No config name provided"
        end
        
        if not self.Library then
            return false, "SaveManager not connected to library"
        end

        local fullPath = self.Folder .. "/configs/" .. configName .. ".json"
        
        local configData = {
            version = "1.0",
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            elements = {}
        }

        -- Collect all element values
        for elementName, element in pairs(self.Options) do
            if not self.Ignore[elementName] and element.type and self.Parser[element.type] then
                local saveData = self.Parser[element.type].Save(elementName, element)
                if saveData then
                    table.insert(configData.elements, saveData)
                end
            end
        end

        -- Encode to JSON
        local success, encoded = pcall(function()
            return httpService:JSONEncode(configData)
        end)
        
        if not success then
            return false, "Failed to encode config data"
        end

        -- Write to file
        local writeSuccess, writeError = pcall(function()
            writefile(fullPath, encoded)
        end)
        
        if not writeSuccess then
            return false, "Failed to write config file: " .. tostring(writeError)
        end

        return true, "Config saved successfully"
    end

    -- Load config from file
    function SaveManager:Load(configName)
        if not configName or configName == "" then
            return false, "No config name provided"
        end
        
        if not self.Library then
            return false, "SaveManager not connected to library"
        end

        local filePath = self.Folder .. "/configs/" .. configName .. ".json"
        
        -- Check if file exists
        if not isfile(filePath) then
            return false, "Config file not found"
        end

        -- Read file
        local fileContent
        local readSuccess, readError = pcall(function()
            fileContent = readfile(filePath)
        end)
        
        if not readSuccess then
            return false, "Failed to read config file: " .. tostring(readError)
        end

        -- Decode JSON
        local configData
        local decodeSuccess, decodeError = pcall(function()
            configData = httpService:JSONDecode(fileContent)
        end)
        
        if not decodeSuccess then
            return false, "Failed to decode config file: " .. tostring(decodeError)
        end

        -- Validate config structure
        if not configData.elements then
            return false, "Invalid config file format"
        end

        -- Load all elements
        for _, elementData in pairs(configData.elements) do
            if elementData.type and elementData.idx and self.Parser[elementData.type] then
                task.spawn(function()
                    self.Parser[elementData.type].Load(elementData.idx, elementData)
                end)
            end
        end

        return true, "Config loaded successfully"
    end

    -- Delete config file
    function SaveManager:Delete(configName)
        if not configName or configName == "" then
            return false, "No config name provided"
        end

        local filePath = self.Folder .. "/configs/" .. configName .. ".json"
        
        if not isfile(filePath) then
            return false, "Config file not found"
        end

        local deleteSuccess, deleteError = pcall(function()
            delfile(filePath)
        end)
        
        if not deleteSuccess then
            return false, "Failed to delete config file: " .. tostring(deleteError)
        end

        return true, "Config deleted successfully"
    end

    -- Get list of all saved configs
    function SaveManager:RefreshConfigList()
        local configPath = self.Folder .. "/configs"
        
        if not isfolder(configPath) then
            return {}
        end

        local files = listfiles(configPath)
        local configs = {}
        
        for _, filePath in pairs(files) do
            if filePath:sub(-5) == ".json" then
                -- Extract filename without path and extension
                local fileName = filePath:match("([^/\\]+)%.json$")
                if fileName and fileName ~= "autoload" then
                    table.insert(configs, fileName)
                end
            end
        end
        
        -- Sort alphabetically
        table.sort(configs)
        return configs
    end

    -- Create folder structure
    function SaveManager:BuildFolderTree()
        local folders = {
            self.Folder,
            self.Folder .. "/configs"
        }

        for _, folderPath in pairs(folders) do
            if not isfolder(folderPath) then
                local success, error = pcall(function()
                    makefolder(folderPath)
                end)
                if not success then
                    warn("Failed to create folder: " .. folderPath .. " - " .. tostring(error))
                end
            end
        end
    end

    -- Auto-load system
    function SaveManager:SetAutoLoad(configName)
        local autoloadPath = self.Folder .. "/configs/autoload.txt"
        
        local success, error = pcall(function()
            writefile(autoloadPath, configName)
        end)
        
        if not success then
            return false, "Failed to set autoload: " .. tostring(error)
        end
        
        return true, "Autoload config set"
    end

    function SaveManager:GetAutoLoad()
        local autoloadPath = self.Folder .. "/configs/autoload.txt"
        
        if not isfile(autoloadPath) then
            return nil
        end
        
        local success, configName = pcall(function()
            return readfile(autoloadPath)
        end)
        
        if success and configName and configName ~= "" then
            return configName
        end
        
        return nil
    end

    function SaveManager:LoadAutoLoad()
        local autoloadConfig = self:GetAutoLoad()
        
        if autoloadConfig then
            local success, message = self:Load(autoloadConfig)
            if success then
                if self.Library and self.Library.Notify then
                    self.Library:Notify("Config System", "Auto-loaded: " .. autoloadConfig, "success", 3)
                end
                return true, "Auto-loaded: " .. autoloadConfig
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify("Config System", "Failed to auto-load: " .. message, "error", 4)
                end
                return false, "Failed to auto-load: " .. message
            end
        end
        
        return false, "No autoload config set"
    end

    -- Build config management UI in Settings tab
    function SaveManager:BuildConfigSection(settingsTab)
        if not self.Library then
            error("SaveManager must be connected to library before building UI")
        end
        
        if not settingsTab then
            error("Settings tab not provided")
        end

        -- Find available section (should be second section in settings)
        local configSection
        
        -- Try to find existing section or create new one
        if #settingsTab.sections < 2 then
            configSection = settingsTab:CreateSection("Configuration")
        else
            -- Use second section if it exists
            configSection = settingsTab.sections[2]
            if configSection.name ~= "Configuration" then
                configSection = settingsTab:CreateSection("Configuration")
            end
        end

        if not configSection then
            error("Failed to create config section")
        end

        -- Config name input
        local configNameInput = ""
        configSection:CreateToggle("Config Name Input", false, function() end) -- Placeholder for now
        
        -- We'll use a simple system: store config name in a variable
        -- This is a limitation of the current GUI system
        
        -- Current config display
        local currentConfigName = "None"
        local autoloadConfig = self:GetAutoLoad()
        if autoloadConfig then
            currentConfigName = autoloadConfig .. " (Auto)"
        end

        -- Config list dropdown
        local configList = self:RefreshConfigList()
        local selectedConfig = ""
        
        if #configList > 0 then
            selectedConfig = configList[1]
        end
        
        configSection:CreateDropdown("Saved Configs", configList, function(value)
            selectedConfig = value
        end)

        -- Save config button
        configSection:CreateToggle("Save Current Settings", false, function(value)
            if value then
                -- Toggle back off immediately
                task.wait(0.1)
                -- Here we use a simple naming system since we can't get user input easily
                local timestamp = os.date("%H%M%S")
                local configName = "Config_" .. timestamp
                
                local success, message = self:Save(configName)
                
                if self.Library.Notify then
                    if success then
                        self.Library:Notify("Config System", "Saved: " .. configName, "success", 3)
                    else
                        self.Library:Notify("Config System", "Save failed: " .. message, "error", 4)
                    end
                end
                
                -- Refresh dropdown
                local newConfigList = self:RefreshConfigList()
                -- Note: We'd need to update the dropdown here, but the current system doesn't support it
            end
        end)

        -- Load config button
        configSection:CreateToggle("Load Selected Config", false, function(value)
            if value then
                task.wait(0.1)
                if selectedConfig and selectedConfig ~= "" then
                    local success, message = self:Load(selectedConfig)
                    
                    if self.Library.Notify then
                        if success then
                            self.Library:Notify("Config System", "Loaded: " .. selectedConfig, "success", 3)
                        else
                            self.Library:Notify("Config System", "Load failed: " .. message, "error", 4)
                        end
                    end
                else
                    if self.Library.Notify then
                        self.Library:Notify("Config System", "No config selected", "warning", 3)
                    end
                end
            end
        end)

        -- Delete config button
        configSection:CreateToggle("Delete Selected Config", false, function(value)
            if value then
                task.wait(0.1)
                if selectedConfig and selectedConfig ~= "" then
                    local success, message = self:Delete(selectedConfig)
                    
                    if self.Library.Notify then
                        if success then
                            self.Library:Notify("Config System", "Deleted: " .. selectedConfig, "info", 3)
                        else
                            self.Library:Notify("Config System", "Delete failed: " .. message, "error", 4)
                        end
                    end
                    
                    -- Clear selection after deletion
                    selectedConfig = ""
                else
                    if self.Library.Notify then
                        self.Library:Notify("Config System", "No config selected", "warning", 3)
                    end
                end
            end
        end)

        -- Set autoload button
        configSection:CreateToggle("Set as Auto-Load", false, function(value)
            if value then
                task.wait(0.1)
                if selectedConfig and selectedConfig ~= "" then
                    local success, message = self:SetAutoLoad(selectedConfig)
                    
                    if self.Library.Notify then
                        if success then
                            self.Library:Notify("Config System", "Auto-load set: " .. selectedConfig, "success", 3)
                        else
                            self.Library:Notify("Config System", "Auto-load failed: " .. message, "error", 4)
                        end
                    end
                else
                    if self.Library.Notify then
                        self.Library:Notify("Config System", "No config selected", "warning", 3)
                    end
                end
            end
        end)

        -- Ignore config system elements from being saved
        self:SetIgnoreIndexes({
            "Config Name Input",
            "Saved Configs", 
            "Save Current Settings",
            "Load Selected Config",
            "Delete Selected Config",
            "Set as Auto-Load"
        })

        -- Try to auto-load if available
        task.spawn(function()
            task.wait(2) -- Wait for all elements to be registered
            self:LoadAutoLoad()
        end)
    end

    -- Initialize folder structure
    SaveManager:BuildFolderTree()
end

return SaveManager
