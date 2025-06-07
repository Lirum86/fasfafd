-- RadiantHub GUI Library v2.1 Premium
-- A modern, clean GUI library for Roblox

local Services = {
    Players = game:GetService('Players'),
    UserInputService = game:GetService('UserInputService'),
    TweenService = game:GetService('TweenService'),
    CoreGui = game:GetService('CoreGui'),
    RunService = game:GetService('RunService'),
    Stats = game:GetService('Stats'),
}

local Player = Services.Players.LocalPlayer

-- Default Configuration
local DefaultConfig = {
    Size = { 800, 600 },
    TabIconSize = 45,
    Logo = 'rbxassetid://72668739203416',
    Colors = {
        Background = Color3.fromRGB(23, 22, 22),
        Header = Color3.fromRGB(15, 15, 15),
        Active = Color3.fromRGB(24, 149, 235),
        Inactive = Color3.fromRGB(35, 35, 45),
        Hover = Color3.fromRGB(45, 45, 60),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 220),
        Success = Color3.fromRGB(50, 255, 50),
        Error = Color3.fromRGB(255, 100, 100),
        Warning = Color3.fromRGB(255, 193, 7),
    },
    MenuToggleKey = Enum.KeyCode.RightShift,
    WatermarkEnabled = true,
    NotificationsEnabled = true,
}

-- Utility Functions
local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function addCorner(parent, radius)
    create('UICorner', { 
        CornerRadius = UDim.new(0, radius or 8), 
        Parent = parent 
    })
end

local function addPadding(parent, all)
    create('UIPadding', {
        PaddingTop = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all),
        PaddingRight = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        Parent = parent,
    })
end

local function addStroke(parent, color, thickness)
    create('UIStroke', {
        Color = color or Color3.fromRGB(55, 55, 65),
        Thickness = thickness or 1,
        Transparency = 0.3,
        Parent = parent,
    })
end

local function tween(obj, time, props)
    return Services.TweenService:Create(obj, TweenInfo.new(time or 0.2), props)
end

-- Watermark Manager
local WatermarkManager = {}
WatermarkManager.__index = WatermarkManager

function WatermarkManager.new(config)
    local self = setmetatable({}, WatermarkManager)
    self.config = config
    self.isVisible = config.WatermarkEnabled
    self.container = nil
    self.updateConnection = nil
    self.lastUpdate = tick()
    
    if self.isVisible then
        self:createWatermark()
        self:startUpdating()
    end
    
    return self
end

function WatermarkManager:createWatermark()
    local watermarkGui = create('ScreenGui', {
        Name = 'RadiantHubWatermark_' .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = Services.CoreGui,
    })

    self.container = create('Frame', {
        Name = 'WatermarkContainer',
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(1, -360, 0, 20),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),
        BorderSizePixel = 0,
        Parent = watermarkGui,
    })
    addCorner(self.container, 10)
    addStroke(self.container, self.config.Colors.Active, 1)

    -- Brand text
    create('TextLabel', {
        Size = UDim2.new(0, 120, 0, 25),
        Position = UDim2.new(0, 15, 0, 8),
        BackgroundTransparency = 1,
        Text = 'RadiantHub',
        TextColor3 = self.config.Colors.Active,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = self.container,
    })

    create('TextLabel', {
        Size = UDim2.new(0, 120, 0, 18),
        Position = UDim2.new(0, 15, 0, 33),
        BackgroundTransparency = 1,
        Text = 'v2.1 Premium',
        TextColor3 = self.config.Colors.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = self.container,
    })

    -- Performance stats
    self.fpsLabel = create('TextLabel', {
        Size = UDim2.new(0, 70, 0, 22),
        Position = UDim2.new(1, -190, 0, 20),
        BackgroundTransparency = 1,
        Text = 'FPS: 60',
        TextColor3 = self.config.Colors.Success,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.container,
    })

    self.pingLabel = create('TextLabel', {
        Size = UDim2.new(0, 70, 0, 22),
        Position = UDim2.new(1, -115, 0, 20),
        BackgroundTransparency = 1,
        Text = 'Ping: 0ms',
        TextColor3 = self.config.Colors.Active,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self.container,
    })

    -- Performance bars
    self.fpsBar = create('Frame', {
        Size = UDim2.new(0, 65, 0, 4),
        Position = UDim2.new(1, -187, 0, 44),
        BackgroundColor3 = self.config.Colors.Success,
        BorderSizePixel = 0,
        Parent = self.container,
    })
    addCorner(self.fpsBar, 2)

    self.pingBar = create('Frame', {
        Size = UDim2.new(0, 65, 0, 4),
        Position = UDim2.new(1, -112, 0, 44),
        BackgroundColor3 = self.config.Colors.Active,
        BorderSizePixel = 0,
        Parent = self.container,
    })
    addCorner(self.pingBar, 2)

    -- Make draggable
    self.container.Active = true
    self.container.Draggable = true

    -- Entrance animation
    self.container.Position = UDim2.new(1, 20, 0, 20)
    tween(self.container, 0.5, {
        Position = UDim2.new(1, -360, 0, 20),
    }):Play()
end

function WatermarkManager:startUpdating()
    local lastTime = tick()
    local frameBuffer = {}
    local bufferSize = 20

    self.updateConnection = Services.RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime

        table.insert(frameBuffer, 1 / deltaTime)
        if #frameBuffer > bufferSize then
            table.remove(frameBuffer, 1)
        end

        local sum = 0
        for _, v in ipairs(frameBuffer) do
            sum = sum + v
        end
        local avgFPS = math.floor(sum / #frameBuffer)

        if currentTime - self.lastUpdate >= 0.5 then
            self:updateStats(avgFPS)
            self.lastUpdate = currentTime
        end
    end)
end

function WatermarkManager:updateStats(fps)
    if not self.fpsLabel or not self.pingLabel then return end

    -- Update FPS
    self.fpsLabel.Text = 'FPS: ' .. fps
    local fpsColor = fps < 30 and self.config.Colors.Error
        or fps < 50 and self.config.Colors.Warning
        or self.config.Colors.Success
    self.fpsLabel.TextColor3 = fpsColor

    if self.fpsBar then
        tween(self.fpsBar, 0.3, {
            Size = UDim2.new(0, math.clamp(fps / 120 * 65, 5, 65), 0, 4),
            BackgroundColor3 = fpsColor,
        }):Play()
    end

    -- Update Ping
    local ping = self:getPing()
    self.pingLabel.Text = 'Ping: ' .. ping .. 'ms'
    local pingColor = ping > 150 and self.config.Colors.Error
        or ping > 80 and self.config.Colors.Warning
        or self.config.Colors.Success
    self.pingLabel.TextColor3 = pingColor

    if self.pingBar then
        tween(self.pingBar, 0.3, {
            Size = UDim2.new(0, math.clamp((1 - ping / 300) * 65, 5, 65), 0, 4),
            BackgroundColor3 = pingColor,
        }):Play()
    end
end

function WatermarkManager:getPing()
    local ping = 0
    pcall(function()
        local net = Services.Stats.Network
        if net and net.ServerStatsItem['Data Ping'] then
            ping = math.floor(net.ServerStatsItem['Data Ping']:GetValue())
        end
    end)
    return ping
end

function WatermarkManager:setVisible(visible)
    if not self.container then return end
    self.isVisible = visible

    if visible then
        if not self.container.Parent then
            self:createWatermark()
            self:startUpdating()
        else
            self.container.Visible = true
            tween(self.container, 0.3, {
                Position = UDim2.new(1, -360, 0, 20),
            }):Play()
        end
    else
        if self.container then
            tween(self.container, 0.3, {
                Position = UDim2.new(1, 20, 0, 20),
            }):Play()
            task.delay(0.3, function()
                if self.container then
                    self.container.Visible = false
                end
            end)
        end
    end
end

function WatermarkManager:destroy()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    if self.container and self.container.Parent then
        self.container.Parent:Destroy()
    end
end

-- Notification Manager
local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(config)
    local self = setmetatable({}, NotificationManager)
    self.config = config
    self.notifications = {}
    self.container = nil
    
    if config.NotificationsEnabled then
        self:createContainer()
    end
    
    return self
end

function NotificationManager:createContainer()
    local notifGui = create('ScreenGui', {
        Name = 'RadiantHubNotifications_' .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = Services.CoreGui,
    })

    self.container = create('Frame', {
        Name = 'NotificationContainer',
        Size = UDim2.new(0, 350, 1, -80),
        Position = UDim2.new(1, -370, 0, 40),
        BackgroundTransparency = 1,
        Parent = notifGui,
    })

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 8),
        Parent = self.container,
    })
end

function NotificationManager:createNotification(title, message, duration, notifType)
    if not self.config.NotificationsEnabled or not self.container then
        return
    end

    duration = duration or 4
    notifType = notifType or 'info'

    local colors = {
        success = {
            bg = Color3.fromRGB(18, 25, 35),
            accent = self.config.Colors.Success,
            icon = self.config.Colors.Success,
        },
        error = {
            bg = Color3.fromRGB(25, 18, 18),
            accent = self.config.Colors.Error,
            icon = self.config.Colors.Error,
        },
        warning = {
            bg = Color3.fromRGB(25, 22, 18),
            accent = self.config.Colors.Warning,
            icon = self.config.Colors.Warning,
        },
        info = {
            bg = Color3.fromRGB(18, 25, 35),
            accent = self.config.Colors.Active,
            icon = self.config.Colors.Active,
        },
    }
    local scheme = colors[notifType] or colors.info

    local notifFrame = create('Frame', {
        Size = UDim2.new(0, 340, 0, 65),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        BorderSizePixel = 0,
        Parent = self.container,
    })
    addCorner(notifFrame, 12)
    addStroke(notifFrame, scheme.accent, 1)

    -- Progress bar
    local progressBg = create('Frame', {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 0,
        Parent = notifFrame,
    })
    addCorner(progressBg, 2)

    local progressFill = create('Frame', {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = scheme.accent,
        BorderSizePixel = 0,
        Parent = progressBg,
    })
    addCorner(progressFill, 2)

    -- Icon
    local icons = {
        success = '✓',
        error = '✕',
        warning = '⚠',
        info = 'ℹ',
    }
    local icon = create('TextLabel', {
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(0, 12, 0, 15),
        BackgroundColor3 = scheme.bg,
        Text = icons[notifType] or icons.info,
        TextColor3 = scheme.icon,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = notifFrame,
    })
    addCorner(icon, 17.5)
    addStroke(icon, scheme.accent, 1)

    -- Title
    create('TextLabel', {
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.new(0, 55, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(245, 245, 250),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notifFrame,
    })

    -- Message
    create('TextLabel', {
        Size = UDim2.new(1, -80, 0, 14),
        Position = UDim2.new(0, 55, 0, 35),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Color3.fromRGB(170, 170, 180),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notifFrame,
    })

    -- Close button
    local closeBtn = create('TextButton', {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0, 5),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Text = '×',
        TextColor3 = Color3.fromRGB(170, 170, 180),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = notifFrame,
    })
    addCorner(closeBtn, 10)
    addStroke(closeBtn, Color3.fromRGB(50, 50, 60), 1)

    -- Animations and events
    notifFrame.Position = UDim2.new(0, 400, 0, 100)
    tween(notifFrame, 0.5, { Position = UDim2.new(0, 0, 0, 0) }):Play()

    local progressTween = tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) })
    progressTween:Play()

    local function removeNotification()
        tween(notifFrame, 0.3, {
            Position = UDim2.new(0, 400, 0, 30),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.3, function()
            if notifFrame and notifFrame.Parent then
                notifFrame:Destroy()
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(removeNotification)
    progressTween.Completed:Connect(removeNotification)

    -- Hover effects
    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    end)

    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
        closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    end)

    return notifFrame
end

function NotificationManager:success(title, message, duration)
    return self:createNotification(title, message, duration, 'success')
end

function NotificationManager:error(title, message, duration)
    return self:createNotification(title, message, duration, 'error')
end

function NotificationManager:warning(title, message, duration)
    return self:createNotification(title, message, duration, 'warning')
end

function NotificationManager:info(title, message, duration)
    return self:createNotification(title, message, duration, 'info')
end

function NotificationManager:destroy()
    if self.container and self.container.Parent then
        self.container.Parent:Destroy()
    end
end

-- Main Library
local RadiantHubLibrary = {}
RadiantHubLibrary.__index = RadiantHubLibrary

function RadiantHubLibrary.new(config)
    local self = setmetatable({}, RadiantHubLibrary)
    
    -- Merge config with defaults
    self.config = {}
    for k, v in pairs(DefaultConfig) do
        if type(v) == "table" then
            self.config[k] = {}
            for k2, v2 in pairs(v) do
                self.config[k][k2] = (config and config[k] and config[k][k2]) or v2
            end
        else
            self.config[k] = (config and config[k]) or v
        end
    end
    
    -- Internal variables
    self.tabs = {}
    self.tabOrder = {}
    self.content = {}
    self.sections = {}
    self.currentTab = nil
    self.isVisible = true
    self.isDragging = false
    self.isSettingKeybind = false
    
    -- Initialize systems
    self:createMain()
    self:setupMenuToggle()
    self:initializeWatermark()
    self:initializeNotifications()
    
    -- Always add Settings tab at the bottom
    self:addTab("Settings", "rbxassetid://76381602959993")
    self:addTab("Credits", "🌟", true) -- Hidden credits tab
    
    return self
end

function RadiantHubLibrary:createMain()
    -- Cleanup existing
    local existing = Services.CoreGui:FindFirstChild('RadiantHub_' .. Player.Name)
    if existing then
        existing:Destroy()
    end

    -- Screen GUI
    self.screen = create('ScreenGui', {
        Name = 'RadiantHub_' .. Player.Name,
        ResetOnSpawn = false,
        Parent = Services.CoreGui,
    })

    -- Main Container
    self.main = create('Frame', {
        Size = UDim2.new(0, self.config.Size[1], 0, self.config.Size[2]),
        Position = UDim2.new(0.5, -self.config.Size[1] / 2, 0.5, -self.config.Size[2] / 2),
        BackgroundTransparency = 1,
        Parent = self.screen,
    })

    -- Tab Container
    self.tabContainer = create('Frame', {
        Size = UDim2.new(0, 85, 1, -10),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = self.config.Colors.Background,
        Parent = self.main,
    })
    addCorner(self.tabContainer, 12)
    addPadding(self.tabContainer, 15)

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = self.tabContainer,
    })

    -- Logo
    self:createLogo()

    -- Header
    self.header = create('Frame', {
        Size = UDim2.new(1, -105, 0, 70),
        Position = UDim2.new(0, 105, 0, 10),
        BackgroundColor3 = self.config.Colors.Header,
        Parent = self.main,
    })
    addCorner(self.header, 12)

    -- Title
    self.title = create('TextLabel', {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 25, 0, 0),
        BackgroundTransparency = 1,
        Text = "RadiantHub",
        TextColor3 = self.config.Colors.Text,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.header,
    })

    -- Avatar
    local avatar = create('Frame', {
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(1, -110, 0.5, -22.5),
        BackgroundColor3 = self.config.Colors.Hover,
        Parent = self.header,
    })
    addCorner(avatar, 22.5)
    addStroke(avatar, self.config.Colors.Active, 2)

    local avatarImg = create('ImageLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = 'https://www.roblox.com/headshot-thumbnail/image?userId=' .. Player.UserId .. '&width=150&height=150&format=png',
        Parent = avatar,
    })
    addCorner(avatarImg, 22.5)

    -- Close Button
    self.closeBtn = create('TextButton', {
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(1, -60, 0.5, -22.5),
        BackgroundTransparency = 1,
        Text = '×',
        TextColor3 = self.config.Colors.Text,
        TextSize = 32,
        Font = Enum.Font.GothamBold,
        Parent = self.header,
    })

    -- Content Frame
    self.contentFrame = create('Frame', {
        Size = UDim2.new(1, -105, 1, -90),
        Position = UDim2.new(0, 105, 0, 90),
        BackgroundColor3 = self.config.Colors.Background,
        Parent = self.main,
    })
    addCorner(self.contentFrame, 12)
    addPadding(self.contentFrame, 20)

    self:setupEvents()
end

function RadiantHubLibrary:createLogo()
    local logoContainer = create('Frame', {
        Size = UDim2.new(0, 65, 0, 65),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = self.tabContainer,
    })

    -- Glow effect
    local glow = create('Frame', {
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0, -4, 0, -4),
        BackgroundColor3 = self.config.Colors.Active,
        BackgroundTransparency = 0.85,
        ZIndex = 1,
        Parent = logoContainer,
    })
    addCorner(glow, 35)

    -- Logo frame
    local logoFrame = create('Frame', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.config.Colors.Inactive,
        ZIndex = 2,
        Parent = logoContainer,
    })
    addCorner(logoFrame, 32)
    addStroke(logoFrame, self.config.Colors.Active, 2)

    -- Logo image
    local logoImg = create('ImageLabel', {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        Image = self.config.Logo,
        ZIndex = 3,
        Parent = logoFrame,
    })
    addCorner(logoImg, 28)

    -- Logo button
    local logoBtn = create('TextButton', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = '',
        ZIndex = 4,
        Parent = logoFrame,
    })

    logoBtn.MouseEnter:Connect(function()
        logoFrame.BackgroundColor3 = self.config.Colors.Hover
        logoImg.ImageColor3 = self.config.Colors.Active
    end)

    logoBtn.MouseLeave:Connect(function()
        logoFrame.BackgroundColor3 = self.config.Colors.Inactive
        logoImg.ImageColor3 = self.config.Colors.Text
    end)

    logoBtn.MouseButton1Click:Connect(function()
        self:switchTab('Credits')
    end)
end

function RadiantHubLibrary:addTab(name, icon, hidden)
    if self.tabs[name] then
        return self.tabs[name]
    end

    -- Determine layout order
    local layoutOrder
    if name == "Settings" then
        layoutOrder = 9998 -- Always second to last
    elseif name == "Credits" then
        layoutOrder = 9999 -- Always last
    else
        layoutOrder = #self.tabOrder + 1
    end

    -- Create tab button (only if not hidden)
    local tabBtn
    if not hidden then
        tabBtn = create('ImageButton', {
            Size = UDim2.new(0, 65, 0, 65),
            BackgroundColor3 = self.config.Colors.Inactive,
            Image = '',
            LayoutOrder = layoutOrder,
            Parent = self.tabContainer,
        })
        addCorner(tabBtn, 12)
        addPadding(tabBtn, 11)

        -- Icon
        local iconLabel = create('ImageLabel', {
            Size = UDim2.new(0, self.config.TabIconSize, 0, self.config.TabIconSize),
            Position = UDim2.new(0.5, -self.config.TabIconSize / 2, 0.5, -self.config.TabIconSize / 2),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = self.config.Colors.SubText,
            ScaleType = Enum.ScaleType.Fit,
            Parent = tabBtn,
        })

        -- If icon is text (like emoji), use TextLabel instead
        if icon:sub(1, 10) ~= "rbxassetid" then
            iconLabel:Destroy()
            iconLabel = create('TextLabel', {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = icon,
                TextColor3 = self.config.Colors.SubText,
                TextSize = 24,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = tabBtn,
            })
        end

        -- Tab events
        local function updateHover(isHover)
            if self.currentTab ~= name then
                tabBtn.BackgroundColor3 = isHover and self.config.Colors.Hover or self.config.Colors.Inactive
            end
            if iconLabel.ClassName == "ImageLabel" then
                iconLabel.ImageColor3 = (isHover or self.currentTab == name) and self.config.Colors.Text or self.config.Colors.SubText
            else
                iconLabel.TextColor3 = (isHover or self.currentTab == name) and self.config.Colors.Text or self.config.Colors.SubText
            end
        end

        tabBtn.MouseEnter:Connect(function() updateHover(true) end)
        tabBtn.MouseLeave:Connect(function() updateHover(false) end)
        tabBtn.MouseButton1Click:Connect(function() self:switchTab(name) end)
    end

    -- Create content frame
    local content = create('Frame', {
        Name = name .. 'Content',
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.contentFrame,
    })

    -- Store tab data
    self.tabs[name] = {
        button = tabBtn,
        content = content,
        sections = {},
        hidden = hidden or false,
        layoutOrder = layoutOrder
    }
    
    if not hidden then
        table.insert(self.tabOrder, name)
    end

    -- Auto-create content based on tab name
    if name == "Settings" then
        self:createSettingsContent(content)
    elseif name == "Credits" then
        self:createCreditsContent(content)
    else
        self:createDefaultTabContent(content, name)
    end

    -- Auto-switch to first non-hidden tab
    if not self.currentTab and not hidden then
        self:switchTab(name)
    end

    return self.tabs[name]
end

function RadiantHubLibrary:createSettingsContent(parent)
    -- Column titles
    create('TextLabel', {
        Size = UDim2.new(0, 250, 0, 30),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = 'Menu Settings',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(0, 250, 0, 30),
        Position = UDim2.new(0.515, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = 'Display Settings',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })

    -- Create columns
    local leftColumn = create('ScrollingFrame', {
        Size = UDim2.new(0.485, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.config.Colors.Active,
        CanvasSize = UDim2.new(0, 0, 2, 0),
        Parent = parent,
    })
    addCorner(leftColumn, 8)
    addPadding(leftColumn, 15)

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 15),
        Parent = leftColumn,
    })

    local rightColumn = create('ScrollingFrame', {
        Size = UDim2.new(0.485, 0, 1, -40),
        Position = UDim2.new(0.515, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.config.Colors.Active,
        CanvasSize = UDim2.new(0, 0, 2, 0),
        Parent = parent,
    })
    addCorner(rightColumn, 8)
    addPadding(rightColumn, 15)

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 15),
        Parent = rightColumn,
    })

    -- Menu Settings Section
    local menuSection = self:createSection(leftColumn, 'Menu Controls', UDim2.new(1, 0, 0, 160))
    
    self.menuKeybind = self:createKeybind(menuSection, 'Menu Toggle Key', self.config.MenuToggleKey.Name, UDim2.new(0, 0, 0, 40))
    
    -- Display Settings Section
    local displaySection = self:createSection(rightColumn, 'Performance Display', UDim2.new(1, 0, 0, 160))
    
    self.watermarkToggle = self:createToggle(displaySection, 'Show Watermark', 'Display performance overlay', self.config.WatermarkEnabled, UDim2.new(0, 0, 0, 40))
    self.notificationToggle = self:createToggle(displaySection, 'Enable Notifications', 'Show system notifications', self.config.NotificationsEnabled, UDim2.new(0, 0, 0, 90))

    -- Additional sections
    self:createSection(leftColumn, 'Advanced Options', UDim2.new(1, 0, 0, 120))
    self:createSection(rightColumn, 'Theme Settings', UDim2.new(1, 0, 0, 120))
end

function RadiantHubLibrary:createCreditsContent(parent)
    -- Main title with gradient effect
    local titleFrame = create('Frame', {
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = '🎉 RadiantHub Premium',
        TextColor3 = self.config.Colors.Active,
        TextSize = 28,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = titleFrame,
    })

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = 'Advanced GUI Library v2.1',
        TextColor3 = self.config.Colors.SubText,
        TextSize = 16,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = titleFrame,
    })

    -- Developer info section
    local devSection = create('Frame', {
        Size = UDim2.new(0.9, 0, 0, 120),
        Position = UDim2.new(0.05, 0, 0, 120),
        BackgroundColor3 = Color3.fromRGB(20, 25, 30),
        Parent = parent,
    })
    addCorner(devSection, 12)
    addStroke(devSection, self.config.Colors.Active, 2)
    addPadding(devSection, 20)

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = '👨‍💻 Developer Information',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = devSection,
    })

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        TextWrapped = true,
        Text = 'Created by: Anonymous Developer\nVersion: 2.1.0 Premium Edition\nBuilt with: Modern Roblox Lua\nSpecial thanks to the Roblox community!',
        TextColor3 = self.config.Colors.SubText,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = devSection,
    })

    -- Features section
    local featuresSection = create('Frame', {
        Size = UDim2.new(0.9, 0, 0, 180),
        Position = UDim2.new(0.05, 0, 0, 260),
        BackgroundColor3 = Color3.fromRGB(20, 25, 30),
        Parent = parent,
    })
    addCorner(featuresSection, 12)
    addStroke(featuresSection, self.config.Colors.Success, 2)
    addPadding(featuresSection, 20)

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = '✨ Premium Features',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = featuresSection,
    })

    local featuresList = {
        '🎨 Modern Dark Theme with Smooth Animations',
        '📱 Responsive Drag & Drop Interface',
        '🔧 Advanced Component System',
        '📊 Real-time Performance Monitoring',
        '🔔 Smart Notification System',
        '⚙️ Customizable Settings Panel',
        '🎯 Easy-to-use API for Developers',
        '🔒 Secure and Optimized Code'
    }

    local featureText = table.concat(featuresList, '\n')
    create('TextLabel', {
        Size = UDim2.new(1, 0, 1, -30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = featureText,
        TextColor3 = self.config.Colors.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = featuresSection,
    })
end

function RadiantHubLibrary:createDefaultTabContent(parent, tabName)
    -- Column titles
    create('TextLabel', {
        Size = UDim2.new(0, 250, 0, 30),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = tabName .. ' - Configuration',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(0, 250, 0, 30),
        Position = UDim2.new(0.515, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = tabName .. ' - Advanced',
        TextColor3 = self.config.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })

    -- Create columns
    local leftColumn = create('ScrollingFrame', {
        Size = UDim2.new(0.485, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.config.Colors.Active,
        CanvasSize = UDim2.new(0, 0, 2, 0),
        Parent = parent,
    })
    addCorner(leftColumn, 8)
    addPadding(leftColumn, 15)

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 15),
        Parent = leftColumn,
    })

    local rightColumn = create('ScrollingFrame', {
        Size = UDim2.new(0.485, 0, 1, -40),
        Position = UDim2.new(0.515, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.config.Colors.Active,
        CanvasSize = UDim2.new(0, 0, 2, 0),
        Parent = parent,
    })
    addCorner(rightColumn, 8)
    addPadding(rightColumn, 15)

    create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 15),
        Parent = rightColumn,
    })

    -- Store column references
    self.tabs[tabName].leftColumn = leftColumn
    self.tabs[tabName].rightColumn = rightColumn

    -- Example sections (can be customized)
    self:createSection(leftColumn, tabName .. ' Settings', UDim2.new(1, 0, 0, 180))
    self:createSection(rightColumn, tabName .. ' Advanced', UDim2.new(1, 0, 0, 180))
end

function RadiantHubLibrary:createSection(parent, title, size)
    local section = create('Frame', {
        Size = size or UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = Color3.fromRGB(28, 28, 30),
        Parent = parent,
    })
    addCorner(section, 8)
    addPadding(section, 15)
    addStroke(section)

    create('TextLabel', {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section,
    })

    return section
end

function RadiantHubLibrary:createToggle(parent, title, desc, state, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 32),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    -- Labels
    create('TextLabel', {
        Size = UDim2.new(1, -55, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    create('TextLabel', {
        Size = UDim2.new(1, -55, 0, 12),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = self.config.Colors.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    -- Switch
    local switch = create('Frame', {
        Size = UDim2.new(0, 45, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = state and self.config.Colors.Active or Color3.fromRGB(50, 50, 55),
        Parent = frame,
    })
    addCorner(switch, 10)

    local knob = create('Frame', {
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = self.config.Colors.Text,
        Parent = switch,
    })
    addCorner(knob, 8)

    -- Button
    local btn = create('TextButton', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = '',
        Parent = frame,
    })

    local isToggled = state
    local callbacks = {}

    btn.MouseButton1Click:Connect(function()
        isToggled = not isToggled

        tween(switch, 0.2, {
            BackgroundColor3 = isToggled and self.config.Colors.Active or Color3.fromRGB(50, 50, 55),
        }):Play()

        tween(knob, 0.2, {
            Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        }):Play()

        -- Handle special toggles
        if self.watermarkToggle and frame == self.watermarkToggle then
            self.config.WatermarkEnabled = isToggled
            if self.watermark then
                self.watermark:setVisible(isToggled)
            end
            local status = isToggled and 'Enabled' or 'Disabled'
            self.notifications:info('Watermark ' .. status, 'Performance overlay ' .. status:lower() .. '.', 3)
        elseif self.notificationToggle and frame == self.notificationToggle then
            self.config.NotificationsEnabled = isToggled
            local status = isToggled and 'Enabled' or 'Disabled'
            if isToggled then
                self.notifications:success('Notifications ' .. status, 'System notifications ' .. status:lower() .. '.', 3)
            end
        else
            local status = isToggled and 'Enabled' or 'Disabled'
            self.notifications:success(title .. ' ' .. status, desc, 3)
        end

        -- Execute callbacks
        for _, callback in ipairs(callbacks) do
            pcall(callback, isToggled)
        end
    end)

    -- Return toggle object with methods
    return {
        frame = frame,
        getValue = function() return isToggled end,
        setValue = function(value)
            if value ~= isToggled then
                btn.MouseButton1Click:Fire()
            end
        end,
        onChanged = function(callback)
            table.insert(callbacks, callback)
        end
    }
end

function RadiantHubLibrary:createSlider(parent, title, desc, min, max, default, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 50),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    -- Title
    create('TextLabel', {
        Size = UDim2.new(1, -75, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    -- Description
    create('TextLabel', {
        Size = UDim2.new(1, -75, 0, 12),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = self.config.Colors.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    -- Value display
    local valueBox = create('TextBox', {
        Size = UDim2.new(0, 70, 0, 20),
        Position = UDim2.new(1, -75, 0, 2),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Text = tostring(default),
        TextColor3 = self.config.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        Parent = frame,
    })
    addCorner(valueBox, 6)
    addStroke(valueBox)

    -- Slider track
    local sliderTrack = create('Frame', {
        Size = UDim2.new(1, -85, 0, 6),
        Position = UDim2.new(0, 0, 0, 37),
        BackgroundColor3 = Color3.fromRGB(45, 45, 55),
        BorderSizePixel = 0,
        Parent = frame,
    })
    addCorner(sliderTrack, 3)

    -- Slider fill
    local sliderFill = create('Frame', {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.Colors.Active,
        BorderSizePixel = 0,
        Parent = sliderTrack,
    })
    addCorner(sliderFill, 3)

    -- Invisible button for interaction
    local sliderButton = create('TextButton', {
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundTransparency = 1,
        Text = '',
        Parent = sliderTrack,
    })

    local currentValue = default
    local isDragging = false
    local callbacks = {}

    local function updateSliderFromValue(value, showNotification)
        value = math.max(min, math.min(max, value))
        currentValue = value
        local normalizedPos = (currentValue - min) / (max - min)

        sliderFill.Size = UDim2.new(normalizedPos, 0, 1, 0)
        valueBox.Text = tostring(currentValue)

        if showNotification then
            self.notifications:info('Slider Updated', title .. ' set to: ' .. currentValue, 2)
        end

        -- Execute callbacks
        for _, callback in ipairs(callbacks) do
            pcall(callback, currentValue)
        end
    end

    local function updateSlider(mouseX)
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackSize = sliderTrack.AbsoluteSize.X
        local relativeX = math.max(0, math.min(1, (mouseX - trackPos) / trackSize))
        local newValue = math.floor(min + (max - min) * relativeX)
        updateSliderFromValue(newValue, false)
    end

    -- TextBox events
    valueBox.FocusLost:Connect(function()
        local inputValue = tonumber(valueBox.Text)
        if inputValue then
            updateSliderFromValue(inputValue, true)
        else
            valueBox.Text = tostring(currentValue)
        end
    end)

    -- Slider events
    sliderButton.MouseButton1Down:Connect(function()
        isDragging = true
        local mousePos = Services.UserInputService:GetMouseLocation()
        updateSlider(mousePos.X)

        local connection = Services.UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                local newMousePos = Services.UserInputService:GetMouseLocation()
                updateSlider(newMousePos.X)
            end
        end)

        local endConnection = Services.UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
                self.notifications:info('Slider Updated', title .. ' set to: ' .. currentValue, 2)
                connection:Disconnect()
                endConnection:Disconnect()
            end
        end)
    end)

    return {
        frame = frame,
        getValue = function() return currentValue end,
        setValue = function(value) updateSliderFromValue(value, true) end,
        onChanged = function(callback) table.insert(callbacks, callback) end
    }
end

function RadiantHubLibrary:createKeybind(parent, title, key, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 32),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(1, -75, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local keyBtn = create('TextButton', {
        Size = UDim2.new(0, 70, 0, 24),
        Position = UDim2.new(1, -75, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Text = key,
        TextColor3 = self.config.Colors.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = frame,
    })
    addCorner(keyBtn, 8)
    addStroke(keyBtn)

    local listening = false
    local currentKey = key
    local callbacks = {}

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        self.isSettingKeybind = true

        keyBtn.Text = '...'
        keyBtn.BackgroundColor3 = self.config.Colors.Active

        local connection = Services.UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local newKey = input.KeyCode.Name
                keyBtn.Text = newKey
                keyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                listening = false
                currentKey = newKey

                -- Update menu toggle key if this is the menu keybind
                if self.menuKeybind and frame == self.menuKeybind then
                    self.config.MenuToggleKey = input.KeyCode
                    self.notifications:success('Keybind Updated', 'Menu toggle key set to: ' .. newKey, 3)
                else
                    self.notifications:info('Keybind Set', title .. ' bound to: ' .. newKey, 3)
                end

                -- Execute callbacks
                for _, callback in ipairs(callbacks) do
                    pcall(callback, input.KeyCode, newKey)
                end

                task.wait(0.1)
                self.isSettingKeybind = false
                connection:Disconnect()
            end
        end)
    end)

    return {
        frame = frame,
        getValue = function() return currentKey end,
        setValue = function(key) 
            currentKey = key
            keyBtn.Text = key
        end,
        onChanged = function(callback) table.insert(callbacks, callback) end
    }
end

function RadiantHubLibrary:createDropdown(parent, title, options, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 32),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(1, -115, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local dropdown = create('Frame', {
        Size = UDim2.new(0, 110, 0, 26),
        Position = UDim2.new(1, -115, 0.5, -13),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        Parent = frame,
    })
    addCorner(dropdown, 8)
    addStroke(dropdown)

    local selected = create('TextLabel', {
        Size = UDim2.new(1, -35, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = options[1] or "Select...",
        TextColor3 = self.config.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdown,
    })

    local arrow = create('TextLabel', {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundTransparency = 1,
        Text = '▼',
        TextColor3 = self.config.Colors.SubText,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = dropdown,
    })

    -- Options frame
    local optionsFrame = create('Frame', {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        Visible = false,
        ZIndex = 10,
        Parent = dropdown,
    })
    addCorner(optionsFrame, 8)
    addStroke(optionsFrame)

    local isOpen = false
    local currentSelection = options[1] or ""
    local callbacks = {}

    local function updateOptions()
        -- Clear existing options
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA('TextButton') then
                child:Destroy()
            end
        end

        -- Create options
        for i, option in ipairs(options) do
            local optBtn = create('TextButton', {
                Size = UDim2.new(1, -8, 0, 26),
                Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 28),
                BackgroundTransparency = (option == currentSelection) and 0 or 1,
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Text = '',
                ZIndex = 11,
                Parent = optionsFrame,
            })
            addCorner(optBtn, 6)

            local indicator = create('Frame', {
                Size = UDim2.new(0, 3, 0.6, 0),
                Position = UDim2.new(0, 3, 0.2, 0),
                BackgroundColor3 = (option == currentSelection) and self.config.Colors.Active or Color3.fromRGB(60, 60, 70),
                ZIndex = 12,
                Parent = optBtn,
            })
            addCorner(indicator, 2)

            local text = create('TextLabel', {
                Size = UDim2.new(1, -18, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = option,
                TextColor3 = (option == currentSelection) and self.config.Colors.Active or self.config.Colors.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12,
                Parent = optBtn,
            })

            optBtn.MouseButton1Click:Connect(function()
                currentSelection = option
                selected.Text = option
                isOpen = false
                optionsFrame.Visible = false
                arrow.Text = '▼'
                updateOptions()
                self.notifications:info('Selection Changed', title .. ': ' .. option, 2)
                
                -- Execute callbacks
                for _, callback in ipairs(callbacks) do
                    pcall(callback, option)
                end
            end)
        end

        optionsFrame.Size = UDim2.new(1, 0, 0, #options * 28 + 8)
    end

    updateOptions()

    local arrowBtn = create('TextButton', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = '',
        Parent = dropdown,
    })

    arrowBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsFrame.Visible = isOpen
        arrow.Text = isOpen and '▲' or '▼'
    end)

    return {
        frame = frame,
        getValue = function() return currentSelection end,
        setValue = function(value)
            if table.find(options, value) then
                currentSelection = value
                selected.Text = value
                updateOptions()
            end
        end,
        setOptions = function(newOptions)
            options = newOptions
            if not table.find(options, currentSelection) and #options > 0 then
                currentSelection = options[1]
                selected.Text = currentSelection
            end
            updateOptions()
        end,
        onChanged = function(callback) table.insert(callbacks, callback) end
    }
end

function RadiantHubLibrary:createButton(parent, title, desc, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 32),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(1, -85, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    if desc then
        create('TextLabel', {
            Size = UDim2.new(1, -85, 0, 12),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = self.config.Colors.SubText,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
    end

    local button = create('TextButton', {
        Size = UDim2.new(0, 80, 0, 26),
        Position = UDim2.new(1, -85, 0.5, -13),
        BackgroundColor3 = self.config.Colors.Active,
        Text = 'Execute',
        TextColor3 = self.config.Colors.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = frame,
    })
    addCorner(button, 8)

    local callbacks = {}

    button.MouseButton1Click:Connect(function()
        -- Visual feedback
        button.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
        tween(button, 0.1, { BackgroundColor3 = self.config.Colors.Active }):Play()
        
        self.notifications:success('Action Executed', title .. ' completed successfully!', 3)
        
        -- Execute callbacks
        for _, callback in ipairs(callbacks) do
            pcall(callback)
        end
    end)

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(30, 160, 255)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = self.config.Colors.Active
    end)

    return {
        frame = frame,
        onClick = function(callback) table.insert(callbacks, callback) end,
        setText = function(text) button.Text = text end
    }
end

function RadiantHubLibrary:createColorPicker(parent, title, defaultColor, pos)
    local frame = create('Frame', {
        Size = UDim2.new(1, -5, 0, 32),
        Position = pos or UDim2.new(0, 25, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    create('TextLabel', {
        Size = UDim2.new(1, -75, 0, 16),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.config.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local colorButton = create('Frame', {
        Size = UDim2.new(0, 60, 0, 26),
        Position = UDim2.new(1, -65, 0.5, -13),
        BackgroundColor3 = defaultColor or Color3.fromRGB(255, 255, 255),
        Parent = frame,
    })
    addCorner(colorButton, 8)
    addStroke(colorButton)

    local colorBtn = create('TextButton', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = '',
        Parent = colorButton,
    })

    local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
    local callbacks = {}

    colorBtn.MouseButton1Click:Connect(function()
        -- Simple color cycle for demo (in real implementation, you'd open a color picker)
        local colors = {
            Color3.fromRGB(255, 0, 0),    -- Red
            Color3.fromRGB(0, 255, 0),    -- Green  
            Color3.fromRGB(0, 0, 255),    -- Blue
            Color3.fromRGB(255, 255, 0),  -- Yellow
            Color3.fromRGB(255, 0, 255),  -- Magenta
            Color3.fromRGB(0, 255, 255),  -- Cyan
            Color3.fromRGB(255, 255, 255) -- White
        }
        
        local currentIndex = 1
        for i, color in ipairs(colors) do
            if color == currentColor then
                currentIndex = i
                break
            end
        end
        
        currentIndex = (currentIndex % #colors) + 1
        currentColor = colors[currentIndex]
        colorButton.BackgroundColor3 = currentColor
        
        self.notifications:info('Color Changed', title .. ' color updated!', 2)
        
        -- Execute callbacks
        for _, callback in ipairs(callbacks) do
            pcall(callback, currentColor)
        end
    end)

    return {
        frame = frame,
        getValue = function() return currentColor end,
        setValue = function(color) 
            currentColor = color
            colorButton.BackgroundColor3 = color
        end,
        onChanged = function(callback) table.insert(callbacks, callback) end
    }
end

function RadiantHubLibrary:switchTab(tabName)
    if not self.tabs[tabName] or self.currentTab == tabName then
        return
    end

    -- Deactivate all tabs
    for name, tab in pairs(self.tabs) do
        if tab.button then
            tab.button.BackgroundColor3 = self.config.Colors.Inactive
            local indicator = tab.button:FindFirstChild('ActiveIndicator')
            if indicator then
                indicator:Destroy()
            end
        end
        tab.content.Visible = false
    end

    -- Activate new tab
    if self.tabs[tabName].button then
        self:setActiveTab(self.tabs[tabName].button)
    end
    self.tabs[tabName].content.Visible = true

    self.currentTab = tabName
    self.title.Text = tabName
end

function RadiantHubLibrary:setActiveTab(btn)
    local indicator = create('Frame', {
        Name = 'ActiveIndicator',
        Size = UDim2.new(0, 4, 0.7, 0),
        Position = UDim2.new(0, -15, 0.15, 0),
        BackgroundColor3 = self.config.Colors.Active,
        Parent = btn,
    })
    addCorner(indicator, 2)
    btn.BackgroundColor3 = self.config.Colors.Active
end

function RadiantHubLibrary:setupMenuToggle()
    Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or self.isSettingKeybind then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.config.MenuToggleKey then
            self:toggleVisibility()
        end
    end)
end

function RadiantHubLibrary:toggleVisibility()
    self.isVisible = not self.isVisible

    if self.isVisible then
        self.main.Visible = true
        self.main.Position = UDim2.new(0.5, -self.config.Size[1] / 2, 0.5, -self.config.Size[2] / 2 - 50)
        self.main.Size = UDim2.new(0, self.config.Size[1] * 0.8, 0, self.config.Size[2] * 0.8)

        tween(self.main, 0.3, {
            Position = UDim2.new(0.5, -self.config.Size[1] / 2, 0.5, -self.config.Size[2] / 2),
            Size = UDim2.new(0, self.config.Size[1], 0, self.config.Size[2]),
        }):Play()
    else
        local fadeOut = tween(self.main, 0.2, {
            Position = UDim2.new(0.5, -self.config.Size[1] / 2, 0.5, -self.config.Size[2] / 2 - 30),
            Size = UDim2.new(0, self.config.Size[1] * 0.9, 0, self.config.Size[2] * 0.9),
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            self.main.Visible = false
        end)
    end
end

function RadiantHubLibrary:setupEvents()
    local dragStart, startPos

    self.header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.isDragging = true
            dragStart = input.Position
            startPos = self.main.Position
        end
    end)

    self.header.InputChanged:Connect(function(input)
        if self.isDragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            self.main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.isDragging = false
        end
    end)

    -- Close button
    self.closeBtn.MouseEnter:Connect(function()
        self.closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
        tween(self.closeBtn, 0.1, { TextSize = 34 }):Play()
    end)

    self.closeBtn.MouseLeave:Connect(function()
        self.closeBtn.TextColor3 = self.config.Colors.Text
        tween(self.closeBtn, 0.1, { TextSize = 32 }):Play()
    end)

    self.closeBtn.MouseButton1Click:Connect(function()
        self:destroy()
    end)
end

function RadiantHubLibrary:initializeWatermark()
    self.watermark = WatermarkManager.new(self.config)
end

function RadiantHubLibrary:initializeNotifications()
    self.notifications = NotificationManager.new(self.config)
    
    -- Welcome notification
    task.delay(0.5, function()
        self.notifications:success('RadiantHub Loaded', 'Welcome! All systems initialized successfully.', 5)
    end)
end

function RadiantHubLibrary:destroy()
    if self.watermark then
        self.watermark:destroy()
    end
    if self.notifications then
        self.notifications:destroy()
    end
    if self.screen then
        self.screen:Destroy()
    end
end

-- Window creation method
function RadiantHubLibrary:createWindow(title)
    if title then
        self.title.Text = title
    end
    return self
end

-- Section creation for tabs
function RadiantHubLibrary:getTab(tabName)
    return self.tabs[tabName]
end

-- Export the library
return RadiantHubLibrary
