--// Location Part TP with Position Saving
--// GUI Toggle Default = RightShift
--// Default TP Keybind = "T"

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Cleanup
if game.CoreGui:FindFirstChild("LocationTPGui") then
    game.CoreGui.LocationTPGui:Destroy()
end
if _G.LocationTPConnections then
    for _, c in ipairs(_G.LocationTPConnections) do
        pcall(function() c:Disconnect() end)
    end
end
_G.LocationTPConnections = {}

-- Vars
local savedPosition = nil
local tpKey = Enum.KeyCode.T
local guiKey = Enum.KeyCode.RightShift
local guiVisible = true

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LocationTPGui"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 160)
Frame.Position = UDim2.new(0.35, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- ✅ Custom Draggable (works for PC + Mobile)
local dragging, dragInput, dragStart, startPos
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
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "📍 Location TP"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

-- Info
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 30)
Info.Position = UDim2.new(0, 10, 0, 35)
Info.BackgroundTransparency = 1
Info.Text = "Click anywhere to save TP spot"
Info.Font = Enum.Font.Gotham
Info.TextSize = 14
Info.TextColor3 = Color3.fromRGB(200, 200, 200)
Info.TextWrapped = true
Info.Parent = Frame

-- TP Keybind Button
local KeybindButton = Instance.new("TextButton")
KeybindButton.Size = UDim2.new(1, -20, 0, 30)
KeybindButton.Position = UDim2.new(0, 10, 0, 75)
KeybindButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
KeybindButton.Text = "Change TP Keybind ("..tpKey.Name..")"
KeybindButton.Font = Enum.Font.Gotham
KeybindButton.TextSize = 14
KeybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindButton.Parent = Frame

-- GUI Toggle Keybind Button
local GuiKeyButton = Instance.new("TextButton")
GuiKeyButton.Size = UDim2.new(1, -20, 0, 30)
GuiKeyButton.Position = UDim2.new(0, 10, 0, 115)
GuiKeyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
GuiKeyButton.Text = "Change GUI Keybind ("..guiKey.Name..")"
GuiKeyButton.Font = Enum.Font.Gotham
GuiKeyButton.TextSize = 14
GuiKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GuiKeyButton.Parent = Frame

-- Keybind Change Logic
local changingTPKey, changingGuiKey = false, false

KeybindButton.MouseButton1Click:Connect(function()
    if not changingTPKey then
        changingTPKey = true
        KeybindButton.Text = "Press a key..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                tpKey = input.KeyCode
                KeybindButton.Text = "Change TP Keybind ("..tpKey.Name..")"
                changingTPKey = false
                conn:Disconnect()
            end
        end)
    end
end)

GuiKeyButton.MouseButton1Click:Connect(function()
    if not changingGuiKey then
        changingGuiKey = true
        GuiKeyButton.Text = "Press a key..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                guiKey = input.KeyCode
                GuiKeyButton.Text = "Change GUI Keybind ("..guiKey.Name..")"
                changingGuiKey = false
                conn:Disconnect()
            end
        end)
    end
end)

-- Mouse click save position
local clickConn
local function enableClickSave()
    if clickConn then clickConn:Disconnect() end
    clickConn = Mouse.Button1Down:Connect(function()
        local pos = Mouse.Hit.p
        savedPosition = pos
        Info.Text = "Saved position at: ("..math.floor(pos.X)..","..math.floor(pos.Y)..","..math.floor(pos.Z)..")"
    end)
end
local function disableClickSave()
    if clickConn then clickConn:Disconnect() end
end

enableClickSave()

-- Toggle GUI
_G.LocationTPConnections["gui"] = UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == guiKey then
        guiVisible = not guiVisible
        ScreenGui.Enabled = guiVisible
        if guiVisible then
            enableClickSave()
        else
            disableClickSave()
        end
    end
end)

-- Teleport with keybind
_G.LocationTPConnections["tp"] = UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == tpKey and not guiVisible and savedPosition then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char:MoveTo(savedPosition)
        end
    end
end)
