local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local UIS = game:GetService("UserInputService")

local coinsFolder = game:GetService("Workspace"):WaitForChild("Coins")

-- Function to teleport to all existing coins
local function tpToCoins()
    for _, coin in pairs(coinsFolder:GetDescendants()) do
        if coin:IsA("BasePart") and coin.Name == "Coin" and coin:IsDescendantOf(coinsFolder) then
            -- Teleport slightly above the coin
            hrp.CFrame = coin.CFrame + Vector3.new(0, 5, 0)
            task.wait(0.2) -- small delay between each
        end
    end
end

-- F6 Keybind
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F6 then
        tpToCoins()
    end
end)
