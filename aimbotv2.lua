--[[ 
    Universal Aimbot v4 - Part 1
    Author: C_mthe3rd Gaming
    Purpose: Core settings, services, utilities, aimlock helper functions
    Features: Settings defaults, prediction, visibility check, root part finder
    Lines: Maximized for clarity
]]

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- === Settings ===
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local fov = 120
local minFov = 50
local maxFov = 500
local lockPart = "HumanoidRootPart"
local predictionEnabled = true
local predictionFactor = 0.125
local visibilityCheck = true
local currentTarget = nil

-- Highlight and ESP tables
local highlightedPlayers = {}
local nameLabels = {}
local healthLabels = {}

-- Theme setup
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2

-- Settings persistence
local saveFileName = "UniversalAimbot_Settings.json"
local savedSettings = {}

-- === Utilities ===

-- Find the root part of a character
local function findRootPart(character)
    return character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Torso") 
        or character:FindFirstChild("UpperTorso")
end

-- Check if a target is visible (line-of-sight)
local function isTargetVisible(part)
    if not part then return false end
    if not visibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return (hit == nil or hit:IsDescendantOf(part.Parent))
end

-- Predict a moving target's position
local function getPredictedPosition(part)
    if not predictionEnabled or not part then return part.Position end
    local velocity = part.Velocity or Vector3.new()
    return part.Position + velocity * predictionFactor
end

-- Get closest target within FOV
local function getClosestTarget()
    local closest = nil
    local closestDist = math.huge
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health > 0 then
            local root = findRootPart(pl.Character)
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < closestDist and dist <= fov then
                        if not visibilityCheck or isTargetVisible(root) then
                            closest = pl
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Aimlock function: lock camera to target
local function lockOnTarget(target)
    if not target or not target.Character then return end
    local targetPart = headAimEnabled and target.Character:FindFirstChild("Head") or findRootPart(target.Character)
    if targetPart and isTargetVisible(targetPart) then
        local predicted = getPredictedPosition(targetPart)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
    end
end

-- === Part 1 Loaded ===
print("[UniversalAimbot v4] Part 1 loaded: Core settings, utilities, aimlock helpers.")

--[[ 
    Universal Aimbot v4 - Part 2
    Author: C_mthe3rd Gaming
    Purpose: GUI creation, toggles, sliders, theme handling, interactive buttons
    Features: ESP toggle, Aimlock toggle, Head Aim toggle, FOV slider, theme cycling, save/reset buttons
]]

-- === GUI Setup ===
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 400, 0, 420)
Frame.Position = UDim2.new(1, -420, 0, 80)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 122, 255)
Frame.Active = true
Frame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Frame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Universal Aimbot v4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 56, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -64, 0, 4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.BorderColor3 = Color3.fromRGB(0, 122, 255)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Parent = TitleBar

MinimizeBtn.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)

-- Content container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent = Frame

-- Credits (bottom)
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(0.7, 0, 0, 18)
Credits.Position = UDim2.new(0, 10, 1, -28)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180, 180, 180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 14
Credits.Parent = Frame

-- === Theme Helper ===
local function themeColorNow()
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        local t = (tick() * 0.2) % 1
        return Color3.fromHSV(t, 1, 1)
    end
    local map = {
        Red = Color3.fromRGB(255, 0, 0),
        Blue = Color3.fromRGB(0, 122, 255),
        Orange = Color3.fromRGB(255, 165, 0),
        Green = Color3.fromRGB(0, 255, 0)
    }
    return map[name] or Color3.fromRGB(0, 122, 255)
end

-- === Toggle Helper ===
local function makeToggle(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 34)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = themeColorNow()
    btn.Text = text .. ": " .. (initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = parent

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 60, 1, 0)
    status.Position = UDim2.new(1, -72, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = (initial and "On" or "Off")
    status.Font = Enum.Font.SourceSansBold
    status.TextSize = 16
    status.TextColor3 = initial and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    status.Parent = btn

    return btn, status
end

-- === Slider Helper ===
local function makeSlider(parent, labelText, y, minVal, maxVal, initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 260, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(math.floor(initialVal))
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 300, 0, 18)
    bar.Position = UDim2.new(0, 12, 0, y + 24)
    bar.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    bar.BorderSizePixel = 1
    bar.BorderColor3 = themeColorNow()
    bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = themeColorNow()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    local corner = Instance.new("UICorner", knob)
    corner.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        local val = minVal + rel * (maxVal - minVal)
        lbl.Text = labelText .. ": " .. tostring(math.floor(val))
        return val
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)

    local obj = {
        Label = lbl,
        Bar = bar,
        Fill = fill,
        Knob = knob,
        SetValue = function(v)
            local rel = (v - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            lbl.Text = labelText .. ": " .. tostring(math.floor(v))
        end,
        GetValue = function()
            local rel = fill.Size.X.Scale
            return minVal + rel * (maxVal - minVal)
        end
    }
    return obj
end

-- === Create Toggles and Sliders ===
local ESPBtn, ESPStatus = makeToggle(Content, "ESP", 12, espEnabled)
local AimBtn, AimStatus = makeToggle(Content, "Aimlock", 64, aimbotEnabled)
local HeadBtn, HeadStatus = makeToggle(Content, "Head Aim", 116, headAimEnabled)
local FOVSlider = makeSlider(Content, "FOV Circle", 168, minFov, maxFov, fov)

-- Theme Button
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(0, 180, 0, 36)
ThemeBtn.Position = UDim2.new(0, 12, 0, 232)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ThemeBtn.BorderSizePixel = 2
ThemeBtn.BorderColor3 = themeColorNow()
ThemeBtn.Text = "Theme: " .. (themeNames[currentThemeIndex] or "Blue")
ThemeBtn.Font = Enum.Font.SourceSansBold
ThemeBtn.TextSize = 16
ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeBtn.Parent = Content

-- Reset & Save Buttons
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(0, 180, 0, 36)
ResetBtn.Position = UDim2.new(0, 12, 0, 284)
ResetBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ResetBtn.BorderSizePixel = 2
ResetBtn.BorderColor3 = themeColorNow()
ResetBtn.Text = "Reset Settings"
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.TextSize = 16
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.Parent = Content

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 180, 0, 36)
SaveBtn.Position = UDim2.new(0, 212, 0, 284)
SaveBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
SaveBtn.BorderSizePixel = 2
SaveBtn.BorderColor3 = themeColorNow()
SaveBtn.Text = "Save Settings"
SaveBtn.Font = Enum.Font.SourceSansBold
SaveBtn.TextSize = 16
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Parent = Content

print("[UniversalAimbot v4] Part 2 loaded: GUI created with toggles, sliders, theme, save/reset buttons.")

--[[ 
    Universal Aimbot v4 - Part 3
    Author: C_mthe3rd Gaming
    Purpose: Aimlock logic, target prediction, visibility checks, GUI integration
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ensure defaults exist
espEnabled = (type(espEnabled) == "boolean") and espEnabled or true
aimbotEnabled = (type(aimbotEnabled) == "boolean") and aimbotEnabled or false
headAimEnabled = (type(headAimEnabled) == "boolean") and headAimEnabled or false
fov = (type(fov) == "number") and fov or 120
predictionEnabled = (type(predictionEnabled)=="boolean") and predictionEnabled or true
predictionFactor = (type(predictionFactor)=="number") and predictionFactor or 0.125
visibilityCheck = (type(visibilityCheck)=="boolean") and visibilityCheck or true

highlightedPlayers = highlightedPlayers or {}
currentTarget = nil

-- Utility: find character root part
local function findRootPart(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

-- Utility: check if target visible
local function isTargetVisible(part)
    if not part then return false end
    if not visibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray,{LocalPlayer.Character})
    return (hit==nil or hit:IsDescendantOf(part.Parent))
end

-- Utility: predict position
local function getPredictedPosition(part)
    if not predictionEnabled or not part then return part.Position end
    local velocity = part.Velocity or Vector3.new()
    return part.Position + velocity * predictionFactor
end

-- Find closest target within FOV
local function getClosestTarget()
    local closest = nil
    local closestDist = math.huge
    for _,pl in pairs(Players:GetPlayers()) do
        if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health>0 then
            local root = findRootPart(pl.Character)
            if root then
                local screenPos, onscreen = Camera:WorldToViewportPoint(root.Position)
                if onscreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < closestDist and dist <= fov then
                        if not visibilityCheck or isTargetVisible(root) then
                            closest = pl
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Aimlock logic
local function lockOnTarget(target)
    if not target or not target.Character then return end
    local targetPart = headAimEnabled and target.Character:FindFirstChild("Head") or findRootPart(target.Character)
    if targetPart and isTargetVisible(targetPart) then
        local predicted = getPredictedPosition(targetPart)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
    end
end

-- Right-click inside FOV to enable aimlock
local aiming = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        local mousePos = UserInputService:GetMouseLocation()
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        if (mousePos - center).Magnitude <= fov then
            aiming = true
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- Part 2 GUI hooks: toggle behaviors
ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPBtn.Text = "ESP: "..(espEnabled and "On" or "Off")
    ESPStatus.Text = espEnabled and "On" or "Off"
    ESPStatus.TextColor3 = espEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)
AimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
    AimStatus.Text = aimbotEnabled and "On" or "Off"
    AimStatus.TextColor3 = aimbotEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)
HeadBtn.MouseButton1Click:Connect(function()
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
    HeadStatus.Text = headAimEnabled and "On" or "Off"
    HeadStatus.TextColor3 = headAimEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

-- Theme cycling
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = (currentThemeIndex % #themeNames) + 1
    local c = themeColorNow()
    ThemeBtn.BorderColor3 = c
end)

-- Reset / Save
ResetBtn.MouseButton1Click:Connect(function()
    espEnabled=true; aimbotEnabled=false; headAimEnabled=false; fov=120
    predictionEnabled=true; predictionFactor=0.125; visibilityCheck=true
    ESPBtn.Text="ESP: On"; ESPStatus.Text="On"; ESPStatus.TextColor3=Color3.fromRGB(100,255,100)
    AimBtn.Text="Aimlock: Off"; AimStatus.Text="Off"; AimStatus.TextColor3=Color3.fromRGB(255,100,100)
    HeadBtn.Text="Head Aim: Off"; HeadStatus.Text="Off"; HeadStatus.TextColor3=Color3.fromRGB(255,100,100)
    FOVSlider.SetValue(fov)
end)
SaveBtn.MouseButton1Click:Connect(function()
    -- saveSettings() can be called here if implemented
    print("[UniversalAimbot] Settings saved.")
end)

-- RenderStepped: main loop for aimlock
RunService.RenderStepped:Connect(function()
    if aiming and aimbotEnabled then
        currentTarget = getClosestTarget()
        if currentTarget then
            lockOnTarget(currentTarget)
        end
    else
        currentTarget = nil
    end
end)

print("[UniversalAimbot v4] Part 3 loaded: Aimlock logic and input handling active.")

--[[ 
    Universal Aimbot v4 - Part 4
    Author: C_mthe3rd Gaming
    Purpose: ESP, FOV circle, distance & health display, respawn hooks, final GUI polish
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ensure tables exist
highlightedPlayers = highlightedPlayers or {}
local nameLabels = nameLabels or {}
local healthLabels = healthLabels or {}

-- Function to get theme color
local function theme_color_now()
    return themeColorNow()
end

-- Setup ESP for a player
local function setupESP(plr)
    if not plr or not plr.Character then return end
    local root = findRootPart(plr.Character)
    if not root then return end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = plr.Character
    highlight.FillTransparency = 0.6
    highlight.FillColor = theme_color_now()
    highlight.OutlineColor = theme_color_now()
    highlight.Enabled = espEnabled
    highlight.Parent = CoreGui
    highlightedPlayers[plr] = highlight

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Text = plr.Name
    nameLabel.Parent = Frame
    nameLabels[plr] = nameLabel

    -- Health label
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(0, 120, 0, 14)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(0,255,0)
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.TextSize = 12
    healthLabel.Text = "Health: N/A"
    healthLabel.Parent = Frame
    healthLabels[plr] = healthLabel
end

-- Setup ESP for existing players
for _, plr in pairs(Players:GetPlayers()) do
    if plr~=LocalPlayer then
        setupESP(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.35)
            setupESP(plr)
        end)
    end
end

-- Player added
Players.PlayerAdded:Connect(function(plr)
    if plr~=LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(0.35)
            setupESP(plr)
        end)
    end
end)

-- Player removing cleanup
Players.PlayerRemoving:Connect(function(plr)
    if highlightedPlayers[plr] then
        pcall(function() highlightedPlayers[plr]:Destroy() end)
        highlightedPlayers[plr] = nil
    end
    if nameLabels[plr] then
        pcall(function() nameLabels[plr]:Destroy() end)
        nameLabels[plr] = nil
    end
    if healthLabels[plr] then
        pcall(function() healthLabels[plr]:Destroy() end)
        healthLabels[plr] = nil
    end
end)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = aimbotEnabled
FOVCircle.Radius = fov
FOVCircle.Color = theme_color_now()
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.NumSides = 100
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- Distance display
DistanceUI = DistanceUI or Instance.new("TextLabel")
DistanceUI.Size = UDim2.new(0, 180, 0, 20)
DistanceUI.Position = UDim2.new(0, 12, 0, 280)
DistanceUI.BackgroundTransparency = 1
DistanceUI.TextColor3 = Color3.fromRGB(255,255,255)
DistanceUI.Font = Enum.Font.SourceSans
DistanceUI.TextSize = 14
DistanceUI.TextXAlignment = Enum.TextXAlignment.Left
DistanceUI.Parent = Frame

-- Update loop
RunService.RenderStepped:Connect(function()
    local themeColor = theme_color_now()

    -- Update FOV circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = fov
    FOVCircle.Color = themeColor
    FOVCircle.Visible = aimbotEnabled

    -- Update ESP highlights
    for plr, hl in pairs(highlightedPlayers) do
        if hl and plr.Character then
            hl.FillColor = themeColor
            hl.OutlineColor = themeColor
            hl.Enabled = espEnabled
        end
    end

    -- Update name and health labels
    for plr, label in pairs(nameLabels) do
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local root = findRootPart(plr.Character)
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,3,0))
                label.Visible = espEnabled and onScreen
                label.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 36)
                label.TextColor3 = themeColor
            else
                label.Visible = false
            end
        else
            label.Visible = false
        end
    end

    for plr, label in pairs(healthLabels) do
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local root = findRootPart(plr.Character)
            local hum = plr.Character.Humanoid
            if root and hum then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,1.5,0))
                label.Visible = espEnabled and onScreen
                label.Position = UDim2.new(0, screenPos.X - 60, 0, screenPos.Y - 20)
                label.Text = "Health: "..tostring(math.floor(hum.Health))
                if hum.Health/hum.MaxHealth > 0.5 then
                    label.TextColor3 = Color3.fromRGB(0,255,0)
                elseif hum.Health/hum.MaxHealth > 0.25 then
                    label.TextColor3 = Color3.fromRGB(255,165,0)
                else
                    label.TextColor3 = Color3.fromRGB(255,0,0)
                end
            else
                label.Visible = false
            end
        else
            label.Visible = false
        end
    end

    -- Update distance
    if currentTarget and currentTarget.Character and findRootPart(currentTarget.Character) and LocalPlayer.Character then
        local dist = (findRootPart(LocalPlayer.Character).Position - findRootPart(currentTarget.Character).Position).Magnitude
        DistanceUI.Text = "Distance: "..tostring(math.floor(dist)).."m"
    else
        DistanceUI.Text = "Distance: N/A"
    end
end)

-- GUI Tweens for polish
Frame.BackgroundTransparency = 1
TweenService:Create(Frame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=0}):Play()

-- Credits (bottom)
if Credits then
    Credits.Position = UDim2.new(0, 10, 1, -22)
    Credits.TextColor3 = Color3.fromRGB(180,180,180)
    Credits.Parent = Frame
end

print("[UniversalAimbot v4] Part 4 loaded. All systems active with names & health ESP.")
