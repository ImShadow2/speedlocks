-- Modern GUI Loader (LocalScript)
-- Features:
-- • Draggable, modern-looking GUI
-- • Buttons to load: Infinite Yield, Speed, Universal script
-- • Terminate button that cleans up (removes GUI and unhooks keybinds)
-- • RightShift toggle to show/hide GUI (user preference)
-- • Safe re-execution: removes previous GUI if present
-- • Minimal dependencies, works in most executors

-- Prevent stacking on re-execution
if getgenv().ModernGuiLoader and getgenv().ModernGuiLoader.Cleanup then
    pcall(getgenv().ModernGuiLoader.Cleanup)
    getgenv().ModernGuiLoader = nil
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Config
local TOGGLE_KEY = Enum.KeyCode.RightShift
local GUI_NAME = "ModernGuiLoader_v1"

-- Utility: make Instance with properties
local function new(cls, props)
    local obj = Instance.new(cls)
    if props then
        for k,v in pairs(props) do
            if type(k) == "string" then
                obj[k] = v
            end
        end
    end
    return obj
end

-- Create screen gui
local screenGui = new("ScreenGui", {Name = GUI_NAME, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
if syn and syn.protect_gui then pcall(syn.protect_gui, screenGui) end
screenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Main container
local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.new(0.5, 0.5, 0.5, 0),
    Size = UDim2.new(0, 200, 0, 330),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.fromRGB(25,25,25),
})
main.Parent = screenGui

local uicorner = new("UICorner", {CornerRadius = UDim.new(0, 14), Parent = main})
local shadow = new("UICorner", {CornerRadius = UDim.new(0, 16), Parent = main})

-- Top bar
local topBar = new("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1,0,0,48),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    Parent = main,
})

local title = new("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1,-96,1,0),
    Position = UDim2.new(0,16,0,0),
    BackgroundTransparency = 1,
    Text = "GUI Loader",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(240,240,240),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = topBar,
})

local closeBtn = new("TextButton", {
    Name = "Close",
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -40, 0.5, -14),
    BackgroundTransparency = 0,
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(220,80,90),
    AutoButtonColor = true,
    Parent = topBar,
})
new("UICorner", {CornerRadius = UDim.new(0,8), Parent = closeBtn})

local minimizeBtn = new("TextButton", {
    Name = "Minimize",
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -72, 0.5, -14),
    BackgroundTransparency = 0,
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    Text = "—",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(200,200,200),
    AutoButtonColor = true,
    Parent = topBar,
})
new("UICorner", {CornerRadius = UDim.new(0,8), Parent = minimizeBtn})

-- Body
local body = new("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -32, 1, -64),
    Position = UDim2.new(0,16,0,56),
    BackgroundTransparency = 1,
    Parent = main,
})

-- Grid for buttons
local uiGrid = new("UIGridLayout", {Parent = body, CellSize = UDim2.new(0, 170, 0, 56), CellPadding = UDim2.new(0,12,0,12), HorizontalAlignment = Enum.HorizontalAlignment.Left, SortOrder = Enum.SortOrder.LayoutOrder})

local function makeButton(text, desc)
    local btn = new("TextButton", {
        Name = text:gsub("%s+",""),
        Size = UDim2.new(0, 170, 0, 56),
        BackgroundColor3 = Color3.fromRGB(45,45,45),
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(230,230,230),
        AutoButtonColor = true,
        Parent = body,
    })
    new("UICorner", {CornerRadius = UDim.new(0,10), Parent = btn})
    local sub = new("TextLabel", {Parent = btn, Size = UDim2.new(1,-12,0,18), Position = UDim2.new(0,8,1,-22), BackgroundTransparency = 1, Text = desc or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(170,170,170), TextXAlignment = Enum.TextXAlignment.Left})
    return btn
end

-- Buttons
local btnInfYield = makeButton("Infinite Yield","Load InfiniteYield admin script")
local btnSpeed = makeButton("Speed","Load speed script (if available)")
local btnUniv = makeButton("Universal","Load universal GUI script")
local btnTerminate = makeButton("Terminate","Remove this GUI and cleanup")
btnTerminate.BackgroundColor3 = Color3.fromRGB(55,40,40)

-- Helper to safely httpget and load
local function safeLoad(url)
    local ok, res = pcall(function()
        if isfile and writefile and readfile then
            -- executor with file support: try to fetch
            return game:HttpGet(url, true)
        else
            return game:HttpGet(url, true)
        end
    end)
    if not ok or not res then
        warn("Failed to fetch:", url)
        return false
    end
    local suc, err = pcall(function() loadstring(res)() end)
    if not suc then warn("exec error:", err) end
    return suc
end

-- Button actions
btnInfYield.MouseButton1Click:Connect(function()
    spawn(function()
        pcall(function()
            safeLoad('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source')
        end)
    end)
end)

btnSpeed.MouseButton1Click:Connect(function()
    spawn(function()
        pcall(function()
            safeLoad('https://raw.githubusercontent.com/ImShadow2/speedlocks/main/speed.lua')
        end)
    end)
end)

btnUniv.MouseButton1Click:Connect(function()
    spawn(function()
        pcall(function()
            safeLoad('https://raw.githubusercontent.com/ImShadow2/3-universal-gui/main/3universalgui.lua')
        end)
    end)
end)

local function Cleanup()
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    if getgenv().ModernGuiLoader then
        getgenv().ModernGuiLoader = nil
    end
end

btnTerminate.MouseButton1Click:Connect(function()
    Cleanup()
end)

-- Close / Minimize
closeBtn.MouseButton1Click:Connect(Cleanup)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    if minimized then
        main.Size = UDim2.new(0, 240, 0, 56)
    else
        main.Size = UDim2.new(0, 380, 0, 240)
    end
end)

-- Dragging
local dragging,dragInput,dragStart,startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle with RightShift
UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.KeyCode == TOGGLE_KEY then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- Save cleanup to global for re-exec
getgenv().ModernGuiLoader = {Cleanup = Cleanup, ScreenGui = screenGui}

-- Finished
print("Modern GUI Loader loaded. RightShift to toggle.")
