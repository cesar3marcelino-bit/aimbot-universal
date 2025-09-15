--[[ 
Universal Aimbot v5 – Part 1: GUI Setup
Author: C_mthe3rd Gaming
Features: GUI, Toggles, Theme, Sliders, ESP placeholders, Stable Noclip
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Clean old GUI
if CoreGui:FindFirstChild("UniversalAimbot_GUI") then
    pcall(function() CoreGui:FindFirstChild("UniversalAimbot_GUI"):Destroy() end)
end

-- === Settings ===
local aimbotEnabled, headAimEnabled, espEnabled = false, false, true
local noclipEnabled, fullbrightEnabled = false, false
local themeNames = {"Red","Blue","Orange","Green","Rainbow"}
local currentThemeIndex = 2

-- Theme helper
local function themeColorNow()
    local name = themeNames[currentThemeIndex] or "Blue"
    if name == "Rainbow" then
        return Color3.fromHSV((tick()*0.15)%1,1,1)
    end
    local map = {
        Red = Color3.fromRGB(255,0,0),
        Blue = Color3.fromRGB(0,122,255),
        Orange = Color3.fromRGB(255,165,0),
        Green = Color3.fromRGB(0,255,0)
    }
    return map[name] or Color3.fromRGB(0,122,255)
end

-- GUI creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalAimbot_GUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0,400,0,560)
Frame.Position = UDim2.new(1,-420,0,80)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = themeColorNow()
Frame.Active = true
Frame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1,-80,1,0)
TitleLabel.Position = UDim2.new(0,12,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "UniversalAimbot v5"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Parent = TitleBar

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0,56,0,28)
MinimizeBtn.Position = UDim2.new(1,-64,0,4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
MinimizeBtn.BorderSizePixel = 2
MinimizeBtn.BorderColor3 = themeColorNow()
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeBtn.Parent = TitleBar

-- Content frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-36)
Content.Position = UDim2.new(0,0,0,36)
Content.BackgroundTransparency = 1
Content.Parent = Frame

-- Credits and Distance
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(0.7,0,0,18)
Credits.Position = UDim2.new(0,10,1,-28)
Credits.BackgroundTransparency = 1
Credits.Text = "Script By C_mthe3rd"
Credits.TextColor3 = Color3.fromRGB(180,180,180)
Credits.TextXAlignment = Enum.TextXAlignment.Left
Credits.Font = Enum.Font.SourceSans
Credits.TextSize = 14
Credits.Parent = Content

local DistanceLabel = Instance.new("TextLabel")
DistanceLabel.Size = UDim2.new(0.7,0,0,18)
DistanceLabel.Position = UDim2.new(0,10,1,-48)
DistanceLabel.BackgroundTransparency = 1
DistanceLabel.Text = "Distance: N/A"
DistanceLabel.TextColor3 = Color3.fromRGB(255,255,255)
DistanceLabel.Font = Enum.Font.SourceSansBold
DistanceLabel.TextSize = 14
DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
DistanceLabel.Parent = Content

-- Drag functionality
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Helper functions for toggle and slider
local function makeToggle(parent,text,y,initial)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-24,0,50)
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = text..": "..(initial and "On" or "Off")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

local function makeThemeButton(parent,y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-24,0,50)
    btn.Position = UDim2.new(0,12,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = themeColorNow()
    btn.Text = "Theme: "..themeNames[currentThemeIndex]
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = parent
    return btn
end

local function makeSlider(parent,labelText,y,minVal,maxVal,initialVal)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-24,0,24)
    lbl.Position = UDim2.new(0,12,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText..": "..string.format("%.2f", initialVal) -- show decimals
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-24,0,20)
    bar.Position = UDim2.new(0,12,0,y+28)
    bar.BackgroundColor3 = Color3.fromRGB(42,42,42)
    bar.BorderSizePixel = 2
    bar.BorderColor3 = themeColorNow()
    bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initialVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = themeColorNow()
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,16,0,16)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale,0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,0.5,0)
        local val = minVal + rel * (maxVal - minVal)
        -- show with two decimals (use "%.1f" for 1 decimal)
        lbl.Text = labelText..": "..string.format("%.2f", val)
        return val
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)

    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)

    return {
        Bar = bar,
        Fill = fill,
        Knob = knob,
        GetValue = function() return minVal + fill.Size.X.Scale * (maxVal - minVal) end
    }
end

local ESPBtn = makeToggle(Content,"ESP",12,true)
local AimBtn = makeToggle(Content,"Aimlock",72,false)

-- New Aimlock Strength Slider
local StrengthSlider = makeSlider(Content,"Aimlock Strength",132,0.1,1,0.5)

-- Push everything else down
local HeadBtn = makeToggle(Content,"Head Aim",192,false)
local ThemeBtn = makeThemeButton(Content,252)
local FOVSlider = makeSlider(Content,"FOV Circle Size",312,50,500,120)
local NoclipBtn = makeToggle(Content, "Noclip", 392, false)



--[[ 
Universal Aimbot v5 – Part 2: Functionality & Loops (Fixed ESP + Stable Noclip)
Author: C_mthe3rd Gaming
Features: Aimlock, ESP, Distance, Fullbright, FOV Circle, Stable Noclip
]]

-- Fullbright button
local FullbrightBtn = Instance.new("TextButton")
FullbrightBtn.Size = UDim2.new(0,40,0,40)
FullbrightBtn.Position = UDim2.new(1,-52,1,-52)
FullbrightBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
FullbrightBtn.BorderSizePixel = 2
FullbrightBtn.BorderColor3 = themeColorNow()
FullbrightBtn.Text = "☀"
FullbrightBtn.TextColor3 = Color3.fromRGB(255,255,255)
FullbrightBtn.Font = Enum.Font.SourceSansBold
FullbrightBtn.TextSize = 20
FullbrightBtn.Parent = Frame

-- Freecam hint text (just text, no icon)
local FreecamHint = Instance.new("TextLabel")
FreecamHint.Size = UDim2.new(0,120,0,20)
FreecamHint.Position = UDim2.new(1,-180,1,-44) -- next to Fullbright
FreecamHint.BackgroundTransparency = 1
FreecamHint.Text = "Shift+P For Freecam"
FreecamHint.TextColor3 = Color3.fromRGB(255,255,255)
FreecamHint.Font = Enum.Font.SourceSansBold
FreecamHint.TextSize = 14
FreecamHint.TextXAlignment = Enum.TextXAlignment.Left
FreecamHint.Parent = Frame

FullbrightBtn.MouseButton1Click:Connect(function()
    fullbrightEnabled = not fullbrightEnabled
    FullbrightBtn.BackgroundColor3 = fullbrightEnabled and Color3.fromRGB(200,200,200) or Color3.fromRGB(45,45,45)
end)

-- Noclip toggle (stable ON/OFF, unchanged)
local ClipConnection
NoclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    NoclipBtn.Text = "Noclip: "..(noclipEnabled and "On" or "Off")

    if ClipConnection then
        ClipConnection:Disconnect()
        ClipConnection = nil
    end

    if noclipEnabled and LocalPlayer.Character then
        ClipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Theme toggle
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex +1
    if currentThemeIndex > #themeNames then currentThemeIndex =1 end
    ThemeBtn.Text = "Theme: "..themeNames[currentThemeIndex]
end)

-- Other button toggles
ESPBtn.MouseButton1Click:Connect(function() 
    espEnabled = not espEnabled
    ESPBtn.Text = "ESP: "..(espEnabled and "On" or "Off") 
end)
AimBtn.MouseButton1Click:Connect(function() 
    aimbotEnabled = not aimbotEnabled
    AimBtn.Text = "Aimlock: "..(aimbotEnabled and "On" or "Off") 
end)
HeadBtn.MouseButton1Click:Connect(function() 
    headAimEnabled = not headAimEnabled
    HeadBtn.Text = "Head Aim: "..(headAimEnabled and "On" or "Off") 
end)

-- Minimize toggle
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Credits.Visible = not minimized
    DistanceLabel.Visible = not minimized
    FullbrightBtn.Visible = not minimized
    FreecamHint.Visible = not minimized   -- <-- ADD THIS LINE
    if minimized then
        Frame.Size = UDim2.new(0,400,0,36)
    else
        Frame.Size = UDim2.new(0,400,0,560)
    end
end)


-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOVSlider:GetValue()
fovCircle.Color = themeColorNow()
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Visible = aimbotEnabled
fovCircle.NumSides = 100
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ESP highlight logic
local highlightedPlayers = {}
local aiming = false
local function findRootPart(character) return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") end
local function findHeadPart(character) return character:FindFirstChild("Head") or findRootPart(character) end
local function setupESP(plr)
    if plr == LocalPlayer then return end
    if highlightedPlayers[plr] and highlightedPlayers[plr].Parent then highlightedPlayers[plr]:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Adornee = plr.Character
    hl.FillTransparency = 0.6
    hl.FillColor = themeColorNow()
    hl.OutlineColor = themeColorNow()
    hl.Enabled = espEnabled
    hl.Parent = CoreGui
    highlightedPlayers[plr] = hl
end
local function removeESP(plr) 
    if highlightedPlayers[plr] and highlightedPlayers[plr].Parent then 
        highlightedPlayers[plr]:Destroy() 
    end
    highlightedPlayers[plr]=nil 
end

-- Handle players joining/leaving and respawning (fixed)
local function onCharacterAdded(plr, char)
    task.wait(0.1)
    setupESP(plr)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        onCharacterAdded(plr, char)
    end)
    if plr.Character then
        onCharacterAdded(plr, plr.Character)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr.Character then
        onCharacterAdded(plr, plr.Character)
    end
    plr.CharacterAdded:Connect(function(char)
        onCharacterAdded(plr, char)
    end)
end

-- Main update loop
RunService.RenderStepped:Connect(function()
    local color = themeColorNow()

    -- Update GUI borders and slider colors
    Frame.BorderColor3 = color
    MinimizeBtn.BorderColor3 = color
    ESPBtn.BorderColor3 = color
    AimBtn.BorderColor3 = color
    HeadBtn.BorderColor3 = color
    ThemeBtn.BorderColor3 = color
    FOVSlider.Bar.BorderColor3 = color
    FOVSlider.Fill.BackgroundColor3 = color
	StrengthSlider.Bar.BorderColor3 = color
    StrengthSlider.Fill.BackgroundColor3 = color
    NoclipBtn.BorderColor3 = color
    FullbrightBtn.BorderColor3 = color

    -- Update FOV Circle
    fovCircle.Radius = FOVSlider:GetValue()
    fovCircle.Color = color
    fovCircle.Visible = aimbotEnabled
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    -- Update ESP highlights
    for plr, hl in pairs(highlightedPlayers) do
        if hl then
            hl.FillColor = color
            hl.OutlineColor = color
            hl.Enabled = espEnabled
        end
    end
    if highlightedPlayers[LocalPlayer] then
        highlightedPlayers[LocalPlayer].Enabled = false
    end

    -- Distance meter
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
            local root = findRootPart(plr.Character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    if closest and closestDist <= FOVSlider:GetValue() then
        local root = findRootPart(closest.Character)
        local distanceStuds = (Camera.CFrame.Position - root.Position).Magnitude
        DistanceLabel.Text = string.format("Distance: %s (%.2f)", closest.Name, distanceStuds)
    else
        DistanceLabel.Text = "Distance: N/A"
    end

    -- Aimlock logic
    if aimbotEnabled and aiming then
        local target, targetDist = nil, FOVSlider:GetValue()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and findRootPart(plr.Character) then
                local root = findRootPart(plr.Character)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist <= targetDist then
                        targetDist = dist
                        target = plr
                    end
                end
            end
        end
        if target and target.Character then
            local part = headAimEnabled and findHeadPart(target.Character) or findRootPart(target.Character)
            if part then
               Camera.CFrame = Camera.CFrame:Lerp(
    CFrame.new(Camera.CFrame.Position, part.Position + (part.Velocity or Vector3.new())*0.1),
    StrengthSlider:GetValue()
)
            end
        end
    end

    -- Fullbright logic
    if fullbrightEnabled then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
    end
end)

-- Aim toggle with right-click inside FOV
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mousePos = UserInputService:GetMouseLocation()
        if (mousePos - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude <= FOVSlider:GetValue() then
            aiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-----------------------------------------------------------------------
-- Freecam
-- Cinematic free camera for spectating and video production.
-- Shift+P to toggle freecam
-- Q and E to go up and down
-- Have fun!
------------------------------------------------------------------------
 
function sandbox(var,func)
local env = getfenv(func)
local newenv = setmetatable({},{
__index = function(self,k)
if k=="script" then
return var
else
return env[k]
end
end,
})
setfenv(func,newenv)
return func
end
cors = {}
mas = Instance.new("Model",game:GetService("Lighting"))
LocalScript0 = Instance.new("LocalScript")
LocalScript0.Name = "FreeCamera"
LocalScript0.Parent = mas
table.insert(cors,sandbox(LocalScript0,function()
 
local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan
 
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
 
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
LocalPlayer = Players.LocalPlayer
end
 
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
local newCamera = workspace.CurrentCamera
if newCamera then
Camera = newCamera
end
end)
 
------------------------------------------------------------------------
 
local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
 
local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300
 
local PITCH_LIMIT = rad(90)
 
local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = 1.0
local FOV_STIFFNESS = 4.0
 
------------------------------------------------------------------------
 
local Spring = {} do
Spring.__index = Spring
 
function Spring.new(freq, pos)
local self = setmetatable({}, Spring)
self.f = freq
self.p = pos
self.v = pos*0
return self
end
 
function Spring:Update(dt, goal)
local f = self.f*2*pi
local p0 = self.p
local v0 = self.v
 
local offset = goal - p0
local decay = exp(-f*dt)
 
local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
local v1 = (f*dt*(offset*f - v0) + v0)*decay
 
self.p = p1
self.v = v1
 
return p1
end
 
function Spring:Reset(pos)
self.p = pos
self.v = pos*0
end
end
 
------------------------------------------------------------------------
 
local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0
 
local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)
 
------------------------------------------------------------------------
 
local Input = {} do
local thumbstickCurve do
local K_CURVATURE = 2.0
local K_DEADZONE = 0.15
 
local function fCurve(x)
return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
end
 
local function fDeadzone(x)
return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
end
 
function thumbstickCurve(x)
return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
end
end
 
local gamepad = {
ButtonX = 0,
ButtonY = 0,
DPadDown = 0,
DPadUp = 0,
ButtonL2 = 0,
ButtonR2 = 0,
Thumbstick1 = Vector2.new(),
Thumbstick2 = Vector2.new(),
}
 
local keyboard = {
W = 0,
A = 0,
S = 0,
D = 0,
E = 0,
Q = 0,
U = 0,
H = 0,
J = 0,
K = 0,
I = 0,
Y = 0,
Up = 0,
Down = 0,
LeftShift = 0,
RightShift = 0,
}
 
local mouse = {
Delta = Vector2.new(),
MouseWheel = 0,
}
 
local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
local FOV_WHEEL_SPEED    = 1.0
local FOV_GAMEPAD_SPEED  = 0.25
local NAV_ADJ_SPEED      = 0.75
local NAV_SHIFT_MUL      = 0.25
 
local navSpeed = 1
 
function Input.Vel(dt)
navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)
 
local kGamepad = Vector3.new(
thumbstickCurve(gamepad.Thumbstick1.x),
thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
thumbstickCurve(-gamepad.Thumbstick1.y)
)*NAV_GAMEPAD_SPEED
 
local kKeyboard = Vector3.new(
keyboard.D - keyboard.A + keyboard.K - keyboard.H,
keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
keyboard.S - keyboard.W + keyboard.J - keyboard.U
)*NAV_KEYBOARD_SPEED
 
local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
 
return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
end
 
function Input.Pan(dt)
local kGamepad = Vector2.new(
thumbstickCurve(gamepad.Thumbstick2.y),
thumbstickCurve(-gamepad.Thumbstick2.x)
)*PAN_GAMEPAD_SPEED
local kMouse = mouse.Delta*PAN_MOUSE_SPEED
mouse.Delta = Vector2.new()
return kGamepad + kMouse
end
 
function Input.Fov(dt)
local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
mouse.MouseWheel = 0
return kGamepad + kMouse
end
 
do
local function Keypress(action, state, input)
keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
return Enum.ContextActionResult.Sink
end
 
local function GpButton(action, state, input)
gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
return Enum.ContextActionResult.Sink
end
 
local function MousePan(action, state, input)
local delta = input.Delta
mouse.Delta = Vector2.new(-delta.y, -delta.x)
return Enum.ContextActionResult.Sink
end
 
local function Thumb(action, state, input)
gamepad[input.KeyCode.Name] = input.Position
return Enum.ContextActionResult.Sink
end
 
local function Trigger(action, state, input)
gamepad[input.KeyCode.Name] = input.Position.z
return Enum.ContextActionResult.Sink
end
 
local function MouseWheel(action, state, input)
mouse[input.UserInputType.Name] = -input.Position.z
return Enum.ContextActionResult.Sink
end
 
local function Zero(t)
for k, v in pairs(t) do
t[k] = v*0
end
end
 
function Input.StartCapture()
ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
Enum.KeyCode.W, Enum.KeyCode.U,
Enum.KeyCode.A, Enum.KeyCode.H,
Enum.KeyCode.S, Enum.KeyCode.J,
Enum.KeyCode.D, Enum.KeyCode.K,
Enum.KeyCode.E, Enum.KeyCode.I,
Enum.KeyCode.Q, Enum.KeyCode.Y,
Enum.KeyCode.Up, Enum.KeyCode.Down
)
ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
end
 
function Input.StopCapture()
navSpeed = 1
Zero(gamepad)
Zero(keyboard)
Zero(mouse)
ContextActionService:UnbindAction("FreecamKeyboard")
ContextActionService:UnbindAction("FreecamMousePan")
ContextActionService:UnbindAction("FreecamMouseWheel")
ContextActionService:UnbindAction("FreecamGamepadButton")
ContextActionService:UnbindAction("FreecamGamepadTrigger")
ContextActionService:UnbindAction("FreecamGamepadThumbstick")
end
end
end
 
local function GetFocusDistance(cameraFrame)
local znear = 0.1
local viewport = Camera.ViewportSize
local projy = 2*tan(cameraFov/2)
local projx = viewport.x/viewport.y*projy
local fx = cameraFrame.rightVector
local fy = cameraFrame.upVector
local fz = cameraFrame.lookVector
 
local minVect = Vector3.new()
local minDist = 512
 
for x = 0, 1, 0.5 do
for y = 0, 1, 0.5 do
local cx = (x - 0.5)*projx
local cy = (y - 0.5)*projy
local offset = fx*cx - fy*cy + fz
local origin = cameraFrame.p + offset*znear
local part, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
local dist = (hit - origin).magnitude
if minDist > dist then
minDist = dist
minVect = offset.unit
end
end
end
 
return fz:Dot(minVect)*minDist
end
 
------------------------------------------------------------------------
 
local function StepFreecam(dt)
local vel = velSpring:Update(dt, Input.Vel(dt))
local pan = panSpring:Update(dt, Input.Pan(dt))
local fov = fovSpring:Update(dt, Input.Fov(dt))
 
local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))
 
cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))
 
local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
cameraPos = cameraCFrame.p
 
Camera.CFrame = cameraCFrame
Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
Camera.FieldOfView = cameraFov
end
 
------------------------------------------------------------------------
 
local PlayerState = {} do
local mouseIconEnabled
local cameraSubject
local cameraType
local cameraFocus
local cameraCFrame
local cameraFieldOfView
local screenGuis = {}
local coreGuis = {
Backpack = true,
Chat = true,
Health = true,
PlayerList = true,
}
local setCores = {
BadgesNotificationsActive = true,
PointsNotificationsActive = true,
}
 
-- Save state and set up for freecam
function PlayerState.Push()
for name in pairs(coreGuis) do
coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
end
for name in pairs(setCores) do
setCores[name] = StarterGui:GetCore(name)
StarterGui:SetCore(name, false)
end
local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if playergui then
for _, gui in pairs(playergui:GetChildren()) do
if gui:IsA("ScreenGui") and gui.Enabled then
screenGuis[#screenGuis + 1] = gui
gui.Enabled = false
end
end
end
 
cameraFieldOfView = Camera.FieldOfView
Camera.FieldOfView = 70
 
cameraType = Camera.CameraType
Camera.CameraType = Enum.CameraType.Custom
 
cameraSubject = Camera.CameraSubject
Camera.CameraSubject = nil
 
cameraCFrame = Camera.CFrame
cameraFocus = Camera.Focus
 
mouseIconEnabled = UserInputService.MouseIconEnabled
UserInputService.MouseIconEnabled = false
 
mouseBehavior = UserInputService.MouseBehavior
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end
 
-- Restore state
function PlayerState.Pop()
for name, isEnabled in pairs(coreGuis) do
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
end
for name, isEnabled in pairs(setCores) do
StarterGui:SetCore(name, isEnabled)
end
for _, gui in pairs(screenGuis) do
if gui.Parent then
gui.Enabled = true
end
end
 
Camera.FieldOfView = cameraFieldOfView
cameraFieldOfView = nil
 
Camera.CameraType = cameraType
cameraType = nil
 
Camera.CameraSubject = cameraSubject
cameraSubject = nil
 
Camera.CFrame = cameraCFrame
cameraCFrame = nil
 
Camera.Focus = cameraFocus
cameraFocus = nil
 
UserInputService.MouseIconEnabled = mouseIconEnabled
mouseIconEnabled = nil
 
UserInputService.MouseBehavior = mouseBehavior
mouseBehavior = nil
end
end
 
local function StartFreecam()
local cameraCFrame = Camera.CFrame
cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
cameraPos = cameraCFrame.p
cameraFov = Camera.FieldOfView
 
velSpring:Reset(Vector3.new())
panSpring:Reset(Vector2.new())
fovSpring:Reset(0)
 
PlayerState.Push()
RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
Input.StartCapture()
end
 
local function StopFreecam()
Input.StopCapture()
RunService:UnbindFromRenderStep("Freecam")
PlayerState.Pop()
end
 
------------------------------------------------------------------------
 
do
local enabled = false
 
local function ToggleFreecam()
if enabled then
StopFreecam()
else
StartFreecam()
end
enabled = not enabled
end
 
local function CheckMacro(macro)
for i = 1, #macro - 1 do
if not UserInputService:IsKeyDown(macro[i]) then
return
end
end
ToggleFreecam()
end
 
local function HandleActivationInput(action, state, input)
if state == Enum.UserInputState.Begin then
if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
CheckMacro(FREECAM_MACRO_KB)
end
end
return Enum.ContextActionResult.Pass
end
 
ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
end
end))
for i,v in pairs(mas:GetChildren()) do
v.Parent = game:GetService("Players").LocalPlayer.PlayerGui
pcall(function() v:MakeJoints() end)
end
mas:Destroy()
for i,v in pairs(cors) do
spawn(function()
pcall(v)
end)
end
