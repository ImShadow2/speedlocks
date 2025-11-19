-- Player and GUI setup
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DynamicOpacityGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Table to keep track of modified parts per row
local modifiedParts = {}

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 50) -- will grow dynamically
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Make the GUI draggable
mainFrame.Active = true
mainFrame.Draggable = true

-- UIListLayout for dynamic rows
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,5)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = mainFrame

-- + Button
local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(1, -10, 0, 30)
addButton.Position = UDim2.new(0, 5, 0, 5)
addButton.Text = "+"
addButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
addButton.TextColor3 = Color3.fromRGB(255,255,255)
addButton.Parent = mainFrame

-- Close/terminate button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(170,0,0)
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
closeButton.Parent = mainFrame

-- Function to reset all modified parts
local function resetAllParts()
    for part, _ in pairs(modifiedParts) do
        if part and part.Parent then
            part.Transparency = 0
        end
    end
    modifiedParts = {}
end

closeButton.MouseButton1Click:Connect(function()
    resetAllParts()
    screenGui:Destroy()
end)

-- Keybind input
local keybindBox = Instance.new("TextBox")
keybindBox.Size = UDim2.new(0, 100, 0, 30)
keybindBox.Position = UDim2.new(0, 10, 0, 40)
keybindBox.PlaceholderText = "Press new key"
keybindBox.BackgroundColor3 = Color3.fromRGB(70,70,70)
keybindBox.TextColor3 = Color3.fromRGB(255,255,255)
keybindBox.ClearTextOnFocus = true
keybindBox.Parent = mainFrame


-- Function to add a new row
local function addRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(50,50,50)
    row.BorderSizePixel = 0
    row.Parent = mainFrame

    -- Part name input
    local partNameInput = Instance.new("TextBox")
    partNameInput.Size = UDim2.new(0.4, -5, 1, 0)
    partNameInput.Position = UDim2.new(0, 5, 0, 0)
    partNameInput.PlaceholderText = "Part Name"
    partNameInput.BackgroundColor3 = Color3.fromRGB(70,70,70)
    partNameInput.TextColor3 = Color3.fromRGB(255,255,255)
    partNameInput.Parent = row

    -- Opacity input (0-10, 10=1)
    local opacityInput = Instance.new("TextBox")
    opacityInput.Size = UDim2.new(0.2, -5, 1, 0)
    opacityInput.Position = UDim2.new(0.4, 5, 0, 0)
    opacityInput.PlaceholderText = "0-10"
    opacityInput.BackgroundColor3 = Color3.fromRGB(70,70,70)
    opacityInput.TextColor3 = Color3.fromRGB(255,255,255)
    opacityInput.Parent = row

    -- Apply button
    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.2, -5, 1, 0)
    applyBtn.Position = UDim2.new(0.6, 5, 0, 0)
    applyBtn.Text = "Apply"
    applyBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
    applyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    applyBtn.Parent = row

    applyBtn.MouseButton1Click:Connect(function()
        local name = partNameInput.Text
        local value = tonumber(opacityInput.Text)
        if not value or value < 0 then value = 0 end
        if value > 10 then value = 10 end
        local transparency = value/10
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name:lower() == name:lower() then
                part.Transparency = transparency
                modifiedParts[part] = true -- track modified parts
            end
        end
    end)

    -- Delete button
    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Size = UDim2.new(0.2, -5, 1, 0)
    deleteBtn.Position = UDim2.new(0.8, 5, 0, 0)
    deleteBtn.Text = "Delete"
    deleteBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
    deleteBtn.TextColor3 = Color3.fromRGB(255,255,255)
    deleteBtn.Parent = row

    deleteBtn.MouseButton1Click:Connect(function()
        -- Reset parts for this row
        local name = partNameInput.Text
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.Name:lower() == name:lower() then
                part.Transparency = 0
                modifiedParts[part] = nil
            end
        end
        -- Remove row
        row:Destroy()
    end)
end

-- Keybind system
local toggleKey = Enum.KeyCode.F5  -- default toggle key

-- Function to toggle GUI visibility
local function toggleGUI()
    if screenGui.Enabled == nil then
        screenGui.Enabled = true
    else
        screenGui.Enabled = not screenGui.Enabled
    end
end

-- Listen to key presses
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == toggleKey then
            toggleGUI()
        end
    end
end)

-- Change keybind when TextBox focused
keybindBox.Focused:Connect(function()
    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            toggleKey = input.KeyCode
            keybindBox.Text = "Key: "..tostring(toggleKey):gsub("Enum.KeyCode.", "")
            connection:Disconnect()
            keybindBox:ReleaseFocus()
        end
    end)
end)

-- Connect + button
addButton.MouseButton1Click:Connect(addRow)
