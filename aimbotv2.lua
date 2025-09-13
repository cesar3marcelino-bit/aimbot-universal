--[[ 
    Universal Aimbot v2 - Part 1
    Fully working, polished, Roblox-ready
    Features: Aimlock, Head Aim, ESP, FOV Circle, Rainbow Theme, Draggable GUI, Minimize, Slider
    Author: C_mthe3rd Gaming
]]

-- ===== SETTINGS =====
local teamCheck = false
local fov = 120
local minFov = 50
local maxFov = 500
local lockPart = "HumanoidRootPart"
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local currentTarget = nil
local currentTargetDistance = "N/A"
local currentTheme = "Blue" -- default theme
local highlightedPlayers = {}
local rainbowIndex = 0

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===== DRAW FOV CIRCLE =====
local FOVCircle
pcall(function()
    if Drawing then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 100
        FOVCircle.Filled = false
        FOVCircle.Radius = fov
        FOVCircle.Visible = false
        FOVCircle.Color = Color3.fromRGB(0,122,255)
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end)

-- ===== UTILITY FUNCTIONS =====
local function findRootPart(character)
    if not character then return nil end
    local parts = {"HumanoidRootPart","LowerTorso","UpperTorso","Torso"}
    for _,p in ipairs(parts) do
        local part = character:FindFirstChild(p)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

-- ===== ESP HIGHLIGHT =====
local function removeHighlight(player)
    if highlightedPlayers[player] then
        pcall(function() highlightedPlayers[player]:Destroy() end)
        highlightedPlayers[player] = nil
    end
end

local function setupHighlight(player, character)
    if player == LocalPlayer then return end
    if not character or not character.Parent then return end
    local root = findRootPart(character)
    if not root then
        task.delay(0.5,function()
            if player.Character then setupHighlight(player, player.Character) end
        end)
        return
    end
    removeHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(0,122,255)
    highlight.OutlineColor = Color3.fromRGB(0,122,255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = espEnabled
    highlight.Parent = character
    highlightedPlayers[player] = highlight

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            task.wait(0.1)
            if player.Character then setupHighlight(player, player.Character) end
        end)
    end
end

local function createHighlight(player)
    if player == LocalPlayer then return end
    if player.Character then setupHighlight(player, player.Character) end
    player.CharacterAdded:Connect(function(character)
        task.wait(0.4)
        setupHighlight(player, character)
    end)
end

for _,p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(removeHighlight)

--[[ 
    Universal Aimbot v2 - Part 2
    Features: Target selection, aimlock, FOV circle, theme/rainbow cycling, ESP updates
]]

-- ===== TARGET SELECTION =====
local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Camera.ViewportSize/2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local playerPos = localRoot and localRoot.Position or Vector3.new(0,0,0)

    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = headAimEnabled and player.Character:FindFirstChild("Head") or findRootPart(player.Character)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if targetPart and humanoid and humanoid.Health>0 then
                local distanceFromPlayer = (playerPos - targetPart.Position).Magnitude
                local screenPoint,onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local distanceOnScreen = (Vector2.new(screenPoint.X,screenPoint.Y)-screenCenter).Magnitude
                if onScreen and distanceOnScreen<shortestDistance and distanceOnScreen<=fov then
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

-- ===== AIMLOCK =====
local function lockOnTarget()
    if currentTarget and currentTarget ~= LocalPlayer and currentTarget.Character then
        local targetPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
        if targetPart then
            local targetVel = targetPart.Velocity or Vector3.new(0,0,0)
            local prediction = math.clamp(0.05+(currentTargetDistance/2000),0.02,0.1)
            local predictedPos = targetPart.Position + (targetVel*prediction)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,predictedPos),0.2)
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end

-- ===== RENDER LOOP =====
RunService.RenderStepped:Connect(function()
    -- ===== THEME & RAINBOW CYCLING =====
    if currentTheme=="Rainbow" then
        rainbowIndex = (tick()*0.2)%1
        local newColor = Color3.fromHSV(rainbowIndex,1,1)
        for _,hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then
                pcall(function()
                    hl.FillColor = newColor
                    hl.OutlineColor = newColor
                end)
            end
        end
        if FOVCircle then pcall(function() FOVCircle.Color=newColor end) end
    else
        local colorMap = {
            Red=Color3.fromRGB(255,0,0),
            Blue=Color3.fromRGB(0,122,255),
            Orange=Color3.fromRGB(255,165,0),
            Yellow=Color3.fromRGB(255,255,0),
            Green=Color3.fromRGB(0,255,0),
            Purple=Color3.fromRGB(128,0,128)
        }
        local themeColor = colorMap[currentTheme] or Color3.fromRGB(0,122,255)
        for _,hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then
                pcall(function()
                    hl.FillColor = themeColor
                    hl.OutlineColor = themeColor
                end)
            end
        end
        if FOVCircle then pcall(function() FOVCircle.Color=themeColor end) end
    end

    -- ===== FOV CIRCLE =====
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- ===== ESP ENABLED/DISABLED =====
    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and highlightedPlayers[player] then
            pcall(function()
                highlightedPlayers[player].Enabled = espEnabled
            end)
        end
    end

    -- ===== AIMLOCK ACTIVATION =====
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget=getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget=nil
    end
end)

-- ===== PART 3: GUI CREATION & BUTTONS (No createGUI call at end) =====
-- Function to create the main GUI
function createGUI()
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then game.CoreGui.Aimlock_GUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Main frame
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 260, 0, 300)
    Frame.Position = UDim2.new(1, -280, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 2
    Frame.Active = true

    -- Title bar
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1, 0, 0, 28)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1, -28, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize button
    local MinButton = Instance.new("TextButton", TitleBar)
    MinButton.Size = UDim2.new(0, 28, 0, 28)
    MinButton.Position = UDim2.new(1, -28, 0, 0)
    MinButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MinButton.BorderSizePixel = 1
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinButton.TextScaled = true

    -- Content frame (all buttons go here)
    local Content = Instance.new("Frame", Frame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -28)
    Content.Position = UDim2.new(0, 0, 0, 28)
    Content.BackgroundTransparency = 1

    -- Credits label
    local CreditsLabel = Instance.new("TextLabel", Frame)
    CreditsLabel.Size = UDim2.new(1, -10, 0, 16)
    CreditsLabel.Position = UDim2.new(0, 10, 1, -20)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14

    -- ===== Button helper =====
    local function createButton(name, yPos, callback)
        local btn = Instance.new("TextButton", Content)
        btn.Size = UDim2.new(1, -20, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BorderSizePixel = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Buttons
    local ESPButton = createButton("ESP: On", 0, function()
        espEnabled = not espEnabled
        ESPButton.Text = "ESP: "..(espEnabled and "On" or "Off")
        for _, hl in pairs(highlightedPlayers) do
            if hl then hl.Enabled = espEnabled end
        end
    end)

    local AimlockButton = createButton("Aimlock: Off", 40, function()
        aimbotEnabled = not aimbotEnabled
        AimlockButton.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
    end)

    local HeadAimButton = createButton("Head Aim: Off", 80, function()
        headAimEnabled = not headAimEnabled
        HeadAimButton.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
    end)

    -- Theme button & cycle
    local themeNames = {"Red", "Blue", "Orange", "Green", "Rainbow"}
    local currentThemeIndex = 2
    local themeColor = Color3.fromRGB(0, 122, 255)
    local ThemeButton = createButton("Theme: "..themeNames[currentThemeIndex], 120, function()
        currentThemeIndex = currentThemeIndex % #themeNames + 1
        ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]
        local map = {
            Red = Color3.fromRGB(255, 0, 0),
            Blue = Color3.fromRGB(0, 122, 255),
            Orange = Color3.fromRGB(255, 165, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Rainbow = Color3.fromHSV(tick()%1,1,1)
        }
        themeColor = map[themeNames[currentThemeIndex]]
    end)

    -- ===== FOV Circle Slider =====
    local SliderLabel = Instance.new("TextLabel", Content)
    SliderLabel.Size = UDim2.new(1, -20, 0, 16)
    SliderLabel.Position = UDim2.new(0, 10, 0, 160)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "FOV Circle: "..math.floor(fov)
    SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SliderLabel.Font = Enum.Font.SourceSans
    SliderLabel.TextSize = 14

    local FOVSlider = Instance.new("Frame", Content)
    FOVSlider.Size = UDim2.new(1, -20, 0, 16)
    FOVSlider.Position = UDim2.new(0, 10, 0, 180)
    FOVSlider.BackgroundColor3 = themeColor
    FOVSlider.BorderSizePixel = 1

    local SliderHandle = Instance.new("Frame", FOVSlider)
    SliderHandle.Size = UDim2.new((fov-minFov)/(maxFov-minFov), 0, 1, 0)
    SliderHandle.Position = UDim2.new(0,0,0,0)
    SliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    local dragging, dragInput, dragStart, startSize = false,nil,nil,nil
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
    SliderHandle.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input==dragInput then
            local delta = input.Position.X - dragStart.X
            local newScale = math.clamp(startSize.X.Scale + delta/FOVSlider.AbsoluteSize.X, 0, 1)
            SliderHandle.Size = UDim2.new(newScale,0,1,0)
            fov = minFov + (maxFov-minFov)*newScale
            SliderLabel.Text = "FOV Circle: "..math.floor(fov)
        end
    end)

    -- ===== Draggable GUI =====
    local draggingFrame, dragInputFrame, dragStartFrame, startPosFrame = false,nil,nil,nil
    local function updateInput(input)
        local delta = input.Position - dragStartFrame
        Frame.Position = UDim2.new(startPosFrame.X.Scale, startPosFrame.X.Offset+delta.X,
                                   startPosFrame.Y.Scale, startPosFrame.Y.Offset+delta.Y)
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
        if draggingFrame and input==dragInputFrame then updateInput(input) end
    end)

    -- ===== Minimize button =====
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,300)
        CreditsLabel.Visible = not minimized
    end)
end

-- ===== PART 4: ESP, AIMLOCK, RENDER LOOP & FINAL POLISH =====

-- Function to set up ESP highlight for a character
local function setupHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char.Parent then return end
    local rootPart = findRootPart(char)
    if not rootPart then
        -- Retry if root missing
        task.delay(0.5,function() setupHighlight(player) end)
        return
    end
    removeHighlight(player)
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = themeColor
    hl.OutlineColor = themeColor
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.3
    hl.Enabled = espEnabled
    hl.Parent = char
    highlightedPlayers[player] = hl

    -- Handle respawn
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            task.wait(0.1)
            if player.Character then setupHighlight(player) end
        end)
    end
end

-- Initialize ESP for current players
for _, p in ipairs(Players:GetPlayers()) do setupHighlight(p) end

-- Handle player joins and leaves
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.4)
        setupHighlight(player)
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

-- Get closest target in FOV
local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local playerPos = localRoot and localRoot.Position or Vector3.new()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = headAimEnabled and player.Character:FindFirstChild("Head") or findRootPart(player.Character)
            local hum = player.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health>0 then
                local distWorld = (playerPos-part.Position).Magnitude
                local screenPoint,onScreen = Camera:WorldToViewportPoint(part.Position)
                local distScreen = (Vector2.new(screenPoint.X,screenPoint.Y)-screenCenter).Magnitude
                if onScreen and distScreen<shortest and distScreen<=fov then
                    if not teamCheck or player.Team ~= LocalPlayer.Team then
                        closest = player
                        shortest = distScreen
                        currentTargetDistance = math.floor(distWorld)
                    end
                end
            end
        end
    end
    return closest
end

-- Lock camera smoothly
local function lockOnTarget()
    if currentTarget and currentTarget.Character then
        local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
        if part then
            local pred = part.Position + (part.Velocity or Vector3.new())*math.clamp(0.05 + currentTargetDistance/2000,0.02,0.1)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,pred),0.2)
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end

-- ===== MAIN RENDER LOOP =====
RunService.RenderStepped:Connect(function()
    -- Update theme colors
    if themeNames[currentThemeIndex]=="Rainbow" then
        rainbowIndex = (tick()*0.2)%1
        themeColor = Color3.fromHSV(rainbowIndex,1,1)
    else
        local map = {Red=Color3.fromRGB(255,0,0), Blue=Color3.fromRGB(0,122,255), Orange=Color3.fromRGB(255,165,0), Green=Color3.fromRGB(0,255,0)}
        themeColor = map[themeNames[currentThemeIndex]] or Color3.fromRGB(0,122,255)
    end

    -- Update ESP colors dynamically
    for _, hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
                hl.Enabled = espEnabled
            end)
        end
    end

    -- Update FOV circle
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- Aimlock logic
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)

-- Finally, call GUI creation
createGUI()
