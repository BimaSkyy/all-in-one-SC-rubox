--// Dupe Button GUI
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "DupeGui"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

-- Create draggable button
local button = Instance.new("TextButton")
button.Name = "DupeButton"
button.Parent = gui
button.Text = "DUPE"
button.Size = UDim2.new(0, 60, 0, 60) -- smaller size
button.Position = UDim2.new(0.85, 0, 0.5, 0) -- right side
button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0) -- full circle
corner.Parent = button

-- Make button draggable (works on PC and mobile)
local dragging, dragInput, mousePos, framePos

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		mousePos = input.Position
		framePos = button.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		button.Position = UDim2.new(
			framePos.X.Scale, framePos.X.Offset + delta.X,
			framePos.Y.Scale, framePos.Y.Offset + delta.Y
		)
	end
end)

-- Fake dupe logic
local function dupeItem()
	local char = player.Character
	if not char then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		-- Clone tool
		local clone = tool:Clone()
		clone.Parent = player.Backpack

		-- Notify
		game.StarterGui:SetCore("SendNotification", {
			Title = "Success!",
			Text = "Item duplicated successfully 🎉",
			Duration = 3
		})
	else
		game.StarterGui:SetCore("SendNotification", {
			Title = "Error",
			Text = "No item equipped",
			Duration = 3
		})
	end
end

button.MouseButton1Click:Connect(dupeItem)
