-- skiddos
-- Instances:
-- not mine
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextButton = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")

--Properties:

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
Frame.BorderSizePixel = 2
Frame.Position = UDim2.new(0.34, 0, 0.37, 0)
Frame.Size = UDim2.new(0, 148, 0, 106)

TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BorderSizePixel = 2
TextButton.Position = UDim2.new(0.08, 0, 0.55, 0)
TextButton.Size = UDim2.new(0, 124, 0, 37)
TextButton.Font = Enum.Font.SourceSans
TextButton.Text = "OFF"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 41

TextLabel.Parent = Frame
TextLabel.BackgroundTransparency = 1
TextLabel.Position = UDim2.new(0.06, 0, 0.07, 0)
TextLabel.Size = UDim2.new(0, 128, 0, 39)
TextLabel.Font = Enum.Font.SourceSans
TextLabel.Text = "Touch Fling"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 34

-- Scripts:

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local toggleButton = TextButton
local hiddenfling = false
local movel = 0.1

-- Prevent duplicates
if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
	local marker = Instance.new("Folder")
	marker.Name = "juisdfj0i32i0eidsuf0iok"
	marker.Parent = ReplicatedStorage
end

-- Toggle fling
toggleButton.MouseButton1Click:Connect(function()
	hiddenfling = not hiddenfling
	toggleButton.Text = hiddenfling and "ON" or "OFF"
end)

-- Main fling loop (doesn't block game now)
RunService.Heartbeat:Connect(function()
	if not hiddenfling then return end

	local lp = Players.LocalPlayer
	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		local vel = hrp.Velocity

		hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
		RunService.RenderStepped:Wait()
		if hrp and hrp.Parent then
			hrp.Velocity = vel
		end

		RunService.Stepped:Wait()
		if hrp and hrp.Parent then
			hrp.Velocity = vel + Vector3.new(0, movel, 0)
			movel = -movel
		end
	end
end)

-- ✅ Mobile-friendly draggable GUI
local UserInputService = game:GetService("UserInputService")

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
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
		update(input)
	end
end)
