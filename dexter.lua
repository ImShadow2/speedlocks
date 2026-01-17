--// Modern Dex Ultimate GUI (CoreGui Overlay)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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
DexUI.Parent = CoreGui
DexUI.IgnoreGuiInset = true -- overlay everything

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 438, 0, 480) -- medium size
Main.Position = UDim2.new(0.5, -210, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = DexUI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0,12)
UICorner.Parent = Main

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,30)
TitleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8,0,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.Text = "DEX"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(220,220,220)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- CLOSE BUTTON [ X ]
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,20)
CloseBtn.Position = UDim2.new(1,-35,0,5)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    DexUI:Destroy()
end)

-- BREADCRUMB BAR
local PathBar = Instance.new("TextLabel")
PathBar.Size = UDim2.new(1,-10,0,22)
PathBar.Position = UDim2.new(0,5,0,35)
PathBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
PathBar.TextColor3 = Color3.fromRGB(160,160,160)
PathBar.TextXAlignment = Enum.TextXAlignment.Left
PathBar.Font = Enum.Font.Gotham
PathBar.TextSize = 14
PathBar.Text = "workspace"
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
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = b
    b.Parent = Main
    return b
end

-- CONTROLS
local BackBtn     = makeBtn("<",        5,   28, 60)
local Search      = Instance.new("TextBox")
Search.Size = UDim2.new(0, 120, 0, 26)
Search.Position = UDim2.new(0, 38, 0, 60)
Search.PlaceholderText = "[ search ]"
Search.BackgroundColor3 = Color3.fromRGB(40,40,40)
Search.TextColor3 = Color3.fromRGB(1,1,1)
Search.BorderSizePixel = 0
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,6)
corner.Parent = Search
Search.Parent = Main

local FilterBtn   = makeBtn("All",       165, 60, 60)
local ClearBtn    = makeBtn("Clear",     230, 55, 60)
local BringAllBtn = makeBtn("Bring All", 290, 80, 60)
local BindBtn     = makeBtn("Insert",    375, 60, 60)

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
local toggleKey = Enum.KeyCode.Insert
local filters = {"All","Part","Model","Folder","Script","LocalScript"}
local filterIndex = 1
local statusMap = {}

-- UTIL FUNCTIONS
local function HRP()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

local function bring(obj)
    local hrp = HRP()
    if not hrp then return end
    local cf = hrp.CFrame * CFrame.new(0,0,-5)
    if obj:IsA("Model") then
        pcall(function() obj:PivotTo(cf) end)
    elseif obj:IsA("BasePart") then
        obj.CFrame = cf
    end
end

local function tp(obj)
    local hrp = HRP()
    if not hrp then return end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if p then hrp.CFrame = p.CFrame end
    elseif obj:IsA("BasePart") then
        hrp.CFrame = obj.CFrame
    end
end

local function getFullPath(obj)
    local path = {}
    local o = obj
    while o and o ~= game do
        table.insert(path, 1, o.Name)
        o = o.Parent
    end
    return table.concat(path, "/")
end

local function updatePath()
    local path = {}
    local obj = currentInstance
    while obj and obj ~= game do
        table.insert(path, 1, obj.Name)
        obj = obj.Parent
    end
    PathBar.Text = table.concat(path, " / ")
end

-- REFRESH FUNCTION
local function Refresh()
    for _,v in ipairs(Scroll:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end

    updatePath()
    BackBtn.TextTransparency = currentInstance == workspace and 0.5 or 0

    local search = Search.Text:lower()
    local filter = filters[filterIndex]

    for _,obj in ipairs(currentInstance:GetChildren()) do
        if search ~= "" and not obj.Name:lower():find(search) then continue end
        if filter ~= "All" and not obj.ClassName:find(filter) then continue end

        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1,-10,0,28)
        Row.BackgroundColor3 = Color3.fromRGB(35,35,35)
        Row.BorderSizePixel = 0
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0,6)
        rowCorner.Parent = Row
        Row.Parent = Scroll

        local fullPath = getFullPath(obj)
        if not statusMap[fullPath] then statusMap[fullPath] = 0 end

        -- STATUS BUTTON [ - ]
        local StatusBtn = Instance.new("TextButton")
        StatusBtn.Size = UDim2.new(0,28,0,22)
        StatusBtn.Position = UDim2.new(0,5,0.5,-11)
        StatusBtn.Text = "-"
        StatusBtn.Parent = Row
        local function updateStatusColor()
            if statusMap[fullPath] == 0 then
                Row.BackgroundColor3 = Color3.fromRGB(35,35,35)
            elseif statusMap[fullPath] == 1 then
                Row.BackgroundColor3 = Color3.fromRGB(0,180,0)
            elseif statusMap[fullPath] == 2 then
                Row.BackgroundColor3 = Color3.fromRGB(180,0,0)
            end
        end
        updateStatusColor()
        StatusBtn.MouseButton1Click:Connect(function()
            statusMap[fullPath] = (statusMap[fullPath]+1)%3
            updateStatusColor()
        end)

        -- LABEL
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1,-165,1,0)
        Label.Position = UDim2.new(0,38,0,0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Text = "("..obj.ClassName..") "..obj.Name
        Label.TextColor3 = Color3.new(1,1,1)
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 14
        Label.Parent = Row

        -- BRING & TP
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local Bring = Instance.new("TextButton")
            Bring.Size = UDim2.new(0,45,0,22)
            Bring.Position = UDim2.new(1,-145,0.5,-11)
            Bring.Text = "bring"
            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0,6)
            bCorner.Parent = Bring
            Bring.Parent = Row
            Bring.MouseButton1Click:Connect(function() bring(obj) end)

            local TP = Instance.new("TextButton")
            TP.Size = UDim2.new(0,35,0,22)
            TP.Position = UDim2.new(1,-95,0.5,-11)
            TP.Text = "tp"
            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(0,6)
            tCorner.Parent = TP
            TP.Parent = Row
            TP.MouseButton1Click:Connect(function() tp(obj) end)
        end

        -- FOLDER / MODEL >
        if obj:IsA("Folder") or obj:IsA("Model") then
            local Go = Instance.new("TextButton")
            Go.Size = UDim2.new(0,30,0,22)
            Go.Position = UDim2.new(1,-45,0.5,-11)
            Go.Text = ">"
            local gCorner = Instance.new("UICorner")
            gCorner.CornerRadius = UDim.new(0,6)
            gCorner.Parent = Go
            Go.Parent = Row
            Go.MouseButton1Click:Connect(function()
                currentInstance = obj
                Refresh()
            end)
        end
    end
end

-- EVENTS
Search:GetPropertyChangedSignal("Text"):Connect(Refresh)

FilterBtn.MouseButton1Click:Connect(function()
    filterIndex = filterIndex % #filters + 1
    FilterBtn.Text = filters[filterIndex]
    Refresh()
end)

ClearBtn.MouseButton1Click:Connect(function()
    Search.Text = ""
    Refresh()
end)

BringAllBtn.MouseButton1Click:Connect(function()
    for _,obj in ipairs(currentInstance:GetChildren()) do
        if Search.Text ~= "" and not obj.Name:lower():find(Search.Text:lower()) then continue end
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

BindBtn.MouseButton1Click:Connect(function()
    BindBtn.Text = "Press Key..."
    local c
    c = UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        toggleKey = i.KeyCode
        BindBtn.Text = toggleKey.Name
        c:Disconnect()
    end)
end)

UIS.InputBegan:Connect(function(i,gp)
    if not gp and i.KeyCode == toggleKey then
        Main.Visible = not Main.Visible
    end
end)

-- INIT
Refresh()
