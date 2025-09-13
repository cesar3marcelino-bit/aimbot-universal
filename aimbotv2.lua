--[[ 
Script created by C_mthe3rd gaming
Discord: iliketrains9999
Polished Version: Fully fixed & working
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

Part 3: Targeting & Lock
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

-- ===== Main Render Loop =====
RunService.RenderStepped:Connect(function()
    -- Update theme
    local newTheme
    if themeMode == 1 then rainbowEnabled=false; rainyEnabled=false; newTheme=Color3.fromRGB(255,0,0)
    elseif themeMode==2 then rainbowEnabled=false; rainyEnabled=false; newTheme=Color3.fromRGB(0,122,255)
    elseif themeMode==3 then rainbowEnabled=true; rainyEnabled=false; local t=tick()*0.2; newTheme=Color3.fromHSV(t%1,1,1)
    elseif themeMode==4 then rainbowEnabled=false; rainyEnabled=true; newTheme=Color3.fromRGB(140,160,185)
    else rainbowEnabled=false; rainyEnabled=false; newTheme=Color3.fromRGB(0,122,255) end
    if newTheme ~= themeColor then
        themeColor = newTheme
        for _, hl in pairs(highlightedPlayers) do
            if hl and typeof(hl)=="Instance" then pcall(function() hl.FillColor=themeColor; hl.OutlineColor=themeColor end) end
        end
    end

    -- FOV Circle
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- Update highlights
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if (not highlightedPlayers[player]) and player.Character and findRootPart(player.Character) then
                    createHighlight(player)
                elseif highlightedPlayers[player] then
                    pcall(function()
                        highlightedPlayers[player].Enabled = espEnabled
                        highlightedPlayers[player].FillColor = themeColor
                        highlightedPlayers[player].OutlineColor = themeColor
                    end)
                end
            end
        end
    else
        for p, hl in pairs(highlightedPlayers) do
            if hl then pcall(function() hl.Enabled=false end) end
        end
    end

    -- Aimbot
    if aimbotEnabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not currentTarget then currentTarget = getClosestTarget() end
            if currentTarget then lockOnTarget() end
        else
            currentTarget = nil
        end
    end
end)

-- ===== GUI Controls: Aimlock, HeadAim, ESP, Theme =====
local buttonsFolder = Instance.new("Folder")
buttonsFolder.Name = "ButtonsFolder"

local function createButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 26)
    btn.Position = UDim2.new(0, 20, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderColor3 = themeColor
    btn.BorderSizePixel = 2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(function()
        local tween1 = TweenService:Create(btn, TweenInfo.new(0.08), {Size=UDim2.new(0,230,0,28)})
        local tween2 = TweenService:Create(btn, TweenInfo.new(0.08), {Size=UDim2.new(0,220,0,26)})
        tween1:Play(); tween1.Completed:Wait(); tween2:Play()
        callback()
    end)
    return btn
end

-- Aimlock toggle
local AimBtn = createButton("Aimlock: OFF", 10, function()
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = aimbotEnabled and "Aimlock: ON" or "Aimlock: OFF"
end)

-- Head aim toggle
local HeadBtn = createButton("Head Aim: OFF", 46, function()
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = headAimEnabled and "Head Aim: ON" or "Head Aim: OFF"
end)

-- ESP toggle
local EspBtn = createButton("ESP: ON", 82, function()
    espEnabled = not espEnabled
    EspBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

-- Theme selector
local ThemeBtn = createButton("Theme: BLUE", 118, function()
    themeMode = themeMode + 1
    if themeMode > 4 then themeMode = 1 end
    ThemeBtn.Text = themeMode==1 and "Theme: RED" or themeMode==2 and "Theme: BLUE" or themeMode==3 and "Theme: RAINBOW" or "Theme: RAINY"
end)

-- ===== FOV Slider =====
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(0, 220, 0, 20)
FOVLabel.Position = UDim2.new(0,20,0,154)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = themeColor
FOVLabel.TextScaled = true
FOVLabel.Text = "FOV Circle: "..tostring(fov)
FOVLabel.Visible = false

local SliderBg = Instance.new("Frame")
SliderBg.Size = UDim2.new(0,220,0,18)
SliderBg.Position = UDim2.new(0,20,0,178)
SliderBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
SliderBg.BorderColor3 = Color3.fromRGB(30,30,30)
SliderBg.BorderSizePixel = 1
SliderBg.Visible = false

local SliderFill = Instance.new("Frame", SliderBg)
SliderFill.Size = UDim2.new((fov-minFov)/(maxFov-minFov),0,1,0)
SliderFill.BackgroundColor3 = themeColor
SliderFill.BorderSizePixel = 0

local Knob = Instance.new("TextButton", SliderBg)
Knob.Size = UDim2.new(0,14,1,0)
Knob.AnchorPoint = Vector2.new(0.5,0.5)
Knob.Position = UDim2.new(SliderFill.Size.X.Scale,0,0.5,0)
Knob.BackgroundColor3 = Color3.fromRGB(220,220,220)
Knob.BorderSizePixel = 0
Knob.Text = ""
Knob.AutoButtonColor = false

local draggingSlider = false
local function updateFOV(rel)
    rel = math.clamp(rel,0,1)
    SliderFill.Size = UDim2.new(rel,0,1,0)
    Knob.Position = UDim2.new(rel,0,0.5,0)
    fov = math.floor(minFov + rel*(maxFov-minFov))
    FOVLabel.Text = "FOV Circle: "..tostring(fov)
    if FOVCircle then FOVCircle.Radius = fov end
end

SliderBg.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        local rel = (input.Position.X-SliderBg.AbsolutePosition.X)/SliderBg.AbsoluteSize.X
        updateFOV(rel)
    end
end)
Knob.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingSlider=true end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType==Enum.UserInputType.MouseMovement then
        local rel = (input.Position.X-SliderBg.AbsolutePosition.X)/SliderBg.AbsoluteSize.X
        updateFOV(rel)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingSlider=false end
end)

-- ===== Clouds & Rain Setup =====
local RainLayer = Instance.new("Frame")
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

local function spawnRaindrop()
    if not rainyEnabled then return end
    local xPixel = math.random(4, Frame.AbsoluteSize.X-4)
    local drop = Instance.new("Frame", RainLayer)
    drop.Size = UDim2.new(0,2,0,10)
    drop.Position = UDim2.new(0,xPixel,0,-20)
    drop.BackgroundColor3 = Color3.fromRGB(200,220,255)
    drop.BorderSizePixel = 0
    drop.ZIndex = 1
    local tween = TweenService:Create(drop, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Position=UDim2.new(0,xPixel,0,Frame.AbsoluteSize.Y+30)})
    tween:Play()
    tween.Completed:Connect(function() pcall(function() drop:Destroy() end) end)
end

-- Spawn rain continuously
spawn(function()
    while true do
        if rainyEnabled then
            spawnRaindrop()
            task.wait(0.04 + math.random()*0.04)
        else
            task.wait(0.16)
        end
    end
end)

-- Cloud movement loop
spawn(function()
    while true do
        if rainyEnabled then
            pcall(function()
                cloudA.Position = UDim2.new(0,-150,0,6)
                cloudB.Position = UDim2.new(0,-80,0,2)
                cloudC.Position = UDim2.new(0,-120,0,12)
                local tweenA = TweenService:Create(cloudA,TweenInfo.new(12,Enum.EasingStyle.Linear),{Position=UDim2.new(0,Frame.AbsoluteSize.X,0,6)})
                local tweenB = TweenService:Create(cloudB,TweenInfo.new(16,Enum.EasingStyle.Linear),{Position=UDim2.new(0,Frame.AbsoluteSize.X,0,2)})
                local tweenC = TweenService:Create(cloudC,TweenInfo.new(10,Enum.EasingStyle.Linear),{Position=UDim2.new(0,Frame.AbsoluteSize.X,0,12)})
                tweenA:Play(); tweenB:Play(); tweenC:Play()
                tweenA.Completed:Wait(); tweenB.Completed:Wait(); tweenC.Completed:Wait()
            end)
        else
            task.wait(0.5)
        end
    end
end)

-- ===== Final GUI Initialization =====
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Frame
    Frame.Parent = ScreenGui
    Frame.ZIndex = 4
    Content.Parent = Frame
    TitleBar.Parent = Frame
    buttonsFolder.Parent = Frame
    FOVLabel.Parent = Frame
    SliderBg.Parent = Frame
    RainLayer.Parent = Frame

    -- Minimize button
    MinButton.Parent = Frame
end

-- Call createGUI only after everything is defined
createGUI()
