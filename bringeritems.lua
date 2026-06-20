-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Global States
local isRunning = true
local uiVisible = true
local currentExplorerPath = workspace
local currentTab = 1 

-- Keybind Configuration State
local toggleKeybind = Enum.KeyCode.F1
local isBindingKey = false

-- Multi-Path Targets & View States
local selectedFolderNames = {} 
local folderPools = {}         
local activeBrings = {}        
local activeShowFolder = nil   
local bringDistance = 5
local maxItems = 35           
local bringSearchText = ""    

-- Dynamic Instance Listener Remounters
local activeChildAddedConn = nil
local activeChildRemovedConn = nil

-- Unified Master ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernBringerSystem"
ScreenGui.ResetOnSpawn = false

local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-------------------------------------------------------------------------------
-- MAIN WINDOW (Sleek Dark Premium UI)
-------------------------------------------------------------------------------
local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, 320, 0, 420)
MainWindow.Position = UDim2.new(0.5, -160, 0.4, -210)
MainWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.Draggable = true
MainWindow.Parent = ScreenGui

local MainUICorner = Instance.new("UICorner")
MainUICorner.CornerRadius = UDim.new(0, 8)
MainUICorner.Parent = MainWindow

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(45, 45, 55)
UIStroke.Thickness = 1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainWindow

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainWindow

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 8)
TabBarCorner.Parent = TabBar

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = TabBar

local UtilContainer = Instance.new("Frame")
UtilContainer.Size = UDim2.new(0, 115, 1, 0)
UtilContainer.Position = UDim2.new(1, -120, 0, 0)
UtilContainer.BackgroundTransparency = 1
UtilContainer.Parent = TabBar

local BindBtn = Instance.new("TextButton")
BindBtn.Size = UDim2.new(0, 75, 0, 24)
BindBtn.Position = UDim2.new(0, 0, 0.5, -12)
BindBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
BindBtn.Text = "Bind: F1"
BindBtn.TextColor3 = Color3.fromRGB(190, 190, 210)
BindBtn.Font = Enum.Font.SourceSansBold
BindBtn.TextSize = 12
BindBtn.BorderSizePixel = 0
BindBtn.Parent = UtilContainer

local BindCorner = Instance.new("UICorner")
BindCorner.CornerRadius = UDim.new(0, 4)
BindCorner.Parent = BindBtn

local KillBtn = Instance.new("TextButton")
KillBtn.Size = UDim2.new(0, 24, 0, 24)
KillBtn.Position = UDim2.new(1, -28, 0.5, -12)
KillBtn.BackgroundColor3 = Color3.fromRGB(210, 70, 70)
KillBtn.Text = "×"
KillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillBtn.Font = Enum.Font.SourceSansBold
KillBtn.TextSize = 16
KillBtn.BorderSizePixel = 0
KillBtn.Parent = UtilContainer

local KillCorner = Instance.new("UICorner")
KillCorner.CornerRadius = UDim.new(0, 4)
KillCorner.Parent = KillBtn

-------------------------------------------------------------------------------
-- CHROME TAB SELECTION MATRIX
-------------------------------------------------------------------------------
local TabButtons = {}
local tabNames = { "Paths", "Pool", "Engine" }

for i, name in ipairs(tabNames) do
	local TabBtn = Instance.new("TextButton")
	TabBtn.Size = UDim2.new(0, 58, 1, -12)
	TabBtn.Position = UDim2.new(0, (i - 1) * 62 + 8, 0, 6)
	TabBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	TabBtn.Text = name
	TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	TabBtn.Font = Enum.Font.SourceSansBold
	TabBtn.TextSize = 12
	TabBtn.BorderSizePixel = 0
	TabBtn.Parent = TabBar
	
	local TBCorner = Instance.new("UICorner")
	TBCorner.CornerRadius = UDim.new(0, 4)
	TBCorner.Parent = TabBtn
	
	TabButtons[i] = TabBtn
end

-------------------------------------------------------------------------------
-- SEPARATED ACTIVE CONTENT FRAMES
-------------------------------------------------------------------------------
local Col1Frame = Instance.new("Frame")
Col1Frame.Size = UDim2.new(1, -16, 1, -52)
Col1Frame.Position = UDim2.new(0, 8, 0, 46)
Col1Frame.BackgroundTransparency = 1
Col1Frame.Parent = MainWindow

local UpBtn = Instance.new("TextButton")
UpBtn.Size = UDim2.new(0, 28, 0, 24)
UpBtn.Position = UDim2.new(1, -28, 0, 0)
UpBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 54)
UpBtn.Text = "⌃"
UpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UpBtn.Font = Enum.Font.SourceSansBold
UpBtn.TextSize = 14
UpBtn.BorderSizePixel = 0
UpBtn.Parent = Col1Frame

local UpCorner = Instance.new("UICorner")
UpCorner.CornerRadius = UDim.new(0, 4)
UpCorner.Parent = UpBtn

local FindPathScroller = Instance.new("ScrollingFrame")
FindPathScroller.Size = UDim2.new(1, -34, 0, 24)
FindPathScroller.Position = UDim2.new(0, 0, 0, 0)
FindPathScroller.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
FindPathScroller.BorderSizePixel = 0
FindPathScroller.CanvasSize = UDim2.new(0, 900, 0, 0)
FindPathScroller.ScrollBarThickness = 0
FindPathScroller.Parent = Col1Frame

local FindPathLabel = Instance.new("TextLabel")
FindPathLabel.Size = UDim2.new(1, -5, 1, 0)
FindPathLabel.Position = UDim2.new(0, 6, 0, 0)
FindPathLabel.BackgroundTransparency = 1
FindPathLabel.Text = "workspace"
FindPathLabel.TextColor3 = Color3.fromRGB(110, 160, 235)
FindPathLabel.Font = Enum.Font.Code
FindPathLabel.TextSize = 11
FindPathLabel.TextXAlignment = Enum.TextXAlignment.Left
FindPathLabel.Parent = FindPathScroller

local FindScroll = Instance.new("ScrollingFrame")
FindScroll.Size = UDim2.new(1, 0, 1, -32)
FindScroll.Position = UDim2.new(0, 0, 0, 32)
FindScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
FindScroll.BorderSizePixel = 0
FindScroll.ScrollBarThickness = 2
FindScroll.Parent = Col1Frame

local FindLayout = Instance.new("UIListLayout")
FindLayout.SortOrder = Enum.SortOrder.LayoutOrder
FindLayout.Padding = UDim.new(0, 4)
FindLayout.Parent = FindScroll

local DirectTrackWorkspaceBtn = Instance.new("TextButton")
DirectTrackWorkspaceBtn.Size = UDim2.new(1, -4, 0, 28)
DirectTrackWorkspaceBtn.BackgroundColor3 = Color3.fromRGB(35, 60, 95)
DirectTrackWorkspaceBtn.Text = "🎯 Track Selected Container Folder"
DirectTrackWorkspaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DirectTrackWorkspaceBtn.Font = Enum.Font.SourceSansBold
DirectTrackWorkspaceBtn.TextSize = 12
DirectTrackWorkspaceBtn.BorderSizePixel = 0
DirectTrackWorkspaceBtn.LayoutOrder = 0
DirectTrackWorkspaceBtn.Parent = FindScroll

local DTWCorner = Instance.new("UICorner")
DTWCorner.CornerRadius = UDim.new(0, 4)
DTWCorner.Parent = DirectTrackWorkspaceBtn

local Col2Frame = Instance.new("Frame")
Col2Frame.Size = UDim2.new(1, -16, 1, -52)
Col2Frame.Position = UDim2.new(0, 8, 0, 46)
Col2Frame.BackgroundTransparency = 1
Col2Frame.Visible = false
Col2Frame.Parent = MainWindow

local SelectScroll = Instance.new("ScrollingFrame")
SelectScroll.Size = UDim2.new(1, 0, 1, 0)
SelectScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
SelectScroll.BorderSizePixel = 0
SelectScroll.ScrollBarThickness = 2
SelectScroll.Parent = Col2Frame

local SelectLayout = Instance.new("UIListLayout")
SelectLayout.SortOrder = Enum.SortOrder.LayoutOrder
SelectLayout.Padding = UDim.new(0, 4)
SelectLayout.Parent = SelectScroll

local Col3Frame = Instance.new("Frame")
Col3Frame.Size = UDim2.new(1, -16, 1, -52)
Col3Frame.Position = UDim2.new(0, 8, 0, 46)
Col3Frame.BackgroundTransparency = 1
Col3Frame.Visible = false
Col3Frame.Parent = MainWindow

local ActiveScroller = Instance.new("ScrollingFrame")
ActiveScroller.Size = UDim2.new(1, 0, 0, 24)
ActiveScroller.Position = UDim2.new(0, 0, 0, 0)
ActiveScroller.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
ActiveScroller.BorderSizePixel = 0
ActiveScroller.CanvasSize = UDim2.new(0, 900, 0, 0)
ActiveScroller.ScrollBarThickness = 0
ActiveScroller.Parent = Col3Frame

local ActiveFocusLabel = Instance.new("TextLabel")
ActiveFocusLabel.Size = UDim2.new(1, -5, 1, 0)
ActiveFocusLabel.Position = UDim2.new(0, 6, 0, 0)
ActiveFocusLabel.BackgroundTransparency = 1
ActiveFocusLabel.Text = "Target: None Selected"
ActiveFocusLabel.TextColor3 = Color3.fromRGB(90, 220, 140)
ActiveFocusLabel.Font = Enum.Font.SourceSansBold
ActiveFocusLabel.TextSize = 11
ActiveFocusLabel.TextXAlignment = Enum.TextXAlignment.Left
ActiveFocusLabel.Parent = ActiveScroller

local FilterBar = Instance.new("Frame")
FilterBar.Size = UDim2.new(1, 0, 0, 28)
FilterBar.Position = UDim2.new(0, 0, 0, 30)
FilterBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
FilterBar.BorderSizePixel = 0
FilterBar.Parent = Col3Frame

local FilterCorner = Instance.new("UICorner")
FilterCorner.CornerRadius = UDim.new(0, 4)
FilterCorner.Parent = FilterBar

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -10, 1, -4)
SearchInput.Position = UDim2.new(0, 5, 0, 2)
SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""
SearchInput.PlaceholderText = "🔍 Filter Combined Items (e.g. Plank)..."
SearchInput.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchInput.Font = Enum.Font.SourceSans
SearchInput.TextSize = 12
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.Parent = FilterBar

local RangeBar = Instance.new("Frame")
RangeBar.Size = UDim2.new(1, 0, 0, 28)
RangeBar.Position = UDim2.new(0, 0, 0, 62)
RangeBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
RangeBar.BorderSizePixel = 0
RangeBar.Parent = Col3Frame

local RangeBarCorner = Instance.new("UICorner")
RangeBarCorner.CornerRadius = UDim.new(0, 4)
RangeBarCorner.Parent = RangeBar

local RangeLabel = Instance.new("TextLabel")
RangeLabel.Size = UDim2.new(0, 160, 1, 0)
RangeLabel.Position = UDim2.new(0, 6, 0, 0)
RangeLabel.BackgroundTransparency = 1
RangeLabel.Text = "Bring Distance Offset (Studs):"
RangeLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
RangeLabel.Font = Enum.Font.SourceSans
RangeLabel.TextSize = 12
RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
RangeLabel.Parent = RangeBar

local RangeInput = Instance.new("TextBox")
RangeInput.Size = UDim2.new(0, 45, 0, 20)
RangeInput.Position = UDim2.new(1, -50, 0.5, -10)
RangeInput.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
RangeInput.BorderSizePixel = 0
RangeInput.Text = "5"
RangeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeInput.Font = Enum.Font.SourceSansBold
RangeInput.TextSize = 12
RangeInput.Parent = RangeBar

local RangeInputCorner = Instance.new("UICorner")
RangeInputCorner.CornerRadius = UDim.new(0, 3)
RangeInputCorner.Parent = RangeInput

local BringScroll = Instance.new("ScrollingFrame")
BringScroll.Size = UDim2.new(1, 0, 1, -94)
BringScroll.Position = UDim2.new(0, 0, 0, 94)
BringScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
BringScroll.BorderSizePixel = 0
BringScroll.ScrollBarThickness = 2
BringScroll.Parent = Col3Frame

local BringLayout = Instance.new("UIListLayout")
BringLayout.SortOrder = Enum.SortOrder.Name
BringLayout.Padding = UDim.new(0, 4)
BringLayout.Parent = BringScroll

-------------------------------------------------------------------------------
-- FIXED STATIC MEMORY ARRAYS CORES
-------------------------------------------------------------------------------
local finderRows, selectRows, bringerRows = {}, {}, {}

for i = 1, maxItems do
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, -4, 0, 32)
	Row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	Row.BorderSizePixel = 0
	Row.LayoutOrder = i
	Row.Visible = false
	Row.Parent = FindScroll

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -100, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.fromRGB(220, 220, 225)
	Label.Font = Enum.Font.SourceSans
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Row

	local SelectBtn = Instance.new("TextButton")
	SelectBtn.Size = UDim2.new(0, 45, 0, 24)
	SelectBtn.Position = UDim2.new(1, -86, 0.5, -12)
	SelectBtn.BackgroundColor3 = Color3.fromRGB(45, 105, 60)
	SelectBtn.Text = "Track"
	SelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	SelectBtn.Font = Enum.Font.SourceSansBold
	SelectBtn.TextSize = 11
	SelectBtn.Parent = Row

	local InBtn = Instance.new("TextButton")
	InBtn.Size = UDim2.new(0, 32, 0, 24)
	InBtn.Position = UDim2.new(1, -36, 0.5, -12)
	InBtn.BackgroundColor3 = Color3.fromRGB(46, 50, 62)
	InBtn.Text = "➜"
	InBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
	InBtn.Font = Enum.Font.SourceSansBold
	InBtn.TextSize = 12
	InBtn.Parent = Row

	Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", InBtn).CornerRadius = UDim.new(0, 4)

	finderRows[i] = { Row = Row, Label = Label, SelectBtn = SelectBtn, InBtn = InBtn, Conn1 = nil, Conn2 = nil }
end

for i = 1, maxItems do
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, -4, 0, 32)
	Row.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
	Row.BorderSizePixel = 0
	Row.LayoutOrder = i
	Row.Visible = false
	Row.Parent = SelectScroll

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -85, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.fromRGB(190, 225, 190)
	Label.Font = Enum.Font.SourceSans
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Row

	local ShowBtn = Instance.new("TextButton")
	ShowBtn.Size = UDim2.new(0, 45, 0, 24)
	ShowBtn.Position = UDim2.new(1, -72, 0.5, -12)
	ShowBtn.BackgroundColor3 = Color3.fromRGB(40, 65, 100)
	ShowBtn.Text = "View"
	ShowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ShowBtn.Font = Enum.Font.SourceSansBold
	ShowBtn.TextSize = 11
	ShowBtn.Parent = Row

	local DestroyBtn = Instance.new("TextButton")
	DestroyBtn.Size = UDim2.new(0, 22, 0, 22)
	DestroyBtn.Position = UDim2.new(1, -24, 0.5, -11)
	DestroyBtn.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
	DestroyBtn.Text = "×"
	DestroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	DestroyBtn.Font = Enum.Font.SourceSansBold
	DestroyBtn.TextSize = 14
	DestroyBtn.Parent = Row

	Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", ShowBtn).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", DestroyBtn).CornerRadius = UDim.new(0, 4)

	selectRows[i] = { Row = Row, Label = Label, ShowBtn = ShowBtn, DestroyBtn = DestroyBtn, Conn1 = nil, Conn2 = nil }
end

for i = 1, maxItems do
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, -4, 0, 32)
	Row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	Row.BorderSizePixel = 0
	Row.LayoutOrder = i
	Row.Visible = false
	Row.Parent = BringScroll

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -90, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.fromRGB(245, 245, 250)
	Label.Font = Enum.Font.SourceSans
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Row

	local BringBtn = Instance.new("TextButton")
	BringBtn.Size = UDim2.new(0, 72, 0, 24)
	BringBtn.Position = UDim2.new(1, -76, 0.5, -12)
	BringBtn.Text = "Bring"
	BringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	BringBtn.Font = Enum.Font.SourceSansBold
	BringBtn.TextSize = 11
	BringBtn.Parent = Row

	Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 4)
	Instance.new("UICorner", BringBtn).CornerRadius = UDim.new(0, 4)

	bringerRows[i] = { Row = Row, Label = Label, BringBtn = BringBtn, Conn1 = nil }
end

-------------------------------------------------------------------------------
-- ENGINE FUNCTIONS
-------------------------------------------------------------------------------
local refreshSelectedPathsPanel
local refreshBringerPanel

local function refreshFinderPanel()
	FindPathLabel.Text = currentExplorerPath:GetFullName()
	for i = 1, maxItems do finderRows[i].Row.Visible = false end

	local children = currentExplorerPath:GetChildren()
	local uniqueNames = {}
	local filteredChildren = {}

	-- Unique Filter to make sure identical folder names collapse on screen
	for _, child in ipairs(children) do
		if child ~= ScreenGui and child ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(child) then
			if not uniqueNames[child.Name] then
				uniqueNames[child.Name] = true
				table.insert(filteredChildren, child)
			end
		end
	end

	local index = 1
	for _, child in ipairs(filteredChildren) do
		if index > maxItems then break end
		local row = finderRows[index]
		row.Row.Visible = true
		row.Label.Text = child.Name .. " (Smart Combined)"

		if row.Conn1 then row.Conn1:Disconnect() end
		if row.Conn2 then row.Conn2:Disconnect() end

		row.Conn1 = row.InBtn.MouseButton1Click:Connect(function()
			currentExplorerPath = child
			refreshFinderPanel()
		end)

		row.Conn2 = row.SelectBtn.MouseButton1Click:Connect(function()
			local containerFolder = child.Parent
			local targetName = child.Name
			
			if containerFolder then
				if not folderPools[targetName] then
					folderPools[targetName] = {}
					table.insert(selectedFolderNames, targetName)
					activeBrings[targetName] = {}
				end
				
				for _, obj in ipairs(containerFolder:GetChildren()) do
					if obj.Name == targetName then
						local structureExists = false
						for _, existingObj in ipairs(folderPools[targetName]) do
							if existingObj == obj then structureExists = true break end
						end
						if not structureExists then
							table.insert(folderPools[targetName], obj)
						end
					end
				end
			end

			if not activeShowFolder then activeShowFolder = targetName end
			refreshSelectedPathsPanel()
			refreshBringerPanel()
		end)
		index = index + 1
	end
	FindScroll.CanvasSize = UDim2.new(0, 0, 0, FindLayout.AbsoluteContentSize.Y)
end

DirectTrackWorkspaceBtn.MouseButton1Click:Connect(function()
	if currentExplorerPath ~= workspace and currentExplorerPath.Parent then
		local containerFolder = currentExplorerPath.Parent
		local targetName = currentExplorerPath.Name
		
		if not folderPools[targetName] then
			folderPools[targetName] = {}
			table.insert(selectedFolderNames, targetName)
			activeBrings[targetName] = {}
		end
		
		for _, obj in ipairs(containerFolder:GetChildren()) do
			if obj.Name == targetName then
				local structureExists = false
				for _, existingObj in ipairs(folderPools[targetName]) do
					if existingObj == obj then structureExists = true break end
				end
				if not structureExists then
					table.insert(folderPools[targetName], obj)
				end
			end
		end

		if not activeShowFolder then activeShowFolder = targetName end
		refreshSelectedPathsPanel()
		refreshBringerPanel()
	end
end)

refreshSelectedPathsPanel = function()
	for i = 1, maxItems do selectRows[i].Row.Visible = false end

	for index, folderName in ipairs(selectedFolderNames) do
		if index > maxItems then break end
		local row = selectRows[index]
		row.Row.Visible = true
		row.Label.Text = folderName .. " [Pooled Container]"
		
		if activeShowFolder == folderName then
			row.Row.BackgroundColor3 = Color3.fromRGB(36, 52, 74)
		else
			row.Row.BackgroundColor3 = Color3.fromRGB(26, 28, 34)
		end

		if row.Conn1 then row.Conn1:Disconnect() end
		if row.Conn2 then row.Conn2:Disconnect() end

		row.Conn1 = row.ShowBtn.MouseButton1Click:Connect(function()
			activeShowFolder = folderName
			refreshSelectedPathsPanel()
			refreshBringerPanel()
		end)

		row.Conn2 = row.DestroyBtn.MouseButton1Click:Connect(function()
			table.remove(selectedFolderNames, index)
			folderPools[folderName] = nil
			activeBrings[folderName] = nil
			if activeShowFolder == folderName then
				activeShowFolder = selectedFolderNames[1] or nil
			end
			refreshSelectedPathsPanel()
			refreshBringerPanel()
		end)
	end
	SelectScroll.CanvasSize = UDim2.new(0, 0, 0, SelectLayout.AbsoluteContentSize.Y)
end

refreshBringerPanel = function()
	for i = 1, maxItems do bringerRows[i].Row.Visible = false end

	if activeChildAddedConn then activeChildAddedConn:Disconnect(); activeChildAddedConn = nil end
	if activeChildRemovedConn then activeChildRemovedConn:Disconnect(); activeChildRemovedConn = nil end

	if not activeShowFolder or not folderPools[activeShowFolder] then
		ActiveFocusLabel.Text = "Target: None Selected"
		return
	end

	ActiveFocusLabel.Text = "Tracking Pool: " .. activeShowFolder

	local firstInstance = folderPools[activeShowFolder][1]
	if firstInstance and firstInstance.Parent then
		activeChildAddedConn = firstInstance.Parent.ChildAdded:Connect(function() task.defer(refreshBringerPanel) end)
		activeChildRemovedConn = firstInstance.Parent.ChildRemoved:Connect(function() task.defer(refreshBringerPanel) end)
	end

	local structuralSignatures = {}
	for _, actualSubFolder in ipairs(folderPools[activeShowFolder]) do
		if actualSubFolder and actualSubFolder.Parent then
			
			local resFolder = actualSubFolder:FindFirstChild("Resources")
			if resFolder then
				for _, item in ipairs(resFolder:GetChildren()) do
					structuralSignatures[item.Name] = item.ClassName
				end
			end
			
			for _, item in ipairs(actualSubFolder:GetChildren()) do
				if item.Name ~= "Resources" then
					structuralSignatures[item.Name] = item.ClassName
				end
			end
		end
	end

	local index = 1
	for itemName, className in pairs(structuralSignatures) do
		if index > maxItems then break end
		
		if bringSearchText == "" or string.find(string.lower(itemName), string.lower(bringSearchText)) then
			local row = bringerRows[index]
			row.Row.Visible = true
			row.Label.Text = itemName .. " [" .. className .. "]"

			if row.Conn1 then row.Conn1:Disconnect() end

			local folderBrings = activeBrings[activeShowFolder] or {}
			
			if folderBrings[itemName] then
				row.BringBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 90)
				row.BringBtn.Text = "Bringing Match"
			else
				row.BringBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
				row.BringBtn.Text = "Bring All"
			end

			row.Conn1 = row.BringBtn.MouseButton1Click:Connect(function()
				folderBrings[itemName] = not folderBrings[itemName]
				activeBrings[activeShowFolder] = folderBrings
				refreshBringerPanel()
			end)
			index = index + 1
		end
	end
	BringScroll.CanvasSize = UDim2.new(0, 0, 0, BringLayout.AbsoluteContentSize.Y)
end

-------------------------------------------------------------------------------
-- INTERFACE TAB SWITCH MATRIX
-------------------------------------------------------------------------------
local function switchTab(tabIndex)
	currentTab = tabIndex
	Col1Frame.Visible = (tabIndex == 1)
	Col2Frame.Visible = (tabIndex == 2)
	Col3Frame.Visible = (tabIndex == 3)

	for i, btn in ipairs(TabButtons) do
		if i == tabIndex then
			btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
			btn.TextColor3 = Color3.fromRGB(140, 140, 155)
		end
	end
end

for i, btn in ipairs(TabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

switchTab(1)

-------------------------------------------------------------------------------
-- UI CHANGE SIGNALS
-------------------------------------------------------------------------------
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	bringSearchText = SearchInput.Text
	refreshBringerPanel()
end)

UpBtn.MouseButton1Click:Connect(function()
	if currentExplorerPath ~= workspace and currentExplorerPath ~= game then
		currentExplorerPath = currentExplorerPath.Parent or workspace
		refreshFinderPanel()
	end
end)

RangeInput.FocusLost:Connect(function()
	local val = tonumber(RangeInput.Text)
	if val then bringDistance = val else RangeInput.Text = tostring(bringDistance) end
end)

KillBtn.MouseButton1Click:Connect(function()
	isRunning = false
	if activeChildAddedConn then activeChildAddedConn:Disconnect() end
	if activeChildRemovedConn then activeChildRemovedConn:Disconnect() end
	ScreenGui:Destroy()
end)

BindBtn.MouseButton1Click:Connect(function()
	if isBindingKey then return end
	isBindingKey = true
	BindBtn.Text = "[...]"
	BindBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isBindingKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			toggleKeybind = input.KeyCode
			local keyName = toggleKeybind.Name
			if string.match(keyName, "^NumberPad") then keyName = string.gsub(keyName, "NumberPad", "Num ") end
			BindBtn.Text = "Bind: " .. keyName
			BindBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
			task.defer(function() isBindingKey = false end)
		end
		return 
	end
	if input.KeyCode == toggleKeybind then
		uiVisible = not uiVisible
		MainWindow.Visible = uiVisible
	end
end)

refreshFinderPanel()
refreshSelectedPathsPanel()
refreshBringerPanel()

-------------------------------------------------------------------------------
-- DYNAMIC TELEPORT COMPLIANCE MULTI-OBJECT ENGINE LOOP
-------------------------------------------------------------------------------
task.spawn(function()
	while isRunning do
		task.wait()
		local myChar = LocalPlayer.Character
		if myChar and myChar:FindFirstChild("HumanoidRootPart") then
			local myHRP = myChar.HumanoidRootPart
			local targetCFrame = myHRP.CFrame * CFrame.new(0, 0, -bringDistance)

			for _, trackedFolderName in ipairs(selectedFolderNames) do
				local pools = folderPools[trackedFolderName]
				local folderBrings = activeBrings[trackedFolderName]
				
				if pools and folderBrings then
					for _, subContainer in ipairs(pools) do
						if subContainer and subContainer.Parent and subContainer ~= myChar then
							
							for chosenItemName, activeState in pairs(folderBrings) do
								if activeState == true then
									
									local itemsToBring = {}
									
									local resFolder = subContainer:FindFirstChild("Resources")
									if resFolder then
										for _, item in ipairs(resFolder:GetChildren()) do
											if item.Name == chosenItemName then
												table.insert(itemsToBring, item)
											end
										end
									end
									
									for _, item in ipairs(subContainer:GetChildren()) do
										if item.Name == chosenItemName and item.Name ~= "Resources" then
											table.insert(itemsToBring, item)
										end
									end
									
									-- FIXED SYNTAX HERE: Correct loop iteration assignment
									for _, targetItem in ipairs(itemsToBring) do
										if targetItem and targetItem ~= myChar and not Players:GetPlayerFromCharacter(targetItem) then
											local part = nil
											if targetItem:IsA("BasePart") then
												part = targetItem
											elseif targetItem:IsA("Model") then
												part = targetItem.PrimaryPart 
													or targetItem:FindFirstChild("HumanoidRootPart") 
													or targetItem:FindFirstChild("Torso") 
													or targetItem:FindFirstChildWhichIsA("BasePart")
											end
											
											if part then
												if targetItem:IsA("Model") then
													for _, subPart in ipairs(targetItem:GetDescendants()) do
														if subPart:IsA("BasePart") then subPart.CanCollide = false end
													end
													targetItem:PivotTo(targetCFrame)
												else
													part.CanCollide = false
													part.CFrame = targetCFrame
												end
											end
										end
									end
									
								end
							end
							
						end
					end
				end
			end
		end
	end
end)
