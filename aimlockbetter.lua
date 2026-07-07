-- Player Aimbot + Optimized ESP
-- FULL FIXED VERSION (No lag, wall check, target validation, connection cleanup, auto-hide FOV)
-- MULTI-METHOD TEAM CHECK & SEPARATED AIMBOT/ESP TEAM SETTINGS & BODY PART PRINTER
-- NON-CONFLICTING MULTI-KEYBIND SYSTEM (Hold RMB + Toggle Key work together)

-- ===============================
-- RESET ON RE-EXECUTION
-- ===============================
if getgenv().inputConnection then getgenv().inputConnection:Disconnect() end
if getgenv().aimbotLoop then getgenv().aimbotLoop:Disconnect() end
if getgenv().FOVring then getgenv().FOVring:Remove() end

-- Cleanup previous player connections to prevent memory leaks
if getgenv().playerConnections then
    for _, conn in pairs(getgenv().playerConnections) do
        conn:Disconnect()
    end
end
getgenv().playerConnections = {}

-- Clean up existing highlights
for _, v in pairs(game:GetService("Players"):GetPlayers()) do
    if v.Character then
        local esp = v.Character:FindFirstChild("AimbotESP")
        if esp then esp:Destroy() end
        local hl = v.Character:FindFirstChild("AimbotHighlight")
        if hl then hl:Destroy() end
    end
end

-- ===============================
-- SETTINGS
-- ===============================
getgenv().teamCheckESP = true     -- Color-codes teammates (Green) and enemies (Red)
getgenv().teamCheckAimbot = false -- Set to false to allow the aimbot to lock onto teammates
getgenv().teammateESP = true      -- Set to false if you want ESP ONLY on enemies (improves performance)

getgenv().wallCheck = false
getgenv().fov = 120
getgenv().smoothing = 1
getgenv().predictionFactor = 0
getgenv().highlightEnabled = true

-- Non-Conflicting Bind Settings (Both can be active at the same time!)
getgenv().HoldToAim = true        -- Enable holding Right Mouse Button (RMB) to aim
getgenv().ToggleToAim = true      -- Enable toggling the aimbot with a keyboard key
getgenv().ToggleKey = Enum.KeyCode.E -- The key used to toggle the aimbot ON/OFF
getgenv().lockPartName = "Head"   -- Target body part

-- ESP Settings
getgenv().ESPenabled = true
getgenv().ESPtoggleKey = Enum.KeyCode.F4
getgenv().EnemyColor = Color3.fromRGB(255, 0, 0)       -- Red for enemies
getgenv().TeammateColor = Color3.fromRGB(0, 255, 128)   -- Bright green/teal for teammates

-- ===============================
-- VARIABLES
-- ===============================
getgenv().currentTarget = nil
getgenv().aimbotEnabled = true
getgenv().toggleState = false
getgenv().debounce = false
getgenv().isAiming = false

-- ===============================
-- SERVICES
-- ===============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- ===============================
-- NOTIFY
-- ===============================
local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

notify("Universal Aimbot + ESP", "Loaded successfully", 4)

-- ===============================
-- PRINT CHARACTER PART NAMES (DEVELOPER CONSOLE)
-- ===============================
local function printCharacterParts(character)
    if not character then return end
    print("========================================")
    print("AVAILABLE BODY PARTS FOR: " .. character.Name)
    print("Set getgenv().lockPartName to any of these:")
    print("----------------------------------------")
    
    local partsFound = {}
    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            if not partsFound[v.Name] then
                partsFound[v.Name] = true
                print("-> " .. v.Name)
            end
        end
    end
    print("========================================")
end

if LocalPlayer.Character then
    printCharacterParts(LocalPlayer.Character)
end

local ownCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    printCharacterParts(char)
end)
table.insert(getgenv().playerConnections, ownCharConn)

-- ===============================
-- FOV CIRCLE
-- ===============================
getgenv().FOVring = Drawing.new("Circle")
getgenv().FOVring.Visible = getgenv().aimbotEnabled
getgenv().FOVring.Thickness = 1.5
getgenv().FOVring.Radius = getgenv().fov
getgenv().FOVring.Transparency = 0.6
getgenv().FOVring.Color = Color3.fromRGB(255, 128, 128)
getgenv().FOVring.Position = Camera.ViewportSize / 2

-- ===============================
-- ROBUST TEAM DETECTION FUNCTIONS
-- ===============================
local function checkTeammate(player)
    if player == LocalPlayer then return true end

    -- Method 1: Standard Roblox Team object comparison
    if player.Team and LocalPlayer.Team then
        return player.Team == LocalPlayer.Team
    end

    -- Method 2: TeamColor comparison
    if player.TeamColor and LocalPlayer.TeamColor then
        return player.TeamColor == LocalPlayer.TeamColor
    end

    -- Method 3: Check for custom "Team" values in player object (common in custom leaderboards)
    local customTeam = player:FindFirstChild("Team") or (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Team"))
    local localCustomTeam = LocalPlayer:FindFirstChild("Team") or (LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Team"))
    
    if customTeam and localCustomTeam and customTeam.Value == localCustomTeam.Value then
        return true
    end

    -- Method 4: Attribute comparison
    if player:GetAttribute("Team") and LocalPlayer:GetAttribute("Team") then
        return player:GetAttribute("Team") == LocalPlayer:GetAttribute("Team")
    end

    return false
end

-- ===============================
-- ESP FUNCTIONS (DYNAMIC HIGHLIGHTS)
-- ===============================
local function addESP(player)
    if not getgenv().ESPenabled then return end
    local character = player.Character
    if not character then return end

    local isTeam = getgenv().teamCheckESP and checkTeammate(player)

    if isTeam and not getgenv().teammateESP then
        local old = character:FindFirstChild("AimbotESP")
        if old then old:Destroy() end
        return
    end

    local esp = character:FindFirstChild("AimbotESP")
    if not esp then
        esp = Instance.new("Highlight")
        esp.Name = "AimbotESP"
        esp.Parent = character
    end

    esp.FillTransparency = 1
    esp.OutlineColor = isTeam and getgenv().TeammateColor or getgenv().EnemyColor
    esp.OutlineTransparency = 0
    esp.Adornee = character
end

local function removeESP(character)
    local esp = character:FindFirstChild("AimbotESP")
    if esp then esp:Destroy() end
end

local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            addESP(player)
        end
    end
end

-- ===============================
-- PLAYER JOIN / RESPAWN / LEAVE
-- ===============================
local function setupPlayer(player)
    if player == LocalPlayer then return end

    if player.Character then
        addESP(player)
    end

    local charAddedConn = player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        addESP(player)
    end)
    table.insert(getgenv().playerConnections, charAddedConn)

    local teamChangedConn = player:GetPropertyChangedSignal("Team"):Connect(function()
        if player.Character then
            addESP(player)
        end
    end)
    table.insert(getgenv().playerConnections, teamChangedConn)

    local teamColorChangedConn = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if player.Character then
            addESP(player)
        end
    end)
    table.insert(getgenv().playerConnections, teamColorChangedConn)
end

local ownTeamConn = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshAllESP)
local ownTeamColorConn = LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(refreshAllESP)
table.insert(getgenv().playerConnections, ownTeamConn)
table.insert(getgenv().playerConnections, ownTeamColorConn)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

table.insert(getgenv().playerConnections, Players.PlayerAdded:Connect(setupPlayer))

table.insert(getgenv().playerConnections, Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        removeESP(player.Character)
    end
end))

-- ===============================
-- VISIBILITY CHECK (RAYCASTING)
-- ===============================
local function isVisible(character, part)
    if not getgenv().wallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local destination = part.Position
    local direction = destination - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

-- ===============================
-- AIMBOT FUNCTIONS
-- ===============================
local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local center = Camera.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = player.Character:FindFirstChild(getgenv().lockPartName)
            local hum = player.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health > 0 then
                local isTeam = getgenv().teamCheckAimbot and checkTeammate(player)
                if not isTeam then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if onScreen and dist <= getgenv().fov and dist < shortest then
                        if isVisible(player.Character, part) then
                            closest = player
                            shortest = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function predictPosition(target)
    local part = target.Character:FindFirstChild(getgenv().lockPartName)
    if part then
        return part.Position + (part.Velocity * getgenv().predictionFactor)
    end
end

local function highlightTarget(target)
    if not getgenv().highlightEnabled or not target or not target.Character then return end

    local old = target.Character:FindFirstChild("AimbotHighlight")
    if old then old:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name = "AimbotHighlight"
    hl.Adornee = target.Character
    hl.FillColor = Color3.fromRGB(255, 128, 128)
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.Parent = target.Character
end

local function removeHighlight(target)
    if target and target.Character then
        local hl = target.Character:FindFirstChild("AimbotHighlight")
        if hl then hl:Destroy() end
    end
end

-- ===============================
-- INPUT HANDLING
-- ===============================
local function toggleESP()
    getgenv().ESPenabled = not getgenv().ESPenabled
    refreshAllESP()
    notify("ESP", getgenv().ESPenabled and "Enabled" or "Disabled")
end

local function handleToggle()
    if getgenv().debounce then return end
    getgenv().debounce = true
    getgenv().toggleState = not getgenv().toggleState
    notify("Aimbot", getgenv().toggleState and "ON" or "OFF")
    task.wait(0.3)
    getgenv().debounce = false
end

getgenv().inputConnection = UIS.InputBegan:Connect(function(input, gpe)
    if UIS:GetFocusedTextBox() then return end

    if gpe and input.UserInputType == Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode == getgenv().ToggleKey and getgenv().ToggleToAim then
        handleToggle()
    elseif input.KeyCode == getgenv().ESPtoggleKey then
        toggleESP()
    elseif input.KeyCode == Enum.KeyCode.End then
        getgenv().aimbotEnabled = not getgenv().aimbotEnabled
        getgenv().FOVring.Visible = getgenv().aimbotEnabled
        notify("Aimbot System", getgenv().aimbotEnabled and "Enabled" or "Disabled")
    -- RMB can trigger aimbot independently of whether keybind toggle is active
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and getgenv().HoldToAim then
        getgenv().isAiming = true
    end
end)

local mouseUpConn
mouseUpConn = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        getgenv().isAiming = false
    end
end)
table.insert(getgenv().playerConnections, mouseUpConn)

-- ===============================
-- AIMBOT LOOP
-- ===============================
getgenv().aimbotLoop = RunService.RenderStepped:Connect(function()
    getgenv().FOVring.Visible = getgenv().aimbotEnabled
    if not getgenv().aimbotEnabled then return end

    getgenv().FOVring.Position = Camera.ViewportSize / 2

    -- Aimbot aims if EITHER Toggle state is active OR RMB is being held down. No conflicts!
    local shouldAim = (getgenv().ToggleToAim and getgenv().toggleState) or (getgenv().HoldToAim and getgenv().isAiming)

    if shouldAim then
        local target = getgenv().currentTarget
        if target and target.Character then
            local hum = target.Character:FindFirstChild("Humanoid")
            local part = target.Character:FindFirstChild(getgenv().lockPartName)
            if not (hum and hum.Health > 0 and part and isVisible(target.Character, part)) then
                removeHighlight(target)
                getgenv().currentTarget = nil
            end
        else
            getgenv().currentTarget = nil
        end

        if not getgenv().currentTarget then
            getgenv().currentTarget = getClosestTarget()
            if getgenv().currentTarget then
                highlightTarget(getgenv().currentTarget)
            end
        end

        if getgenv().currentTarget then
            local pos = predictPosition(getgenv().currentTarget)
            if pos then
                Camera.CFrame = Camera.CFrame:Lerp(
                    CFrame.new(Camera.CFrame.Position, pos),
                    getgenv().smoothing
                )
            end
            getgenv().FOVring.Color = Color3.fromRGB(0, 255, 0)
        else
            getgenv().FOVring.Color = Color3.fromRGB(255, 128, 128)
        end
    else
        if getgenv().currentTarget then
            removeHighlight(getgenv().currentTarget)
            getgenv().currentTarget = nil
        end
        getgenv().FOVring.Color = Color3.fromRGB(255, 128, 128)
    end
end)
