--[[ 
Universal Aimbot v5 – Part 1: GUI, Toggles & Theme (Fixed)
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

-- Settings
local aimbotEnabled, headAimEnabled, espEnabled = false, false, true
local fov = 120
local minFov, maxFov = 50, 500
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

-- Main GUI
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

-- Toggle button helper
local function makeToggle(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,200,0,40)
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = text..": "..(initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

-- Theme button helper
local function makeThemeButton(parent, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,200,0,40)
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = "Theme: "..themeNames[currentThemeIndex]
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

-- FOV slider
local function makeSlider(parent,labelText,y,minVal,maxVal,initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,260,0,20)
    lbl.Position = UDim2.new(0,12,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText..": "..tostring(math.floor(initialVal))
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,300,0,18)
    bar.Position = UDim2.new(0,12,0,y+24)
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
local AimBtn = makeToggle(Content,"Aimlock",70,false)
local HeadBtn = makeToggle(Content,"Head Aim",128,false)
local ThemeBtn = makeThemeButton(Content,186)
local FOVSlider = makeSlider(Content,"FOV",244,50,500,fov)

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
    Credits.Visible = not minimized
    if minimized then
        Frame.Size = UDim2.new(0,400,0,36)
    else
        Frame.Size = UDim2.new(0,400,0,480)
    end
end)

-- Dynamic outline update (including rainbow)
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
Universal Aimbot v5 – Part 2: ESP, Healthbar & Aimlock (Dynamic + Rainbow)
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

-- Setup ESP for a player
local function setupESP(plr)
    if not plr or not plr.Character then return end

    -- Cleanup old ESP
    if highlightedPlayers[plr] then highlightedPlayers[plr]:Destroy() highlightedPlayers[plr]=nil end
    if nameLabels[plr] then nameLabels[plr]:Destroy() nameLabels[plr]=nil end
    if healthLabels[plr] then healthLabels[plr]:Destroy() healthLabels[plr]=nil end
    if healthBars[plr] then healthBars[plr].BG:Destroy() healthBars[plr]=nil end
    if distanceLabels[plr] then distanceLabels[plr]:Destroy() distanceLabels[plr]=nil end

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

    -- Health label
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

    -- Vertical health bar
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

-- Setup ESP for existing players
for _,plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        setupESP(plr)
        plr.CharacterAdded:Connect(function() task.wait(0.35) setupESP(plr) end)
    end
end

-- Player join
Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function() task.wait(0.35) setupESP(plr) end)
    end
end)

-- Player leave
Players.PlayerRemoving:Connect(function(plr)
    if highlightedPlayers[plr] then highlightedPlayers[plr]:Destroy() highlightedPlayers[plr]=nil end
    if nameLabels[plr] then nameLabels[plr]:Destroy() nameLabels[plr]=nil end
    if healthLabels[plr] then healthLabels[plr]:Destroy() healthLabels[plr]=nil end
    if healthBars[plr] then healthBars[plr].BG:Destroy() healthBars[plr]=nil end
    if distanceLabels[plr] then distanceLabels[plr]:Destroy() distanceLabels[plr]=nil end
end)

-- RenderStepped loop
RunService.RenderStepped:Connect(function()
    -- Rainbow theme cycling
    local color = themeColorNow()
    if themeNames[currentThemeIndex] == "Rainbow" then
        color = Color3.fromHSV((tick()*0.15)%1,1,1)
    end

    -- Update GUI outlines
    Frame.BorderColor3 = color
    MinimizeBtn.BorderColor3 = color
    ESPBtn.BorderColor3 = color
    AimBtn.BorderColor3 = color
    HeadBtn.BorderColor3 = color
    ThemeBtn.BorderColor3 = color
    FOVSlider.Bar.BorderColor3 = color
    FOVSlider.Fill.BackgroundColor3 = color

    -- FOV Circle
    fovCircle.Color = color
    fovCircle.Radius = FOVSlider:GetValue()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fovCircle.Visible = aimbotEnabled

    -- Update ESP highlights
    for plr,hl in pairs(highlightedPlayers) do
        hl.FillColor = color
        hl.OutlineColor = color
        hl.Enabled = espEnabled
    end

    -- Update ESP labels and healthbars
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
            local root = findRootPart(plr.Character)
            local hum = plr.Character:FindFirstChild("Humanoid")
            local health = hum and hum.Health or 0
            local maxHealth = hum and hum.MaxHealth or 100
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            local scale = math.clamp(1 - dist/300, 0.5, 1)

            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,3,0))

            -- Name
            if nameLabels[plr] then
                nameLabels[plr].Position = UDim2.new(0,screenPos.X-60,0,screenPos.Y-50)
                nameLabels[plr].TextScaled = true
                nameLabels[plr].Visible = espEnabled
            end

            -- Health text (left)
            if healthLabels[plr] then
                healthLabels[plr].Text = "HP: "..math.floor(health)
                healthLabels[plr].Position = UDim2.new(0,screenPos.X-70,0,screenPos.Y-8)
                healthLabels[plr].TextColor3 = Color3.fromRGB(0,255,0)
                healthLabels[plr].TextScaled = true
                healthLabels[plr].Visible = espEnabled
            end

            -- Distance
            if distanceLabels[plr] then
                distanceLabels[plr].Text = "Dist: "..math.floor(dist).." studs"
                distanceLabels[plr].Position = UDim2.new(0,screenPos.X+10,0,screenPos.Y-8)
                distanceLabels[plr].TextColor3 = Color3.fromRGB(160,160,160)
                distanceLabels[plr].TextScaled = true
                distanceLabels[plr].Visible = espEnabled
            end

            -- Health bar vertical
            if healthBars[plr] then
                healthBars[plr].BG.Position = UDim2.new(0,screenPos.X-8,0,screenPos.Y-30)
                healthBars[plr].BG.Size = UDim2.new(0,8,0,60*scale)
                healthBars[plr].BG.Visible = espEnabled
                healthBars[plr].Fill.Size = UDim2.new(1,0,math.clamp(health/maxHealth,0,1),0)
                healthBars[plr].Fill.BackgroundColor3 = color
            end
        end
    end

    -- Aimlock (only if right-click inside FOV)
    if aimbotEnabled and aiming then
        currentTarget = nil
        local mousePos = UserInputService:GetMouseLocation()
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
                local root = findRootPart(plr.Character)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist <= FOVSlider:GetValue() then
                    if not currentTarget or dist < (Vector2.new(Camera:WorldToViewportPoint(findRootPart(currentTarget.Character).Position).X, 
                    Vector2.new(Camera:WorldToViewportPoint(findRootPart(currentTarget.Character).Position).Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude) then
                        currentTarget = plr
                    end
                end
            end
        end
        if currentTarget then
            local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
            if part then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position + part.Velocity*0.1), 0.25)
            end
        end
    end
end)

-- Right-click aim
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end
end)
