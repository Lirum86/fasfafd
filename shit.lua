function LPH_NO_VIRTUALIZE(f) return f end;
--[[
    Lynix GUI Library - Complete Script with Advanced ESP System
    
    Features:
    - Combat (Aimbot, Silent Aim, Gun Mods)
    - Advanced ESP System (All configurable options)
    - Movement (Speed, Jump, Flight, Noclip)
    - Miscellaneous (Game Exploits, Utilities)
]]

-- Load Library
local GuiLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lirum86/fasfafd/refs/heads/main/fuckiod.lua"))()

if not GuiLibrary then
    error("Failed to load Lynix GUI Library!")
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Variables
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Characters = Workspace:WaitForChild("characters")

-- Aimbot Settings (getgenv for global access)
getgenv().aimbotSettings = {
    fov_size = 200,
    aimbot_enabled = false,
    aim_part = "head",
    smoothness = 15,
    team_check = false,
    prediction = 0.12,
    show_fov = true,
    visibility_check = true
}

-- Silent Aim Settings
getgenv().silentAimSettings = {
    silent_aim = false,
    show_fov = true,
    fov_size = 150,
    hit_chance = 100,
    target_part = "Head",
    team_check = false,
    target_line = false,
    bullet_tracer = false,
    bullet_tracer_color = Color3.fromRGB(255, 0, 0),
}

-- Gun Mods Settings
getgenv().gunModSettings = {
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
    instant_bullet = false,
}
getgenv().charSettings = {
    TPerson = false,
    SpeedHack = false,
}
-- ESP System Settings
getgenv().espSettings = {
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
}
local Lighting = game:GetService("Lighting")
local oldGradient1 = Instance.new("Color3Value")
oldGradient1.Name = "OldAmbient"
oldGradient1.Value = Lighting.Ambient
oldGradient1.Parent = Lighting
local oldGradient2 = Instance.new("Color3Value")
oldGradient2.Name = "OldOutdoorAmbient"
oldGradient2.Value = Lighting.OutdoorAmbient
oldGradient2.Parent = Lighting
getgenv().worldVisuals = {
    ambient = false,
    gradient = false,
    gradientcolor1 = Color3.fromRGB(90, 90, 90),
    oldgradient1 = Lighting.Ambient,
    oldgradient2 = Lighting.OutdoorAmbient,
}
getgenv().bulletTracerSettings = {
    enabled = false,
    tracer_color = Color3.fromRGB(0, 255, 255),
    duration = 2,
    thickness = 0.35,
    max_distance = 1000,
    show_impact = true,
    impact_duration = 5,
    silent_aim_priority = true -- When true: Silent Aim Target has priority
}

local Settings = {
    speedHack = false,
    walkSpeed = 16,
    jumpPower = 50,
    fly = false,
    flySpeed = 25,
    noclip = false,
    godMode = false,
    autoReload = false,
    wallhack = false
}
local fov = Drawing.new("Circle")
fov.Radius = getgenv().aimbotSettings.fov_size
fov.Thickness = 1
fov.Transparency = 1
fov.Filled = false
fov.Color = Color3.fromRGB(255, 255, 255)
fov.Visible = getgenv().aimbotSettings.show_fov
local silentFov = Drawing.new("Circle")
silentFov.Radius = getgenv().silentAimSettings.fov_size
silentFov.Thickness = 1
silentFov.Transparency = 1
silentFov.Filled = false
silentFov.Color = Color3.fromRGB(255, 0, 0)
silentFov.Visible = getgenv().silentAimSettings.show_fov
local targetLine = Drawing.new("Line")
targetLine.Thickness = 2
targetLine.Color = Color3.fromRGB(255, 0, 0)
targetLine.Transparency = 1
targetLine.Visible = false
local currentTarget = nil
local silentTarget = nil
local tracerCounter = 0
local impactCounter = 0
local ESPSystem = {}
ESPSystem.__index = ESPSystem
RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
    if worldVisuals.gradient then
        local Lighting = game.Lighting
        for i,v in pairs(Lighting:GetChildren()) do 
            if v:IsA("ColorCorrectionEffect") and v.Name:find("Scare") then
                v.TintColor = worldVisuals.gradientcolor1
            end
        end
    end
end))
function ESPSystem.new()
    local self = setmetatable({}, ESPSystem)
    self.camera = Workspace.CurrentCamera
    self.localPlayer = Players.LocalPlayer
    self.espObjects = {}
    self.connections = {}
    self.isActive = false
    self.raycastParams = RaycastParams.new()
    self.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.raycastParams.FilterDescendantsInstances = {}
    return self
end
local function isEnemy(char)
    local localChar = workspace.characters:FindFirstChild("StarterCharacter")
    if not localChar or not char then 
        return true 
    end
    
    local localHead = localChar:FindFirstChild("head")
    local targetHead = char:FindFirstChild("head")
    if not localHead or not targetHead then 
        return true 
    end
    
    local localMount = localHead:FindFirstChild("head")
    local targetMount = targetHead:FindFirstChild("head")
    if not localMount or not targetMount then 
        return true 
    end
    
    local localNVG = localMount:FindFirstChild("mount")
    local targetNVG = targetMount:FindFirstChild("mount")
    if not localNVG or not targetNVG then 
        return true 
    end
    
    local localC1 = localNVG:FindFirstChild("nvg")
    local targetC1 = targetNVG:FindFirstChild("nvg")
    if not localC1 or not targetC1 then 
        return true 
    end
    
    return localC1.C1 ~= targetC1.C1
end
local function getPlayerFromCharacter(character)
    for _, player in ipairs(Players:GetPlayers()) do
        if Characters:FindFirstChild(player.Name) == character then
            return player
        end
    end
    return nil
end
local isVisible = LPH_NO_VIRTUALIZE(function(targetPart)
    if not getgenv().aimbotSettings.visibility_check then return true end
    
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * (targetPart.Position - rayOrigin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    return raycastResult == nil
end)
local getClosestPlayer = LPH_NO_VIRTUALIZE(function()
    local closestPart, shortestDist = nil, getgenv().aimbotSettings.fov_size
    local mousePos = UserInputService:GetMouseLocation()

    for _, char in ipairs(Characters:GetChildren()) do
        if char:IsA("Model") and char.Name ~= LocalPlayer.Name and isEnemy(char) then
            local targetPart = char:FindFirstChild(getgenv().aimbotSettings.aim_part)
            if targetPart and targetPart:IsA("BasePart") and isVisible(targetPart) then
                local predictedPosition = targetPart.Position
                if targetPart.Velocity then
                    predictedPosition = predictedPosition + (targetPart.Velocity * getgenv().aimbotSettings.prediction)
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPosition)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestPart = targetPart
                    end
                end
            end
        end
    end

    return closestPart
end)
local getClosestPlayerSilent = LPH_NO_VIRTUALIZE(function() 
    local closestPart, shortestDist = nil, getgenv().silentAimSettings.fov_size
    local mousePos = UserInputService:GetMouseLocation()
    for _, char in ipairs(Characters:GetChildren()) do
        if char:IsA("Model") and char.Name ~= LocalPlayer.Name and isEnemy(char) then
            local targetPartName = getgenv().silentAimSettings.target_part:lower()
            local targetPart = char:FindFirstChild(targetPartName)
            if targetPart and targetPart:IsA("BasePart") then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        local hitChance = math.random(1, 100)
                        if hitChance <= getgenv().silentAimSettings.hit_chance then
                            shortestDist = dist
                            closestPart = targetPart
                        end
                    end
                end
            end
        end
    end

    return closestPart
end)

local Camera = workspace.CurrentCamera
local Characters = workspace:WaitForChild("characters")
local barWidth = 200
local barHeight = 12
local barX = (Camera.ViewportSize.X / 2) - (barWidth / 2)
local barY = 900
local bgBar = Drawing.new("Square")
bgBar.Size = Vector2.new(barWidth, barHeight)
bgBar.Position = Vector2.new(barX, barY)
bgBar.Color = Color3.fromRGB(50, 50, 50)
bgBar.Filled = true
bgBar.Visible = gunModSettings.bullet_penetration_bar
local fillBar = Drawing.new("Square")
fillBar.Position = Vector2.new(barX, barY)
fillBar.Size = Vector2.new(barWidth, barHeight)
fillBar.Color = Color3.fromRGB(0, 255, 0)
fillBar.Filled = true
fillBar.Visible = gunModSettings.bullet_penetration_bar

local maxCheckWalls = 20
local maxUsefulWalls = 8

-- Utility functions
local function isWall(part)
    return part:IsA("BasePart") and part.CanCollide and not part:IsDescendantOf(Characters)
end
local function countWallsBetween(startPos, endPos, maxWalls)
    local direction = (endPos - startPos).Unit
    local distance = (endPos - startPos).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local ignoreList = {}
    local wallCount = 0
    local currentPos = startPos
    local stepOffset = 0.1

    while true do
        rayParams.FilterDescendantsInstances = ignoreList
        local result = workspace:Raycast(currentPos, direction * distance, rayParams)
        if result then
            if isWall(result.Instance) then
                wallCount += 1
                if wallCount > maxWalls then break end
            end
            table.insert(ignoreList, result.Instance)
            currentPos = result.Position + direction * stepOffset
        else
            break
        end
    end

    return wallCount
end
RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
    local targetPart = getClosestPlayerSilent()
    if targetPart and gunModSettings.bullet_penetration_bar then
        bgBar.Visible = gunModSettings.bullet_penetration_bar
        fillBar.Visible = gunModSettings.bullet_penetration_bar
        local cameraPos = Camera.CFrame.Position
        local wallCount = countWallsBetween(cameraPos, targetPart.Position, maxCheckWalls)

        local fillRatio = 1 - math.clamp(wallCount, 0, maxUsefulWalls) / maxUsefulWalls
        fillBar.Size = Vector2.new(barWidth * fillRatio, barHeight)
    else
        bgBar.Visible = false
        fillBar.Visible = false
        fillBar.Size = Vector2.new(0, barHeight)
    end
end))





local function make_beam_advanced(Origin, Position, Color, Thickness, Duration)
    local folder = workspace:FindFirstChild("BulletTracers")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "BulletTracers"
        folder.Parent = workspace
    end

    tracerCounter = tracerCounter + 1
    local tracerId = "Tracer_" .. tracerCounter .. "_" .. tick()

    local randomOffset1 = Vector3.new(
        math.random(-50, 50) / 1000,
        math.random(-50, 50) / 1000,
        math.random(-50, 50) / 1000
    )
    local randomOffset2 = Vector3.new(
        math.random(-50, 50) / 1000,
        math.random(-50, 50) / 1000,
        math.random(-50, 50) / 1000
    )

    local part1 = Instance.new("Part")
    local part2 = Instance.new("Part")
    part1.Name = tracerId .. "_Start"
    part2.Name = tracerId .. "_End"
    part1.Parent = folder
    part2.Parent = folder
    part1.Position = Origin + randomOffset1
    part2.Position = Position + randomOffset2
    part1.Transparency = 1
    part2.Transparency = 1
    part1.CanCollide = false
    part2.CanCollide = false
    part1.Size = Vector3.new(0.01, 0.01, 0.01)
    part2.Size = Vector3.new(0.01, 0.01, 0.01)
    part1.Anchored = true
    part2.Anchored = true
    part1.Material = Enum.Material.ForceField
    part2.Material = Enum.Material.ForceField

    local OriginAttachment = Instance.new("Attachment", part1)
    local PositionAttachment = Instance.new("Attachment", part2)
    
    local Beam = Instance.new("Beam")
    Beam.Name = tracerId .. "_Beam"
    Beam.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color),
        ColorSequenceKeypoint.new(1, Color)
    }
    Beam.LightEmission = 1
    Beam.LightInfluence = 0.3
    Beam.TextureMode = Enum.TextureMode.Static
    Beam.TextureSpeed = 0
    Beam.Texture = "http://www.roblox.com/asset/?id=446111271"
    Beam.Transparency = NumberSequence.new(0)
    Beam.Attachment0 = OriginAttachment
    Beam.Attachment1 = PositionAttachment
    Beam.FaceCamera = true
    Beam.Segments = 1
    Beam.Width0 = Thickness or 0.35
    Beam.Width1 = Thickness or 0.35
    Beam.ZOffset = math.random(-100, 100) / 10000
    Beam.Parent = folder

    local fadeTime = Duration * 0.7
    task.spawn(function()
        task.wait(fadeTime)
        local steps = 15
        local stepTime = (Duration - fadeTime) / steps
        for i = 1, steps do
            if not Beam or not Beam.Parent then break end
            local alpha = 1 - (i / steps)
            pcall(function()
                Beam.Transparency = NumberSequence.new(1 - alpha)
            end)
            task.wait(stepTime)
        end
    end)

    task.delay(Duration, function()
        pcall(function()
            if Beam and Beam.Parent then Beam:Destroy() end
            if part1 and part1.Parent then part1:Destroy() end
            if part2 and part2.Parent then part2:Destroy() end
        end)
    end)

    return Beam, part1, part2
end

local function createImpactEffect(position, color)
    if not getgenv().bulletTracerSettings.show_impact then return end
    
    local folder = workspace:FindFirstChild("BulletTracers")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "BulletTracers"
        folder.Parent = workspace
    end
    
    impactCounter = impactCounter + 1
    local impactId = "Impact_" .. impactCounter .. "_" .. tick()
    
    local randomOffset = Vector3.new(
        math.random(-100, 100) / 1000,
        math.random(-100, 100) / 1000,
        math.random(-100, 100) / 1000
    )
    
    local impactPart = Instance.new("Part")
    impactPart.Name = impactId
    impactPart.Size = Vector3.new(0.5, 0.5, 0.5)
    impactPart.Position = position + randomOffset
    impactPart.Anchored = true
    impactPart.CanCollide = false
    impactPart.Material = Enum.Material.Neon
    impactPart.Color = color
    impactPart.Shape = Enum.PartType.Ball
    impactPart.TopSurface = Enum.SurfaceType.Smooth
    impactPart.BottomSurface = Enum.SurfaceType.Smooth
    impactPart.Parent = folder
    
    local startSize = Vector3.new(0.1, 0.1, 0.1)
    local endSize = Vector3.new(1.2, 1.2, 1.2)
    impactPart.Size = startSize
    
    local tween1 = game:GetService("TweenService"):Create(
        impactPart,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = endSize }
    )
    tween1:Play()
    
    task.delay(getgenv().bulletTracerSettings.impact_duration - 2, function()
        if impactPart and impactPart.Parent then
            local tween2 = game:GetService("TweenService"):Create(
                impactPart,
                TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {
                    Transparency = 1,
                    Size = Vector3.new(0.3, 0.3, 0.3)
                }
            )
            tween2:Play()
            
            task.delay(2, function()
                pcall(function()
                    if impactPart and impactPart.Parent then
                        impactPart:Destroy()
                    end
                end)
            end)
        end
    end)
end

local function getSmartTracerTarget()
    -- Priority 1: Silent Aim Target (when enabled and available)
    if getgenv().bulletTracerSettings.silent_aim_priority and getgenv().silentAimSettings.silent_aim then
        if silentTarget then
            local hitpart = nil
            if silentTarget.Parent then
                local hitpartName = getgenv().silentAimSettings.target_part
                local hitpartMap = {
                    ["Head"] = "head",
                    ["Torso"] = "torso", 
                    ["HumanoidRootPart"] = "humanoid_root_part",
                    ["Left Arm"] = "left_arm",
                    ["Right Arm"] = "right_arm", 
                    ["Left Leg"] = "left_leg",
                    ["Right Leg"] = "right_leg"
                }
                local mappedName = hitpartMap[hitpartName] or "head"
                hitpart = silentTarget.Parent:FindFirstChild(mappedName) or silentTarget.Parent:FindFirstChild("head")
            end
            
            if hitpart then
                return hitpart.Position, "Silent Aim Target"
            end
        end
    end
    
    -- Priority 2: Mouse position (default behavior)
    local mouse = LocalPlayer:GetMouse()
    local camera = Camera
    
    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = Workspace:Raycast(
        unitRay.Origin, 
        unitRay.Direction * getgenv().bulletTracerSettings.max_distance, 
        raycastParams
    )
    
    if raycastResult then
        return raycastResult.Position, "Mouse Target"
    else
        return unitRay.Origin + (unitRay.Direction * getgenv().bulletTracerSettings.max_distance), "Mouse Direction"
    end
end
local function setupGunMods()
    local camera = Workspace.CurrentCamera
    
    local getTargetHitpart = function(target)
        if not target then return nil end
        local hitpartName = getgenv().silentAimSettings.target_part
        local hitpartMap = {
            ["Head"] = "head",
            ["Torso"] = "torso", 
            ["HumanoidRootPart"] = "humanoid_root_part",
            ["Left Arm"] = "left_arm",
            ["Right Arm"] = "right_arm", 
            ["Left Leg"] = "left_leg",
            ["Right Leg"] = "right_leg"
        }
        local mappedName = hitpartMap[hitpartName] or "head"
        return target:FindFirstChild(mappedName) or target:FindFirstChild("head")
    end
    local function safeHook()
        local success, err = pcall(function()
            local old
            old = hookfunction(CFrame.Angles, newcclosure(function(self, ...)
                if debug.info(4,"n") == "fire_fp_weapon" and debug.info(4,"l") == 161 then
                    local tbl = debug.getstack(4,1)
                    if not tbl then return old(self, ...) end
                    
                    if getgenv().gunModSettings.infinite_stamina and tbl.stamina then
                        rawset(tbl, "stamina", 999)
                    end
                    
                    if getgenv().gunModSettings.infinite_adrenaline and tbl.adrenaline then
                        rawset(tbl, "adrenaline", 60)
                    end
                    
                    if getgenv().gunModSettings.no_suppression_blur and tbl.suppression_blur then
                        rawset(tbl, "suppression_blur", 0)
                    end 
                    if getgenv().charSettings.TPerson then
                        rawset(tbl, "camera_state", "TPerson")
                    end
                    
                    if getgenv().charSettings.SpeedHack then
                        local char_data = rawget(tbl, "char_data")
                        rawset(char_data,"collective_weight",0.0000000000001)
                    end
                    local weapon = rawget(tbl, "weapon")
                    if weapon and type(weapon) == "table" then
                        if getgenv().gunModSettings.auto_firemode then
                            rawset(weapon, "firemode", "auto")
                        end
                        if getgenv().gunModSettings.no_recoil then
                            rawset(weapon, "progressive_recoil_multiplier", 0)
                        end
                    end
                    
                    local t = debug.getstack(4,11)
                    if t and type(t) == "table" then
                        if getgenv().gunModSettings.bullet_penetration then
                            rawset(t, "bullet_penetration_ability", math.huge)
                        end
                        if getgenv().gunModSettings.no_spread then
                            rawset(t, "spread_multiplier", 0)
                        end
                        if getgenv().gunModSettings.no_muzzle_flash then
                            rawset(t, "muzzle_flash_chance", 0)
                        end
                        if getgenv().gunModSettings.instant_bullet then
                            rawset(t, "velocity", 10000)
                            rawset(t, "velocity_drop", 0.0000001)
                        end
                        
                        debug.setstack(4,11,t)
                    end
                    local a = getstack(6,9)
                    if a then
                        local build = rawget(a, "build")
                        local result = rawget(build, "result")
                        if getgenv().gunModSettings.multi_bullet then
                            rawset(result, "firerate", 20000)
                        end
                        debug.setstack(6,9,a)
                    end
                    
                    if getgenv().silentAimSettings.silent_aim then
                        if silentTarget then
                            local hitpart = getTargetHitpart(silentTarget.Parent)
                            if hitpart and hitpart.Position then
                                debug.setstack(4, 16, CFrame.new(camera.CFrame.Position, hitpart.Position))
                                
                            end
                        end
                    end
                    debug.setstack(4,1,tbl)
                    if getgenv().bulletTracerSettings.enabled then
                        local targetPosition, targetType = getSmartTracerTarget()
                        if targetPosition then
                            make_beam_advanced(
                                camera.CFrame.Position,
                                targetPosition,
                                getgenv().bulletTracerSettings.tracer_color,
                                getgenv().bulletTracerSettings.thickness,
                                getgenv().bulletTracerSettings.duration
                            )
                            createImpactEffect(targetPosition, getgenv().bulletTracerSettings.tracer_color)
                        end
                    end

                    -- Original Silent Aim Tracer (only when Bullet Tracer System is disabled)
                    if getgenv().silentAimSettings.bullet_tracer and not getgenv().bulletTracerSettings.enabled then
                        local beam, part1, part2 = make_beam_advanced(
                            camera.CFrame.Position, 
                            hitpart.Position, 
                            getgenv().silentAimSettings.bullet_tracer_color,
                            0.25,
                            1
                        )
                    end
                end
                return old(self, ...)
            end))
        end)
    end
    safeHook()
end
setupGunMods()
function ESPSystem:createESPElements(model)
    if not model or not model.Parent then 
        return nil 
    end
    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = getgenv().espSettings.boxThickness + getgenv().espSettings.outlineThickness
    boxOutline.Color = Color3.fromRGB(0, 0, 0)
    boxOutline.Transparency = 1
    boxOutline.Filled = false
    boxOutline.Visible = false
    boxOutline.ZIndex = 1
    local box = Drawing.new("Square")
    box.Thickness = getgenv().espSettings.boxThickness
    box.Color = getgenv().espSettings.visibleColor
    box.Transparency = 1
    box.Filled = false
    box.Visible = false
    box.ZIndex = 2
    local skeletonLines = {}
    local skeletonConnections = {
        {"head", "humanoid_root_part"},
        {"humanoid_root_part", "left_arm_vis"},
        {"humanoid_root_part", "right_arm_vis"},
        {"humanoid_root_part", "left_leg_vis"},
        {"humanoid_root_part", "right_leg_vis"},
        {"left_arm_vis", "left_arm"},
        {"right_arm_vis", "right_arm"},
        {"left_leg_vis", "left_leg"},
        {"right_leg_vis", "right_leg"},
        {"humanoid_root_part", "torso"}
    }
    
    for _, connection in pairs(skeletonConnections) do
        local outlineLine = Drawing.new("Line")
        outlineLine.Color = Color3.fromRGB(0, 0, 0)
        outlineLine.Thickness = getgenv().espSettings.skeletonThickness + getgenv().espSettings.outlineThickness
        outlineLine.Transparency = 1
        outlineLine.Visible = false
        outlineLine.ZIndex = 1
        local line = Drawing.new("Line")
        line.Color = getgenv().espSettings.visibleColor
        line.Thickness = getgenv().espSettings.skeletonThickness
        line.Transparency = 1
        line.Visible = false
        line.ZIndex = 2
        table.insert(skeletonLines, {
            outlineLine = outlineLine,
            line = line, 
            from = connection[1], 
            to = connection[2]
        })
    end
    local traceOutline = Drawing.new("Line")
    traceOutline.Thickness = getgenv().espSettings.tracerThickness + getgenv().espSettings.outlineThickness
    traceOutline.Color = Color3.fromRGB(0, 0, 0)
    traceOutline.Transparency = 1
    traceOutline.Visible = false
    traceOutline.ZIndex = 1
    local trace = Drawing.new("Line")
    trace.Thickness = getgenv().espSettings.tracerThickness
    trace.Color = getgenv().espSettings.visibleColor
    trace.Transparency = 1
    trace.Visible = false
    trace.ZIndex = 2
    local healthBG = Drawing.new("Square")
    healthBG.Thickness = 1
    healthBG.Color = Color3.fromRGB(0, 0, 0)
    healthBG.Transparency = 0.7
    healthBG.Filled = true
    healthBG.Visible = false
    healthBG.ZIndex = 1
    local healthBorder = Drawing.new("Square")
    healthBorder.Thickness = 1
    healthBorder.Color = Color3.fromRGB(50, 50, 50)
    healthBorder.Transparency = 1
    healthBorder.Filled = false
    healthBorder.Visible = false
    healthBorder.ZIndex = 2
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 0
    healthBar.Color = getgenv().espSettings.healthColor
    healthBar.Transparency = 1
    healthBar.Filled = true
    healthBar.Visible = false
    healthBar.ZIndex = 3
    local nameText = Drawing.new("Text")
    nameText.Text = "Loading..."
    nameText.Size = getgenv().espSettings.nameSize
    nameText.Color = getgenv().espSettings.nameColor
    nameText.Font = Drawing.Fonts.Plex
    nameText.Center = true
    nameText.Outline = getgenv().espSettings.outline
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Transparency = 1
    nameText.Visible = false
    nameText.ZIndex = 3
    local distanceText = Drawing.new("Text")
    distanceText.Text = "0m"
    distanceText.Size = getgenv().espSettings.distanceSize
    distanceText.Color = getgenv().espSettings.distanceColor
    distanceText.Font = Drawing.Fonts.Plex
    distanceText.Center = true
    distanceText.Outline = getgenv().espSettings.outline
    distanceText.OutlineColor = Color3.fromRGB(0, 0, 0)
    distanceText.Transparency = 1
    distanceText.Visible = false
    distanceText.ZIndex = 3
    local weaponText = Drawing.new("Text")
    weaponText.Text = "Unknown"
    weaponText.Size = getgenv().espSettings.weaponSize
    weaponText.Color = getgenv().espSettings.weaponColor
    weaponText.Font = Drawing.Fonts.Plex
    weaponText.Center = true
    weaponText.Outline = getgenv().espSettings.outline
    weaponText.OutlineColor = Color3.fromRGB(0, 0, 0)
    weaponText.Transparency = 1
    weaponText.Visible = false
    weaponText.ZIndex = 3
    return {
        boxOutline = boxOutline,
        box = box,
        skeletonLines = skeletonLines,
        traceOutline = traceOutline,
        trace = trace,
        healthBG = healthBG,
        healthBorder = healthBorder,
        healthBar = healthBar,
        nameText = nameText,
        distanceText = distanceText,
        weaponText = weaponText,
        model = model
    }
end
function ESPSystem:updatePlayerNameMapping()
    local currentPlayerCount = #Players:GetPlayers()
    self.lastPlayerCount = currentPlayerCount
    self.dynamicPlayerMap = {}
    local sortedPlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= self.localPlayer then 
            table.insert(sortedPlayers, player)
        end
    end
    table.sort(sortedPlayers, function(a, b)
        return a.UserId < b.UserId
    end)
    local charactersFolder = Workspace:FindFirstChild("characters")
    local characterModels = {}
    if charactersFolder then
        for _, model in pairs(charactersFolder:GetChildren()) do
            if model:IsA("Model") and string.match(model.Name, "^%d+$") then
                local isLocalChar = false
                if self.localPlayer and self.localPlayer.Character then
                    if model == self.localPlayer.Character then
                        isLocalChar = true
                    end
                end
                if model.Name == "StarterCharacter" then
                    isLocalChar = true
                end
                if not isLocalChar then
                    table.insert(characterModels, {
                        model = model,
                        id = tonumber(model.Name)
                    })
                end
            end
        end
    end
    table.sort(characterModels, function(a, b)
        return a.id < b.id
    end)
    local maxMappings = math.min(#sortedPlayers, #characterModels)
    for i = 1, maxMappings do
        local player = sortedPlayers[i]
        local charData = characterModels[i]
        
        if player and charData then
            local displayName = player.DisplayName
            if not displayName or displayName == "" then
                displayName = player.Name
            end
            local modelName = tostring(charData.id)
            
            self.dynamicPlayerMap[modelName] = displayName
        end
    end
    for i = maxMappings + 1, #characterModels do
        local charData = characterModels[i]
        local modelName = tostring(charData.id)
        self.dynamicPlayerMap[modelName] = "Unknown Player " .. modelName
    end
end

function ESPSystem:getDisplayName(model)
    if not model then return "Enemy" end
    
    local modelName = model.Name
    if self.localPlayer and self.localPlayer.Character and model == self.localPlayer.Character then
        return "LOCAL"
    end
    if modelName == "StarterCharacter" then
        return "LOCAL"
    end
    self:updatePlayerNameMapping()
    if self.dynamicPlayerMap[modelName] then
        return self.dynamicPlayerMap[modelName]
    end
    local player = self:getPlayerFromModel(model)
    if player then
        local displayName = player.DisplayName
        if displayName and displayName ~= "" then
            return displayName
        end
        return player.Name or "Player"
    end
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("StringValue") and child.Value ~= "" then
            local childName = string.lower(child.Name)
            if string.find(childName, "name") or string.find(childName, "player") or 
               string.find(childName, "user") or string.find(childName, "display") then
                return child.Value
            end
        end
    end
    if string.match(modelName, "^%d+$") then
        for _, plr in pairs(Players:GetPlayers()) do
            if tostring(plr.UserId) == modelName then
                local name = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
                return name
            end
        end
        return "Player " .. modelName
    end
    local cleanName = modelName
    cleanName = string.gsub(cleanName, "%d+$", "")
    cleanName = string.gsub(cleanName, "_+$", "")
    cleanName = string.gsub(cleanName, "_", " ")
    
    if cleanName ~= "" and cleanName ~= "Model" then
        return cleanName
    end
    
    return "Enemy"
end

function ESPSystem:getPlayerFromModel(model)
    if not model then return nil end
    
    -- First try direct character matching
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character == model then
            return player
        end
    end
    
    -- Try matching by UserId (for custom characters with numeric names)
    local modelName = model.Name
    if string.match(modelName, "^%d+$") then
        for _, player in pairs(Players:GetPlayers()) do
            if tostring(player.UserId) == modelName then
                return player
            end
        end
    end
    
    -- Try matching by name (case insensitive)
    local modelNameLower = string.lower(modelName)
    for _, player in pairs(Players:GetPlayers()) do
        if string.lower(player.Name) == modelNameLower then
            return player
        end
    end
    
    return nil
end

function ESPSystem:isTeammate(model)
    if not self.localPlayer then
        return false
    end
    
    -- First check using the custom NVG-based enemy detection
    if not isEnemy(model) then
        return true -- Not an enemy = teammate
    end
    
    return false
end

function ESPSystem:findRootPart(model)
    local rootPartNames = {"HumanoidRootPart", "humanoid_root_part", "Torso", "UpperTorso"}
    for _, name in pairs(rootPartNames) do
        local part = model:FindFirstChild(name)
        if part then
            return part
        end
    end
    return nil
end

function ESPSystem:findHumanoid(model)
    local humanoidNames = {"Humanoid", "humanoid"}
    for _, name in pairs(humanoidNames) do
        local humanoid = model:FindFirstChild(name)
        if humanoid then
            return humanoid
        end
    end
    return nil
end

function ESPSystem:getHealthInfo(model)
    local humanoid = self:findHumanoid(model)
    if not humanoid or not humanoid.MaxHealth or humanoid.MaxHealth <= 0 then
        return 1, getgenv().espSettings.healthColor
    end
    
    local currentHealth = math.max(0, humanoid.Health or 0)
    local maxHealth = humanoid.MaxHealth
    local healthPercent = math.min(1, currentHealth / maxHealth)
    
    -- Smooth RGB gradient from Red → Orange → Green
    local healthColor
    if healthPercent <= 0.5 then
        local factor = healthPercent * 2
        local red = 255
        local green = math.floor(165 * factor)
        local blue = 0
        healthColor = Color3.fromRGB(red, green, blue)
    else
        local factor = (healthPercent - 0.5) * 2
        local red = math.floor(255 - (255 * factor))
        local green = math.floor(165 + (90 * factor))
        local blue = 0
        healthColor = Color3.fromRGB(red, green, blue)
    end
    
    return healthPercent, healthColor
end

function ESPSystem:getDistance(model)
    if not model then return 0 end
    
    local rootPart = self:findRootPart(model)
    if not rootPart then return 0 end
    
    local cameraPos = self.camera.CFrame.Position
    local targetPos = rootPart.CFrame.Position
    local distance = (targetPos - cameraPos).Magnitude
    
    return math.floor(distance + 0.5)
end

function ESPSystem:getWeaponInfo(model)
    if not model then return "Unknown" end
    
    local weaponNames = {"rifle", "smg", "pistol", "sniper", "shotgun", "launcher", "grenade", "knife", "weapon", "gun"}
    
    -- Search for weapons in the model
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Model") or child:IsA("Part") or child:IsA("MeshPart") then
            local childName = string.lower(child.Name)
            for _, weaponName in pairs(weaponNames) do
                if string.find(childName, weaponName) then
                    local displayName = string.gsub(child.Name, "_", " ")
                    displayName = string.gsub(displayName, "%d+$", "")
                    displayName = string.gsub(displayName, "^%l", string.upper)
                    return displayName ~= "" and displayName or "Weapon"
                end
            end
        end
    end
    
    return "Unarmed"
end

function ESPSystem:isVisibleESP(rootPart)
    if not rootPart or not getgenv().espSettings.visibilityCheck then 
        return true 
    end
    
    local cameraPos = self.camera.CFrame.Position
    local targetPos = rootPart.CFrame.Position
    
    local direction = (targetPos - cameraPos)
    local distance = direction.Magnitude
    
    if distance <= 0.5 then return true end
    
    direction = direction.Unit * (distance - 0.5)
    
    self.raycastParams.FilterDescendantsInstances = {rootPart.Parent}
    
    local result = Workspace:Raycast(cameraPos, direction, self.raycastParams)
    return result == nil
end

function ESPSystem:getBodyParts(model)
    local parts = {}
    for _, partName in pairs({"head", "humanoid_root_part", "left_arm_vis", "right_arm_vis", 
                             "left_leg_vis", "right_leg_vis", "left_arm", "right_arm", 
                             "left_leg", "right_leg", "torso"}) do
        local part = model:FindFirstChild(partName)
        if part then
            parts[partName] = part
        end
    end
    return parts
end

function ESPSystem:updateSkeleton(esp, bodyParts, isVisible)
    if not getgenv().espSettings.skeleton then
        for _, lineData in pairs(esp.skeletonLines) do
            lineData.outlineLine.Visible = false
            lineData.line.Visible = false
        end
        return
    end
    
    for _, lineData in pairs(esp.skeletonLines) do
        local fromPart = bodyParts[lineData.from]
        local toPart = bodyParts[lineData.to]
        
        if fromPart and toPart then
            local fromPos, fromOnScreen = self.camera:WorldToViewportPoint(fromPart.CFrame.Position)
            local toPos, toOnScreen = self.camera:WorldToViewportPoint(toPart.CFrame.Position)
            
            if fromOnScreen and toOnScreen and fromPos.Z > 0 and toPos.Z > 0 then
                local from2D = Vector2.new(fromPos.X, fromPos.Y)
                local to2D = Vector2.new(toPos.X, toPos.Y)
                
                local color = getgenv().espSettings.visibilityCheck and 
                    (isVisible and getgenv().espSettings.visibleColor or getgenv().espSettings.hiddenColor) or
                    getgenv().espSettings.basicColor
                
                -- Update outline
                if getgenv().espSettings.outline then
                    lineData.outlineLine.From = from2D
                    lineData.outlineLine.To = to2D
                    lineData.outlineLine.Thickness = getgenv().espSettings.skeletonThickness + getgenv().espSettings.outlineThickness
                    lineData.outlineLine.Visible = true
                else
                    lineData.outlineLine.Visible = false
                end
                
                -- Update main line
                lineData.line.From = from2D
                lineData.line.To = to2D
                lineData.line.Color = color
                lineData.line.Thickness = getgenv().espSettings.skeletonThickness
                lineData.line.Visible = true
            else
                lineData.outlineLine.Visible = false
                lineData.line.Visible = false
            end
        else
            lineData.outlineLine.Visible = false
            lineData.line.Visible = false
        end
    end
end

function ESPSystem:setupESP(model)
    if not model or not model.Parent then 
        return 
    end
    
    if self.espObjects[model] then 
        return 
    end
    
    if self:isTeammate(model) then
        return
    end
    
    local espElements = self:createESPElements(model)
    if espElements then
        self.espObjects[model] = espElements
    end
end

function ESPSystem:updateESP()
    if not getgenv().espSettings.enabled then
        for _, esp in pairs(self.espObjects) do
            self:hideESPElements(esp)
        end
        return
    end
    
    for model, esp in pairs(self.espObjects) do
        if not model or not model.Parent then
            self:cleanupESP(esp)
            self.espObjects[model] = nil
            continue
        end
        
        if self:isTeammate(model) then
            self:cleanupESP(esp)
            self.espObjects[model] = nil
            continue
        end
        
        local rootPart = self:findRootPart(model)
        
        if rootPart then
            local position = rootPart.CFrame.Position
            local screenPos, onScreen = self.camera:WorldToViewportPoint(position)
            
            if onScreen and screenPos.Z > 0 then
                local upVector = rootPart.CFrame.UpVector.Y
                local offset = Vector3.new(0, 3 * math.abs(upVector), 0)
                local topPos = self.camera:WorldToViewportPoint(position + offset)
                local bottomPos = self.camera:WorldToViewportPoint(position - offset)
                
                local height = math.abs(topPos.Y - bottomPos.Y)
                local width = height * 0.6
                
                local isVisible = self:isVisibleESP(rootPart)
                local color = getgenv().espSettings.visibilityCheck and 
                    (isVisible and getgenv().espSettings.visibleColor or getgenv().espSettings.hiddenColor) or
                    getgenv().espSettings.basicColor
                
                -- Update boxes
                if getgenv().espSettings.boxes then
                    -- Update box outline
                    if getgenv().espSettings.outline then
                        esp.boxOutline.Size = Vector2.new(width, height)
                        esp.boxOutline.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                        esp.boxOutline.Thickness = getgenv().espSettings.boxThickness + getgenv().espSettings.outlineThickness
                        esp.boxOutline.Visible = true
                    else
                        esp.boxOutline.Visible = false
                    end
                    
                    -- Update main box
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                    esp.box.Color = color
                    esp.box.Thickness = getgenv().espSettings.boxThickness
                    esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false
                    esp.box.Visible = false
                end
                
                -- Update skeleton
                local bodyParts = self:getBodyParts(model)
                self:updateSkeleton(esp, bodyParts, isVisible)
                
                -- Update tracers
                if getgenv().espSettings.tracers then
                    local centerScreen = Vector2.new(self.camera.ViewportSize.X / 2, self.camera.ViewportSize.Y)
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    
                    -- Update trace outline
                    if getgenv().espSettings.outline then
                        esp.traceOutline.From = centerScreen
                        esp.traceOutline.To = targetPos
                        esp.traceOutline.Thickness = getgenv().espSettings.tracerThickness + getgenv().espSettings.outlineThickness
                        esp.traceOutline.Visible = true
                    else
                        esp.traceOutline.Visible = false
                    end
                    
                    -- Update main trace
                    esp.trace.From = centerScreen
                    esp.trace.To = targetPos
                    esp.trace.Color = color
                    esp.trace.Thickness = getgenv().espSettings.tracerThickness
                    esp.trace.Visible = true
                else
                    esp.traceOutline.Visible = false
                    esp.trace.Visible = false
                end
                
                -- Update health bar
                if getgenv().espSettings.health then
                    local healthPercent, healthColor = self:getHealthInfo(model)
                    local healthBarHeight = height * 0.88
                    local healthBarWidth = 4
                    
                    -- Health bar background
                    esp.healthBG.Size = Vector2.new(healthBarWidth + 2, healthBarHeight + 2)
                    esp.healthBG.Position = Vector2.new(
                        screenPos.X - width / 2 - 6 - healthBarWidth - 1,
                        screenPos.Y - healthBarHeight / 2 - 1
                    )
                    esp.healthBG.Visible = true
                    
                    -- Health bar border
                    esp.healthBorder.Size = Vector2.new(healthBarWidth + 2, healthBarHeight + 2)
                    esp.healthBorder.Position = Vector2.new(
                        screenPos.X - width / 2 - 6 - healthBarWidth - 1,
                        screenPos.Y - healthBarHeight / 2 - 1
                    )
                    esp.healthBorder.Visible = true
                    
                    -- Main health bar
                    local actualHealthHeight = math.max(2, healthBarHeight * healthPercent)
                    esp.healthBar.Size = Vector2.new(healthBarWidth, actualHealthHeight)
                    esp.healthBar.Position = Vector2.new(
                        screenPos.X - width / 2 - 6 - healthBarWidth,
                        screenPos.Y + healthBarHeight / 2 - actualHealthHeight
                    )
                    esp.healthBar.Color = healthColor
                    esp.healthBar.Visible = true
                else
                    esp.healthBG.Visible = false
                    esp.healthBorder.Visible = false
                    esp.healthBar.Visible = false
                end
                
                -- Update name
                if getgenv().espSettings.names then
                    local currentName = self:getDisplayName(model)
                    esp.nameText.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 20)
                    esp.nameText.Text = currentName or "Enemy"
                    esp.nameText.Color = getgenv().espSettings.nameColor
                    esp.nameText.Size = getgenv().espSettings.nameSize
                    esp.nameText.Outline = getgenv().espSettings.outline
                    esp.nameText.Visible = true
                else
                    esp.nameText.Visible = false
                end
                
                -- Update weapon
                if getgenv().espSettings.weapon then
                    local weapon = self:getWeaponInfo(model)
                    esp.weaponText.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 5)
                    esp.weaponText.Text = weapon
                    esp.weaponText.Color = getgenv().espSettings.weaponColor
                    esp.weaponText.Size = getgenv().espSettings.weaponSize
                    esp.weaponText.Outline = getgenv().espSettings.outline
                    esp.weaponText.Visible = true
                else
                    esp.weaponText.Visible = false
                end
                
                -- Update distance
                if getgenv().espSettings.distance then
                    local distance = self:getDistance(model)
                    esp.distanceText.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 18)
                    esp.distanceText.Text = distance .. "m"
                    esp.distanceText.Color = getgenv().espSettings.distanceColor
                    esp.distanceText.Size = getgenv().espSettings.distanceSize
                    esp.distanceText.Outline = getgenv().espSettings.outline
                    esp.distanceText.Visible = true
                else
                    esp.distanceText.Visible = false
                end
                
            else
                self:hideESPElements(esp)
            end
        else
            self:hideESPElements(esp)
        end
    end
end

function ESPSystem:hideESPElements(esp)
    esp.boxOutline.Visible = false
    esp.box.Visible = false
    esp.healthBG.Visible = false
    esp.healthBorder.Visible = false
    esp.healthBar.Visible = false
    esp.nameText.Visible = false
    esp.distanceText.Visible = false
    esp.weaponText.Visible = false
    esp.traceOutline.Visible = false
    esp.trace.Visible = false
    for _, lineData in pairs(esp.skeletonLines) do
        lineData.outlineLine.Visible = false
        lineData.line.Visible = false
    end
end

function ESPSystem:cleanupESP(esp)
    if esp.boxOutline then esp.boxOutline:Remove() end
    if esp.box then esp.box:Remove() end
    if esp.traceOutline then esp.traceOutline:Remove() end
    if esp.trace then esp.trace:Remove() end
    if esp.healthBG then esp.healthBG:Remove() end
    if esp.healthBorder then esp.healthBorder:Remove() end
    if esp.healthBar then esp.healthBar:Remove() end
    if esp.nameText then esp.nameText:Remove() end
    if esp.distanceText then esp.distanceText:Remove() end
    if esp.weaponText then esp.weaponText:Remove() end
    if esp.skeletonLines then
        for _, lineData in pairs(esp.skeletonLines) do
            if lineData.outlineLine then lineData.outlineLine:Remove() end
            if lineData.line then lineData.line:Remove() end
        end
    end
end

function ESPSystem:initialize()
    if self.isActive then
        return
    end
    
    -- Initialize dynamic mapping system
    self.dynamicPlayerMap = {}
    self.lastPlayerCount = 0
    
    -- Wait a moment for all players and characters to load
    task.wait(2)
    
    -- Build initial player name mapping
    self:updatePlayerNameMapping()
    
    local charactersFolder = Workspace:FindFirstChild("characters")
    
    if charactersFolder then
        for _, model in ipairs(charactersFolder:GetChildren()) do
            if model:IsA("Model") and self:findRootPart(model) then
                task.spawn(function()
                    task.wait(0.1)
                    self:setupESP(model)
                end)
            end
        end
        self:connectEvents(charactersFolder)
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and self:findRootPart(player.Character) then
                task.spawn(function()
                    task.wait(0.1)
                    self:setupESP(player.Character)
                end)
            end
        end
        self:connectPlayerEvents()
    end
    
    self.isActive = true
end

function ESPSystem:connectEvents(folder)
    self.connections.update = RunService.Heartbeat:Connect(function()
        pcall(function()
            self:updateESP()
        end)
    end)
    
    self.connections.childAdded = folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") and self:findRootPart(child) then
            task.spawn(function()
                task.wait(0.1)
                self:setupESP(child)
            end)
        end
    end)
    
    self.connections.childRemoved = folder.ChildRemoved:Connect(function(child)
        if self.espObjects[child] then
            self:cleanupESP(self.espObjects[child])
            self.espObjects[child] = nil
        end
    end)
    
    -- Update player mapping when players join/leave
    self.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        self:updatePlayerNameMapping()
    end)
    
    self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        task.wait(1)
        self:updatePlayerNameMapping()
    end)
end

function ESPSystem:connectPlayerEvents()
    self.connections.update = RunService.Heartbeat:Connect(function()
        pcall(function()
            self:updateESP()
        end)
    end)
    
    -- Update player mapping when players join/leave
    self.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        self:updatePlayerNameMapping()
        
        local function onCharacterAdded(character)
            if self:findRootPart(character) then
                task.spawn(function()
                    task.wait(0.1)
                    self:setupESP(character)
                end)
            end
        end
        
        if player.Character then
            onCharacterAdded(player.Character)
        end
        
        self.connections["player_" .. player.UserId] = player.CharacterAdded:Connect(onCharacterAdded)
    end)
    
    -- Setup existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= self.localPlayer and player.Character and self:findRootPart(player.Character) then
            task.spawn(function()
                task.wait(0.1)
                self:setupESP(player.Character)
            end)
        end
        
        -- Connect to future character spawns
        self.connections["player_" .. player.UserId] = player.CharacterAdded:Connect(function(character)
            if self:findRootPart(character) then
                task.spawn(function()
                    task.wait(0.1)
                    self:setupESP(character)
                end)
            end
        end)
    end
    
    -- Handle player leaving and rebuild mapping
    self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        if self.connections["player_" .. player.UserId] then
            self.connections["player_" .. player.UserId]:Disconnect()
            self.connections["player_" .. player.UserId] = nil
        end
        
        -- Clean up ESP for their character
        if player.Character and self.espObjects[player.Character] then
            self:cleanupESP(self.espObjects[player.Character])
            self.espObjects[player.Character] = nil
        end
        
        -- Rebuild mapping after player leaves
        task.wait(1)
        self:updatePlayerNameMapping()
    end)
end

function ESPSystem:destroy()
    -- Clean up all ESP objects
    for _, esp in pairs(self.espObjects) do
        self:cleanupESP(esp)
    end
    self.espObjects = {}
    
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    self.isActive = false
end


local espSystem = ESPSystem.new()
espSystem:initialize()

-- God Mode System
local godModeConnection = nil

local function startGodMode()
    if godModeConnection then return end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if not Settings.godMode then
            if godModeConnection then godModeConnection:Disconnect() godModeConnection = nil end
            return
        end
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end
    end)
end

local function stopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

-- Flight and Movement System
local flyConnection = nil
local noclipConnection = nil

local function startFly()
    if flyConnection then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not Settings.fly then
            if bodyVelocity then bodyVelocity:Destroy() end
            if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            return
        end
        
        local camera = Workspace.CurrentCamera
        local moveVector = humanoid.MoveDirection * Settings.flySpeed
        local cameraDirection = camera.CFrame.LookVector
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, Settings.flySpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, Settings.flySpeed, 0)
        end
        
        bodyVelocity.Velocity = moveVector
    end)
end

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local bodyVelocity = rootPart:FindFirstChild("BodyVelocity")
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
        end
    end
end

local function startNoclip()
    if noclipConnection then return end
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not Settings.noclip then
            if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
            return
        end
        
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- Aimbot Loop
RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
    -- Update FOV circles positions
    local mousePos = UserInputService:GetMouseLocation()
    fov.Position = mousePos
    silentFov.Position = mousePos
    
    -- Update Silent Aim target and line
    if getgenv().silentAimSettings.silent_aim then
        silentTarget = getClosestPlayerSilent()
        if silentTarget and getgenv().silentAimSettings.target_line then
            local screenPos, onScreen = Camera:WorldToViewportPoint(silentTarget.Position)
            if onScreen then
                targetLine.From = mousePos
                targetLine.To = Vector2.new(screenPos.X, screenPos.Y)
                targetLine.Visible = true
            else
                targetLine.Visible = false
            end
        else
            targetLine.Visible = false
        end
    else
        targetLine.Visible = false
        silentTarget = nil
    end

    if getgenv().aimbotSettings.aimbot_enabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            currentTarget = getClosestPlayer()
        else
            currentTarget = nil
        end

        if currentTarget then
            local predictedPosition = currentTarget.Position
            if currentTarget.Velocity then
                predictedPosition = predictedPosition + (currentTarget.Velocity * getgenv().aimbotSettings.prediction)
            end

            local screenPos = Camera:WorldToViewportPoint(predictedPosition)
            local mousePos = UserInputService:GetMouseLocation()
            local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos

            local move = delta * (getgenv().aimbotSettings.smoothness / 100)
            move = Vector2.new(
                math.clamp(move.X, -100, 100),
                math.clamp(move.Y, -100, 100)
            )

            mousemoverel(move.X, move.Y)
        end
    end
end))

-- HOTKEY: Press X to toggle aim_part
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.X then
        getgenv().aimbotSettings.aim_part = getgenv().aimbotSettings.aim_part == "head" and "torso" or "head"
        print("[Aimbot] Changed target to:", getgenv().aimbotSettings.aim_part)
    end
end)

-- Create GUI
local gui = GuiLibrary.new("Lynix")

-- Show welcome notification
gui:Notify("Lynix", "Successfully loaded!", "success", 3)

-- COMBAT TAB
local combatTab = gui:CreateTab("Combat")

-- Aimbot Section
local aimbotSection = combatTab:CreateSection("Aimbot")

aimbotSection:CreateToggle("Aimbot", getgenv().aimbotSettings.aimbot_enabled, function(value)
    getgenv().aimbotSettings.aimbot_enabled = value
end)

aimbotSection:CreateToggle("Show FOV", getgenv().aimbotSettings.show_fov, function(value)
    getgenv().aimbotSettings.show_fov = value
    fov.Visible = value
end)

aimbotSection:CreateSlider("FOV Size", 30, 300, getgenv().aimbotSettings.fov_size, function(value)
    getgenv().aimbotSettings.fov_size = value
    fov.Radius = value
end)

aimbotSection:CreateSlider("Smoothness", 1, 100, getgenv().aimbotSettings.smoothness, function(value)
    getgenv().aimbotSettings.smoothness = value
end)

aimbotSection:CreateDropdown("Target Part", {"head", "torso", "humanoidrootpart"}, function(value)
    getgenv().aimbotSettings.aim_part = value
end)

aimbotSection:CreateToggle("Visibility Check", getgenv().aimbotSettings.visibility_check, function(value)
    getgenv().aimbotSettings.visibility_check = value
end)

-- Silent Aim Section
local silentAimSection = combatTab:CreateSection("Silent Aim")

silentAimSection:CreateToggle("Silent Aim", getgenv().silentAimSettings.silent_aim, function(value)
    getgenv().silentAimSettings.silent_aim = value
end)

silentAimSection:CreateToggle("Show FOV", getgenv().silentAimSettings.show_fov, function(value)
    getgenv().silentAimSettings.show_fov = value
    silentFov.Visible = value
end)

silentAimSection:CreateSlider("FOV Size", 30, 300, getgenv().silentAimSettings.fov_size, function(value)
    getgenv().silentAimSettings.fov_size = value
    silentFov.Radius = value
end)

silentAimSection:CreateSlider("Hit Chance", 1, 100, getgenv().silentAimSettings.hit_chance, function(value)
    getgenv().silentAimSettings.hit_chance = value
end)

silentAimSection:CreateDropdown("Target Part", {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, function(value)
    getgenv().silentAimSettings.target_part = value
end)

silentAimSection:CreateToggle("Target Line", getgenv().silentAimSettings.target_line, function(value)
    getgenv().silentAimSettings.target_line = value
    if not value then
        targetLine.Visible = false
    end
end)
silentAimSection:CreateToggle("Show Bullet Tracers", getgenv().silentAimSettings.bullet_tracer, function(value)
    getgenv().silentAimSettings.bullet_tracer = value
end)

-- VISUALS TAB
local visualsTab = gui:CreateTab("Visuals")
local worldTab = gui:CreateTab("World")
local worldSection = worldTab:CreateSection("World Visuals")


worldSection:CreateToggle("Gradient", getgenv().worldVisuals.gradient, function(value)
    getgenv().worldVisuals.gradient = value
end)

worldSection:CreateColorPicker("gradient color1", getgenv().worldVisuals.gradientcolor1, function(color)
    getgenv().worldVisuals.gradientcolor1 = color
end)
worldSection:CreateColorPicker("gradient color2", getgenv().worldVisuals.gradientcolor2, function(color)
    getgenv().worldVisuals.gradientcolor2 = color
end)


local bulletTracerSection = worldTab:CreateSection("Bullet Tracers")

bulletTracerSection:CreateToggle("Enable Bullet Tracers", getgenv().bulletTracerSettings.enabled, function(value)
    getgenv().bulletTracerSettings.enabled = value
end)

bulletTracerSection:CreateToggle("Show Impact Effects", getgenv().bulletTracerSettings.show_impact, function(value)
    getgenv().bulletTracerSettings.show_impact = value
end)

bulletTracerSection:CreateToggle("Silent Aim Priority", getgenv().bulletTracerSettings.silent_aim_priority, function(value)
    getgenv().bulletTracerSettings.silent_aim_priority = value
end)

-- Color Picker for Bullet Tracer
local success, err = pcall(function()
    bulletTracerSection:CreateColorPicker("Tracer Color", getgenv().bulletTracerSettings.tracer_color, function(color)
        getgenv().bulletTracerSettings.tracer_color = color
    end)
end)

-- Fallback RGB Sliders
if not success then
    bulletTracerSection:CreateSlider("Tracer R", 0, 255, 0, function(value)
        local g = getgenv().bulletTracerSettings.tracer_color.G * 255
        local b = getgenv().bulletTracerSettings.tracer_color.B * 255
        getgenv().bulletTracerSettings.tracer_color = Color3.fromRGB(value, g, b)
    end)
    
    bulletTracerSection:CreateSlider("Tracer G", 0, 255, 255, function(value)
        local r = getgenv().bulletTracerSettings.tracer_color.R * 255
        local b = getgenv().bulletTracerSettings.tracer_color.B * 255
        getgenv().bulletTracerSettings.tracer_color = Color3.fromRGB(r, value, b)
    end)
    
    bulletTracerSection:CreateSlider("Tracer B", 0, 255, 255, function(value)
        local r = getgenv().bulletTracerSettings.tracer_color.R * 255
        local g = getgenv().bulletTracerSettings.tracer_color.G * 255
        getgenv().bulletTracerSettings.tracer_color = Color3.fromRGB(r, g, value)
    end)
end

bulletTracerSection:CreateSlider("Tracer Duration", 0.5, 5, getgenv().bulletTracerSettings.duration, function(value)
    getgenv().bulletTracerSettings.duration = value
end)

bulletTracerSection:CreateSlider("Impact Duration", 2, 10, getgenv().bulletTracerSettings.impact_duration, function(value)
    getgenv().bulletTracerSettings.impact_duration = value
end)

bulletTracerSection:CreateSlider("Max Distance", 100, 2000, getgenv().bulletTracerSettings.max_distance, function(value)
    getgenv().bulletTracerSettings.max_distance = value
end)

bulletTracerSection:CreateSlider("Tracer Thickness", 0.1, 1, getgenv().bulletTracerSettings.thickness, function(value)
    getgenv().bulletTracerSettings.thickness = value
end)





-- ESP Main Section
local espSection = visualsTab:CreateSection("ESP Settings")

espSection:CreateToggle("Enable ESP", getgenv().espSettings.enabled, function(value)
    getgenv().espSettings.enabled = value
end)

espSection:CreateToggle("Boxes", getgenv().espSettings.boxes, function(value)
    getgenv().espSettings.boxes = value
end)

espSection:CreateToggle("Skeleton", getgenv().espSettings.skeleton, function(value)
    getgenv().espSettings.skeleton = value
end)

espSection:CreateToggle("Tracers", getgenv().espSettings.tracers, function(value)
    getgenv().espSettings.tracers = value
end)

espSection:CreateToggle("Names", getgenv().espSettings.names, function(value)
    getgenv().espSettings.names = value
end)

espSection:CreateToggle("Health", getgenv().espSettings.health, function(value)
    getgenv().espSettings.health = value
end)

espSection:CreateToggle("Distance", getgenv().espSettings.distance, function(value)
    getgenv().espSettings.distance = value
end)

espSection:CreateToggle("Weapon", getgenv().espSettings.weapon, function(value)
    getgenv().espSettings.weapon = value
end)

espSection:CreateToggle("Outline", getgenv().espSettings.outline, function(value)
    getgenv().espSettings.outline = value
end)

espSection:CreateToggle("Visibility Check", getgenv().espSettings.visibilityCheck, function(value)
    getgenv().espSettings.visibilityCheck = value
end)

-- ESP Advanced Section
local espAdvancedSection = visualsTab:CreateSection("ESP Advanced")

espAdvancedSection:CreateSlider("Box Thickness", 1, 5, getgenv().espSettings.boxThickness, function(value)
    getgenv().espSettings.boxThickness = value
end)

espAdvancedSection:CreateSlider("Skeleton Thickness", 1, 5, getgenv().espSettings.skeletonThickness, function(value)
    getgenv().espSettings.skeletonThickness = value
end)

espAdvancedSection:CreateSlider("Tracer Thickness", 1, 5, getgenv().espSettings.tracerThickness, function(value)
    getgenv().espSettings.tracerThickness = value
end)

espAdvancedSection:CreateSlider("Outline Thickness", 1, 3, getgenv().espSettings.outlineThickness, function(value)
    getgenv().espSettings.outlineThickness = value
end)

-- Try to create color pickers, fallback to sliders if not supported
local success, err = pcall(function()
    espAdvancedSection:CreateColorPicker("Visible Color", getgenv().espSettings.visibleColor, function(color)
        getgenv().espSettings.visibleColor = color
    end)
end)

if not success then
    print("ColorPicker not supported, using alternative method")
    -- Fallback: Create RGB sliders instead
    espAdvancedSection:CreateSlider("Visible R", 0, 255, 0, function(value)
        local g = getgenv().espSettings.visibleColor.G * 255
        local b = getgenv().espSettings.visibleColor.B * 255
        getgenv().espSettings.visibleColor = Color3.fromRGB(value, g, b)
    end)
    
    espAdvancedSection:CreateSlider("Visible G", 0, 255, 255, function(value)
        local r = getgenv().espSettings.visibleColor.R * 255
        local b = getgenv().espSettings.visibleColor.B * 255
        getgenv().espSettings.visibleColor = Color3.fromRGB(r, value, b)
    end)
    
    espAdvancedSection:CreateSlider("Visible B", 0, 255, 0, function(value)
        local r = getgenv().espSettings.visibleColor.R * 255
        local g = getgenv().espSettings.visibleColor.G * 255
        getgenv().espSettings.visibleColor = Color3.fromRGB(r, g, value)
    end)
else
    -- If first color picker works, add the rest
    pcall(function()
        espAdvancedSection:CreateColorPicker("Hidden Color", getgenv().espSettings.hiddenColor, function(color)
            getgenv().espSettings.hiddenColor = color
        end)
        
        espAdvancedSection:CreateColorPicker("Basic Color", getgenv().espSettings.basicColor, function(color)
            getgenv().espSettings.basicColor = color
        end)
        
        espAdvancedSection:CreateColorPicker("Name Color", getgenv().espSettings.nameColor, function(color)
            getgenv().espSettings.nameColor = color
        end)
        
        espAdvancedSection:CreateColorPicker("Distance Color", getgenv().espSettings.distanceColor, function(color)
            getgenv().espSettings.distanceColor = color
        end)
        
        espAdvancedSection:CreateColorPicker("Weapon Color", getgenv().espSettings.weaponColor, function(color)
            getgenv().espSettings.weaponColor = color
        end)
    end)
end

espAdvancedSection:CreateSlider("Name Size", 8, 24, getgenv().espSettings.nameSize, function(value)
    getgenv().espSettings.nameSize = value
end)

espAdvancedSection:CreateSlider("Distance Size", 8, 20, getgenv().espSettings.distanceSize, function(value)
    getgenv().espSettings.distanceSize = value
end)

espAdvancedSection:CreateSlider("Weapon Size", 8, 18, getgenv().espSettings.weaponSize, function(value)
    getgenv().espSettings.weaponSize = value
end)


-- MISCELLANEOUS TAB
local miscTab = gui:CreateTab("Miscellaneous")

-- Gun Mods Section
local gunModsSection = miscTab:CreateSection("Gun Mods")

gunModsSection:CreateToggle("No Recoil", getgenv().gunModSettings.no_recoil, function(value)
    getgenv().gunModSettings.no_recoil = value
end)

gunModsSection:CreateToggle("No Spread", getgenv().gunModSettings.no_spread, function(value)
    getgenv().gunModSettings.no_spread = value
end)
gunModsSection:CreateToggle("Instant Bullet", getgenv().gunModSettings.instant_bullet, function(value)
    getgenv().gunModSettings.instant_bullet = value
end)
gunModsSection:CreateToggle("Auto Firemode", getgenv().gunModSettings.auto_firemode, function(value)
    getgenv().gunModSettings.auto_firemode = value
end)

gunModsSection:CreateToggle("Bullet Penetration", getgenv().gunModSettings.bullet_penetration, function(value)
    getgenv().gunModSettings.bullet_penetration = value
end)
gunModsSection:CreateToggle("Bullet Penetration Bar", getgenv().gunModSettings.bullet_penetration_bar, function(value)
    getgenv().gunModSettings.bullet_penetration_bar = value
end)

gunModsSection:CreateToggle("No Muzzle Flash", getgenv().gunModSettings.no_muzzle_flash, function(value)
    getgenv().gunModSettings.no_muzzle_flash = value
end)

gunModsSection:CreateToggle("Infinite Stamina", getgenv().gunModSettings.infinite_stamina, function(value)
    getgenv().gunModSettings.infinite_stamina = value
end)

gunModsSection:CreateToggle("Infinite Adrenaline", getgenv().gunModSettings.infinite_adrenaline, function(value)
    getgenv().gunModSettings.infinite_adrenaline = value
end)

gunModsSection:CreateToggle("No Suppression Blur", getgenv().gunModSettings.no_suppression_blur, function(value)
    getgenv().gunModSettings.no_suppression_blur = value
end)
gunModsSection:CreateToggle("MultiBullet *DETECTED* ", getgenv().gunModSettings.multi_bullet, function(value)
    getgenv().gunModSettings.multi_bullet = value
end)
local charExploitsSection = miscTab:CreateSection("Character Exploits")

charExploitsSection:CreateToggle("Speed Hack", getgenv().charSettings.SpeedHack, function(value)
    getgenv().charSettings.SpeedHack = value
   
end)
charExploitsSection:CreateToggle("Third Person", getgenv().charSettings.TPerson, function(value)
    getgenv().charSettings.TPerson = value
end)
local success, err = pcall(function()
    utilitiesSection:CreateButton("Destroy ESP", function()
        espSystem:destroy()
        gui:Notify("ESP", "ESP System destroyed!", "info", 2)
    end)
end)

if success then
    pcall(function()
        utilitiesSection:CreateButton("Restart ESP", function()
            espSystem:destroy()
            task.wait(0.5)
            espSystem = ESPSystem.new()
            espSystem:initialize()
            gui:Notify("ESP", "ESP System restarted!", "success", 2)
        end)
        
        utilitiesSection:CreateButton("Teleport to Spawn", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
                gui:Notify("Teleport", "Teleported to spawn!", "success", 2)
            end
        end)
        
        utilitiesSection:CreateButton("Reset All Settings", function()
            -- Reset aimbot settings
            getgenv().aimbotSettings.fov_size = 200
            getgenv().aimbotSettings.aimbot_enabled = false
            getgenv().aimbotSettings.aim_part = "head"
            getgenv().aimbotSettings.smoothness = 15
            getgenv().aimbotSettings.prediction = 0.12
            getgenv().aimbotSettings.show_fov = true
            getgenv().aimbotSettings.visibility_check = true
            
            -- Reset ESP settings
            getgenv().espSettings.enabled = false
            getgenv().espSettings.boxes = true
            getgenv().espSettings.skeleton = true
            getgenv().espSettings.tracers = true
            getgenv().espSettings.names = true
            getgenv().espSettings.health = true
            getgenv().espSettings.distance = true
            getgenv().espSettings.weapon = true
            getgenv().espSettings.outline = true
            getgenv().espSettings.visibilityCheck = true
            
            gui:Notify("Settings", "All settings reset to default!", "info", 3)
        end)
    end)
end
return gui
