-- 1. NUCLEAR SYMMETRICAL CLEANUP & FAIL-SAFE EXECUTION
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local TAG = "Matrix_V34_Stable"

-- Initial Setup for Reverting
if not getgenv().OriginalLighting then
    getgenv().OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    }
end
getgenv().OriginalDurations = getgenv().OriginalDurations or {}

local function WipeAll()
    _G.KillMenu = true 
    pcall(function()
        -- Reset Lighting
        local orig = getgenv().OriginalLighting
        Lighting.Brightness = orig.Brightness
        Lighting.ClockTime = orig.ClockTime
        Lighting.FogEnd = orig.FogEnd
        Lighting.GlobalShadows = orig.GlobalShadows
        Lighting.Ambient = orig.Ambient

        -- Reset Prompts
        for prompt, duration in pairs(getgenv().OriginalDurations) do
            if prompt and prompt.Parent then prompt.HoldDuration = duration end
        end
        getgenv().OriginalDurations = {}

        -- Kill FOV Drawing
        if getgenv().FOVCircle then
            getgenv().FOVCircle.Visible = false
            getgenv().FOVCircle:Destroy()
            getgenv().FOVCircle = nil
        end
        
        -- Remove GUIs
        for _, v in pairs(CoreGui:GetChildren()) do
            if v.Name:find("Matrix") then v:Destroy() end
        end

        -- Physics Reset
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false; hum.WalkSpeed = 16 end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
            end
        end
    end)
end

WipeAll()
task.wait(0.3)
_G.KillMenu = false

-- 2. DRAWING API
local FOV = Drawing.new("Circle")
FOV.Thickness = 1.5; FOV.Color = Color3.new(1, 1, 1); FOV.Transparency = 1; FOV.Filled = false; FOV.Visible = false
getgenv().FOVCircle = FOV

-- 3. SETTINGS
local LockedTarget = nil
local bv, bg
local Settings = {
    Speed = {Bind = nil, Value = 100},
    InfJump = {Status = false, Power = 50},
    Fly = {Status = false, Bind = nil, Speed = 100},
    ESP = {Status = false},
    Aimlock = {Status = false, FOVSize = 100},
    Fullbright = {Status = false},
    NoFog = {Status = false},
    FastInteract = {Status = false},
    HideGui = {Bind = Enum.KeyCode.Insert, Status = true}
}

-- 4. GUI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = TAG
local Outer = Instance.new("Frame", ScreenGui)
Outer.Size = UDim2.new(0, 360, 0, 440); Outer.Position = UDim2.new(0.5, -180, 0.3, 0)
Outer.BackgroundColor3 = Color3.new(1, 1, 1); Outer.BorderSizePixel = 0; Outer.Active = true; Outer.Draggable = true; Instance.new("UICorner", Outer)

local Main = Instance.new("Frame", Outer)
Main.Size = UDim2.new(1, -4, 1, -6); Main.Position = UDim2.new(0, 2, 0, 3)
Main.BackgroundColor3 = Color3.new(0, 0, 0); Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -40, 0, 45); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1
Title.Text = "MENU"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = 0

local Close = Instance.new("TextButton", Main)
Close.Size = UDim2.new(0, 24, 0, 24); Close.Position = UDim2.new(1, -32, 0, 10); Close.BackgroundColor3 = Color3.fromRGB(60, 0, 0); Close.Text = "X"; Close.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", Close); Close.MouseButton1Click:Connect(WipeAll)

local function NewRow(text, y)
    local r = Instance.new("Frame", Main); r.Size = UDim2.new(1, -30, 0, 35); r.Position = UDim2.new(0, 15, 0, y); r.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", r); l.Size = UDim2.new(0, 110, 1, 0); l.Text = text .. "    "; l.TextColor3 = Color3.new(1, 1, 1); l.Font = Enum.Font.GothamSemibold; l.BackgroundTransparency = 1; l.TextSize = 13; l.TextXAlignment = 0
    local c = Instance.new("Frame", r); c.Size = UDim2.new(1, -115, 1, 0); c.Position = UDim2.new(0, 115, 0, 0); c.BackgroundTransparency = 1
    local lay = Instance.new("UIListLayout", c); lay.FillDirection = 0; lay.HorizontalAlignment = 1; lay.VerticalAlignment = 1; lay.Padding = UDim.new(0, 8)
    return c
end

-- DATA ROWS
local c1 = NewRow("👟 Speed", 55); local sInp = Instance.new("TextBox", c1); sInp.Size = UDim2.new(0.3, 0, 1, 0); sInp.Text = "100"; local sBnd = Instance.new("TextButton", c1); sBnd.Size = UDim2.new(0.7, -8, 1, 0); sBnd.Text = "[ Bind ]"
local c2 = NewRow("🦘 Inf Jump", 95); local jInp = Instance.new("TextBox", c2); jInp.Size = UDim2.new(0.3, 0, 1, 0); jInp.Text = "50"; local jTgl = Instance.new("TextButton", c2); jTgl.Size = UDim2.new(0.7, -8, 1, 0); jTgl.Text = "Off"
local c3 = NewRow("🦅 Fly", 135); local fInp = Instance.new("TextBox", c3); fInp.Size = UDim2.new(0.3, 0, 1, 0); fInp.Text = "100"; local fBnd = Instance.new("TextButton", c3); fBnd.Size = UDim2.new(0.7, -8, 1, 0); fBnd.Text = "[ Bind ]"
local c4 = NewRow("👀 ESP", 175); local eTgl = Instance.new("TextButton", c4); eTgl.Size = UDim2.new(1, 0, 1, 0); eTgl.Text = "Off"
local c5 = NewRow("🎯 Aimlock", 215); local aInp = Instance.new("TextBox", c5); aInp.Size = UDim2.new(0.3, 0, 1, 0); aInp.Text = "100"; local aTgl = Instance.new("TextButton", c5); aTgl.Size = UDim2.new(0.7, -8, 1, 0); aTgl.Text = "Off"
local c6 = NewRow("🔦 Fullbright", 255); local bTgl = Instance.new("TextButton", c6); bTgl.Size = UDim2.new(1, 0, 1, 0); bTgl.Text = "Off"
local c7 = NewRow("🔭 No Fog", 295); local nTgl = Instance.new("TextButton", c7); nTgl.Size = UDim2.new(1, 0, 1, 0); nTgl.Text = "Off"
local c8 = NewRow("⏩ Fast Interact", 335); local iTgl = Instance.new("TextButton", c8); iTgl.Size = UDim2.new(1, 0, 1, 0); iTgl.Text = "Off"
local c9 = NewRow("🚫 Hide GUI", 375); local hBnd = Instance.new("TextButton", c9); hBnd.Size = UDim2.new(1, 0, 1, 0); hBnd.Text = "[ Insert ]"

for _, v in pairs(Main:GetDescendants()) do if v:IsA("TextBox") or v:IsA("TextButton") then if v ~= Close then v.BackgroundColor3 = Color3.fromRGB(30, 30, 30); v.TextColor3 = Color3.new(1,1,1); v.Font = Enum.Font.Gotham; v.TextSize = 11; Instance.new("UICorner", v) end end end

-- 5. FUNCTIONALITY
local function SetStatus(btn, stat, isAim)
    btn.Text = stat and (isAim and "On (RMB)" or "On") or (isAim and "Off (RMB)" or "Off")
    btn.TextColor3 = stat and Color3.new(0, 1, 0.5) or Color3.new(1, 0.3, 0.3)
end

local function SetupPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if not getgenv().OriginalDurations[prompt] then getgenv().OriginalDurations[prompt] = prompt.HoldDuration end
    if Settings.FastInteract.Status then prompt.HoldDuration = 0.0001 end
end

Workspace.DescendantAdded:Connect(SetupPrompt)

-- KEYBIND SYSTEM
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Settings.Fly.Bind and (input.KeyCode == Settings.Fly.Bind or input.UserInputType == Settings.Fly.Bind) then
        Settings.Fly.Status = not Settings.Fly.Status; SetStatus(fBnd, Settings.Fly.Status)
    end
    if input.KeyCode == Settings.HideGui.Bind then
        Settings.HideGui.Status = not Settings.HideGui.Status; Outer.Visible = Settings.HideGui.Status
    end
end)

-- CLICK LISTENERS
fBnd.MouseButton1Click:Connect(function() fBnd.Text = "..."; local i = UserInputService.InputBegan:Wait(); Settings.Fly.Bind = (i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType); fBnd.Text = "[ " .. Settings.Fly.Bind.Name:gsub("MouseButton","MB") .. " ]" end)
sBnd.MouseButton1Click:Connect(function() sBnd.Text = "..."; local i = UserInputService.InputBegan:Wait(); Settings.Speed.Bind = (i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType); sBnd.Text = "[ " .. Settings.Speed.Bind.Name:gsub("MouseButton","MB") .. " ]" end)
hBnd.MouseButton1Click:Connect(function() hBnd.Text = "..."; local i = UserInputService.InputBegan:Wait(); if i.KeyCode ~= Enum.KeyCode.Unknown then Settings.HideGui.Bind = i.KeyCode; hBnd.Text = "[ " .. i.KeyCode.Name .. " ]" end end)
jTgl.MouseButton1Click:Connect(function() Settings.InfJump.Status = not Settings.InfJump.Status; SetStatus(jTgl, Settings.InfJump.Status) end)
eTgl.MouseButton1Click:Connect(function() Settings.ESP.Status = not Settings.ESP.Status; SetStatus(eTgl, Settings.ESP.Status) end)
aTgl.MouseButton1Click:Connect(function() Settings.Aimlock.Status = not Settings.Aimlock.Status; SetStatus(aTgl, Settings.Aimlock.Status, true); FOV.Visible = Settings.Aimlock.Status end)
bTgl.MouseButton1Click:Connect(function() Settings.Fullbright.Status = not Settings.Fullbright.Status; SetStatus(bTgl, Settings.Fullbright.Status) end)
nTgl.MouseButton1Click:Connect(function() Settings.NoFog.Status = not Settings.NoFog.Status; SetStatus(nTgl, Settings.NoFog.Status) end)
iTgl.MouseButton1Click:Connect(function() Settings.FastInteract.Status = not Settings.FastInteract.Status; SetStatus(iTgl, Settings.FastInteract.Status); for _,v in pairs(Workspace:GetDescendants()) do SetupPrompt(v) end end)

-- 6. FAIL-SAFE MASTER LOOP
task.spawn(function()
    while not _G.KillMenu do
        pcall(function()
            Outer.BackgroundColor3 = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            local cam = Workspace.CurrentCamera; local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart")

            -- Fast Interact logic inside loop for reliability
            if Settings.FastInteract.Status then
                for prompt, _ in pairs(getgenv().OriginalDurations) do
                    if prompt and prompt.Parent then prompt.HoldDuration = 0.0001 end
                end
            end

            -- Environmental Check
            if Settings.Fullbright.Status then Lighting.Brightness = 2; Lighting.Ambient = Color3.new(1,1,1); Lighting.GlobalShadows = false
            elseif not Settings.NoFog.Status then Lighting.Brightness = getgenv().OriginalLighting.Brightness; Lighting.Ambient = getgenv().OriginalLighting.Ambient; Lighting.GlobalShadows = getgenv().OriginalLighting.GlobalShadows end
            Lighting.FogEnd = Settings.NoFog.Status and 1e5 or getgenv().OriginalLighting.FogEnd

            if hum and root then
                -- FLY RE-ENGINEERED
                if Settings.Fly.Status then
                    if not bv or bv.Parent ~= root then
                        if bv then bv:Destroy(); bg:Destroy() end
                        bv = Instance.new("BodyVelocity", root); bv.MaxForce = Vector3.new(1e6,1e6,1e6); bg = Instance.new("BodyGyro", root); bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
                    end
                    local fs = tonumber(fInp.Text) or 100
                    local moveDir = (UserInputService:IsKeyDown("W") and cam.CFrame.LookVector or Vector3.new()) + (UserInputService:IsKeyDown("S") and -cam.CFrame.LookVector or Vector3.new()) + (UserInputService:IsKeyDown("A") and -cam.CFrame.RightVector or Vector3.new()) + (UserInputService:IsKeyDown("D") and cam.CFrame.RightVector or Vector3.new())
                    local vert = UserInputService:IsKeyDown("Space") and 0.25 or (UserInputService:IsKeyDown("LeftShift") and -0.25 or 0)
                    bv.Velocity = (moveDir * fs) + Vector3.new(0, vert * fs, 0); bg.CFrame = cam.CFrame; hum.PlatformStand = true
                elseif bv then
                    bv:Destroy(); bg:Destroy(); bv = nil; hum.PlatformStand = false
                end

                -- Speed/Jump/Aimlock
                if Settings.Speed.Bind and UserInputService:IsKeyDown(Settings.Speed.Bind) then hum.WalkSpeed = tonumber(sInp.Text) or 100 else hum.WalkSpeed = 16 end
                if Settings.InfJump.Status and UserInputService:IsKeyDown(Enum.KeyCode.Space) then root.Velocity = Vector3.new(root.Velocity.X, tonumber(jInp.Text) or 50, root.Velocity.Z) end
                
                FOV.Radius = tonumber(aInp.Text) or 100; FOV.Position = UserInputService:GetMouseLocation()
                if Settings.Aimlock.Status and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    if not LockedTarget or not LockedTarget.Parent or LockedTarget.Parent.Humanoid.Health <= 0 then
                        local target, dist = nil, FOV.Radius
                        for _, v in pairs(Players:GetPlayers()) do
                            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
                                local pos, vis = cam:WorldToViewportPoint(v.Character.Head.Position)
                                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                                if vis and mag < dist then dist = mag; target = v.Character.Head end
                            end
                        end; LockedTarget = target
                    end
                    if LockedTarget then cam.CFrame = CFrame.new(cam.CFrame.Position, LockedTarget.Position) end
                else LockedTarget = nil end
            end

            -- ESP
            if Settings.ESP.Status then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local h = p.Character:FindFirstChild("ESPHighlight") or Instance.new("Highlight", p.Character)
                        h.Name = "ESPHighlight"; h.FillTransparency = 0.5; h.FillColor = Color3.new(1,0,0)
                    end
                end
            else
                for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end end
            end
        end)
        task.wait()
    end
end)
