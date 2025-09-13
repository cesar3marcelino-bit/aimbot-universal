--[[
    Universal Aimbot v3 - Part 1
    Core Settings, ESP, FOV Circle, Utilities
    Author: C_mthe3rd Gaming
    Maximized version with outlines for GUI & ESP, fully ready for Part 2 & 3 integration
]]

-- ===== SETTINGS =====
local teamCheck = false -- enable team check
local fov = 120 -- initial FOV radius
local minFov = 50 -- FOV slider min
local maxFov = 500 -- FOV slider max
local lockPart = "HumanoidRootPart" -- default part to aim at
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
    highlight.OutlineColor = Color3.fromRGB(0,0,0) -- default outline, dynamically updates in Part 2/3
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = espEnabled
    highlight.Parent = character
    highlightedPlayers[player] = highlight

    -- Died handler to reapply highlight after respawn
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

-- ===== INITIALIZE HIGHLIGHTS FOR EXISTING PLAYERS =====
for _,p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(removeHighlight)

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

-- ===== FOV CIRCLE UPDATE =====
local function updateFOVCircle()
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = Color3.fromRGB(0,122,255) -- will update dynamically in Part 2
            FOVCircle.Visible = aimbotEnabled
        end)
    end
end

-- ===== RENDER LOOP =====
RunService.RenderStepped:Connect(function()
    -- Targeting & aimlock
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

    -- FOV Circle update
    updateFOVCircle()

    -- ESP dynamic outline update will be handled in Part 2
end)

-- ===== PLAYER JOIN & LEAVE HANDLER =====
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        setupHighlight(player, char)
    end)
end)
Players.PlayerRemoving:Connect(removeHighlight)

-- ===== END OF PART 1 =====
-- Features included:
-- [x] Core Settings
-- [x] ESP Highlight with outline
-- [x] Target selection
-- [x] FOV Circle
-- [x] Aimbot basic lock
-- Part 2 will include:
-- - Theme cycling
-- - Rainbow mode
-- - Dynamic ESP & GUI outline integration
-- - Aimlock smoothing & prediction

--[[
    Universal Aimbot v3 - Part 2
    Theme Cycling, Rainbow Mode, Dynamic ESP & GUI Outlines, Aimlock polish
    Author: C_mthe3rd Gaming
]]

-- ===== THEME SETTINGS =====
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2
local themeColor = Color3.fromRGB(0,122,255)

-- ===== UPDATE THEME FUNCTION =====
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

-- ===== UPDATE ESP COLORS DYNAMICALLY =====
local function updateESPColors()
    for _,hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = Color3.fromRGB(0,0,0) -- outline stays visible for contrast
                hl.Enabled = espEnabled
            end)
        end
    end
end

-- ===== UPDATE FOV CIRCLE =====
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

-- ===== AIMLOCK POLISH =====
local function lockOnTarget()
    if currentTarget and currentTarget.Character then
        local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
        if part then
            local prediction = math.clamp(0.05 + currentTargetDistance/2000,0.02,0.1)
            local predictedPos = part.Position + (part.Velocity or Vector3.new())*prediction
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,predictedPos),0.25) -- smoother
        else
            currentTarget = nil
        end
    else
        currentTarget = nil
    end
end

-- ===== DYNAMIC TARGET & RENDER LOOP =====
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

-- ===== GUI OUTLINE DYNAMIC UPDATE =====
local function updateGUIOutline(guiFrame)
    if guiFrame and guiFrame:FindFirstChild("Outline") then
        guiFrame.Outline.BackgroundColor3 = themeColor
    end
end

-- ===== PLAYER JOIN/LEAVE HANDLER ENSURING DYNAMIC ESP =====
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        setupHighlight(player,char)
    end)
end)
Players.PlayerRemoving:Connect(removeHighlight)

-- ===== INITIALIZE HIGHLIGHTS AND GUI OUTLINES =====
for _,player in ipairs(Players:GetPlayers()) do
    if player.Character then setupHighlight(player,player.Character) end
end

-- ===== MAXIMIZATION NOTES =====
-- [x] Rainbow mode cycles dynamically in RenderStepped
-- [x] All ESP outlines stay visible with contrast color (black) for theme readability
-- [x] Aimlock smoothing improved for prediction
-- [x] GUI outline updating ready to integrate with Part 3
-- [x] Handles player respawn and dynamic highlight reapplication

-- Part 3 will include:
-- - Fully functional GUI with buttons
-- - Theme button cycling (changes theme + outline)
-- - FOV slider (moving correctly, outline visible)
-- - Minimize button positioned correctly
-- - GUI draggable functionality

--[[
    Universal Aimbot v3 - Part 3
    Fully Functional GUI, Draggable, Minimize, Button Outlines, Theme Cycling, FOV Slider
    Author: C_mthe3rd Gaming
]]

function createGUI()
    -- Remove old GUI
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then
        game.CoreGui.Aimlock_GUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Aimlock_GUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- ===== MAIN FRAME =====
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 300, 0, 360)
    Frame.Position = UDim2.new(1, -320, 0, 80)
    Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Frame.BorderSizePixel = 0
    Frame.Active = true

    -- Outline for GUI
    local Outline = Instance.new("Frame", Frame)
    Outline.Name = "Outline"
    Outline.Size = UDim2.new(1, 4, 1, 4)
    Outline.Position = UDim2.new(0, -2, 0, -2)
    Outline.BackgroundColor3 = themeColor
    Outline.BorderSizePixel = 0

    -- ===== TITLE BAR =====
    local TitleBar = Instance.new("Frame", Frame)
    TitleBar.Size = UDim2.new(1,0,0,30)
    TitleBar.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1, -40,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Universal Aimbot v3"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- ===== MINIMIZE BUTTON =====
    local MinButton = Instance.new("TextButton", TitleBar)
    MinButton.Size = UDim2.new(0,30,0,30)
    MinButton.Position = UDim2.new(1,-35,0,0)
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
    CreditsLabel.Text = "Script by C_mthe3rd"
    CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
    CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14

    -- ===== BUTTON CREATOR WITH OUTLINE =====
    local function createButton(name, yPos, callback)
        local btnFrame = Instance.new("Frame", Content)
        btnFrame.Size = UDim2.new(1,-20,0,30)
        btnFrame.Position = UDim2.new(0,10,0,yPos)
        btnFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btnFrame.BorderSizePixel = 0

        local outline = Instance.new("Frame", btnFrame)
        outline.Size = UDim2.new(1,2,1,2)
        outline.Position = UDim2.new(0,-1,0,-1)
        outline.BackgroundColor3 = themeColor
        outline.BorderSizePixel = 0

        local btn = Instance.new("TextButton", btnFrame)
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextScaled = true
        btn.MouseButton1Click:Connect(callback)
        return btn, outline
    end

    -- ===== BUTTONS =====
    local ESPButton, ESPOutline = createButton("ESP: On", 0, function()
        espEnabled = not espEnabled
        ESPButton.Text = "ESP: "..(espEnabled and "On" or "Off")
        for _, hl in pairs(highlightedPlayers) do
            if hl then hl.Enabled = espEnabled end
        end
        ESPOutline.BackgroundColor3 = themeColor
    end)

    local AimlockButton, AimlockOutline = createButton("Aimlock: Off", 50, function()
        aimbotEnabled = not aimbotEnabled
        AimlockButton.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off")
        AimlockOutline.BackgroundColor3 = themeColor
    end)

    local HeadAimButton, HeadAimOutline = createButton("Head Aim: Off", 100, function()
        headAimEnabled = not headAimEnabled
        HeadAimButton.Text = "Head Aim: "..(headAimEnabled and "On" or "Off")
        HeadAimOutline.BackgroundColor3 = themeColor
    end)

    local ThemeButton, ThemeOutline = createButton("Theme: "..themeNames[currentThemeIndex], 150, function()
        currentThemeIndex = currentThemeIndex % #themeNames + 1
        ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]
        -- Update all button outlines dynamically
        ESPOutline.BackgroundColor3 = themeColor
        AimlockOutline.BackgroundColor3 = themeColor
        HeadAimOutline.BackgroundColor3 = themeColor
        ThemeOutline.BackgroundColor3 = themeColor
        Outline.BackgroundColor3 = themeColor
    end)

    -- ===== FOV SLIDER WITH HANDLE =====
    local SliderLabel = Instance.new("TextLabel", Content)
    SliderLabel.Size = UDim2.new(1,-20,0,16)
    SliderLabel.Position = UDim2.new(0,10,0,200)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "FOV Circle: "..math.floor(fov)
    SliderLabel.TextColor3 = Color3.fromRGB(255,255,255)
    SliderLabel.Font = Enum.Font.SourceSans
    SliderLabel.TextSize = 14

    local FOVSlider = Instance.new("Frame", Content)
    FOVSlider.Size = UDim2.new(1,-20,0,16)
    FOVSlider.Position = UDim2.new(0,10,0,220)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(60,60,60)
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

    -- ===== MINIMIZE FUNCTION =====
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Frame.Size = minimized and UDim2.new(0,300,0,30) or UDim2.new(0,300,0,360)
        CreditsLabel.Visible = not minimized
    end)
end

-- ===== CALL GUI CREATION =====
createGUI()
