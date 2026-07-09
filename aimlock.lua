local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
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
local wallCheckEnabled = false
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
local activeHighlights = {} 

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

-- 2. Line of Sight Wall Check (Bypasses non-collidable transparent parts)
local function isVisible(targetPart)
    if not wallCheckEnabled then return true end
    if not targetPart or not targetPart.Parent then return false end
    
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    
    local params = RaycastParams.new()
    local ignoreList = {player.Character, targetPart.Parent}
    params.FilterDescendantsInstances = ignoreList
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    
    local currentOrigin = origin
    local currentDirection = direction
    
    for i = 1, 5 do -- Limit loops to prevent crashing
        local result = workspace:Raycast(currentOrigin, currentDirection, params)
        if not result then
            return true -- Clear line of sight
        end
        
        if result.Instance.CanCollide then
            return false -- Solid obstruction hit
        end
        
        -- Bypass non-collidable part (foliage, trigger zones, highlights)
        table.insert(ignoreList, result.Instance)
        params.FilterDescendantsInstances = ignoreList
        
        currentOrigin = result.Position + (direction.Unit * 0.05)
        currentDirection = destination - currentOrigin
        
        if (currentOrigin - origin).Magnitude >= direction.Magnitude then
            return true
        end
    end
    
    return false
end

-- 3. ESP Highlight Routine
local MAX_ACTIVE_HIGHLIGHTS = 25

local function updateAllESP()
    local list = {}
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)
    
    if espEnabled and (targetMode == "Players" or targetMode == "Both") then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local char = p.Character
                local dist = (char.HumanoidRootPart.Position - myPos).Magnitude
                table.insert(list, { char = char, isPlayer = true, dist = dist })
            end
        end
    end
    
    if espEnabled and (targetMode == "NPCs" or targetMode == "Both") then
        for _, npc in ipairs(npcCache) do
            if npc:FindFirstChild("HumanoidRootPart") then
                local dist = (npc.HumanoidRootPart.Position - myPos).Magnitude
                table.insert(list, { char = npc, isPlayer = false, dist = dist })
            end
        end
    end
    
    table.sort(list, function(a, b) return a.dist < b.dist end)
    
    local activeHighlightMap = {}
    for i = 1, math.min(#list, MAX_ACTIVE_HIGHLIGHTS) do
        local target = list[i]
        activeHighlightMap[target.char] = target
    end
    
    for char, h in pairs(activeHighlights) do
        if not char or not char.Parent or not activeHighlightMap[char] then
            if h and h.Parent then h:Destroy() end
            activeHighlights[char] = nil
        end
    end
    
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
        
        local correctColor = target.isPlayer and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(170, 50, 255)
        if h.OutlineColor ~= correctColor then
            h.OutlineColor = correctColor
        end
        
        h.Enabled = true
    end
end

-- 4. GUI Mounting Setup
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

-- FOV Ring
local circleFrame = Instance.new("Frame")
circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
circleFrame.BackgroundTransparency = 1
circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
circleFrame.Parent = screenGui
local uiStroke = Instance.new("UIStroke", circleFrame)
uiStroke.Color = Color3.fromHex("CCCCCC")
Instance.new("UICorner", circleFrame).CornerRadius = UDim.new(1, 0)

-- 5. GUI Panel (Modern Midnight Theme)
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 220, 0, 385) -- Width slightly wider for cleaner layouts
mainPanel.Position = UDim2.new(1, -240, 0.5, -190)
mainPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainPanel.BorderSizePixel = 0
mainPanel.Active = true
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Color = Color3.fromRGB(35, 35, 45)
panelStroke.Thickness = 1

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
topBar.BorderSizePixel = 0
topBar.Parent = mainPanel
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

-- Merge top corners
local topBarCover = Instance.new("Frame")
topBarCover.Size = UDim2.new(1, 0, 0, 10)
topBarCover.Position = UDim2.new(0, 0, 1, -10)
topBarCover.BackgroundColor3 = topBar.BackgroundColor3
topBarCover.BorderSizePixel = 0
topBarCover.Parent = topBar

-- Cyan neon title accent line
local titleAccent = Instance.new("Frame")
titleAccent.Size = UDim2.new(1, 0, 0, 1.5)
titleAccent.Position = UDim2.new(0, 0, 1, 0)
titleAccent.BackgroundColor3 = Color3.fromRGB(0, 188, 212)
titleAccent.BorderSizePixel = 0
titleAccent.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.Text = "ELITE SYSTEM"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -32, 0, 0)
closeBtn.Text = "✕"
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -64, 0, 0)
minBtn.Text = "−"
minBtn.TextSize = 13
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.BackgroundTransparency = 1
minBtn.Parent = topBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -32)
content.Position = UDim2.new(0, 0, 0, 32)
content.BackgroundTransparency = 1
content.Parent = mainPanel

local listLayout = Instance.new("UIListLayout", content)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)

local listPadding = Instance.new("UIPadding", content)
listPadding.PaddingTop = UDim.new(0, 10)
listPadding.PaddingBottom = UDim.new(0, 10)
listPadding.PaddingLeft = UDim.new(0, 10)
listPadding.PaddingRight = UDim.new(0, 10)

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

-- Hover Utility using smooth Tweening
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

    local tweenIn = TweenService:Create(hover, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.93})
    local tweenOut = TweenService:Create(hover, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})

    safeConnect(button.MouseEnter, function() tweenIn:Play() end)
    safeConnect(button.MouseLeave, function() tweenOut:Play() end)
end

-- Input Group Setup
local inputGroup = Instance.new("Frame")
inputGroup.Size = UDim2.new(1, 0, 0, 118)
inputGroup.BackgroundTransparency = 1
inputGroup.LayoutOrder = 1
inputGroup.Parent = content

local inputList = Instance.new("UIListLayout", inputGroup)
inputList.Padding = UDim.new(0, 6)

local function createInputRow(labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = inputGroup
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -5, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = row
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, 5, 1, 0)
    box.Position = UDim2.new(0.4, -5, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    box.Text = defaultValue
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    local inputStroke = Instance.new("UIStroke", box)
    inputStroke.Color = Color3.fromRGB(45, 45, 55)
    inputStroke.Thickness = 1
    
    return box, label
end

local radIn = createInputRow("Radius:", "100")
local colIn = createInputRow("Hex Color:", "CCCCCC")
local smthIn = createInputRow("Smoothness:", "0")
local partIn = createInputRow("Aim Part:", "Head")

-- Section Separator
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
separator.BorderSizePixel = 0
separator.LayoutOrder = 2
separator.Parent = content

local function createButton(text, layoutOrder, color)
    local btn = Instance.new("TextButton", content)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.LayoutOrder = layoutOrder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    addHoverEffect(btn)
    return btn
end

local masterBtn = createButton("SYSTEM: ACTIVE", 3, Color3.fromRGB(0, 188, 212))
local modeToggleBtn = createButton("TARGET: PLAYERS", 4, Color3.fromRGB(28, 28, 35))
local bindBtn = createButton("BIND: " .. toggleKey.Name, 5, Color3.fromRGB(28, 28, 35))
bindBtn.Size = UDim2.new(1, 0, 0, 25)

local espToggleBtn = createButton("ESP: OFF", 6, Color3.fromRGB(28, 28, 35))
local wallCheckBtn = createButton("WALL CHECK: OFF", 7, Color3.fromRGB(28, 28, 35))
local tpToggleBtn = createButton("TP MODE: OFF", 8, Color3.fromRGB(28, 28, 35))

-- TP Sub-menu layout
local tpPanel = Instance.new("Frame")
tpPanel.Size = UDim2.new(1, 0, 0, 97)
tpPanel.BackgroundTransparency = 1
tpPanel.LayoutOrder = 9
tpPanel.Visible = false
tpPanel.Parent = content

local tpList = Instance.new("UIListLayout", tpPanel)
tpList.Padding = UDim.new(0, 6)

local function createTpInputRow(labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = tpPanel
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -5, 1, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = row
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, 5, 1, 0)
    box.Position = UDim2.new(0.4, -5, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    box.Text = defaultValue
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Color3.fromRGB(45, 45, 55)
    stroke.Thickness = 1
    
    return box, label
end

local tpRangeIn, tpRangeLabel = createTpInputRow("TP Range:", "3")

local function createTpButton(text, color)
    local btn = Instance.new("TextButton", tpPanel)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    addHoverEffect(btn)
    return btn
end

local gravToggleBtn = createTpButton("GRAVITY: 0 (ON)", Color3.fromRGB(0, 188, 212))
local methodToggleBtn = createTpButton("METHOD: TELEPORT", Color3.fromRGB(130, 80, 250))

-- 6. Targeting Calculations
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
                    if isVisible(part) then -- Wallcheck evaluation
                        target = part
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

-- 7. Render Loop (Frame-Rate Independent)
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
                -- Final safety wall-check during tracking
                if not isVisible(lockedTargetPart) then
                    lockedTargetPart = nil
                    return
                end
                
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

-- 8. Button Interaction Event Handlers
masterBtn.MouseButton1Click:Connect(function()
    masterLocked = not masterLocked
    masterBtn.Text = masterLocked and "SYSTEM: ACTIVE" or "SYSTEM: DISABLED"
    masterBtn.BackgroundColor3 = masterLocked and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(150, 50, 50)
    circleFrame.Visible = masterLocked
    lockedTargetPart = nil
end)

modeToggleBtn.MouseButton1Click:Connect(function()
    if targetMode == "Players" then
        targetMode = "NPCs"
        modeToggleBtn.Text = "TARGET: NPCs"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(130, 80, 250)
    elseif targetMode == "NPCs" then
        targetMode = "Both"
        modeToggleBtn.Text = "TARGET: BOTH"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 188, 212)
    else
        targetMode = "Players"
        modeToggleBtn.Text = "TARGET: PLAYERS"
        modeToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    end
    lockedTargetPart = nil
    updateAllESP()
end)

espToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espToggleBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espToggleBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(28, 28, 35)
    updateAllESP()
end)

wallCheckBtn.MouseButton1Click:Connect(function()
    wallCheckEnabled = not wallCheckEnabled
    wallCheckBtn.Text = wallCheckEnabled and "WALL CHECK: ON" or "WALL CHECK: OFF"
    wallCheckBtn.BackgroundColor3 = wallCheckEnabled and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(28, 28, 35)
    lockedTargetPart = nil
end)

methodToggleBtn.MouseButton1Click:Connect(function()
    tpMethod = (tpMethod == "Teleport") and "Moveset" or "Teleport"
    methodToggleBtn.Text = "METHOD: " .. tpMethod:upper()
    methodToggleBtn.BackgroundColor3 = (tpMethod == "Teleport") and Color3.fromRGB(130, 80, 250) or Color3.fromRGB(0, 188, 212)
end)

gravToggleBtn.MouseButton1Click:Connect(function()
    useZeroGravity = not useZeroGravity
    gravToggleBtn.Text = useZeroGravity and "GRAVITY: 0 (ON)" or "GRAVITY: NORMAL"
    gravToggleBtn.BackgroundColor3 = useZeroGravity and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(150, 50, 50)
    if not useZeroGravity then workspace.Gravity = originalGravity end
end)

tpToggleBtn.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    tpToggleBtn.Text = tpEnabled and "TP MODE: ON" or "TP MODE: OFF"
    tpToggleBtn.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(28, 28, 35)
    
    tpPanel.Visible = tpEnabled
    
    -- Smoothly Tween UI Height
    local targetHeight = tpEnabled and 490 or 385
    TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, targetHeight)
    }):Play()
end)

-- 9. Key Binding Setup
bindBtn.MouseButton1Click:Connect(function()
    if isBindingKey then return end
    isBindingKey = true
    bindBtn.Text = "PRESS KEY..."
    bindBtn.BackgroundColor3 = Color3.fromRGB(130, 80, 250)
    
    local keyConn
    keyConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                toggleKey = input.KeyCode
            end
            bindBtn.Text = "BIND: " .. toggleKey.Name
            bindBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            keyConn:Disconnect()
            isBindingKey = false
        end
    end)
    table.insert(scriptConnections, keyConn)
end)

-- 10. Global Shortcuts & Inputs
safeConnect(UserInputService.InputBegan, function(input, gpe)
    if gpe or isBindingKey then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then 
        aimActive = true
        lockedTargetPart = findSingleTarget()
    elseif input.KeyCode == toggleKey then 
        masterLocked = not masterLocked
        masterBtn.Text = masterLocked and "SYSTEM: ACTIVE" or "SYSTEM: DISABLED"
        masterBtn.BackgroundColor3 = masterLocked and Color3.fromRGB(0, 188, 212) or Color3.fromRGB(150, 50, 50)
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
    
    local panelTargetHeight = 32
    if not isMinimized then
        panelTargetHeight = tpEnabled and 490 or 385
        minBtn.Text = "−"
    else
        minBtn.Text = "+"
    end
    
    TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, panelTargetHeight)
    }):Play()
end)

-- 11. Clean Exit & De-registration
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

-- Config input mapping
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

tpRangeIn.FocusLost:Connect(function() 
    tpDistance = sanitize(tpRangeIn.Text, 3)
    tpRangeIn.Text = tostring(tpDistance) 
end)

-- 12. Startup Caches & Loop Init
scanWorkspaceForNPCs()
updateAllESP()

task.spawn(function()
    while scriptActive do
        task.wait(1.5)
        if not scriptActive then break end
        scanWorkspaceForNPCs()
        updateAllESP()
    end
end)
