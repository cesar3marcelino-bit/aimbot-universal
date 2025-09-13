--[[
    Universal Aimbot v4 - Complete
    Author: C_mthe3rd Gaming
    Purpose: Fully integrated aimlock, ESP, GUI, FOV circle, distance & health display
    Features: Settings, prediction, visibility check, root part finder, GUI toggles/sliders, theme cycling
]]

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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

-- === Utilities ===
local function findRootPart(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function isTargetVisible(part)
    if not part then return false end
    if not visibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return (hit == nil or hit:IsDescendantOf(part.Parent))
end

local function getPredictedPosition(part)
    if not predictionEnabled or not part then return part.Position end
    local velocity = part.Velocity or Vector3.new()
    return part.Position + velocity * predictionFactor
end

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

local function lockOnTarget(target)
    if not target or not target.Character then return end
    local targetPart = headAimEnabled and target.Character:FindFirstChild("Head") or findRootPart(target.Character)
    if targetPart and isTargetVisible(targetPart) then
        local predicted = getPredictedPosition(targetPart)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
    end
end

-- === GUI Setup ===
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 400, 0, 420)
Frame.Position = UDim2.new(1, -420, 0, 80)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 122, 255)
Frame.Active = true
Frame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Frame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "UniversalAimbot v4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar

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

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Parent = Frame

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

-- Theme color helper
local function themeColorNow()
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        local t = (tick() * 0.2) % 1
        return Color3.fromHSV(t, 1, 1)
    end
    local map = {
        Red = Color3.fromRGB(255,0,0),
        Blue = Color3.fromRGB(0,122,255),
        Orange = Color3.fromRGB(255,165,0),
        Green = Color3.fromRGB(0,255,0)
    }
    return map[name] or Color3.fromRGB(0,122,255)
end

-- Toggle helper
local function makeToggle(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 34)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = themeColorNow()
    btn.Text = text..": "..(initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0,60,1,0)
    status.Position = UDim2.new(1,-72,0,0)
    status.BackgroundTransparency = 1
    status.Text = (initial and "On" or "Off")
    status.Font = Enum.Font.SourceSansBold
    status.TextSize = 16
    status.TextColor3 = initial and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    status.Parent = btn
    return btn, status
end

-- Slider helper
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
    bar.BorderSizePixel = 1
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
        local rel=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        fill.Size=UDim2.new(rel,0,1,0)
        knob.Position=UDim2.new(rel,0,0.5,0)
        local val=minVal+rel*(maxVal-minVal)
        lbl.Text=labelText..": "..tostring(math.floor(val))
        return val
    end
    bar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true update(input.Position.X) end end)
    bar.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then update(input.Position.X) end end)
    return {
        Label=lbl,Bar=bar,Fill=fill,Knob=knob,
        SetValue=function(v)local rel=(v-minVal)/(maxVal-minVal) fill.Size=UDim2.new(rel,0,1,0) knob.Position=UDim2.new(rel,0,0.5,0) lbl.Text=labelText..": "..tostring(math.floor(v)) end,
        GetValue=function() local rel=fill.Size.X.Scale return minVal+rel*(maxVal-minVal) end
    }
end

-- Create toggles and sliders
local ESPBtn,ESPStatus=makeToggle(Content,"ESP",12,espEnabled)
local AimBtn,AimStatus=makeToggle(Content,"Aimlock",64,aimbotEnabled)
local HeadBtn,HeadStatus=makeToggle(Content,"Head Aim",116,headAimEnabled)
local FOVSlider=makeSlider(Content,"FOV Circle",168,minFov,maxFov,fov)

-- Theme button
local ThemeBtn=Instance.new("TextButton")
ThemeBtn.Size=UDim2.new(0,180,0,36)
ThemeBtn.Position=UDim2.new(0,12,0,232)
ThemeBtn.BackgroundColor3=Color3.fromRGB(45,45,45)
ThemeBtn.BorderSizePixel=2
ThemeBtn.BorderColor3=themeColorNow()
ThemeBtn.Text="Theme: "..(themeNames[currentThemeIndex] or "Blue")
ThemeBtn.Font=Enum.Font.SourceSansBold
ThemeBtn.TextSize=16
ThemeBtn.TextColor3=Color3.fromRGB(255,255,255)
ThemeBtn.Parent=Content

-- Reset & Save buttons
local ResetBtn=Instance.new("TextButton")
ResetBtn.Size=UDim2.new(0,180,0,36)
ResetBtn.Position=UDim2.new(0,12,0,284)
ResetBtn.BackgroundColor3=Color3.fromRGB(45,45,45)
ResetBtn.BorderSizePixel=2
ResetBtn.BorderColor3=themeColorNow()
ResetBtn.Text="Reset Settings"
ResetBtn.Font=Enum.Font.SourceSansBold
ResetBtn.TextSize=16
ResetBtn.TextColor3=Color3.fromRGB(255,255,255)
ResetBtn.Parent=Content

local SaveBtn=Instance.new("TextButton")
SaveBtn.Size=UDim2.new(0,180,0,36)
SaveBtn.Position=UDim2.new(0,212,0,284)
SaveBtn.BackgroundColor3=Color3.fromRGB(45,45,45)
SaveBtn.BorderSizePixel=2
SaveBtn.BorderColor3=themeColorNow()
SaveBtn.Text="Save Settings"
SaveBtn.Font=Enum.Font.SourceSansBold
SaveBtn.TextSize=16
SaveBtn.TextColor3=Color3.fromRGB(255,255,255)
SaveBtn.Parent=Content

-- === ESP Setup ===
local function setupESP(plr)
    if not plr or not plr.Character then return end
    local root=findRootPart(plr.Character)
    if not root then return end
    if highlightedPlayers[plr] then pcall(function() highlightedPlayers[plr]:Destroy() end) end
    local highlight=Instance.new("Highlight")
    highlight.Adornee=plr.Character
    highlight.FillTransparency=0.6
    highlight.FillColor=themeColorNow()
    highlight.OutlineColor=themeColorNow()
    highlight.Enabled=espEnabled
    highlight.Parent=CoreGui
    highlightedPlayers[plr]=highlight

    if nameLabels[plr] then pcall(function() nameLabels[plr]:Destroy() end) end
    local nameLabel=Instance.new("TextLabel")
    nameLabel.Size=UDim2.new(0,120,0,18)
    nameLabel.BackgroundTransparency=1
    nameLabel.TextColor3=Color3.fromRGB(255,255,255)
    nameLabel.Font=Enum.Font.SourceSansBold
    nameLabel.TextSize=14
    nameLabel.Text=plr.Name
    nameLabel.Parent=Frame
    nameLabels[plr]=nameLabel

    if healthLabels[plr] then pcall(function() healthLabels[plr]:Destroy() end) end
    local healthLabel=Instance.new("TextLabel")
    healthLabel.Size=UDim2.new(0,120,0,14)
    healthLabel.BackgroundTransparency=1
    healthLabel.TextColor3=Color3.fromRGB(0,255,0)
    healthLabel.Font=Enum.Font.SourceSans
    healthLabel.TextSize=12
    healthLabel.Text="Health: N/A"
    healthLabel.Parent=Frame
    healthLabels[plr]=healthLabel
end

for _,plr in pairs(Players:GetPlayers()) do
    if plr~=LocalPlayer then
        setupESP(plr)
        plr.CharacterAdded:Connect(function() task.wait(0.35) setupESP(plr) end)
    end
end
Players.PlayerAdded:Connect(function(plr)
    if plr~=LocalPlayer then
        plr.CharacterAdded:Connect(function() task.wait(0.35) setupESP(plr) end)
    end
end)
Players.PlayerRemoving:Connect(function(plr)
    if highlightedPlayers[plr] then pcall(function() highlightedPlayers[plr]:Destroy() end) highlightedPlayers[plr]=nil end
    if nameLabels[plr] then pcall(function() nameLabels[plr]:Destroy() end) nameLabels[plr]=nil end
    if healthLabels[plr] then pcall(function() healthLabels[plr]:Destroy() end) healthLabels[plr]=nil end
end)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible=aimbotEnabled
FOVCircle.Radius=fov
FOVCircle.Color=themeColorNow()
FOVCircle.Thickness=2
FOVCircle.Filled=false
FOVCircle.NumSides=100
FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)

-- Distance label
local DistanceUI = Instance.new("TextLabel")
DistanceUI.Size=UDim2.new(0,180,0,20)
DistanceUI.Position=UDim2.new(0,12,0,280)
DistanceUI.BackgroundTransparency=1
DistanceUI.TextColor3=Color3.fromRGB(255,255,255)
DistanceUI.Font=Enum.Font.SourceSans
DistanceUI.TextSize=14
DistanceUI.TextXAlignment=Enum.TextXAlignment.Left
DistanceUI.Parent=Frame

-- === Input & Aimlock ===
local aiming=false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        local mousePos=UserInputService:GetMouseLocation()
        local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        if (mousePos-center).Magnitude<=fov then aiming=true end
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)

-- GUI interactions
ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPStatus.Text = espEnabled and "On" or "Off"
    ESPStatus.TextColor3 = espEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    for _,hl in pairs(highlightedPlayers) do hl.Enabled=espEnabled end
end)
AimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimStatus.Text = aimbotEnabled and "On" or "Off"
    AimStatus.TextColor3 = aimbotEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    FOVCircle.Visible=aimbotEnabled
end)
HeadBtn.MouseButton1Click:Connect(function()
    headAimEnabled = not headAimEnabled
    HeadStatus.Text = headAimEnabled and "On" or "Off"
    HeadStatus.TextColor3 = headAimEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex%#themeNames+1
    ThemeBtn.Text="Theme: "..(themeNames[currentThemeIndex] or "Blue")
end)
ResetBtn.MouseButton1Click:Connect(function()
    aimbotEnabled=false
    headAimEnabled=false
    espEnabled=true
    fov=120
    AimBtn.MouseButton1Click()
    HeadBtn.MouseButton1Click()
    ESPBtn.MouseButton1Click()
    FOVSlider.SetValue(fov)
end)
SaveBtn.MouseButton1Click:Connect(function()
    print("Settings saved (placeholder).")
end)

-- === RunService Loop ===
RunService.RenderStepped:Connect(function()
    -- Update FOV circle & theme
    FOVCircle.Radius = fov
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = themeColorNow()
    for _,hl in pairs(highlightedPlayers) do
        hl.FillColor = themeColorNow()
        hl.OutlineColor = themeColorNow()
    end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local root=findRootPart(plr.Character)
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    if nameLabels[plr] then nameLabels[plr].Position=UDim2.new(0,screenPos.X-60,0,screenPos.Y-40) end
                    if healthLabels[plr] then
                        local health=plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health or 0
                        healthLabels[plr].Position=UDim2.new(0,screenPos.X-60,0,screenPos.Y-22)
                        healthLabels[plr].Text="Health: "..math.floor(health)
                    end
                end
            end
        end
    end
    -- Aimlock
    if aimbotEnabled and aiming then
        currentTarget = getClosestTarget()
        if currentTarget then lockOnTarget(currentTarget) end
    end
    -- Distance update
    if currentTarget and currentTarget.Character then
        local root=findRootPart(currentTarget.Character)
        if root then
            DistanceUI.Text="Distance: "..math.floor((Camera.CFrame.Position-root.Position).Magnitude)
        end
    else
        DistanceUI.Text="Distance: N/A"
    end
    -- FOV slider
    fov = FOVSlider.GetValue()
end)
