--// 🧩 Modern GUI Loader (Auto Button Version)
--// Features:
--// • Draggable, modern GUI
--// • RightShift toggle visibility
--// • Re-exec safe cleanup
--// • Auto button generation from table
--// • Smooth minimize + close

-- 🛑 Prevent stacking on re-execution
if getgenv().ModernGuiLoader and getgenv().ModernGuiLoader.Cleanup then
    pcall(getgenv().ModernGuiLoader.Cleanup)
    getgenv().ModernGuiLoader = nil
end

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Config
local TOGGLE_KEY = Enum.KeyCode.RightShift
local GUI_NAME = "ModernGuiLoader_v3"

--// Utility: Instance creator
local function new(cls, props)
    local obj = Instance.new(cls)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

--// ✨ Script Loader List (just edit this!)
local LOADERS = {
    {Name = "Infinite Yield", Description = "Load InfiniteYield admin script", URL = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
    {Name = "Speed", Description = "Load Speed script (if available)", URL = "https://raw.githubusercontent.com/ImShadow2/speedlocks/main/speed.lua"},
    {Name = "Universal", Description = "Load universal GUI script", URL = "https://raw.githubusercontent.com/ImShadow2/3-universal-gui/main/3universalgui.lua"},
    -- 🧩 Add new scripts below:
    -- {Name = "Fly", Description = "Toggle fly script", URL = "https://example.com/fly.lua"},
}

--// Create GUI
local screenGui = new("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
if syn and syn.protect_gui then pcall(syn.protect_gui, screenGui) end
screenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

--// Main frame
local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 200, 0, 330),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BorderSizePixel = 0
})
main.Parent = screenGui
new("UICorner", {CornerRadius = UDim.new(0, 14), Parent = main})

--// Top Bar
local topBar = new("Frame", {Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, Parent = main})
local title = new("TextLabel", {
    Size = UDim2.new(1,-96,1,0),
    Position = UDim2.new(0,16,0,0),
    BackgroundTransparency = 1,
    Text = "GUI Loader",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(240,240,240),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = topBar
})

local closeBtn = new("TextButton", {
    Size = UDim2.new(0,28,0,28),
    Position = UDim2.new(1,-40,0.5,-14),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(220,80,90),
    Parent = topBar
})
new("UICorner", {CornerRadius = UDim.new(0,8), Parent = closeBtn})

local minimizeBtn = new("TextButton", {
    Size = UDim2.new(0,28,0,28),
    Position = UDim2.new(1,-72,0.5,-14),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "—",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(200,200,200),
    Parent = topBar
})
new("UICorner", {CornerRadius = UDim.new(0,8), Parent = minimizeBtn})

--// Body
local body = new("Frame", {
    Size = UDim2.new(1,-32,1,-64),
    Position = UDim2.new(0,16,0,56),
    BackgroundTransparency = 1,
    Parent = main
})
local uiGrid = new("UIGridLayout", {
    Parent = body,
    CellSize = UDim2.new(0, 170, 0, 56),
    CellPadding = UDim2.new(0,12,0,12),
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    SortOrder = Enum.SortOrder.LayoutOrder
})

--// Safe Load Function
local function safeLoad(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not res then warn("❌ Failed to fetch:", url) return end
    local suc, err = pcall(function() loadstring(res)() end)
    if not suc then warn("⚠️ Exec error:", err) end
end

--// Button Maker
local function makeButton(text, desc, parent)
    local btn = new("TextButton", {
        Name = text:gsub("%s+",""),
        Size = UDim2.new(0,170,0,56),
        BackgroundColor3 = Color3.fromRGB(45,45,45),
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(230,230,230),
        AutoButtonColor = true,
        Parent = parent,
    })
    new("UICorner", {CornerRadius = UDim.new(0,10), Parent = btn})
    new("TextLabel", {
        Parent = btn,
        Size = UDim2.new(1,-12,0,18),
        Position = UDim2.new(0,8,1,-22),
        BackgroundTransparency = 1,
        Text = desc or "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(170,170,170),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return btn
end

--// Cleanup
local function Cleanup()
    if screenGui and screenGui.Parent then screenGui:Destroy() end
    if getgenv().ModernGuiLoader then getgenv().ModernGuiLoader = nil end
end
closeBtn.MouseButton1Click:Connect(Cleanup)

--// Auto Create Buttons from LOADERS
for _, item in ipairs(LOADERS) do
    local btn = makeButton(item.Name, item.Description, body)
    btn.MouseButton1Click:Connect(function()
        if item.URL then safeLoad(item.URL) else warn("⚠️ Missing URL for", item.Name) end
    end)
end

--// Terminate Button (always last)
local btnTerminate = makeButton("Terminate","Remove this GUI and cleanup", body)
btnTerminate.BackgroundColor3 = Color3.fromRGB(55,40,40)
btnTerminate.MouseButton1Click:Connect(Cleanup)

--// 🌀 Minimize / Restore
local minimized = false
local originalSize = main.Size
local originalPosition = main.Position

local function tweenMainTo(size,pos)
    local tween = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = size, Position = pos})
    tween:Play()
end

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        body.Visible = false
        tweenMainTo(UDim2.new(0, 240, 0, 56), originalPosition)
    else
        body.Visible = true
        tweenMainTo(originalSize, originalPosition)
    end
end)

--// 🖱️ Dragging
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// ⌨️ RightShift Toggle
UserInputService.InputBegan:Connect(function(inp, processed)
    if not processed and inp.KeyCode == TOGGLE_KEY then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

--// Store Cleanup reference
getgenv().ModernGuiLoader = {Cleanup = Cleanup, ScreenGui = screenGui}

print("✅ Modern GUI Loader (Auto Button) loaded. Press RightShift to toggle visibility.")
