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
Players.PlayerAdded:Connect(function(p) createHighlight(p) end)
Players.PlayerRemoving:Connect(function(p) removeHighlight(p) end)

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
    local newTheme = (function()
        if themeMode == 1 then rainbowEnabled = false; rainyEnabled = false; return Color3.fromRGB(255,0,0)
        elseif themeMode == 2 then rainbowEnabled = false; rainyEnabled = false; return Color3.fromRGB(0,122,255)
        elseif themeMode == 3 then rainbowEnabled = true; rainyEnabled = false; local t = tick()*0.2; return Color3.fromHSV(t%1,1,1)
        elseif themeMode == 4 then rainbowEnabled = false; rainyEnabled = true; return Color3.fromRGB(140,160,185)
        else rainbowEnabled=false; rainyEnabled=false; return Color3.fromRGB(0,122,255) end
    end)()
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

    -- ensure highlights exist/are updated
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

    -- aimbot behavior
    if aimbotEnabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not currentTarget then currentTarget = getClosestTarget() end
            if currentTarget then lockOnTarget() end
        else
            currentTarget = nil
        end
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
    Content.ZIndex = 2

    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,28)
    TitleBar.Position = UDim2.new(0,0,0,0)
    TitleBar.BackgroundTransparency = 1
    TitleBar.ZIndex = 3

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1,-10,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3

    -- Credits below title
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
    CreditsLabel.ZIndex = 3

-- ===== GUI Toggles & Buttons =====
local minimized = false

local function toggleMinimize()
    minimized = not minimized
    Content.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,300)
end

-- Minimize button
local MinButton = Instance.new("TextButton", TitleBar)
MinButton.Size = UDim2.new(0,28,0,28)
MinButton.Position = UDim2.new(1,-28,0,0)
MinButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
MinButton.BorderSizePixel = 1
MinButton.BorderColor3 = themeColor
MinButton.Text = "_"
MinButton.TextColor3 = Color3.fromRGB(255,255,255)
MinButton.TextScaled = true
MinButton.MouseButton1Click:Connect(toggleMinimize)

-- Draggable GUI
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
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateInput(input) end
end)

-- ===== Clouds (background effect) =====
local cloudsFolder = Instance.new("Folder", Frame)
cloudsFolder.Name = "CloudsFolder"
for i = 1, 5 do
    local cloud = Instance.new("ImageLabel", cloudsFolder)
    cloud.Image = "rbxassetid://10732346" -- placeholder cloud asset
    cloud.Size = UDim2.new(0,100,0,60)
    cloud.Position = UDim2.new(math.random(),0,math.random(),0)
    cloud.BackgroundTransparency = 1
    cloud.ZIndex = 1
    local speed = math.random(5,20)/100
    RunService.RenderStepped:Connect(function()
        cloud.Position = cloud.Position + UDim2.new(speed,0,0,0)
        if cloud.Position.X.Offset > 300 then cloud.Position = UDim2.new(-100,0,cloud.Position.Y.Scale,cloud.Position.Y.Offset) end
    end)
end

-- ===== Rain effect =====
local rainFolder = Instance.new("Folder", Frame)
rainFolder.Name = "RainFolder"
local function createRaindrop()
    local drop = Instance.new("Frame", rainFolder)
    drop.Size = UDim2.new(0,2,0,10)
    drop.Position = UDim2.new(math.random(),0,0,math.random(-300,0))
    drop.BackgroundColor3 = Color3.fromRGB(170,170,255)
    drop.BorderSizePixel = 0
    local speed = math.random(5,15)
    RunService.RenderStepped:Connect(function(dt)
        drop.Position = drop.Position + UDim2.new(0,0,0,speed)
        if drop.Position.Y.Offset > 300 then drop.Position = UDim2.new(drop.Position.X.Scale,drop.Position.X.Offset,0,math.random(-300,0)) end
    end)
end
for i = 1, 50 do createRaindrop() end

    -- ===== GUI Controls: Aimlock, HeadAim, ESP, Theme =====
local buttonsFolder = Instance.new("Folder", Frame)
buttonsFolder.Name = "ButtonsFolder"

local function createButton(text,posY,callback)
    local btn = Instance.new("TextButton", buttonsFolder)
    btn.Size = UDim2.new(0,220,0,26)
    btn.Position = UDim2.new(0,20,0,posY)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderColor3 = themeColor
    btn.BorderSizePixel = 2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(function()
        local tween1 = TweenService:Create(btn,TweenInfo.new(0.08),{Size=UDim2.new(0,230,0,28)})
        local tween2 = TweenService:Create(btn,TweenInfo.new(0.08),{Size=UDim2.new(0,220,0,26)})
        tween1:Play(); tween1.Completed:Wait(); tween2:Play()
        callback()
    end)
    return btn
end

-- Aimlock toggle
local AimBtn = createButton("Aimlock: OFF",10,function()
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = aimbotEnabled and "Aimlock: ON" or "Aimlock: OFF"
    FOVCircle.Visible = aimbotEnabled
    FOVSlider.Visible = aimbotEnabled
    FOVLabel.Visible = aimbotEnabled
end)

-- Head aim toggle
local HeadBtn = createButton("Head Aim: OFF",46,function()
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = headAimEnabled and "Head Aim: ON" or "Head Aim: OFF"
end)

-- ESP toggle
local EspBtn = createButton("ESP: ON",82,function()
    espEnabled = not espEnabled
    EspBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)

-- Theme selector
local ThemeBtn = createButton("Theme: BLUE",118,function()
    themeMode = themeMode + 1
    if themeMode > 4 then themeMode = 1 end
    if themeMode == 1 then ThemeBtn.Text = "Theme: RED"
    elseif themeMode == 2 then ThemeBtn.Text = "Theme: BLUE"
    elseif themeMode == 3 then ThemeBtn.Text = "Theme: RAINBOW"
    elseif themeMode == 4 then ThemeBtn.Text = "Theme: RAINY" end
    themeColor = computeThemeColor()
    Frame.BorderColor3 = themeColor
    for _,b in pairs(buttonsFolder:GetChildren()) do if b:IsA("TextButton") then b.BorderColor3 = themeColor end end
    SliderFill.BackgroundColor3 = themeColor
end)

-- ===== FOV Slider =====
local FOVLabel = Instance.new("TextLabel", Frame)
FOVLabel.Size = UDim2.new(0,220,0,20)
FOVLabel.Position = UDim2.new(0,20,0,154)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = themeColor
FOVLabel.TextScaled = true
FOVLabel.Text = "FOV Circle: "..tostring(fov)
FOVLabel.Visible = false

local SliderBg = Instance.new("Frame", Frame)
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

    -- ===== Rain Layer & Clouds =====
local RainLayer = Instance.new("Frame", Frame)
RainLayer.Size = UDim2.new(1,0,1,0)
RainLayer.Position = UDim2.new(0,0,0,0)
RainLayer.BackgroundTransparency = 1
RainLayer.ClipsDescendants = true
RainLayer.ZIndex = 0

-- Clouds
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

-- Rain spawn function
local function spawnRaindrop()
    if not rainyEnabled then return end
    local width = math.max(30, Frame.AbsoluteSize.X-6)
    local xPixel = math.random(4,width-4)
    local drop = Instance.new("Frame", RainLayer)
    drop.Size = UDim2.new(0,2,0,10)
    drop.Position = UDim2.new(0,xPixel,0,-20)
    drop.BackgroundColor3 = Color3.fromRGB(200,220,255)
    drop.BorderSizePixel = 0
    drop.ZIndex = 1
    local fallTime = 0.5 + math.random()*0.5
    local targetY = Frame.AbsoluteSize.Y+30
    local tween = TweenService:Create(drop,TweenInfo.new(fallTime,Enum.EasingStyle.Linear),{Position=UDim2.new(0,xPixel,0,targetY)})
    tween:Play()
    tween.Completed:Connect(function()
        pcall(function()
            drop:Destroy()
            local splash = Instance.new("Frame", RainLayer)
            splash.Size = UDim2.new(0,6,0,2)
            splash.Position = UDim2.new(0,xPixel,0,targetY-2)
            splash.BackgroundColor3 = Color3.fromRGB(180,200,255)
            splash.BorderSizePixel = 0
            splash.ZIndex = 1
            local splashTween = TweenService:Create(splash,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0,xPixel,0,targetY)})
            splashTween:Play()
            splashTween.Completed:Connect(function() pcall(function() splash:Destroy() end) end)
        end)
    end)
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
            local endX = Frame.AbsoluteSize.X + 200
            pcall(function()
                cloudA.Position = UDim2.new(0,-150,0,6)
                cloudB.Position = UDim2.new(0,-80,0,2)
                cloudC.Position = UDim2.new(0,-120,0,12)
                local tweenA = TweenService:Create(cloudA,TweenInfo.new(12,Enum.EasingStyle.Linear),{Position=UDim2.new(0,endX/Frame.AbsoluteSize.X,0,6)})
                local tweenB = TweenService:Create(cloudB,TweenInfo.new(16,Enum.EasingStyle.Linear),{Position=UDim2.new(0,endX/Frame.AbsoluteSize.X,0,2)})
                local tweenC = TweenService:Create(cloudC,TweenInfo.new(10,Enum.EasingStyle.Linear),{Position=UDim2.new(0,endX/Frame.AbsoluteSize.X,0,12)})
                tweenA:Play(); tweenB:Play(); tweenC:Play()
                tweenA.Completed:Wait(); tweenB.Completed:Wait(); tweenC.Completed:Wait()
            end)
        else
            task.wait(0.5)
        end
    end
end)

-- ===== RenderStepped Updates: Distance, Target, Lock =====
RunService.RenderStepped:Connect(function()
    local closest = getClosestTarget()
    if closest and closest.Character and LocalPlayer.Character then
        local localRoot = findRootPart(LocalPlayer.Character)
        local targetRoot = findRootPart(closest.Character)
        if localRoot and targetRoot then
            local dist = (localRoot.Position - targetRoot.Position).Magnitude
            DistanceLabel.Text = "Distance: "..math.floor(dist)
            currentTarget = closest
        else
            DistanceLabel.Text = "Distance: N/A"
            currentTarget = nil
        end
    else
        DistanceLabel.Text = "Distance: N/A"
        currentTarget = nil
    end

    -- Lock on target if Aimlock is enabled
    if aimbotEnabled then lockOnTarget() end

    -- Theme updates
    themeColor = computeThemeColor()
    Frame.BorderColor3 = themeColor
    for _,b in pairs(buttonsFolder:GetChildren()) do if b:IsA("TextButton") then b.BorderColor3 = themeColor end end
    SliderFill.BackgroundColor3 = themeColor
    FOVLabel.TextColor3 = themeColor

    -- Show/hide FOV slider
    FOVLabel.Visible = aimbotEnabled
    SliderBg.Visible = aimbotEnabled
end)

    -- ===== Minimize Button =====
local MinimizeBtn = Instance.new("TextButton", ScreenGui)
MinimizeBtn.Size = UDim2.new(0,28,0,20)
MinimizeBtn.Position = UDim2.new(1,-32,0,4) -- top-right corner
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.BorderColor3 = themeColor
MinimizeBtn.Text = "—"
MinimizeBtn.TextScaled = true
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.ZIndex = 5

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Content.Visible = false
        FOVLabel.Visible = false
        SliderBg.Visible = false
        TweenService:Create(Frame,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,260,0,34)}):Play()
        MinimizeBtn.Text = "+"
    else
        TweenService:Create(Frame,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,260,0,300)}):Play()
        task.wait(0.16)
        Content.Visible = true
        if aimbotEnabled then
            FOVLabel.Visible = true
            SliderBg.Visible = true
        end
        MinimizeBtn.Text = "—"
    end
end)

-- ===== Credits Placement =====
CreditsLabel.Position = UDim2.new(0,10,0,28)
CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
CreditsLabel.TextScaled = false
CreditsLabel.Font = Enum.Font.SourceSans
CreditsLabel.TextSize = 14

-- ===== Smooth Dragging GUI =====
local draggingGui = false
local dragStart, startPos, targetPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingGui = true
        dragStart = input.Position
        startPos = Frame.Position
        targetPos = startPos
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingGui = false end
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
    if targetPos then Frame.Position = Frame.Position:Lerp(targetPos,0.25) end
end)

-- ===== Ensure all GUI elements are properly visible based on Aimlock =====
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        FOVLabel.Visible = true
        SliderBg.Visible = true
    else
        FOVLabel.Visible = false
        SliderBg.Visible = false
    end
end)

-- ===== Final Script Initialization =====
createGUI() -- Initialize GUI fully
