local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = game.Players.LocalPlayer

-- STYLES
local MAIN_FONT = Enum.Font.Gotham
local BOLD_FONT = Enum.Font.GothamBold
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

-- 1. CLEANUP & RESTORE SYSTEM
if _G.SpeedLockCleanup then _G.SpeedLockCleanup() end

local originalSettings = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    Ambient = Lighting.Ambient
}

local function RestoreLighting()
    for setting, value in pairs(originalSettings) do pcall(function() Lighting[setting] = value end) end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:GetAttribute("WasHidden") then
            obj.Parent = Lighting
            obj:SetAttribute("WasHidden", nil)
        end
    end
end

_G.SpeedLockConnections = {}
_G.SpeedLockCleanup = function()
    local gui = game.CoreGui:FindFirstChild("SpeedLockGUI")
    if gui then gui:Destroy() end
    RestoreLighting()
    for _, c in ipairs(_G.SpeedLockConnections) do pcall(function() c:Disconnect() end) end
    _G.SpeedLockConnections = {}
end

-- 2. STATE DATA
local OriginalDurations = {} 
local FastInteractEnabled, FullbrightEnabled, NoFogEnabled = false, false, false
local infJumpEnabled, boostKey, flyKey, noclipKey = false, nil, nil, Enum.KeyCode.V
local noclip, flying, waitingForBind = false, false, nil
local guiKey = Enum.KeyCode.Insert

-- 3. GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", game.CoreGui); ScreenGui.Name = "SpeedLockGUI"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 320, 0, 310); MainFrame.Position = UDim2.new(-0.5, 0, 1, -530) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MainFrame.BackgroundTransparency = 0.2 
MainFrame.BorderSizePixel = 0; MainFrame.ClipsDescendants = true; MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame)

-- RGB Sideline
local SideLine = Instance.new("Frame", MainFrame)
SideLine.Size = UDim2.new(0, 4, 1, 0); SideLine.Position = UDim2.new(0, 0, 0, 0); SideLine.BorderSizePixel = 0
task.spawn(function()
    while task.wait() do if not MainFrame:IsDescendantOf(game) then break end
        SideLine.BackgroundColor3 = Color3.fromHSV(tick() % 5 / 5, 0.8, 1) 
    end
end)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0, 200, 0, 40); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1
Title.Text = "                                     MENU"; Title.TextColor3 = TEXT_COLOR; Title.Font = BOLD_FONT; Title.TextSize = 14; Title.TextXAlignment = "Left"

local TerminateBtn = Instance.new("TextButton", MainFrame)
TerminateBtn.Size = UDim2.new(0, 30, 0, 30); TerminateBtn.Position = UDim2.new(1, -35, 0, 5); TerminateBtn.BackgroundTransparency = 1
TerminateBtn.Text = "X"; TerminateBtn.TextColor3 = Color3.fromRGB(255, 80, 80); TerminateBtn.Font = BOLD_FONT; TerminateBtn.TextSize = 16
TerminateBtn.MouseButton1Click:Connect(_G.SpeedLockCleanup)

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -25, 1, -50); Content.Position = UDim2.new(0, 15, 0, 45); Content.BackgroundTransparency = 1
Instance.new("UIListLayout", Content).Padding = UDim.new(0, 6)

-- 4. BUILDERS (RMB2 Support)
local function createRow(name, parent)
    local Row = Instance.new("Frame", parent or Content); Row.Size = UDim2.new(1, 0, 0, 35); Row.BackgroundColor3 = Color3.fromRGB(30, 30, 30); Row.BackgroundTransparency = 0.3; Instance.new("UICorner", Row)
    local Lab = Instance.new("TextLabel", Row); Lab.Size = UDim2.new(0.4, 0, 1, 0); Lab.Position = UDim2.new(0, 10, 0, 0); Lab.BackgroundTransparency = 1
    Lab.Text = name; Lab.TextColor3 = TEXT_COLOR; Lab.Font = MAIN_FONT; Lab.TextSize = 12; Lab.TextXAlignment = "Left"
    local RightAlign = Instance.new("Frame", Row); RightAlign.Size = UDim2.new(0.6, -10, 1, 0); RightAlign.Position = UDim2.new(0.4, 0, 0, 0); RightAlign.BackgroundTransparency = 1
    local Layout = Instance.new("UIListLayout", RightAlign); Layout.FillDirection = "Horizontal"; Layout.HorizontalAlignment = "Right"; Layout.VerticalAlignment = "Center"; Layout.Padding = UDim.new(0, 5)
    return RightAlign, Row
end

local function mkBox(p, t)
    local b = Instance.new("TextBox", p); b.Size = UDim2.new(0, 55, 0.7, 0); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45); b.Text = t; b.TextColor3 = TEXT_COLOR; b.Font = MAIN_FONT; b.TextSize = 11; Instance.new("UICorner", b); return b
end

local function mkBtn(p, t, w)
    local b = Instance.new("TextButton", p); b.Size = UDim2.new(0, w or 85, 0.7, 0); b.BackgroundColor3 = Color3.fromRGB(50, 50, 50); b.Text = t; b.TextColor3 = TEXT_COLOR; b.Font = MAIN_FONT; b.TextSize = 11; Instance.new("UICorner", b); return b
end

-- Init Rows
local speedR = createRow("👟   WALK SPEED"); local speedVal = mkBox(speedR, "100"); local speedKey = mkBtn(speedR, "Key: None")
local jumpR = createRow("🦘   INFINITE JUMP"); local jumpVal = mkBox(jumpR, "20"); local jumpTog = mkBtn(jumpR, "Off")
local noclipR = createRow("🚪   NO CLIP"); local noclipBtn = mkBtn(noclipR, "V")
local flyR = createRow("🦅   FLIGHT"); local flyVal = mkBox(flyR, "100"); local flyBtn = mkBtn(flyR, "Key: None")
local interactTog = mkBtn(createRow("⏩   FAST INTERACT"), "Off")
local moreBtn = mkBtn(createRow(""), "More", 280)

local MoreContainer = Instance.new("Frame", Content); MoreContainer.Size = UDim2.new(1, 0, 0, 0); MoreContainer.BackgroundTransparency = 1; MoreContainer.ClipsDescendants = true
Instance.new("UIListLayout", MoreContainer).Padding = UDim.new(0, 5)

local _, fbRow = createRow("🔦    FULL BRIGHT", MoreContainer); local fbBtn = mkBtn(fbRow:FindFirstChild("Frame"), "Off")
local _, nfRow = createRow("☁️    NO FOG", MoreContainer); local nfBtn = mkBtn(nfRow:FindFirstChild("Frame"), "Off")
local _, tpRow = createRow("🔧    TELEPORT TOOL", MoreContainer); local tpBtn = mkBtn(tpRow:FindFirstChild("Frame"), "Add")
local _, hideRow = createRow("🚫    HIDE GUI", MoreContainer); local hideBtn = mkBtn(hideRow:FindFirstChild("Frame"), "Insert")

-- 5. ENGINE LOGIC
moreBtn.MouseButton1Click:Connect(function()
    moreToggled = not moreToggled
    local mH = moreToggled and 470 or 310; local cH = moreToggled and 160 or 0
    TweenService:Create(MainFrame, TweenInfo.new(0.4), {Size = UDim2.new(0, 320, 0, mH)}):Play()
    TweenService:Create(MoreContainer, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, cH)}):Play()
end)

fbBtn.MouseButton1Click:Connect(function() FullbrightEnabled = not FullbrightEnabled; fbBtn.Text = FullbrightEnabled and "On" or "Off"; if not FullbrightEnabled then RestoreLighting() end end)
nfBtn.MouseButton1Click:Connect(function() 
    NoFogEnabled = not NoFogEnabled; nfBtn.Text = NoFogEnabled and "On" or "Off"
    if NoFogEnabled then for _, o in ipairs(Lighting:GetChildren()) do if o:IsA("Atmosphere") then o:SetAttribute("WasHidden", true); o.Parent = nil end end
    else RestoreLighting() end
end)

table.insert(_G.SpeedLockConnections, RunService.RenderStepped:Connect(function()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character.HumanoidRootPart
    if infJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService:GetFocusedTextBox() then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, tonumber(jumpVal.Text) or 20, hrp.Velocity.Z)
    end
    if noclip then for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    if FullbrightEnabled then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.GlobalShadows = false end
    if NoFogEnabled then Lighting.FogEnd = 100000; Lighting.Ambient = Color3.new(1,1,1) end
end))

-- Interaction
local function SetupPrompt(p)
    if p:IsA("ProximityPrompt") then
        if OriginalDurations[p] == nil then OriginalDurations[p] = p.HoldDuration end
        if FastInteractEnabled then p.HoldDuration = 0 end
    end
end
table.insert(_G.SpeedLockConnections, workspace.DescendantAdded:Connect(SetupPrompt))
interactTog.MouseButton1Click:Connect(function()
    FastInteractEnabled = not FastInteractEnabled; interactTog.Text = FastInteractEnabled and "On" or "Off"
    for _, o in ipairs(workspace:GetDescendants()) do SetupPrompt(o) end
    if not FastInteractEnabled then for p, d in pairs(OriginalDurations) do pcall(function() p.HoldDuration = d end) end end
end)

-- Keybinds (RMB2 Logic simulated via click)
local function setBind(btn, tag) 
    btn.MouseButton1Click:Connect(function() btn.Text = "..."; waitingForBind = tag end) 
end
setBind(speedKey, "Speed"); setBind(flyBtn, "Fly"); setBind(noclipBtn, "Noclip"); setBind(hideBtn, "Hide")

table.insert(_G.SpeedLockConnections, UserInputService.InputBegan:Connect(function(i, gpe)
    if waitingForBind then
        if i.KeyCode == Enum.KeyCode.Unknown then return end
        if waitingForBind == "Speed" then boostKey = i.KeyCode; speedKey.Text = "Key: "..i.KeyCode.Name
        elseif waitingForBind == "Fly" then flyKey = i.KeyCode; flyBtn.Text = "Key: "..i.KeyCode.Name
        elseif waitingForBind == "Noclip" then noclipKey = i.KeyCode; noclipBtn.Text = i.KeyCode.Name
        elseif waitingForBind == "Hide" then guiKey = i.KeyCode; hideBtn.Text = i.KeyCode.Name end
        waitingForBind = nil; return
    end
    if gpe then return end
    if i.KeyCode == guiKey then
        local isH = MainFrame.Position.X.Scale < 0
        TweenService:Create(MainFrame, TweenInfo.new(0.5), {Position = isH and UDim2.new(0, 20, 1, -530) or UDim2.new(-0.5, 0, 1, -530)}):Play()
    elseif i.KeyCode == noclipKey then noclip = not noclip
    elseif i.KeyCode == flyKey then flying = not flying
    elseif i.KeyCode == boostKey then pcall(function() player.Character.Humanoid.WalkSpeed = tonumber(speedVal.Text) end) end
end))

table.insert(_G.SpeedLockConnections, UserInputService.InputEnded:Connect(function(i) if i.KeyCode == boostKey then pcall(function() player.Character.Humanoid.WalkSpeed = 16 end) end end))
jumpTog.MouseButton1Click:Connect(function() infJumpEnabled = not infJumpEnabled; jumpTog.Text = infJumpEnabled and "On" or "Off" end)

-- FLY (Space Up / Shift Down)
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

tpBtn.MouseButton1Click:Connect(function()
    local t = Instance.new("Tool", player.Backpack); t.Name = "TP Tool"; t.RequiresHandle = false
    t.Activated:Connect(function() player.Character:MoveTo(player:GetMouse().Hit.Position) end)
end)

TweenService:Create(MainFrame, TweenInfo.new(0.6), {Position = UDim2.new(0, 20, 1, -530)}):Play()
