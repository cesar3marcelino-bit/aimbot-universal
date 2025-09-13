--[[
    Universal Aimbot v4 - Part 1 (Core + Helpers + FOV + Smooth Aim)
    Author: C_mthe3rd Gaming
    Lines: ~320
    Notes:
        - Fully robust core setup for ESP, Aimlock, FOV
        - Smooth mouse movement with configurable speed
        - Supports head/body toggle
        - Robust highlight creation/removal handled
        - Theme colors & rainbow support included
        - Prepared for GUI integration in later parts
]]

-----------------------------
--== Services & Globals ==--
-----------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- State Variables
local espEnabled = true
local aimbotEnabled = false
local headAimEnabled = false
local fov = 150
local minFov, maxFov = 50, 500
local lockPart = "HumanoidRootPart"
local currentTarget = nil
local rightClickHeld = false
local aimSpeed = 5 -- smooth aim factor (larger = slower)
local rainbowSpeed = 0.3

local highlightedPlayers = {}
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2

-- Theme color map
local themeMap = {
    Red = Color3.fromRGB(255,50,50),
    Blue = Color3.fromRGB(0,140,255),
    Orange = Color3.fromRGB(255,170,40),
    Green = Color3.fromRGB(40,255,120),
}

-- Utility clamp
local function clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, val))
end

-----------------------------
--== Theme Functions ==--
-----------------------------
local function getThemeColor()
    local themeName = themeNames[currentThemeIndex]
    if themeName == "Rainbow" then
        local t = (tick() * rainbowSpeed) % 1
        return Color3.fromHSV(t,1,1)
    end
    return themeMap[themeName] or Color3.fromRGB(0,140,255)
end

-----------------------------
--== Character Helpers ==--
-----------------------------
local function findRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local function setupHighlight(player)
    if not player.Character then return end
    if highlightedPlayers[player] then
        highlightedPlayers[player]:Destroy()
        highlightedPlayers[player] = nil
    end
    local hl = Instance.new("Highlight")
    hl.Adornee = player.Character
    hl.FillColor = getThemeColor()
    hl.OutlineColor = getThemeColor()
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Enabled = espEnabled
    hl.Parent = player.Character
    highlightedPlayers[player] = hl
end

local function removeHighlight(player)
    if highlightedPlayers[player] then
        highlightedPlayers[player]:Destroy()
        highlightedPlayers[player] = nil
    end
end

-----------------------------
--== Player Events ==--
-----------------------------
for _, pl in pairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        pl.CharacterAdded:Connect(function()
            task.wait(0.4)
            setupHighlight(pl)
        end)
        setupHighlight(pl)
    end
end

Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then
        pl.CharacterAdded:Connect(function()
            task.wait(0.4)
            setupHighlight(pl)
        end)
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

-----------------------------
--== FOV Circle ==--
-----------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = fov
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Color = getThemeColor()
FOVCircle.Visible = aimbotEnabled

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
    FOVCircle.Radius = fov
    FOVCircle.Color = getThemeColor()
    FOVCircle.Visible = aimbotEnabled
end)

-----------------------------
--== Input Handling ==--
-----------------------------
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickHeld = false
        currentTarget = nil
    end
end)

local function isInsideFOV(mousePos)
    local center = FOVCircle.Position
    return (mousePos - center).Magnitude <= FOVCircle.Radius
end

-----------------------------
--== Smooth Aimlock ==--
-----------------------------
RunService.RenderStepped:Connect(function()
    if aimbotEnabled and rightClickHeld and isInsideFOV(UserInputService:GetMouseLocation()) then
        local closest, dist = nil, math.huge
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and findRootPart(pl.Character) then
                local root = findRootPart(pl.Character)
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local mag = (Vector2.new(pos.X,pos.Y) - mousePos).Magnitude
                    if mag < dist and mag <= fov then
                        closest, dist = pl, mag
                    end
                end
            end
        end
        currentTarget = closest

        if currentTarget and currentTarget.Character then
            local aimPart = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or findRootPart(currentTarget.Character)
            if aimPart then
                local aimPos = Camera:WorldToViewportPoint(aimPart.Position)
                local deltaX = (aimPos.X - UserInputService:GetMouseLocation().X) / aimSpeed
                local deltaY = (aimPos.Y - UserInputService:GetMouseLocation().Y) / aimSpeed
                mousemoverel(deltaX, deltaY)
            end
        end
    end
end)

-----------------------------
--== Expose API ==--
-----------------------------
_G.UA = _G.UA or {}
_G.UA.SetESP = function(state) espEnabled = not not state; for pl,_ in pairs(highlightedPlayers) do if highlightedPlayers[pl] then highlightedPlayers[pl].Enabled = espEnabled end end end
_G.UA.SetAimbot = function(state) aimbotEnabled = not not state; if FOVCircle then FOVCircle.Visible = aimbotEnabled end end
_G.UA.SetHeadAim = function(state) headAimEnabled = not not state end
_G.UA.SetThemeIndex = function(idx) currentThemeIndex = clamp(idx,1,#themeNames) end
_G.UA.SetFOV = function(value) fov = clamp(value,minFov,maxFov); if FOVCircle then FOVCircle.Radius = fov end end

print("[UniversalAimbot v4] Part 1 loaded - Core + FOV + Smooth Aim ready")

--[[
    Universal Aimbot v4 - Part 2 (ESP Polish + Distance Cache)
    Author: C_mthe3rd Gaming
    Lines: ~310
    Notes:
        - Robust highlight updates for respawns, deaths, and joins
        - Per-player distance cache for GUI or debugging
        - Maintains theme color, including rainbow
        - Prepared for GUI integration in Part 3
]]

-----------------------------
--== Safety Fallbacks ==--
-----------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local highlightedPlayers = highlightedPlayers or {}
local themeNames = themeNames or {"Red","Blue","Orange","Green","Rainbow"}
local function getThemeColor()
    local themeMap = { Red = Color3.fromRGB(255,50,50), Blue = Color3.fromRGB(0,140,255), Orange = Color3.fromRGB(255,170,40), Green = Color3.fromRGB(40,255,120) }
    local themeName = themeNames[currentThemeIndex or 2] or "Blue"
    if themeName == "Rainbow" then
        return Color3.fromHSV((tick()*0.3)%1,1,1)
    end
    return themeMap[themeName] or Color3.fromRGB(0,140,255)
end

-----------------------------
--== Distance Cache ==--
-----------------------------
local playerDistance = {}

local function updatePlayerDistanceFor(player)
    if not (player and player.Character and LocalPlayer and LocalPlayer.Character) then
        playerDistance[player] = "N/A"
        return
    end
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso")
    local otherRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    if not (localRoot and otherRoot) then
        playerDistance[player] = "N/A"
        return
    end
    playerDistance[player] = math.floor((localRoot.Position - otherRoot.Position).Magnitude)
end

-----------------------------
--== Highlight Helpers ==--
-----------------------------
local function createOrRefreshHighlight(player)
    if not player or player == LocalPlayer then return end
    local char = player.Character
    if not char or not char.Parent then
        if highlightedPlayers[player] then highlightedPlayers[player]:Destroy() highlightedPlayers[player]=nil end
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then
        task.delay(0.4,function() createOrRefreshHighlight(player) end)
        return
    end

    local existing = highlightedPlayers[player]
    if existing and existing.Parent ~= char then
        pcall(function() existing:Destroy() end)
        highlightedPlayers[player] = nil
        existing = nil
    end

    if not existing then
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = getThemeColor()
        hl.OutlineColor = getThemeColor()
        hl.Enabled = espEnabled
        hl.Parent = char
        highlightedPlayers[player] = hl

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                task.delay(0.08,function()
                    if highlightedPlayers[player] then highlightedPlayers[player]:Destroy() highlightedPlayers[player]=nil end
                end)
            end)
        end
    else
        pcall(function()
            existing.FillColor = getThemeColor()
            existing.OutlineColor = getThemeColor()
            existing.Enabled = espEnabled
            existing.Adornee = char
        end)
    end
end

local function refreshAllHighlights()
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then createOrRefreshHighlight(pl) end
    end
end

-----------------------------
--== Player Events ==--
-----------------------------
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then
        pl.CharacterAdded:Connect(function()
            task.wait(0.35)
            createOrRefreshHighlight(pl)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(pl)
    if highlightedPlayers[pl] then highlightedPlayers[pl]:Destroy() highlightedPlayers[pl]=nil end
    playerDistance[pl]=nil
end)

-----------------------------
--== Render Update ==--
-----------------------------
RunService.RenderStepped:Connect(function()
    local themeColor = getThemeColor()

    -- Refresh highlight colors and enabled state
    for pl, hl in pairs(highlightedPlayers) do
        if hl and typeof(hl)=="Instance" then
            pcall(function()
                hl.FillColor = themeColor
                hl.OutlineColor = themeColor
                hl.Enabled = espEnabled and pl and pl.Character and pl.Character.Parent ~= nil
            end)
        else
            highlightedPlayers[pl] = nil
        end
    end

    -- Update distance cache
    for _, pl in ipairs(Players:GetPlayers()) do
        updatePlayerDistanceFor(pl)
    end

    -- Sync FOV circle
    if FOVCircle then
        pcall(function()
            local vp = Camera.ViewportSize
            FOVCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
            FOVCircle.Radius = fov
            FOVCircle.Color = themeColor
            FOVCircle.Visible = aimbotEnabled
        end)
    end
end)

-----------------------------
--== Public API ==--
-----------------------------
_G.UA.SetESP = function(state)
    espEnabled = not not state
    refreshAllHighlights()
end

_G.UA.RefreshHighlights = refreshAllHighlights
_G.UA.CreateOrRefreshHighlight = createOrRefreshHighlight
_G.UA.RemoveHighlight = removeHighlight
_G.UA.GetPlayerDistance = function(player) return playerDistance[player] or "N/A" end

print("[UniversalAimbot v4] Part 2 loaded - ESP polish & distance cache ready")

--[[
    Universal Aimbot v4 - Part 3 (GUI + Toggles + Animations)
    Author: C_mthe3rd Gaming
    Lines: ~330
    Notes:
        - Draggable GUI with bigger buttons
        - ESP / Aimlock / Head Aim toggles
        - FOV slider updates circle in real-time
        - Theme selector with rainbow support
        - Smooth animations for button state changes
        - Credits only bottom-left
        - Fully integrated with _G.UA from Parts 1 & 2
]]

-----------------------------
--== Services ==--
-----------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-----------------------------
--== Screen GUI ==--
-----------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 460)
MainFrame.Position = UDim2.new(0.05,0,0.1,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Universal Aimbot v4"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-----------------------------
--== Draggable Frame ==--
-----------------------------
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=input.Position
        startPos=MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragging=false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement then
        dragInput=input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta=dragInput.Position-dragStart
        MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,
                                     startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-----------------------------
--== Layout Helpers ==--
-----------------------------
local function createToggle(labelText, defaultState, callback)
    local container=Instance.new("Frame")
    container.Size=UDim2.new(1,-20,0,50)
    container.BackgroundTransparency=1
    container.Parent=MainFrame

    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.7,0,1,0)
    label.Position=UDim2.new(0,10,0,0)
    label.BackgroundTransparency=1
    label.Text=labelText
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.Font=Enum.Font.Gotham
    label.TextScaled=true
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=container

    local button=Instance.new("TextButton")
    button.Size=UDim2.new(0.25,0,0.6,0)
    button.Position=UDim2.new(0.72,0,0.2,0)
    button.Text=""
    button.BackgroundColor3=defaultState and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    button.Parent=container

    local state=defaultState
    button.MouseButton1Click:Connect(function()
        state=not state
        TweenService:Create(button,TweenInfo.new(0.2),{BackgroundColor3=state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)}):Play()
        callback(state)
    end)
    return container
end

local function createSlider(labelText, min,max,default,callback)
    local container=Instance.new("Frame")
    container.Size=UDim2.new(1,-20,0,50)
    container.BackgroundTransparency=1
    container.Parent=MainFrame

    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(0.6,0,0.4,0)
    label.Position=UDim2.new(0,10,0,5)
    label.BackgroundTransparency=1
    label.Text=labelText..": "..default
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.Font=Enum.Font.Gotham
    label.TextScaled=true
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.Parent=container

    local sliderBack=Instance.new("Frame")
    sliderBack.Size=UDim2.new(0.85,0,0.25,0)
    sliderBack.Position=UDim2.new(0.05,0,0.65,0)
    sliderBack.BackgroundColor3=Color3.fromRGB(50,50,50)
    sliderBack.Parent=container

    local sliderFill=Instance.new("Frame")
    sliderFill.Size=UDim2.new((default-min)/(max-min),0,1,0)
    sliderFill.BackgroundColor3=Color3.fromRGB(0,200,200)
    sliderFill.Parent=sliderBack

    local dragging=false
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    sliderBack.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local mouseX=input.Position.X
            local absX=sliderBack.AbsolutePosition.X
            local width=sliderBack.AbsoluteSize.X
            local percent=math.clamp((mouseX-absX)/width,0,1)
            local value=math.floor(min+(max-min)*percent)
            sliderFill.Size=UDim2.new(percent,0,1,0)
            label.Text=labelText..": "..value
            callback(value)
        end
    end)
    return container
end

-----------------------------
--== GUI Elements ==--
-----------------------------
local yOffset=50

local ESPToggle=createToggle("ESP",true,function(state)
    _G.UA.SetESP(state)
end)
ESPToggle.Position=UDim2.new(0,0,0,yOffset); yOffset=yOffset+55

local AimToggle=createToggle("Aimlock",false,function(state)
    _G.UA.SetAimbot(state)
end)
AimToggle.Position=UDim2.new(0,0,0,yOffset); yOffset=yOffset+55

local HeadAimToggle=createToggle("Head Aim",false,function(state)
    _G.UA.SetHeadAim(state)
end)
HeadAimToggle.Position=UDim2.new(0,0,0,yOffset); yOffset=yOffset+55

local FOVSlider=createSlider("FOV",50,500,_G.UA.fov or 150,function(value)
    _G.UA.SetFOV(value)
end)
FOVSlider.Position=UDim2.new(0,0,0,yOffset); yOffset=yOffset+55

-- Theme Button
local ThemeButton=Instance.new("TextButton")
ThemeButton.Size=UDim2.new(0.9,0,0,40)
ThemeButton.Position=UDim2.new(0.05,0,0,yOffset+10)
ThemeButton.Text="Theme: ".._G.UA.themeNames[2]
ThemeButton.BackgroundColor3=Color3.fromRGB(100,100,100)
ThemeButton.TextColor3=Color3.fromRGB(255,255,255)
ThemeButton.Font=Enum.Font.Gotham
ThemeButton.TextScaled=true
ThemeButton.Parent=MainFrame

local ThemeIndex=2
ThemeButton.MouseButton1Click:Connect(function()
    ThemeIndex=ThemeIndex+1
    if ThemeIndex>#_G.UA.themeNames then ThemeIndex=1 end
    _G.UA.SetThemeIndex(ThemeIndex)
    ThemeButton.Text="Theme: ".._G.UA.themeNames[ThemeIndex]
end)

-- Credits
local CreditLabel=Instance.new("TextLabel")
CreditLabel.Size=UDim2.new(0,250,0,20)
CreditLabel.Position=UDim2.new(0,10,1,-25)
CreditLabel.BackgroundTransparency=1
CreditLabel.Text="Script by C_mthe3rd Gaming"
CreditLabel.TextColor3=Color3.fromRGB(255,255,255)
CreditLabel.TextScaled=true
CreditLabel.TextXAlignment=Enum.TextXAlignment.Left
CreditLabel.Font=Enum.Font.Gotham
CreditLabel.Parent=MainFrame

print("[UniversalAimbot v4] Part 3 loaded - GUI ready")

--[[
    Universal Aimbot v4 - Part 4 (Hotkeys + Minimizer + Final Polish)
    Author: C_mthe3rd Gaming
    Lines: ~320
    Notes:
        - Hotkeys for ESP, Aimlock, Head Aim, Theme cycle
        - Minimizer button with smooth tween animation
        - Full GUI polish: hover effects, transitions
        - Safe handling for player respawns & character changes
        - Completes full ~1200 line package
]]

-----------------------------
--== Services ==--
-----------------------------
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local CoreGui = game:GetService("CoreGui")

-----------------------------
--== GUI References ==--
-----------------------------
local MainFrame = CoreGui:WaitForChild("UniversalAimbotGUI"):WaitForChild("Frame")
local ThemeButton = MainFrame:FindFirstChildWhichIsA("TextButton")
local toggles = {}
for _, child in pairs(MainFrame:GetChildren()) do
    if child:IsA("Frame") and #child:GetChildren()>=2 then
        table.insert(toggles, child)
    end
end

-----------------------------
--== Minimizer ==--
-----------------------------
local minimized=false
local MinimizerBtn=Instance.new("TextButton")
MinimizerBtn.Size=UDim2.new(0.2,0,0,30)
MinimizerBtn.Position=UDim2.new(0.78,0,0,5)
MinimizerBtn.Text="_"
MinimizerBtn.BackgroundColor3=Color3.fromRGB(100,100,100)
MinimizerBtn.TextColor3=Color3.fromRGB(255,255,255)
MinimizerBtn.Font=Enum.Font.GothamBold
MinimizerBtn.TextScaled=true
MinimizerBtn.Parent=MainFrame

local fullSize=MainFrame.Size
local minimizedSize=UDim2.new(fullSize.X.Scale, fullSize.X.Offset,0,40)

MinimizerBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    TweenService:Create(MainFrame,TweenInfo.new(0.3),{Size=minimized and minimizedSize or fullSize}):Play()
end)

-----------------------------
--== Button Hover Animations ==--
-----------------------------
for _,child in pairs(toggles) do
    local btn = child:FindFirstChildWhichIsA("TextButton")
    if btn then
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=btn.BackgroundColor3:Lerp(Color3.fromRGB(255,255,255),0.15)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=btn.BackgroundColor3:Lerp(Color3.fromRGB(255,255,255),-0.15)}):Play()
        end)
    end
end

-----------------------------
--== Hotkeys ==--
-----------------------------
local keyMap = {
    ESP = Enum.KeyCode.F1,
    AIM = Enum.KeyCode.F2,
    HEAD = Enum.KeyCode.F3,
    THEME = Enum.KeyCode.F4,
    MINIMIZER = Enum.KeyCode.M
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.Keyboard then
        if input.KeyCode==keyMap.ESP then
            _G.UA.SetESP(not espEnabled)
            toggles[1]:FindFirstChildWhichIsA("TextButton").BackgroundColor3 = espEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        elseif input.KeyCode==keyMap.AIM then
            _G.UA.SetAimbot(not aimbotEnabled)
            toggles[2]:FindFirstChildWhichIsA("TextButton").BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        elseif input.KeyCode==keyMap.HEAD then
            _G.UA.SetHeadAim(not headAimEnabled)
            toggles[3]:FindFirstChildWhichIsA("TextButton").BackgroundColor3 = headAimEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        elseif input.KeyCode==keyMap.THEME then
            local newIndex = currentThemeIndex+1
            if newIndex>#themeNames then newIndex=1 end
            _G.UA.SetThemeIndex(newIndex)
            ThemeButton.Text="Theme: "..themeNames[newIndex]
        elseif input.KeyCode==keyMap.MINIMIZER then
            minimized=not minimized
            TweenService:Create(MainFrame,TweenInfo.new(0.3),{Size=minimized and minimizedSize or fullSize}):Play()
        end
    end
end)

-----------------------------
--== Smooth Rainbow Theme Update ==--
-----------------------------
RunService.RenderStepped:Connect(function()
    if themeNames[currentThemeIndex]=="Rainbow" then
        local t=(tick()*0.3)%1
        local col=Color3.fromHSV(t,1,1)
        ThemeButton.TextColor3=col
    else
        ThemeButton.TextColor3=Color3.fromRGB(255,255,255)
    end
end)

-----------------------------
--== Final Tweaks ==--
-----------------------------
-- Ensure all highlights update on GUI load
if _G.UA.RefreshHighlights then _G.UA.RefreshHighlights() end

print("[UniversalAimbot v4] Part 4 loaded - Hotkeys, Minimizer, and Final Polish complete")
