-- ============================================================================
-- [PRO UTILITY ENGINE v12 - FINAL MASTER EDITION]
-- ============================================================================

local ScreenGuiName = "ModernSpeedMenu_ProV12"
local CoreGui = game:GetService("CoreGui")

-- 1. ADVANCED ANTI-DUPLICATION & GLOBAL CLEANUP PIPELINE
if _G.ProUtilityCleanup then
    pcall(function()
        _G.ProUtilityCleanup() -- Forcefully run the old script's entire shutdown loop
    end)
    _G.ProUtilityCleanup = nil
    task.wait(0.1) -- Small delay to allow the game engine to clear threads safely
end

-- Fallback UI check
local existingGui = CoreGui:FindFirstChild(ScreenGuiName) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(ScreenGuiName)
if existingGui then 
    pcall(function() existingGui:Destroy() end) 
end

-- 2. CORE CONFIGURATION & PHYSICS STATES
local TargetSpeed = 100
local SpeedKey = Enum.KeyCode.LeftControl
local IsHoldingSpeed = false
local LiveNormalSpeed = 16

local TargetJump = 50
local JumpEnabled = false
local IsHoldingSpace = false
local LiveNormalJump = 50

local NoclipEnabled = false
local NoclipKey = Enum.KeyCode.V

local TargetFlySpeed = 100
local FlyKey = nil 
local FlyEnabled = false
local bv, bg 

local InteractEnabled = false
local PromptMemoryBank = {}

-- Hide/Show Toggle Configurations
local ToggleKey = Enum.KeyCode.Insert 
local GuiVisible = true
local SavedPosition = UDim2.new(0.05, 0, 0.2, 0) 

-- Visual Modifiers Config
local FullBrightEnabled = false
local NoFogEnabled = false
local OriginalLighting = {
    Ambient = game:GetService("Lighting").Ambient,
    OutdoorAmbient = game:GetService("Lighting").OutdoorAmbient,
    ColorShift_Top = game:GetService("Lighting").ColorShift_Top,
    ColorShift_Bottom = game:GetService("Lighting").ColorShift_Bottom,
    ClockTime = game:GetService("Lighting").ClockTime,
    FogStart = game:GetService("Lighting").FogStart,
    FogEnd = game:GetService("Lighting").FogEnd
}

local IsBindingSpeed = false
local IsBindingNoclip = false
local IsBindingFly = false
local IsBindingHide = false
local MenuExpanded = false
local ScriptRunning = true 

-- ROBLOX CORE ENGINE SERVICES
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

-- ============================================================================
-- 3. MODERNIZED INTERACTIVE GUI STRUCTURE
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenGuiName
local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Master Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 260) 
MainFrame.Position = SavedPosition
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true 
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 25)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  PRO UTILITY ENGINE"
TitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
TitleLabel.TextSize = 11
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local KillButton = Instance.new("TextButton")
KillButton.Size = UDim2.new(0, 24, 0, 18)
KillButton.Position = UDim2.new(1, -30, 0, 4)
KillButton.BackgroundColor3 = Color3.fromRGB(45, 20, 20)
KillButton.BorderSizePixel = 0
KillButton.Text = "X"
KillButton.TextColor3 = Color3.fromRGB(255, 75, 75)
KillButton.TextSize = 11
KillButton.Font = Enum.Font.GothamBold
KillButton.Parent = MainFrame
Instance.new("UICorner", KillButton).CornerRadius = UDim.new(0, 4)

local function createRow(text, yPos, parentFrame)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -16, 0, 32)
    row.Position = UDim2.new(0, 8, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    row.BorderSizePixel = 0
    row.Parent = parentFrame or MainFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    return row
end

-- Base Standard Rows
local SpeedRow = createRow("Speed", 28)
local JumpRow = createRow("InfJump", 66)
local NoclipRow = createRow("Noclip", 104)
local FlyRow = createRow("Fly", 142)
local HideRow = createRow("HideGui", 180) 

-- Separated Expansion Container Frame
local HiddenContainer = Instance.new("Frame")
HiddenContainer.Size = UDim2.new(1, 0, 0, 160)
HiddenContainer.Position = UDim2.new(0, 0, 0, 253)
HiddenContainer.BackgroundTransparency = 1
HiddenContainer.Parent = MainFrame

local TPRow = createRow("Teleport", 0, HiddenContainer)
local InteractRow = createRow("FastInteract", 38, HiddenContainer)
local FullBrightRow = createRow("FullBright", 76, HiddenContainer)
local NoFogRow = createRow("NoFog", 114, HiddenContainer)

-- --- 3A. ROW INTERNALS CONFIGURATION ---
-- Speed Components
local SpeedLiveLabel = Instance.new("TextLabel")
SpeedLiveLabel.Size = UDim2.new(0, 40, 1, 0)
SpeedLiveLabel.Position = UDim2.new(0, 62, 0, 0)
SpeedLiveLabel.BackgroundTransparency = 1
SpeedLiveLabel.Text = tostring(LiveNormalSpeed)
SpeedLiveLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
SpeedLiveLabel.TextSize = 12
SpeedLiveLabel.Font = Enum.Font.Code
SpeedLiveLabel.Parent = SpeedRow

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 85, 0, 22)
SpeedInput.Position = UDim2.new(0, 112, 0.5, -11)
SpeedInput.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
SpeedInput.Text = tostring(TargetSpeed)
SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 150)
SpeedInput.TextSize = 12
SpeedInput.Font = Enum.Font.Code
SpeedInput.Parent = SpeedRow
Instance.new("UICorner", SpeedInput).CornerRadius = UDim.new(0, 4)

local SpeedBindButton = Instance.new("TextButton")
SpeedBindButton.Size = UDim2.new(0, 110, 0, 22)
SpeedBindButton.Position = UDim2.new(1, -118, 0.5, -11)
SpeedBindButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
SpeedBindButton.Text = SpeedKey.Name
SpeedBindButton.TextColor3 = Color3.fromRGB(0, 200, 255)
SpeedBindButton.TextSize = 12
SpeedBindButton.Font = Enum.Font.Code
SpeedBindButton.Parent = SpeedRow
Instance.new("UICorner", SpeedBindButton).CornerRadius = UDim.new(0, 4)

-- Jump Components
local JumpLiveLabel = Instance.new("TextLabel")
JumpLiveLabel.Size = UDim2.new(0, 40, 1, 0)
JumpLiveLabel.Position = UDim2.new(0, 62, 0, 0)
JumpLiveLabel.BackgroundTransparency = 1
JumpLiveLabel.Text = tostring(LiveNormalJump)
JumpLiveLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
JumpLiveLabel.TextSize = 12
JumpLiveLabel.Font = Enum.Font.Code
JumpLiveLabel.Parent = JumpRow -- Re-added cleanly!

local JumpInput = Instance.new("TextBox")
JumpInput.Size = UDim2.new(0, 85, 0, 22)
JumpInput.Position = UDim2.new(0, 112, 0.5, -11)
JumpInput.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
JumpInput.Text = tostring(TargetJump)
JumpInput.TextColor3 = Color3.fromRGB(255, 200, 0)
JumpInput.TextSize = 12
JumpInput.Font = Enum.Font.Code
JumpInput.Parent = JumpRow 
Instance.new("UICorner", JumpInput).CornerRadius = UDim.new(0, 4)

local JumpToggleButton = Instance.new("TextButton")
JumpToggleButton.Size = UDim2.new(0, 110, 0, 22)
JumpToggleButton.Position = UDim2.new(1, -118, 0.5, -11)
JumpToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
JumpToggleButton.Text = "OFF"
JumpToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
JumpToggleButton.TextSize = 12
JumpToggleButton.Font = Enum.Font.Code
JumpToggleButton.Parent = JumpRow
Instance.new("UICorner", JumpToggleButton).CornerRadius = UDim.new(0, 4)

-- Noclip Components
local NoclipStatusLabel = Instance.new("TextLabel")
NoclipStatusLabel.Size = UDim2.new(0, 85, 0, 22)
NoclipStatusLabel.Position = UDim2.new(0, 112, 0.5, -11)
NoclipStatusLabel.BackgroundTransparency = 1
NoclipStatusLabel.Text = "STATUS: OFF"
NoclipStatusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
NoclipStatusLabel.TextSize = 11
NoclipStatusLabel.Font = Enum.Font.Code
NoclipStatusLabel.Parent = NoclipRow

local NoclipBindButton = Instance.new("TextButton")
NoclipBindButton.Size = UDim2.new(0, 110, 0, 22)
NoclipBindButton.Position = UDim2.new(1, -118, 0.5, -11)
NoclipBindButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
NoclipBindButton.Text = NoclipKey.Name
NoclipBindButton.TextColor3 = Color3.fromRGB(0, 200, 255)
NoclipBindButton.TextSize = 12
NoclipBindButton.Font = Enum.Font.Code
NoclipBindButton.Parent = NoclipRow
Instance.new("UICorner", NoclipBindButton).CornerRadius = UDim.new(0, 4)

-- Fly Components
local FlyStatusLabel = Instance.new("TextLabel")
FlyStatusLabel.Size = UDim2.new(0, 40, 1, 0)
FlyStatusLabel.Position = UDim2.new(0, 62, 0, 0)
FlyStatusLabel.BackgroundTransparency = 1
FlyStatusLabel.Text = "OFF"
FlyStatusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
FlyStatusLabel.TextSize = 12
FlyStatusLabel.Font = Enum.Font.Code
FlyStatusLabel.Parent = FlyRow

local FlyInput = Instance.new("TextBox")
FlyInput.Size = UDim2.new(0, 85, 0, 22)
FlyInput.Position = UDim2.new(0, 112, 0.5, -11)
FlyInput.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
FlyInput.Text = tostring(TargetFlySpeed)
FlyInput.TextColor3 = Color3.fromRGB(180, 75, 255)
FlyInput.TextSize = 12
FlyInput.Font = Enum.Font.Code
FlyInput.Parent = FlyRow
Instance.new("UICorner", FlyInput).CornerRadius = UDim.new(0, 4)

local FlyBindButton = Instance.new("TextButton")
FlyBindButton.Size = UDim2.new(0, 110, 0, 22)
FlyBindButton.Position = UDim2.new(1, -118, 0.5, -11)
FlyBindButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
FlyBindButton.Text = "[ None ]"
FlyBindButton.TextColor3 = Color3.fromRGB(180, 180, 180)
FlyBindButton.TextSize = 12
FlyBindButton.Font = Enum.Font.Code
FlyBindButton.Parent = FlyRow
Instance.new("UICorner", FlyBindButton).CornerRadius = UDim.new(0, 4)

-- Hide GUI Keybind Button Components
local HideDescLabel = Instance.new("TextLabel")
HideDescLabel.Size = UDim2.new(0, 120, 1, 0)
HideDescLabel.Position = UDim2.new(0, 95, 0, 0)
HideDescLabel.BackgroundTransparency = 1
HideDescLabel.Text = "Toggle Visibility"
HideDescLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
HideDescLabel.TextSize = 11
HideDescLabel.Font = Enum.Font.Gotham
HideDescLabel.TextXAlignment = Enum.TextXAlignment.Left
HideDescLabel.Parent = HideRow

local HideBindButton = Instance.new("TextButton")
HideBindButton.Size = UDim2.new(0, 110, 0, 22)
HideBindButton.Position = UDim2.new(1, -118, 0.5, -11)
HideBindButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
HideBindButton.Text = ToggleKey.Name
HideBindButton.TextColor3 = Color3.fromRGB(230, 230, 230)
HideBindButton.TextSize = 12
HideBindButton.Font = Enum.Font.Code
HideBindButton.Parent = HideRow
Instance.new("UICorner", HideBindButton).CornerRadius = UDim.new(0, 4)

-- Teleport Components
local TPStatusLabel = Instance.new("TextLabel")
TPStatusLabel.Size = UDim2.new(0, 120, 1, 0)
TPStatusLabel.Position = UDim2.new(0, 95, 0, 0)
TPStatusLabel.BackgroundTransparency = 1
TPStatusLabel.Text = "Spawn standard tool"
TPStatusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
TPStatusLabel.TextSize = 11
TPStatusLabel.Font = Enum.Font.Gotham
TPStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
TPStatusLabel.Parent = TPRow

local TPButton = Instance.new("TextButton")
TPButton.Size = UDim2.new(0, 110, 0, 22)
TPButton.Position = UDim2.new(1, -118, 0.5, -11)
TPButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
TPButton.Text = "Get TP Tool"
TPButton.TextColor3 = Color3.fromRGB(255, 130, 0)
TPButton.TextSize = 12
TPButton.Font = Enum.Font.Code
TPButton.Parent = TPRow
Instance.new("UICorner", TPButton).CornerRadius = UDim.new(0, 4)

-- Interact Components
local InteractTimeLabel = Instance.new("TextLabel")
InteractTimeLabel.Size = UDim2.new(0, 60, 1, 0)
InteractTimeLabel.Position = UDim2.new(0, 95, 0, 0)
InteractTimeLabel.BackgroundTransparency = 1
InteractTimeLabel.Text = "0s - 15s"
InteractTimeLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
InteractTimeLabel.TextSize = 12
InteractTimeLabel.Font = Enum.Font.Code
InteractTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
InteractTimeLabel.Parent = InteractRow

local InteractToggleButton = Instance.new("TextButton")
InteractToggleButton.Size = UDim2.new(0, 110, 0, 22)
InteractToggleButton.Position = UDim2.new(1, -118, 0.5, -11)
InteractToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
InteractToggleButton.Text = "OFF"
InteractToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
InteractToggleButton.TextSize = 12
InteractToggleButton.Font = Enum.Font.Code
InteractToggleButton.Parent = InteractRow
Instance.new("UICorner", InteractToggleButton).CornerRadius = UDim.new(0, 4)

-- Full Bright Components
local FullBrightDescLabel = Instance.new("TextLabel")
FullBrightDescLabel.Size = UDim2.new(0, 120, 1, 0)
FullBrightDescLabel.Position = UDim2.new(0, 95, 0, 0)
FullBrightDescLabel.BackgroundTransparency = 1
FullBrightDescLabel.Text = "Force Day Ambient"
FullBrightDescLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
FullBrightDescLabel.TextSize = 11
FullBrightDescLabel.Font = Enum.Font.Gotham
FullBrightDescLabel.TextXAlignment = Enum.TextXAlignment.Left
FullBrightDescLabel.Parent = FullBrightRow

local FullBrightToggleButton = Instance.new("TextButton")
FullBrightToggleButton.Size = UDim2.new(0, 110, 0, 22)
FullBrightToggleButton.Position = UDim2.new(1, -118, 0.5, -11)
FullBrightToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
FullBrightToggleButton.Text = "OFF"
FullBrightToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
FullBrightToggleButton.TextSize = 12
FullBrightToggleButton.Font = Enum.Font.Code
FullBrightToggleButton.Parent = FullBrightRow
Instance.new("UICorner", FullBrightToggleButton).CornerRadius = UDim.new(0, 4)

-- No Fog Components
local NoFogDescLabel = Instance.new("TextLabel")
NoFogDescLabel.Size = UDim2.new(0, 120, 1, 0)
NoFogDescLabel.Position = UDim2.new(0, 95, 0, 0)
NoFogDescLabel.BackgroundTransparency = 1
NoFogDescLabel.Text = "Clear Far Vision"
NoFogDescLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
NoFogDescLabel.TextSize = 11
NoFogDescLabel.Font = Enum.Font.Gotham
NoFogDescLabel.TextXAlignment = Enum.TextXAlignment.Left
NoFogDescLabel.Parent = NoFogRow

local NoFogToggleButton = Instance.new("TextButton")
NoFogToggleButton.Size = UDim2.new(0, 110, 0, 22)
NoFogToggleButton.Position = UDim2.new(1, -118, 0.5, -11)
NoFogToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
NoFogToggleButton.Text = "OFF"
NoFogToggleButton.TextColor3 = Color3.fromRGB(255, 75, 75)
NoFogToggleButton.TextSize = 12
NoFogToggleButton.Font = Enum.Font.Code
NoFogToggleButton.Parent = NoFogRow
Instance.new("UICorner", NoFogToggleButton).CornerRadius = UDim.new(0, 4)

-- Menu Expand Control Button
local ExpandButton = Instance.new("TextButton")
ExpandButton.Size = UDim2.new(1, -16, 0, 22)
ExpandButton.Position = UDim2.new(0, 8, 0, 220) 
ExpandButton.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
ExpandButton.BorderSizePixel = 0
ExpandButton.Text = "more"
ExpandButton.TextColor3 = Color3.fromRGB(160, 160, 160)
ExpandButton.TextSize = 11
ExpandButton.Font = Enum.Font.GothamBold
ExpandButton.Parent = MainFrame
Instance.new("UICorner", ExpandButton).CornerRadius = UDim.new(0, 4)

-- Visual Bottom Accent Line
local RainbowLine = Instance.new("Frame")
RainbowLine.Size = UDim2.new(1, 0, 0, 3)
RainbowLine.Position = UDim2.new(0, 0, 1, -3)
RainbowLine.BorderSizePixel = 0
RainbowLine.Parent = MainFrame
Instance.new("UICorner", RainbowLine).CornerRadius = UDim.new(0, 6)

-- Track dragging positions continuously so we can return cleanly when unhiding
MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    if GuiVisible then
        SavedPosition = MainFrame.Position
    end
end)

-- ============================================================================
-- 4. RUNTIME SYSTEM ENGINES & FUNCTIONAL LOOP HOOKS
-- ============================================================================

-- Chroma Rainbow Accent Loop Thread
task.spawn(function()
    while ScriptRunning and MainFrame and MainFrame.Parent do
        for i = 0, 1, 0.005 do
            if not RainbowLine or not RainbowLine.Parent then break end
            RainbowLine.BackgroundColor3 = Color3.fromHSV(i, 0.8, 0.9)
            task.wait(0.015)
        end
    end
end)

-- Runtime Environment Active Value Scraper Loop
task.spawn(function()
    while ScriptRunning and MainFrame and MainFrame.Parent do
        local hum = getHumanoid()
        if hum then
            if not IsHoldingSpeed then
                LiveNormalSpeed = hum.WalkSpeed
                SpeedLiveLabel.Text = tostring(math.round(LiveNormalSpeed))
            end
            if not IsHoldingSpace then
                LiveNormalJump = hum.UseJumpPower and hum.JumpPower or hum.JumpHeight
                JumpLiveLabel.Text = tostring(math.round(LiveNormalJump))
            end
        end
        task.wait(0.3)
    end
end)

-- Continuous Environment Visual Modifier Core Loop
task.spawn(function()
    while ScriptRunning do
        if FullBrightEnabled then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
            Lighting.ClockTime = 14
        end
        if NoFogEnabled then
            Lighting.FogStart = 0
            Lighting.FogEnd = 999999
        end
        task.wait(1)
    end
end)

-- ============================================================================
-- [ MANUAL HEIGHT CONFIGURATION SECTION ]
-- ============================================================================
ExpandButton.MouseButton1Click:Connect(function()
    MenuExpanded = not MenuExpanded
    
    local ClosedWindowHeight = 260   
    local OpenedWindowHeight = 440   
    local ClosedButtonYPos   = 220   
    local OpenedButtonYPos   = 402   
    
    local targetHeight = MenuExpanded and OpenedWindowHeight or ClosedWindowHeight
    local buttonText = MenuExpanded and "close" or "more"
    local buttonYPos = MenuExpanded and OpenedButtonYPos or ClosedButtonYPos
    
    ExpandButton.Text = buttonText
    
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 340, 0, targetHeight)}):Play()
    TweenService:Create(ExpandButton, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 8, 0, buttonYPos)}):Play()
end)

-- Unified Destroy Pipeline (Used by Kill Switch and Auto-Execution Replacements)
local function cleanupActiveScript()
    ScriptRunning = false
    
    -- Clear physics items perfectly
    if bv then pcall(function() bv:Destroy() end) bv = nil end
    if bg then pcall(function() bg:Destroy() end) bg = nil end
    
    -- Revert interaction prompts
    for prompt, originalDuration in pairs(PromptMemoryBank) do
        if prompt and prompt.Parent then pcall(function() prompt.HoldDuration = originalDuration end) end
    end
    table.clear(PromptMemoryBank)
    
    -- Restore lighting environments
    pcall(function()
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
    end)
    
    -- Revert Speed values
    local hum = getHumanoid()
    if hum then pcall(function() hum.WalkSpeed = LiveNormalSpeed end) end
    
    -- Safely drop UI elements
    pcall(function() ScreenGui:Destroy() end)
end

-- Wire the Kill Switch up
KillButton.MouseButton1Click:Connect(cleanupActiveScript)

-- Bind cleanup into global memory bank so Solara execution checks can force access it next run
_G.ProUtilityCleanup = cleanupActiveScript

-- Input Focus Formats
SpeedInput.FocusLost:Connect(function() TargetSpeed = tonumber(SpeedInput.Text) or TargetSpeed; SpeedInput.Text = tostring(TargetSpeed) end)
JumpInput.FocusLost:Connect(function() TargetJump = tonumber(JumpInput.Text) or TargetJump; JumpInput.Text = tostring(TargetJump) end)
FlyInput.FocusLost:Connect(function() TargetFlySpeed = tonumber(FlyInput.Text) or TargetFlySpeed; FlyInput.Text = tostring(TargetFlySpeed) end)

-- Keybind Set Triggers
SpeedBindButton.MouseButton1Click:Connect(function() if not IsBindingSpeed and not IsBindingNoclip and not IsBindingFly and not IsBindingHide then IsBindingSpeed = true; SpeedBindButton.Text = "..."; SpeedBindButton.TextColor3 = Color3.fromRGB(255, 150, 0) end end)
NoclipBindButton.MouseButton1Click:Connect(function() if not IsBindingSpeed and not IsBindingNoclip and not IsBindingFly and not IsBindingHide then IsBindingNoclip = true; NoclipBindButton.Text = "..."; NoclipBindButton.TextColor3 = Color3.fromRGB(255, 150, 0) end end)
FlyBindButton.MouseButton1Click:Connect(function() if not IsBindingSpeed and not IsBindingNoclip and not IsBindingFly and not IsBindingHide then IsBindingFly = true; FlyBindButton.Text = "..."; FlyBindButton.TextColor3 = Color3.fromRGB(255, 150, 0) end end)
HideBindButton.MouseButton1Click:Connect(function() if not IsBindingSpeed and not IsBindingNoclip and not IsBindingFly and not IsBindingHide then IsBindingHide = true; HideBindButton.Text = "..."; HideBindButton.TextColor3 = Color3.fromRGB(230, 230, 230); IsBindingHide = false; return end end)

JumpToggleButton.MouseButton1Click:Connect(function()
    JumpEnabled = not JumpEnabled
    JumpToggleButton.Text = JumpEnabled and "ON" or "OFF"
    JumpToggleButton.TextColor3 = JumpEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    if not JumpEnabled then IsHoldingSpace = false end
end)

-- Full Bright Button Toggles
FullBrightToggleButton.MouseButton1Click:Connect(function()
    FullBrightEnabled = not FullBrightEnabled
    FullBrightToggleButton.Text = FullBrightEnabled and "ON" or "OFF"
    FullBrightToggleButton.TextColor3 = FullBrightEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    if not FullBrightEnabled then
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
        Lighting.ClockTime = OriginalLighting.ClockTime
    end
end)

-- No Fog Button Toggles
NoFogToggleButton.MouseButton1Click:Connect(function()
    NoFogEnabled = not NoFogEnabled
    NoFogToggleButton.Text = NoFogEnabled and "ON" or "OFF"
    NoFogToggleButton.TextColor3 = NoFogEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    if not NoFogEnabled then
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
    end
end)

-- Backpack Teleport Spawner
TPButton.MouseButton1Click:Connect(function()
    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        if char then char:MoveTo(LocalPlayer:GetMouse().Hit.Position) end
    end)
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
    TPStatusLabel.Text = "Tool Added!"
    TPStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    task.delay(2, function()
        if TPStatusLabel then TPStatusLabel.Text = "Spawn standard tool"; TPStatusLabel.TextColor3 = Color3.fromRGB(140, 140, 140) end
    end)
end)

-- --- 4A. PROXIMITY INTERACT PROCESSOR PIPELINE ---
local function processPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if InteractEnabled then
        if not PromptMemoryBank[prompt] then PromptMemoryBank[prompt] = prompt.HoldDuration end
        prompt.HoldDuration = 0
    end
end

InteractToggleButton.MouseButton1Click:Connect(function()
    InteractEnabled = not InteractEnabled
    InteractToggleButton.Text = InteractEnabled and "ON" or "OFF"
    InteractToggleButton.TextColor3 = InteractEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    
    if InteractEnabled then
        InteractTimeLabel.Text = "0s [Instant]"
        InteractTimeLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            processPrompt(descendants[i])
            if i % 150 == 0 then task.wait() end
        end
    else
        InteractTimeLabel.Text = "0s - 15s"
        InteractTimeLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
        
        for prompt, originalDuration in pairs(PromptMemoryBank) do
            if prompt and prompt.Parent then prompt.HoldDuration = originalDuration end
        end
        table.clear(PromptMemoryBank)
    end
end)

Workspace.DescendantAdded:Connect(function(descendant)
    if InteractEnabled then task.defer(function() processPrompt(descendant) end) end
end)

-- --- 4B. COLLISION, SPEED & FLIGHT CONTROLLERS ---
local function toggleNoclip()
    NoclipEnabled = not NoclipEnabled
    NoclipStatusLabel.Text = NoclipEnabled and "STATUS: ON" or "STATUS: OFF"
    NoclipStatusLabel.TextColor3 = NoclipEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    if not NoclipEnabled then
        local hum = getHumanoid()
        if hum then task.wait(0.05); hum.Jump = true end
    end
end

local function toggleFly()
    FlyEnabled = not FlyEnabled
    FlyStatusLabel.Text = FlyEnabled and "ON" or "OFF"
    FlyStatusLabel.TextColor3 = FlyEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 75, 75)
    if not FlyEnabled then
        if bv then bv:Destroy(); bv = nil end
        if bg then bg:Destroy(); bg = nil end
    end
end

-- User Input Trigger Allocators (Including Smooth Slide Hide/Show System)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if UserInputService:GetFocusedTextBox() or not ScriptRunning then return end

    -- Rebind Captures
    if IsBindingSpeed and input.UserInputType == Enum.UserInputType.Keyboard then
        SpeedKey = input.KeyCode; SpeedBindButton.Text = SpeedKey.Name; SpeedBindButton.TextColor3 = Color3.fromRGB(0, 200, 255); IsBindingSpeed = false; return
    elseif IsBindingNoclip and input.UserInputType == Enum.UserInputType.Keyboard then
        NoclipKey = input.KeyCode; NoclipBindButton.Text = NoclipKey.Name; NoclipBindButton.TextColor3 = Color3.fromRGB(0, 200, 255); IsBindingNoclip = false; return
    elseif IsBindingFly and input.UserInputType == Enum.UserInputType.Keyboard then
        FlyKey = input.KeyCode; FlyBindButton.Text = FlyKey.Name; FlyBindButton.TextColor3 = Color3.fromRGB(180, 75, 255); IsBindingFly = false; return
    elseif IsBindingHide and input.UserInputType == Enum.UserInputType.Keyboard then
        ToggleKey = input.KeyCode; HideBindButton.Text = ToggleKey.Name; HideBindButton.TextColor3 = Color3.fromRGB(230, 230, 230); IsBindingHide = false; return
    end

    -- Hide/Show Animation Trigger Toggle Link
    if input.KeyCode == ToggleKey then
        GuiVisible = not GuiVisible
        if not GuiVisible then
            local hiddenPos = UDim2.new(0, -360, SavedPosition.Y.Scale, SavedPosition.Y.Offset)
            TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = hiddenPos}):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = SavedPosition}):Play()
        end
        return
    end

    if input.KeyCode == SpeedKey then
        local hum = getHumanoid()
        if hum then IsHoldingSpeed = true; hum.WalkSpeed = TargetSpeed end
    elseif input.KeyCode == Enum.KeyCode.Space then
        IsHoldingSpace = true
    elseif input.KeyCode == NoclipKey then
        toggleNoclip()
    elseif FlyKey and input.KeyCode == FlyKey then
        toggleFly()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if not ScriptRunning then return end
    if input.KeyCode == SpeedKey and IsHoldingSpeed then
        IsHoldingSpeed = false
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = LiveNormalSpeed end
    elseif input.KeyCode == Enum.KeyCode.Space then
        IsHoldingSpace = false
    end
end)

-- Realtime Simulation Physics Loops
RunService.Stepped:Connect(function()
    if not ScriptRunning then return end
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    
    if character and hum then
        local flyTarget = character:FindFirstChild("HumanoidRootPart")
        if hum.SeatPart and (hum.SeatPart:IsA("VehicleSeat") or hum.SeatPart:IsA("Seat")) then
            flyTarget = hum.SeatPart.AssemblyRootPart or hum.SeatPart
        end

        if IsHoldingSpeed and hum.WalkSpeed ~= TargetSpeed then
            hum.WalkSpeed = TargetSpeed
        end
        
        if JumpEnabled and IsHoldingSpace and flyTarget and not FlyEnabled then
            if hum.UseJumpPower then
                flyTarget.AssemblyLinearVelocity = Vector3.new(flyTarget.AssemblyLinearVelocity.X, TargetJump, flyTarget.AssemblyLinearVelocity.Z)
            else
                local calcVelocity = math.sqrt(2 * workspace.Gravity * TargetJump)
                flyTarget.AssemblyLinearVelocity = Vector3.new(flyTarget.AssemblyLinearVelocity.X, calcVelocity, flyTarget.AssemblyLinearVelocity.Z)
            end
        end
        
        if NoclipEnabled then
            for _, child in ipairs(character:GetDescendants()) do
                if child:IsA("BasePart") then child.CanCollide = false end
            end
            if hum.SeatPart and hum.SeatPart.Parent then
                for _, child in ipairs(hum.SeatPart.Parent:GetDescendants()) do
                    if child:IsA("BasePart") then child.CanCollide = false end
                end
            end
        end

        if FlyEnabled and flyTarget then
            if not bv or bv.Parent ~= flyTarget or not bg or bg.Parent ~= flyTarget then
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
                bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Parent = flyTarget
                bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                bg.Parent = flyTarget
            end

            local dir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then bv.Velocity = dir.Unit * TargetFlySpeed else bv.Velocity = Vector3.new(0, 0, 0) end
            bg.CFrame = Camera.CFrame
            
            if not hum.SeatPart then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
        end
    end
end)
