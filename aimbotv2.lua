--[[ 
    Universal Aimbot v3 - Part 1
    Author: C_mthe3rd Gaming
    This part contains:
      - Settings & services
      - Utilities
      - Theme system (outline + fill)
      - Drawing FOV circle
      - Robust ESP (handles join/leave/respawn)
      - GUI foundation + helper builders: makeToggle, makeSlider, makeDropdown
      - CreateGui() call (only in Part 1)
    Notes:
      - GUI Outline and ESP Fill/Outline follow the active themeColor
      - FOV slider uses a moving white knob (left-to-right) and updates the FOV circle
      - Buttons change label text "On"/"Off" immediately
      - The script uses safe pcall checks for Drawing API and Instance creation
]]

-- ===== SETTINGS =====
local teamCheck = false               -- don't target teammates when true
local fov = 120                       -- starting FOV radius (in screen-space units)
local minFov = 50
local maxFov = 500
local lockPart = "HumanoidRootPart"   -- preferred lock part
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local currentTarget = nil
local currentTargetDistance = "N/A"

-- theme options (order matters for cycling)
local themeNames = {"Red", "Blue", "Orange", "Green", "Rainbow"}
local currentThemeIndex = 2           -- default = Blue (index into themeNames)
local themeColor = nil                -- computed below
local rainbowSpeed = 0.2

-- storage
local highlightedPlayers = {}         -- map: Player -> Highlight instance (or nil)

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===== UTILITIES =====
local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function safeInstanceNew(className)
    local ok, inst = pcall(function() return Instance.new(className) end)
    if ok then return inst end
    return nil
end

-- Robust root part finder (tries common torso names)
local function findRootPart(character)
    if not character then return nil end
    local names = {"HumanoidRootPart", "LowerTorso", "UpperTorso", "Torso"}
    for _,n in ipairs(names) do
        local p = character:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

-- ===== DRAWING: FOV CIRCLE (safe) =====
local FOVCircle = nil
do
    local ok, DrawingAPI = pcall(function() return Drawing end)
    if ok and type(DrawingAPI) == "table" then
        local success, circle = pcall(function()
            local c = Drawing.new("Circle")
            c.Thickness = 2
            c.NumSides = 100
            c.Filled = false
            c.Radius = fov
            c.Visible = false
            c.Color = Color3.fromRGB(0,122,255)
            c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            return c
        end)
        if success then FOVCircle = circle end
    end
end

-- ===== THEME SYSTEM =====
local function computeThemeColor()
    local theme = themeNames[currentThemeIndex] or "Blue"
    if theme == "Rainbow" then
        local t = tick() * rainbowSpeed
        return Color3.fromHSV((t % 1), 1, 1)
    end
    if theme == "Red" then return Color3.fromRGB(255,0,0) end
    if theme == "Blue" then return Color3.fromRGB(0,122,255) end
    if theme == "Orange" then return Color3.fromRGB(255,165,0) end
    if theme == "Green" then return Color3.fromRGB(0,255,0) end
    return Color3.fromRGB(0,122,255)
end

local function cycleTheme()
    currentThemeIndex = currentThemeIndex % #themeNames + 1
    themeColor = computeThemeColor()
end

-- initialize themeColor
themeColor = computeThemeColor()

-- ===== ESP: Create / Remove Highlights (robust) =====
local function removeHighlight(player)
    if not player then return end
    local h = highlightedPlayers[player]
    if h and typeof(h) == "Instance" then
        pcall(function() h:Destroy() end)
    end
    highlightedPlayers[player] = nil
end

local function setupHighlightForCharacter(player, character)
    if not player or player == LocalPlayer then return end
    if not character or not character.Parent then return end

    -- ensure there is a root part
    local root = findRootPart(character)
    if not root then
        -- retry once shortly after
        task.delay(0.4, function()
            if player and player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
        return
    end

    -- clear old
    removeHighlight(player)

    -- create highlight instance
    local hl = safeInstanceNew("Highlight")
    if not hl then return end
    hl.Adornee = character
    hl.FillColor = themeColor
    hl.OutlineColor = themeColor
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.3
    hl.Enabled = espEnabled
    hl.Parent = character
    highlightedPlayers[player] = hl

    -- re-setup when they die (respawn)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            -- give a short delay for respawn to set up new highlight
            task.wait(0.1)
            if player and player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
    end
end

local function createHighlight(player)
    if not player or player == LocalPlayer then return end
    if player.Character then
        setupHighlightForCharacter(player, player.Character)
    end
    -- hook CharacterAdded to reapply highlight reliably
    player.CharacterAdded:Connect(function(character)
        task.wait(0.35)
        setupHighlightForCharacter(player, character)
    end)
end

-- initialize existing players
for _,p in ipairs(Players:GetPlayers()) do
    createHighlight(p)
end

-- connect join/leave
Players.PlayerAdded:Connect(function(p)
    createHighlight(p)
end)
Players.PlayerRemoving:Connect(function(p)
    removeHighlight(p)
end)

-- ===== TARGET SELECTION & AIMLOCK HELPERS (kept small here) =====
local function getClosestTarget()
    local closest = nil
    local shortest = math.huge
    local screenCenter = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local localPos = localRoot and localRoot.Position or Vector3.new()
    for _,pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local targetPart = headAimEnabled and pl.Character:FindFirstChild("Head") or findRootPart(pl.Character)
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                local worldDist = (localPos - targetPart.Position).Magnitude
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                if onScreen and screenDist <= fov and screenDist < shortest then
                    if not teamCheck or pl.Team ~= LocalPlayer.Team then
                        closest = pl
                        shortest = screenDist
                        currentTargetDistance = math.floor(worldDist)
                    end
                end
            end
        end
    end
    return closest
end

local function lockOnTarget()
    if not currentTarget then return end
    if currentTarget == LocalPlayer or not currentTarget.Character then currentTarget = nil; return end
    local targetPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
    if not targetPart then currentTarget = nil; return end
    local targetVel = (targetPart.Velocity or Vector3.new())
    local pred = math.clamp(0.05 + ( (type(currentTargetDistance)=="number" and currentTargetDistance or 0) / 2000 ), 0.02, 0.1)
    local predictedPos = targetPart.Position + (targetVel * pred)
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), 0.2)
end

-- ===== RENDER STEP: Update theme & ESP visuals & FOVCircle =====
RunService.RenderStepped:Connect(function()
    -- compute theme color (rainbow included)
    themeColor = computeThemeColor()

    -- update all highlights quickly (fill + outline + enabled)
    for pl,h in pairs(highlightedPlayers) do
        if h and typeof(h) == "Instance" then
            pcall(function()
                h.FillColor = themeColor
                h.OutlineColor = themeColor
                h.Enabled = espEnabled
            end)
        end
    end

    -- update FOV circle if available
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end
end)

-- ===== GUI HELPERS: makeToggle / makeSlider / makeDropdown =====
-- These helpers return created UI objects (TextButton/Frame/etc)
local function makeToggle(parent, labelText, startState, posY, callback)
    -- container
    local container = safeInstanceNew("Frame")
    container.Size = UDim2.new(1, -20, 0, 28)
    container.Position = UDim2.new(0, 10, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = parent

    -- label
    local label = safeInstanceNew("TextLabel")
    label.Size = UDim2.new(0.64, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Parent = container

    -- toggle button (shows On/Off)
    local toggle = safeInstanceNew("TextButton")
    toggle.Size = UDim2.new(0.34, 0, 1, 0)
    toggle.Position = UDim2.new(0.66, 0, 0, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(45,45,45)
    toggle.BorderSizePixel = 2
    toggle.AutoButtonColor = false
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 14
    toggle.Parent = container

    local function refresh(state)
        toggle.Text = state and "On" or "Off"
        -- outline follows theme
        toggle.BorderColor3 = themeColor
        -- darker fill for off, theme outline still visible
        toggle.BackgroundColor3 = state and Color3.fromRGB(30,30,30) or Color3.fromRGB(45,45,45)
        toggle.TextColor3 = Color3.fromRGB(255,255,255)
    end

    -- initial
    refresh(startState)

    toggle.MouseButton1Click:Connect(function()
        startState = not startState
        refresh(startState)
        pcall(function() callback(startState) end)
    end)

    -- return control objects for external updates if needed
    return {
        Container = container,
        Label = label,
        Toggle = toggle,
        SetState = function(s) startState = s; refresh(s) end,
    }
end

-- makeSlider: horizontal slider with white knob moving left-to-right
local function makeSlider(parent, labelText, posY, width, height, minVal, maxVal, startVal, callback)
    local container = safeInstanceNew("Frame")
    container.Size = UDim2.new(1, -20, 0, height + 20)
    container.Position = UDim2.new(0, 10, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = safeInstanceNew("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.format("%s: %d", labelText, math.floor(startVal))
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Parent = container

    local track = safeInstanceNew("Frame")
    track.Size = UDim2.new(1, 0, 0, height)
    track.Position = UDim2.new(0, 0, 0, 20)
    track.BackgroundColor3 = Color3.fromRGB(40,40,40)
    track.BorderSizePixel = 1
    track.BorderColor3 = themeColor
    track.Parent = container

    -- fill shows progress in theme color
    local fill = safeInstanceNew("Frame")
    local initialScale = (startVal - minVal) / math.max(1, (maxVal - minVal))
    fill.Size = UDim2.new(initialScale, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = themeColor
    fill.BorderSizePixel = 0
    fill.Parent = track

    -- knob is a white rounded button (we'll use TextButton so it can receive Input)
    local knob = safeInstanceNew("TextButton")
    knob.Size = UDim2.new(0, 14, 1, -4) -- fixed px width, full height minus padding
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialScale, 0, 0.5, 0)
    knob.Text = ""
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.AutoButtonColor = false
    knob.Parent = track

    -- white knob visual corner
    local kcorner = safeInstanceNew("UICorner")
    kcorner.CornerRadius = UDim.new(1,0)
    kcorner.Parent = knob

    -- interactions
    local dragging = false
    local dragConnection
    local function setFromScreenX(screenX)
        local left = track.AbsolutePosition.X
        local w = track.AbsoluteSize.X
        local rel = clamp((screenX - left) / (w), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        local val = math.floor(minVal + rel * (maxVal - minVal))
        label.Text = string.format("%s: %d", labelText, val)
        pcall(function() callback(val) end)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromScreenX(input.Position.X)
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setFromScreenX(input.Position.X)
        end
    end)

    -- return objects so caller can adjust if needed
    return {
        Container = container,
        Label = label,
        Track = track,
        Fill = fill,
        Knob = knob,
        SetValue = function(v)
            v = clamp(v, minVal, maxVal)
            local rel = (v - minVal) / math.max(1, (maxVal - minVal))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            label.Text = string.format("%s: %d", labelText, math.floor(v))
            pcall(function() callback(math.floor(v)) end)
        end
    }
end

-- simple dropdown (cycles through options on click)
local function makeDropdown(parent, labelText, posY, options, startIndex, onChange)
    local container = safeInstanceNew("Frame")
    container.Size = UDim2.new(1, -20, 0, 28)
    container.Position = UDim2.new(0, 10, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = safeInstanceNew("TextLabel")
    label.Size = UDim2.new(0.64, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Parent = container

    local btn = safeInstanceNew("TextButton")
    btn.Size = UDim2.new(0.34, 0, 1, 0)
    btn.Position = UDim2.new(0.66, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = container

    local idx = startIndex or 1
    if idx < 1 then idx = 1 end
    if idx > #options then idx = #options end
    btn.Text = tostring(options[idx])

    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = tostring(options[idx])
        pcall(function() onChange(options[idx], idx) end)
    end)

    return {
        Container = container,
        Label = label,
        Button = btn,
        GetIndex = function() return idx end,
        SetIndex = function(i) idx = clamp(i, 1, #options); btn.Text = options[idx]; pcall(onChange, options[idx], idx) end
    }
end

-- ===== GUI CREATION =====
local function CreateGui()
    -- remove existing GUI if any
    if CoreGui:FindFirstChild("UniversalAimbotV3_GUI") then
        pcall(function() CoreGui.UniversalAimbotV3_GUI:Destroy() end)
    end

    local screenGui = safeInstanceNew("ScreenGui")
    screenGui.Name = "UniversalAimbotV3_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    -- main frame
    local Frame = safeInstanceNew("Frame")
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 320, 0, 380)
    Frame.Position = UDim2.new(1, -340, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = themeColor
    Frame.Active = true
    Frame.Parent = screenGui

    -- title bar
    local TitleBar = safeInstanceNew("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 28)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Frame

    local TitleLabel = safeInstanceNew("TextLabel")
    TitleLabel.Size = UDim2.new(1, -60, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    -- credits small under title (will be hidden when minimized via code)
    local CreditsLabel = safeInstanceNew("TextLabel")
    CreditsLabel.Size = UDim2.new(1, -60, 0, 14)
    CreditsLabel.Position = UDim2.new(0, 10, 0, 14)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextScaled = false
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 12
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Parent = TitleBar

    -- minimize button (positioned to the right of title)
    local MinBtn = safeInstanceNew("TextButton")
    MinBtn.Size = UDim2.new(0, 36, 0, 20)
    MinBtn.Position = UDim2.new(1, -44, 0, 4)
    MinBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    MinBtn.BorderSizePixel = 2
    MinBtn.BorderColor3 = themeColor
    MinBtn.Text = "—"
    MinBtn.Font = Enum.Font.SourceSansBold
    MinBtn.TextSize = 16
    MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    MinBtn.Parent = TitleBar

    -- content container
    local Content = safeInstanceNew("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -28)
    Content.Position = UDim2.new(0, 0, 0, 28)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    -- we will store references to controls so further parts can access them
    local controls = {}

    -- create toggles / slider / dropdown using helper functions
    controls.esp = makeToggle(Content, "ESP", espEnabled, 4, function(state)
        espEnabled = state
        -- update all highlights immediately
        for pl,hl in pairs(highlightedPlayers) do
            if hl and typeof(hl) == "Instance" then
                pcall(function() hl.Enabled = espEnabled end)
            end
        end
    end)

    controls.aimlock = makeToggle(Content, "Aimlock", aimbotEnabled, 40, function(state)
        aimbotEnabled = state
    end)

    controls.headAim = makeToggle(Content, "Head Aim", headAimEnabled, 76, function(state)
        headAimEnabled = state
    end)

    controls.themeDrop = makeDropdown(Content, "Theme", 112, themeNames, currentThemeIndex, function(opt, idx)
        -- find index and set
        for i,name in ipairs(themeNames) do
            if name == opt then currentThemeIndex = i; break end
        end
        -- immediate application: update themeColor and GUI outlines
        themeColor = computeThemeColor()
        Frame.BorderColor3 = themeColor
        MinBtn.BorderColor3 = themeColor
        controls.esp.Toggle.BorderColor3 = themeColor
        controls.esp.Toggle.BackgroundColor3 = controls.esp.Toggle.BackgroundColor3
    end)

    -- FOV slider: label + moving white knob
    controls.fov = makeSlider(Content, "FOV Circle", 148, 280, 14, minFov, maxFov, fov, function(val)
        fov = val
        -- FOVCircle updated in RenderStepped
    end)

    -- distance label (inside GUI as well)
    local DistLabel = safeInstanceNew("TextLabel")
    DistLabel.Size = UDim2.new(1, -20, 0, 18)
    DistLabel.Position = UDim2.new(0, 10, 0, 188)
    DistLabel.BackgroundTransparency = 1
    DistLabel.TextXAlignment = Enum.TextXAlignment.Left
    DistLabel.Font = Enum.Font.SourceSans
    DistLabel.TextSize = 14
    DistLabel.TextColor3 = Color3.fromRGB(255,255,255)
    DistLabel.Text = "Distance: N/A"
    DistLabel.Parent = Content

    -- bottom-left credits (outside content so it disappears on minimize)
    local CreditsBL = safeInstanceNew("TextLabel")
    CreditsBL.Size = UDim2.new(0, 180, 0, 16)
    CreditsBL.Position = UDim2.new(0, 10, 1, -20)
    CreditsBL.BackgroundTransparency = 1
    CreditsBL.Text = "Script By C_mthe3rd"
    CreditsBL.Font = Enum.Font.SourceSans
    CreditsBL.TextSize = 13
    CreditsBL.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsBL.TextXAlignment = Enum.TextXAlignment.Left
    CreditsBL.Parent = Frame

    -- draggable title logic (smooth lerp)
    local draggingGui = false
    local dragStartPos, dragStartMouse, targetPos = nil, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingGui = true
            dragStartMouse = input.Position
            dragStartPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingGui = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and draggingGui and dragStartMouse and dragStartPos then
            local delta = input.Position - dragStartMouse
            targetPos = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
        end
    end)

    -- smooth positioning every render step
    RunService.RenderStepped:Connect(function()
        if targetPos then
            Frame.Position = Frame.Position:Lerp(targetPos, 0.25)
        end

        -- update dynamic values inside GUI (distance label and outline)
        themeColor = computeThemeColor()
        Frame.BorderColor3 = themeColor
        MinBtn.BorderColor3 = themeColor
        controls.fov.Fill.BackgroundColor3 = themeColor
        controls.fov.Track.BorderColor3 = themeColor

        if currentTarget and currentTarget.Character then
            DistLabel.Text = "Distance: "..tostring(currentTargetDistance).."m"
        else
            DistLabel.Text = "Distance: N/A"
        end
    end)

    -- minimize button behavior (hides content + creditsBL)
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        CreditsBL.Visible = not minimized
        CreditsLabel.Visible = (not minimized) -- small label under title
        Frame.Size = minimized and UDim2.new(0, 320, 0, 28) or UDim2.new(0, 320, 0, 380)
        MinBtn.Text = minimized and "+" or "—"
    end)

    -- return references for later parts
    return {
        ScreenGui = screenGui,
        Frame = Frame,
        Content = Content,
        Controls = controls,
        DistLabel = DistLabel,
        CreditsBL = CreditsBL
    }
end

-- finally create the GUI (Part 1 creates GUI so Part 2/3 can reference it)
local GUIrefs = CreateGui()

-- Expose some variables to global table for later parts to pick up (safe)
_G.UniversalAimbot = _G.UniversalAimbot or {}
_G.UniversalAimbot.GUI = GUIrefs
_G.UniversalAimbot.Settings = {
    teamCheck = function(v) teamCheck = v end,
    getFOV = function() return fov end,
    setFOV = function(v) fov = clamp(v, minFov, maxFov) end,
    setThemeIndex = function(i) currentThemeIndex = clamp(i, 1, #themeNames); themeColor = computeThemeColor() end,
    getThemeIndex = function() return currentThemeIndex end
}

--[[
    Universal Aimbot v3 - Part 2
    Author: C_mthe3rd Gaming
    Purpose:
      - Main aimlock & targeting logic
      - Input handling (mouse, keybinds)
      - Sync GUI controls with state (keeps On/Off label consistent)
      - Distance tracking and consistent currentTarget updates
      - Clean shutdown helpers
      - Extra small safety checks & debounces
    NOTE: This part assumes Part 1 has been executed and:
      _G.UniversalAimbot and _G.UniversalAimbot.GUI exist
      helper functions (makeToggle/makeSlider/makeDropdown) are available in environment
--]]

-- quick sanity checks for required globals created by Part 1
if not _G or not _G.UniversalAimbot or not _G.UniversalAimbot.GUI then
    error("Part 2 expected Part 1 to run first. Please run Part 1 then Part 2.")
    return
end

-- grab references set by Part 1
local GUIrefs = _G.UniversalAimbot.GUI
local SettingsAPI = _G.UniversalAimbot.Settings

-- local shortcuts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- import state variables from environment if present (defensive)
local aimbotEnabled = aimbotEnabled or false
local headAimEnabled = headAimEnabled or false
local espEnabled = espEnabled or true
local fov = fov or 120
local minFov = minFov or 50
local maxFov = maxFov or 500

-- internal runtime state
local currentTarget = nil
local currentTargetDistance = "N/A"
local isRightMouseDown = false
local aimLockActive = false
local lastTargetCheck = 0
local targetCheckInterval = 0.06 -- seconds between scanning for target while holding

-- helpers
local function isInstanceAlive(i)
    return i and typeof(i) == "Instance" and i.Parent
end

-- safe function to update GUI toggle visuals from code (so labels never mismatch)
local function syncToggleVisual(toggleRef, state)
    if not toggleRef or not toggleRef.Toggle then return end
    local btn = toggleRef.Toggle
    -- update internal style & label
    btn.Text = state and "On" or "Off"
    btn.BorderColor3 = (type(themeColor) == "Color3" and themeColor) or btn.BorderColor3
    btn.BackgroundColor3 = state and Color3.fromRGB(30,30,30) or Color3.fromRGB(45,45,45)
end

-- sync known GUI toggles on start (in case Part1's toggles didn't reflect external state)
do
    local controls = GUIrefs.Controls
    if controls and controls.esp and controls.esp.SetState then
        controls.esp.SetState(espEnabled)
    else
        pcall(function() if controls and controls.esp and controls.esp.Toggle then syncToggleVisual(controls.esp, espEnabled) end end)
    end
    if controls and controls.aimlock and controls.aimlock.SetState then
        controls.aimlock.SetState(aimbotEnabled)
    else
        pcall(function() if controls and controls.aimlock and controls.aimlock.Toggle then syncToggleVisual(controls.aimlock, aimbotEnabled) end end)
    end
    if controls and controls.headAim and controls.headAim.SetState then
        controls.headAim.SetState(headAimEnabled)
    else
        pcall(function() if controls and controls.headAim and controls.headAim.Toggle then syncToggleVisual(controls.headAim, headAimEnabled) end end)
    end
end

-- update all highlights' enabled property instantly (used when toggling ESP)
local function applyESPStateToAll(enabled)
    for pl,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.Enabled = enabled
            end)
        end
    end
end

-- update theme visuals immediately for everything (GUI and highlights)
local function applyThemeImmediately()
    themeColor = computeThemeColor()
    -- GUI outline updates
    pcall(function()
        if GUIrefs and GUIrefs.Frame then
            GUIrefs.Frame.BorderColor3 = themeColor
            if GUIrefs.Controls and GUIrefs.Controls.fov and GUIrefs.Controls.fov.Track then
                GUIrefs.Controls.fov.Track.BorderColor3 = themeColor
                GUIrefs.Controls.fov.Fill.BackgroundColor3 = themeColor
            end
            -- update toggle borders
            for _,v in pairs(GUIrefs.Controls) do
                pcall(function()
                    if v.Toggle then v.Toggle.BorderColor3 = themeColor end
                end)
            end
        end
    end)
    -- apply to highlights (fill & outline)
    for pl,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
            end)
        end
    end
    -- apply to FOV circle if exists
    if FOVCircle then
        pcall(function() FOVCircle.Color = themeColor end)
    end
end

-- robust target selection with small ray-check optional (keeps cheap)
local function chooseTarget()
    -- reuse getClosestTarget from part1 if present, otherwise implement inline
    if type(getClosestTarget) == "function" then
        return getClosestTarget()
    end

    -- fallback simple selection
    local closest, shortest = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local localPos = localRoot and localRoot.Position or Vector3.new()
    for _,pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local part = headAimEnabled and pl.Character:FindFirstChild("Head") or findRootPart(pl.Character)
            local hum = pl.Character:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                if onScreen and screenDist <= fov and screenDist < shortest then
                    if not teamCheck or pl.Team ~= LocalPlayer.Team then
                        closest = pl
                        shortest = screenDist
                        currentTargetDistance = math.floor((localPos - part.Position).Magnitude)
                    end
                end
            end
        end
    end
    return closest
end

-- input handling for right mouse (aimlock) and updates isRightMouseDown
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
        -- release lock target when mouse released unless aimbot toggle dictates otherwise
        currentTarget = nil
    end
end)

-- bind H to toggle headAim (give GUI indicator too)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        headAimEnabled = not headAimEnabled
        -- update GUI if present
        if GUIrefs and GUIrefs.Controls and GUIrefs.Controls.headAim and GUIrefs.Controls.headAim.SetState then
            GUIrefs.Controls.headAim.SetState(headAimEnabled)
        else
            pcall(function() syncToggleVisual(GUIrefs.Controls.headAim, headAimEnabled) end)
        end
    end
end)

-- central render loop for aim behavior & distance updates
RunService.Heartbeat:Connect(function(step)
    -- apply theme visuals each frame (keeps rainbow smooth)
    applyThemeImmediately()

    -- handle scanning/locking while right mouse is held and aimlock toggle is enabled
    if aimbotEnabled and isRightMouseDown then
        -- throttle scanning
        if tick() - lastTargetCheck >= targetCheckInterval then
            lastTargetCheck = tick()
            -- reselect if no current or if current invalid
            if not currentTarget or not currentTarget.Character or not currentTarget.Character.Parent then
                currentTarget = chooseTarget()
            else
                -- if current exists but died or left, clear
                local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then
                    currentTarget = chooseTarget()
                end
            end
        end

        -- if have target, lock
        if currentTarget then
            lockOnTarget()
        end
    else
        -- clear lock if mouse up or aimbot disabled
        if not aimbotEnabled or not isRightMouseDown then
            currentTarget = nil
        end
    end

    -- update distance in GUI and globally
    if currentTarget and currentTarget.Character and findRootPart(currentTarget.Character) and LocalPlayer.Character and findRootPart(LocalPlayer.Character) then
        local dist = (findRootPart(LocalPlayer.Character).Position - findRootPart(currentTarget.Character).Position).Magnitude
        currentTargetDistance = math.floor(dist)
    else
        currentTargetDistance = "N/A"
    end

    -- sync GUI distance label if present
    if GUIrefs and GUIrefs.DistLabel then
        pcall(function()
            if type(currentTargetDistance) == "number" then
                GUIrefs.DistLabel.Text = "Distance: " .. tostring(currentTargetDistance) .. "m"
            else
                GUIrefs.DistLabel.Text = "Distance: N/A"
            end
        end)
    end
end)

-- ensure GUI toggles locally update internal state when clicked (connect their callbacks too)
do
    local ctrls = GUIrefs.Controls
    if ctrls then
        -- ESP toggle: ensure highlights reflect state
        if ctrls.esp and ctrls.esp.Toggle then
            ctrls.esp.Toggle.MouseButton1Click:Connect(function()
                -- read new state from button text
                local newState = tostring(ctrls.esp.Toggle.Text) == "On"
                espEnabled = newState
                applyESPStateToAll(espEnabled)
            end)
        end

        if ctrls.aimlock and ctrls.aimlock.Toggle then
            ctrls.aimlock.Toggle.MouseButton1Click:Connect(function()
                local newState = tostring(ctrls.aimlock.Toggle.Text) == "On"
                aimbotEnabled = newState
                -- update FOV circle visibility immediately
                if FOVCircle then
                    pcall(function() FOVCircle.Visible = aimbotEnabled end)
                end
            end)
        end

        if ctrls.headAim and ctrls.headAim.Toggle then
            ctrls.headAim.Toggle.MouseButton1Click:Connect(function()
                local newState = tostring(ctrls.headAim.Toggle.Text) == "On"
                headAimEnabled = newState
            end)
        end

        -- theme dropdown: ensure selecting applies theme immediately
        if ctrls.themeDrop and ctrls.themeDrop.Button then
            ctrls.themeDrop.Button.MouseButton1Click:Connect(function()
                -- dropdown cycles internally, we'll sync local index to its text
                local chosen = tostring(ctrls.themeDrop.Button.Text)
                for i, name in ipairs(themeNames) do
                    if name == chosen then
                        currentThemeIndex = i
                        break
                    end
                end
                -- apply immediately
                applyThemeImmediately()
            end)
        end

        -- FOV slider internal callback already wired in Part 1 -> just ensure external change updates FOVCircle
        if ctrls.fov and ctrls.fov.SetValue then
            -- if someone programmatically calls SetValue, we ensure global fov is updated too
            -- monkeypatch SetValue to also set global fov variable
            local originalSet = ctrls.fov.SetValue
            ctrls.fov.SetValue = function(v)
                fov = clamp(v, minFov, maxFov)
                originalSet(v)
                if FOVCircle then pcall(function() FOVCircle.Radius = fov end) end
            end
        end
    end
end

-- small API for external scripts to toggle features (keeps UI in sync)
_G.UniversalAimbot.ToggleESP = function(val)
    espEnabled = not not val
    applyESPStateToAll(espEnabled)
    if GUIrefs and GUIrefs.Controls and GUIrefs.Controls.esp and GUIrefs.Controls.esp.SetState then
        GUIrefs.Controls.esp.SetState(espEnabled)
    end
end

_G.UniversalAimbot.ToggleAimbot = function(val)
    aimbotEnabled = not not val
    if GUIrefs and GUIrefs.Controls and GUIrefs.Controls.aimlock and GUIrefs.Controls.aimlock.SetState then
        GUIrefs.Controls.aimlock.SetState(aimbotEnabled)
    end
    if FOVCircle then pcall(function() FOVCircle.Visible = aimbotEnabled end) end
end

_G.UniversalAimbot.ToggleHeadAim = function(val)
    headAimEnabled = not not val
    if GUIrefs and GUIrefs.Controls and GUIrefs.Controls.headAim and GUIrefs.Controls.headAim.SetState then
        GUIrefs.Controls.headAim.SetState(headAimEnabled)
    end
end

_G.UniversalAimbot.SetFOV = function(val)
    val = clamp(tonumber(val) or fov, minFov, maxFov)
    fov = val
    if GUIrefs and GUIrefs.Controls and GUIrefs.Controls.fov and GUIrefs.Controls.fov.SetValue then
        GUIrefs.Controls.fov.SetValue(val)
    end
    if FOVCircle then pcall(function() FOVCircle.Radius = fov end) end
end

-- clean-up when unloading: destroy GUI and restore Drawing objects
_G.UniversalAimbot.Cleanup = function()
    pcall(function()
        if GUIrefs and GUIrefs.ScreenGui and isInstanceAlive(GUIrefs.ScreenGui) then GUIrefs.ScreenGui:Destroy() end
        if FOVCircle and typeof(FOVCircle) == "userdata" then
            pcall(function() FOVCircle:Remove() end)
            FOVCircle = nil
        end
        -- remove all highlights
        for pl,h in pairs(highlightedPlayers) do
            pcall(function() if h and typeof(h)=="Instance" then h:Destroy() end end)
            highlightedPlayers[pl] = nil
        end
    end)
end

-- final immediate sync to make sure UI matches state
applyESPStateToAll(espEnabled)
applyThemeImmediately()
if FOVCircle then pcall(function() FOVCircle.Radius = fov; FOVCircle.Visible = aimbotEnabled end) end

--[[
    Universal Aimbot v3 - Part 3
    Author: C_mthe3rd Gaming
    Purpose:
      - Extra polish and advanced features
      - Prediction tuning (leading targets slightly)
      - Visibility checks (raycasting for walls/cover)
      - Save/load settings persistence
      - Reset button & tween animations
      - Final extended comments & documentation
    NOTE: This part assumes Part 1 + Part 2 are already loaded.
--]]

if not _G.UniversalAimbot or not _G.UniversalAimbot.GUI then
    error("Part 3 expected Part 1 & Part 2 to run first. Please run them in order.")
    return
end

-- === Services ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === References ===
local GUIrefs = _G.UniversalAimbot.GUI
local ctrls = GUIrefs.Controls

-- === Prediction Variables ===
local predictionEnabled = true
local predictionFactor = 0.125 -- how far ahead to lead shots (tweakable)
local predictionSlider = nil

-- === Visibility Check Variables ===
local visibilityCheck = true

-- === Settings Persistence ===
local savedSettings = {
    espEnabled = true,
    aimbotEnabled = false,
    headAimEnabled = false,
    fov = 120,
    themeIndex = 1,
    predictionFactor = predictionFactor,
    predictionEnabled = true,
    visibilityCheck = true
}
local saveFileName = "UniversalAimbotSettings.json"

-- === Helpers ===

local function safeRaycast(origin, dir, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignore or {}
    local result = workspace:Raycast(origin, dir, params)
    return result
end

-- check if target is visible from camera
local function isTargetVisible(targetPart)
    if not visibilityCheck or not targetPart then return true end
    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local result = safeRaycast(origin, dir, {LocalPlayer.Character})
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

-- apply prediction offset if enabled
local function getPredictedPosition(part)
    if not predictionEnabled then return part.Position end
    local hrp = part.Parent:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Velocity.Magnitude > 0.1 then
        return part.Position + (hrp.Velocity * predictionFactor)
    else
        return part.Position
    end
end

-- enhanced lock function with prediction + visibility
function lockOnTarget()
    if not currentTarget or not currentTarget.Character then return end
    local targetPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
    if targetPart and isTargetVisible(targetPart) then
        local predicted = getPredictedPosition(targetPart)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
    end
end

-- === Settings Persistence ===

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

-- === GUI Additions ===

-- Prediction toggle
local predictToggle = makeToggle("Prediction", true, 235, function(state)
    predictionEnabled = state
end)

-- Prediction factor slider
predictionSlider = makeSlider("Lead Factor", predictionFactor, 0.01, 0.25, 270, function(val)
    predictionFactor = val
end)

-- Visibility check toggle
local visToggle = makeToggle("Visibility Check", true, 305, function(state)
    visibilityCheck = state
end)

-- Reset button
local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.new(0, 120, 0, 25)
ResetButton.Position = UDim2.new(0, 10, 0, 340)
ResetButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
ResetButton.BorderSizePixel = 2
ResetButton.BorderColor3 = themeColor
ResetButton.Text = "Reset Settings"
ResetButton.Font = Enum.Font.SourceSansBold
ResetButton.TextSize = 16
ResetButton.TextColor3 = Color3.fromRGB(255,255,255)
ResetButton.Parent = GUIrefs.Frame

-- Reset behavior
ResetButton.MouseButton1Click:Connect(function()
    aimbotEnabled = false
    espEnabled = true
    headAimEnabled = false
    fov = 120
    currentThemeIndex = 1
    predictionEnabled = true
    predictionFactor = 0.125
    visibilityCheck = true
    ctrls.aimlock.SetState(aimbotEnabled)
    ctrls.esp.SetState(espEnabled)
    ctrls.headAim.SetState(headAimEnabled)
    ctrls.fov.SetValue(fov)
    if ctrls.themeDrop then ctrls.themeDrop.Button.Text = "Red" end
    predictToggle.SetState(predictionEnabled)
    predictionSlider.SetValue(predictionFactor)
    visToggle.SetState(visibilityCheck)
    saveSettings()
end)

-- Save/load button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0, 120, 0, 25)
SaveButton.Position = UDim2.new(0, 150, 0, 340)
SaveButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
SaveButton.BorderSizePixel = 2
SaveButton.BorderColor3 = themeColor
SaveButton.Text = "Save Settings"
SaveButton.Font = Enum.Font.SourceSansBold
SaveButton.TextSize = 16
SaveButton.TextColor3 = Color3.fromRGB(255,255,255)
SaveButton.Parent = GUIrefs.Frame

SaveButton.MouseButton1Click:Connect(saveSettings)

-- === Tween Animations ===

-- fade-in for main frame
GUIrefs.Frame.BackgroundTransparency = 1
TweenService:Create(GUIrefs.Frame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

-- pulse effect on minimize button
spawn(function()
    while wait(1) do
        if MinimizeButton and MinimizeButton.Parent then
            local tween1 = TweenService:Create(MinimizeButton, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(200,50,50)})
            local tween2 = TweenService:Create(MinimizeButton, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,255,255)})
            tween1:Play()
            tween1.Completed:Wait()
            tween2:Play()
        else
            break
        end
    end
end)

-- === Startup ===

-- load previous settings if file exists
loadSettings()

-- apply loaded settings to GUI
ctrls.esp.SetState(espEnabled)
ctrls.aimlock.SetState(aimbotEnabled)
ctrls.headAim.SetState(headAimEnabled)
ctrls.fov.SetValue(fov)
if ctrls.themeDrop then
    ctrls.themeDrop.Button.Text = themeNames[currentThemeIndex]
end
predictToggle.SetState(predictionEnabled)
predictionSlider.SetValue(predictionFactor)
visToggle.SetState(visibilityCheck)

-- Save automatically when toggles change
local function hookSave(toggle)
    if toggle and toggle.Toggle then
        toggle.Toggle.MouseButton1Click:Connect(function()
            saveSettings()
        end)
    end
end
hookSave(ctrls.esp)
hookSave(ctrls.aimlock)
hookSave(ctrls.headAim)
hookSave(predictToggle)
hookSave(visToggle)

-- Save when sliders change
if ctrls.fov then ctrls.fov.Slider.MouseButton1Up:Connect(saveSettings) end
if predictionSlider then predictionSlider.Slider.MouseButton1Up:Connect(saveSettings) end

-- === End of Part 3 ===
print("Universal Aimbot v3 fully loaded with all parts.")

--[[
    Universal Aimbot v3 - Part 4 (GUI rebuild & polish)
    Author: C_mthe3rd Gaming
    Purpose:
      - Rebuild CreateGui so GUI always shows and is self-contained
      - Fix slider knob movement, theme cycling, outline updates, credits visibility
      - Ensure buttons reflect current state (On/Off)
      - Hook UI <-> logic updates (esp, aimlock, head aim, FOV, theme)
--]]

-- Guard: require core parts to exist (we'll still try to continue gracefully)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ensure some globals exist (set defaults if missing)
espEnabled = (type(espEnabled) == "boolean") and espEnabled or true
aimbotEnabled = (type(aimbotEnabled) == "boolean") and aimbotEnabled or false
headAimEnabled = (type(headAimEnabled) == "boolean") and headAimEnabled or false
fov = (type(fov)=="number") and fov or 120
minFov = (type(minFov)=="number") and minFov or 50
maxFov = (type(maxFov)=="number") and maxFov or 500
highlightedPlayers = highlightedPlayers or {} -- table from earlier parts
themeNames = themeNames or {"Red","Blue","Orange","Green","Rainbow"}
currentThemeIndex = currentThemeIndex or 2

-- local theme mapping (kept here for GUI; uses getThemeColor if exists)
local themeMap = {
    Red = Color3.fromRGB(255,0,0),
    Blue = Color3.fromRGB(0,122,255),
    Orange = Color3.fromRGB(255,165,0),
    Green = Color3.fromRGB(0,255,0),
}

-- Utility: safe get theme color (prefer getThemeColor if provided by earlier parts)
local function theme_color_now()
    if type(getThemeColor) == "function" then
        return getThemeColor()
    end
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        local t = (tick() * 0.2) % 1
        return Color3.fromHSV(t, 1, 1)
    end
    return themeMap[name] or Color3.fromRGB(0,122,255)
end

-- Remove any old GUI we created before to prevent duplicates
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

-- Root ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Main frame (we'll make it draggable via script for smoothness)
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 320, 0, 360)
Frame.Position = UDim2.new(1, -340, 0, 80)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = theme_color_now()
Frame.Parent = ScreenGui
Frame.ZIndex = 2
Frame.Active = true

-- TitleBar container (transparent background to capture input)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 34)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Frame
TitleBar.ZIndex = 3

-- Title label (left)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Universal Aimbot v2"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar
TitleLabel.ZIndex = 4

-- Credits label (bottom-left of frame)
local Credits = Instance.new("TextLabel")
Credits.Name = "Credits"
Credits.Size = UDim2.new(0.6, 0, 0, 16)
Credits.Position = UDim2.new(0, 10, 1, -22)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180,180,180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 13
Credits.Parent = Frame
Credits.ZIndex = 3

-- Right-side minimize button (separate so it doesn't overlap title)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 48, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -56, 0, 6)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.BorderColor3 = theme_color_now()
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 18
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.Parent = TitleBar
MinimizeBtn.ZIndex = 5

-- Container for content
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -34)
Content.Position = UDim2.new(0, 0, 0, 34)
Content.BackgroundTransparency = 1
Content.Parent = Frame
Content.ZIndex = 2

-- Helper: create labeled button (shows on/off)
local function makeToggleLabel(parent, text, y, initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 28)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = theme_color_now()
    btn.Text = text .. ": " .. (initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent

    -- small status label on right side
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 60, 1, 0)
    status.Position = UDim2.new(1, -72, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = (initial and "On" or "Off")
    status.Font = Enum.Font.SourceSansBold
    status.TextSize = 14
    status.TextColor3 = initial and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    status.Parent = btn

    return btn, status
end

-- Helper: create simple button (for reset/save)
local function makeSmallButton(parent, text, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 26)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = theme_color_now()
    btn.Text = text
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

-- Helper: create slider with movable white knob
local function makeSlider(parent, labelText, y, minVal, maxVal, initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 200, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(math.floor(initialVal))
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Content

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 260, 0, 14)
    bar.Position = UDim2.new(0, 12, 0, y + 22)
    bar.BackgroundColor3 = Color3.fromRGB(42,42,42)
    bar.BorderSizePixel = 1
    bar.BorderColor3 = theme_color_now()
    bar.Parent = Content

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = theme_color_now()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("ImageLabel")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundTransparency = 1
    knob.Image = ""
    knob.Parent = bar

    -- create white circular knob using a Frame overlay
    local knobWhite = Instance.new("Frame", bar)
    knobWhite.Size = UDim2.new(0, 12, 0, 12)
    knobWhite.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knobWhite.AnchorPoint = Vector2.new(0.5, 0.5)
    knobWhite.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knobWhite.BorderSizePixel = 0
    local corner = Instance.new("UICorner", knobWhite)
    corner.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knobWhite.Position = UDim2.new(rel, 0, 0.5, 0)
        local value = minVal + rel * (maxVal - minVal)
        lbl.Text = labelText .. ": " .. tostring(math.floor(value))
        return value
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local val = setFromX(input.Position.X)
            return val
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local val = setFromX(input.Position.X)
        end
    end)

    -- initially return a setter so code can update slider when fov changes externally
    local obj = {
        Label = lbl,
        Bar = bar,
        Fill = fill,
        Knob = knobWhite,
        SetValue = function(v)
            local rel = (v - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knobWhite.Position = UDim2.new(rel, 0, 0.5, 0)
            lbl.Text = labelText .. ": " .. tostring(math.floor(v))
        end,
        GetValue = function()
            local rel = fill.Size.X.Scale
            return minVal + rel * (maxVal - minVal)
        end
    }
    return obj
end

-- create toggles & controls (using helpers)
local ESPBtn, ESPStatus = makeToggleLabel(Content, "ESP", 8, espEnabled)
local AimBtn, AimStatus = makeToggleLabel(Content, "Aimlock", 46, aimbotEnabled)
local HeadBtn, HeadStatus = makeToggleLabel(Content, "Head Aim", 84, headAimEnabled)

-- Theme button (cycles)
local ThemeBtn = makeSmallButton(Content, "Theme: "..(themeNames[currentThemeIndex] or "Blue"), 12, 122)

-- FOV slider (with knob)
local FOVSlider = makeSlider(Content, "FOV Circle", 150, minFov, maxFov, fov)

-- Distance indicator inside GUI (also keep external distance label if present)
local DistanceUI = Instance.new("TextLabel")
DistanceUI.Size = UDim2.new(0, 180, 0, 20)
DistanceUI.Position = UDim2.new(0, 12, 0, 250)
DistanceUI.BackgroundTransparency = 1
DistanceUI.Text = "Distance: N/A"
DistanceUI.Font = Enum.Font.SourceSans
DistanceUI.TextSize = 14
DistanceUI.TextColor3 = Color3.fromRGB(255,255,255)
DistanceUI.TextXAlignment = Enum.TextXAlignment.Left
DistanceUI.Parent = Content

-- Reset & Save buttons
local ResetBtn = makeSmallButton(Content, "Reset Settings", 12, 280)
local SaveBtn = makeSmallButton(Content, "Save Settings", 156, 280)

-- Make sure the minimize button toggles content and hides credits
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Credits.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0, 320, 0, 34) or UDim2.new(0, 320, 0, 360)
    MinimizeBtn.Text = minimized and "+" or "—"
end)

-- Toggle behaviors (update underlying flags & button labels)
ESPBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPBtn.Text = "ESP: " .. (espEnabled and "On" or "Off")
    ESPStatus.Text = (espEnabled and "On" or "Off")
    ESPStatus.TextColor3 = espEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    -- update existing highlights immediately
    for _, hl in pairs(highlightedPlayers) do
        if hl and typeof(hl) == "Instance" then
            pcall(function() hl.Enabled = espEnabled end)
        end
    end
end)

AimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = "Aimlock: " .. (aimbotEnabled and "On" or "Off")
    AimStatus.Text = (aimbotEnabled and "On" or "Off")
    AimStatus.TextColor3 = aimbotEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    -- FOV circle visibility handled in RenderStepped
end)

HeadBtn.MouseButton1Click:Connect(function()
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = "Head Aim: " .. (headAimEnabled and "On" or "Off")
    HeadStatus.Text = (headAimEnabled and "On" or "Off")
    HeadStatus.TextColor3 = headAimEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

-- Theme cycling
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = (currentThemeIndex % #themeNames) + 1
    local tn = themeNames[currentThemeIndex]
    ThemeBtn.Text = "Theme: " .. tn
    -- apply color across GUI immediately
    local c = theme_color_now()
    Frame.BorderColor3 = c
    MinimizeBtn.BorderColor3 = c
    ResetBtn.BorderColor3 = c
    SaveBtn.BorderColor3 = c
    ThemeBtn.BorderColor3 = c
    -- update slider fill color
    FOVSlider.Fill.BackgroundColor3 = c
    -- update highlights
    for _, hl in pairs(highlightedPlayers) do
        if hl and typeof(hl) == "Instance" then
            pcall(function()
                hl.FillColor = c
                hl.OutlineColor = c
            end)
        end
    end
    -- update FOV circle color
    if FOVCircle then
        pcall(function() FOVCircle.Color = c end)
    end
end)

-- Hook for Save/Reset (if earlier parts implement save, these can call them)
ResetBtn.MouseButton1Click:Connect(function()
    -- Reset to defaults
    espEnabled = true
    aimbotEnabled = false
    headAimEnabled = false
    fov = 120
    currentThemeIndex = 2 -- Blue
    -- update UI
    ESPBtn.Text = "ESP: On"; ESPStatus.Text = "On"; ESPStatus.TextColor3 = Color3.fromRGB(100,255,100)
    AimBtn.Text = "Aimlock: Off"; AimStatus.Text = "Off"; AimStatus.TextColor3 = Color3.fromRGB(255,100,100)
    HeadBtn.Text = "Head Aim: Off"; HeadStatus.Text = "Off"; HeadStatus.TextColor3 = Color3.fromRGB(255,100,100)
    ThemeBtn.Text = "Theme: "..(themeNames[currentThemeIndex] or "Blue")
    FOVSlider.SetValue(fov)
    -- update highlights / FOV circle
    local c = theme_color_now()
    for _,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl) == "Instance" then
            pcall(function() hl.FillColor = c; hl.OutlineColor = c; hl.Enabled = espEnabled end)
        end
    end
    if FOVCircle then pcall(function() FOVCircle.Radius = fov; FOVCircle.Color = c; FOVCircle.Visible = aimbotEnabled end) end
end)

-- Save button: tries to call an existing save function if present, else just toggles border color as feedback
SaveBtn.MouseButton1Click:Connect(function()
    -- try to call external save function (from Part 3), otherwise flash the button
    if type(saveSettings) == "function" then
        pcall(saveSettings)
    else
        local orig = SaveBtn.BackgroundColor3
        TweenService:Create(SaveBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,120,70)}):Play()
        task.delay(0.2, function()
            pcall(function() SaveBtn.BackgroundColor3 = orig end)
        end)
    end
end)

-- Dragging the GUI (smooth lerp)
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

RunService.RenderStepped:Connect(function()
    if targetPos then
        Frame.Position = Frame.Position:Lerp(targetPos, 0.25)
    end
    -- Update dynamic parts every frame:
    local currentThemeColor = theme_color_now()
    Frame.BorderColor3 = currentThemeColor
    MinimizeBtn.BorderColor3 = currentThemeColor
    ResetBtn.BorderColor3 = currentThemeColor
    SaveBtn.BorderColor3 = currentThemeColor
    ThemeBtn.BorderColor3 = currentThemeColor
    -- Update slider fill color if theme changes (smooth)
    FOVSlider.Fill.BackgroundColor3 = currentThemeColor

    -- Update FOV circle radius/color/visibility
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = fov
            FOVCircle.Color = currentThemeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- Update credits color (slightly dim)
    Credits.TextColor3 = Color3.fromRGB(180,180,180)

    -- Update per-frame distance display (uses currentTarget from earlier parts)
    if typeof(currentTarget) == "Instance" and currentTarget and currentTarget.Character and findRootPart(currentTarget.Character) and LocalPlayer.Character and findRootPart(LocalPlayer.Character) then
        local dist = (findRootPart(LocalPlayer.Character).Position - findRootPart(currentTarget.Character).Position).Magnitude
        DistanceUI.Text = "Distance: "..tostring(math.floor(dist)).."m"
    else
        DistanceUI.Text = "Distance: N/A"
    end
end)

-- Ensure highlightedPlayers is kept updated if players respawn or rejoin (safe hookup)
Players.PlayerAdded:Connect(function(pl)
    -- after character loads, create highlight
    pl.CharacterAdded:Connect(function()
        task.wait(0.35)
        if type(setupHighlight) == "function" then
            pcall(function() setupHighlight(pl) end)
        else
            -- best-effort fallback: wait then try to create highlight if table present
            task.wait(0.2)
        end
    end)
end)
Players.PlayerRemoving:Connect(function(pl)
    if highlightedPlayers and highlightedPlayers[pl] then
        pcall(function() highlightedPlayers[pl]:Destroy() end)
        highlightedPlayers[pl] = nil
    end
end)

-- Make GUI visible immediately with a small intro tween
Frame.BackgroundTransparency = 1
TweenService:Create(Frame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

-- Final log
print("[UniversalAimbot] Part 4 GUI created successfully.")

-- End of Part 4



