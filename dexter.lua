--// Modern Dex Ultimate GUI (CoreGui Overlay)
--// Explorer Bring with IY-style Bring/TP

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- SAFE RE-EXECUTION
if CoreGui:FindFirstChild("Dex_Ultimate") then
    CoreGui.Dex_Ultimate:Destroy()
end

-- GUI
local DexUI = Instance.new("ScreenGui")
DexUI.Name = "Dex_Ultimate"
DexUI.ResetOnSpawn = false
DexUI.IgnoreGuiInset = true
DexUI.Parent = CoreGui

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 490, 0, 480)
Main.Position = UDim2.new(0.5, -245, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = DexUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,30)
TitleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-40,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.Text = "Explorer Bring"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(220,220,220)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,20)
CloseBtn.Position = UDim2.new(1,-35,0,5)
CloseBtn.Text = "❌"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    DexUI:Destroy()
end)

-- PATH BAR
local PathBar = Instance.new("TextLabel")
PathBar.Size = UDim2.new(1,-10,0,22)
PathBar.Position = UDim2.new(0,5,0,35)
PathBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
PathBar.TextColor3 = Color3.fromRGB(160,160,160)
PathBar.TextXAlignment = Enum.TextXAlignment.Left
PathBar.Font = Enum.Font.Gotham
PathBar.TextSize = 14
PathBar.BorderSizePixel = 0
PathBar.Parent = Main

-- BUTTON FACTORY
local function makeBtn(text, x, w, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 26)
    b.Position = UDim2.new(0, x, 0, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(45,45,45)
    b.TextColor3 = Color3.fromRGB(220,220,220)
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.Parent = Main
    return b
end

-- CONTROLS
local BackBtn      = makeBtn("◀️", 5, 28, 60)
local WorkspaceBtn = makeBtn("🔄️", 38, 28, 60)

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(0, 120, 0, 26)
Search.Position = UDim2.new(0, 70, 0, 60)
Search.PlaceholderText = "Search here"
Search.BackgroundColor3 = Color3.fromRGB(40,40,40)
Search.TextColor3 = Color3.fromRGB(255,255,255)
Search.BorderSizePixel = 0
Instance.new("UICorner", Search).CornerRadius = UDim.new(0,6)
Search.Parent = Main

local filters = {"All","Part","Model","Folder","Script","LocalScript"}
local filterIndex = 1
local FilterBtn   = makeBtn("All", 195, 60, 60)
local ClearBtn    = makeBtn("Clear", 260, 55, 60)
local BringAllBtn = makeBtn("Bring All", 320, 80, 60)
local BindBtn     = makeBtn("Key: Insert", 405, 80, 60)

-- SCROLL
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,-100)
Scroll.Position = UDim2.new(0,0,0,100)
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.BackgroundTransparency = 1
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,4)
Layout.Parent = Scroll

-- STATE
local currentInstance = workspace
local statusMap = {}
local visibleObjects = {}
local toggleKey = Enum.KeyCode.Insert

-- UTIL
local function HRP()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

local function resolvePart(obj)
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
end

-- IY-STYLE BRING
local function bring(obj)
    local hrp = HRP()
    if not hrp then return end

    if obj:IsA("Model") then
        local part = resolvePart(obj)
        if part then
            local cf = hrp.CFrame * CFrame.new(0,0,-5)
            pcall(function() obj:PivotTo(cf) end)
        end
    elseif obj:IsA("BasePart") then
        obj.CFrame = hrp.CFrame * CFrame.new(0,0,-5)
    end
end

-- IY-STYLE TP
local function tp(obj)
    local hrp = HRP()
    if not hrp then return end

    local part = resolvePart(obj)
    if part then
        hrp.CFrame = part.CFrame * CFrame.new(0,3,-6)
    end
end

-- PATH SAFE
local function updatePath()
    if not currentInstance or not currentInstance:IsDescendantOf(game) then
        currentInstance = workspace
    end

    local parts = {}
    local o = currentInstance
    while o and o ~= workspace do
        table.insert(parts, 1, o.Name)
        o = o.Parent
    end

    PathBar.Text = "workspace" .. (#parts > 0 and " / "..table.concat(parts, " / ") or "")
end

-- REFRESH
local function Refresh()
    visibleObjects = {}

    for _,v in ipairs(Scroll:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end

    updatePath()
    BackBtn.TextTransparency = currentInstance == workspace and 0.5 or 0

    local search = Search.Text:lower()
    local filter = filters[filterIndex]

    for _,obj in ipairs(currentInstance:GetChildren()) do
        if search ~= "" and not obj.Name:lower():find(search, 1, true) then continue end
        if filter ~= "All" and not obj.ClassName:find(filter) then continue end

        table.insert(visibleObjects, obj)
        local fullPath = obj:GetFullName()
        statusMap[fullPath] = statusMap[fullPath] or 0

        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1,-10,0,28)
        Row.BackgroundColor3 = Color3.fromRGB(35,35,35)
        Row.BorderSizePixel = 0
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0,6)
        Row.Parent = Scroll

        -- STATUS
        local Status = Instance.new("TextButton")
        Status.Size = UDim2.new(0,28,0,22)
        Status.Position = UDim2.new(0,5,0.5,-11)
        Status.Text = "-"
        Status.Parent = Row

        local function updateColor()
            Row.BackgroundColor3 =
                statusMap[fullPath] == 1 and Color3.fromRGB(0,170,0)
                or statusMap[fullPath] == 2 and Color3.fromRGB(170,0,0)
                or Color3.fromRGB(35,35,35)
        end
        updateColor()

        Status.MouseButton1Click:Connect(function()
            statusMap[fullPath] = (statusMap[fullPath] + 1) % 3
            updateColor()
        end)

        -- LABEL
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1,-165,1,0)
        Label.Position = UDim2.new(0,38,0,0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Text = "("..obj.ClassName..") "..obj.Name
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.TextColor3 = Color3.new(1,1,1)
        Label.Parent = Row

        -- ACTIONS
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local BringBtn = Instance.new("TextButton")
            BringBtn.Size = UDim2.new(0,45,0,22)
            BringBtn.Position = UDim2.new(1,-145,0.5,-11)
            BringBtn.Text = "bring"
            BringBtn.Parent = Row
            BringBtn.MouseButton1Click:Connect(function() bring(obj) end)

            local TPBtn = Instance.new("TextButton")
            TPBtn.Size = UDim2.new(0,35,0,22)
            TPBtn.Position = UDim2.new(1,-95,0.5,-11)
            TPBtn.Text = "tp"
            TPBtn.Parent = Row
            TPBtn.MouseButton1Click:Connect(function() tp(obj) end)
        end

        if obj:IsA("Folder") or obj:IsA("Model") then
            local GoBtn = Instance.new("TextButton")
            GoBtn.Size = UDim2.new(0,30,0,22)
            GoBtn.Position = UDim2.new(1,-45,0.5,-11)
            GoBtn.Text = "▶️"
            GoBtn.Parent = Row
            GoBtn.MouseButton1Click:Connect(function()
                currentInstance = obj
                Refresh()
            end)
        end
    end
end

-- EVENTS
Search:GetPropertyChangedSignal("Text"):Connect(Refresh)

ClearBtn.MouseButton1Click:Connect(function()
    Search.Text = ""
    Refresh()
end)

FilterBtn.MouseButton1Click:Connect(function()
    filterIndex = filterIndex % #filters + 1
    FilterBtn.Text = filters[filterIndex]
    Refresh()
end)

BringAllBtn.MouseButton1Click:Connect(function()
    for _,obj in ipairs(visibleObjects) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            bring(obj)
        end
    end
end)

BackBtn.MouseButton1Click:Connect(function()
    if currentInstance ~= workspace then
        currentInstance = currentInstance.Parent or workspace
        Refresh()
    end
end)

WorkspaceBtn.MouseButton1Click:Connect(function()
    currentInstance = workspace
    Refresh()
end)

-- KEYBIND BUTTON
BindBtn.MouseButton1Click:Connect(function()
    BindBtn.Text = "..."
    local conn
    conn = UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode ~= Enum.KeyCode.Unknown then
            toggleKey = i.KeyCode
            BindBtn.Text = toggleKey.Name
            conn:Disconnect()
        end
    end)
end)

-- TOGGLE GUI
UIS.InputBegan:Connect(function(i,gp)
    if not gp and i.KeyCode == toggleKey then
        Main.Visible = not Main.Visible
    end
end)

-- INIT
Refresh()
