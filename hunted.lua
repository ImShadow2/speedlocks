-- Premium Roblox Multi-ESP & Misc Script
-- Features:
--   1. Visuals Section:
--      - Enemy ESP: Red Highlight (no fill) on ALL enemies in `workspace.Terrain.Enemies`
--      - Shard ESP: Diamond billboards on ALL shards (Color-Coded, defaults to Violet)
--      - Altar ESP: Cyan Highlight (no fill) on RingAltar
--      - Portal ESP: Labeled billboards (Gray Entrance / Green Exit)
--   2. Miscellaneous Section:
--      - Avoid Enemy: Creates a customizable-stud "reverse magnet" forcefield around all enemies, forcing the player away.
--      - NoClip: Toggleable NoClip with a bindable key (click keybind button to re-bind). Restores body collisions instantly upon disabling.
--      - Shard TP: Hold-to-trigger teleportation to the nearest shard in `workspace.Shards` (re-bindable).
--        * Infinite Chain-TP: Teleports to up to 20 shards IN A SINGLE FRAME (instant clearance of the entire map!).
--   3. Clean Slate Engine: Checks _G for duplicate runs and cleans up all threads, connections, and GUIs.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- Legacy Executor Compatibility Wrappers
-- ==========================================
local taskWait = (task and task.wait) or wait
local taskSpawn = (task and task.spawn) or spawn
local tableClear = (table and table.clear) or function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

-- ==========================================
-- SAFE PLAYER INITIALIZATION
-- ==========================================
local localPlayer = Players.LocalPlayer
if not localPlayer then
    local start = os.clock()
    while not Players.LocalPlayer and os.clock() - start < 5 do
        taskWait()
    end
    localPlayer = Players.LocalPlayer
end

-- ==========================================
-- CLEAN SLATE & DUPLICATE PREVENTION
-- ==========================================
if _G.AntigravityEspCleanup then
    pcall(_G.AntigravityEspCleanup)
end

-- ==========================================
-- DESIGN SYSTEM (Sleek Dark Theme)
-- ==========================================
local COLORS = {
    Background = Color3.fromRGB(20, 20, 25),
    Header = Color3.fromRGB(28, 28, 35),
    
    EnemyAccent = Color3.fromRGB(255, 60, 60),       -- Red
    ShardDefaultAccent = Color3.fromRGB(180, 0, 255), -- Violet
    AltarAccent = Color3.fromRGB(0, 235, 255),       -- Cyan
    PortalAccent = Color3.fromRGB(46, 204, 113),     -- Green
    AvoidAccent = Color3.fromRGB(243, 156, 18),      -- Orange
    NoclipAccent = Color3.fromRGB(155, 89, 182),     -- Amethyst/Purple
    
    TextActive = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(130, 130, 140),
    ToggleOff = Color3.fromRGB(45, 45, 55),
    ButtonHover = Color3.fromRGB(55, 55, 65),
}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ==========================================
-- STATE MANAGEMENT
-- ==========================================
local enemyEspEnabled = false
local shardEspEnabled = false
local altarEspEnabled = false
local portalEspEnabled = false
local avoidEnemyEnabled = false
local avoidDistance = 15

local noclipEnabled = false
local noclipKeybind = Enum.KeyCode.N -- Default keybind: N
local bindingActive = false

local tpActive = false
local tpKeybind = Enum.KeyCode.V -- Default keybind: V
local tpBindingActive = false

local panelVisible = true
local panelKeybind = Enum.KeyCode.F1 -- Default panel toggle keybind: F1
local panelBindingActive = false

local loopSpeedValue = 16
local speedLoopConnection = nil

local BLOCKED_KEYS = {
    [Enum.KeyCode.Escape] = true,
    [Enum.KeyCode.F9] = true,
    [Enum.KeyCode.F11] = true,
    [Enum.KeyCode.Slash] = true,
    [Enum.KeyCode.Backquote] = true,
    [Enum.KeyCode.F8] = true,
    [Enum.KeyCode.F10] = true,
    [Enum.KeyCode.F12] = true,
    [Enum.KeyCode.Unknown] = true,
}

local visitedShards = {}         -- Map of Shard Instance -> Expiration Clock Time
local isShardSafe = nil          -- Forward-declared safety check function for Shard TP

local activeEnemyHighlights = {} -- Enemy Model/Part -> Highlight Instance
local activeShardBillboards = {} -- Shard Instance -> BillboardGui Instance
local activeAltarHighlights = {} -- Altar Model/Part -> Highlight Instance
local activePortalBillboards = {} -- Portal Instance -> BillboardGui Instance

local enemyConnections = {}
local altarConnections = {}
local shardConnectionAdded = nil
local shardConnectionRemoved = nil
local avoidConnection = nil
local noclipConnection = nil
local tpConnection = nil
local inputConnection = nil
local inputEndedConnection = nil
local syncRunning = true

-- ==========================================
-- SAFE PATH FINDERS
-- ==========================================
local function getRingAltar()
    local hotel = workspace:FindFirstChild("Hotel")
    if not hotel then return nil end
    local maze = hotel:FindFirstChild("Maze")
    if not maze then return nil end
    local rooms = maze:FindFirstChild("Rooms")
    if not rooms then return nil end
    local main = rooms:FindFirstChild("Main")
    if not main then return nil end
    local ringAltarModel = main:FindFirstChild("RingAltar")
    if not ringAltarModel then return nil end
    local parts = ringAltarModel:FindFirstChild("Parts")
    if not parts then return nil end
    return parts:FindFirstChild("RingAltar")
end

local function getPortals()
    local portals = workspace:FindFirstChild("Portals")
    if not portals then return nil, nil end
    return portals:FindFirstChild("EntrancePortal"), portals:FindFirstChild("ExitPortal")
end

local function getNearestShard()
    local shardsFolder = workspace:FindFirstChild("Shards")
    if not shardsFolder then return nil end
    
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local playerPos = rootPart.Position
    local nearest = nil
    local minDist = math.huge
    local now = os.clock()
    
    for _, shard in ipairs(shardsFolder:GetChildren()) do
        local shardPart = shard:IsA("BasePart") and shard or shard:FindFirstChildWhichIsA("BasePart")
        if shardPart then
            -- Verify shard has not been recently visited (collected but still in workspace)
            local ignoreUntil = visitedShards[shard]
            if not ignoreUntil or now > ignoreUntil then
                -- Safety check: skip this shard if it is close to an enemy
                if isShardSafe(shardPart) then
                    local dist = (playerPos - shardPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = shard
                    end
                end
            end
        end
    end
    
    return nearest
end

-- ==========================================
-- ENEMY COLLECTION & ESP FUNCTIONS
-- ==========================================
local function getDoomDucky()
    local trap = workspace:FindFirstChild("DoomDuckyTrap")
    if not trap then return nil end
    local template = trap:FindFirstChild("TemplateDD")
    if not template then return nil end
    local dd = template:FindFirstChild("DoomDucky")
    if not dd then return nil end
    return dd:FindFirstChild("DooDuckyModel") or dd:FindFirstChild("DoomDuckyModel") or dd:FindFirstChildOfClass("Model") or dd:FindFirstChildWhichIsA("BasePart")
end

local function getDoomDuckyPart()
    local dd = getDoomDucky()
    if not dd then return nil end
    if dd:IsA("BasePart") then return dd end
    return dd.PrimaryPart 
        or dd:FindFirstChild("HumanoidRootPart")
        or dd:FindFirstChild("Torso")
        or dd:FindFirstChild("Body")
        or dd:FindFirstChildWhichIsA("BasePart")
end

local function updateDoomDuckyCircle()
    local ddPart = getDoomDuckyPart()
    if ddPart then
        local existing = ddPart:FindFirstChild("DoomDuckyRangeCircle")
        if not existing then
            local adorn = Instance.new("CylinderHandleAdornment")
            adorn.Name = "DoomDuckyRangeCircle"
            adorn.Height = 0.05
            adorn.Radius = 50 -- 50-stud range visual circle
            adorn.InnerRadius = 49.8 -- Thin outline circle shape
            adorn.Color3 = Color3.fromRGB(255, 60, 60)
            adorn.Transparency = 0.35
            adorn.AlwaysOnTop = false
            adorn.ZIndex = 5
            adorn.CFrame = CFrame.Angles(math.rad(90), 0, 0) -- Oriented flat horizontally
            adorn.Adornee = ddPart
            adorn.Parent = ddPart
        end
    end
end

local function removeDoomDuckyCircle()
    local ddPart = getDoomDuckyPart()
    if ddPart then
        local existing = ddPart:FindFirstChild("DoomDuckyRangeCircle")
        if existing then
            pcall(function() existing:Destroy() end)
        end
    end
end

local function getAllEnemies()
    local enemies = {}
    
    -- 1. Terrain Enemies (e.g. Monkey, DreadDucky)
    local terrain = workspace:FindFirstChild("Terrain")
    local enemiesFolder = terrain and terrain:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            table.insert(enemies, enemy)
        end
    end
    
    -- 2. NPCs (Agatha)
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            table.insert(enemies, npc)
        end
    end
    
    -- 3. DoomDucky (Part 3 Boss / Trap)
    local dd = getDoomDucky()
    if dd then
        table.insert(enemies, dd)
    end
    
    return enemies
end

local function getAvoidTargets()
    local targets = {}
    
    -- 1. Terrain Enemies (e.g. Monkey, DreadDucky)
    local terrain = workspace:FindFirstChild("Terrain")
    local enemiesFolder = terrain and terrain:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            table.insert(targets, enemy)
        end
    end
    
    -- 2. NPCs (Agatha)
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            table.insert(targets, npc)
        end
    end
    
    -- 3. DoomDucky Part
    local ddPart = getDoomDuckyPart()
    if ddPart then
        table.insert(targets, ddPart)
    end
    
    return targets
end
isShardSafe = function(shardPart)
    if not avoidEnemyEnabled then return true end
    
    local trap = workspace:FindFirstChild("DoomDuckyTrap")
    for _, enemy in ipairs(getAvoidTargets()) do
        local enemyPart = enemy:IsA("BasePart") and enemy or (enemy:IsA("Model") and (enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")))
        if enemyPart then
            local dist = (shardPart.Position - enemyPart.Position).Magnitude
            
            -- DoomDucky has a fixed 50 stud range, others use custom avoidDistance
            local isDD = trap and enemy:IsDescendantOf(trap)
            local safetyRange = isDD and 50 or avoidDistance
            
            if dist < safetyRange then
                return false -- Unsafe (enemy nearby!)
            end
        end
    end
    return true -- Safe!
end

local function addEnemyHighlight(enemy)
    if not enemy:IsA("Model") and not enemy:IsA("BasePart") then return end
    
    -- Check if highlight already exists
    local highlight = enemy:FindFirstChild("EnemyEspHighlight")
    if highlight and highlight:IsA("Highlight") then
        activeEnemyHighlights[enemy] = highlight
        return
    end
    
    highlight = Instance.new("Highlight")
    highlight.Name = "EnemyEspHighlight"
    highlight.FillColor = COLORS.EnemyAccent
    highlight.FillTransparency = 1 -- NO FILL
    highlight.OutlineColor = COLORS.EnemyAccent
    highlight.OutlineTransparency = 0
    highlight.Adornee = enemy
    
    -- Anti-Removal Guard:
    -- If the game's scan ability script deletes our highlight upon cooldown,
    -- this connection immediately intercepts the parenting change and forces it back to the enemy model.
    local parentConn
    parentConn = highlight.AncestryChanged:Connect(function(_, newParent)
        if enemyEspEnabled and not newParent and enemy.Parent then
            pcall(function()
                highlight.Parent = enemy
            end)
        elseif not enemyEspEnabled or not enemy.Parent then
            if parentConn then parentConn:Disconnect() end
        end
    end)
    
    highlight.Parent = enemy
    activeEnemyHighlights[enemy] = highlight
end

local function removeEnemyHighlight(enemy)
    if activeEnemyHighlights[enemy] then
        pcall(function() activeEnemyHighlights[enemy]:Destroy() end)
        activeEnemyHighlights[enemy] = nil
    end
    local highlight = enemy:FindFirstChild("EnemyEspHighlight")
    if highlight then
        pcall(function() highlight:Destroy() end)
    end
end

local function enableEnemyEsp()
    enemyEspEnabled = true
    
    -- Apply highlights to all current enemies
    for _, enemy in ipairs(getAllEnemies()) do
        addEnemyHighlight(enemy)
    end
    updateDoomDuckyCircle()
    
    -- Hook Terrain Enemies
    local terrain = workspace:FindFirstChild("Terrain")
    local enemiesFolder = terrain and terrain:FindFirstChild("Enemies")
    if enemiesFolder then
        table.insert(enemyConnections, enemiesFolder.ChildAdded:Connect(function(child)
            taskWait(0.1)
            if enemyEspEnabled then addEnemyHighlight(child) end
        end))
        table.insert(enemyConnections, enemiesFolder.ChildRemoved:Connect(function(child)
            removeEnemyHighlight(child)
        end))
    end
    
    -- Hook NPCs (Agatha)
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        table.insert(enemyConnections, npcsFolder.ChildAdded:Connect(function(child)
            taskWait(0.1)
            if enemyEspEnabled then addEnemyHighlight(child) end
        end))
        table.insert(enemyConnections, npcsFolder.ChildRemoved:Connect(function(child)
            removeEnemyHighlight(child)
        end))
    end
    
    -- Hook RingPiece (Statue)
    local ringPieceFolder = workspace:FindFirstChild("RingPiece")
    if ringPieceFolder then
        table.insert(enemyConnections, ringPieceFolder.ChildAdded:Connect(function(child)
            taskWait(0.1)
            if enemyEspEnabled then addEnemyHighlight(child) end
        end))
        table.insert(enemyConnections, ringPieceFolder.ChildRemoved:Connect(function(child)
            removeEnemyHighlight(child)
        end))
    end
end

local function disableEnemyEsp()
    enemyEspEnabled = false
    for _, conn in ipairs(enemyConnections) do
        pcall(function() conn:Disconnect() end)
    end
    tableClear(enemyConnections)
    
    for enemy, highlight in pairs(activeEnemyHighlights) do
        if highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    tableClear(activeEnemyHighlights)
    removeDoomDuckyCircle()
end

-- ==========================================
-- SHARD ESP FUNCTIONS
-- ==========================================
local function getShardColor(shard)
    local name = shard.Name
    if string.find(name, "Red") then
        return Color3.fromRGB(255, 60, 60)
    elseif string.find(name, "Orange") then
        return Color3.fromRGB(255, 130, 0)
    elseif string.find(name, "Yellow") or string.find(name, "Gold") then
        return Color3.fromRGB(255, 215, 0)
    elseif string.find(name, "Cyan") or string.find(name, "Blue") then
        return Color3.fromRGB(0, 200, 255)
    elseif string.find(name, "Green") then
        return Color3.fromRGB(0, 255, 100)
    end
    return COLORS.ShardDefaultAccent
end

local function addShardBillboard(shard)
    if not shard:IsA("BasePart") and not shard:IsA("Model") then return end
    if activeShardBillboards[shard] then return end
    
    local adornPart = shard
    if shard:IsA("Model") then
        adornPart = shard.PrimaryPart or shard:FindFirstChildWhichIsA("BasePart")
    end
    if not adornPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ShardEspBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 20, 0, 20)
    billboard.Adornee = adornPart
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "◆"
    label.TextColor3 = getShardColor(shard)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    local labelStroke = Instance.new("UIStroke")
    labelStroke.Color = Color3.fromRGB(0, 0, 0)
    labelStroke.Thickness = 1.5
    labelStroke.Parent = label
    
    billboard.Parent = adornPart
    activeShardBillboards[shard] = billboard
end

local function removeShardBillboard(shard)
    if activeShardBillboards[shard] then
        pcall(function() activeShardBillboards[shard]:Destroy() end)
        activeShardBillboards[shard] = nil
    end
end

local function enableShardEsp()
    shardEspEnabled = true
    local shardsFolder = workspace:FindFirstChild("Shards")
    
    if shardsFolder then
        for _, shard in ipairs(shardsFolder:GetChildren()) do
            addShardBillboard(shard)
        end
        
        shardConnectionAdded = shardsFolder.ChildAdded:Connect(function(child)
            taskWait(0.1)
            if shardEspEnabled then addShardBillboard(child) end
        end)
        
        shardConnectionRemoved = shardsFolder.ChildRemoved:Connect(function(child)
            removeShardBillboard(child)
        end)
    end
end

local function disableShardEsp()
    shardEspEnabled = false
    if shardConnectionAdded then shardConnectionAdded:Disconnect() shardConnectionAdded = nil end
    if shardConnectionRemoved then shardConnectionRemoved:Disconnect() shardConnectionRemoved = nil end
    for shard, billboard in pairs(activeShardBillboards) do
        if billboard then
            pcall(function() billboard:Destroy() end)
        end
    end
    tableClear(activeShardBillboards)
end

-- ==========================================
-- ALTAR ESP FUNCTIONS (Cyan Highlights)
-- ==========================================
local function getAllAltars()
    local altars = {}
    
    -- 1. Main RingAltar
    local ringAltar = getRingAltar()
    if ringAltar then
        table.insert(altars, ringAltar)
    end
    
    -- 2. RingPiece Statue (treated as altar escape)
    local ringPieceFolder = workspace:FindFirstChild("RingPiece")
    if ringPieceFolder then
        for _, item in ipairs(ringPieceFolder:GetChildren()) do
            table.insert(altars, item)
        end
    end
    
    return altars
end

local function getNearestAltar()
    local altars = getAllAltars()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local playerPos = rootPart.Position
    local nearest = nil
    local minDist = math.huge
    for _, altar in ipairs(altars) do
        local altarPart = altar:IsA("BasePart") and altar or altar:FindFirstChildWhichIsA("BasePart")
        if altarPart then
            local dist = (playerPos - altarPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = altarPart
            end
        end
    end
    return nearest
end

local function addAltarHighlight(altar)
    if not altar:IsA("Model") and not altar:IsA("BasePart") then return end
    if activeAltarHighlights[altar] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "AltarEspHighlight"
    highlight.FillColor = COLORS.AltarAccent
    highlight.FillTransparency = 1 -- NO FILL
    highlight.OutlineColor = COLORS.AltarAccent
    highlight.OutlineTransparency = 0
    highlight.Adornee = altar
    highlight.Parent = altar
    
    activeAltarHighlights[altar] = highlight
end

local function removeAltarHighlight(altar)
    if activeAltarHighlights[altar] then
        pcall(function() activeAltarHighlights[altar]:Destroy() end)
        activeAltarHighlights[altar] = nil
    end
end

local function enableAltarEsp()
    altarEspEnabled = true
    
    -- Apply highlights to all current altars
    for _, altar in ipairs(getAllAltars()) do
        addAltarHighlight(altar)
    end
    
    -- Hook RingPiece additions/deletions (Statue spawns)
    local ringPieceFolder = workspace:FindFirstChild("RingPiece")
    if ringPieceFolder then
        table.insert(altarConnections, ringPieceFolder.ChildAdded:Connect(function(child)
            taskWait(0.1)
            if altarEspEnabled then addAltarHighlight(child) end
        end))
        table.insert(altarConnections, ringPieceFolder.ChildRemoved:Connect(function(child)
            removeAltarHighlight(child)
        end))
    end
end

local function disableAltarEsp()
    altarEspEnabled = false
    for _, conn in ipairs(altarConnections) do
        pcall(function() conn:Disconnect() end)
    end
    tableClear(altarConnections)
    
    for altar, highlight in pairs(activeAltarHighlights) do
        if highlight then
            pcall(function() highlight:Destroy() end)
        end
    end
    tableClear(activeAltarHighlights)
end

-- ==========================================
-- PORTAL ESP FUNCTIONS
-- ==========================================
local function addPortalBillboard(portal, labelText, color)
    if not portal:IsA("BasePart") and not portal:IsA("Model") then return end
    if activePortalBillboards[portal] then return end
    
    local adornPart = portal
    if portal:IsA("Model") then
        adornPart = portal.PrimaryPart or portal:FindFirstChildWhichIsA("BasePart")
    end
    if not adornPart then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PortalEspBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.Adornee = adornPart
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    local labelStroke = Instance.new("UIStroke")
    labelStroke.Color = Color3.fromRGB(0, 0, 0)
    labelStroke.Thickness = 1.5
    labelStroke.Parent = label
    
    billboard.Parent = adornPart
    activePortalBillboards[portal] = billboard
end

local function removePortalBillboard(portal)
    if activePortalBillboards[portal] then
        pcall(function() activePortalBillboards[portal]:Destroy() end)
        activePortalBillboards[portal] = nil
    end
end

local function enablePortalEsp()
    portalEspEnabled = true
    local entrance, exitPortal = getPortals()
    if entrance then
        addPortalBillboard(entrance, "Entrance Portal", Color3.fromRGB(150, 155, 165)) -- Gray
    end
    if exitPortal then
        addPortalBillboard(exitPortal, "Exit Portal", Color3.fromRGB(46, 204, 113)) -- Green
    end
end

local function disablePortalEsp()
    portalEspEnabled = false
    for portal, billboard in pairs(activePortalBillboards) do
        if billboard then
            pcall(function() billboard:Destroy() end)
        end
    end
    tableClear(activePortalBillboards)
end

-- ==========================================
-- MISCELLANEOUS: AVOID ENEMY (Reverse Magnet)
-- ==========================================
local function enableAvoidEnemy()
    avoidEnemyEnabled = true
    
    avoidConnection = RunService.Heartbeat:Connect(function()
        if not avoidEnemyEnabled then return end
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local playerPos = rootPart.Position
        local finalPos = playerPos
        local needsAdjust = false
        
        local trap = workspace:FindFirstChild("DoomDuckyTrap")
        
        for _, enemy in ipairs(getAvoidTargets()) do
            local enemyPart = enemy:IsA("BasePart") and enemy or (enemy:IsA("Model") and (enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")))
            if enemyPart then
                local enemyPos = enemyPart.Position
                local diff = playerPos - enemyPos
                local diff2D = Vector3.new(diff.X, 0, diff.Z)
                local dist2D = diff2D.Magnitude
                
                -- DoomDucky has a fixed 50 stud avoidance range
                local isDD = trap and enemy:IsDescendantOf(trap)
                local currentAvoidDist = isDD and 50 or avoidDistance
                
                if dist2D < currentAvoidDist then
                    local direction = diff2D
                    if direction.Magnitude == 0 then
                        direction = Vector3.new(0, 0, 1)
                    end
                    direction = direction.Unit
                    
                    finalPos = enemyPos + direction * (currentAvoidDist + 0.2)
                    finalPos = Vector3.new(finalPos.X, playerPos.Y, finalPos.Z)
                    playerPos = finalPos
                    needsAdjust = true
                end
            end
        end
        
        if needsAdjust then
            rootPart.CFrame = CFrame.new(finalPos) * (rootPart.CFrame - rootPart.CFrame.Position)
        end
    end)
end

local function disableAvoidEnemy()
    avoidEnemyEnabled = false
    if avoidConnection then
        avoidConnection:Disconnect()
        avoidConnection = nil
    end
end

-- ==========================================
-- MISCELLANEOUS: NOCLIP FUNCTIONS & FIX
-- ==========================================
local function disableNoClip()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    taskWait(0.05)
    local character = localPlayer.Character
    if character then
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
            end
        end
    end
end

local function enableNoClip()
    noclipEnabled = true
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        local character = localPlayer.Character
        if character then
            for _, child in ipairs(character:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.CanCollide = false
                end
            end
        end
    end)
end

-- ==========================================
-- MISCELLANEOUS: SHARD TP FUNCTIONS (Infinite Chain)
-- ==========================================
local function startTp()
    if tpActive then return end
    tpActive = true
    
    tpConnection = RunService.Heartbeat:Connect(function()
        if not tpActive then return end
        
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local targetShard = getNearestShard()
        if targetShard then
            local shardPart = targetShard:IsA("BasePart") and targetShard or targetShard:FindFirstChildWhichIsA("BasePart")
            if shardPart then
                rootPart.CFrame = shardPart.CFrame
                -- Blacklist this shard for 3 seconds to let the server register the touch and destroy the shard object.
                visitedShards[targetShard] = os.clock() + 3.0
            end
        end
    end)
end

local function stopTp()
    tpActive = false
    if tpConnection then
        tpConnection:Disconnect()
        tpConnection = nil
    end
end

local speedChangeConnection = nil

local function startSpeedLoop()
    if speedLoopConnection then return end
    
    local function hookHumanoid(humanoid)
        if speedChangeConnection then speedChangeConnection:Disconnect() end
        speedChangeConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed ~= loopSpeedValue then
                humanoid.WalkSpeed = loopSpeedValue
            end
        end)
        humanoid.WalkSpeed = loopSpeedValue
    end
    
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        hookHumanoid(humanoid)
    end
    
    speedLoopConnection = RunService.RenderStepped:Connect(function()
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed ~= loopSpeedValue then
                hum.WalkSpeed = loopSpeedValue
            end
            if not speedChangeConnection or not speedChangeConnection.Connected then
                hookHumanoid(hum)
            end
        end
    end)
end

local function stopSpeedLoop()
    if speedLoopConnection then
        speedLoopConnection:Disconnect()
        speedLoopConnection = nil
    end
    if speedChangeConnection then
        speedChangeConnection:Disconnect()
        speedChangeConnection = nil
    end
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
    end
end

-- ==========================================
-- BACKGROUND ROBUST SYNC LOOP
-- ==========================================
taskSpawn(function()
    while syncRunning do
        taskWait(1.5)
        
        -- Sync Enemy Highlights
        if enemyEspEnabled then
            for _, enemy in ipairs(getAllEnemies()) do
                if not activeEnemyHighlights[enemy] then
                    addEnemyHighlight(enemy)
                end
            end
            updateDoomDuckyCircle()
        end
        
        -- Sync Shard Billboards
        if shardEspEnabled then
            local shardsFolder = workspace:FindFirstChild("Shards")
            if shardsFolder then
                for _, shard in ipairs(shardsFolder:GetChildren()) do
                    if not activeShardBillboards[shard] then
                        addShardBillboard(shard)
                    end
                end
            end
        end
        
        -- Sync Altar Highlights
        if altarEspEnabled then
            for _, altar in ipairs(getAllAltars()) do
                if not activeAltarHighlights[altar] then
                    addAltarHighlight(altar)
                end
            end
        end
        
        -- Sync Portal Billboards
        if portalEspEnabled then
            local entrance, exitPortal = getPortals()
            
            if entrance and not activePortalBillboards[entrance] then
                addPortalBillboard(entrance, "Entrance Portal", Color3.fromRGB(150, 155, 165))
            elseif not entrance and activePortalBillboards[entrance] then
                removePortalBillboard(entrance)
            end
            
            if exitPortal and not activePortalBillboards[exitPortal] then
                addPortalBillboard(exitPortal, "Exit Portal", Color3.fromRGB(46, 204, 113))
            elseif not exitPortal and activePortalBillboards[exitPortal] then
                removePortalBillboard(exitPortal)
            end
        end
        
        -- Clean up expired visited/ignored shards to avoid memory growth
        local now = os.clock()
        for shard, expireTime in pairs(visitedShards) do
            if now > expireTime then
                visitedShards[shard] = nil
            end
        end
    end
end)

-- ==========================================
-- UI CREATION
-- ==========================================
local parentGui = nil

local coreGuiSuccess, coreGuiErr = pcall(function()
    parentGui = game:GetService("CoreGui")
end)

if not coreGuiSuccess or not parentGui then
    if localPlayer then
        parentGui = localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5)
    end
end

if not parentGui then
    parentGui = game:GetService("StarterGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiEspControllerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.DisplayOrder = 9999
end)

-- Main Frame (Draggable Container)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 288, 0, 420) -- Expanded to 288x420 to fit settings and sliders without overlap
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(50, 50, 60)
Stroke.Thickness = 1.5
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke.Parent = MainFrame

-- Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = COLORS.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Name = "HeaderCover"
HeaderCover.Size = UDim2.new(1, 0, 0, 8)
HeaderCover.Position = UDim2.new(0, 0, 1, -8)
HeaderCover.BackgroundColor3 = COLORS.Header
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0) -- Resized to leave room for close button
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ANTIGRAVITY CONTROL PANEL"
Title.TextColor3 = COLORS.TextActive
Title.TextSize = 10
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Header Close/Termination Button ("X")
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -26, 0.5, -10)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = COLORS.TextMuted
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.AutoButtonColor = false
CloseButton.Parent = Header

-- Content Container
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -32)
Content.Position = UDim2.new(0, 0, 0, 32)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Visuals Section Header
local VisualsTitle = Instance.new("TextLabel")
VisualsTitle.Name = "VisualsTitle"
VisualsTitle.Size = UDim2.new(1, -24, 0, 14)
VisualsTitle.Position = UDim2.new(0, 12, 0, 8)
VisualsTitle.BackgroundTransparency = 1
VisualsTitle.Text = "VISUALS"
VisualsTitle.TextColor3 = COLORS.TextMuted
VisualsTitle.TextSize = 9
VisualsTitle.Font = Enum.Font.GothamBold
VisualsTitle.TextXAlignment = Enum.TextXAlignment.Left
VisualsTitle.Parent = Content

-- Helper to create buttons
-- Helper to create labels
local function createRowLabel(text, positionOffset)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 110, 0, 28)
    label.Position = UDim2.new(0, 20, 0, positionOffset)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
    return label
end

-- ==========================================
-- ROW 1: Enemy ESP (offset 26)
-- ==========================================
createRowLabel("Enemy ESP", 26)

local EnemyButton = Instance.new("TextButton")
EnemyButton.Name = "EnemyButton"
EnemyButton.Size = UDim2.new(0, 128, 0, 28)
EnemyButton.Position = UDim2.new(0, 140, 0, 26)
EnemyButton.BackgroundColor3 = COLORS.ToggleOff
EnemyButton.Text = "OFF"
EnemyButton.TextColor3 = COLORS.TextActive
EnemyButton.Font = Enum.Font.GothamBold
EnemyButton.TextSize = 9
EnemyButton.AutoButtonColor = false
EnemyButton.Parent = Content

local EnemyCorner = Instance.new("UICorner")
EnemyCorner.CornerRadius = UDim.new(0, 5)
EnemyCorner.Parent = EnemyButton

local EnemyStroke = Instance.new("UIStroke")
EnemyStroke.Color = Color3.fromRGB(255, 255, 255)
EnemyStroke.Transparency = 0.88
EnemyStroke.Thickness = 1
EnemyStroke.Parent = EnemyButton

-- ==========================================
-- ROW 2: Shard ESP (offset 58)
-- ==========================================
createRowLabel("Shard ESP", 58)

local ShardButton = Instance.new("TextButton")
ShardButton.Name = "ShardButton"
ShardButton.Size = UDim2.new(0, 128, 0, 28)
ShardButton.Position = UDim2.new(0, 140, 0, 58)
ShardButton.BackgroundColor3 = COLORS.ToggleOff
ShardButton.Text = "OFF"
ShardButton.TextColor3 = COLORS.TextActive
ShardButton.Font = Enum.Font.GothamBold
ShardButton.TextSize = 9
ShardButton.AutoButtonColor = false
ShardButton.Parent = Content

local ShardCorner = Instance.new("UICorner")
ShardCorner.CornerRadius = UDim.new(0, 5)
ShardCorner.Parent = ShardButton

local ShardStroke = Instance.new("UIStroke")
ShardStroke.Color = Color3.fromRGB(255, 255, 255)
ShardStroke.Transparency = 0.88
ShardStroke.Thickness = 1
ShardStroke.Parent = ShardButton

-- ==========================================
-- ROW 3: Altar/Statue ESP (offset 90)
-- ==========================================
createRowLabel("Altar/Statue", 90)

local AltarButton = Instance.new("TextButton")
AltarButton.Name = "AltarButton"
AltarButton.Size = UDim2.new(0, 78, 0, 28)
AltarButton.Position = UDim2.new(0, 140, 0, 90)
AltarButton.BackgroundColor3 = COLORS.ToggleOff
AltarButton.Text = "OFF"
AltarButton.TextColor3 = COLORS.TextActive
AltarButton.Font = Enum.Font.GothamBold
AltarButton.TextSize = 9
AltarButton.AutoButtonColor = false
AltarButton.Parent = Content

local AltarCorner = Instance.new("UICorner")
AltarCorner.CornerRadius = UDim.new(0, 5)
AltarCorner.Parent = AltarButton

local AltarStroke = Instance.new("UIStroke")
AltarStroke.Color = Color3.fromRGB(255, 255, 255)
AltarStroke.Transparency = 0.88
AltarStroke.Thickness = 1
AltarStroke.Parent = AltarButton

local AltarTpButton = Instance.new("TextButton")
AltarTpButton.Name = "AltarTpButton"
AltarTpButton.Size = UDim2.new(0, 46, 0, 28)
AltarTpButton.Position = UDim2.new(0, 222, 0, 90)
AltarTpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AltarTpButton.Text = "TP"
AltarTpButton.TextColor3 = COLORS.TextActive
AltarTpButton.Font = Enum.Font.GothamBold
AltarTpButton.TextSize = 10
AltarTpButton.AutoButtonColor = false
AltarTpButton.Parent = Content

local AltarTpCorner = Instance.new("UICorner")
AltarTpCorner.CornerRadius = UDim.new(0, 5)
AltarTpCorner.Parent = AltarTpButton

local AltarTpStroke = Instance.new("UIStroke")
AltarTpStroke.Color = Color3.fromRGB(255, 255, 255)
AltarTpStroke.Transparency = 0.85
AltarTpStroke.Thickness = 1
AltarTpStroke.Parent = AltarTpButton

-- ==========================================
-- ROW 4: Portal ESP (offset 122)
-- ==========================================
createRowLabel("Portal ESP", 122)

local PortalButton = Instance.new("TextButton")
PortalButton.Name = "PortalButton"
PortalButton.Size = UDim2.new(0, 78, 0, 28)
PortalButton.Position = UDim2.new(0, 140, 0, 122)
PortalButton.BackgroundColor3 = COLORS.ToggleOff
PortalButton.Text = "OFF"
PortalButton.TextColor3 = COLORS.TextActive
PortalButton.Font = Enum.Font.GothamBold
PortalButton.TextSize = 9
PortalButton.AutoButtonColor = false
PortalButton.Parent = Content

local PortalCorner = Instance.new("UICorner")
PortalCorner.CornerRadius = UDim.new(0, 5)
PortalCorner.Parent = PortalButton

local PortalStroke = Instance.new("UIStroke")
PortalStroke.Color = Color3.fromRGB(255, 255, 255)
PortalStroke.Transparency = 0.88
PortalStroke.Thickness = 1
PortalStroke.Parent = PortalButton

local PortalTpButton = Instance.new("TextButton")
PortalTpButton.Name = "PortalTpButton"
PortalTpButton.Size = UDim2.new(0, 46, 0, 28)
PortalTpButton.Position = UDim2.new(0, 222, 0, 122)
PortalTpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PortalTpButton.Text = "TP"
PortalTpButton.TextColor3 = COLORS.TextActive
PortalTpButton.Font = Enum.Font.GothamBold
PortalTpButton.TextSize = 10
PortalTpButton.AutoButtonColor = false
PortalTpButton.Parent = Content

local PortalTpCorner = Instance.new("UICorner")
PortalTpCorner.CornerRadius = UDim.new(0, 5)
PortalTpCorner.Parent = PortalTpButton

local PortalTpStroke = Instance.new("UIStroke")
PortalTpStroke.Color = Color3.fromRGB(255, 255, 255)
PortalTpStroke.Transparency = 0.85
PortalTpStroke.Thickness = 1
PortalTpStroke.Parent = PortalTpButton

-- Divider Line
local Divider = Instance.new("Frame")
Divider.Name = "Divider"
Divider.Size = UDim2.new(1, -24, 0, 1)
Divider.Position = UDim2.new(0, 12, 0, 158)
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Divider.BorderSizePixel = 0
Divider.Parent = Content

-- Miscellaneous Section Header
local MiscTitle = Instance.new("TextLabel")
MiscTitle.Name = "MiscTitle"
MiscTitle.Size = UDim2.new(1, -24, 0, 14)
MiscTitle.Position = UDim2.new(0, 12, 0, 166)
MiscTitle.BackgroundTransparency = 1
MiscTitle.Text = "MISCELLANEOUS"
MiscTitle.TextColor3 = COLORS.TextMuted
MiscTitle.TextSize = 9
MiscTitle.Font = Enum.Font.GothamBold
MiscTitle.TextXAlignment = Enum.TextXAlignment.Left
MiscTitle.Parent = Content

-- ==========================================
-- ROW 5: Avoid Enemy (offset 184)
-- ==========================================
createRowLabel("Avoid Enemy", 184)

local AvoidButton = Instance.new("TextButton")
AvoidButton.Name = "AvoidButton"
AvoidButton.Size = UDim2.new(0, 78, 0, 28)
AvoidButton.Position = UDim2.new(0, 140, 0, 184)
AvoidButton.BackgroundColor3 = COLORS.ToggleOff
AvoidButton.Text = "OFF"
AvoidButton.TextColor3 = COLORS.TextActive
AvoidButton.Font = Enum.Font.GothamBold
AvoidButton.TextSize = 9
AvoidButton.AutoButtonColor = false
AvoidButton.Parent = Content

local AvoidCorner = Instance.new("UICorner")
AvoidCorner.CornerRadius = UDim.new(0, 5)
AvoidCorner.Parent = AvoidButton

local AvoidStroke = Instance.new("UIStroke")
AvoidStroke.Color = Color3.fromRGB(255, 255, 255)
AvoidStroke.Transparency = 0.88
AvoidStroke.Thickness = 1
AvoidStroke.Parent = AvoidButton

local AvoidTextBox = Instance.new("TextBox")
AvoidTextBox.Name = "AvoidTextBox"
AvoidTextBox.Size = UDim2.new(0, 46, 0, 28)
AvoidTextBox.Position = UDim2.new(0, 222, 0, 184)
AvoidTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AvoidTextBox.Text = tostring(avoidDistance)
AvoidTextBox.TextColor3 = COLORS.TextActive
AvoidTextBox.PlaceholderText = ""
AvoidTextBox.Font = Enum.Font.GothamBold
AvoidTextBox.TextSize = 10
AvoidTextBox.ClearTextOnFocus = true
AvoidTextBox.Parent = Content

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 5)
BoxCorner.Parent = AvoidTextBox

local BoxStroke = Instance.new("UIStroke")
BoxStroke.Color = Color3.fromRGB(255, 255, 255)
BoxStroke.Transparency = 0.85
BoxStroke.Thickness = 1
BoxStroke.Parent = AvoidTextBox

AvoidTextBox.FocusLost:Connect(function(enterPressed)
    local num = tonumber(AvoidTextBox.Text)
    if num and num >= 0 then
        avoidDistance = num
    else
        AvoidTextBox.Text = tostring(avoidDistance)
    end
end)

-- ==========================================
-- ROW 6: NoClip (offset 218)
-- ==========================================
createRowLabel("NoClip", 218)

local NoClipButton = Instance.new("TextButton")
NoClipButton.Name = "NoClipButton"
NoClipButton.Size = UDim2.new(0, 78, 0, 28)
NoClipButton.Position = UDim2.new(0, 140, 0, 218)
NoClipButton.BackgroundColor3 = COLORS.ToggleOff
NoClipButton.Text = "OFF"
NoClipButton.TextColor3 = COLORS.TextActive
NoClipButton.Font = Enum.Font.GothamBold
NoClipButton.TextSize = 9
NoClipButton.AutoButtonColor = false
NoClipButton.Parent = Content

local NoclipCorner = Instance.new("UICorner")
NoclipCorner.CornerRadius = UDim.new(0, 5)
NoclipCorner.Parent = NoClipButton

local NoclipStroke = Instance.new("UIStroke")
NoclipStroke.Color = Color3.fromRGB(255, 255, 255)
NoclipStroke.Transparency = 0.88
NoclipStroke.Thickness = 1
NoclipStroke.Parent = NoClipButton

local KeybindButton = Instance.new("TextButton")
KeybindButton.Name = "KeybindButton"
KeybindButton.Size = UDim2.new(0, 46, 0, 28)
KeybindButton.Position = UDim2.new(0, 222, 0, 218)
KeybindButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
KeybindButton.Text = noclipKeybind.Name:upper()
KeybindButton.TextColor3 = COLORS.TextActive
KeybindButton.Font = Enum.Font.GothamBold
KeybindButton.TextSize = 10
KeybindButton.AutoButtonColor = false
KeybindButton.Parent = Content

local KeybindCorner = Instance.new("UICorner")
KeybindCorner.CornerRadius = UDim.new(0, 5)
KeybindCorner.Parent = KeybindButton

local KeybindStroke = Instance.new("UIStroke")
KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
KeybindStroke.Transparency = 0.85
KeybindStroke.Thickness = 1
KeybindStroke.Parent = KeybindButton

-- ==========================================
-- ROW 7: Shard TP (offset 252)
-- ==========================================
createRowLabel("Shard TP", 252)

local TpButton = Instance.new("TextButton")
TpButton.Name = "TpButton"
TpButton.Size = UDim2.new(0, 78, 0, 28)
TpButton.Position = UDim2.new(0, 140, 0, 252)
TpButton.BackgroundColor3 = COLORS.ToggleOff
TpButton.Text = "OFF"
TpButton.TextColor3 = COLORS.TextActive
TpButton.Font = Enum.Font.GothamBold
TpButton.TextSize = 9
TpButton.AutoButtonColor = false
TpButton.Parent = Content

local TpCorner = Instance.new("UICorner")
TpCorner.CornerRadius = UDim.new(0, 5)
TpCorner.Parent = TpButton

local TpStroke = Instance.new("UIStroke")
TpStroke.Color = Color3.fromRGB(255, 255, 255)
TpStroke.Transparency = 0.88
TpStroke.Thickness = 1
TpStroke.Parent = TpButton

local TpKeybindButton = Instance.new("TextButton")
TpKeybindButton.Name = "TpKeybindButton"
TpKeybindButton.Size = UDim2.new(0, 46, 0, 28)
TpKeybindButton.Position = UDim2.new(0, 222, 0, 252)
TpKeybindButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TpKeybindButton.Text = tpKeybind.Name:upper()
TpKeybindButton.TextColor3 = COLORS.TextActive
TpKeybindButton.Font = Enum.Font.GothamBold
TpKeybindButton.TextSize = 10
TpKeybindButton.AutoButtonColor = false
TpKeybindButton.Parent = Content

local TpKeybindCorner = Instance.new("UICorner")
TpKeybindCorner.CornerRadius = UDim.new(0, 5)
TpKeybindCorner.Parent = TpKeybindButton

local TpKeybindStroke = Instance.new("UIStroke")
TpKeybindStroke.Color = Color3.fromRGB(255, 255, 255)
TpKeybindStroke.Transparency = 0.85
TpKeybindStroke.Thickness = 1
TpKeybindStroke.Parent = TpKeybindButton

-- ==========================================
-- ROW 8: Speed Slider (offset 286)
-- ==========================================
createRowLabel("Speed", 286)

local SliderTrack = Instance.new("Frame")
SliderTrack.Name = "SliderTrack"
SliderTrack.Size = UDim2.new(0, 78, 0, 4)
SliderTrack.Position = UDim2.new(0, 140, 0, 298) -- Centered vertically at 286 + 12px
SliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
SliderTrack.BorderSizePixel = 0
SliderTrack.Active = true
SliderTrack.Parent = Content

local SliderTrackCorner = Instance.new("UICorner")
SliderTrackCorner.CornerRadius = UDim.new(0, 2)
SliderTrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Name = "SliderFill"
SliderFill.Size = UDim2.new(0.16, 0, 1, 0) -- Default speed 16 is 16% fill
SliderFill.BackgroundColor3 = COLORS.AvoidAccent
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(0, 2)
SliderFillCorner.Parent = SliderFill

local SliderThumb = Instance.new("TextButton")
SliderThumb.Name = "SliderThumb"
SliderThumb.Size = UDim2.new(0, 12, 0, 12)
SliderThumb.Position = UDim2.new(0.16, -6, 0.5, -6)
SliderThumb.BackgroundColor3 = COLORS.TextActive
SliderThumb.BorderSizePixel = 0
SliderThumb.Text = ""
SliderThumb.AutoButtonColor = false
SliderThumb.Parent = SliderTrack

local SliderThumbCorner = Instance.new("UICorner")
SliderThumbCorner.CornerRadius = UDim.new(0, 6)
SliderThumbCorner.Parent = SliderThumb

local SliderThumbStroke = Instance.new("UIStroke")
SliderThumbStroke.Color = Color3.fromRGB(50, 50, 60)
SliderThumbStroke.Thickness = 1
SliderThumbStroke.Parent = SliderThumb

local SpeedTextBox = Instance.new("TextBox")
SpeedTextBox.Name = "SpeedTextBox"
SpeedTextBox.Size = UDim2.new(0, 46, 0, 28)
SpeedTextBox.Position = UDim2.new(0, 222, 0, 286)
SpeedTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SpeedTextBox.Text = tostring(loopSpeedValue)
SpeedTextBox.TextColor3 = COLORS.TextActive
SpeedTextBox.PlaceholderText = ""
SpeedTextBox.Font = Enum.Font.GothamBold
SpeedTextBox.TextSize = 10
SpeedTextBox.ClearTextOnFocus = true
SpeedTextBox.Parent = Content

local SpeedBoxCorner = Instance.new("UICorner")
SpeedBoxCorner.CornerRadius = UDim.new(0, 5)
SpeedBoxCorner.Parent = SpeedTextBox

local SpeedBoxStroke = Instance.new("UIStroke")
SpeedBoxStroke.Color = Color3.fromRGB(255, 255, 255)
SpeedBoxStroke.Transparency = 0.85
SpeedBoxStroke.Thickness = 1
SpeedBoxStroke.Parent = SpeedTextBox

-- Divider Line 2
local Divider2 = Instance.new("Frame")
Divider2.Name = "Divider2"
Divider2.Size = UDim2.new(1, -24, 0, 1)
Divider2.Position = UDim2.new(0, 12, 0, 322)
Divider2.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Divider2.BorderSizePixel = 0
Divider2.Parent = Content

-- Game Settings Section Header
local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Name = "SettingsTitle"
SettingsTitle.Size = UDim2.new(1, -24, 0, 14)
SettingsTitle.Position = UDim2.new(0, 12, 0, 330)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "GAME SETTING"
SettingsTitle.TextColor3 = COLORS.TextMuted
SettingsTitle.TextSize = 9
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.Parent = Content

-- ==========================================
-- ROW 9: Toggle Panel (offset 348)
-- ==========================================
createRowLabel("Toggle Panel", 348)

local PanelHideButton = Instance.new("TextButton")
PanelHideButton.Name = "PanelHideButton"
PanelHideButton.Size = UDim2.new(0, 78, 0, 28)
PanelHideButton.Position = UDim2.new(0, 140, 0, 348)
PanelHideButton.BackgroundColor3 = COLORS.ToggleOff
PanelHideButton.Text = "HIDE"
PanelHideButton.TextColor3 = COLORS.TextActive
PanelHideButton.Font = Enum.Font.GothamBold
PanelHideButton.TextSize = 9
PanelHideButton.AutoButtonColor = false
PanelHideButton.Parent = Content

local PanelHideCorner = Instance.new("UICorner")
PanelHideCorner.CornerRadius = UDim.new(0, 5)
PanelHideCorner.Parent = PanelHideButton

local PanelHideStroke = Instance.new("UIStroke")
PanelHideStroke.Color = Color3.fromRGB(255, 255, 255)
PanelHideStroke.Transparency = 0.88
PanelHideStroke.Thickness = 1
PanelHideStroke.Parent = PanelHideButton

local PanelKeybindButton = Instance.new("TextButton")
PanelKeybindButton.Name = "PanelKeybindButton"
PanelKeybindButton.Size = UDim2.new(0, 46, 0, 28)
PanelKeybindButton.Position = UDim2.new(0, 222, 0, 348)
PanelKeybindButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PanelKeybindButton.Text = panelKeybind.Name:upper()
PanelKeybindButton.TextColor3 = COLORS.TextActive
PanelKeybindButton.Font = Enum.Font.GothamBold
PanelKeybindButton.TextSize = 10
PanelKeybindButton.AutoButtonColor = false
PanelKeybindButton.Parent = Content

local PanelKeybindCorner = Instance.new("UICorner")
PanelKeybindCorner.CornerRadius = UDim.new(0, 5)
PanelKeybindCorner.Parent = PanelKeybindButton

local PanelKeybindStroke = Instance.new("UIStroke")
PanelKeybindStroke.Color = Color3.fromRGB(255, 255, 255)
PanelKeybindStroke.Transparency = 0.85
PanelKeybindStroke.Thickness = 1
PanelKeybindStroke.Parent = PanelKeybindButton



-- ==========================================
-- BUTTON HOOK IMPLEMENTATION
-- ==========================================
-- Fixed Button Shrinking Bug: Uses static absolute sizing for standard toggle buttons (width 200)
local function hookButtonEvents(button, positionOffset, getEnabledState, setEnabledState, enableFunc, disableFunc, activeColor, textDisabled, textEnabled)
    button.MouseEnter:Connect(function()
        local isEnabled = getEnabledState()
        local hoverBase = isEnabled and activeColor or COLORS.ToggleOff
        TweenService:Create(button, TWEEN_INFO, {
            BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08)
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        local isEnabled = getEnabledState()
        TweenService:Create(button, TWEEN_INFO, {
            BackgroundColor3 = isEnabled and activeColor or COLORS.ToggleOff
        }):Play()
    end)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TWEEN_INFO, {
            Size = UDim2.new(0, 124, 0, 24),
            Position = UDim2.new(0, 142, 0, positionOffset + 2)
        }):Play()
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TWEEN_INFO, {
            Size = UDim2.new(0, 128, 0, 28),
            Position = UDim2.new(0, 140, 0, positionOffset)
        }):Play()
        
        local isEnabled = getEnabledState()
        if isEnabled then
            disableFunc()
            button.Text = textDisabled
            TweenService:Create(button, TWEEN_INFO, {
                BackgroundColor3 = COLORS.ToggleOff
            }):Play()
        else
            enableFunc()
            button.Text = textEnabled
            TweenService:Create(button, TWEEN_INFO, {
                BackgroundColor3 = activeColor
            }):Play()
        end
    end)
end

-- Hook Visual Toggles
hookButtonEvents(EnemyButton, 26, function() return enemyEspEnabled end, nil, enableEnemyEsp, disableEnemyEsp, COLORS.EnemyAccent, "OFF", "ON")
hookButtonEvents(ShardButton, 58, function() return shardEspEnabled end, nil, enableShardEsp, disableShardEsp, COLORS.ShardDefaultAccent, "OFF", "ON")

local function updateNoclipUI()
    if noclipEnabled then
        NoClipButton.Text = "ON"
        TweenService:Create(NoClipButton, TWEEN_INFO, { BackgroundColor3 = COLORS.NoclipAccent }):Play()
    else
        NoClipButton.Text = "OFF"
        TweenService:Create(NoClipButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
    end
end

local function updateTpUI()
    if tpActive then
        TpButton.Text = "ON"
        TweenService:Create(TpButton, TWEEN_INFO, { BackgroundColor3 = COLORS.AvoidAccent }):Play()
    else
        TpButton.Text = "OFF"
        TweenService:Create(TpButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
    end
end

-- ==========================================
-- ALTAR ROW CUSTOM INTERACTIVE HOOKS (Fixed Offset 90)
-- ==========================================
AltarButton.MouseEnter:Connect(function()
    local hoverBase = altarEspEnabled and COLORS.AltarAccent or COLORS.ToggleOff
    TweenService:Create(AltarButton, TWEEN_INFO, { BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)

AltarButton.MouseLeave:Connect(function()
    TweenService:Create(AltarButton, TWEEN_INFO, { BackgroundColor3 = altarEspEnabled and COLORS.AltarAccent or COLORS.ToggleOff }):Play()
end)

AltarButton.MouseButton1Down:Connect(function()
    TweenService:Create(AltarButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 92) }):Play()
end)

AltarButton.MouseButton1Up:Connect(function()
    TweenService:Create(AltarButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 90) }):Play()
    if altarEspEnabled then
        disableAltarEsp()
        AltarButton.Text = "OFF"
        TweenService:Create(AltarButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
    else
        enableAltarEsp()
        AltarButton.Text = "ON"
        TweenService:Create(AltarButton, TWEEN_INFO, { BackgroundColor3 = COLORS.AltarAccent }):Play()
    end
end)

AltarTpButton.MouseEnter:Connect(function()
    TweenService:Create(AltarTpButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
end)

AltarTpButton.MouseLeave:Connect(function()
    TweenService:Create(AltarTpButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
end)

AltarTpButton.MouseButton1Down:Connect(function()
    TweenService:Create(AltarTpButton, TWEEN_INFO, { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(0, 224, 0, 92) }):Play()
end)

AltarTpButton.MouseButton1Up:Connect(function()
    TweenService:Create(AltarTpButton, TWEEN_INFO, { Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(0, 222, 0, 90) }):Play()
    
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local target = getNearestAltar()
    if target then
        rootPart.CFrame = target.CFrame
    end
end)

-- ==========================================
-- PORTAL ROW CUSTOM INTERACTIVE HOOKS (Fixed Offset 122)
-- ==========================================
PortalButton.MouseEnter:Connect(function()
    local hoverBase = portalEspEnabled and COLORS.PortalAccent or COLORS.ToggleOff
    TweenService:Create(PortalButton, TWEEN_INFO, { BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)

PortalButton.MouseLeave:Connect(function()
    TweenService:Create(PortalButton, TWEEN_INFO, { BackgroundColor3 = portalEspEnabled and COLORS.PortalAccent or COLORS.ToggleOff }):Play()
end)

PortalButton.MouseButton1Down:Connect(function()
    TweenService:Create(PortalButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 124) }):Play()
end)

PortalButton.MouseButton1Up:Connect(function()
    TweenService:Create(PortalButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 122) }):Play()
    if portalEspEnabled then
        disablePortalEsp()
        PortalButton.Text = "OFF"
        TweenService:Create(PortalButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
    else
        enablePortalEsp()
        PortalButton.Text = "ON"
        TweenService:Create(PortalButton, TWEEN_INFO, { BackgroundColor3 = COLORS.PortalAccent }):Play()
    end
end)

PortalTpButton.MouseEnter:Connect(function()
    TweenService:Create(PortalTpButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
end)

PortalTpButton.MouseLeave:Connect(function()
    TweenService:Create(PortalTpButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
end)

PortalTpButton.MouseButton1Down:Connect(function()
    TweenService:Create(PortalTpButton, TWEEN_INFO, { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(0, 224, 0, 124) }):Play()
end)

PortalTpButton.MouseButton1Up:Connect(function()
    TweenService:Create(PortalTpButton, TWEEN_INFO, { Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(0, 222, 0, 122) }):Play()
    
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local entrance, exitPortal = getPortals()
    local target = exitPortal or entrance
    
    if target then
        local targetPart = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            rootPart.CFrame = targetPart.CFrame
        end
    end
end)

-- ==========================================
-- AVOID ROW CUSTOM HOOKS (Fixed Offset 184)
-- ==========================================
AvoidButton.MouseEnter:Connect(function()
    local hoverBase = avoidEnemyEnabled and COLORS.AvoidAccent or COLORS.ToggleOff
    TweenService:Create(AvoidButton, TWEEN_INFO, { BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)
AvoidButton.MouseLeave:Connect(function()
    TweenService:Create(AvoidButton, TWEEN_INFO, { BackgroundColor3 = avoidEnemyEnabled and COLORS.AvoidAccent or COLORS.ToggleOff }):Play()
end)
AvoidButton.MouseButton1Down:Connect(function()
    TweenService:Create(AvoidButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 186) }):Play()
end)
AvoidButton.MouseButton1Up:Connect(function()
    TweenService:Create(AvoidButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 184) }):Play()
    if avoidEnemyEnabled then disableAvoidEnemy() else enableAvoidEnemy() end
    AvoidButton.Text = avoidEnemyEnabled and "ON" or "OFF"
    TweenService:Create(AvoidButton, TWEEN_INFO, { BackgroundColor3 = avoidEnemyEnabled and COLORS.AvoidAccent or COLORS.ToggleOff }):Play()
end)

-- ==========================================
-- NOCLIP ROW CUSTOM HOOKS (Fixed Offset 218)
-- ==========================================
NoClipButton.MouseEnter:Connect(function()
    local hoverBase = noclipEnabled and COLORS.NoclipAccent or COLORS.ToggleOff
    TweenService:Create(NoClipButton, TWEEN_INFO, { BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)
NoClipButton.MouseLeave:Connect(function()
    TweenService:Create(NoClipButton, TWEEN_INFO, { BackgroundColor3 = noclipEnabled and COLORS.NoclipAccent or COLORS.ToggleOff }):Play()
end)
NoClipButton.MouseButton1Down:Connect(function()
    TweenService:Create(NoClipButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 220) }):Play()
end)
NoClipButton.MouseButton1Up:Connect(function()
    TweenService:Create(NoClipButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 218) }):Play()
    if noclipEnabled then disableNoClip() else enableNoClip() end
    updateNoclipUI()
end)

-- Keybind interaction logic
KeybindButton.MouseEnter:Connect(function()
    TweenService:Create(KeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
end)
KeybindButton.MouseLeave:Connect(function()
    TweenService:Create(KeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
end)
KeybindButton.MouseButton1Down:Connect(function()
    TweenService:Create(KeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(0, 224, 0, 220) }):Play()
end)
KeybindButton.MouseButton1Up:Connect(function()
    TweenService:Create(KeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(0, 222, 0, 218) }):Play()
    bindingActive = true
    KeybindButton.Text = "..."
end)

-- ==========================================
-- SHARD TP ROW CUSTOM HOOKS (Fixed Offset 252)
-- ==========================================
TpButton.MouseEnter:Connect(function()
    local hoverBase = tpActive and COLORS.AvoidAccent or COLORS.ToggleOff
    TweenService:Create(TpButton, TWEEN_INFO, { BackgroundColor3 = hoverBase:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)
TpButton.MouseLeave:Connect(function()
    if tpActive then
        stopTp()
        updateTpUI()
    end
    TweenService:Create(TpButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
end)
TpButton.MouseButton1Down:Connect(function()
    TweenService:Create(TpButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 254) }):Play()
    startTp()
    updateTpUI()
end)
TpButton.MouseButton1Up:Connect(function()
    TweenService:Create(TpButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 252) }):Play()
    stopTp()
    updateTpUI()
end)

TpKeybindButton.MouseEnter:Connect(function()
    TweenService:Create(TpKeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
end)
TpKeybindButton.MouseLeave:Connect(function()
    TweenService:Create(TpKeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
end)
TpKeybindButton.MouseButton1Down:Connect(function()
    TweenService:Create(TpKeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(0, 224, 0, 254) }):Play()
end)
TpKeybindButton.MouseButton1Up:Connect(function()
    TweenService:Create(TpKeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(0, 222, 0, 252) }):Play()
    tpBindingActive = true
    TpKeybindButton.Text = "..."
end)

-- ==========================================
-- SPEED ROW CUSTOM INTERACTIVE HOOKS (Fixed Offset 286)
-- ==========================================
local isDragging = false

local function updateSlider(inputPositionX)
    local trackAbsPos = SliderTrack.AbsolutePosition.X
    local trackAbsWidth = SliderTrack.AbsoluteSize.X
    if trackAbsWidth <= 0 then return end
    
    local relativeX = inputPositionX - trackAbsPos
    local fraction = math.clamp(relativeX / trackAbsWidth, 0, 1)
    
    local speed = math.round(fraction * 100)
    loopSpeedValue = speed
    SpeedTextBox.Text = tostring(speed)
    
    SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    SliderThumb.Position = UDim2.new(fraction, -6, 0.5, -6)
end

SliderThumb.MouseButton1Down:Connect(function()
    isDragging = true
end)

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

SpeedTextBox.FocusLost:Connect(function(enterPressed)
    local num = tonumber(SpeedTextBox.Text)
    if num and num >= 0 then
        loopSpeedValue = num
        
        -- Update visual slider (clamped between 0 and 100)
        local clamped = math.clamp(num, 0, 100)
        local fraction = clamped / 100
        SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
        SliderThumb.Position = UDim2.new(fraction, -6, 0.5, -6)
    else
        SpeedTextBox.Text = tostring(loopSpeedValue)
    end
end)

-- ==========================================
-- GAME SETTING ROW CUSTOM INTERACTIVE HOOKS (Fixed Offset 348)
-- ==========================================
PanelHideButton.MouseEnter:Connect(function()
    TweenService:Create(PanelHideButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff:Lerp(Color3.fromRGB(255,255,255), 0.08) }):Play()
end)

PanelHideButton.MouseLeave:Connect(function()
    TweenService:Create(PanelHideButton, TWEEN_INFO, { BackgroundColor3 = COLORS.ToggleOff }):Play()
end)

PanelHideButton.MouseButton1Down:Connect(function()
    TweenService:Create(PanelHideButton, TWEEN_INFO, { Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(0, 142, 0, 350) }):Play()
end)

PanelHideButton.MouseButton1Up:Connect(function()
    TweenService:Create(PanelHideButton, TWEEN_INFO, { Size = UDim2.new(0, 78, 0, 28), Position = UDim2.new(0, 140, 0, 348) }):Play()
    panelVisible = false
    MainFrame.Visible = false
end)

PanelKeybindButton.MouseEnter:Connect(function()
    TweenService:Create(PanelKeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
end)

PanelKeybindButton.MouseLeave:Connect(function()
    TweenService:Create(PanelKeybindButton, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
end)

PanelKeybindButton.MouseButton1Down:Connect(function()
    TweenService:Create(PanelKeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(0, 224, 0, 350) }):Play()
end)

PanelKeybindButton.MouseButton1Up:Connect(function()
    TweenService:Create(PanelKeybindButton, TWEEN_INFO, { Size = UDim2.new(0, 46, 0, 28), Position = UDim2.new(0, 222, 0, 348) }):Play()
    panelBindingActive = true
    PanelKeybindButton.Text = "..."
end)

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TWEEN_INFO, { TextColor3 = Color3.fromRGB(255, 75, 75) }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TWEEN_INFO, { TextColor3 = COLORS.TextMuted }):Play()
end)

CloseButton.MouseButton1Down:Connect(function()
    CloseButton.TextSize = 12
end)

CloseButton.MouseButton1Up:Connect(function()
    CloseButton.TextSize = 14
    if _G.AntigravityEspCleanup then
        _G.AntigravityEspCleanup()
    end
end)

-- Keyboard inputs (Binding & Keybind triggering)
inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
    -- Allow panel toggle even if Roblox processed it (like pressing F1 while chat is active)
    if not panelBindingActive and not bindingActive and not tpBindingActive then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == panelKeybind then
                panelVisible = not panelVisible
                MainFrame.Visible = panelVisible
                return
            end
        end
    end
    
    if processed then return end
    
    if panelBindingActive then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local code = input.KeyCode
            if not BLOCKED_KEYS[code] then
                panelKeybind = code
            end
            PanelKeybindButton.Text = panelKeybind.Name:upper()
            panelBindingActive = false
        end
    elseif bindingActive then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local code = input.KeyCode
            if not BLOCKED_KEYS[code] then
                noclipKeybind = code
            end
            KeybindButton.Text = noclipKeybind.Name:upper()
            bindingActive = false
        end
    elseif tpBindingActive then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local code = input.KeyCode
            if not BLOCKED_KEYS[code] then
                tpKeybind = code
            end
            TpKeybindButton.Text = tpKeybind.Name:upper()
            tpBindingActive = false
        end
    else
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == noclipKeybind then
                if noclipEnabled then disableNoClip() else enableNoClip() end
                updateNoclipUI()
            elseif input.KeyCode == tpKeybind then
                startTp()
                updateTpUI()
            end
        end
    end
end)

-- Hold-to-trigger Release listener
inputEndedConnection = UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == tpKeybind then
            stopTp()
            updateTpUI()
        end
    end
end)

-- Mount ScreenGui
ScreenGui.Parent = parentGui
startSpeedLoop()

-- ==========================================
-- DEFINING GLOBAL CLEANUP HANDLER
-- ==========================================
_G.AntigravityEspCleanup = function()
    -- Disconnect visual updates & loops
    disableEnemyEsp()
    disableShardEsp()
    disableAltarEsp()
    disablePortalEsp()
    disableAvoidEnemy()
    disableNoClip()
    stopTp()
    stopSpeedLoop()
    
    syncRunning = false
    
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
        inputEndedConnection = nil
    end
    
    -- Destroy ScreenGui safely
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    
    _G.AntigravityEspCleanup = nil
    print("Cleaned")
end

print("Menu Loaded")
