-- Dynamic Speed Lock GUI | Infinite Jump, Noclip, Teleport Tool, Fly

-- Cleanup on re-execution
-- FULL CLEANUP ON RE-EXECUTION
if _G.SpeedLockCleanup then
    _G.SpeedLockCleanup()
end

_G.SpeedLockCleanup = function()
    -- Remove GUI
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        if gui.Name == "SpeedLockGUI" then
            gui:Destroy()
        end
    end

    -- Disconnect old connections
    if _G.SpeedLockConnections then
        for _, c in ipairs(_G.SpeedLockConnections) do
            pcall(function() c:Disconnect() end)
        end
    end
    _G.SpeedLockConnections = {}

    -- Reset speed
    local plr = game.Players.LocalPlayer
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid.WalkSpeed = 16
        plr.Character.Humanoid.JumpPower = 50
    end

    -- Remove noclip
    if plr.Character then
        for _, part in ipairs(plr.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    -- Remove fly forces
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        if hrp:FindFirstChild("BodyVelocity") then hrp.BodyVelocity:Destroy() end
        if hrp:FindFirstChild("BodyGyro") then hrp.BodyGyro:Destroy() end
    end

    -- Reset globals
    _G.SpeedLockFlying = false
    _G.SpeedLockNoclip = false
    _G.SpeedLockToggle = false
    _G.SpeedLockHold = false
end

-- Run cleanup now if script is re-executed
_G.SpeedLockCleanup()


for _, gui in ipairs(game.CoreGui:GetChildren()) do
    if gui.Name == "SpeedLockGUI" then gui:Destroy() end
end
if _G.SpeedLockConnections then
    for _, c in ipairs(_G.SpeedLockConnections) do
        pcall(function() c:Disconnect() end)
    end
end
_G.SpeedLockConnections = {}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

-- Utility to get humanoid
local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

local humanoid = getHumanoid()
local normalSpeed = humanoid.WalkSpeed
local boostSpeed = 100
local infJumpEnabled = false
local noclip = false
local flying = false
local flySpeed = 50

-- Default key binds
local defaultKeys = {
    holdKey = Enum.KeyCode.LeftShift,
    toggleKey = Enum.KeyCode.T,
    guiKey = Enum.KeyCode.Insert,
    noclipKey = Enum.KeyCode.V,
    flyKey = Enum.KeyCode.B,
}

local waitingForBind = nil
local waitingForBindNoclip = false
local waitingForBindFly = false
local toggleMode = false

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedLockGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Position = UDim2.new(0.4,0,0.4,0)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0,12)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Speed Lock"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

-- UIListLayout for auto stacking
local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Frame

-- Button definitions table
local buttons = {
    {name="Speed", type="input", value=boostSpeed},
    {name="Hold Key", type="bind", key=defaultKeys.holdKey},
    {name="Toggle Key", type="bind", key=defaultKeys.toggleKey},
    {name="GUI Key", type="bind", key=defaultKeys.guiKey},
    {name="Infinite Jump", type="toggle", value=false},
    {name="Noclip", type="toggle", value=false, key=defaultKeys.noclipKey},
    {name="Teleport Tool", type="action"},
    {name="Fly Speed", type="input", value=flySpeed},
    {name="Fly", type="toggle", value=false, key=defaultKeys.flyKey},
}

-- Create buttons dynamically
local buttonHeight = 30
local buttonInstances = {}

for i, btn in ipairs(buttons) do
    if btn.type == "input" then
        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1,-20,0,buttonHeight)
        Box.BackgroundColor3 = Color3.fromRGB(40,40,40)
        Box.TextColor3 = Color3.fromRGB(255,255,255)
        Box.Text = tostring(btn.value)
        Box.PlaceholderText = btn.name
        Box.Font = Enum.Font.SourceSans
        Box.TextSize = 16
        Box.LayoutOrder = i
        Box.Parent = Frame
        local UICornerBtn = Instance.new("UICorner", Box)
        UICornerBtn.CornerRadius = UDim.new(0,8)
        buttonInstances[btn.name] = Box
    else
        local TextButton = Instance.new("TextButton")
        TextButton.Size = UDim2.new(1,-20,0,buttonHeight)
        TextButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
        TextButton.TextColor3 = Color3.fromRGB(255,255,255)
        TextButton.Font = Enum.Font.SourceSans
        TextButton.TextSize = 16
        TextButton.LayoutOrder = i
        TextButton.Parent = Frame
        local UICornerBtn = Instance.new("UICorner", TextButton)
        UICornerBtn.CornerRadius = UDim.new(0,8)

        if btn.type == "bind" then
            TextButton.Text = btn.name..": "..btn.key.Name
        elseif btn.type == "toggle" then
            TextButton.Text = btn.name..": "..(btn.value and "ON" or "OFF")
        elseif btn.type == "action" then
            TextButton.Text = btn.name
        end
        buttonInstances[btn.name] = TextButton
    end
end

-- Resize frame dynamically based on content
Frame.Size = UDim2.new(0, 260, 0, UIList.AbsoluteContentSize.Y + 20)
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Frame.Size = UDim2.new(0, 260, 0, UIList.AbsoluteContentSize.Y + 20)
end)

-- Button callbacks
buttonInstances["Infinite Jump"].MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    buttonInstances["Infinite Jump"].Text = "Infinite Jump: "..(infJumpEnabled and "ON" or "OFF")
end)

buttonInstances["Noclip"].MouseButton1Click:Connect(function()
    waitingForBindNoclip = true
    buttonInstances["Noclip"].Text = "Noclip: Press any key..."
end)

buttonInstances["Teleport Tool"].MouseButton1Click:Connect(function()
    local Backpack = player:WaitForChild("Backpack")
    if Backpack:FindFirstChild("Teleport") then return end
    local tool = Instance.new("Tool")
    tool.Name = "Teleport"
    tool.RequiresHandle = false
    tool.Parent = Backpack
    tool.Activated:Connect(function()
        local mouse = player:GetMouse()
        local char = player.Character
        if char then char:MoveTo(mouse.Hit.Position) end
    end)
end)

buttonInstances["Fly"].MouseButton1Click:Connect(function()
    flying = not flying
    buttonInstances["Fly"].Text = "Fly: "..(flying and "ON" or "OFF")
end)

-- Rebind key buttons
for _, keyBtn in ipairs({"Hold Key", "Toggle Key", "GUI Key", "Fly"}) do
    if buttonInstances[keyBtn] then
        buttonInstances[keyBtn].MouseButton1Click:Connect(function()
            buttonInstances[keyBtn].Text = "Press any key..."
            if keyBtn == "Fly" then
                waitingForBindFly = true
            else
                waitingForBind = keyBtn
            end
        end)
    end
end

-- Input handling
table.insert(_G.SpeedLockConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- Key rebinding
    if waitingForBind and input.UserInputType == Enum.UserInputType.Keyboard then
        if waitingForBind == "Hold Key" then defaultKeys.holdKey = input.KeyCode
        elseif waitingForBind == "Toggle Key" then defaultKeys.toggleKey = input.KeyCode
        elseif waitingForBind == "GUI Key" then defaultKeys.guiKey = input.KeyCode
        end
        buttonInstances[waitingForBind].Text = waitingForBind..": "..input.KeyCode.Name
        waitingForBind = nil
        return
    end
    if waitingForBindNoclip and input.UserInputType == Enum.UserInputType.Keyboard then
        defaultKeys.noclipKey = input.KeyCode
        waitingForBindNoclip = false
        buttonInstances["Noclip"].Text = "Noclip: "..input.KeyCode.Name.." "..(noclip and "ON" or "OFF")
        return
    end
    if waitingForBindFly and input.UserInputType == Enum.UserInputType.Keyboard then
        defaultKeys.flyKey = input.KeyCode
        waitingForBindFly = false
        buttonInstances["Fly"].Text = "Fly: "..input.KeyCode.Name.." "..(flying and "ON" or "OFF")
        return
    end

    -- Key actions
    if input.KeyCode == defaultKeys.holdKey then
        humanoid.WalkSpeed = tonumber(buttonInstances["Speed"].Text) or boostSpeed
    elseif input.KeyCode == defaultKeys.toggleKey then
        toggleMode = not toggleMode
        humanoid.WalkSpeed = toggleMode and (tonumber(buttonInstances["Speed"].Text) or boostSpeed) or normalSpeed
    elseif input.KeyCode == defaultKeys.guiKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    elseif input.KeyCode == defaultKeys.noclipKey then
        noclip = not noclip
        buttonInstances["Noclip"].Text = "Noclip: "..defaultKeys.noclipKey.Name.." "..(noclip and "ON" or "OFF")
    elseif input.KeyCode == defaultKeys.flyKey then
        flying = not flying
        buttonInstances["Fly"].Text = "Fly: "..(flying and "ON" or "OFF")
    end
end))

table.insert(_G.SpeedLockConnections, UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == defaultKeys.holdKey and not toggleMode then
        humanoid.WalkSpeed = normalSpeed
    end
end))

-- Infinite jump logic
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip logic
table.insert(_G.SpeedLockConnections, RunService.Stepped:Connect(function()
    if noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

-- Fly logic
local bv, bg
table.insert(_G.SpeedLockConnections, RunService.RenderStepped:Connect(function()
    if flying and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                bv.Velocity = Vector3.new(0,0,0)
                bv.Parent = hrp

                bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
                bg.CFrame = hrp.CFrame
                bg.Parent = hrp
            end

            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0,-1,0) end

            local speedVal = tonumber(buttonInstances["Fly Speed"].Text) or flySpeed
            bv.Velocity = (cam.CFrame.LookVector*moveDir.Z + cam.CFrame.RightVector*moveDir.X + Vector3.new(0,moveDir.Y,0)) * speedVal
            bg.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
        end
    else
        if bv then bv:Destroy(); bv=nil end
        if bg then bg:Destroy(); bg=nil end
    end
end))

-- Respawn support
player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid")
    normalSpeed = humanoid.WalkSpeed
end)

-- Fly Speed input logic
buttonInstances["Fly Speed"].FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(buttonInstances["Fly Speed"].Text)
        if val then flySpeed = val else buttonInstances["Fly Speed"].Text = tostring(flySpeed) end
    end
end)

-- Speed input logic
buttonInstances["Speed"].FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(buttonInstances["Speed"].Text)
        if val then boostSpeed = val else buttonInstances["Speed"].Text = tostring(boostSpeed) end
    end
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,30)
CloseBtn.Position = UDim2.new(1,-35,0,5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 18
CloseBtn.Parent = Frame
local UICornerClose = Instance.new("UICorner", CloseBtn)
UICornerClose.CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(_G.SpeedLockConnections) do
        pcall(function() c:Disconnect() end)
    end
    _G.SpeedLockConnections = {}
    ScreenGui:Destroy()
end)
