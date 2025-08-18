--// Modern ESP GUI (English Only)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Main GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernESP"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- ESP Toggle Button
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 38, 0, 38)
Button.Position = UDim2.new(1, -45, 0, 10)
Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Button.Text = "👁️"
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.TextColor3 = Color3.new(1,1,1)
Button.Parent = ScreenGui

Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Button)
stroke.Color = Color3.fromRGB(90,90,90)
stroke.Thickness = 1.5

-- ESP Variables
local ESPEnabled = false
local ESPConnections = {}
local ESPLabels = {}

-- Create ESP for player
local function CreatePlayerESP(plr)
	if plr == LocalPlayer then return end

	local function SetupChar(char)
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		if char:FindFirstChild("ESPName") then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ESPName"
		billboard.Adornee = char:FindFirstChild("HumanoidRootPart")
		billboard.Size = UDim2.new(0, 200, 0, 25)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(0,255,0)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = plr.Name
		label.Parent = billboard

		billboard.Parent = char
		ESPLabels[plr] = label
	end

	-- setup for current character
	SetupChar(plr.Character)

	-- re-setup when respawn
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		SetupChar(char)
	end)
end

-- Remove ESP when player leaves
local function RemovePlayerESP(plr)
	if ESPLabels[plr] then
		ESPLabels[plr] = nil
	end
	if plr.Character and plr.Character:FindFirstChild("ESPName") then
		plr.Character.ESPName:Destroy()
	end
end

-- Enable ESP
local function EnableESP()
	for _, plr in pairs(Players:GetPlayers()) do
		CreatePlayerESP(plr)
	end
	ESPConnections.PlayerAdded = Players.PlayerAdded:Connect(CreatePlayerESP)
	ESPConnections.PlayerRemoving = Players.PlayerRemoving:Connect(RemovePlayerESP)

	-- Update info
	ESPConnections.Update = RunService.RenderStepped:Connect(function()
		local localChar = LocalPlayer.Character
		if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
		local localPos = localChar.HumanoidRootPart.Position

		for plr, label in pairs(ESPLabels) do
			local char = plr.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local dist = (char.HumanoidRootPart.Position - localPos).Magnitude
				local tool = char:FindFirstChildOfClass("Tool")
				local toolName = tool and tool.Name or "NULL"

				label.Text = string.format("%s | %s | %dm", plr.Name, toolName, math.floor(dist))
			end
		end
	end)
end

-- Disable ESP
local function DisableESP()
	for _, plr in pairs(Players:GetPlayers()) do
		RemovePlayerESP(plr)
	end
	ESPLabels = {}
	if ESPConnections.PlayerAdded then ESPConnections.PlayerAdded:Disconnect() end
	if ESPConnections.PlayerRemoving then ESPConnections.PlayerRemoving:Disconnect() end
	if ESPConnections.Update then ESPConnections.Update:Disconnect() end
end

-- Toggle ESP
Button.MouseButton1Click:Connect(function()
	ESPEnabled = not ESPEnabled
	if ESPEnabled then
		Button.BackgroundColor3 = Color3.fromRGB(0,200,0)
		EnableESP()
	else
		Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
		DisableESP()
	end
end)

-- Draggable Button (PC + Mobile)
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	Button.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

Button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Button.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
	   input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)
