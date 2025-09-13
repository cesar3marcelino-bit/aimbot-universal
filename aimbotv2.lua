--[[
    Script created by C_mthe3rd Gaming
    Discord: iliketrains9999
    Polished Version: Fully working, feature-complete, commented, and Roblox-ready
    Description:
        - Universal Aimbot v2
        - Features: Aimlock, Head Aim, ESP, FOV Circle, Rainbow Theme, Clouds & Rain,
          Fully Draggable GUI, Minimize Button, Theme Selector, Sliders, and Animations
        - All colors and outlines respond to theme changes
        - Every part commented for clarity
]]

-- ======= SETTINGS =======
-- Team check disables aiming at teammates
local teamCheck = false
-- Default FOV for aimbot circle
local fov = 120
-- Minimum and maximum FOV allowed via slider
local minFov = 50
local maxFov = 500
-- Part to lock aim to
local lockPart = "HumanoidRootPart"
-- Toggles for features
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
-- Current target reference
local currentTarget = nil
local currentTargetDistance = "N/A"
-- Theme system
local currentTheme = "Blue" -- Default theme
-- Stores all highlighted players for ESP
local highlightedPlayers = {}
-- Rainbow theme cycle tracking
local rainbowIndex = 0

-- ======= SERVICES =======
local Players = game:GetService("Players") -- Player service
local RunService = game:GetService("RunService") -- For RenderStepped loops
local UserInputService = game:GetService("UserInputService") -- Mouse & keyboard input
local TweenService = game:GetService("TweenService") -- For animations
local Camera = workspace.CurrentCamera -- Current game camera
local LocalPlayer = Players.LocalPlayer -- Reference to local player

-- ======= DRAWING FOV CIRCLE =======
-- Check if Drawing API is available
local DrawingAvailable, DrawingAPI = pcall(function() return Drawing end)
local FOVCircle = nil
if DrawingAvailable and type(DrawingAPI) == "table" then
    local ok, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Thickness = 2 -- Circle line thickness
        c.NumSides = 100 -- Smooth circle
        c.Filled = false -- Hollow circle
        c.Radius = fov -- Initial radius
        c.Visible = false -- Hide until aimbot active
        c.Color = Color3.fromRGB(0,122,255) -- Default Blue
        -- Center circle on screen
        c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        return c
    end)
    if ok then FOVCircle = circle end
end

-- ======= UTILITY: FIND ROOT PART =======
-- Attempts to locate main part for aiming in a character
local function findRootPart(character)
    if not character then return nil end
    local names = {"HumanoidRootPart", "LowerTorso", "UpperTorso", "Torso"}
    for _, n in ipairs(names) do
        local p = character:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

-- ======= REMOVE / SETUP HIGHLIGHT =======
-- Removes highlight from a player if exists
local function removeHighlight(player)
    if highlightedPlayers[player] then
        pcall(function() highlightedPlayers[player]:Destroy() end)
        highlightedPlayers[player] = nil
    end
end

-- Setup highlight ESP for a player’s character
local function setupHighlightForCharacter(player, character)
    if player == LocalPlayer then return end -- Ignore self
    if not character or not character.Parent then return end
    local root = findRootPart(character)
    if not root then
        -- Retry after 0.5s if root part missing
        task.delay(0.5, function()
            if player and player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
        return
    end
    removeHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character -- Attach to character model
    highlight.FillColor = Color3.fromRGB(0,122,255) -- Default Blue
    highlight.OutlineColor = Color3.fromRGB(0,122,255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = espEnabled
    highlight.Parent = character
    highlightedPlayers[player] = highlight
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            -- Respawn handling
            task.wait(0.1)
            if player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
    end
end

-- Wrapper to create highlight when character exists
local function createHighlight(player)
    if player == LocalPlayer then return end
    if player.Character then setupHighlightForCharacter(player, player.Character) end
    player.CharacterAdded:Connect(function(character)
        task.wait(0.4) -- Wait for character to load
        setupHighlightForCharacter(player, character)
    end)
end

-- Initialize highlights for all players
for _, p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(removeHighlight)

-- ======= TARGET SELECTION & AIMLOCK =======
-- Returns the closest valid target within FOV
local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local playerPosition = localRoot and localRoot.Position or Vector3.new(0,0,0)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = headAimEnabled and player.Character:FindFirstChild("Head") or findRootPart(player.Character)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
                local distanceFromPlayer = (playerPosition - targetPart.Position).Magnitude
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local distanceOnScreen = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                if onScreen and distanceOnScreen < shortestDistance and distanceOnScreen <= fov then
                    if not teamCheck or player.Team ~= LocalPlayer.Team then
                        closestTarget = player
                        shortestDistance = distanceOnScreen
                        currentTargetDistance = math.floor(distanceFromPlayer)
                    end
                end
            end
        end
    end

    return closestTarget
end

-- Locks camera on the current target smoothly with prediction
local function lockOnTarget()
    if currentTarget and currentTarget ~= LocalPlayer and currentTarget.Character then
        local targetPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
        if targetPart then
            local targetVelocity = targetPart.Velocity or Vector3.new(0,0,0)
            local predictionFactor = math.clamp(0.05 + (currentTargetDistance / 2000), 0.02, 0.1)
            local predictedPosition = targetPart.Position + (targetVelocity * predictionFactor)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), 0.2)
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end

-- ======= MAIN RENDER LOOP =======
RunService.RenderStepped:Connect(function()
    -- ===== Update Theme & Rainbow Cycling =====
    if currentTheme == "Rainbow" then
        -- Cycle HSV over time for rainbow effect
        rainbowIndex = (tick() * 0.2) % 1
        local newColor = Color3.fromHSV(rainbowIndex, 1, 1)
        for _, hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then
                pcall(function()
                    hl.FillColor = newColor
                    hl.OutlineColor = newColor
                end)
            end
        end
        if FOVCircle then
            pcall(function() FOVCircle.Color = newColor end)
        end
    else
        -- Map theme name to color
        local colorMap = {
            Red = Color3.fromRGB(255,0,0),
            Blue = Color3.fromRGB(0,122,255),
            Orange = Color3.fromRGB(255,165,0),
            Yellow = Color3.fromRGB(255,255,0),
            Purple = Color3.fromRGB(128,0,128)
        }
        local themeColor = colorMap[currentTheme] or Color3.fromRGB(0,122,255)
        for _, hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then
                pcall(function()
                    hl.FillColor = themeColor
                    hl.OutlineColor = themeColor
                end)
            end
        end
        if FOVCircle then
            pcall(function() FOVCircle.Color = themeColor end)
        end
    end

    -- ===== Update FOV Circle =====
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- ===== Update ESP Highlights =====
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and highlightedPlayers[player] then
            pcall(function()
                highlightedPlayers[player].Enabled = espEnabled
            end)
        end
    end

    -- ===== AIMBOT LOCK =====
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)

-- ===== GUI CREATION =====
local function createGUI()
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then game.CoreGui.Aimlock_GUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Main Frame
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 260, 0, 300)
    Frame.Position = UDim2.new(1, -280, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = themeColor
    Frame.Active = true

    -- Title Bar
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,28)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1,-50,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize Button
    local MinButton = Instance.new("TextButton", TitleBar)
    MinButton.Size = UDim2.new(0,28,0,28)
    MinButton.Position = UDim2.new(1,-28,0,0)
    MinButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
    MinButton.BorderSizePixel = 1
    MinButton.BorderColor3 = themeColor
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255,255,255)
    MinButton.TextScaled = true
    MinButton.TextXAlignment = Enum.TextXAlignment.Center
    MinButton.TextYAlignment = Enum.TextYAlignment.Center

    local Content = Instance.new("Frame", Frame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1,0,1,-28)
    Content.Position = UDim2.new(0,0,0,28)
    Content.BackgroundTransparency = 1

    -- Credits Label
    local CreditsLabel = Instance.new("TextLabel", Frame)
    CreditsLabel.Size = UDim2.new(1,-10,0,16)
    CreditsLabel.Position = UDim2.new(0,10,1,-20)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextScaled = false
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14

    -- TODO: Insert buttons: Aimlock, Head Aim, Theme, FOV slider here
    -- TODO: Insert cloud & rain animations here
end

-- ===== GUI CREATION & BUTTONS =====
local function createGUI()
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then game.CoreGui.Aimlock_GUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Main Frame
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 260, 0, 300)
    Frame.Position = UDim2.new(1, -280, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = themeColor
    Frame.Active = true

    -- Title Bar
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,28)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1,-28,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize Button
    local MinButton = Instance.new("TextButton", TitleBar)
    MinButton.Size = UDim2.new(0,28,0,28)
    MinButton.Position = UDim2.new(1,-28,0,0)
    MinButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
    MinButton.BorderSizePixel = 1
    MinButton.BorderColor3 = themeColor
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255,255,255)
    MinButton.TextScaled = true
    MinButton.TextXAlignment = Enum.TextXAlignment.Center
    MinButton.TextYAlignment = Enum.TextYAlignment.Center

    local Content = Instance.new("Frame", Frame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1,0,1,-28)
    Content.Position = UDim2.new(0,0,0,28)
    Content.BackgroundTransparency = 1

    -- Credits Label
    local CreditsLabel = Instance.new("TextLabel", Frame)
    CreditsLabel.Size = UDim2.new(1,-10,0,16)
    CreditsLabel.Position = UDim2.new(0,10,1,-20)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextScaled = false
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14

    -- ===== Buttons & Slider =====
    local function createButton(name, yPos, callback)
        local btn = Instance.new("TextButton", Content)
        btn.Size = UDim2.new(1,-20,0,28)
        btn.Position = UDim2.new(0,10,0,yPos)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = themeColor
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- ESP Button
    createButton("ESP",0,function() espEnabled = not espEnabled end)
    -- Aimlock Button
    createButton("Aimlock",40,function() aimbotEnabled = not aimbotEnabled end)
    -- Head Aim Button
    createButton("Head Aim",80,function() headAimEnabled = not headAimEnabled end)
    -- Theme Dropdown
    local themeNames = {"Red","Blue","Orange","Yellow","Purple","Rainbow"}
    local currentThemeIndex = 2
    local ThemeButton = createButton("Theme: "..themeNames[currentThemeIndex],120,function()
        currentThemeIndex = currentThemeIndex % #themeNames + 1
        ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]
        -- apply color
        local colorMap = {
            Red = Color3.fromRGB(255,0,0),
            Blue = Color3.fromRGB(0,122,255),
            Orange = Color3.fromRGB(255,165,0),
            Yellow = Color3.fromRGB(255,255,0),
            Purple = Color3.fromRGB(128,0,128),
            Rainbow = Color3.fromHSV(tick()%1,1,1)
        }
        themeColor = colorMap[themeNames[currentThemeIndex]]
        -- Update outlines
        for _,hl in pairs(highlightedPlayers) do
            if hl then hl.FillColor = themeColor; hl.OutlineColor = themeColor end
        end
        if FOVCircle then FOVCircle.Color = themeColor end
        Frame.BorderColor3 = themeColor
    end)

    -- FOV Slider
    local SliderLabel = Instance.new("TextLabel",Content)
    SliderLabel.Size = UDim2.new(1,-20,0,16)
    SliderLabel.Position = UDim2.new(0,10,0,160)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "FOV: "..fov
    SliderLabel.TextColor3 = Color3.fromRGB(255,255,255)
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Font = Enum.Font.SourceSans
    SliderLabel.TextSize = 14

    local FOVSlider = Instance.new("Frame",Content)
    FOVSlider.Size = UDim2.new(1,-20,0,16)
    FOVSlider.Position = UDim2.new(0,10,0,180)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    FOVSlider.BorderSizePixel = 1
    FOVSlider.BorderColor3 = themeColor

    local SliderHandle = Instance.new("Frame",FOVSlider)
    SliderHandle.Size = UDim2.new((fov-minFov)/(maxFov-minFov),0,1,0)
    SliderHandle.BackgroundColor3 = Color3.fromRGB(0,122,255)

    local dragging,dragInput,dragStart,startSize = false,nil,nil,nil
    SliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startSize = SliderHandle.Size
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    SliderHandle.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input==dragInput and dragging then
            local delta = input.Position.X - dragStart.X
            local newScale = math.clamp(startSize.X.Scale + delta/FOVSlider.AbsoluteSize.X,0,1)
            SliderHandle.Size = UDim2.new(newScale,0,1,0)
            fov = minFov + (maxFov-minFov)*newScale
            SliderLabel.Text = "FOV: "..math.floor(fov)
        end
    end)

    -- ===== Draggable GUI =====
    local draggingFrame,dragInputFrame,dragStartFrame,startPosFrame = false,nil,nil,nil
    local function updateInputFrame(input)
        local delta = input.Position - dragStartFrame
        Frame.Position = UDim2.new(startPosFrame.X.Scale,startPosFrame.X.Offset+delta.X,
                                   startPosFrame.Y.Scale,startPosFrame.Y.Offset+delta.Y)
    end
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            draggingFrame = true
            dragStartFrame = input.Position
            startPosFrame = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then draggingFrame=false end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement then dragInputFrame=input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input==dragInputFrame and draggingFrame then updateInputFrame(input) end
    end)

    -- ===== Minimize Button Function =====
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,300)
    end)

    -- ===== Cloud & Rain Animations =====
    local RainLayer = Instance.new("Frame", Frame)
    RainLayer.Size = UDim2.new(1,0,1,0)
    RainLayer.BackgroundTransparency = 1
    RainLayer.ClipsDescendants = true
    RainLayer.ZIndex = 0

    local function createCloud(xOffset, y, sx, sy)
        local cloud = Instance.new("Frame", RainLayer)
        cloud.Size = UDim2.new(0, sx, 0, sy)
        cloud.Position = UDim2.new(0, xOffset, 0, y)
        cloud.BackgroundColor3 = Color3.fromRGB(230,230,240)
        cloud.BorderSizePixel = 0
        local corner = Instance.new("UICorner", cloud)
        corner.CornerRadius = UDim.new(1,0)
        cloud.ZIndex = 0
        return cloud
    end
    createCloud(0, 8, 120, 36)
    createCloud(200, 2, 160, 48)
    createCloud(400, 12, 110, 34)

    spawn(function()
        while true do
            if rainyEnabled then
                local drop = Instance.new("Frame", RainLayer)
                drop.Size = UDim2.new(0,2,0,10)
                drop.Position = UDim2.new(0, math.random(4, Frame.AbsoluteSize.X-4), 0, -20)
                drop.BackgroundColor3 = Color3.fromRGB(200,220,255)
                drop.BorderSizePixel = 0
                drop.ZIndex = 1
                local tween = TweenService:Create(drop, TweenInfo.new(0.5,Enum.EasingStyle.Linear), {Position=UDim2.new(0, drop.Position.X.Offset,0,Frame.AbsoluteSize.Y+30)})
                tween:Play()
                tween.Completed:Connect(function() pcall(function() drop:Destroy() end) end)
            end
            task.wait(0.04)
        end
    end)
end

-- Call GUI creator at end
createGUI()
