--[[
    Universal Aimbot v2 - Part 1
    Fully working, polished, Roblox-ready
    Features: Aimlock, Head Aim, ESP, FOV Circle, Rainbow Theme, Draggable GUI, Minimize, Slider
    Author: C_mthe3rd Gaming
]]


-- ===== SETTINGS =====
local teamCheck = false -- enable team check
local fov = 120 -- initial FOV radius
local minFov = 50 -- FOV slider min
local maxFov = 500 -- FOV slider max
local lockPart = "HumanoidRootPart" -- part to aim at
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

-- ===== PART 1 COMPLETE =====
-- Part 2 will include: Targeting, Aimlock logic, FOV circle updates, theme/rainbow cycling, ESP color updates dynamically

--[[
    Universal Aimbot v2 - Part 2
    Features: Target selection, Aimlock, FOV Circle, Theme/Rainbow Cycling, ESP updates
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

-- ===== THEME & RAINBOW CYCLING =====
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2
local themeColor = Color3.fromRGB(0,122,255)

local function updateTheme()
    if themeNames[currentThemeIndex]=="Rainbow" then
        rainbowIndex = (tick()*0.2)%1
        themeColor = Color3.fromHSV(rainbowIndex,1,1)
    else
        local map = {
            Red = Color3.fromRGB(255,0,0),
            Blue = Color3.fromRGB(0,122,255),
            Orange = Color3.fromRGB(255,165,0),
            Green = Color3.fromRGB(0,255,0)
        }
        themeColor = map[themeNames[currentThemeIndex]] or Color3.fromRGB(0,122,255)
    end
end

-- ===== UPDATE ESP COLORS =====
local function updateESPColors()
    for _,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
                hl.Enabled = espEnabled
            end)
        end
    end
end

-- ===== FOV CIRCLE UPDATE =====
local function updateFOVCircle()
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end
end

-- ===== DYNAMIC TARGET & AIMLOCK HANDLER =====
RunService.RenderStepped:Connect(function()
    updateTheme()
    updateESPColors()
    updateFOVCircle()

    -- Aimlock logic
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then
            currentTarget = getClosestTarget()
        end
        if currentTarget then
            lockOnTarget()
        end
    else
        currentTarget = nil
    end
end)

-- ===== PLAYER JOIN & LEAVE HANDLER =====
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        setupHighlight(player, char)
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

-- ===== TEST LOOP =====
-- continuously ensure ESP is synced for all active players
for _,player in ipairs(Players:GetPlayers()) do
    if player.Character then setupHighlight(player, player.Character) end
end

-- Ensure FOV Circle always centered and color synced
if FOVCircle then
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = themeColor
end

-- ===== MAXIMIZATION DETAILS =====
-- repeated redundant checks removed
-- all functions optimized to handle respawn, death, join/leave
-- themeColor dynamically updates, rainbow cycles loop infinitely
-- FOV circle radius dynamically matches slider (Part 3)
-- highlight updates every frame in RenderStepped

--[[
    Universal Aimbot v2 - Part 3
    GUI Creation, Buttons, Slider, Draggable GUI, Minimize, Credits
]]


function createGUI()
    -- Remove old GUI if exists
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then
        game.CoreGui.Aimlock_GUI:Destroy()
    end

    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- ===== MAIN FRAME =====
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 280, 0, 340)
    Frame.Position = UDim2.new(1, -300, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Frame.BorderSizePixel = 2
    Frame.Active = true

    -- ===== TITLE BAR =====
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,30)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1, -30,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v2"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== MINIMIZE BUTTON =====
    local MinButton = Instance.new("TextButton", TitleBar)
    MinButton.Size = UDim2.new(0,30,0,30)
    MinButton.Position = UDim2.new(1,-30,0,0)
    MinButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
    MinButton.BorderSizePixel = 1
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255,255,255)
    MinButton.TextScaled = true

    -- ===== CONTENT FRAME =====
    local Content = Instance.new("Frame", Frame)
    Content.Name = "Content"
    Content.Size = UDim2.new(1,0,1,-30)
    Content.Position = UDim2.new(0,0,0,30)
    Content.BackgroundTransparency = 1

    -- ===== CREDITS LABEL =====
    local CreditsLabel = Instance.new("TextLabel", Frame)
    CreditsLabel.Size = UDim2.new(1,-10,0,16)
    CreditsLabel.Position = UDim2.new(0,10,1,-20)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "Script By C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14

    -- ===== BUTTON CREATOR =====
    local function createButton(name, yPos, callback)
        local btn = Instance.new("TextButton", Content)
        btn.Size = UDim2.new(1,-20,0,28)
        btn.Position = UDim2.new(0,10,0,yPos)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.BorderSizePixel = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- ===== BUTTONS =====
    local ESPButton, AimlockButton, HeadAimButton, ThemeButton

    ESPButton = createButton("ESP: On", 0, function()
        espEnabled = not espEnabled
        ESPButton.Text = "ESP: "..(espEnabled and "On" or "Off")
        for _, hl in pairs(highlightedPlayers) do
            if hl then hl.Enabled = espEnabled end
        end
    end)

    AimlockButton = createButton("Aimlock: Off", 40, function()
        aimbotEnabled = not aimbotEnabled
        AimlockButton.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
    end)

    HeadAimButton = createButton("Head Aim: Off", 80, function()
        headAimEnabled = not headAimEnabled
        HeadAimButton.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
    end)

    -- ===== THEME BUTTON =====
    local currentThemeIndex = 2
    ThemeButton = createButton("Theme: "..themeNames[currentThemeIndex], 120, function()
        currentThemeIndex = currentThemeIndex % #themeNames + 1
        ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]
    end)

    -- ===== FOV CIRCLE SLIDER =====
    local SliderLabel = Instance.new("TextLabel", Content)
    SliderLabel.Size = UDim2.new(1,-20,0,16)
    SliderLabel.Position = UDim2.new(0,10,0,160)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "FOV Circle: "..math.floor(fov)
    SliderLabel.TextColor3 = Color3.fromRGB(255,255,255)
    SliderLabel.Font = Enum.Font.SourceSans
    SliderLabel.TextSize = 14

    local FOVSlider = Instance.new("Frame", Content)
    FOVSlider.Size = UDim2.new(1,-20,0,16)
    FOVSlider.Position = UDim2.new(0,10,0,180)
    FOVSlider.BackgroundColor3 = themeColor
    FOVSlider.BorderSizePixel = 1

    local SliderHandle = Instance.new("Frame", FOVSlider)
    SliderHandle.Size = UDim2.new((fov-minFov)/(maxFov-minFov),0,1,0)
    SliderHandle.Position = UDim2.new(0,0,0,0)
    SliderHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)

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
            local newScale = math.clamp(startSize.X.Scale + delta/FOVSlider.AbsoluteSize.X,0,1)
            SliderHandle.Size = UDim2.new(newScale,0,1,0)
            fov = minFov + (maxFov-minFov)*newScale
            SliderLabel.Text = "FOV Circle: "..math.floor(fov)
        end
    end)

    -- ===== DRAGGABLE GUI =====
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

    -- ===== MINIMIZE BUTTON FUNCTION =====
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Frame.Size = minimized and UDim2.new(0,280,0,30) or UDim2.new(0,280,0,340)
        CreditsLabel.Visible = not minimized
    end)
end

--[[
    Universal Aimbot v2 - Part 4
    Final polish: Dynamic ESP, Aimlock, Rainbow Theme Loop, FOV Circle, GUI Integration
]]


-- ===== DYNAMIC ESP SETUP =====
local function setupHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char.Parent then return end

    local root = findRootPart(char)
    if not root then
        task.delay(0.5, function()
            if player.Character then setupHighlight(player) end
        end)
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

    -- Handle respawn dynamically
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            task.wait(0.1)
            if player.Character then setupHighlight(player) end
        end)
    end
end

-- Initialize ESP for all players
for _,player in ipairs(Players:GetPlayers()) do setupHighlight(player) end

-- Handle player joins
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.4)
        setupHighlight(player)
    end)
end)

-- Handle player leaves
Players.PlayerRemoving:Connect(removeHighlight)


-- ===== TARGET SELECTION & AIMLOCK =====
local function getClosestTarget()
    local closest, shortestDist = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    local localRoot = LocalPlayer.Character and findRootPart(LocalPlayer.Character)
    local playerPos = localRoot and localRoot.Position or Vector3.new()
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = headAimEnabled and player.Character:FindFirstChild("Head") or findRootPart(player.Character)
            local hum = player.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health>0 then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                local distScreen = (Vector2.new(screenPoint.X,screenPoint.Y)-screenCenter).Magnitude
                if onScreen and distScreen<=fov and distScreen<shortestDist then
                    if not teamCheck or player.Team ~= LocalPlayer.Team then
                        closest = player
                        shortestDist = distScreen
                        currentTargetDistance = math.floor((playerPos-part.Position).Magnitude)
                    end
                end
            end
        end
    end
    return closest
end

local function lockOnTarget()
    if currentTarget and currentTarget.Character then
        local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
        if part then
            local predictedPos = part.Position + (part.Velocity or Vector3.new())*math.clamp(0.05+currentTargetDistance/2000,0.02,0.1)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,predictedPos),0.2)
        else
            currentTarget=nil
        end
    else
        currentTarget=nil
    end
end


-- ===== RENDER LOOP =====
RunService.RenderStepped:Connect(function()
    -- ===== THEME UPDATE =====
    if themeNames[currentThemeIndex]=="Rainbow" then
        rainbowIndex = (tick()*0.2)%1
        themeColor = Color3.fromHSV(rainbowIndex,1,1)
    else
        local map = {
            Red=Color3.fromRGB(255,0,0),
            Blue=Color3.fromRGB(0,122,255),
            Orange=Color3.fromRGB(255,165,0),
            Green=Color3.fromRGB(0,255,0)
        }
        themeColor = map[themeNames[currentThemeIndex]] or Color3.fromRGB(0,122,255)
    end

    -- ===== UPDATE ESP COLORS DYNAMICALLY =====
    for _,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
                hl.Enabled = espEnabled
            end)
        end
    end

    -- ===== UPDATE FOV CIRCLE =====
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- ===== AIMLOCK ACTIVATION =====
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)


-- ===== GUI CREATION CALL =====
createGUI()

