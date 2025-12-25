local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local originalGravity = workspace.Gravity

-- 1. CORE GUI MOUNTING (Persistent Overlay)
local targetParent = nil
local success, err = pcall(function()
    targetParent = gethui and gethui() or CoreGui
end)
if not targetParent then targetParent = player:WaitForChild("PlayerGui") end

local oldGui = targetParent:FindFirstChild("Elite_Aim_System")
if oldGui then oldGui:Destroy() end

-- 2. Configuration & State
local fovRadius = 100
local smoothness = 0
local aimPartName = "Head"
local tpDistance = 3 
local aimActive = false
local tpEnabled = false 
local espEnabled = false 
local masterLocked = true 
local toggleKey = Enum.KeyCode.End 
local lockedTargetPart = nil 
local isMinimized = false

local function sanitize(val)
    local num = tonumber(val)
    return num or 3
end

-- 3. UPDATED ESP LOGIC (Death & Join Proof)
local function applyESP(targetPlayer)
    if targetPlayer == player then return end
    
    local function createHighlight(char)
        if not char then return end
        
        -- Wait for character to be fully parented
        char:WaitForChild("HumanoidRootPart", 5)
        
        -- Remove existing to avoid duplicates
        local old = char:FindFirstChild("EliteHighlight")
        if old then old:Destroy() end

        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteHighlight"
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineTransparency = 0
        -- Automatically stays ON if menu setting is ON
        highlight.Enabled = espEnabled 
        highlight.Adornee = char
        highlight.Parent = char
    end

    -- Apply if they already have a character
    if targetPlayer.Character then 
        task.spawn(function() createHighlight(targetPlayer.Character) end) 
    end
    
    -- Re-apply every time they die and respawn
    targetPlayer.CharacterAdded:Connect(createHighlight)
end

-- Initialize for current players and future joiners
for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

local function toggleAllHighlights(state)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("EliteHighlight")
            if h then h.Enabled = state end
        end
    end
end

-- 4. GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Elite_Aim_System"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = targetParent

local circleFrame = Instance.new("Frame")
circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
circleFrame.BackgroundTransparency = 1
circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
circleFrame.Parent = screenGui

local uiStroke = Instance.new("UIStroke", circleFrame)
uiStroke.Color = Color3.fromHex("CCCCCC")
uiStroke.Thickness = 1.5
Instance.new("UICorner", circleFrame).CornerRadius = UDim.new(1, 0)

-- 5. Menu Creation
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 200, 0, 335)
mainPanel.Position = UDim2.new(1, -220, 0.5, -167)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainPanel.Active = true
mainPanel.Draggable = true 
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 25); topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); topBar.Parent = mainPanel
Instance.new("UICorner", topBar)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0); title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "ELITE SYSTEM"; title.TextColor3 = Color3.new(1,1,1); title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left; title.Font = Enum.Font.SourceSansBold; title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25); closeBtn.Position = UDim2.new(1, -25, 0, 0)
closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.BackgroundTransparency = 1; closeBtn.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 25, 0, 25); minBtn.Position = UDim2.new(1, -50, 0, 0)
minBtn.Text = "−"; minBtn.TextColor3 = Color3.new(1,1,1); minBtn.BackgroundTransparency = 1; minBtn.Parent = topBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -25); content.Position = UDim2.new(0, 0, 0, 25); content.BackgroundTransparency = 1; content.Parent = mainPanel

local function createInput(labelText, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 25); label.Position = UDim2.new(0, 10, 0, posY)
    label.Text = labelText; label.TextColor3 = Color3.new(1,1,1); label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = content; label.Name = labelText
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 95, 0, 25); box.Position = UDim2.new(0, 95, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35); box.Text = defaultValue; box.TextColor3 = Color3.new(1,1,1)
    box.ClearTextOnFocus = false; box.Parent = content; Instance.new("UICorner", box)
    return box, label
end

local radIn = createInput("Radius:", 15, "100")
local colIn = createInput("Hex:", 50, "CCCCCC")
local smthIn = createInput("Smooth:", 85, "0")
local partIn = createInput("Aim Part:", 120, "Head")

local masterBtn = Instance.new("TextButton", content)
masterBtn.Size = UDim2.new(0, 180, 0, 30); masterBtn.Position = UDim2.new(0, 10, 0, 160)
masterBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30); masterBtn.Text = "SYSTEM: ACTIVE"
masterBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", masterBtn)

local bindBtn = Instance.new("TextButton", content)
bindBtn.Size = UDim2.new(0, 180, 0, 25); bindBtn.Position = UDim2.new(0, 10, 0, 200)
bindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); bindBtn.Text = "BIND: " .. toggleKey.Name
bindBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", bindBtn)

local espToggleBtn = Instance.new("TextButton", content)
espToggleBtn.Size = UDim2.new(0, 180, 0, 30); espToggleBtn.Position = UDim2.new(0, 10, 0, 235)
espToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); espToggleBtn.Text = "ESP: OFF"
espToggleBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", espToggleBtn)

local tpToggleBtn = Instance.new("TextButton", content)
tpToggleBtn.Size = UDim2.new(0, 180, 0, 30); tpToggleBtn.Position = UDim2.new(0, 10, 0, 275)
tpToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); tpToggleBtn.Text = "TP MODE: OFF"
tpToggleBtn.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", tpToggleBtn)

local tpRangeIn, tpRangeLabel = createInput("TP Range:", 15, "3")
tpRangeIn.Visible = false; tpRangeLabel.Visible = false

-- 6. Logic Loops
local connections = {}

local function findSingleTarget()
    if not masterLocked then return nil end
    local target, dist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local part = p.Character:FindFirstChild(aimPartName)
            if part and part:IsA("BasePart") then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag <= fovRadius and mag < dist then target = part; dist = mag end
                end
            end
        end
    end
    return target
end

connections.renderLoop = RunService.RenderStepped:Connect(function()
    if masterLocked and aimActive then
        if not lockedTargetPart then lockedTargetPart = findSingleTarget() end
        if lockedTargetPart and lockedTargetPart.Parent then
            local targetChar = lockedTargetPart.Parent
            local root, hum = targetChar:FindFirstChild("HumanoidRootPart"), targetChar:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and root then
                local targetCF = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)
                if smoothness <= 0 then Camera.CFrame = targetCF 
                else Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / (smoothness + 1)) end
                
                if tpEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    workspace.Gravity = 0
                    player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    player.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, tpDistance)
                end
            else lockedTargetPart = findSingleTarget() end
        end
    else
        if workspace.Gravity ~= originalGravity then workspace.Gravity = originalGravity end
    end
end)

-- 7. Interaction Handlers
espToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleAllHighlights(espEnabled)
    espToggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(45, 45, 45)
end)

tpToggleBtn.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    if tpEnabled then
        tpToggleBtn.Text = "TP MODE: ON"; tpToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30)
        radIn.Position = UDim2.new(0, 95, 0, 50); content:FindFirstChild("Radius:").Position = UDim2.new(0, 10, 0, 50)
        colIn.Position = UDim2.new(0, 95, 0, 85); content:FindFirstChild("Hex:").Position = UDim2.new(0, 10, 0, 85)
        smthIn.Position = UDim2.new(0, 95, 0, 120); content:FindFirstChild("Smooth:").Position = UDim2.new(0, 10, 0, 120)
        partIn.Position = UDim2.new(0, 95, 0, 155); content:FindFirstChild("Aim Part:").Position = UDim2.new(0, 10, 0, 155)
        tpRangeIn.Visible = true; tpRangeLabel.Visible = true
        tpRangeIn.Position = UDim2.new(0, 95, 0, 15); tpRangeLabel.Position = UDim2.new(0, 10, 0, 15)
        masterBtn.Position = UDim2.new(0, 10, 0, 195); bindBtn.Position = UDim2.new(0, 10, 0, 235); espToggleBtn.Position = UDim2.new(0, 10, 0, 270); tpToggleBtn.Position = UDim2.new(0, 10, 0, 310)
        mainPanel.Size = UDim2.new(0, 200, 0, 375)
    else
        workspace.Gravity = originalGravity
        tpToggleBtn.Text = "TP MODE: OFF"; tpToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        radIn.Position = UDim2.new(0, 95, 0, 15); content:FindFirstChild("Radius:").Position = UDim2.new(0, 10, 0, 15)
        colIn.Position = UDim2.new(0, 95, 0, 50); content:FindFirstChild("Hex:").Position = UDim2.new(0, 10, 0, 50)
        smthIn.Position = UDim2.new(0, 95, 0, 85); content:FindFirstChild("Smooth:").Position = UDim2.new(0, 10, 0, 85)
        partIn.Position = UDim2.new(0, 95, 0, 120); content:FindFirstChild("Aim Part:").Position = UDim2.new(0, 10, 0, 120)
        tpRangeIn.Visible = false; tpRangeLabel.Visible = false
        masterBtn.Position = UDim2.new(0, 10, 0, 160); bindBtn.Position = UDim2.new(0, 10, 0, 200); espToggleBtn.Position = UDim2.new(0, 10, 0, 235); tpToggleBtn.Position = UDim2.new(0, 10, 0, 275)
        mainPanel.Size = UDim2.new(0, 200, 0, 335)
    end
end)

-- Inputs
connections.inputBegan = UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aimActive = true; lockedTargetPart = findSingleTarget()
    elseif i.KeyCode == toggleKey then 
        masterLocked = not masterLocked
        masterBtn.Text = masterLocked and "SYSTEM: ACTIVE" or "SYSTEM: DISABLED"
        masterBtn.BackgroundColor3 = masterLocked and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(130, 30, 30)
        circleFrame.Visible = masterLocked
    end
end)

connections.inputEnded = UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aimActive = false; lockedTargetPart = nil end
end)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized; content.Visible = not isMinimized
    if isMinimized then mainPanel.Size = UDim2.new(0, 200, 0, 25); minBtn.Text = "+"
    else mainPanel.Size = tpEnabled and UDim2.new(0, 200, 0, 375) or UDim2.new(0, 200, 0, 335); minBtn.Text = "−" end
end)

closeBtn.MouseButton1Click:Connect(function() 
    workspace.Gravity = originalGravity
    toggleAllHighlights(false)
    for _, conn in pairs(connections) do if conn then conn:Disconnect() end end
    screenGui:Destroy() 
end)

-- Sanitizers
tpRangeIn.FocusLost:Connect(function() tpDistance = sanitize(tpRangeIn.Text); tpRangeIn.Text = tostring(tpDistance) end)
radIn.FocusLost:Connect(function() fovRadius = sanitize(radIn.Text); radIn.Text = tostring(fovRadius); circleFrame.Size = UDim2.new(0, fovRadius*2, 0, fovRadius*2) end)
smthIn.FocusLost:Connect(function() smoothness = sanitize(smthIn.Text); smthIn.Text = tostring(smoothness) end)
partIn.FocusLost:Connect(function() aimPartName = partIn.Text; lockedTargetPart = nil end)
bindBtn.MouseButton1Click:Connect(function() bindBtn.Text = "..."; local tempConn; tempConn = UserInputService.InputBegan:Connect(function(input) if input.UserInputType == Enum.KeyCode.Unknown or input.UserInputType == Enum.KeyCode.Keyboard then toggleKey = input.KeyCode; bindBtn.Text = "BIND: " .. toggleKey.Name; tempConn:Disconnect() end end) end)
