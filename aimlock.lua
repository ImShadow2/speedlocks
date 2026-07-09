-- tp aim
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local originalGravity = workspace.Gravity

-- State Management
local fovRadius = 100
local smoothness = 0
local aimPartName = "Head"
local tpDistance = 3 
local aimActive = false
local tpEnabled = false 
local useZeroGravity = true 
local tpMethod = "Teleport" 
local espEnabled = false 
local targetMode = "Players" -- "Players", "NPCs", "Both"
local masterLocked = true 
local toggleKey = Enum.KeyCode.End 
local lockedTargetPart = nil 
local isMinimized = false
local scriptActive = true
local isBindingKey = false

-- Garbage Collection / Cleanup Registry
local scriptConnections = {}
local npcCache = {}
local activeHighlights = {} -- Tracks active highlight instances

local function safeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(scriptConnections, conn)
    return conn
end

local function sanitize(val, default)
    local num = tonumber(val)
    return num or default
end

-- Robust checking for players (immune to renaming/spoofing)
local function getPlayerFromChar(char)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == char then
            return p
        end
    end
    return nil
end

-- 1. Smart NPC Scanner (Traverses nested folders/actors, skips scanning character contents)
local function scanNPCs(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Humanoid") then
            local character = parent
            if not getPlayerFromChar(character) then
                table.insert(npcCache, character)
            end
            return 
        end
    end
    
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") or child:IsA("Actor") then
            scanNPCs(child)
        end
    end
end

local function scanWorkspaceForNPCs()
    table.clear(npcCache)
    scanNPCs(workspace)
end

-- 2. ESP HIGHLIGHT SYSTEM WITH CULLING (Prevents Roblox 31-Highlight Cap Limit)
local MAX_ACTIVE_HIGHLIGHTS = 25

local function updateAllESP()
    local list = {}
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)
    
    -- Gather Players
    if espEnabled and (targetMode == "Players" or targetMode == "Both") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local char = p.Character
                local dist = (char.HumanoidRootPart.Position - myPos).Magnitude
                table.insert(list, { char = char, isPlayer = true, dist = dist })
            end
        end
    end
    
    -- Gather NPCs
    if espEnabled and (targetMode == "NPCs" or targetMode == "Both") then
        for _, npc in ipairs(npcCache) do
            if npc:FindFirstChild("HumanoidRootPart") then
                local dist = (npc.HumanoidRootPart.Position - myPos).Magnitude
                table.insert(list, { char = npc, isPlayer = false, dist = dist })
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(list, function(a, b) return a.dist < b.dist end)
    
    -- Populate Active Highlight Map (Limit to MAX_ACTIVE_HIGHLIGHTS)
    local activeHighlightMap = {}
    for i = 1, math.min(#list, MAX_ACTIVE_HIGHLIGHTS) do
        local target = list[i]
        activeHighlightMap[target.char] = target
    end
    
    -- Destroy highlights that are out-of-range or disabled
    for char, h in pairs(activeHighlights) do
        if not char or not char.Parent or not activeHighlightMap[char] then
            if h and h.Parent then h:Destroy() end
            activeHighlights[char] = nil
        end
    end
    
    -- Draw/Update close highlights
    for char, target in pairs(activeHighlightMap) do
        local h = activeHighlights[char] or char:FindFirstChild("EliteHighlight")
        if not h then
            h = Instance.new("Highlight")
            h.Name = "EliteHighlight"
            h.FillTransparency = 1
            h.OutlineTransparency = 0
            h.Adornee = char
            h.Parent = char
            activeHighlights[char] = h
        end
        
        -- Color code targets accurately
        local correctColor = target.isPlayer and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(170, 50, 255)
        if h.OutlineColor ~= correctColor then
            h.OutlineColor = correctColor
        end
        
        h.Enabled = true
    end
end

-- 3. Core GUI Mounting
local targetParent = nil
local success, err = pcall(function()
    targetParent = gethui and gethui() or CoreGui
end)
if not targetParent then targetParent = player:WaitForChild("PlayerGui") end

local oldGui = targetParent:FindFirstChild("Elite_Aim_System")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Elite_Aim_System"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = targetParent

-- FOV Reticle
local circleFrame = Instance.new("Frame")
circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
circleFrame.BackgroundTransparency = 1
circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
circleFrame.Parent = screenGui
local uiStroke = Instance.new("UIStroke", circleFrame)
uiStroke.Color = Color3.fromHex("CCCCCC")
Instance.new("UICorner", circleFrame).CornerRadius = UDim.new(1, 0)

-- 4. Premium GUI Panel Setup
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 200, 0, 370) 
mainPanel.Position = UDim2.new(1, -220, 0.5, -185)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainPanel.BorderSizePixel = 0
mainPanel.Active = true
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 8)

local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Color = Color3.fromRGB(45, 45, 45)
panelStroke.Thickness = 1

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
topBar.BorderSizePixel = 0
topBar.Parent = mainPanel
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local topBarCover = Instance.new("Frame")
topBarCover.Size = UDim2.new(1, 0, 0, 10)
topBarCover.Position = UDim2.new(0, 0, 1, -10)
topBarCover.BackgroundColor3 = topBar.BackgroundColor3
topBarCover.BorderSizePixel = 0
topBarCover.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "ELITE SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -60, 0, 0)
minBtn.Text = "−"
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.BackgroundTransparency = 1
minBtn.Parent = topBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1
content.Parent = mainPanel

-- Drag Integration
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos

    safeConnect(dragHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    safeConnect(dragHandle.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    safeConnect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    safeConnect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end
makeDraggable(mainPanel, topBar)

-- Hover Utility
local function addHoverEffect(button)
    local hover = Instance.new("Frame")
    hover.Size = UDim2.new(1, 0, 1, 0)
    hover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hover.BackgroundTransparency = 1
    hover.BorderSizePixel = 0
    hover.ZIndex = button.ZIndex + 1
    hover.Parent = button
    
    local corner = button:FindFirstChildOfClass("UICorner")
    if corner then
        local hoverCorner = Instance.new("UICorner", hover)
        hoverCorner.CornerRadius = corner.CornerRadius
    end

    safeConnect(button.MouseEnter, function() hover.BackgroundTransparency = 0.95 end)
    safeConnect(button.MouseLeave, function() hover.BackgroundTransparency = 1 end)
end

local function createInput(labelText, posY, defaultValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 25)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = content
    label.Name = labelText
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 95, 0, 25)
    box.Position = UDim2.new(0, 95, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.Text = defaultValue
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Parent = content
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    local inputStroke = Instance.new("UIStroke", box)
    inputStroke.Color = Color3.fromRGB(45, 45, 45)
    inputStroke.Thickness = 1
    
    return box, label
end

local radIn = createInput("Radius:", 15, "100")
local colIn = createInput("Hex:", 50, "CCCCCC")
local smthIn = createInput("Smooth:", 85, "0")
local partIn = createInput("Aim Part:", 120, "Head")

local function createButton(text, posY, color)
    local btn = Instance.new("TextButton", content)
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    addHoverEffect(btn)
    return btn
end

local modeToggleBtn = createButton("TARGET: PLAYERS", 155, Color3.fromRGB(60, 60, 60))
local masterBtn = createButton("SYSTEM: ACTIVE", 195, Color3.fromRGB(30, 130, 30))
local bindBtn = createButton("BIND: " .. toggleKey.Name, 235, Color3.fromRGB(45, 45, 45))
bindBtn.Size = UDim2.new(0, 180, 0, 25)

local espToggleBtn = createButton("ESP: OFF", 270, Color3.fromRGB(45, 45, 45))
local tpToggleBtn = createButton("TP MODE: OFF", 310, Color3.fromRGB(45, 45, 45))

local gravToggleBtn = createButton("GRAVITY: 0 (ON)", 380, Color3.fromRGB(30, 130, 30))
gravToggleBtn.Visible = false
local methodToggleBtn = createButton("METHOD: TELEPORT", 415, Color3.fromRGB(60, 60, 120))
methodToggleBtn.Visible = false

local tpRangeIn, tpRangeLabel = createInput("TP Range:", 15, "3")
tpRangeIn.Visible = false; tpRangeLabel.Visible = false

-- 5. Targeting Calculations
local function findSingleTarget()
    if not masterLocked then return nil end
    local target, dist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local candidates = {}
    
    if targetMode == "Players" or targetMode == "Both" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(candidates, p.Character)
                end
            end
        end
    end
    
    if targetMode == "NPCs" or targetMode == "Both" then
        for _, npc in ipairs(npcCache) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(candidates, npc)
            end
        end
    end

    for _, char in ipairs(candidates) do
        local part = char:FindFirstChild(aimPartName)
        if part and part:IsA("BasePart") then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if mag <= fovRadius and mag < dist then
                    target = part
                    dist = mag
                end
            end
        end
    end
    return target
end

-- 6. Render Loop (Frame-Rate Independent)
local renderLoopConnection
renderLoopConnection = RunService.RenderStepped:Connect(function(dt)
    if masterLocked and aimActive then
        if not lockedTargetPart or not lockedTargetPart.Parent or not lockedTargetPart.Parent:FindFirstChildOfClass("Humanoid") or lockedTargetPart.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
            lockedTargetPart = findSingleTarget()
        end
        
        if lockedTargetPart and lockedTargetPart.Parent then
            local targetChar = lockedTargetPart.Parent
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 and root then
                local targetCF = CFrame.new(Camera.CFrame.Position, lockedTargetPart.Position)
                if smoothness <= 0 then
                    Camera.CFrame = targetCF 
                else
                    local speed = 25 / (smoothness + 1)
                    local t = 1 - math.exp(-speed * dt)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(t, 0, 1))
                end
                
                if tpEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myRoot = player.Character.HumanoidRootPart
                    local goalCFrame = root.CFrame * CFrame.new(0, 0, tpDistance)
                    
                    if useZeroGravity then 
                        workspace.Gravity = 0
                        myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    else 
                        workspace.Gravity = originalGravity 
                    end

                    if tpMethod == "Teleport" then 
                        myRoot.CFrame = goalCFrame
                    else 
                        myRoot.CFrame = myRoot.CFrame:Lerp(goalCFrame, 0.2)
                        myRoot.AssemblyLinearVelocity = (goalCFrame.Position - myRoot.Position).Unit * 60 
                    end
                end
            else 
                lockedTargetPart = findSingleTarget() 
            end
        end
    else
        if workspace.Gravity ~= originalGravity then 
            workspace.Gravity = originalGravity 
        end
    end
end)
table.insert(scriptConnections, renderLoopConnection)

-- 7. Interaction Event Listeners
modeToggleBtn.MouseButton1Click:Connect(function()
    if targetMode == "Players" then
        targetMode = "NPCs"
        modeToggleBtn.Text = "TARGET: NPCs"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 150)
    elseif targetMode == "NPCs" then
        targetMode = "Both"
        modeToggleBtn.Text = "TARGET: BOTH"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    else
        targetMode = "Players"
        modeToggleBtn.Text = "TARGET: PLAYERS"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    lockedTargetPart = nil
    updateAllESP()
end)

espToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espToggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(45, 45, 45)
    updateAllESP()
end)

methodToggleBtn.MouseButton1Click:Connect(function()
    tpMethod = (tpMethod == "Teleport") and "Moveset" or "Teleport"
    methodToggleBtn.Text = "METHOD: " .. tpMethod:upper()
end)

gravToggleBtn.MouseButton1Click:Connect(function()
    useZeroGravity = not useZeroGravity
    gravToggleBtn.Text = useZeroGravity and "GRAVITY: 0 (ON)" or "GRAVITY: NORMAL"
    gravToggleBtn.BackgroundColor3 = useZeroGravity and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(130, 30, 30)
    if not useZeroGravity then workspace.Gravity = originalGravity end
end)

tpToggleBtn.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    if tpEnabled then
        tpToggleBtn.Text = "TP MODE: ON"
        tpToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30)
        tpRangeIn.Visible = true
        tpRangeLabel.Visible = true
        gravToggleBtn.Visible = true
        methodToggleBtn.Visible = true
        mainPanel.Size = UDim2.new(0, 200, 0, 480)
        modeToggleBtn.Position = UDim2.new(0, 10, 0, 190)
        masterBtn.Position = UDim2.new(0, 10, 0, 230)
        bindBtn.Position = UDim2.new(0, 10, 0, 270)
        espToggleBtn.Position = UDim2.new(0, 10, 0, 305)
        tpToggleBtn.Position = UDim2.new(0, 10, 0, 345)
        gravToggleBtn.Position = UDim2.new(0, 10, 0, 380)
        methodToggleBtn.Position = UDim2.new(0, 10, 0, 415)
    else
        workspace.Gravity = originalGravity
        tpToggleBtn.Text = "TP MODE: OFF"
        tpToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tpRangeIn.Visible = false
        tpRangeLabel.Visible = false
        gravToggleBtn.Visible = false
        methodToggleBtn.Visible = false
        mainPanel.Size = UDim2.new(0, 200, 0, 370)
        modeToggleBtn.Position = UDim2.new(0, 10, 0, 155)
        masterBtn.Position = UDim2.new(0, 10, 0, 195)
        bindBtn.Position = UDim2.new(0, 10, 0, 235)
        espToggleBtn.Position = UDim2.new(0, 10, 0, 270)
        tpToggleBtn.Position = UDim2.new(0, 10, 0, 310)
    end
end)

-- 8. Input Event Subscriptions (Isolated while key binding and textbox typing)
safeConnect(UserInputService.InputBegan, function(input, gpe)
    if gpe or isBindingKey then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then 
        aimActive = true
        lockedTargetPart = findSingleTarget()
    elseif input.KeyCode == toggleKey then 
        masterLocked = not masterLocked
        masterBtn.Text = masterLocked and "SYSTEM: ACTIVE" or "SYSTEM: DISABLED"
        masterBtn.BackgroundColor3 = masterLocked and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(130, 30, 30)
        circleFrame.Visible = masterLocked
    end
end)

safeConnect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then 
        aimActive = false
        lockedTargetPart = nil 
    end
end)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    content.Visible = not isMinimized
    if isMinimized then 
        mainPanel.Size = UDim2.new(0, 200, 0, 30)
        minBtn.Text = "+"
    else 
        mainPanel.Size = tpEnabled and UDim2.new(0, 200, 0, 480) or UDim2.new(0, 200, 0, 370)
        minBtn.Text = "−" 
    end
end)

-- 9. Clean Exit Routine
local function removeAllHighlights()
    for char, h in pairs(activeHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    table.clear(activeHighlights)
end

closeBtn.MouseButton1Click:Connect(function() 
    scriptActive = false
    workspace.Gravity = originalGravity
    espEnabled = false
    removeAllHighlights()
    for _, conn in ipairs(scriptConnections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(scriptConnections)
    screenGui:Destroy() 
end)

-- Input Focus Configuration handlers
tpRangeIn.FocusLost:Connect(function() 
    tpDistance = sanitize(tpRangeIn.Text, 3)
    tpRangeIn.Text = tostring(tpDistance) 
end)

radIn.FocusLost:Connect(function() 
    fovRadius = sanitize(radIn.Text, 100)
    radIn.Text = tostring(fovRadius)
    circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2) 
end)

colIn.FocusLost:Connect(function()
    local success, color = pcall(function()
        return Color3.fromHex(colIn.Text)
    end)
    if success and color then
        uiStroke.Color = color
    else
        colIn.Text = uiStroke.Color:ToHex()
    end
end)

smthIn.FocusLost:Connect(function() 
    smoothness = sanitize(smthIn.Text, 0)
    smthIn.Text = tostring(smoothness) 
end)

partIn.FocusLost:Connect(function() 
    aimPartName = partIn.Text
    lockedTargetPart = nil 
end)

-- Key Binding Setup
bindBtn.MouseButton1Click:Connect(function()
    if isBindingKey then return end
    isBindingKey = true
    bindBtn.Text = "PRESS KEY..."
    
    local keyConn
    keyConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                toggleKey = input.KeyCode
            end
            bindBtn.Text = "BIND: " .. toggleKey.Name
            keyConn:Disconnect()
            isBindingKey = false
        end
    end)
    table.insert(scriptConnections, keyConn)
end)

-- 10. Startup Initialization & Main Updates
scanWorkspaceForNPCs()
updateAllESP()

-- Lightweight dynamic background thread (Updates every 1.5 seconds)
task.spawn(function()
    while scriptActive do
        task.wait(1.5)
        if not scriptActive then break end
        scanWorkspaceForNPCs()
        updateAllESP()
    end
end)
