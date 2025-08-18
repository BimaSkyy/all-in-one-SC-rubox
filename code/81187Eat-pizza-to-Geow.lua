--// Elegant Floating UI (Centered Small Button)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

-- Main Screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ElegantUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Floating Toggle Button (⚙️)
local mainButton = Instance.new("TextButton")
mainButton.Name = "MainButton"
mainButton.Size = UDim2.new(0, 38, 0, 38) -- lebih kecil
mainButton.Position = UDim2.new(0.5, -19, 0.5, -19) -- spawn di tengah layar
mainButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainButton.Text = "⚙️"
mainButton.Font = Enum.Font.GothamBold
mainButton.TextSize = 18
mainButton.TextColor3 = Color3.new(1,1,1)
mainButton.Parent = screenGui

-- Rounded circle button
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1,0)
corner.Parent = mainButton

-- Draggable logic
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	mainButton.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end
mainButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
mainButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Hidden Panel
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 95)
frame.Position = UDim2.new(0.5, -110, 0.25, 0) -- muncul agak atas
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BackgroundTransparency = 0.2
frame.Visible = false
frame.Parent = screenGui

local fcorner = Instance.new("UICorner", frame)
fcorner.CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(90,90,90)
stroke.Thickness = 1.5

-- Button factory
local function createButton(name, x, y)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(0, 100, 0, 35)
	btn.Position = UDim2.new(0, x, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	local c = Instance.new("UICorner", btn)
	c.CornerRadius = UDim.new(0,8)
	return btn
end

-- Buttons
local runBtn = createButton("Run x2", 5, 5)
local run10Btn = createButton("Run x10", 115, 5)
local autoEatBtn = createButton("Auto Eat", 5, 50)
local eatSpamBtn = createButton("Eat x10000", 115, 50)

-- Status
local autoEat = false
local runBoost = false
local runBoost10 = false

-- Toggle Panel
mainButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- Logic: Auto Eat
autoEatBtn.MouseButton1Click:Connect(function()
	autoEat = not autoEat
	autoEatBtn.BackgroundColor3 = autoEat and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
end)

-- Logic: Eat Spam
eatSpamBtn.MouseButton1Click:Connect(function()
	for i = 1, 2000 do
		RS.Msg[utf8.char(21507)]:FireServer("掉落物","6")
	end
end)

-- Logic: Run x2
runBtn.MouseButton1Click:Connect(function()
	runBoost = not runBoost
	runBoost10 = false
	runBtn.BackgroundColor3 = runBoost and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
	run10Btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
end)

-- Logic: Run x10
run10Btn.MouseButton1Click:Connect(function()
	runBoost10 = not runBoost10
	runBoost = false
	run10Btn.BackgroundColor3 = runBoost10 and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
	runBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
end)

-- Auto loops
task.spawn(function()
	while true do
		if autoEat then
			RS.Msg[utf8.char(21507)]:FireServer("掉落物","6")
			task.wait(0.02)
		else
			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	while true do
		local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			if runBoost then
				hum.WalkSpeed = 48
			elseif runBoost10 then
				hum.WalkSpeed = 160
			else
				hum.WalkSpeed = 16
			end
		end
		task.wait(0.2)
	end
end)
