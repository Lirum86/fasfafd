--[[
    Lynix GUI Library v1.1 - Mit Config System
    A professional, secure Roblox Lua GUI Library
    
    Features:
    - Modular tab system with exactly 2 sections per tab
    - Protected core elements (Kill button, Minimize button, Settings tab)
    - Toggle buttons, Color pickers, Sliders, Dropdown menus
    - Advanced notification system
    - Keybind management
    - Modern dark theme with smooth animations
    - Complete Config System (Save/Load/Auto-Save)
    
    Security Features:
    - Input validation and sanitization
    - Error handling for all operations
    - Protection against code injection
    - Memory management optimizations
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Theme Configuration
local THEME = {
    Background = Color3.fromRGB(18, 18, 18),
    Surface = Color3.fromRGB(25, 25, 25),
    SurfaceLight = Color3.fromRGB(35, 35, 35),
    Primary = Color3.fromRGB(80, 140, 255),
    PrimaryDark = Color3.fromRGB(60, 120, 235),
    Success = Color3.fromRGB(40, 180, 100),
    Warning = Color3.fromRGB(255, 165, 0),
    Error = Color3.fromRGB(235, 65, 65),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(45, 45, 45),
    Accent = Color3.fromRGB(100, 160, 255)
}

-- Animation Presets
local ANIMATIONS = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

-- Utility Functions
local function validateInput(input, inputType, allowedValues)
    if inputType == "string" and type(input) ~= "string" then
        return false, "Expected string input"
    elseif inputType == "number" and type(input) ~= "number" then
        return false, "Expected number input"
    elseif inputType == "boolean" and type(input) ~= "boolean" then
        return false, "Expected boolean input"
    elseif inputType == "function" and type(input) ~= "function" then
        return false, "Expected function input"
    elseif inputType == "Color3" and typeof(input) ~= "Color3" then
        return false, "Expected Color3 input"
    end
    
    if allowedValues and not table.find(allowedValues, input) then
        return false, "Input not in allowed values"
    end
    
    return true, "Valid input"
end

local function safeCreate(className, properties)
    local success, result = pcall(function()
        local instance = Instance.new(className)
        if properties then
            for property, value in pairs(properties) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
        return instance
    end)
    
    if success then
        return result
    else
        warn("Failed to create " .. className .. ": " .. tostring(result))
        return nil
    end
end

local function deepCopy(original)
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

-- Config System
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(library)
    local self = setmetatable({}, ConfigManager)
    self.library = library
    self.configs = {}
    self.currentConfig = "Default"
    self.autoSaveEnabled = true
    self.autoSaveInterval = 30 -- seconds
    self.lastAutoSave = tick()
    self.configElements = {}
    
    -- Create default config
    self:createDefaultConfig()
    
    return self
end

function ConfigManager:createDefaultConfig()
    self.configs["Default"] = {
        name = "Default",
        created = os.date("%Y-%m-%d %H:%M:%S"),
        elements = {}
    }
end

function ConfigManager:registerElement(element)
    if not element or not element.name or not element.type then
        warn("Invalid element registration")
        return
    end
    
    -- Check if required properties exist
    if not element.tab or not element.tab.name then
        warn("Element missing tab information")
        return
    end
    
    if not element.section or not element.section.name then
        warn("Element missing section information")
        return
    end
    
    local elementId = element.tab.name .. "_" .. element.section.name .. "_" .. element.name .. "_" .. element.type
    self.configElements[elementId] = element
end

function ConfigManager:saveCurrentConfig()
    if not self.currentConfig or not self.configs[self.currentConfig] then
        warn("No valid config to save")
        return false
    end
    
    local configData = {
        name = self.currentConfig,
        created = self.configs[self.currentConfig].created,
        lastModified = os.date("%Y-%m-%d %H:%M:%S"),
        elements = {}
    }
    
    -- Save all registered elements
    for elementId, element in pairs(self.configElements) do
        if element and element.value ~= nil then
            local elementData = {
                value = element.value,
                type = element.type
            }
            
            -- Special handling for Color3
            if element.type == "colorpicker" and typeof(element.value) == "Color3" then
                elementData.value = {
                    r = element.value.R,
                    g = element.value.G,
                    b = element.value.B
                }
            end
            
            configData.elements[elementId] = elementData
        end
    end
    
    self.configs[self.currentConfig] = configData
    
    -- Show notification
    if self.library and self.library.notificationManager then
        self.library:Notify("Config Saved", "Configuration '" .. self.currentConfig .. "' saved successfully", "success", 2)
    end
    
    return true
end

function ConfigManager:loadConfig(configName)
    if not configName or not self.configs[configName] then
        warn("Config not found: " .. tostring(configName))
        return false
    end
    
    local configData = self.configs[configName]
    local loadedCount = 0
    local totalCount = 0
    
    -- Load all elements
    for elementId, savedData in pairs(configData.elements) do
        totalCount = totalCount + 1
        local element = self.configElements[elementId]
        
        if element and savedData.value ~= nil then
            local success = pcall(function()
                local value = savedData.value
                
                -- Special handling for Color3
                if savedData.type == "colorpicker" and type(value) == "table" and value.r then
                    value = Color3.fromRGB(
                        math.floor(value.r * 255),
                        math.floor(value.g * 255),
                        math.floor(value.b * 255)
                    )
                end
                
                -- Update element value
                element.value = value
                
                -- Trigger callback
                if element.callback and type(element.callback) == "function" then
                    element.callback(value)
                end
                
                -- Update visual representation
                self:updateElementVisual(element, value)
            end)
            
            if success then
                loadedCount = loadedCount + 1
            end
        end
    end
    
    self.currentConfig = configName
    
    if self.library and self.library.notificationManager then
        self.library:Notify("Config Loaded", 
            string.format("Loaded %d/%d elements from '%s'", loadedCount, totalCount, configName), 
            "success", 3)
    end
    
    return true
end

function ConfigManager:updateElementVisual(element, value)
    if not element.container then return end
    
    if element.type == "toggle" then
        local toggleBG = element.container:FindFirstChild("ToggleBG")
        local toggleButton = toggleBG and toggleBG:FindFirstChild("ToggleButton")
        
        if toggleBG and toggleButton then
            local newPos = value and UDim2.new(0, 27, 0, 2) or UDim2.new(0, 2, 0, 2)
            local newColor = value and THEME.Primary or THEME.Border
            
            TweenService:Create(toggleButton, ANIMATIONS.Medium, {Position = newPos}):Play()
            TweenService:Create(toggleBG, ANIMATIONS.Medium, {BackgroundColor3 = newColor}):Play()
        end
        
    elseif element.type == "slider" then
        local valueLabel = element.container:FindFirstChild("ValueLabel")
        local sliderFill = element.container:FindFirstChild("SliderTrack")
        sliderFill = sliderFill and sliderFill:FindFirstChild("SliderFill")
        
        if valueLabel then
            valueLabel.Text = tostring(value)
        end
        
        if sliderFill and element.min and element.max then
            local fillPercent = (value - element.min) / (element.max - element.min)
            TweenService:Create(sliderFill, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {
                Size = UDim2.new(fillPercent, 0, 1, 0)
            }):Play()
        end
        
    elseif element.type == "dropdown" then
        local selectedLabel = element.container:FindFirstChild("DropdownBtn")
        selectedLabel = selectedLabel and selectedLabel:FindFirstChild("SelectedLabel")
        
        if selectedLabel then
            selectedLabel.Text = tostring(value)
        end
        
    elseif element.type == "colorpicker" then
        local colorPreview = element.container:FindFirstChild("ColorPreview")
        
        if colorPreview and typeof(value) == "Color3" then
            colorPreview.BackgroundColor3 = value
        end
        
    elseif element.type == "keybind" then
        local keybindBtn = element.container:FindFirstChild("KeybindBtn")
        
        if keybindBtn then
            keybindBtn.Text = tostring(value)
        end
    end
end

function ConfigManager:createConfig(name)
    if not name or name == "" then
        warn("Invalid config name")
        return false
    end
    
    if self.configs[name] then
        warn("Config already exists: " .. name)
        return false
    end
    
    self.configs[name] = {
        name = name,
        created = os.date("%Y-%m-%d %H:%M:%S"),
        elements = {}
    }
    
    if self.library and self.library.notificationManager then
        self.library:Notify("Config Created", "New configuration '" .. name .. "' created", "success", 2)
    end
    
    return true
end

function ConfigManager:deleteConfig(name)
    if not name or name == "Default" then
        warn("Cannot delete default config")
        return false
    end
    
    if not self.configs[name] then
        warn("Config not found: " .. name)
        return false
    end
    
    self.configs[name] = nil
    
    if self.currentConfig == name then
        self.currentConfig = "Default"
    end
    
    if self.library and self.library.notificationManager then
        self.library:Notify("Config Deleted", "Configuration '" .. name .. "' deleted", "info", 2)
    end
    
    return true
end

function ConfigManager:getConfigList()
    local list = {}
    for name, _ in pairs(self.configs) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

function ConfigManager:exportConfig(configName)
    configName = configName or self.currentConfig
    
    if not self.configs[configName] then
        warn("Config not found: " .. tostring(configName))
        return nil
    end
    
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(self.configs[configName])
    end)
    
    if success then
        return jsonString
    else
        warn("Failed to export config: " .. tostring(jsonString))
        return nil
    end
end

function ConfigManager:importConfig(jsonString, configName)
    if not jsonString or jsonString == "" then
        warn("Invalid JSON string")
        return false
    end
    
    local success, configData = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        warn("Failed to parse JSON: " .. tostring(configData))
        return false
    end
    
    configName = configName or configData.name or "Imported_" .. os.time()
    
    if self.configs[configName] then
        configName = configName .. "_" .. os.time()
    end
    
    configData.name = configName
    configData.imported = os.date("%Y-%m-%d %H:%M:%S")
    
    self.configs[configName] = configData
    
    if self.library and self.library.notificationManager then
        self.library:Notify("Config Imported", "Configuration '" .. configName .. "' imported successfully", "success", 3)
    end
    
    return true
end

function ConfigManager:startAutoSave()
    if self.autoSaveConnection then
        return
    end
    
    self.autoSaveConnection = RunService.Heartbeat:Connect(function()
        if self.autoSaveEnabled and tick() - self.lastAutoSave >= self.autoSaveInterval then
            self:saveCurrentConfig()
            self.lastAutoSave = tick()
        end
    end)
end

function ConfigManager:stopAutoSave()
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
        self.autoSaveConnection = nil
    end
end

function ConfigManager:destroy()
    self:stopAutoSave()
    self.configs = {}
    self.configElements = {}
end

-- Notification System
local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new()
    local self = setmetatable({}, NotificationManager)
    self.notifications = {}
    self.container = nil
    self:createContainer()
    return self
end

function NotificationManager:createContainer()
    if self.container and self.container.Parent then
        return
    end
    
    local screenGui = safeCreate("ScreenGui", {
        Name = "LynixNotifications_" .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = CoreGui
    })
    
    if not screenGui then return end
    
    self.container = safeCreate("Frame", {
        Name = "NotificationContainer",
        Size = UDim2.new(0, 350, 0, 400),
        Position = UDim2.new(1, -370, 1, -420),
        BackgroundTransparency = 1,
        Parent = screenGui
    })
end

function NotificationManager:notify(title, message, notificationType, duration)
    local isValid, error = validateInput(title, "string")
    if not isValid then
        warn("Invalid notification title: " .. error)
        return
    end
    
    duration = duration or 4
    notificationType = notificationType or "info"
    message = message or ""
    
    if not self.container then
        self:createContainer()
    end
    
    -- Clean up destroyed notifications first
    for i = #self.notifications, 1, -1 do
        if not self.notifications[i] or not self.notifications[i].Parent then
            table.remove(self.notifications, i)
        end
    end
    
    -- Push existing notifications down before adding new one
    for i, existingNotif in pairs(self.notifications) do
        if existingNotif and existingNotif.Parent then
            local currentY = existingNotif.Position.Y.Offset
            TweenService:Create(existingNotif, ANIMATIONS.Medium, {
                Position = UDim2.new(0, 0, 1, currentY - 90) -- Move down by 90 pixels
            }):Play()
        end
    end
    
    -- New notification always starts at the top position
    local yOffset = -90
    
    local notification = safeCreate("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(1, 0, 1, yOffset),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.container
    })
    
    if not notification then return end
    
    -- Styling
    local corner = safeCreate("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = notification
    })
    
    local stroke = safeCreate("UIStroke", {
        Color = THEME.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = notification
    })
    
    -- Icon
    local iconColor = THEME.Primary
    local iconText = "ℹ"
    
    if notificationType == "success" then
        iconText = "✓"
        iconColor = THEME.Success
    elseif notificationType == "warning" then
        iconText = "⚠"
        iconColor = THEME.Warning
    elseif notificationType == "error" then
        iconText = "✗"
        iconColor = THEME.Error
    end
    
    local iconFrame = safeCreate("Frame", {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = iconColor,
        BorderSizePixel = 0,
        Parent = notification
    })
    
    if iconFrame then
        local iconCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 25),
            Parent = iconFrame
        })
        
        local icon = safeCreate("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = iconText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 24,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = iconFrame
        })
    end
    
    -- Title
    local titleLabel = safeCreate("TextLabel", {
        Size = UDim2.new(0, 250, 0, 25),
        Position = UDim2.new(0, 75, 0, 15),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = THEME.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notification
    })
    
    -- Message
    local messageLabel = safeCreate("TextLabel", {
        Size = UDim2.new(0, 250, 0, 20),
        Position = UDim2.new(0, 75, 0, 40),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = THEME.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notification
    })
    
    -- Progress Bar
    local progressBG = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 1, -10),
        BackgroundColor3 = THEME.SurfaceLight,
        BorderSizePixel = 0,
        Parent = notification
    })
    
    if progressBG then
        local progressCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 2),
            Parent = progressBG
        })
        
        local progressFill = safeCreate("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = iconColor,
            BorderSizePixel = 0,
            Parent = progressBG
        })
        
        if progressFill then
            local fillCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 2),
                Parent = progressFill
            })
            
            local progressTween = TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            })
            progressTween:Play()
        end
    end
    
    -- Close Button
    local closeBtn = safeCreate("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -30, 0, 10),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = THEME.TextSecondary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = notification
    })
    
    -- Animation and cleanup
    table.insert(self.notifications, notification)
    
    TweenService:Create(notification, ANIMATIONS.Bounce, {
        Position = UDim2.new(0, 0, 1, yOffset)
    }):Play()
    
    local function removeNotification()
        local index = table.find(self.notifications, notification)
        if index then
            table.remove(self.notifications, index)
        end
        
        TweenService:Create(notification, ANIMATIONS.Medium, {
            Position = UDim2.new(1, 0, 1, yOffset),
            BackgroundTransparency = 1
        }):Play()
        
        task.spawn(function()
            task.wait(0.3)
            if notification then
                notification:Destroy()
            end
        end)
    end
    
    task.spawn(function()
        task.wait(duration)
        removeNotification()
    end)
    
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(removeNotification)
        
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeBtn, ANIMATIONS.Fast, {
                TextColor3 = THEME.Error,
                TextSize = 18
            }):Play()
        end)
        
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeBtn, ANIMATIONS.Fast, {
                TextColor3 = THEME.TextSecondary,
                TextSize = 16
            }):Play()
        end)
    end
    
    return notification
end

 -- Watermark Manager Class
local WatermarkManager = {}
WatermarkManager.__index = WatermarkManager

function WatermarkManager.new(library)
    local self = setmetatable({}, WatermarkManager)
    self.library = library
    self.isVisible = true
    self.container = nil
    self.updateConnection = nil
    self.lastUpdate = tick()
    self.frameCount = 0
    self.fps = 0
    
    self:createWatermark()
    self:startUpdating()
    
    return self
end

function WatermarkManager:createWatermark()
    -- Create watermark ScreenGui
    local watermarkGui = safeCreate("ScreenGui", {
        Name = "LynixWatermark_" .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = CoreGui
    })
    
    if not watermarkGui then return end
    
    -- Main watermark container
self.container = safeCreate("Frame", {
    Name = "WatermarkContainer",
    Size = UDim2.new(0, 320, 0, 65),
    Position = UDim2.new(1, -340, 0, 20),
    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
    BorderSizePixel = 0,
    Parent = watermarkGui
})
    if not self.container then return end
    
    -- Styling
    local containerCorner = safeCreate("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.container
    })
    
    local containerStroke = safeCreate("UIStroke", {
        Color = THEME.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = self.container
    })
    
    -- Gradient background
local gradient = safeCreate("UIGradient", {
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 55, 60))
    },
    Rotation = 45,
    Parent = self.container
})
    
    -- Accent line (top)
    local accentLine = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = THEME.Primary,
        BorderSizePixel = 0,
        Parent = self.container
    })
    
    if accentLine then
        local accentCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = accentLine
        })
        
        -- Fix corners for top only
        local accentFix = safeCreate("Frame", {
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = THEME.Primary,
            BorderSizePixel = 0,
            Parent = accentLine
        })
    end
    
    -- Brand section (Lynix)
    local brandFrame = safeCreate("Frame", {
        Size = UDim2.new(0, 100, 1, -10),
        Position = UDim2.new(0, 15, 0, 8),
        BackgroundTransparency = 1,
        Parent = self.container
    })
    
    if brandFrame then
        -- Lynix logo/text
        local brandText = safeCreate("TextLabel", {
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 5),
            BackgroundTransparency = 1,
            Text = "Lynix",
            TextColor3 = THEME.Primary,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = brandFrame
        })
        
        -- Version/subtitle
        local versionText = safeCreate("TextLabel", {
            Size = UDim2.new(1, 0, 0, 15),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = "v1.1 • Config",
            TextColor3 = THEME.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = brandFrame
        })
    end
    
    -- Stats section (Ping & FPS)
local statsFrame = safeCreate("Frame", {
    Size = UDim2.new(0, 180, 1, -5),
    Position = UDim2.new(1, -190, 0, 5),
    BackgroundTransparency = 1,
    Parent = self.container
})
    
    if statsFrame then
 -- FPS Display
        self.fpsLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.5, -5, 0, 25),
            Position = UDim2.new(0, 0, 0, 15),
            BackgroundTransparency = 1,
            Text = "FPS: 60",
            TextColor3 = THEME.Success,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = statsFrame
        })
        
        -- Ping Display
        self.pingLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.5, -5, 0, 25),
            Position = UDim2.new(0.5, 5, 0, 15),
            BackgroundTransparency = 1,
            Text = "Ping: 0ms",
            TextColor3 = THEME.Accent,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = statsFrame
        })
        
        -- Performance indicator bars
        local fpsBar = safeCreate("Frame", {
            Size = UDim2.new(0.5, -10, 0, 4),
            Position = UDim2.new(0, 5, 0, 45),
            BackgroundColor3 = THEME.Success,
            BorderSizePixel = 0,
            Parent = statsFrame
        })
        
        if fpsBar then
            local fpsBarCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 2),
                Parent = fpsBar
            })
            self.fpsBar = fpsBar
        end
        
        local pingBar = safeCreate("Frame", {
            Size = UDim2.new(0.5, -10, 0, 4),
            Position = UDim2.new(0.5, 5, 0, 45),
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Parent = statsFrame
        })
        
        if pingBar then
            local pingBarCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 2),
                Parent = pingBar
            })
            self.pingBar = pingBar
        end
    end
    
    -- Draggable functionality
    self.container.Active = true
    self.container.Draggable = true
    
    -- Smooth entrance animation
self.container.Position = UDim2.new(1, 20, 0, 20)
TweenService:Create(self.container, ANIMATIONS.Bounce, {
    Position = UDim2.new(1, -340, 0, 20)
}):Play()
end

function WatermarkManager:startUpdating()
    -- FPS calculation
    local lastTime = tick()
    local frameBuffer = {}
    local bufferSize = 30
    
    self.updateConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime
        
        -- FPS calculation with smoothing
        table.insert(frameBuffer, 1 / deltaTime)
        if #frameBuffer > bufferSize then
            table.remove(frameBuffer, 1)
        end
        
        local averageFPS = 0
        for _, fps in ipairs(frameBuffer) do
            averageFPS = averageFPS + fps
        end
        averageFPS = math.floor(averageFPS / #frameBuffer)
        
        -- Update every 0.5 seconds for performance
        if currentTime - self.lastUpdate >= 0.5 then
            self:updateStats(averageFPS)
            self.lastUpdate = currentTime
        end
    end)
end

function WatermarkManager:updateStats(fps)
    if not self.fpsLabel or not self.pingLabel then return end
    
    -- Update FPS
    self.fps = fps
    self.fpsLabel.Text = "FPS: " .. tostring(fps)
    
    -- FPS color coding
    local fpsColor = THEME.Success
    if fps < 30 then
        fpsColor = THEME.Error
    elseif fps < 50 then
        fpsColor = THEME.Warning
    end
    
    self.fpsLabel.TextColor3 = fpsColor
    if self.fpsBar then
        self.fpsBar.BackgroundColor3 = fpsColor
        -- Scale bar based on FPS (0-120 range)
        local fpsScale = math.clamp(fps / 120, 0.1, 1)
        TweenService:Create(self.fpsBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(fpsScale * 0.5, -10, 0, 4)
        }):Play()
    end
    
    -- Update Ping
    local ping = self:getPing()
    self.pingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
    
    -- Ping color coding
    local pingColor = THEME.Success
    if ping > 150 then
        pingColor = THEME.Error
    elseif ping > 80 then
        pingColor = THEME.Warning
    end
    
    self.pingLabel.TextColor3 = pingColor
    if self.pingBar then
        self.pingBar.BackgroundColor3 = pingColor
        -- Scale bar based on ping (inverse - lower ping = fuller bar)
        local pingScale = math.clamp(1 - (ping / 300), 0.1, 1)
        TweenService:Create(self.pingBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(pingScale * 0.5, -10, 0, 4)
        }):Play()
    end
end

function WatermarkManager:getPing()
    -- Roblox ping calculation
    local ping = 0
    pcall(function()
        local networkStats = game:GetService("Stats").Network
        if networkStats and networkStats.ServerStatsItem then
            local serverStats = networkStats.ServerStatsItem["Data Ping"]
            if serverStats then
                ping = math.floor(serverStats:GetValue())
            end
        end
    end)
    
    -- Fallback method if above doesn't work
    if ping == 0 then
        pcall(function()
            local replicatedStorage = game:GetService("ReplicatedStorage")
            local statsService = game:GetService("Stats")
            if statsService.Network then
                ping = math.floor(statsService.Network.ServerStatsItem["Data Ping"]:GetValueString():match("%d+") or 0)
            end
        end)
    end
    
    return ping
end

function WatermarkManager:setVisible(visible)
    if not self.container then return end
    
    self.isVisible = visible
    
    if visible then
        self.container.Visible = true
        self.container.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        TweenService:Create(self.container, ANIMATIONS.Medium, {
            Position = UDim2.new(1, -340, 0, 20),
            Size = UDim2.new(0, 320, 0, 65),
            BackgroundTransparency = 0
        }):Play()
    else
        TweenService:Create(self.container, ANIMATIONS.Medium, {
            Position = UDim2.new(1, 20, 0, 20),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        
        task.spawn(function()
            task.wait(0.3)
            if self.container then
                self.container.Visible = false
            end
        end)
    end
end

function WatermarkManager:destroy()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    if self.container and self.container.Parent then
        local watermarkGui = self.container.Parent
TweenService:Create(self.container, ANIMATIONS.Medium, {
    Position = UDim2.new(1, 20, 0, 20),
    Rotation = -15,
    Size = UDim2.new(0, 0, 0, 0)
}):Play()
        
        task.spawn(function()
            task.wait(0.3)
            if watermarkGui then
                watermarkGui:Destroy()
            end
        end)
    end
end

-- Main GUI Library
local GuiLibrary = {}
GuiLibrary.__index = GuiLibrary

function GuiLibrary.new(title)
    local isValid, error = validateInput(title, "string")
    if not isValid then
        warn("Invalid GUI title: " .. error)
        title = "Lynix GUI"
    end
    
    local self = setmetatable({}, GuiLibrary)
    self.title = title
    self.tabs = {}
    self.isVisible = true
    self.isMinimized = false
    self.currentTab = nil
    self.keybinds = {
        toggle = "RightShift"
    }
    
    -- Initialize managers with error handling
    local success, notifManager = pcall(function()
        return NotificationManager.new()
    end)
    self.notificationManager = success and notifManager or nil
    
    local success2, watermarkManager = pcall(function()
        return WatermarkManager.new(self)
    end)
    self.watermarkManager = success2 and watermarkManager or nil
    
    local success3, configManager = pcall(function()
        return ConfigManager.new(self)
    end)
    self.configManager = success3 and configManager or nil
    
    self.connections = {}
    
    self:createGUI()
    self:setupKeybinds()
    
    -- Start auto-save if config manager exists
    if self.configManager then
        self.configManager:startAutoSave()
    end
    
    return self
end

function GuiLibrary:createGUI()
    -- Create main ScreenGui
    self.screenGui = safeCreate("ScreenGui", {
        Name = "LynixGUI_" .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = CoreGui
    })
    
    if not self.screenGui then
        error("Failed to create ScreenGui")
    end
    
    -- Backdrop
    self.backdrop = safeCreate("Frame", {
        Name = "Backdrop",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = self.screenGui
    })
    
    -- Main Container
    self.mainFrame = safeCreate("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0, 900, 0, 600),
        Position = UDim2.new(0.5, -450, 0.5, -300),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        Parent = self.screenGui
    })
    
    if not self.mainFrame then
        error("Failed to create main frame")
    end
    
    local mainCorner = safeCreate("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.mainFrame
    })
    
    self:createHeader()
    self:createSidebar()
    self:createContentArea()
    self:createSettingsTab()
end

function GuiLibrary:createHeader()
    self.header = safeCreate("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = self.mainFrame
    })
    
    if self.header then
        local headerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = self.header
        })
        
        local headerFix = safeCreate("Frame", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 1, -12),
            BackgroundColor3 = THEME.Surface,
            BorderSizePixel = 0,
            Parent = self.header
        })
        
        -- Title
        local title = safeCreate("TextLabel", {
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = self.title,
            TextColor3 = THEME.Primary,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.header
        })
        
        -- Minimize Button (Protected)
        self.minimizeBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 45, 0, 45),
            Position = UDim2.new(1, -105, 0.5, -22.5),
            BackgroundColor3 = THEME.Primary,
            BorderSizePixel = 0,
            Text = "−",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 24,
            Font = Enum.Font.GothamBold,
            ZIndex = 10,
            Parent = self.header
        })
        
        if self.minimizeBtn then
            local minimizeCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = self.minimizeBtn
            })
            
            self.minimizeBtn.MouseEnter:Connect(function()
                TweenService:Create(self.minimizeBtn, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Accent
                }):Play()
            end)
            
            self.minimizeBtn.MouseLeave:Connect(function()
                TweenService:Create(self.minimizeBtn, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Primary
                }):Play()
            end)
            
            self.minimizeBtn.MouseButton1Click:Connect(function()
                self:toggleVisibility()
            end)
        end
        
        -- Close Button (Protected)
        self.closeBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 45, 0, 45),
            Position = UDim2.new(1, -55, 0.5, -22.5),
            BackgroundColor3 = THEME.Error,
            BorderSizePixel = 0,
            Text = "×",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 24,
            Font = Enum.Font.GothamBold,
            ZIndex = 10,
            Parent = self.header
        })
        
        if self.closeBtn then
            local closeCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = self.closeBtn
            })
            
            self.closeBtn.MouseEnter:Connect(function()
                TweenService:Create(self.closeBtn, ANIMATIONS.Fast, {
                    BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                }):Play()
            end)
            
            self.closeBtn.MouseLeave:Connect(function()
                TweenService:Create(self.closeBtn, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Error
                }):Play()
            end)
            
            self.closeBtn.MouseButton1Click:Connect(function()
                self:destroy()
            end)
        end
    end
end

function GuiLibrary:createSidebar()
    self.sidebar = safeCreate("Frame", {
        Size = UDim2.new(0, 200, 1, -60),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = self.mainFrame
    })
    
    -- Normal tabs container (takes most of the space, leaves room for settings)
    self.tabContainer = safeCreate("ScrollingFrame", {
        Size = UDim2.new(1, -10, 0, 450),
        Position = UDim2.new(0, 5, 0, -40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = THEME.Primary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.sidebar
    })
    
    -- Settings area (bottom section, clearly separated)
    self.settingsArea = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 1, -70),
        BackgroundTransparency = 1,
        Parent = self.sidebar
    })
    
    -- Visual separator line above settings
    local separator = safeCreate("Frame", {
        Size = UDim2.new(0.8, 0, 0, 1),
        Position = UDim2.new(0.1, 0, 0, 5),
        BackgroundColor3 = THEME.Border,
        BorderSizePixel = 0,
        Parent = self.settingsArea
    })
end

function GuiLibrary:createContentArea()
    self.contentArea = safeCreate("Frame", {
        Size = UDim2.new(1, -200, 1, -60),
        Position = UDim2.new(0, 200, 0, 60),
        BackgroundTransparency = 1,
        Parent = self.mainFrame
    })
end

function GuiLibrary:createSettingsTab()
    -- Settings tab is protected and always created last
    local settingsTab = self:CreateTab("Settings")
    
    if not settingsTab then
        warn("Failed to create settings tab")
        return
    end
    
    local keybindSection = settingsTab:CreateSection("Keybinds")
    local guiSection = settingsTab:CreateSection("GUI Settings")
    
    if not keybindSection or not guiSection then
        warn("Failed to create settings sections")
        return
    end
    
    -- GUI Toggle Keybind
    keybindSection:CreateKeybind("GUI Toggle", self.keybinds.toggle, function(newKey)
        self.keybinds.toggle = newKey
        self:setupKeybinds()
        self:Notify("Keybind Updated", "GUI toggle set to " .. newKey, "success")
    end)
    
    -- Watermark Toggle
    guiSection:CreateToggle("Show Watermark", self.watermarkManager and self.watermarkManager.isVisible or true, function(enabled)
        if self.watermarkManager then
            self.watermarkManager:setVisible(enabled)
        end
        local status = enabled and "enabled" or "disabled"
        self:Notify("Watermark " .. (enabled and "Enabled" or "Disabled"), 
                   "Watermark display has been " .. status, 
                   enabled and "success" or "info")
    end)
    
    -- Config System
    guiSection:CreateToggle("Auto Save", self.configManager and self.configManager.autoSaveEnabled or true, function(enabled)
        if self.configManager then
            self.configManager.autoSaveEnabled = enabled
            if enabled then
                self.configManager:startAutoSave()
            else
                self.configManager:stopAutoSave()
            end
        end
        self:Notify("Auto Save", "Auto save " .. (enabled and "enabled" or "disabled"), "info")
    end)
    
    guiSection:CreateSlider("Auto Save Interval", 10, 120, self.configManager and self.configManager.autoSaveInterval or 30, function(value)
        if self.configManager then
            self.configManager.autoSaveInterval = value
        end
        self:Notify("Auto Save", "Interval set to " .. value .. " seconds", "info")
    end)
    
    -- Config Management Buttons
    self:createConfigButtons(guiSection)
    
    -- Move settings tab button to bottom left with gear icon
    if settingsTab.button then
        -- Update button styling for settings
        settingsTab.button.BackgroundColor3 = THEME.Primary
        settingsTab.button.Size = UDim2.new(0, 45, 0, 45)
        settingsTab.button.Position = UDim2.new(0, 10, 1, -55)
        
        -- Clear existing text and add gear icon
        local existingText = settingsTab.button:FindFirstChild("TextLabel")
        if existingText then
            existingText:Destroy()
        end
        
        local gearIcon = safeCreate("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "⚙",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 20,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = settingsTab.button
        })
        
        -- Add corner radius to settings button
        local settingsCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = settingsTab.button
        })
        
        -- Update hover effects for gear button
        settingsTab.button.MouseEnter:Connect(function()
            if self.currentTab ~= settingsTab then
                TweenService:Create(settingsTab.button, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Accent,
                    Size = UDim2.new(0, 47, 0, 47)
                }):Play()
                if gearIcon then
                    TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                        TextSize = 22
                    }):Play()
                end
            end
        end)
        
        settingsTab.button.MouseLeave:Connect(function()
            if self.currentTab ~= settingsTab then
                TweenService:Create(settingsTab.button, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Primary,
                    Size = UDim2.new(0, 45, 0, 45)
                }):Play()
                if gearIcon then
                    TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                        TextSize = 20
                    }):Play()
                end
            end
        end)
    end
end

function GuiLibrary:createConfigButtons(section)
    if not section then
        warn("Invalid section for config buttons")
        return
    end
    
    -- Config Dropdown
    local configList = {}
    if self.configManager then
        configList = self.configManager:getConfigList()
    else
        configList = {"Default"}
    end
    
    local configDropdown = section:CreateDropdown("Current Config", configList, function(configName)
        if self.configManager and configName ~= self.configManager.currentConfig then
            self.configManager:loadConfig(configName)
        end
    end)
    
    -- Save Current Config Button
    self:createCustomButton(section, "Save Config", THEME.Success, function()
        if self.configManager then
            self.configManager:saveCurrentConfig()
        else
            self:Notify("Config Error", "Config manager not available", "error")
        end
    end)
    
    -- Create New Config Button
    self:createCustomButton(section, "New Config", THEME.Primary, function()
        self:showConfigNameInput("Create New Config", function(name)
            if self.configManager and self.configManager:createConfig(name) then
                -- Update dropdown with new config
                local newConfigList = self.configManager:getConfigList()
                self:updateDropdownOptions(configDropdown, newConfigList)
                self.configManager.currentConfig = name
            end
        end)
    end)
    
    -- Delete Config Button
    self:createCustomButton(section, "Delete Config", THEME.Error, function()
        if not self.configManager then
            self:Notify("Config Error", "Config manager not available", "error")
            return
        end
        
        if self.configManager.currentConfig == "Default" then
            self:Notify("Config Error", "Cannot delete default config", "error")
            return
        end
        
        self:showConfirmDialog("Delete Config", 
            "Are you sure you want to delete '" .. (self.configManager.currentConfig or "Unknown") .. "'?", 
            function()
                if self.configManager then
                    local configToDelete = self.configManager.currentConfig
                    if self.configManager:deleteConfig(configToDelete) then
                        -- Update dropdown
                        local newConfigList = self.configManager:getConfigList()
                        self:updateDropdownOptions(configDropdown, newConfigList)
                    end
                end
            end
        )
    end)
    
    -- Export Config Button
    self:createCustomButton(section, "Export Config", THEME.Warning, function()
        if not self.configManager then
            self:Notify("Config Error", "Config manager not available", "error")
            return
        end
        
        local exportData = self.configManager:exportConfig()
        if exportData then
            -- Create export window
            self:showExportWindow(exportData)
        else
            self:Notify("Export Error", "Failed to export config", "error")
        end
    end)
    
    -- Import Config Button
    self:createCustomButton(section, "Import Config", THEME.Accent, function()
        self:showImportWindow(function(jsonData, configName)
            if self.configManager and self.configManager:importConfig(jsonData, configName) then
                -- Update dropdown
                local newConfigList = self.configManager:getConfigList()
                self:updateDropdownOptions(configDropdown, newConfigList)
            end
        end)
    end)
end

function GuiLibrary:createCustomButton(section, text, color, callback)
    local elementIndex = #section.elements
    local yPos = elementIndex * 80 + 10
    
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = section.container
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local button = safeCreate("TextButton", {
            Size = UDim2.new(1, -20, 0, 50),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = container
        })
        
        if button then
            local buttonCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = button
            })
            
            button.MouseEnter:Connect(function()
                TweenService:Create(button, ANIMATIONS.Fast, {
                    BackgroundColor3 = Color3.fromRGB(
                        math.min(255, color.R * 255 + 30),
                        math.min(255, color.G * 255 + 30),
                        math.min(255, color.B * 255 + 30)
                    )
                }):Play()
            end)
            
            button.MouseLeave:Connect(function()
                TweenService:Create(button, ANIMATIONS.Fast, {
                    BackgroundColor3 = color
                }):Play()
            end)
            
            button.MouseButton1Click:Connect(callback)
        end
        
        -- Add to section elements
        table.insert(section.elements, {
            name = text,
            type = "button",
            container = container
        })
        
        -- Update canvas size
        if section.container then
            section.container.CanvasSize = UDim2.new(0, 0, 0, #section.elements * 80 + 20)
        end
    end
end

function GuiLibrary:showConfigNameInput(title, callback)
    -- Create backdrop first
    local backdrop = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 19,
        Parent = self.screenGui
    })
    
    local inputDialog = safeCreate("Frame", {
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0.5, -200, 0.5, -100),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = self.screenGui
    })
    
    if inputDialog then
        local dialogCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = inputDialog
        })
        
        local dialogStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = inputDialog
        })
        
        -- Title
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Primary,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 21,
            Parent = inputDialog
        })
        
        -- Input Box
        local inputBox = safeCreate("TextBox", {
            Size = UDim2.new(1, -40, 0, 40),
            Position = UDim2.new(0, 20, 0, 60),
            BackgroundColor3 = THEME.Surface,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Enter config name...",
            TextColor3 = THEME.Text,
            PlaceholderColor3 = THEME.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            ZIndex = 21,
            Parent = inputDialog
        })
        
        if inputBox then
            local inputCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = inputBox
            })
            
            local inputStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = inputBox
            })
        end
        
        -- Buttons
        local createBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(0, 60, 1, -50),
            BackgroundColor3 = THEME.Success,
            BorderSizePixel = 0,
            Text = "Create",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = inputDialog
        })
        
        local cancelBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(1, -180, 1, -50),
            BackgroundColor3 = THEME.Error,
            BorderSizePixel = 0,
            Text = "Cancel",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = inputDialog
        })
        
        if createBtn then
            local createCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = createBtn
            })
        end
        
        if cancelBtn then
            local cancelCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = cancelBtn
            })
        end
        
        local function closeDialog()
            if backdrop then backdrop:Destroy() end
            if inputDialog then inputDialog:Destroy() end
        end
        
        -- Button events
        if createBtn and inputBox then
            createBtn.MouseButton1Click:Connect(function()
                local configName = inputBox.Text
                if configName and configName ~= "" then
                    callback(configName)
                    closeDialog()
                else
                    self:Notify("Config Error", "Please enter a valid name", "error")
                end
            end)
        end
        
        if cancelBtn then
            cancelBtn.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Click backdrop to close
        if backdrop then
            backdrop.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Entrance animation
        inputDialog.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(inputDialog, ANIMATIONS.Bounce, {
            Size = UDim2.new(0, 400, 0, 200)
        }):Play()
    end
end

function GuiLibrary:showConfirmDialog(title, message, callback)
    -- Create backdrop
    local backdrop = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 19,
        Parent = self.screenGui
    })
    
    local confirmDialog = safeCreate("Frame", {
        Size = UDim2.new(0, 400, 0, 180),
        Position = UDim2.new(0.5, -200, 0.5, -90),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = self.screenGui
    })
    
    if confirmDialog then
        local dialogCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = confirmDialog
        })
        
        local dialogStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = confirmDialog
        })
        
        -- Title
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Primary,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 21,
            Parent = confirmDialog
        })
        
        -- Message
        local messageLabel = safeCreate("TextLabel", {
            Size = UDim2.new(1, -40, 0, 60),
            Position = UDim2.new(0, 20, 0, 50),
            BackgroundTransparency = 1,
            Text = message,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            ZIndex = 21,
            Parent = confirmDialog
        })
        
        -- Buttons
        local confirmBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(0, 60, 1, -50),
            BackgroundColor3 = THEME.Error,
            BorderSizePixel = 0,
            Text = "Confirm",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = confirmDialog
        })
        
        local cancelBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(1, -180, 1, -50),
            BackgroundColor3 = THEME.Border,
            BorderSizePixel = 0,
            Text = "Cancel",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = confirmDialog
        })
        
        if confirmBtn then
            local confirmCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = confirmBtn
            })
        end
        
        if cancelBtn then
            local cancelCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = cancelBtn
            })
        end
        
        local function closeDialog()
            if backdrop then backdrop:Destroy() end
            if confirmDialog then confirmDialog:Destroy() end
        end
        
        if confirmBtn then
            confirmBtn.MouseButton1Click:Connect(function()
                callback()
                closeDialog()
            end)
        end
        
        if cancelBtn then
            cancelBtn.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Click backdrop to close
        if backdrop then
            backdrop.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Entrance animation
        confirmDialog.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(confirmDialog, ANIMATIONS.Bounce, {
            Size = UDim2.new(0, 400, 0, 180)
        }):Play()
    end
end

function GuiLibrary:showExportWindow(exportData)
    -- Create backdrop
    local backdrop = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 19,
        Parent = self.screenGui
    })
    
    local exportDialog = safeCreate("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = self.screenGui
    })
    
    if exportDialog then
        local dialogCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = exportDialog
        })
        
        local dialogStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = exportDialog
        })
        
        -- Title
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = "Export Config",
            TextColor3 = THEME.Primary,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 21,
            Parent = exportDialog
        })
        
        -- Export text box
        local exportBox = safeCreate("TextBox", {
            Size = UDim2.new(1, -40, 1, -120),
            Position = UDim2.new(0, 20, 0, 60),
            BackgroundColor3 = THEME.Surface,
            BorderSizePixel = 0,
            Text = exportData,
            TextColor3 = THEME.Text,
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            MultiLine = true,
            ClearTextOnFocus = false,
            ZIndex = 21,
            Parent = exportDialog
        })
        
        if exportBox then
            local exportCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = exportBox
            })
            
            local exportStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = exportBox
            })
        end
        
        -- Copy button
        local copyBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 140, 0, 35),
            Position = UDim2.new(0, 60, 1, -50),
            BackgroundColor3 = THEME.Success,
            BorderSizePixel = 0,
            Text = "Copy to Clipboard",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = exportDialog
        })
        
        local closeBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(1, -180, 1, -50),
            BackgroundColor3 = THEME.Border,
            BorderSizePixel = 0,
            Text = "Close",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = exportDialog
        })
        
        if copyBtn then
            local copyCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = copyBtn
            })
        end
        
        if closeBtn then
            local closeCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = closeBtn
            })
        end
        
        local function closeDialog()
            if backdrop then backdrop:Destroy() end
            if exportDialog then exportDialog:Destroy() end
        end
        
        if copyBtn then
            copyBtn.MouseButton1Click:Connect(function()
                -- Try to copy to clipboard
                pcall(function()
                    setclipboard(exportData)
                    self:Notify("Export", "Config copied to clipboard!", "success")
                end)
            end)
        end
        
        if closeBtn then
            closeBtn.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Click backdrop to close
        if backdrop then
            backdrop.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Entrance animation
        exportDialog.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(exportDialog, ANIMATIONS.Bounce, {
            Size = UDim2.new(0, 500, 0, 400)
        }):Play()
    end
end
                CornerRadius = UDim.new(0, 8),
                Parent = closeBtn
            })
            
            closeBtn.MouseButton1Click:Connect(function()
                exportDialog:Destroy()
            end)
        end
        
        -- Entrance animation
        exportDialog.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(exportDialog, ANIMATIONS.Bounce, {
            Size = UDim2.new(0, 500, 0, 400)
        }):Play()
    end
end

function GuiLibrary:showImportWindow(callback)
    -- Create backdrop
    local backdrop = safeCreate("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 19,
        Parent = self.screenGui
    })
    
    local importDialog = safeCreate("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = self.screenGui
    })
    
    if importDialog then
        local dialogCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = importDialog
        })
        
        local dialogStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = importDialog
        })
        
        -- Title
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = "Import Config",
            TextColor3 = THEME.Primary,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 21,
            Parent = importDialog
        })
        
        -- Import text box
        local importBox = safeCreate("TextBox", {
            Size = UDim2.new(1, -40, 1, -160),
            Position = UDim2.new(0, 20, 0, 60),
            BackgroundColor3 = THEME.Surface,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Paste config JSON here...",
            TextColor3 = THEME.Text,
            PlaceholderColor3 = THEME.TextSecondary,
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            MultiLine = true,
            ClearTextOnFocus = false,
            ZIndex = 21,
            Parent = importDialog
        })
        
        if importBox then
            local importCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = importBox
            })
            
            local importStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = importBox
            })
        end
        
        -- Config name input
        local nameBox = safeCreate("TextBox", {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 1, -120),
            BackgroundColor3 = THEME.Surface,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = "Config name (optional)",
            TextColor3 = THEME.Text,
            PlaceholderColor3 = THEME.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            ZIndex = 21,
            Parent = importDialog
        })
        
        if nameBox then
            local nameCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = nameBox
            })
            
            local nameStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = nameBox
            })
        end
        
        -- Buttons
        local importBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(0, 60, 1, -50),
            BackgroundColor3 = THEME.Success,
            BorderSizePixel = 0,
            Text = "Import",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = importDialog
        })
        
        local cancelBtn = safeCreate("TextButton", {
            Size = UDim2.new(0, 120, 0, 35),
            Position = UDim2.new(1, -180, 1, -50),
            BackgroundColor3 = THEME.Border,
            BorderSizePixel = 0,
            Text = "Cancel",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            ZIndex = 21,
            Parent = importDialog
        })
        
        if importBtn then
            local importCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = importBtn
            })
        end
        
        if cancelBtn then
            local cancelCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = cancelBtn
            })
        end
        
        local function closeDialog()
            if backdrop then backdrop:Destroy() end
            if importDialog then importDialog:Destroy() end
        end
        
        if importBtn then
            importBtn.MouseButton1Click:Connect(function()
                local jsonData = importBox.Text
                local configName = nameBox.Text
                
                if jsonData and jsonData ~= "" then
                    callback(jsonData, configName ~= "" and configName or nil)
                    closeDialog()
                else
                    self:Notify("Import Error", "Please paste valid JSON data", "error")
                end
            end)
        end
        
        if cancelBtn then
            cancelBtn.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Click backdrop to close
        if backdrop then
            backdrop.MouseButton1Click:Connect(function()
                closeDialog()
            end)
        end
        
        -- Entrance animation
        importDialog.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(importDialog, ANIMATIONS.Bounce, {
            Size = UDim2.new(0, 500, 0, 400)
        }):Play()
    end
end

function GuiLibrary:updateDropdownOptions(dropdownElement, newOptions)
    if not dropdownElement or not dropdownElement.container then return end
    
    -- This is a simplified version - in a real implementation,
    -- you'd need to rebuild the dropdown's option list
    -- For now, we'll just notify that the config list has changed
    self:Notify("Config List", "Config list updated", "info", 1)
end

function GuiLibrary:CreateTab(name)
    local isValid, error = validateInput(name, "string")
    if not isValid then
        warn("Invalid tab name: " .. error)
        return nil
    end
    
    local tab = {
        name = name,
        sections = {},
        content = nil,
        button = nil,
        library = self
    }
    
    -- Create content frame
    tab.content = safeCreate("Frame", {
        Name = name .. "Content",
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.contentArea
    })
    
    -- Create tab button (special handling for Settings tab)
    local tabIndex = #self.tabs + 1
    local isSettingsTab = (name == "Settings")
    
    if isSettingsTab then
        -- Settings tab goes in the dedicated settings area at the bottom
        tab.button = safeCreate("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(0, 45, 0, 45),
            Position = UDim2.new(0, 10, 0, 15), -- Position within settings area
            BackgroundTransparency = 1, -- TRANSPARENT BACKGROUND
            BorderSizePixel = 0,
            Text = "",
            Parent = self.settingsArea -- Use settings area instead of sidebar
        })
    else
        -- Normal tabs go in the tab container, positioned from top
        tab.button = safeCreate("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, -10, 0, 45),
            Position = UDim2.new(0, 5, 0, (tabIndex - 1) * 50),
            BackgroundColor3 = THEME.SurfaceLight,
            BorderSizePixel = 0,
            Text = "",
            Parent = self.tabContainer
        })
    end
    
    if tab.button then
        local buttonCorner = safeCreate("UICorner", {
            CornerRadius = isSettingsTab and UDim.new(0, 10) or UDim.new(0, 8),
            Parent = tab.button
        })
        
        if not isSettingsTab then
            local textLabel = safeCreate("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = THEME.TextSecondary,
                TextSize = 14,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tab.button
            })
        else
            -- Add gear icon for settings tab
            local gearIcon = safeCreate("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "⚙",
                TextColor3 = THEME.Primary, -- BLUE GEAR
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = tab.button
            })
        end
        
        tab.button.MouseButton1Click:Connect(function()
            self:switchToTab(tab)
        end)
        
        tab.button.MouseEnter:Connect(function()
            if self.currentTab ~= tab then
                if isSettingsTab then
                    local gearIcon = tab.button:FindFirstChildOfClass("TextLabel")
                    if gearIcon then
                        TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                            TextColor3 = THEME.Accent, -- Lighter blue on hover
                            TextSize = 22
                        }):Play()
                    end
                else
                    TweenService:Create(tab.button, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.Border
                    }):Play()
                end
            end
        end)
        
        tab.button.MouseLeave:Connect(function()
            if self.currentTab ~= tab then
                if isSettingsTab then
                    local gearIcon = tab.button:FindFirstChildOfClass("TextLabel")
                    if gearIcon then
                        TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                            TextColor3 = THEME.Primary, -- Back to blue
                            TextSize = 20
                        }):Play()
                    end
                else
                    TweenService:Create(tab.button, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.SurfaceLight
                    }):Play()
                end
            end
        end)
    end
    
    -- Update canvas size only for normal tabs (not settings)
    if self.tabContainer and not isSettingsTab then
        local normalTabCount = 0
        for _, existingTab in pairs(self.tabs) do
            if existingTab.name ~= "Settings" then
                normalTabCount = normalTabCount + 1
            end
        end
        -- Account for the spacing (50px per tab)
        self.tabContainer.CanvasSize = UDim2.new(0, 0, 0, normalTabCount * 50 + 60)
    end
    
    table.insert(self.tabs, tab)
    
    -- Set as current tab if it's the first NON-SETTINGS tab
    if #self.tabs == 1 and not isSettingsTab then
        self:switchToTab(tab)
    elseif #self.tabs == 2 and isSettingsTab then
        -- If we just added settings as second tab, switch to first tab
        for _, existingTab in pairs(self.tabs) do
            if existingTab.name ~= "Settings" then
                self:switchToTab(existingTab)
                break
            end
        end
    end
    
    -- Add CreateSection method to tab
    function tab:CreateSection(sectionName)
        local isValid, error = validateInput(sectionName, "string")
        if not isValid then
            warn("Invalid section name: " .. error)
            return nil
        end
        
        if #self.sections >= 2 then
            warn("Tab '" .. self.name .. "' already has 2 sections (maximum allowed)")
            return nil
        end
        
        local section = {
            name = sectionName,
            elements = {},
            container = nil,
            tab = self
        }
        
        local sectionIndex = #self.sections + 1
        local xPos = sectionIndex == 1 and 10 or 360
        local width = 320
        
        section.container = self.library:createSection(self.content, sectionName, xPos, width)
        
        table.insert(self.sections, section)
        
        -- Add element creation methods
        function section:CreateToggle(name, default, callback)
            return self.tab.library:createElement(self, "toggle", name, default, callback)
        end
        
        function section:CreateSlider(name, min, max, default, callback)
            return self.tab.library:createElement(self, "slider", name, {min, max, default}, callback)
        end
        
        function section:CreateDropdown(name, options, callback)
            return self.tab.library:createElement(self, "dropdown", name, options, callback)
        end
        
        function section:CreateColorPicker(name, default, callback)
            return self.tab.library:createElement(self, "colorpicker", name, default, callback)
        end
        
        function section:CreateKeybind(name, default, callback)
            return self.tab.library:createElement(self, "keybind", name, default, callback)
        end
        
        return section
    end
    
    return tab
end

function GuiLibrary:createSection(parent, title, xPos, width)
    if not parent then return nil end
    
    local section = safeCreate("Frame", {
        Name = title .. "Section",
        Size = UDim2.new(0, width, 1, -20),
        Position = UDim2.new(0, xPos, 0, 10),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    if section then
        local header = safeCreate("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = THEME.SurfaceLight,
            BorderSizePixel = 0,
            Parent = section
        })
        
        if header then
            local headerCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = header
            })
            
            local headerStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = header
            })
            
            local titleLabel = safeCreate("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = THEME.Primary,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = header
            })
            
            local accentLine = safeCreate("Frame", {
                Size = UDim2.new(0, 4, 0, 20),
                Position = UDim2.new(0, 0, 0.5, -10),
                BackgroundColor3 = THEME.Primary,
                BorderSizePixel = 0,
                Parent = header
            })
            
            if accentLine then
                local lineCorner = safeCreate("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                    Parent = accentLine
                })
            end
        end
        
        local contentContainer = safeCreate("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -50),
            Position = UDim2.new(0, 0, 0, 50),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = THEME.Primary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = section
        })
        
        return contentContainer
    end
    
    return nil
end

function GuiLibrary:createElement(section, elementType, name, data, callback)
    -- Input validation
    local isValid, error = validateInput(name, "string")
    if not isValid then
        warn("Invalid element name: " .. error)
        return nil
    end
    
    if type(callback) ~= "function" then
        warn("Invalid callback function")
        return nil
    end
    
    local elementIndex = #section.elements
    local yPos = elementIndex * 80 + 10
    
    local element = {
        name = name,
        type = elementType,
        value = nil,
        callback = callback,
        container = nil,
        section = section,
        tab = section.tab
    }
    
    if elementType == "toggle" then
        element.value = data or false
        element.container = self:createToggle(section.container, name, element.value, yPos, function(newValue)
            element.value = newValue
            pcall(callback, newValue)
        end)
        
    elseif elementType == "slider" then
        local min, max, default = data[1], data[2], data[3]
        element.min = min
        element.max = max
        element.value = default or min
        element.container = self:createSlider(section.container, name, min, max, element.value, yPos, function(newValue)
            element.value = newValue
            pcall(callback, newValue)
        end)
        
    elseif elementType == "dropdown" then
        element.value = data[1] or ""
        element.options = data
        element.container = self:createDropdown(section.container, name, data, element.value, yPos, function(newValue)
            element.value = newValue
            pcall(callback, newValue)
        end)
        
    elseif elementType == "colorpicker" then
        element.value = data or Color3.fromRGB(255, 255, 255)
        element.container = self:createColorPicker(section.container, name, element.value, yPos, function(newValue)
            element.value = newValue
            pcall(callback, newValue)
        end)
        
    elseif elementType == "keybind" then
        element.value = data or "None"
        element.container = self:createKeybind(section.container, name, element.value, yPos, function(newValue)
            element.value = newValue
            pcall(callback, newValue)
        end)
    end
    
    table.insert(section.elements, element)
    
    -- Register element with config manager
    self.configManager:registerElement(element)
    
    -- Update canvas size
    if section.container then
        section.container.CanvasSize = UDim2.new(0, 0, 0, #section.elements * 80 + 20)
    end
    
    return element
end

function GuiLibrary:createToggle(parent, title, default, yPos, callback)
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local toggleBG = safeCreate("Frame", {
            Name = "ToggleBG",
            Size = UDim2.new(0, 50, 0, 25),
            Position = UDim2.new(1, -70, 0.5, -12.5),
            BackgroundColor3 = default and THEME.Primary or THEME.Border,
            BorderSizePixel = 0,
            Parent = container
        })
        
        if toggleBG then
            local toggleCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 12.5),
                Parent = toggleBG
            })
            
            local toggleButton = safeCreate("Frame", {
                Name = "ToggleButton",
                Size = UDim2.new(0, 21, 0, 21),
                Position = default and UDim2.new(0, 27, 0, 2) or UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = toggleBG
            })
            
            if toggleButton then
                local buttonCorner = safeCreate("UICorner", {
                    CornerRadius = UDim.new(0, 10.5),
                    Parent = toggleButton
                })
                
                local clickButton = safeCreate("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = container
                })
                
                local currentValue = default
                
                if clickButton then
                    clickButton.MouseEnter:Connect(function()
                        TweenService:Create(container, ANIMATIONS.Fast, {
                            BackgroundColor3 = THEME.SurfaceLight
                        }):Play()
                    end)
                    
                    clickButton.MouseLeave:Connect(function()
                        TweenService:Create(container, ANIMATIONS.Fast, {
                            BackgroundColor3 = THEME.Surface
                        }):Play()
                    end)
                    
                    clickButton.MouseButton1Click:Connect(function()
                        currentValue = not currentValue
                        
                        local newPos = currentValue and UDim2.new(0, 27, 0, 2) or UDim2.new(0, 2, 0, 2)
                        local newColor = currentValue and THEME.Primary or THEME.Border
                        
                        TweenService:Create(toggleButton, ANIMATIONS.Medium, {Position = newPos}):Play()
                        TweenService:Create(toggleBG, ANIMATIONS.Medium, {BackgroundColor3 = newColor}):Play()
                        
                        callback(currentValue)
                    end)
                end
            end
        end
    end
    
    return container
end

function GuiLibrary:createSlider(parent, title, minValue, maxValue, default, yPos, callback)
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.5, 0, 0.5, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local valueLabel = safeCreate("TextLabel", {
            Name = "ValueLabel",
            Size = UDim2.new(0.25, 0, 0.5, 0),
            Position = UDim2.new(0.75, -20, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(default),
            TextColor3 = THEME.Primary,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local sliderTrack = safeCreate("Frame", {
            Name = "SliderTrack",
            Size = UDim2.new(0.85, -40, 0, 8),
            Position = UDim2.new(0, 20, 0.7, -4),
            BackgroundColor3 = THEME.SurfaceLight,
            BorderSizePixel = 0,
            Parent = container
        })
        
        if sliderTrack then
            local trackCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = sliderTrack
            })
            
            local currentValue = (default - minValue) / (maxValue - minValue)
            local sliderFill = safeCreate("Frame", {
                Name = "SliderFill",
                Size = UDim2.new(currentValue, 0, 1, 0),
                BackgroundColor3 = THEME.Primary,
                BorderSizePixel = 0,
                Parent = sliderTrack
            })
            
            if sliderFill then
                local fillCorner = safeCreate("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = sliderFill
                })
            end
            
            local dragging = false
            local dragConnection = nil
            
            local clickArea = safeCreate("TextButton", {
                Size = UDim2.new(1, 0, 1, 10),
                Position = UDim2.new(0, 0, 0, -5),
                BackgroundTransparency = 1,
                Text = "",
                Parent = sliderTrack
            })
            
            local function updateSlider(mouseX)
                local trackPos = sliderTrack.AbsolutePosition.X
                local trackSize = sliderTrack.AbsoluteSize.X
                
                local relativeX = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
                local newValue = math.floor(minValue + (maxValue - minValue) * relativeX)
                
                valueLabel.Text = tostring(newValue)
                
                TweenService:Create(sliderFill, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {
                    Size = UDim2.new(relativeX, 0, 1, 0)
                }):Play()
                
                callback(newValue)
            end
            
            if clickArea then
                clickArea.MouseButton1Down:Connect(function()
                    dragging = true
                    updateSlider(UserInputService:GetMouseLocation().X)
                    
                    dragConnection = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                            updateSlider(input.Position.X)
                        end
                    end)
                end)
                
                table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                        dragging = false
                        if dragConnection then
                            dragConnection:Disconnect()
                            dragConnection = nil
                        end
                    end
                end))
                
                clickArea.MouseButton1Click:Connect(function()
                    if not dragging then
                        updateSlider(UserInputService:GetMouseLocation().X)
                    end
                end)
                
                clickArea.MouseEnter:Connect(function()
                    TweenService:Create(container, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.SurfaceLight
                    }):Play()
                end)
                
                clickArea.MouseLeave:Connect(function()
                    TweenService:Create(container, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.Surface
                    }):Play()
                end)
            end
        end
    end
    
    return container
end

function GuiLibrary:createDropdown(parent, title, options, default, yPos, callback)
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local dropdownBtn = safeCreate("TextButton", {
            Name = "DropdownBtn",
            Size = UDim2.new(0, 160, 0, 35),
            Position = UDim2.new(1, -180, 0.5, -17.5),
            BackgroundColor3 = THEME.SurfaceLight,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 2,
            Parent = container
        })
        
        if dropdownBtn then
            local dropdownCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = dropdownBtn
            })
            
            local dropdownStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = dropdownBtn
            })
            
            local selectedLabel = safeCreate("TextLabel", {
                Name = "SelectedLabel",
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = default,
                TextColor3 = THEME.Text,
                TextSize = 14,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3,
                Parent = dropdownBtn
            })
            
            local arrow = safeCreate("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -25, 0, 0),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = THEME.Primary,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3,
                Parent = dropdownBtn
            })
            
            local dropdownList = safeCreate("Frame", {
                Size = UDim2.new(0, 160, 0, 0),
                Position = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = THEME.Background,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 15,
                ClipsDescendants = true,
                Parent = dropdownBtn
            })
            
            if dropdownList then
                local listCorner = safeCreate("UICorner", {
                    CornerRadius = UDim.new(0, 10),
                    Parent = dropdownList
                })
                
                local listStroke = safeCreate("UIStroke", {
                    Color = THEME.Border,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = dropdownList
                })
                
                local scrollFrame = safeCreate("ScrollingFrame", {
                    Size = UDim2.new(1, -8, 1, -8),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 4,
                    ScrollBarImageColor3 = THEME.Primary,
                    CanvasSize = UDim2.new(0, 0, 0, #options * 40),
                    ZIndex = 16,
                    Parent = dropdownList
                })
                
                for i, option in ipairs(options) do
                    local optionBtn = safeCreate("TextButton", {
                        Size = UDim2.new(1, -8, 0, 38),
                        Position = UDim2.new(0, 4, 0, (i - 1) * 40 + 2),
                        BackgroundColor3 = THEME.SurfaceLight,
                        BorderSizePixel = 0,
                        Text = "",
                        ZIndex = 17,
                        Parent = scrollFrame
                    })
                    
                    if optionBtn then
                        local optionCorner = safeCreate("UICorner", {
                            CornerRadius = UDim.new(0, 8),
                            Parent = optionBtn
                        })
                        
                        local optionText = safeCreate("TextLabel", {
                            Size = UDim2.new(1, -20, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = option,
                            TextColor3 = THEME.Text,
                            TextSize = 14,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                            ZIndex = 18,
                            Parent = optionBtn
                        })
                        
                        optionBtn.MouseEnter:Connect(function()
                            TweenService:Create(optionBtn, ANIMATIONS.Fast, {
                                BackgroundColor3 = THEME.Primary
                            }):Play()
                        end)
                        
                        optionBtn.MouseLeave:Connect(function()
                            TweenService:Create(optionBtn, ANIMATIONS.Fast, {
                                BackgroundColor3 = THEME.SurfaceLight
                            }):Play()
                        end)
                        
                        optionBtn.MouseButton1Click:Connect(function()
                            selectedLabel.Text = option
                            dropdownList.Visible = false
                            dropdownList.Size = UDim2.new(0, 160, 0, 0)
                            arrow.Rotation = 0
                            callback(option)
                        end)
                    end
                end
                
                dropdownBtn.MouseButton1Click:Connect(function()
                    if dropdownList.Visible then
                        TweenService:Create(dropdownList, ANIMATIONS.Medium, {
                            Size = UDim2.new(0, 160, 0, 0)
                        }):Play()
                        TweenService:Create(arrow, ANIMATIONS.Medium, {
                            Rotation = 0
                        }):Play()
                        task.spawn(function()
                            task.wait(0.25)
                            dropdownList.Visible = false
                        end)
                    else
                        dropdownList.Visible = true
                        dropdownList.Size = UDim2.new(0, 160, 0, 0)
                        local maxHeight = math.min(#options * 40 + 8, 200)
                        TweenService:Create(dropdownList, ANIMATIONS.Medium, {
                            Size = UDim2.new(0, 160, 0, maxHeight)
                        }):Play()
                        TweenService:Create(arrow, ANIMATIONS.Medium, {
                            Rotation = 180
                        }):Play()
                    end
                end)
            end
        end
    end
    
    return container
end

function GuiLibrary:createColorPicker(parent, title, default, yPos, callback)
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local colorPreview = safeCreate("Frame", {
            Name = "ColorPreview",
            Size = UDim2.new(0, 80, 0, 35),
            Position = UDim2.new(1, -100, 0.5, -17.5),
            BackgroundColor3 = default,
            BorderSizePixel = 0,
            Parent = container
        })
        
        if colorPreview then
            local previewCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = colorPreview
            })
            
            local previewStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = colorPreview
            })
            
            local colorButton = safeCreate("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = colorPreview
            })
            
            if colorButton then
                local isPickerOpen = false
                
                colorButton.MouseEnter:Connect(function()
                    TweenService:Create(container, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.SurfaceLight
                    }):Play()
                end)
                
                colorButton.MouseLeave:Connect(function()
                    TweenService:Create(container, ANIMATIONS.Fast, {
                        BackgroundColor3 = THEME.Surface
                    }):Play()
                end)
                
                colorButton.MouseButton1Click:Connect(function()
                    if isPickerOpen then return end
                    isPickerOpen = true
                    
                    local colorPicker = safeCreate("Frame", {
                        Size = UDim2.new(0, 0, 0, 0),
                        Position = UDim2.new(1, -40, 0.5, 0),
                        BackgroundColor3 = THEME.Background,
                        BorderSizePixel = 0,
                        ZIndex = 10,
                        Parent = container
                    })
                    
                    if colorPicker then
                        local pickerCorner = safeCreate("UICorner", {
                            CornerRadius = UDim.new(0, 10),
                            Parent = colorPicker
                        })
                        
                        local pickerStroke = safeCreate("UIStroke", {
                            Color = THEME.Border,
                            Thickness = 1,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            Parent = colorPicker
                        })
                        
                        -- Simple color palette
                        local colors = {
                            Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100), Color3.fromRGB(0, 0, 0),
                            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
                            Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 165, 0), Color3.fromRGB(128, 0, 128)
                        }
                        
                        for i, color in ipairs(colors) do
                            local row = math.floor((i - 1) / 4)
                            local col = (i - 1) % 4
                            
                            local colorBtn = safeCreate("Frame", {
                                Size = UDim2.new(0, 30, 0, 30),
                                Position = UDim2.new(0, 10 + col * 35, 0, 10 + row * 35),
                                BackgroundColor3 = color,
                                BorderSizePixel = 0,
                                ZIndex = 12,
                                Parent = colorPicker
                            })
                            
                            if colorBtn then
                                local colorCorner = safeCreate("UICorner", {
                                    CornerRadius = UDim.new(0, 6),
                                    Parent = colorBtn
                                })
                                
                                local colorClickBtn = safeCreate("TextButton", {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    BackgroundTransparency = 1,
                                    Text = "",
                                    ZIndex = 13,
                                    Parent = colorBtn
                                })
                                
                                colorClickBtn.MouseButton1Click:Connect(function()
                                    colorPreview.BackgroundColor3 = color
                                    callback(color)
                                    TweenService:Create(colorPicker, ANIMATIONS.Medium, {
                                        Size = UDim2.new(0, 0, 0, 0)
                                    }):Play()
                                    task.spawn(function()
                                        task.wait(0.3)
                                        colorPicker:Destroy()
                                        isPickerOpen = false
                                    end)
                                end)
                            end
                        end
                        
                        TweenService:Create(colorPicker, ANIMATIONS.Bounce, {
                            Size = UDim2.new(0, 160, 0, 120),
                            Position = UDim2.new(1, -170, 0.5, -60)
                        }):Play()
                    end
                end)
            end
        end
    end
    
    return container
end

function GuiLibrary:createKeybind(parent, title, default, yPos, callback)
    local container = safeCreate("Frame", {
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if container then
        local containerCorner = safeCreate("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = container
        })
        
        local borderStroke = safeCreate("UIStroke", {
            Color = THEME.Border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = container
        })
        
        local titleLabel = safeCreate("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = container
        })
        
        local keybindBtn = safeCreate("TextButton", {
            Name = "KeybindBtn",
            Size = UDim2.new(0, 160, 0, 35),
            Position = UDim2.new(1, -180, 0.5, -17.5),
            BackgroundColor3 = THEME.SurfaceLight,
            BorderSizePixel = 0,
            Text = default,
            TextColor3 = THEME.Text,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            ZIndex = 2,
            Parent = container
        })
        
        if keybindBtn then
            local keybindCorner = safeCreate("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = keybindBtn
            })
            
            local keybindStroke = safeCreate("UIStroke", {
                Color = THEME.Border,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = keybindBtn
            })
            
            local isBinding = false
            local bindingConnection = nil
            
            keybindBtn.MouseButton1Click:Connect(function()
                if bindingConnection then
                    bindingConnection:Disconnect()
                    bindingConnection = nil
                end
                
                if isBinding then
                    isBinding = false
                    keybindBtn.Text = default
                    keybindBtn.TextColor3 = THEME.Text
                    keybindBtn.BackgroundColor3 = THEME.SurfaceLight
                    return
                end
                
                isBinding = true
                keybindBtn.Text = "Press any key..."
                keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                keybindBtn.BackgroundColor3 = THEME.Primary
                
                bindingConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    
                    local keyName = input.KeyCode.Name
                    
                    if keyName == "LeftShift" or keyName == "RightShift" or 
                       keyName == "LeftControl" or keyName == "RightControl" or
                       keyName == "LeftAlt" or keyName == "RightAlt" or
                       keyName == "Unknown" then
                        return
                    end
                    
                    keybindBtn.Text = keyName
                    keybindBtn.TextColor3 = THEME.Text
                    keybindBtn.BackgroundColor3 = THEME.SurfaceLight
                    
                    callback(keyName)
                    
                    bindingConnection:Disconnect()
                    bindingConnection = nil
                    isBinding = false
                end)
                
                task.spawn(function()
                    task.wait(8)
                    if isBinding and bindingConnection then
                        bindingConnection:Disconnect()
                        bindingConnection = nil
                        isBinding = false
                        keybindBtn.Text = default
                        keybindBtn.TextColor3 = THEME.Text
                        keybindBtn.BackgroundColor3 = THEME.SurfaceLight
                    end
                end)
            end)
            
            keybindBtn.MouseEnter:Connect(function()
                if not isBinding then
                    keybindBtn.BackgroundColor3 = THEME.Border
                end
            end)
            
            keybindBtn.MouseLeave:Connect(function()
                if not isBinding then
                    keybindBtn.BackgroundColor3 = THEME.SurfaceLight
                end
            end)
        end
    end
    
    return container
end

function GuiLibrary:switchToTab(tab)
    if self.currentTab == tab then return end
    
    -- Hide all tabs
    for _, existingTab in pairs(self.tabs) do
        if existingTab.content then
            existingTab.content.Visible = false
        end
        
        if existingTab.button then
            local isSettingsTab = (existingTab.name == "Settings")
            local textLabel = existingTab.button:FindFirstChild("TextLabel")
            local gearIcon = existingTab.button:FindFirstChildOfClass("TextLabel")
            
            if isSettingsTab then
                TweenService:Create(existingTab.button, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.Primary
                }):Play()
                if gearIcon then
                    TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                end
            else
                TweenService:Create(existingTab.button, ANIMATIONS.Fast, {
                    BackgroundColor3 = THEME.SurfaceLight
                }):Play()
                if textLabel then
                    TweenService:Create(textLabel, ANIMATIONS.Fast, {
                        TextColor3 = THEME.TextSecondary
                    }):Play()
                end
            end
        end
    end
    
    -- Show selected tab
    if tab.content then
        tab.content.Visible = true
    end
    
    if tab.button then
        local isSettingsTab = (tab.name == "Settings")
        local textLabel = tab.button:FindFirstChild("TextLabel")
        local gearIcon = tab.button:FindFirstChildOfClass("TextLabel")
        
        if isSettingsTab then
            local gearIcon = tab.button:FindFirstChildOfClass("TextLabel")
            if gearIcon then
                TweenService:Create(gearIcon, ANIMATIONS.Fast, {
                    TextColor3 = THEME.Accent -- Brighter blue when active
                }):Play()
            end
        else
            TweenService:Create(tab.button, ANIMATIONS.Fast, {
                BackgroundColor3 = THEME.Primary
            }):Play()
            if textLabel then
                TweenService:Create(textLabel, ANIMATIONS.Fast, {
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end
    
    self.currentTab = tab
end

function GuiLibrary:toggleVisibility()
    if self.isMinimized then
        self:show()
    else
        self:hide()
    end
end

function GuiLibrary:hide()
    if self.isMinimized then return end
    self.isMinimized = true
    
    TweenService:Create(self.mainFrame, ANIMATIONS.Medium, {
        Position = UDim2.new(0.5, -450, 1, 50)
    }):Play()
    
    TweenService:Create(self.backdrop, ANIMATIONS.Medium, {
        BackgroundTransparency = 1
    }):Play()
    
    
    task.spawn(function()
        task.wait(0.3)
        if self.backdrop then
            self.backdrop.Visible = false
        end
    end)
end

function GuiLibrary:show()
    if not self.isMinimized then return end
    self.isMinimized = false
    
    if self.backdrop then
        self.backdrop.Visible = true
    end
    
    TweenService:Create(self.mainFrame, ANIMATIONS.Medium, {
        Position = UDim2.new(0.5, -450, 0.5, -300)
    }):Play()
    
    TweenService:Create(self.backdrop, ANIMATIONS.Medium, {
        BackgroundTransparency = 0.7
    }):Play()
end

function GuiLibrary:setupKeybinds()
    -- Disconnect existing keybind
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    -- Setup new keybind
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode.Name == self.keybinds.toggle then
            self:toggleVisibility()
        end
    end))
end

function GuiLibrary:Notify(title, message, notificationType, duration)
    return self.notificationManager:notify(title, message, notificationType, duration)
end

function GuiLibrary:SaveConfig(configName)
    configName = configName or self.configManager.currentConfig
    self.configManager.currentConfig = configName
    return self.configManager:saveCurrentConfig()
end

function GuiLibrary:LoadConfig(configName)
    return self.configManager:loadConfig(configName)
end

function GuiLibrary:CreateConfig(configName)
    return self.configManager:createConfig(configName)
end

function GuiLibrary:DeleteConfig(configName)
    return self.configManager:deleteConfig(configName)
end

function GuiLibrary:ExportConfig(configName)
    return self.configManager:exportConfig(configName)
end

function GuiLibrary:ImportConfig(jsonString, configName)
    return self.configManager:importConfig(jsonString, configName)
end

function GuiLibrary:GetConfigList()
    return self.configManager:getConfigList()
end

function GuiLibrary:GetCurrentConfig()
    return self.configManager.currentConfig
end

function GuiLibrary:SetAutoSave(enabled)
    self.configManager.autoSaveEnabled = enabled
    if enabled then
        self.configManager:startAutoSave()
    else
        self.configManager:stopAutoSave()
    end
end

function GuiLibrary:SetAutoSaveInterval(seconds)
    self.configManager.autoSaveInterval = seconds
end

function GuiLibrary:destroy()
    -- Save current config before destroying
    if self.configManager.autoSaveEnabled then
        self.configManager:saveCurrentConfig()
    end
    
    -- Cleanup all connections
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    -- Cleanup managers
    if self.notificationManager and self.notificationManager.container then
        local notifGui = self.notificationManager.container.Parent
        if notifGui then
            notifGui:Destroy()
        end
    end

    if self.watermarkManager then
        self.watermarkManager:destroy()
    end
    
    if self.configManager then
        self.configManager:destroy()
    end
    
    -- Animate and destroy main GUI
    if self.mainFrame then
        TweenService:Create(self.mainFrame, ANIMATIONS.Medium, {
            Position = UDim2.new(0.5, -450, -1, -300),
            Rotation = 15,
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
    end
    
    if self.backdrop then
        TweenService:Create(self.backdrop, ANIMATIONS.Medium, {
            BackgroundTransparency = 1
        }):Play()
    end
    
    task.spawn(function()
        task.wait(0.3)
        if self.screenGui then
            self.screenGui:Destroy()
        end
    end)
end

-- Memory Management
local function cleanupMemory()
    -- Force garbage collection
    for i = 1, 3 do
        collectgarbage("collect")
        task.wait(0.1)
    end
end

-- Auto cleanup on player leaving
if Players.PlayerRemoving then
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            cleanupMemory()
        end
    end)
end

-- Export the library
return {
    new = function(title)
        return GuiLibrary.new(title)
    end,
    
    -- Utility functions for advanced users
    validateInput = validateInput,
    safeCreate = safeCreate,
    THEME = deepCopy(THEME),
    ANIMATIONS = deepCopy(ANIMATIONS),
    
    -- Config System Access
    ConfigManager = ConfigManager,
    
    -- Version info
    VERSION = "1.1.0",
    AUTHOR = "Lynix Development",
    DESCRIPTION = "Professional Roblox GUI Library with advanced security, modern design and complete config system",
    
    -- Config System Documentation
    CONFIG_FEATURES = {
        "Automatic saving and loading of all GUI elements",
        "Multiple config support with easy switching",
        "Import/Export functionality with JSON format",
        "Auto-save with customizable intervals",
        "Visual config management interface",
        "Backup and restore capabilities",
        "Cross-session persistence"
    }
}
