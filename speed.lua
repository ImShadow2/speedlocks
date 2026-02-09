-- SERVICES
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- 1. HARD RESET & ANTI-DUPLICATION
local SessionTag = "CoreUltimate_Final_V18"
if _G[SessionTag] then
    _G[SessionTag].Enabled = false
    if _G[SessionTag].BG then _G[SessionTag].BG:Destroy() end
    if _G[SessionTag].BV then _G[SessionTag].BV:Destroy() end
    for prop, val in pairs(_G[SessionTag].OriginalLighting) do pcall(function() Lighting[prop] = val end) end
    for prompt, duration in pairs(_G[SessionTag].OriginalDurations) do
        if prompt and prompt.Parent then prompt.HoldDuration = duration end
    end
    local oldGui = CoreGui:FindFirstChild("CoreOverlay_Final")
    if oldGui then oldGui:Destroy() end
    task.wait(0.1)
end

local Session = { 
    Enabled = true, 
    BG = nil,
    BV = nil,
    Visible = true,
    OriginalDurations = {}, 
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd
    }
}
_G[SessionTag] = Session

-- 2. GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "CoreOverlay_Final"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 480, 0, 450)
MainFrame.Position = UDim2.new(-1, 0, 0.45, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.Draggable = true

-- ENTRY ANIMATION
task.spawn(function()
    task.wait(0.1)
    TweenService:Create(MainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.003, 0, 0.45, 0)}):Play()
end)

-- RGB Sideline
local RGBStrip = Instance.new("Frame", MainFrame)
RGBStrip.Size = UDim2.new(0, 4, 1, 0); RGBStrip.BorderSizePixel = 0
task.spawn(function()
    while Session.Enabled do
        RGBStrip.BackgroundColor3 = Color3.fromHSV(tick() % 5 / 5, 0.8, 1); task.wait()
    end
end)

local function CreateLabel(text, pos)
    local lbl = Instance.new("TextLabel", MainFrame)
    lbl.Size = UDim2.new(0, 100, 0, 35); lbl.Position = pos; lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = Color3.new(1, 1, 1); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; return lbl
end

CreateLabel("Menu", UDim2.new(0, 10, 0, 5))
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.new(1, 0, 0); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 20
CloseBtn.MouseButton1Down:Connect(function() 
    Session.Enabled = false 
    if Session.BG then Session.BG:Destroy() end
    if Session.BV then Session.BV:Destroy() end
    for prop, val in pairs(Session.OriginalLighting) do pcall(function() Lighting[prop] = val end) end
    for prompt, duration in pairs(Session.OriginalDurations) do if prompt.Parent then prompt.HoldDuration = duration end end
    ScreenGui:Destroy() 
end)

-- FEATURES
CreateLabel("Noclip", UDim2.new(0, 10, 0, 40))
local NoclipBtn = Instance.new("TextButton", MainFrame); NoclipBtn.Size = UDim2.new(1, -120, 0, 30); NoclipBtn.Position = UDim2.new(0, 110, 0, 42); NoclipBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0); NoclipBtn.Text = "Key: V"; NoclipBtn.TextColor3 = Color3.new(1,1,1)

CreateLabel("Speed", UDim2.new(0, 10, 0, 80))
local SpeedInput = Instance.new("TextBox", MainFrame); SpeedInput.Size = UDim2.new(0, 60, 0, 30); SpeedInput.Position = UDim2.new(0, 110, 0, 82); SpeedInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SpeedInput.Text = "100"; SpeedInput.TextColor3 = Color3.new(1,1,1)
local SpeedKeyBtn = Instance.new("TextButton", MainFrame); SpeedKeyBtn.Size = UDim2.new(0, 140, 0, 30); SpeedKeyBtn.Position = UDim2.new(0, 180, 0, 82); SpeedKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); SpeedKeyBtn.Text = "Key: None"; SpeedKeyBtn.TextColor3 = Color3.new(1,1,1)
local SpeedModeBtn = Instance.new("TextButton", MainFrame); SpeedModeBtn.Size = UDim2.new(0, 140, 0, 30); SpeedModeBtn.Position = UDim2.new(0, 330, 0, 82); SpeedModeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); SpeedModeBtn.Text = "Hold"; SpeedModeBtn.TextColor3 = Color3.new(1,1,1)

CreateLabel("Fly", UDim2.new(0, 10, 0, 120))
local FlyInput = Instance.new("TextBox", MainFrame); FlyInput.Size = UDim2.new(0, 60, 0, 30); FlyInput.Position = UDim2.new(0, 110, 0, 122); FlyInput.BackgroundColor3 = Color3.fromRGB(30,30,30); FlyInput.Text = "100"; FlyInput.TextColor3 = Color3.new(1,1,1)
local FlyKeyBtn = Instance.new("TextButton", MainFrame); FlyKeyBtn.Size = UDim2.new(1, -190, 0, 30); FlyKeyBtn.Position = UDim2.new(0, 180, 0, 122); FlyKeyBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); FlyKeyBtn.Text = "Key: None"; FlyKeyBtn.TextColor3 = Color3.new(1,1,1)

CreateLabel("Inf Jump", UDim2.new(0, 10, 0, 160))
local JumpHInput = Instance.new("TextBox", MainFrame); JumpHInput.Size = UDim2.new(0, 60, 0, 30); JumpHInput.Position = UDim2.new(0, 110, 0, 162); JumpHInput.BackgroundColor3 = Color3.fromRGB(30,30,30); JumpHInput.Text = "50"; JumpHInput.TextColor3 = Color3.new(1,1,1)
local JumpTBtn = Instance.new("TextButton", MainFrame); JumpTBtn.Size = UDim2.new(1, -190, 0, 30); JumpTBtn.Position = UDim2.new(0, 180, 0, 162); JumpTBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); JumpTBtn.Text = "Off"; JumpTBtn.TextColor3 = Color3.new(1,1,1)

local function SimpleToggle(text, pos, callback)
    CreateLabel(text, pos)
    local b = Instance.new("TextButton", MainFrame); b.Size = UDim2.new(1, -120, 0, 30); b.Position = UDim2.new(0, 110, pos.Y.Scale, pos.Y.Offset + 2)
    b.BackgroundColor3 = Color3.fromRGB(150,0,0); b.Text = "Off"; b.TextColor3 = Color3.new(1,1,1)
    local s = false; b.MouseButton1Down:Connect(function() s = not s; b.Text = s and "On" or "Off"; b.BackgroundColor3 = s and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0); callback(s) end)
    return b
end

SimpleToggle("Fullbright", UDim2.new(0, 10, 0, 200), function(v) Lighting.Ambient = v and Color3.new(1,1,1) or Session.OriginalLighting.Ambient; Lighting.OutdoorAmbient = v and Color3.new(1,1,1) or Session.OriginalLighting.OutdoorAmbient end)
SimpleToggle("No Fog", UDim2.new(0, 10, 0, 240), function(v) Lighting.FogEnd = v and 999999 or Session.OriginalLighting.FogEnd end)
SimpleToggle("Fast Interact", UDim2.new(0, 10, 0, 280), function(v) _G.FastEnabled = v; if not v then for p, d in pairs(Session.OriginalDurations) do if p.Parent then p.HoldDuration = d end end end end)

CreateLabel("TP Tool", UDim2.new(0, 10, 0, 320))
local TPBtn = Instance.new("TextButton", MainFrame); TPBtn.Size = UDim2.new(1, -120, 0, 30); TPBtn.Position = UDim2.new(0, 110, 0, 322); TPBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); TPBtn.Text = "Add to Backpack"; TPBtn.TextColor3 = Color3.new(1, 1, 1)
TPBtn.MouseButton1Down:Connect(function()
    local tool = Instance.new("Tool"); tool.Name = "Teleport Tool"; tool.RequiresHandle = false; tool.Parent = Players.LocalPlayer.Backpack
    tool.Activated:Connect(function() local pos = Players.LocalPlayer:GetMouse().Hit.p; Players.LocalPlayer.Character:MoveTo(pos + Vector3.new(0, 3, 0)) end)
end)

CreateLabel("Hide", UDim2.new(0, 10, 0, 360))
local HideBtn = Instance.new("TextButton", MainFrame); HideBtn.Size = UDim2.new(1, -120, 0, 30); HideBtn.Position = UDim2.new(0, 110, 0, 362); HideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); HideBtn.Text = "Key: Insert"; HideBtn.TextColor3 = Color3.new(1, 1, 1)

-- LOGIC
local Vars = { noclip = false, speedA = false, speedM = "Hold", fly = false, infJ = false }
local Binds = { noclip = Enum.KeyCode.V, speed = nil, fly = nil, hide = Enum.KeyCode.Insert }

local function SetupRebind(btn, id)
    btn.MouseButton2Down:Connect(function() 
        btn.Text = "Press any key..."; local c; c = UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then Binds[id] = i.KeyCode; btn.Text = "Key: "..i.KeyCode.Name; c:Disconnect() end end)
    end)
end
SetupRebind(NoclipBtn, "noclip"); SetupRebind(SpeedKeyBtn, "speed"); SetupRebind(FlyKeyBtn, "fly"); SetupRebind(HideBtn, "hide")

local function ToggleVisibility()
    Session.Visible = not Session.Visible
    local targetPos = Session.Visible and UDim2.new(0.003, 0, 0.45, 0) or UDim2.new(-1, 0, 0.45, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

SpeedModeBtn.MouseButton1Down:Connect(function() Vars.speedM = (Vars.speedM == "Hold") and "Toggle" or "Hold"; SpeedModeBtn.Text = Vars.speedM end)
JumpTBtn.MouseButton1Down:Connect(function() Vars.infJ = not Vars.infJ; JumpTBtn.Text = Vars.infJ and "On" or "Off"; JumpTBtn.BackgroundColor3 = Vars.infJ and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0) end)

local function SetupPrompt(p) if not Session.OriginalDurations[p] then Session.OriginalDurations[p] = p.HoldDuration end if _G.FastEnabled then p.HoldDuration = 0.0001 end end
for _, o in pairs(workspace:GetDescendants()) do if o:IsA("ProximityPrompt") then SetupPrompt(o) end end
workspace.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then SetupPrompt(d) end end)

-- MAIN LOOP
RunService.Stepped:Connect(function()
    if not Session.Enabled then return end
    local char = Players.LocalPlayer.Character; if not char or not char:FindFirstChild("Humanoid") then return end
    if Vars.noclip then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
    local sOn = (Vars.speedM == "Hold" and Binds.speed and UIS:IsKeyDown(Binds.speed)) or (Vars.speedM == "Toggle" and Vars.speedA)
    char.Humanoid.WalkSpeed = sOn and (tonumber(SpeedInput.Text) or 100) or 16
    
    -- CUSTOM ANIMATION FLY (FREEFALL STATE)
    if Vars.fly then
        if not Session.BV then 
            Session.BV = Instance.new("BodyVelocity", char.HumanoidRootPart); Session.BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            Session.BG = Instance.new("BodyGyro", char.HumanoidRootPart); Session.BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); Session.BG.D = 100
        end
        -- Triggers your paid Falling animation
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall) 
        
        local cam = workspace.CurrentCamera; local s = tonumber(FlyInput.Text) or 100
        local d = Vector3.new(0,0,0)
        if UIS:IsKeyDown("W") then d = d + cam.CFrame.LookVector end
        if UIS:IsKeyDown("S") then d = d - cam.CFrame.LookVector end
        if UIS:IsKeyDown("A") then d = d - cam.CFrame.RightVector end
        if UIS:IsKeyDown("D") then d = d + cam.CFrame.RightVector end
        Session.BV.Velocity = d * s
        Session.BG.CFrame = cam.CFrame
    else
        if Session.BV then Session.BV:Destroy(); Session.BV = nil end
        if Session.BG then Session.BG:Destroy(); Session.BG = nil end
    end
    if _G.FastEnabled then for p, _ in pairs(Session.OriginalDurations) do if p.Parent then p.HoldDuration = 0.0001 end end end
end)

UIS.JumpRequest:Connect(function() 
    if Vars.infJ and Session.Enabled then 
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.Humanoid:ChangeState(3)
            local current = char.HumanoidRootPart.Velocity
            char.HumanoidRootPart.Velocity = Vector3.new(current.X, tonumber(JumpHInput.Text) or 50, current.Z)
        end
    end 
end)

UIS.InputBegan:Connect(function(i, g)
    if g or not Session.Enabled then return end
    if i.KeyCode == Binds.hide then ToggleVisibility()
    elseif i.KeyCode == Binds.noclip then Vars.noclip = not Vars.noclip; NoclipBtn.BackgroundColor3 = Vars.noclip and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
    elseif Binds.speed and i.KeyCode == Binds.speed and Vars.speedM == "Toggle" then Vars.speedA = not Vars.speedA; SpeedKeyBtn.BackgroundColor3 = Vars.speedA and Color3.fromRGB(0,150,0) or Color3.fromRGB(50,50,50)
    elseif Binds.fly and i.KeyCode == Binds.fly then Vars.fly = not Vars.fly; FlyKeyBtn.BackgroundColor3 = Vars.fly and Color3.fromRGB(0,150,0) or Color3.fromRGB(50,50,50) end
end)
