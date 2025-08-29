-- Speed Lock GUI with Custom Keybinds (Hold / Toggle / GUI), PC + Mobile draggable

-- Cleanup on re-execution
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
local player = game.Players.LocalPlayer
local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

local humanoid = getHumanoid()
local normalSpeed = humanoid.WalkSpeed
local boostSpeed = 100

-- Default binds
local holdKey = Enum.KeyCode.LeftShift
local toggleKey = Enum.KeyCode.T
local guiKey = Enum.KeyCode.Insert
local waitingForBind = nil
local toggleMode = false

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedLockGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 220)
Frame.Position = UDim2.new(0.4, 0, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.Active = true
Frame.Draggable = false -- we’ll handle dragging
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0,12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Speed Lock"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

-- Speed Box
local Box = Instance.new("TextBox")
Box.Size = UDim2.new(0.8,0,0,30)
Box.Position = UDim2.new(0.1,0,0.2,0)
Box.BackgroundColor3 = Color3.fromRGB(40,40,40)
Box.TextColor3 = Color3.fromRGB(255,255,255)
Box.Text = tostring(boostSpeed)
Box.PlaceholderText = "Enter Speed"
Box.Font = Enum.Font.SourceSans
Box.TextSize = 16
Box.Parent = Frame
local UICorner2 = Instance.new("UICorner", Box)
UICorner2.CornerRadius = UDim.new(0,8)

-- Hold Key Button
local HoldBindBtn = Instance.new("TextButton")
HoldBindBtn.Size = UDim2.new(0.8,0,0,30)
HoldBindBtn.Position = UDim2.new(0.1,0,0.4,0)
HoldBindBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
HoldBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
HoldBindBtn.Text = "Hold Key: "..holdKey.Name
HoldBindBtn.Font = Enum.Font.SourceSans
HoldBindBtn.TextSize = 16
HoldBindBtn.Parent = Frame
local UICorner3 = Instance.new("UICorner", HoldBindBtn)
UICorner3.CornerRadius = UDim.new(0,8)

-- Toggle Key Button
local ToggleBindBtn = Instance.new("TextButton")
ToggleBindBtn.Size = UDim2.new(0.8,0,0,30)
ToggleBindBtn.Position = UDim2.new(0.1,0,0.6,0)
ToggleBindBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
ToggleBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBindBtn.Text = "Toggle Key: "..toggleKey.Name
ToggleBindBtn.Font = Enum.Font.SourceSans
ToggleBindBtn.TextSize = 16
ToggleBindBtn.Parent = Frame
local UICorner4 = Instance.new("UICorner", ToggleBindBtn)
UICorner4.CornerRadius = UDim.new(0,8)

-- GUI Key Button
local GuiBindBtn = Instance.new("TextButton")
GuiBindBtn.Size = UDim2.new(0.8,0,0,30)
GuiBindBtn.Position = UDim2.new(0.1,0,0.8,0)
GuiBindBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
GuiBindBtn.TextColor3 = Color3.fromRGB(255,255,255)
GuiBindBtn.Text = "GUI Key: "..guiKey.Name
GuiBindBtn.Font = Enum.Font.SourceSans
GuiBindBtn.TextSize = 16
GuiBindBtn.Parent = Frame
local UICorner5 = Instance.new("UICorner", GuiBindBtn)
UICorner5.CornerRadius = UDim.new(0,8)

-------------------------
-- Dragging (Mouse + Touch)
-------------------------
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-------------------------
-- Input logic
-------------------------
table.insert(_G.SpeedLockConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- Rebinding
    if waitingForBind and input.UserInputType == Enum.UserInputType.Keyboard then
        if waitingForBind == "hold" then
            holdKey = input.KeyCode
            HoldBindBtn.Text = "Hold Key: "..holdKey.Name
        elseif waitingForBind == "toggle" then
            toggleKey = input.KeyCode
            ToggleBindBtn.Text = "Toggle Key: "..toggleKey.Name
        elseif waitingForBind == "gui" then
            guiKey = input.KeyCode
            GuiBindBtn.Text = "GUI Key: "..guiKey.Name
        end
        waitingForBind = nil
        return
    end

    -- Normal input
    if input.KeyCode == holdKey then
        humanoid.WalkSpeed = boostSpeed
    elseif input.KeyCode == toggleKey then
        toggleMode = not toggleMode
        humanoid.WalkSpeed = toggleMode and boostSpeed or normalSpeed
    elseif input.KeyCode == guiKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end))

table.insert(_G.SpeedLockConnections, UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == holdKey and not toggleMode then
        humanoid.WalkSpeed = normalSpeed
    end
end))

-- Speed Box
Box.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(Box.Text)
        if val then
            boostSpeed = val
        else
            Box.Text = tostring(boostSpeed)
        end
    end
end)

-- Buttons
HoldBindBtn.MouseButton1Click:Connect(function()
    HoldBindBtn.Text = "Press any key..."
    waitingForBind = "hold"
end)

ToggleBindBtn.MouseButton1Click:Connect(function()
    ToggleBindBtn.Text = "Press any key..."
    waitingForBind = "toggle"
end)

GuiBindBtn.MouseButton1Click:Connect(function()
    GuiBindBtn.Text = "Press any key..."
    waitingForBind = "gui"
end)

-- Respawn support
player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid")
    normalSpeed = humanoid.WalkSpeed
end)
