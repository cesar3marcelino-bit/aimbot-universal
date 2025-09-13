--[[ 
Universal Aimbot v5 – Part 1: GUI, Toggles & Theme
Author: C_mthe3rd Gaming
]] 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Clean old GUI
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

-- === Settings ===
local aimbotEnabled, headAimEnabled, espEnabled = false, false, true
local fov = 120
local minFov, maxFov = 50, 500
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2

-- === Theme helper ===
local function themeColorNow()
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        return Color3.fromHSV((tick()*0.15)%1,1,1)
    end
    local map = {
        Red = Color3.fromRGB(255,0,0),
        Blue = Color3.fromRGB(0,122,255),
        Orange = Color3.fromRGB(255,165,0),
        Green = Color3.fromRGB(0,255,0)
    }
    return map[name] or Color3.fromRGB(0,122,255)
end

-- === Main GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0,400,0,480)
Frame.Position = UDim2.new(1,-420,0,80)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = themeColorNow()
Frame.Active = true
Frame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1,-80,1,0)
TitleLabel.Position = UDim2.new(0,12,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "UniversalAimbot v5"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0,56,0,28)
MinimizeBtn.Position = UDim2.new(1,-64,0,4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
MinimizeBtn.BorderSizePixel = 2
MinimizeBtn.BorderColor3 = themeColorNow()
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.Parent = TitleBar

-- Content frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-36)
Content.Position = UDim2.new(0,0,0,36)
Content.BackgroundTransparency = 1
Content.Parent = Frame

-- Credits
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(0.7,0,0,18)
Credits.Position = UDim2.new(0,10,1,-28)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180,180,180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 14
Credits.Parent = Frame

-- Drag functionality
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === Helper: Toggle Button (Maximized) ===
local function makeToggle(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-24,0,50)  -- full width minus margin
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = text..": "..(initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

-- === Theme Button (Maximized) ===
local function makeThemeButton(parent, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-24,0,50)
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = "Theme: "..themeNames[currentThemeIndex]
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

-- === FOV Slider (Maximized) ===
local function makeSlider(parent,labelText,y,minVal,maxVal,initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-24,0,24)
    lbl.Position = UDim2.new(0,12,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText..": "..tostring(math.floor(initialVal))
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-24,0,20)
    bar.Position = UDim2.new(0,12,0,y+28)
    bar.BackgroundColor3 = Color3.fromRGB(42,42,42)
    bar.BorderSizePixel = 2
    bar.BorderColor3 = themeColorNow()
    bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = themeColorNow()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local dragging=false
    local function update(x)
        local rel = math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,0.5,0)
        local val = minVal + rel*(maxVal-minVal)
        lbl.Text = labelText..": "..tostring(math.floor(val))
        return val
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true update(input.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)
    return {
        Bar=bar,
        Fill=fill,
        Knob=knob,
        GetValue=function() return minVal + fill.Size.X.Scale*(maxVal-minVal) end
    }
end

-- Create buttons and slider
local ESPBtn = makeToggle(Content,"ESP",12,true)
local AimBtn = makeToggle(Content,"Aimlock",72,false)
local HeadBtn = makeToggle(Content,"Head Aim",132,false)
local ThemeBtn = makeThemeButton(Content,192)
local FOVSlider = makeSlider(Content,"FOV",252,50,500,fov)

-- Create Noclip toggle (below FOV slider)
local NoclipBtn = makeToggle(Content, "Noclip", 332, false)  -- 332 so it sits nicely below FOV

-- Noclip state
local noclipEnabled = false
local originalCollides = {} -- store original CanCollide states

-- Button functionality
NoclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    NoclipBtn.Text = "Noclip: "..(noclipEnabled and "On" or "Off")

    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipEnabled then
                    originalCollides[part] = part.CanCollide
                    part.CanCollide = false
                else
                    -- restore original CanCollide
                    if originalCollides[part] ~= nil then
                        part.CanCollide = originalCollides[part]
                    else
                        part.CanCollide = true
                    end
                end
            end
        end
    end
end)

-- Keep noclip on for new parts if enabled
RunService.RenderStepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Button functionality
ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPBtn.Text = "ESP: "..(espEnabled and "On" or "Off")
end)
AimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
end)
HeadBtn.MouseButton1Click:Connect(function()
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
end)
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex + 1
    if currentThemeIndex > #themeNames then currentThemeIndex = 1 end
    ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
end)

-- Minimize toggle
local minimized=false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    if minimized then
        Frame.Size = UDim2.new(0,400,0,36)
        Credits.Position = UDim2.new(0,10,0,36)
    else
        Frame.Size = UDim2.new(0,400,0,480)
        Credits.Position = UDim2.new(0,10,1,-28)
    end
end)

-- Update rainbow theme dynamically
RunService.RenderStepped:Connect(function()
    local color = themeColorNow()
    Frame.BorderColor3 = color
    MinimizeBtn.BorderColor3 = color
    ESPBtn.BorderColor3 = color
    AimBtn.BorderColor3 = color
    HeadBtn.BorderColor3 = color
    ThemeBtn.BorderColor3 = color
    FOVSlider.Bar.BorderColor3 = color
    FOVSlider.Fill.BackgroundColor3 = color
end)

--[[ 
Universal Aimbot v5 – Part 2: ESP, Healthbar & Aimlock
Author: C_mthe3rd Gaming
]] 

local highlightedPlayers, nameLabels, healthLabels, healthBars, distanceLabels = {}, {}, {}, {}, {}
local aiming, currentTarget = false, nil

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOVSlider:GetValue()
fovCircle.Color = themeColorNow()
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Visible = true
fovCircle.NumSides = 100
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- Helper: find root part
local function findRootPart(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

-- Helper: simple prediction
local function getPredictedPosition(part)
    if not part then return Vector3.new() end
    local vel = part.Velocity or Vector3.new()
    return part.Position + vel * 0.1
end

-- Lock-on target
local function lockOnTarget(target)
    if not target or not target.Character then return end
    local part = headAimEnabled and target.Character:FindFirstChild("Head") or findRootPart(target.Character)
    if part then
        local predicted = getPredictedPosition(part)
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local mousePos = UserInputService:GetMouseLocation()
        if (Vector2.new(mousePos.X, mousePos.Y) - center).Magnitude <= FOVSlider:GetValue() then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predicted), 0.25)
        end
    end
end

-- Get closest target within FOV
local function getClosestTarget()
    local closest, closestDist = nil, FOVSlider:GetValue()
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
            local root = findRootPart(plr.Character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist <= closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- Setup ESP for a player (no lingering duplicates)
local function setupESP(plr)
    if not plr or not plr.Character then return end

    -- Destroy old objects
    for _, obj in pairs({highlightedPlayers[plr], nameLabels[plr], healthLabels[plr], distanceLabels[plr], healthBars[plr] and healthBars[plr].BG}) do
        if obj and obj.Parent then obj:Destroy() end
    end
    highlightedPlayers[plr], nameLabels[plr], healthLabels[plr], healthBars[plr], distanceLabels[plr] = nil, nil, nil, nil, nil

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Adornee = plr.Character
    hl.FillTransparency = 0.6
    hl.FillColor = themeColorNow()
    hl.OutlineColor = themeColorNow()
    hl.Enabled = espEnabled
    hl.Parent = CoreGui
    highlightedPlayers[plr] = hl

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0,120,0,22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 16
    nameLabel.Text = plr.Name
    nameLabel.Parent = ScreenGui
    nameLabels[plr] = nameLabel

    -- Health label (left of bar)
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(0,50,0,16)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(0,255,0)
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextSize = 14
    healthLabel.Text = "HP: N/A"
    healthLabel.Parent = ScreenGui
    healthLabels[plr] = healthLabel

    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(0,120,0,14)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(160,160,160)
    distLabel.Font = Enum.Font.SourceSans
    distLabel.TextSize = 14
    distLabel.Text = "Dist: N/A"
    distLabel.Parent = ScreenGui
    distanceLabels[plr] = distLabel

    -- Health bar vertical
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(0,8,0,60)
    barBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    barBG.BorderSizePixel = 0
    barBG.Parent = ScreenGui

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(1,0,1,0)
    barFill.BackgroundColor3 = themeColorNow()
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG

    healthBars[plr] = {BG=barBG, Fill=barFill}
end

-- Handle character added (respawn)
local function onCharacterAdded(plr, char)
    task.wait(0.3)
    setupESP(plr)
end

-- Initial setup for existing players
for _,plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        if plr.Character then setupESP(plr) end
        plr.CharacterAdded:Connect(function(char) onCharacterAdded(plr,char) end)
    end
end

-- Setup for new players
Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function(char) onCharacterAdded(plr,char) end)
        if plr.Character then setupESP(plr) end
    end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(plr)
    for _, obj in pairs({highlightedPlayers[plr], nameLabels[plr], healthLabels[plr], distanceLabels[plr], healthBars[plr] and healthBars[plr].BG}) do
        if obj and obj.Parent then obj:Destroy() end
    end
    highlightedPlayers[plr], nameLabels[plr], healthLabels[plr], healthBars[plr], distanceLabels[plr] = nil, nil, nil, nil, nil
end)

-- Update loop
RunService.RenderStepped:Connect(function()
    local color = themeColorNow()

    -- FOV circle
    fovCircle.Color = color
    fovCircle.Radius = FOVSlider:GetValue()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = aimbotEnabled

    -- Update highlights
    for plr, hl in pairs(highlightedPlayers) do
        if hl then
            hl.FillColor = color
            hl.OutlineColor = color
            hl.Enabled = espEnabled
        end
    end

    -- Update ESP text & healthbars
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = findRootPart(plr.Character)
            local hum = plr.Character:FindFirstChild("Humanoid")
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,3,0))
                local health = hum and hum.Health or 0
                local maxHealth = hum and hum.MaxHealth or 100
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local scale = math.clamp(1 - dist/300, 0.5, 1)

                -- Name
                if nameLabels[plr] then
                    nameLabels[plr].Position = UDim2.new(0,screenPos.X-60,0,screenPos.Y-50)
                    nameLabels[plr].TextScaled = true
                    nameLabels[plr].Visible = espEnabled
                end

                -- Health text
                if healthLabels[plr] then
                    healthLabels[plr].Text = "HP: "..math.floor(health)
                    healthLabels[plr].Position = UDim2.new(0,screenPos.X-70,0,screenPos.Y-8)
                    healthLabels[plr].Visible = espEnabled
                end

                -- Distance text
                if distanceLabels[plr] then
                    distanceLabels[plr].Text = "Dist: "..math.floor(dist).." studs"
                    distanceLabels[plr].Position = UDim2.new(0,screenPos.X+10,0,screenPos.Y-8)
                    distanceLabels[plr].Visible = espEnabled
                end

                -- Health bar
                if healthBars[plr] then
                    healthBars[plr].BG.Position = UDim2.new(0,screenPos.X-8,0,screenPos.Y-30)
                    healthBars[plr].BG.Size = UDim2.new(0,8,0,60*scale)
                    healthBars[plr].BG.Visible = espEnabled
                    healthBars[plr].Fill.Size = UDim2.new(1,0,math.clamp(health/maxHealth,0,1),0)
                    healthBars[plr].Fill.BackgroundColor3 = color
                end
            end
        end
    end

    -- Aimlock
    if aimbotEnabled and aiming then
        currentTarget = getClosestTarget()
        if currentTarget then lockOnTarget(currentTarget) end
    end
end)

-- Right-click aim
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end
end)
