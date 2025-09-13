--[[ 
    Universal Aimbot v3 - Part 1/4
    Fully polished, Roblox-ready
    Author: C_mthe3rd + polished by ChatGPT
]]

-- ======= SETTINGS =======
local teamCheck = false             -- Ignore teammates if true
local fov = 120                     -- Default FOV
local minFov = 50                   -- Slider min
local maxFov = 500                  -- Slider max
local lockPart = "HumanoidRootPart" -- Part to aim at
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local currentTarget = nil
local currentTargetDistance = "N/A"
local currentThemeIndex = 2          -- Default Blue
local themeNames = {"Red", "Blue", "Orange", "Green", "Rainbow"}
local rainbowIndex = 0               -- For rainbow cycling
local highlightedPlayers = {}        -- Stores ESP highlights

-- ======= SERVICES =======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ======= DRAWING FOV CIRCLE =======
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
        c.Color = Color3.fromRGB(0,122,255)
        c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        return c
    end)
    if ok then FOVCircle = circle end
end

-- ======= UTILITY FUNCTIONS =======
-- Find main part for aiming
local function findRootPart(character)
    if not character then return nil end
    local names = {"HumanoidRootPart", "LowerTorso", "UpperTorso", "Torso"}
    for _, n in ipairs(names) do
        local part = character:FindFirstChild(n)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

-- Remove highlight from player
local function removeHighlight(player)
    if highlightedPlayers[player] then
        pcall(function() highlightedPlayers[player]:Destroy() end)
        highlightedPlayers[player] = nil
    end
end

-- Setup ESP highlight for a character
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
            if player.Character then
                setupHighlightForCharacter(player, player.Character)
            end
        end)
    end
end

-- Create highlight when character exists
local function createHighlight(player)
    if player == LocalPlayer then return end
    if player.Character then setupHighlightForCharacter(player, player.Character) end
    player.CharacterAdded:Connect(function(character)
        task.wait(0.4)
        setupHighlightForCharacter(player, character)
    end)
end

-- Initialize highlights for all players
for _, p in ipairs(Players:GetPlayers()) do createHighlight(p) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(removeHighlight)

--[[ 
    Universal Aimbot v3 - Part 2/4
    Target selection, Aimlock, FOV circle, and theme color cycling
]]

-- ======= TARGET SELECTION =======
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

-- ======= AIMLOCK =======
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

-- ======= THEME COLOR HELPER =======
local function getThemeColor(index)
    local name = themeNames[index]
    if name == "Red" then
        return Color3.fromRGB(255,0,0)
    elseif name == "Blue" then
        return Color3.fromRGB(0,122,255)
    elseif name == "Orange" then
        return Color3.fromRGB(255,165,0)
    elseif name == "Green" then
        return Color3.fromRGB(0,255,0)
    elseif name == "Rainbow" then
        return Color3.fromHSV(rainbowIndex % 1, 1, 1)
    else
        return Color3.fromRGB(0,122,255)
    end
end

-- ======= MAIN RENDER LOOP =======
RunService.RenderStepped:Connect(function()
    -- Update rainbow index for rainbow theme
    if themeNames[currentThemeIndex] == "Rainbow" then
        rainbowIndex = (tick() * 0.2) % 1
    end

    -- Apply current theme color
    local themeColor = getThemeColor(currentThemeIndex)
    for _, hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
            end)
        end
    end
    if FOVCircle then
        pcall(function()
            FOVCircle.Color = themeColor
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Visible = aimbotEnabled
        end)
    end

    -- Update ESP highlights enable/disable
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and highlightedPlayers[player] then
            pcall(function()
                highlightedPlayers[player].Enabled = espEnabled
            end)
        end
    end

    -- AIMBOT LOCK
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)

-- ===== THEME & FOV SYSTEM =====
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2
local themeColor = Color3.fromRGB(0,122,255)

-- Theme button
local ThemeButton = Instance.new("TextButton", Content)
ThemeButton.Size = UDim2.new(1,-20,0,28)
ThemeButton.Position = UDim2.new(0,10,0,120)
ThemeButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
ThemeButton.BorderSizePixel = 1
ThemeButton.BorderColor3 = themeColor
ThemeButton.TextColor3 = Color3.fromRGB(255,255,255)
ThemeButton.TextScaled = true
ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]

-- Theme cycle function
local function cycleTheme()
    currentThemeIndex = currentThemeIndex % #themeNames + 1
    ThemeButton.Text = "Theme: "..themeNames[currentThemeIndex]
end
ThemeButton.MouseButton1Click:Connect(cycleTheme)

-- FOV slider
local FOVLabel = Instance.new("TextLabel", Content)
FOVLabel.Size = UDim2.new(1,-20,0,16)
FOVLabel.Position = UDim2.new(0,10,0,160)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: "..fov
FOVLabel.TextColor3 = Color3.fromRGB(255,255,255)
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Font = Enum.Font.SourceSans
FOVLabel.TextSize = 14

local FOVSlider = Instance.new("Frame", Content)
FOVSlider.Size = UDim2.new(1,-20,0,16)
FOVSlider.Position = UDim2.new(0,10,0,180)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50,50,50)
FOVSlider.BorderSizePixel = 1
FOVSlider.BorderColor3 = themeColor

local FOVHandle = Instance.new("Frame", FOVSlider)
FOVHandle.Size = UDim2.new((fov-minFov)/(maxFov-minFov),0,1,0)
FOVHandle.BackgroundColor3 = Color3.fromRGB(0,122,255)

local draggingFOV = false
FOVHandle.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        draggingFOV = true
        local startX = input.Position.X
        local startScale = FOVHandle.Size.X.Scale
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                draggingFOV = false
            end
        end)
        UserInputService.InputChanged:Connect(function(moveInput)
            if draggingFOV and moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = moveInput.Position.X - startX
                local newScale = math.clamp(startScale + delta/FOVSlider.AbsoluteSize.X, 0,1)
                FOVHandle.Size = UDim2.new(newScale,0,1,0)
                fov = minFov + (maxFov-minFov)*newScale
                FOVLabel.Text = "FOV: "..math.floor(fov)
            end
        end)
    end
end)

-- ===== THEME COLOR CYCLE ON RENDER =====
RunService.RenderStepped:Connect(function()
    local selectedTheme = themeNames[currentThemeIndex]
    if selectedTheme == "Rainbow" then
        local t = tick()*0.3
        local hue = t%1
        themeColor = Color3.fromHSV(hue,1,1)
    else
        local colorMap = {
            Red = Color3.fromRGB(255,0,0),
            Blue = Color3.fromRGB(0,122,255),
            Orange = Color3.fromRGB(255,165,0),
            Green = Color3.fromRGB(0,255,0)
        }
        themeColor = colorMap[selectedTheme] or Color3.fromRGB(0,122,255)
    end

    -- Update GUI elements with new theme color
    ThemeButton.BorderColor3 = themeColor
    FOVSlider.BorderColor3 = themeColor
    FOVHandle.BackgroundColor3 = themeColor
    Frame.BorderColor3 = themeColor

    -- Update ESP highlights
    for _,hl in pairs(highlightedPlayers) do
        if hl then
            hl.FillColor = themeColor
            hl.OutlineColor = themeColor
        end
    end

    -- Update FOV circle if exists
    if FOVCircle then
        FOVCircle.Color = themeColor
        FOVCircle.Radius = fov
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Visible = aimbotEnabled
    end
end)

-- ===== ON/OFF BUTTONS VISUAL =====
local function createToggleButton(name, yPos, stateRef)
    local btn = Instance.new("TextButton", Content)
    btn.Size = UDim2.new(1,-20,0,28)
    btn.Position = UDim2.new(0,10,0,yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = themeColor
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true

    local function updateText()
        btn.Text = name.." : "..(stateRef() and "ON" or "OFF")
    end
    updateText()

    btn.MouseButton1Click:Connect(function()
        stateRef(not stateRef())
        updateText()
    end)
    return btn
end

-- State references
local espState = function(val) if val~=nil then espEnabled=val else return espEnabled end end
local aimState = function(val) if val~=nil then aimbotEnabled=val else return aimbotEnabled end end
local headState = function(val) if val~=nil then headAimEnabled=val else return headAimEnabled end end

-- Buttons
createToggleButton("ESP",0,espState)
createToggleButton("Aimlock",40,aimState)
createToggleButton("Head Aim",80,headState)

-- ===== CREDITS BOTTOM-LEFT =====
local CreditsLabel = Instance.new("TextLabel", ScreenGui)
CreditsLabel.Size = UDim2.new(0,200,0,16)
CreditsLabel.Position = UDim2.new(0,10,1,-20)
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Text = "Script by C_mthe3rd"
CreditsLabel.TextColor3 = Color3.fromRGB(180,180,180)
CreditsLabel.TextXAlignment = Enum.TextXAlignment.Left
CreditsLabel.TextScaled = false
CreditsLabel.Font = Enum.Font.SourceSans
CreditsLabel.TextSize = 14

-- ===== FINAL TOUCHES =====
-- Ensure GUI always on top
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Smooth dragging
local draggingFrame, dragInputFrame, dragStartFrame, startPosFrame = false, nil, nil, nil
local function updateFrame(input)
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
    if input==dragInputFrame and draggingFrame then updateFrame(input) end
end)

-- Minimize button function
local minimized = false
MinButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,300)
end)

-- ===== READY =====
print("Universal Aimbot v2 GUI loaded. All systems functional.")
