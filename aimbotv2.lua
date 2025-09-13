--[[ 
    Universal Aimbot vFinal - Part 1 
    Author: C_mthe3rd Gaming
    Purpose: Core functions, utilities, settings persistence, ESP & Aimbot flags
]]

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===== Globals / Defaults =====
local espEnabled = true
local aimbotEnabled = false
local headAimEnabled = false
local fov = 150
local minFov = 50
local maxFov = 500
local predictionEnabled = true
local predictionFactor = 0.125
local visibilityCheck = true
local lockPart = "HumanoidRootPart"
local currentTarget = nil
local highlightedPlayers = {}
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2
local FOVCircle = nil

local savedSettings = {}
local saveFileName = "UniversalAimbotSettings.json"

-- ===== Utilities =====
local function findRootPart(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function isTargetVisible(targetPart)
    if not visibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
    return (hit == nil or hit:IsDescendantOf(targetPart.Parent))
end

local function getPredictedPosition(part)
    if not predictionEnabled then return part.Position end
    local vel = part.Velocity or Vector3.new()
    return part.Position + vel * predictionFactor
end

local function lockOnTarget()
    if not currentTarget or not currentTarget.Character then return end
    local targetPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
    if targetPart and isTargetVisible(targetPart) then
        local predicted = getPredictedPosition(targetPart)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
    end
end

-- ===== Settings Persistence =====
local function saveSettings()
    savedSettings.espEnabled = espEnabled
    savedSettings.aimbotEnabled = aimbotEnabled
    savedSettings.headAimEnabled = headAimEnabled
    savedSettings.fov = fov
    savedSettings.themeIndex = currentThemeIndex
    savedSettings.predictionFactor = predictionFactor
    savedSettings.predictionEnabled = predictionEnabled
    savedSettings.visibilityCheck = visibilityCheck
    local encoded = HttpService:JSONEncode(savedSettings)
    writefile(saveFileName, encoded)
end

local function loadSettings()
    if not isfile(saveFileName) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(saveFileName)) end)
    if success and type(data) == "table" then
        for k,v in pairs(data) do
            if savedSettings[k] ~= nil then
                savedSettings[k] = v
            end
        end
        espEnabled = savedSettings.espEnabled
        aimbotEnabled = savedSettings.aimbotEnabled
        headAimEnabled = savedSettings.headAimEnabled
        fov = savedSettings.fov
        currentThemeIndex = savedSettings.themeIndex
        predictionFactor = savedSettings.predictionFactor
        predictionEnabled = savedSettings.predictionEnabled
        visibilityCheck = savedSettings.visibilityCheck
    end
end

-- ===== Highlight / ESP setup =====
local function setupHighlight(player)
    if not player.Character then return end
    local root = findRootPart(player.Character)
    if not root then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight_"..player.Name
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(0,122,255)
    highlight.OutlineColor = Color3.fromRGB(0,122,255)
    highlight.Enabled = espEnabled
    highlight.Parent = CoreGui
    highlightedPlayers[player] = highlight
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.35)
        pcall(function() setupHighlight(pl) end)
    end)
end)

Players.PlayerRemoving:Connect(function(pl)
    if highlightedPlayers[pl] then
        pcall(function() highlightedPlayers[pl]:Destroy() end)
        highlightedPlayers[pl] = nil
    end
end)

-- ===== Part 1 Startup =====
loadSettings()
print("[UniversalAimbot] Part 1 loaded: Core functions and settings.")

--[[ 
    Universal Aimbot vFinal - Part 2 
    Author: C_mthe3rd Gaming
    Purpose: GUI creation, toggles, sliders, theme button, credits
]]

-- ===== Root ScreenGui =====
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- ===== Main Frame =====
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 360, 0, 400) -- slightly bigger
Frame.Position = UDim2.new(1, -380, 0, 80)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0,122,255)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.ZIndex = 2

-- ===== TitleBar =====
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Frame
TitleBar.ZIndex = 3

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Universal Aimbot vFinal"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar
TitleLabel.ZIndex = 4

-- ===== Credits (bottom only) =====
local Credits = Instance.new("TextLabel")
Credits.Name = "Credits"
Credits.Size = UDim2.new(0.6, 0, 0, 18)
Credits.Position = UDim2.new(0, 10, 1, -26)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180,180,180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 15
Credits.Parent = Frame
Credits.ZIndex = 3

-- ===== Minimize Button =====
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 50, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 6)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.BorderColor3 = Color3.fromRGB(0,122,255)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.Parent = TitleBar
MinimizeBtn.ZIndex = 5

-- ===== Content Container =====
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -40)
Content.Position = UDim2.new(0, 0, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = Frame
Content.ZIndex = 2

-- ===== Helper: Toggle Button =====
local function makeToggleLabel(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 32)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = theme_color_now()
    btn.Text = text .. ": " .. (initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 70, 1, 0)
    status.Position = UDim2.new(1, -78, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = (initial and "On" or "Off")
    status.Font = Enum.Font.SourceSansBold
    status.TextSize = 15
    status.TextColor3 = initial and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    status.Parent = btn

    return btn, status
end

-- ===== Helper: Slider =====
local function makeSlider(parent, labelText, y, minVal, maxVal, initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 220, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(math.floor(initialVal))
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 280, 0, 16)
    bar.Position = UDim2.new(0, 12, 0, y + 22)
    bar.BackgroundColor3 = Color3.fromRGB(42,42,42)
    bar.BorderSizePixel = 1
    bar.BorderColor3 = theme_color_now()
    bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0,0)
    fill.Position = UDim2.new(0,0,0,0)
    fill.BackgroundColor3 = theme_color_now()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knobWhite = Instance.new("Frame", bar)
    knobWhite.Size = UDim2.new(0, 14, 0, 14)
    knobWhite.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knobWhite.AnchorPoint = Vector2.new(0.5,0.5)
    knobWhite.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knobWhite.BorderSizePixel = 0
    local corner = Instance.new("UICorner", knobWhite)
    corner.CornerRadius = UDim.new(1,0)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel,0,1,0)
        knobWhite.Position = UDim2.new(rel,0,0.5,0)
        local value = minVal + rel*(maxVal-minVal)
        lbl.Text = labelText .. ": " .. tostring(math.floor(value))
        return value
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    local obj = {
        Label = lbl,
        Bar = bar,
        Fill = fill,
        Knob = knobWhite,
        SetValue = function(v)
            local rel = (v-minVal)/(maxVal-minVal)
            fill.Size = UDim2.new(rel,0,1,0)
            knobWhite.Position = UDim2.new(rel,0,0.5,0)
            lbl.Text = labelText .. ": " .. tostring(math.floor(v))
        end,
        GetValue = function()
            local rel = fill.Size.X.Scale
            return minVal + rel*(maxVal-minVal)
        end
    }
    return obj
end

-- ===== Create Toggles =====
local ESPBtn, ESPStatus = makeToggleLabel(Content, "ESP", 10, espEnabled)
local AimBtn, AimStatus = makeToggleLabel(Content, "Aimlock", 52, aimbotEnabled)
local HeadBtn, HeadStatus = makeToggleLabel(Content, "Head Aim", 94, headAimEnabled)

-- ===== Theme Button =====
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(0, 160, 0, 32)
ThemeBtn.Position = UDim2.new(0, 12, 0, 140)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
ThemeBtn.BorderSizePixel = 1
ThemeBtn.BorderColor3 = theme_color_now()
ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
ThemeBtn.TextColor3 = Color3.fromRGB(255,255,255) -- white text
ThemeBtn.Font = Enum.Font.SourceSansBold
ThemeBtn.TextSize = 15
ThemeBtn.Parent = Content

-- ===== FOV Slider =====
local FOVSlider = makeSlider(Content, "FOV Circle", 180, minFov, maxFov, fov)

-- ===== Reset & Save Buttons =====
local function makeSmallButton(parent, text, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 32)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = theme_color_now()
    btn.Text = text
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

local ResetBtn = makeSmallButton(Content, "Reset Settings", 12, 230)
local SaveBtn = makeSmallButton(Content, "Save Settings", 188, 230)

-- ===== Part 2 Startup =====
print("[UniversalAimbot] Part 2 loaded: GUI created successfully.")

--[[ 
    Universal Aimbot vFinal - Part 3 
    Author: C_mthe3rd Gaming
    Purpose: Dragging, FOV circle, right-click aimlock inside circle, theme outline updates, per-frame updates
]]

-- ===== Services =====
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- ===== Theme Helper =====
local function theme_color_now()
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        local t = (tick() * 0.2) % 1
        return Color3.fromHSV(t,1,1)
    end
    local themeMap = {
        Red = Color3.fromRGB(255,0,0),
        Blue = Color3.fromRGB(0,122,255),
        Orange = Color3.fromRGB(255,165,0),
        Green = Color3.fromRGB(0,255,0),
    }
    return themeMap[name] or Color3.fromRGB(0,122,255)
end

-- ===== Dragging =====
local draggingGui = false
local dragStart = nil
local startPos = nil
local targetPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingGui = true
        dragStart = input.Position
        startPos = Frame.Position
        targetPos = startPos
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingGui = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and draggingGui and dragStart and startPos then
        local delta = input.Position - dragStart
        targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ===== FOV Circle =====
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Visible = aimbotEnabled
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 1
    FOVCircle.Radius = fov
    FOVCircle.Color = theme_color_now()
    FOVCircle.Filled = false
end

-- ===== Right-click aimlock inside FOV =====
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and FOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local dist = (mousePos - screenCenter).Magnitude
        if dist <= fov then
            aimbotEnabled = true
            AimBtn.Text = "Aimlock: On"
            AimStatus.Text = "On"
            AimStatus.TextColor3 = Color3.fromRGB(100,255,100)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotEnabled = false
        AimBtn.Text = "Aimlock: Off"
        AimStatus.Text = "Off"
        AimStatus.TextColor3 = Color3.fromRGB(255,100,100)
    end
end)

-- ===== Theme Cycling Updates =====
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = (currentThemeIndex % #themeNames) + 1
    ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
    local c = theme_color_now()
    Frame.BorderColor3 = c
    MinimizeBtn.BorderColor3 = c
    ResetBtn.BorderColor3 = c
    SaveBtn.BorderColor3 = c
    ThemeBtn.BorderColor3 = c
    FOVSlider.Fill.BackgroundColor3 = c
end)

-- ===== Minimize Behavior =====
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Credits.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0,360,0,40) or UDim2.new(0,360,0,400)
    MinimizeBtn.Text = minimized and "+" or "—"
end)

-- ===== Per-frame Updates =====
RunService.RenderStepped:Connect(function()
    -- Smooth dragging
    if targetPos then
        Frame.Position = Frame.Position:Lerp(targetPos,0.25)
    end

    -- Update theme outline dynamically
    local c = theme_color_now()
    Frame.BorderColor3 = c
    MinimizeBtn.BorderColor3 = c
    ResetBtn.BorderColor3 = c
    SaveBtn.BorderColor3 = c
    ThemeBtn.BorderColor3 = c
    FOVSlider.Fill.BackgroundColor3 = c

    -- Update FOV circle
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = fov
        FOVCircle.Color = c
        FOVCircle.Visible = aimbotEnabled
    end
end)

-- Final log
print("[UniversalAimbot] Part 3 loaded: FOV circle, aimlock, dragging, theme updates ready.")

--[[ 
    Universal Aimbot vFinal - Part 4 
    Author: C_mthe3rd Gaming
    Purpose: Settings persistence, prediction, visibility toggles, GUI hooks, reset/save, highlight management
]]

-- ===== Services =====
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== Saved Settings =====
savedSettings = savedSettings or {}
local saveFileName = "UniversalAimbot_Settings.json"

-- ===== Prediction & Visibility =====
predictionEnabled = (type(predictionEnabled)=="boolean") and predictionEnabled or true
predictionFactor = (type(predictionFactor)=="number") and predictionFactor or 0.125
visibilityCheck = (type(visibilityCheck)=="boolean") and visibilityCheck or true

-- ===== Save/Load Functions =====
local function saveSettings()
    savedSettings.espEnabled = espEnabled
    savedSettings.aimbotEnabled = aimbotEnabled
    savedSettings.headAimEnabled = headAimEnabled
    savedSettings.fov = fov
    savedSettings.themeIndex = currentThemeIndex
    savedSettings.predictionFactor = predictionFactor
    savedSettings.predictionEnabled = predictionEnabled
    savedSettings.visibilityCheck = visibilityCheck
    local encoded = HttpService:JSONEncode(savedSettings)
    writefile(saveFileName, encoded)
end

local function loadSettings()
    if not isfile(saveFileName) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(saveFileName)) end)
    if success and type(data) == "table" then
        for k,v in pairs(data) do
            if savedSettings[k] ~= nil then
                savedSettings[k] = v
            end
        end
        espEnabled = savedSettings.espEnabled
        aimbotEnabled = savedSettings.aimbotEnabled
        headAimEnabled = savedSettings.headAimEnabled
        fov = savedSettings.fov
        currentThemeIndex = savedSettings.themeIndex
        predictionFactor = savedSettings.predictionFactor
        predictionEnabled = savedSettings.predictionEnabled
        visibilityCheck = savedSettings.visibilityCheck
    end
end

-- ===== GUI Controls: Prediction / Visibility =====
local predictToggle = makeToggleLabel(Content,"Prediction",220,predictionEnabled)
local predictionSlider = makeSlider(Content,"Lead Factor",250,0.01,0.25,predictionFactor)
local visToggle = makeToggleLabel(Content,"Visibility Check",280,visibilityCheck)

predictToggle.MouseButton1Click:Connect(function()
    predictionEnabled = not predictionEnabled
    predictToggle.Text = "Prediction: "..(predictionEnabled and "On" or "Off")
    predictToggle.TextColor3 = predictionEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    saveSettings()
end)

visToggle.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visToggle.Text = "Visibility Check: "..(visibilityCheck and "On" or "Off")
    visToggle.TextColor3 = visibilityCheck and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    saveSettings()
end)

predictionSlider.SetValue(predictionFactor)
predictionSlider.Bar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        predictionFactor = predictionSlider.GetValue()
        saveSettings()
    end
end)

-- ===== Reset & Save Buttons =====
ResetBtn.MouseButton1Click:Connect(function()
    -- Reset flags
    espEnabled = true
    aimbotEnabled = false
    headAimEnabled = false
    fov = 120
    currentThemeIndex = 2
    predictionEnabled = true
    predictionFactor = 0.125
    visibilityCheck = true

    -- Update GUI
    ESPBtn.Text = "ESP: On"; ESPStatus.Text = "On"; ESPStatus.TextColor3 = Color3.fromRGB(100,255,100)
    AimBtn.Text = "Aimlock: Off"; AimStatus.Text = "Off"; AimStatus.TextColor3 = Color3.fromRGB(255,100,100)
    HeadBtn.Text = "Head Aim: Off"; HeadStatus.Text = "Off"; HeadStatus.TextColor3 = Color3.fromRGB(255,100,100)
    ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
    predictToggle.Text = "Prediction: On"; predictToggle.TextColor3 = Color3.fromRGB(100,255,100)
    predictionSlider.SetValue(predictionFactor)
    visToggle.Text = "Visibility Check: On"; visToggle.TextColor3 = Color3.fromRGB(100,255,100)
    FOVSlider.SetValue(fov)

    -- Update highlights
    local c = theme_color_now()
    for _,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = c
                hl.OutlineColor = c
                hl.Enabled = espEnabled
            end)
        end
    end

    if FOVCircle then
        pcall(function()
            FOVCircle.Radius = fov
            FOVCircle.Color = c
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    saveSettings()
end)

SaveBtn.MouseButton1Click:Connect(function()
    saveSettings()
    -- visual feedback
    local orig = SaveBtn.BackgroundColor3
    TweenService:Create(SaveBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70,120,70)}):Play()
    task.delay(0.2,function()
        SaveBtn.BackgroundColor3 = orig
    end)
end)

-- ===== Player Highlights =====
highlightedPlayers = highlightedPlayers or {}
local function setupHighlight(pl)
    if not pl or not pl.Character then return end
    local hrp = findRootPart(pl.Character)
    if not hrp then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = pl.Character
    highlight.FillColor = theme_color_now()
    highlight.OutlineColor = theme_color_now()
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.4
    highlight.Enabled = espEnabled
    highlight.Parent = CoreGui
    highlightedPlayers[pl] = highlight
end

for _,pl in pairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        pl.CharacterAdded:Connect(function()
            task.wait(0.35)
            setupHighlight(pl)
        end)
        if pl.Character then
            setupHighlight(pl)
        end
    end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.35)
        setupHighlight(pl)
    end)
end)

Players.PlayerRemoving:Connect(function(pl)
    if highlightedPlayers[pl] then
        pcall(function() highlightedPlayers[pl]:Destroy() end)
        highlightedPlayers[pl] = nil
    end
end)

-- ===== Load Previous Settings =====
loadSettings()

-- Apply loaded settings to GUI
ESPBtn.Text = "ESP: "..(espEnabled and "On" or "Off")
ESPStatus.Text = (espEnabled and "On" or "Off")
AimBtn.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
AimStatus.Text = (aimbotEnabled and "On" or "Off")
HeadBtn.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
HeadStatus.Text = (headAimEnabled and "On" or "Off")
predictToggle.Text = "Prediction: "..(predictionEnabled and "On" or "Off")
visToggle.Text = "Visibility Check: "..(visibilityCheck and "On" or "Off")
predictionSlider.SetValue(predictionFactor)
FOVSlider.SetValue(fov)

print("[UniversalAimbot] Part 4 loaded: Settings, prediction, visibility, highlights ready.")
