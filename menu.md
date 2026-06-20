-- GUI HUB WITH HIDE AND KEYBIND PROMPT
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

-- CLEANUP
if CoreGui:FindFirstChild("GUI_Hub") then
    CoreGui.GUI_Hub:Destroy()
end

-- DATA
local GUIs = {
    {name = "Infinite Yield", link = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
    {name = "Menu", link = "https://raw.githubusercontent.com/ImShadow2/speedlocks/main/speed.lua"},
    {name = "Bring Item", link = "https://raw.githubusercontent.com/ImShadow2/speedlocks/main/bringeritems.lua"},
    {name = "Universal", link = "https://raw.githubusercontent.com/ImShadow2/3-universal-gui/main/3universalgui.lua"},
    {name = "Part Esp", link = "https://raw.githubusercontent.com/ImShadow2/partesp/main/partespplustp.lua"},
    {name = "AimLock", link = "https://raw.githubusercontent.com/ImShadow2/speedlocks/refs/heads/main/aimlock.lua"},
    {name = "Dex Bring", link = "https://raw.githubusercontent.com/ImShadow2/speedlocks/refs/heads/main/dexter.lua"}
    }

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GUI_Hub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 260)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "GUI Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Parent = TitleBar

-- Buttons: End, Minimize, Close
local function createButton(text, position, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 25, 0, 25)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextScaled = true
    btn.Parent = TitleBar
    return btn
end

local EndButton = createButton("End", UDim2.new(1, -90, 0, 2), Color3.fromRGB(120, 120, 120))
local MinimizeButton = createButton("-", UDim2.new(1, -60, 0, 2), Color3.fromRGB(180, 180, 50))
local CloseButton = createButton("X", UDim2.new(1, -30, 0, 2), Color3.fromRGB(200, 50, 50))

-- Scrollable area
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -35)
ScrollFrame.Position = UDim2.new(0, 5, 0, 30)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- GUI buttons
for i, guiInfo in ipairs(GUIs) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Text = guiInfo.name
    Button.Parent = ScrollFrame

    Button.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(guiInfo.link))()
        end)
        if not success then
            warn("Failed to load "..guiInfo.name..": "..err)
        end
    end)
end

-- Auto-adjust scroll size
local function updateCanvasSize()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
end
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
updateCanvasSize()

-- Minimize button
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 240, 0, 30)
    else
        MainFrame.Size = UDim2.new(0, 240, 0, 260)
    end
end)

-- Close button
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- End button (hide GUI + ask new keybind)
local keybind = Enum.KeyCode.RightShift -- default
local hidden = false

EndButton.MouseButton1Click:Connect(function()
    hidden = true
    ScreenGui.Enabled = false
    print("GUI hidden. Press a new key to toggle it.")

    -- Wait for new key press
    local connection
    connection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keybind = input.KeyCode
            print("New toggle key set to:", keybind.Name)
            ScreenGui.Enabled = true
            hidden = false
            connection:Disconnect()
        end
    end)
end)

-- Listen for toggle key
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == keybind then
        ScreenGui.Enabled = not ScreenGui.Enabled
        hidden = not ScreenGui.Enabled
    end
end)
