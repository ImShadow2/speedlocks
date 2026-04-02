--// 🧩 Refined Modern Loader (RGB + Gotham + Hover Effects)
if getgenv().ModernGuiLoader and getgenv().ModernGuiLoader.Cleanup then
    pcall(getgenv().ModernGuiLoader.Cleanup)
    getgenv().ModernGuiLoader = nil
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// ✨ Content List
local CONTENT = {
    {Type = "Script", Name = "Infinite Yield", Data = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
    {Type = "Script", Name = "Menu", Data = "https://github.com/ImShadow2/speedlocks/raw/refs/heads/main/speed.lua"},
    {Type = "Script", Name = "Bring Item", Data = "https://raw.githubusercontent.com/ImShadow2/speedlocks/refs/heads/main/dexter.lua"},

}

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ModernRefined_v7"

-- Main Frame
local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 190, 0, 260)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Deep Dark Gray
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- RGB Sideline
local SideLine = Instance.new("Frame", Main)
SideLine.Size = UDim2.new(0, 3, 1, -20)
SideLine.Position = UDim2.new(0, 0, 0, 10)
SideLine.BorderSizePixel = 0
Instance.new("UICorner", SideLine)

spawn(function()
    while task.wait() do
        local hue = tick() % 5 / 5
        SideLine.BackgroundColor3 = Color3.fromHSV(hue, 0.8, 1)
    end
end)

-- Top Bar
local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "PROJECT HUB"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = "Left"
Title.BackgroundTransparency = 1

-- Control Buttons
local function createControl(text, pos, color)
    local btn = Instance.new("TextButton", TopBar)
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = color
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local Close = createControl("×", UDim2.new(1, -30, 0.5, -11), Color3.fromRGB(255, 100, 100))
local Min = createControl("-", UDim2.new(1, -58, 0.5, -11), Color3.fromRGB(200, 200, 200))

-- Scrollable Container
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -25, 1, -55)
Scroll.Position = UDim2.new(0, 15, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0, 6)

-- Button Logic with Hover Effects
for _, item in ipairs(CONTENT) do
    local Btn = Instance.new("TextButton", Scroll)
    Btn.Size = UDim2.new(1, -5, 0, 35)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.Text = item.Name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    Btn.TextSize = 12
    Btn.AutoButtonColor = false -- Custom tweening
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.white}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(210, 210, 210)}):Play()
    end)

    Btn.MouseButton1Click:Connect(function()
        if item.Type == "Script" then
            local s, r = pcall(function() return game:HttpGet(item.Data, true) end)
            if s then loadstring(r)() end
        elseif item.Type == "Link" and setclipboard then
            setclipboard(item.Data)
        end
        Btn.Text = "DONE"
        task.wait(0.6)
        Btn.Text = item.Name
    end)
end

-- Functionality (Dragging, Minimize, etc.)
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
end)

local isMin = false
Min.MouseButton1Click:Connect(function()
    isMin = not isMin
    Scroll.Visible = not isMin
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = isMin and UDim2.new(0, 190, 0, 40) or UDim2.new(0, 190, 0, 260)}):Play()
end)

local function Cleanup() ScreenGui:Destroy() end
Close.MouseButton1Click:Connect(Cleanup)

UserInputService.InputBegan:Connect(function(io, p)
    if not p and io.KeyCode == Enum.KeyCode.RightShift then ScreenGui.Enabled = not ScreenGui.Enabled end
end)

-- Dragging System
local d, di, ds, sp
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true ds = i.Position sp = Main.Position i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end) end end)
Main.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then di = i end end)
RunService.RenderStepped:Connect(function() if d and di then local dl = di.Position - ds Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dl.X, sp.Y.Scale, sp.Y.Offset + dl.Y) end end)

getgenv().ModernGuiLoader = {Cleanup = Cleanup}
