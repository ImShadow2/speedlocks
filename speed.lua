-- [[ Smart Speed Lock - Final Optimized Logic ]] --

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = game.Players.LocalPlayer

-- 1. CLEANUP & ANTI-GHOSTING
if _G.SpeedLockCleanup then _G.SpeedLockCleanup() end
_G.SpeedLockConnections = {}
_G.SpeedLockCleanup = function()
    local gui = game.CoreGui:FindFirstChild("SpeedLockGUI")
    if gui then
        local frame = gui:FindFirstChild("MainFrame")
        if frame then
            local t = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-0.5, 0, 1, -380)})
            t:Play() t.Completed:Wait()
        end
        gui:Destroy()
    end
    for _, c in ipairs(_G.SpeedLockConnections) do pcall(function() c:Disconnect() end) end
    _G.SpeedLockConnections = {}
    if _G.OriginalLighting then
        Lighting.Brightness = _G.OriginalLighting.Brightness
        Lighting.ClockTime = _G.OriginalLighting.ClockTime
        Lighting.OutdoorAmbient = _G.OriginalLighting.Ambient
        Lighting.FogEnd = _G.OriginalLighting.FogEnd
        if _G.StoredAtmosphere then _G.StoredAtmosphere.Parent = Lighting end
    end
end

-- 2. SAVE STATE
_G.OriginalLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd }
_G.StoredAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

local boostSpeed, holdKey = 100, nil
local noclip, noclipKey = false, Enum.KeyCode.V
local flySpeed, flyKey, flying = 100, nil, false
local infJumpEnabled, jumpPower = false, 50
local fastInteract, fullbright, nofog = false, false, false
local guiKey = Enum.KeyCode.Insert
local waitingForBind = nil
local originalHold = {}

-- 3. GUI CONSTRUCTION (Bottom-Left)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "SpeedLockGUI"; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Position = UDim2.new(-0.5, 0, 1, -380)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame)

-- RGB Sideline
local SideLine = Instance.new("Frame", MainFrame)
SideLine.Size = UDim2.new(0, 3, 1, -20); SideLine.Position = UDim2.new(0, 5, 0, 10); SideLine.BorderSizePixel = 0
task.spawn(function()
    while task.wait() do 
        if not MainFrame:IsDescendantOf(game) then break end
        SideLine.BackgroundColor3 = Color3.fromHSV(tick() % 5 / 5, 0.8, 1) 
    end
end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0, 200, 0, 40); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1
Title.Text = "MENU"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = "GothamBold"; Title.TextSize = 16; Title.TextXAlignment = "Left"

local TerminateBtn = Instance.new("TextButton", MainFrame)
TerminateBtn.Size = UDim2.new(0, 30, 0, 30); TerminateBtn.Position = UDim2.new(1, -35, 0, 5); TerminateBtn.BackgroundTransparency = 1
TerminateBtn.Text = "X"; TerminateBtn.TextColor3 = Color3.fromRGB(255, 80, 80); TerminateBtn.Font = "GothamBold"; TerminateBtn.TextSize = 18
TerminateBtn.MouseButton1Click:Connect(_G.SpeedLockCleanup)

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -25, 1, -50); Content.Position = UDim2.new(0, 15, 0, 45); Content.BackgroundTransparency = 1
Instance.new("UIListLayout", Content).Padding = UDim.new(0, 6)

-- Injection Animation
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 1, -380)}):Play()

-- 4. HELPERS
local function createRow(name)
    local Row = Instance.new("Frame", Content); Row.Size = UDim2.new(1, 0, 0, 35); Row.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Instance.new("UICorner", Row)
    local Lab = Instance.new("TextLabel", Row); Lab.Size = UDim2.new(0.4, 0, 1, 0); Lab.Position = UDim2.new(0, 10, 0, 0); Lab.BackgroundTransparency = 1
    Lab.Text = name; Lab.TextColor3 = Color3.fromRGB(180, 180, 180); Lab.Font = "Gotham"; Lab.TextSize = 12; Lab.TextXAlignment = "Left"
    local RightAlign = Instance.new("Frame", Row); RightAlign.Size = UDim2.new(0.6, -10, 1, 0); RightAlign.Position = UDim2.new(0.4, 0, 0, 0); RightAlign.BackgroundTransparency = 1
    local Layout = Instance.new("UIListLayout", RightAlign); Layout.FillDirection = "Horizontal"; Layout.HorizontalAlignment = "Right"; Layout.VerticalAlignment = "Center"; Layout.Padding = UDim.new(0, 5)
    return RightAlign
end

local function mkBox(p, t)
    local b = Instance.new("TextBox", p); b.Size = UDim2.new(0, 55, 0.7, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.Text = t; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 11; Instance.new("UICorner", b); return b
end

local function mkBtn(p, t, w)
    local b = Instance.new("TextButton", p); b.Size = UDim2.new(0, w or 85, 0.7, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.Text = t; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 11; Instance.new("UICorner", b); return b
end

-- Rows Setup
local speedR = createRow("👟 WALK SPEED"); local speedVal = mkBox(speedR, "100"); local speedKey = mkBtn(speedR, "Key: None")
local jumpR = createRow("🦘 INFINITE JUMP"); local jumpVal = mkBox(jumpR, "50"); local jumpTog = mkBtn(jumpR, "Off")
local noclipBtn = mkBtn(createRow("🚪 NO CLIP"), "V")
local flyR = createRow("🦅 FLY"); local flyVal = mkBox(flyR, "100"); local flyBtn = mkBtn(flyR, "Key: None")
local tpBtn = mkBtn(createRow("🔧 TP TOOL"), "Add")
local interactTog = mkBtn(createRow("⏩ FAST INTERACT"), "Off")
local moreBtn = mkBtn(createRow(""), "MORE", 280)

local moreFrame = Instance.new("Frame", Content); moreFrame.Size = UDim2.new(1, 0, 0, 120); moreFrame.Visible = false; moreFrame.BackgroundTransparency = 1
Instance.new("UIListLayout", moreFrame).Padding = UDim.new(0, 5)

local function mkSub(n)
    local r = Instance.new("Frame", moreFrame); r.Size = UDim2.new(1, 0, 0, 35); r.BackgroundColor3 = Color3.fromRGB(20, 20, 20); Instance.new("UICorner", r)
    local l = Instance.new("TextLabel", r); l.Size = UDim2.new(0.5,0,1,0); l.Position = UDim2.new(0,15,0,0); l.BackgroundTransparency=1; l.Text=n; l.TextColor3=Color3.fromRGB(150,150,150); l.Font="Gotham"; l.TextSize=11; l.TextXAlignment="Left"
    local b = mkBtn(r, "Off", 85); b.Position = UDim2.new(1, -90, 0.15, 0); return b
end
local fbBtn = mkSub("🔦 FULL BRIGHT"); local nfBtn = mkSub("🔭 NO FOG"); local hideBtn = mkSub("🚫 HIDE GUI"); hideBtn.Text = "Insert"

-- 5. ENGINE LOGIC
local function toggleGui()
    local isHidden = MainFrame.Position.X.Scale < 0
    local target = isHidden and UDim2.new(0, 20, 1, -380) or UDim2.new(-0.5, 0, 1, -380)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = target}):Play()
end

moreBtn.MouseButton1Click:Connect(function()
    moreFrame.Visible = not moreFrame.Visible
    local targetHeight = moreFrame.Visible and 480 or 350
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, targetHeight)}):Play()
end)

-- Binds
local function startBind(btn, tag) waitingForBind = tag; btn.Text = "..." end
speedKey.MouseButton1Click:Connect(function() startBind(speedKey, "Speed") end)
flyBtn.MouseButton1Click:Connect(function() startBind(flyBtn, "Fly") end)
noclipBtn.MouseButton1Click:Connect(function() startBind(noclipBtn, "Noclip") end)
hideBtn.MouseButton1Click:Connect(function() startBind(hideBtn, "Hide") end)

jumpTog.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    jumpTog.Text = infJumpEnabled and "On" or "Off"
end)

table.insert(_G.SpeedLockConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if waitingForBind then
        if input.KeyCode == Enum.KeyCode.Unknown then return end
        if waitingForBind == "Speed" then holdKey = input.KeyCode; speedKey.Text = "Key: "..input.KeyCode.Name
        elseif waitingForBind == "Fly" then flyKey = input.KeyCode; flyBtn.Text = "Key: "..input.KeyCode.Name
        elseif waitingForBind == "Noclip" then noclipKey = input.KeyCode; noclipBtn.Text = input.KeyCode.Name
        elseif waitingForBind == "Hide" then guiKey = input.KeyCode; hideBtn.Text = input.KeyCode.Name end
        waitingForBind = nil; return
    end
    if gpe then return end
    if input.KeyCode == guiKey then toggleGui()
    elseif input.KeyCode == holdKey then pcall(function() player.Character.Humanoid.WalkSpeed = tonumber(speedVal.Text) or 100 end)
    elseif input.KeyCode == noclipKey then noclip = not noclip
    elseif input.KeyCode == flyKey then flying = not flying end
end))

table.insert(_G.SpeedLockConnections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == holdKey then pcall(function() player.Character.Humanoid.WalkSpeed = 16 end) end
end))

-- Execution Loops
table.insert(_G.SpeedLockConnections, RunService.Stepped:Connect(function()
    if noclip and player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    if fullbright then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.OutdoorAmbient = Color3.new(1,1,1) end
end))

fbBtn.MouseButton1Click:Connect(function() 
    fullbright = not fullbright; fbBtn.Text = fullbright and "On" or "Off"
    if not fullbright then Lighting.Brightness = _G.OriginalLighting.Brightness; Lighting.ClockTime = _G.OriginalLighting.ClockTime; Lighting.OutdoorAmbient = _G.OriginalLighting.Ambient end
end)

nfBtn.MouseButton1Click:Connect(function()
    nofog = not nofog; nfBtn.Text = nofog and "On" or "Off"
    if nofog then Lighting.FogEnd = 100000; local atm = Lighting:FindFirstChildOfClass("Atmosphere") if atm then atm.Parent = nil end
    else Lighting.FogEnd = _G.OriginalLighting.FogEnd; if _G.StoredAtmosphere then _G.StoredAtmosphere.Parent = Lighting end end
end)

interactTog.MouseButton1Click:Connect(function()
    fastInteract = not fastInteract; interactTog.Text = fastInteract and "On" or "Off"
    for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then
        if fastInteract then if originalHold[v] == nil then originalHold[v] = v.HoldDuration end v.HoldDuration = 0 
        else v.HoldDuration = originalHold[v] or v.HoldDuration end
    end end
end)

-- Fly Script
local bv, bg
table.insert(_G.SpeedLockConnections, RunService.RenderStepped:Connect(function()
    if flying and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        if not bv or bv.Parent ~= hrp then bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e6,1e6,1e6); bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e6,1e6,1e6) end
        local cam = workspace.CurrentCamera; local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        bv.Velocity = dir.Unit * (tonumber(flyVal.Text) or 100); if dir == Vector3.new(0,0,0) then bv.Velocity = Vector3.new(0,0,0) end; bg.CFrame = cam.CFrame
    else if bv then bv:Destroy(); bv = nil; bg:Destroy(); bg = nil end end
end))

-- SMART INF JUMP (Custom Logic)
table.insert(_G.SpeedLockConnections, UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            -- Reset state to allow "fresh" jump
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            -- Apply upward impulse relative to mass
            local jumpPowerVal = tonumber(jumpVal.Text) or 50
            hrp.Velocity = Vector3.new(hrp.Velocity.X, jumpPowerVal, hrp.Velocity.Z)
        end
    end
end))

tpBtn.MouseButton1Click:Connect(function()
    local t = Instance.new("Tool", player.Backpack); t.Name = "TP Tool"; t.RequiresHandle = false
    t.Activated:Connect(function() player.Character:MoveTo(player:GetMouse().Hit.Position) end)
end)
