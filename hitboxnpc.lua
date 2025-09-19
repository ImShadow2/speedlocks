-- SETTINGS some npc might be work
_G.HeadSize = 30            -- hitbox size
_G.Range = 200              -- range in studs to apply hitbox
_G.Enabled = true           -- true = on, false = off

-- CLEANUP OLD LOOP
if _G.HitboxConnection then _G.HitboxConnection:Disconnect() end
if _G.InputConnection then _G.InputConnection:Disconnect() end

-- SERVICES
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- TRACK APPLIED NPCS
local Applied = {}

-- FUNCTION TO APPLY EXPANDER
local function ApplyHitbox(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if humanoid and root and not Players:GetPlayerFromCharacter(model) then
        if _G.Enabled then
            root.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
            root.Transparency = 0.7
            root.BrickColor = BrickColor.new("Really blue")
            root.Material = Enum.Material.Neon
            root.CanCollide = false
        else
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
            root.Material = Enum.Material.Plastic
        end
        Applied[model] = true -- mark as applied
    end
end

-- MAIN LOOP (only within range + only if not applied before)
_G.HitboxConnection = RunService.RenderStepped:Connect(function()
    if not _G.Enabled then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and not Applied[model] then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist <= _G.Range then
                    ApplyHitbox(model)
                end
            end
        end
    end
end)

-- HOTKEYS (toggle + refresh)
_G.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F2 then
        _G.Enabled = not _G.Enabled
        print("Hitbox Expander: " .. (_G.Enabled and "ENABLED" or "DISABLED"))

    elseif input.KeyCode == Enum.KeyCode.F3 then
        print("Hitbox Expander: REFRESHING...")
        Applied = {} -- clear applied list
    end
end)
