local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GUI_NAME = "CleanUnifiedMenu"
local LP = Players.LocalPlayer

-- ==========================================
-- 1. SAFE EXECUTION
-- ==========================================
local function Cleanup()
    local existing = CoreGui:FindFirstChild(GUI_NAME) or LP:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
    if existing then existing:Destroy() end
end
Cleanup()

-- ==========================================
-- 2. UI INITIALIZATION (WIDER FRAME)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LP.PlayerGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 330) -- WIDENED TO 500
mainFrame.Position = UDim2.new(0.5, -250, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, -30, 0, 30); title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1; title.Text = "Advanced Cheat Menu"; title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left; title.Font = Enum.Font.Code; title.TextSize = 16

local terminateBtn = Instance.new("TextButton", mainFrame)
terminateBtn.Size = UDim2.new(0, 30, 0, 30); terminateBtn.Position = UDim2.new(1, -30, 0, 0)
terminateBtn.BackgroundTransparency = 1; terminateBtn.Text = "x"; terminateBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
terminateBtn.TextSize = 20

local function CreateRow(text, yPos)
    local row = Instance.new("Frame", mainFrame)
    row.Size = UDim2.new(1, -20, 0, 30); row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0, 140, 1, 0) -- INCREASED LABEL WIDTH FOR LONG NAMES
    label.Text = "" .. text .. ""
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 14
    
    return row
end

-- ==========================================
-- 3. INTERFACE ROWS (ADJUSTED FOR WIDTH)
-- ==========================================
local speedRow = CreateRow("👟 Speed", 40)
local speedInput = Instance.new("TextBox", speedRow); speedInput.Size = UDim2.new(0, 50, 0, 25); speedInput.Position = UDim2.new(0, 150, 0, 2); speedInput.Text = "100"; speedInput.BackgroundColor3 = Color3.fromRGB(40,40,40); speedInput.TextColor3 = Color3.fromRGB(0,255,0)
local speedBindBtn = Instance.new("TextButton", speedRow); speedBindBtn.Size = UDim2.new(0, 80, 0, 25); speedBindBtn.Position = UDim2.new(0, 205, 0, 2); speedBindBtn.Text = "[ Bind ]"; speedBindBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); speedBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
local speedStateBtn = Instance.new("TextButton", speedRow); speedStateBtn.Size = UDim2.new(1, -290, 0, 25); speedStateBtn.Position = UDim2.new(0, 290, 0, 2); speedStateBtn.Text = "State: Hold"; speedStateBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); speedStateBtn.TextColor3 = Color3.fromRGB(255,255,255)

local jumpRow = CreateRow("🦘 Inf Jump", 75)
local jumpToggleBtn = Instance.new("TextButton", jumpRow); jumpToggleBtn.Size = UDim2.new(1, -150, 0, 25); jumpToggleBtn.Position = UDim2.new(0, 150, 0, 2); jumpToggleBtn.Text = "Off"; jumpToggleBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); jumpToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

local noclipRow = CreateRow("🧱 No Clip", 110)
local noclipBindBtn = Instance.new("TextButton", noclipRow); noclipBindBtn.Size = UDim2.new(0, 80, 0, 25); noclipBindBtn.Position = UDim2.new(0, 150, 0, 2); noclipBindBtn.Text = "[ V ]"; noclipBindBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); noclipBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
local noclipStateBtn = Instance.new("TextButton", noclipRow); noclipStateBtn.Size = UDim2.new(1, -235, 0, 25); noclipStateBtn.Position = UDim2.new(0, 235, 0, 2); noclipStateBtn.Text = "Off"; noclipStateBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); noclipStateBtn.TextColor3 = Color3.fromRGB(255,255,255)

local flyRow = CreateRow("🦅 Fly", 145)
local flyInput = Instance.new("TextBox", flyRow); flyInput.Size = UDim2.new(0, 50, 0, 25); flyInput.Position = UDim2.new(0, 150, 0, 2); flyInput.Text = "100"; flyInput.BackgroundColor3 = Color3.fromRGB(40,40,40); flyInput.TextColor3 = Color3.fromRGB(0,255,0)
local flyBindBtn = Instance.new("TextButton", flyRow); flyBindBtn.Size = UDim2.new(0, 80, 0, 25); flyBindBtn.Position = UDim2.new(0, 205, 0, 2); flyBindBtn.Text = "[ Bind ]"; flyBindBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); flyBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
local flyToggleBtn = Instance.new("TextButton", flyRow); flyToggleBtn.Size = UDim2.new(1, -290, 0, 25); flyToggleBtn.Position = UDim2.new(0, 290, 0, 2); flyToggleBtn.Text = "Off"; flyToggleBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); flyToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

local hideRow = CreateRow("🚫 Hide Interface", 180)
local hideBindBtn = Instance.new("TextButton", hideRow); hideBindBtn.Size = UDim2.new(1, -150, 0, 25); hideBindBtn.Position = UDim2.new(0, 150, 0, 2); hideBindBtn.Text = "[ Insert ]"; hideBindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); hideBindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)

local fbRow = CreateRow("👁️ Fullbright ", 215)
local fbToggleBtn = Instance.new("TextButton", fbRow); fbToggleBtn.Size = UDim2.new(1, -150, 0, 25); fbToggleBtn.Position = UDim2.new(0, 150, 0, 2); fbToggleBtn.Text = "Off"; fbToggleBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); fbToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

local fogRow = CreateRow("🔭 No Fog", 250)
local fogToggleBtn = Instance.new("TextButton", fogRow); fogToggleBtn.Size = UDim2.new(1, -150, 0, 25); fogToggleBtn.Position = UDim2.new(0, 150, 0, 2); fogToggleBtn.Text = "Off"; fogToggleBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); fogToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

local interactRow = CreateRow("⏩ Fast Interact", 285)
local interactToggleBtn = Instance.new("TextButton", interactRow); interactToggleBtn.Size = UDim2.new(1, -150, 0, 25); interactToggleBtn.Position = UDim2.new(0, 150, 0, 2); interactToggleBtn.Text = "Off"; interactToggleBtn.BackgroundColor3 = Color3.fromRGB(150,0,0); interactToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

-- ==========================================
-- 4. LOGIC & STATE
-- ==========================================
local Binds = { Speed = nil, Noclip = Enum.KeyCode.V, Fly = nil, Hide = Enum.KeyCode.Insert }
local Waiting = { Speed = false, Noclip = false, Fly = false, Hide = false }
local Active = { Speed = false, Jump = false, Noclip = false, Fly = false, Visible = true, Fullbright = false, NoFog = false, FastInteract = false }
local SpeedMode = "Hold"
local originalHold = {}
local bv, bg

local OrigLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

-- Fast Interact Logic
local function ApplyInteract(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if Active.FastInteract then
        if originalHold[prompt] == nil then originalHold[prompt] = prompt.HoldDuration end
        prompt.HoldDuration = 0.0001
    else
        if originalHold[prompt] ~= nil then prompt.HoldDuration = originalHold[prompt] end
    end
end

workspace.DescendantAdded:Connect(function(v)
    task.wait()
    ApplyInteract(v)
end)

-- Lighting Toggle Logic
local function UpdateLighting()
    if Active.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    elseif Active.NoFog then
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = OrigLighting.Brightness
        Lighting.ClockTime = OrigLighting.ClockTime
        Lighting.FogEnd = OrigLighting.FogEnd
        Lighting.GlobalShadows = OrigLighting.GlobalShadows
        Lighting.Ambient = OrigLighting.Ambient
    end
end

local function GetInputObject(input) return (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode or input.UserInputType end
local function GetInputName(input) local obj = GetInputObject(input) return (input.UserInputType == Enum.UserInputType.Keyboard) and obj.Name or input.UserInputType.Name end

local function ToggleFly()
    Active.Fly = not Active.Fly
    flyToggleBtn.Text = Active.Fly and "On" or "Off"
    flyToggleBtn.BackgroundColor3 = Active.Fly and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if Active.Fly and root then
        bv = Instance.new("BodyVelocity", root); bv.MaxForce = Vector3.new(1e5, 1e5, 1e5); bv.Velocity = Vector3.new(0,0,0)
        bg = Instance.new("BodyGyro", root); bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5); bg.CFrame = root.CFrame
    else
        if bv then bv:Destroy() end if bg then bg:Destroy() end
    end
end

-- ==========================================
-- 5. RUN LOOPS
-- ==========================================
RunService.RenderStepped:Connect(function()
    if Active.Fly then
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if root and bv and bg then
            local speedValue = tonumber(flyInput.Text) or 100
            local verticalSpeed = speedValue * 0.25
            
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            
            local yDir = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then yDir = yDir + verticalSpeed end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then yDir = yDir - verticalSpeed end
            
            bv.Velocity = (dir * speedValue) + Vector3.new(0, yDir, 0)
            bg.CFrame = cam.CFrame
        end
    end
    if Active.Fullbright or Active.NoFog then UpdateLighting() end
end)

RunService.Stepped:Connect(function()
    if Active.Noclip and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

task.spawn(function()
    while task.wait() do
        if not screenGui.Parent then break end
        speedStateBtn.BackgroundColor3 = Active.Speed and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Active.Speed and (tonumber(speedInput.Text) or 16) or 16 end
    end
end)

-- ==========================================
-- 6. EVENT LISTENERS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gpe)
    local obj = GetInputObject(input)
    if Waiting.Speed then Binds.Speed = obj; speedBindBtn.Text = "["..GetInputName(input).."]"; Waiting.Speed = false return end
    if Waiting.Noclip then Binds.Noclip = obj; noclipBindBtn.Text = "["..GetInputName(input).."]"; Waiting.Noclip = false return end
    if Waiting.Fly then Binds.Fly = obj; flyBindBtn.Text = "["..GetInputName(input).."]"; Waiting.Fly = false return end
    if Waiting.Hide then Binds.Hide = obj; hideBindBtn.Text = "["..GetInputName(input).."]"; Waiting.Hide = false return end

    if gpe then return end
    if Binds.Speed and obj == Binds.Speed then if SpeedMode == "Toggle" then Active.Speed = not Active.Speed else Active.Speed = true end end
    if Binds.Noclip and obj == Binds.Noclip then Active.Noclip = not Active.Noclip; noclipStateBtn.Text = Active.Noclip and "On" or "Off"; noclipStateBtn.BackgroundColor3 = Active.Noclip and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0) end
    if Binds.Fly and obj == Binds.Fly then ToggleFly() end
    if Binds.Hide and obj == Binds.Hide then Active.Visible = not Active.Visible; mainFrame.Visible = Active.Visible end
end)

UserInputService.InputEnded:Connect(function(input)
    local obj = GetInputObject(input)
    if Binds.Speed and obj == Binds.Speed and SpeedMode == "Hold" then Active.Speed = false end
end)

-- Button Binds
fbToggleBtn.MouseButton1Click:Connect(function() 
    Active.Fullbright = not Active.Fullbright
    fbToggleBtn.Text = Active.Fullbright and "On" or "Off"
    fbToggleBtn.BackgroundColor3 = Active.Fullbright and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    UpdateLighting()
end)

fogToggleBtn.MouseButton1Click:Connect(function() 
    Active.NoFog = not Active.NoFog
    fogToggleBtn.Text = Active.NoFog and "On" or "Off"
    fogToggleBtn.BackgroundColor3 = Active.NoFog and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    UpdateLighting()
end)

interactToggleBtn.MouseButton1Click:Connect(function() 
    Active.FastInteract = not Active.FastInteract
    interactToggleBtn.Text = Active.FastInteract and "On" or "Off"
    interactToggleBtn.BackgroundColor3 = Active.FastInteract and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    for _, v in ipairs(workspace:GetDescendants()) do ApplyInteract(v) end
end)

speedBindBtn.MouseButton1Click:Connect(function() Waiting.Speed = true; speedBindBtn.Text = "..." end)
noclipBindBtn.MouseButton1Click:Connect(function() Waiting.Noclip = true; noclipBindBtn.Text = "..." end)
flyBindBtn.MouseButton1Click:Connect(function() Waiting.Fly = true; flyBindBtn.Text = "..." end)
hideBindBtn.MouseButton1Click:Connect(function() Waiting.Hide = true; hideBindBtn.Text = "..." end)
speedStateBtn.MouseButton1Click:Connect(function() SpeedMode = (SpeedMode == "Hold") and "Toggle" or "Hold"; speedStateBtn.Text = "State: "..SpeedMode; Active.Speed = false end)
jumpToggleBtn.MouseButton1Click:Connect(function() Active.Jump = not Active.Jump; jumpToggleBtn.Text = Active.Jump and "On" or "Off"; jumpToggleBtn.BackgroundColor3 = Active.Jump and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0) end)
noclipStateBtn.MouseButton1Click:Connect(function() Active.Noclip = not Active.Noclip; noclipStateBtn.Text = Active.Noclip and "On" or "Off"; noclipStateBtn.BackgroundColor3 = Active.Noclip and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0) end)
flyToggleBtn.MouseButton1Click:Connect(ToggleFly)
terminateBtn.MouseButton1Click:Connect(function() Cleanup() if LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.WalkSpeed = 16 end end)

UserInputService.JumpRequest:Connect(function()
    if Active.Jump then local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState("Jumping") end end
end)
