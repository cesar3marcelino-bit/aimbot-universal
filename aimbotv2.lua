--[[ 
Universal Aimbot v5 – Part 1: GUI Setup
Author: C_mthe3rd Gaming
Features: GUI, Toggles, Theme, Sliders, ESP placeholders
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Clean old GUI
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

-- === Settings ===
local aimbotEnabled, headAimEnabled, espEnabled = false, false, true
local noclipEnabled, fullbrightEnabled = false, false
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2

-- Theme helper
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

-- GUI creation
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

-- Credits and Distance
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(0.7,0,0,18)
Credits.Position = UDim2.new(0,10,1,-28)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180,180,180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 14
Credits.Parent = Content

local DistanceLabel = Instance.new("TextLabel")
DistanceLabel.Size = UDim2.new(0.7,0,0,18)
DistanceLabel.Position = UDim2.new(0,10,1,-48)
DistanceLabel.BackgroundTransparency = 1
DistanceLabel.Text = "Distance: N/A"
DistanceLabel.TextColor3 = Color3.fromRGB(255,255,255)
DistanceLabel.Font = Enum.Font.SourceSansBold
DistanceLabel.TextSize = 14
DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
DistanceLabel.Parent = Content

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

-- Helper functions for toggle and slider
local function makeToggle(parent,text,y,initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-24,0,50)
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

local function makeThemeButton(parent,y)
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

-- Buttons and slider
local ESPBtn = makeToggle(Content,"ESP",12,true)
local AimBtn = makeToggle(Content,"Aimlock",72,false)
local HeadBtn = makeToggle(Content,"Head Aim",132,false)
local ThemeBtn = makeThemeButton(Content,192)
local FOVSlider = makeSlider(Content,"FOV Circle Size",252,50,500,120)
local NoclipBtn = makeToggle(Content, "Noclip", 332, false)

--[[ 
Universal Aimbot v5 – Part 2: Functionality & Loops
Author: C_mthe3rd Gaming
Features: Aimlock, ESP, Distance, Noclip, Fullbright, FOV Circle
]]

-- Fullbright button
local FullbrightBtn = Instance.new("TextButton")
FullbrightBtn.Size = UDim2.new(0,40,0,40)
FullbrightBtn.Position = UDim2.new(1,-52,1,-52)
FullbrightBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
FullbrightBtn.BorderSizePixel = 2
FullbrightBtn.BorderColor3 = themeColorNow()
FullbrightBtn.Text = "☀"
FullbrightBtn.TextColor3 = Color3.fromRGB(255,255,255)
FullbrightBtn.Font = Enum.Font.SourceSansBold
FullbrightBtn.TextSize = 20
FullbrightBtn.Parent = Frame

FullbrightBtn.MouseButton1Click:Connect(function()
    fullbrightEnabled = not fullbrightEnabled
    FullbrightBtn.TextTransparency = fullbrightEnabled and 0.5 or 0
end)

-- Noclip toggle
NoclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    NoclipBtn.Text = "Noclip: "..(noclipEnabled and "On" or "Off")
end)

-- Theme toggle
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex +1
    if currentThemeIndex > #themeNames then currentThemeIndex =1 end
    ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
end)

-- Other button toggles
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

-- Minimize toggle
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Credits.Visible = not minimized
    DistanceLabel.Visible = not minimized
    FullbrightBtn.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0,400,0,36) or UDim2.new(0,400,0,480)
end)

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOVSlider:GetValue()
fovCircle.Color = themeColorNow()
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Visible = aimbotEnabled
fovCircle.NumSides = 100
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ESP highlight logic
local highlightedPlayers = {}
local aiming = false
local function findRootPart(character) return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") end
local function findHeadPart(character) return character:FindFirstChild("Head") or findRootPart(character) end

local function setupESP(plr)
    if plr == LocalPlayer then return end
    removeESP(plr)
    if plr.Character then
        local hl = Instance.new("Highlight")
        hl.Adornee = plr.Character
        hl.FillTransparency = 0.6
        hl.FillColor = themeColorNow()
        hl.OutlineColor = themeColorNow()
        hl.Enabled = espEnabled
        hl.Parent = CoreGui
        highlightedPlayers[plr] = hl
    end
end

function removeESP(plr)
    if highlightedPlayers[plr] then
        if highlightedPlayers[plr].Parent then highlightedPlayers[plr]:Destroy() end
        highlightedPlayers[plr] = nil
    end
end

-- Player hooks for faster ESP updates
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        setupESP(plr)
    end)
    plr.CharacterRemoving:Connect(function()
        removeESP(plr)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

-- Initial setup for current players
for _, plr in pairs(Players:GetPlayers()) do
    if plr.Character then setupESP(plr) end
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        setupESP(plr)
    end)
    plr.CharacterRemoving:Connect(function()
        removeESP(plr)
    end)
end

-- Main update loop
RunService.RenderStepped:Connect(function()
    local color = themeColorNow()

    -- GUI colors
    Frame.BorderColor3 = color
    MinimizeBtn.BorderColor3 = color
    ESPBtn.BorderColor3 = color
    AimBtn.BorderColor3 = color
    HeadBtn.BorderColor3 = color
    ThemeBtn.BorderColor3 = color
    FOVSlider.Bar.BorderColor3 = color
    FOVSlider.Fill.BackgroundColor3 = color
    NoclipBtn.BorderColor3 = color
    FullbrightBtn.BorderColor3 = color
    FullbrightBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)

    -- FOV Circle
    fovCircle.Radius = FOVSlider:GetValue()
    fovCircle.Color = color
    fovCircle.Visible = aimbotEnabled
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    -- Update ESP highlights
    for plr, hl in pairs(highlightedPlayers) do
        if hl then
            hl.FillColor = color
            hl.OutlineColor = color
            hl.Enabled = espEnabled
        end
    end
    if highlightedPlayers[LocalPlayer] then highlightedPlayers[LocalPlayer].Enabled = false end

    -- Distance meter
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
            local root = findRootPart(plr.Character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    if closest and closestDist <= FOVSlider:GetValue() then
        local root = findRootPart(closest.Character)
        local distanceStuds = (Camera.CFrame.Position - root.Position).Magnitude
        DistanceLabel.Text = string.format("Distance: %s (%.2f)", closest.Name, distanceStuds)
    else
        DistanceLabel.Text = "Distance: N/A"
    end

    -- Aimlock logic
    if aimbotEnabled and aiming then
        local target, targetDist = nil, FOVSlider:GetValue()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
                local root = findRootPart(plr.Character)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist <= targetDist then
                        targetDist = dist
                        target = plr
                    end
                end
            end
        end
        if target and target.Character then
            local part = headAimEnabled and findHeadPart(target.Character) or findRootPart(target.Character)
            if part then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position + (part.Velocity or Vector3.new())*0.1), 0.25)
            end
        end
    end

    -- Fullbright
    if fullbrightEnabled then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
    end

    -- Instant Noclip
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Aim toggle with right-click inside FOV
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mousePos = UserInputService:GetMouseLocation()
        if (mousePos - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude <= FOVSlider:GetValue() then
            aiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)
