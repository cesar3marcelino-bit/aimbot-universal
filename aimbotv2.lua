--[[ 
Script created by C_mthe3rd gaming
Discord: iliketrains9999
Polished Version: Everything fixed
]]

-- ===== Settings =====
local teamCheck = false
local fov = 120
local minFov = 50
local maxFov = 500
local lockPart = "HumanoidRootPart"
local aimbotEnabled = false
local espEnabled = true
local headAimEnabled = false
local currentTarget = nil
local currentTargetDistance = "N/A"
local themeMode = 2
local themeColor = Color3.fromRGB(0,122,255)
local rainbowEnabled = false
local rainyEnabled = false

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===== Highlight storage =====
local highlightedPlayers = {}

-- ===== Drawing FOV Circle =====
local DrawingAvailable, DrawingAPI = pcall(function() return Drawing end)
local FOVCircle = nil
if DrawingAvailable and type(DrawingAPI) == "table" then
    local ok, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Thickness = 2
        c.NumSides = 100
        c.Filled = false
        c.Radius = fov
        c.Visible = false
        c.Color = themeColor
        c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        return c
    end)
    if ok then FOVCircle = circle end
end

-- ===== Utility: find root part =====
local function findRootPart(character)
    if not character then return nil end
    local names = {"HumanoidRootPart", "LowerTorso", "UpperTorso", "Torso"}
    for _, n in ipairs(names) do
        local p = character:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return nil
end

-- ===== Remove / setup highlight =====
local function removeHighlight(player)
    if highlightedPlayers[player] then
        pcall(function() highlightedPlayers[player]:Destroy() end)
        highlightedPlayers[player] = nil
    end
end

local function setupHighlightForCharacter(player, character)
    if player == LocalPlayer then return end
    if not character or not character.Parent then return end
    local root = findRootPart(character)
    if not root then
        task.delay(0.5, function()
            if player and player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
        return
    end
    removeHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = themeColor
    highlight.OutlineColor = themeColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = espEnabled
    highlight.Parent = character
    highlightedPlayers[player] = highlight
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            task.wait(0.1)
            if player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
    end
end

local function createHighlight(player)
    if player == LocalPlayer then return end
    if player.Character then setupHighlightForCharacter(player, player.Character) end
    player.CharacterAdded:Connect(function(character)
        task.wait(0.4)
        setupHighlightForCharacter(player, character)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(removeHighlight)

-- ===== Target selection & lock =====
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

-- ===== Main render loop =====
RunService.RenderStepped:Connect(function()
    -- update theme color (handles rainbow)
    local newTheme
    if themeMode == 1 then newTheme = Color3.fromRGB(255,0,0); rainbowEnabled=false; rainyEnabled=false
    elseif themeMode == 2 then newTheme = Color3.fromRGB(0,122,255); rainbowEnabled=false; rainyEnabled=false
    elseif themeMode == 3 then newTheme = Color3.fromHSV(tick()*0.2%1,1,1); rainbowEnabled=true; rainyEnabled=false
    elseif themeMode == 4 then newTheme = Color3.fromRGB(140,160,185); rainbowEnabled=false; rainyEnabled=true
    else newTheme = Color3.fromRGB(0,122,255); rainbowEnabled=false; rainyEnabled=false end
    if newTheme ~= themeColor then
        themeColor = newTheme
        for _, hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then pcall(function() hl.FillColor = themeColor; hl.OutlineColor = themeColor end) end
        end
    end

    -- update FOV circle
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- Ensure highlights exist/are updated
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and highlightedPlayers[player] then
            pcall(function()
                highlightedPlayers[player].Enabled = espEnabled
                highlightedPlayers[player].FillColor = themeColor
                highlightedPlayers[player].OutlineColor = themeColor
            end)
        end
    end

    -- Aimbot
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)

-- ===== GUI =====
local function createGUI()
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then game.CoreGui.Aimlock_GUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0,260,0,300)
    Frame.Position = UDim2.new(1,-280,0,80)
    Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Frame.BorderSizePixel = 2
    Frame.BorderColor3 = themeColor
    Frame.Active = true

    local Content = Instance.new("Frame", Frame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1,0,1,-28)
    Content.Position = UDim2.new(0,0,0,28)
    Content.BackgroundTransparency = 1

    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,28)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1,-10,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local CreditsLabel = Instance.new("TextLabel", Frame)
    CreditsLabel.Size = UDim2.new(1,-10,0,16)
    CreditsLabel.Position = UDim2.new(0,10,0,28)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextScaled = false
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14
end

-- ===== Minimize Button =====
local minimized = false
local MinButton = Instance.new("TextButton")
MinButton.Size = UDim2.new(0,28,0,28)
MinButton.Position = UDim2.new(1,-28,0,0)
MinButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
MinButton.BorderSizePixel = 1
MinButton.BorderColor3 = themeColor
MinButton.Text = "_"
MinButton.TextColor3 = Color3.fromRGB(255,255,255)
MinButton.TextScaled = true
MinButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,300)
end)

-- ===== Draggable GUI =====
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updateInput(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateInput(input) end
end)

-- ===== Clouds & Rain Layer =====
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

local cloudA = createCloud(0, 8, 120, 36)
local cloudB = createCloud(200, 2, 160, 48)
local cloudC = createCloud(400, 12, 110, 34)

-- Spawn clouds and rain continuously
spawn(function()
    while true do
        if rainyEnabled then
            -- spawn raindrops
            local drop = Instance.new("Frame", RainLayer)
            drop.Size = UDim2.new(0,2,0,10)
            drop.Position = UDim2.new(0, math.random(4, Frame.AbsoluteSize.X-4), 0, -20)
            drop.BackgroundColor3 = Color3.fromRGB(200,220,255)
            drop.BorderSizePixel = 0
            drop.ZIndex = 1
            local tween = TweenService:Create(drop, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Position=UDim2.new(0, drop.Position.X.Offset, 0, Frame.AbsoluteSize.Y+30)})
            tween:Play()
            tween.Completed:Connect(function() pcall(function() drop:Destroy() end) end)
        end
        task.wait(0.04)
    end
end)

-- Call GUI creator
createGUI()
