-- ✅ Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer

-- ✅ Wait Character
local function waitCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	return char, hum, hrp
end

local character, humanoid, hrp = waitCharacter()

-- ✅ GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TPToolsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- ✅ Style Helper
local function makeButton(name, text, color, parent)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 50, 0, 50)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = color
	btn.AutoButtonColor = true
	btn.Parent = parent

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 1.3
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.4

	return btn
end

-- ✅ Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 60, 0, 60)
mainFrame.Position = UDim2.new(0, 100, 0.4, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = gui

-- ✅ Tombol utama
local mainButton = makeButton("Main", "TP", Color3.fromRGB(0, 120, 255), mainFrame)
mainButton.Position = UDim2.new(0, 0, 0, 0)

-- ✅ Tombol lain
local frButton = makeButton("FR", "FR", Color3.fromRGB(0, 200, 100), mainFrame)
local tpButton = makeButton("TPto", "TP", Color3.fromRGB(255, 140, 0), mainFrame)
local upButton = makeButton("Up", "+", Color3.fromRGB(0, 180, 0), mainFrame)
local downButton = makeButton("Down", "-", Color3.fromRGB(180, 0, 0), mainFrame)

frButton.Visible = false
tpButton.Visible = false
upButton.Visible = false
downButton.Visible = false

-- ✅ DRAG SYSTEM (Fix Android)
local dragging = false
local dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	local newPos = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
	mainFrame.Position = newPos
end

mainButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)

-- ✅ Variabel kontrol
local controllingBall = false
local ball
local ballSpeed = 60
local verticalMove = 0

-- ✅ Spawn bola
local function spawnBall()
	if ball then ball:Destroy() end
	ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 255, 255)
	ball.Anchored = false
	ball.CanCollide = false
	ball.Position = hrp.Position + Vector3.new(0, 3, 0)
	ball.Parent = workspace

	local att = Instance.new("Attachment", ball)
	local lv = Instance.new("LinearVelocity", ball)
	lv.Attachment0 = att
	lv.MaxForce = 1e9
	lv.VectorVelocity = Vector3.zero
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
end

-- ✅ Layout tombol bawah
local function updateLayout()
	local spacing = 55
	frButton.Position = UDim2.new(0, 0, 0, spacing)
	tpButton.Position = UDim2.new(0, 0, 0, spacing * 2)
	upButton.Position = UDim2.new(0, 60, 0, spacing * 2)
	downButton.Position = UDim2.new(0, 120, 0, spacing * 2)
end

-- ✅ Toggle tombol tambahan
mainButton.MouseButton1Click:Connect(function()
	local visible = not frButton.Visible
	frButton.Visible = visible
	tpButton.Visible = visible
	updateLayout()

	TweenService:Create(mainButton, TweenInfo.new(0.2), {
		BackgroundColor3 = visible and Color3.fromRGB(0,180,255) or Color3.fromRGB(0,120,255)
	}):Play()
end)

-- ✅ FR toggle
frButton.MouseButton1Click:Connect(function()
	controllingBall = not controllingBall
	if controllingBall then
		spawnBall()
		Camera.CameraSubject = ball
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		upButton.Visible = true
		downButton.Visible = true
	else
		if ball then ball:Destroy() end
		Camera.CameraSubject = humanoid
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		upButton.Visible = false
		downButton.Visible = false
		verticalMove = 0
	end
	updateLayout()
end)

-- ✅ TP ke bola
tpButton.MouseButton1Click:Connect(function()
	if ball and ball.Parent then
		hrp.CFrame = CFrame.new(ball.Position)
	end
end)

-- ✅ + / - control
upButton.MouseButton1Down:Connect(function() verticalMove = 1 end)
upButton.MouseButton1Up:Connect(function() verticalMove = 0 end)
downButton.MouseButton1Down:Connect(function() verticalMove = -1 end)
downButton.MouseButton1Up:Connect(function() verticalMove = 0 end)

-- ✅ Gerak bola
RunService.RenderStepped:Connect(function()
	if controllingBall and ball and ball:FindFirstChild("LinearVelocity") then
		local moveDir = humanoid.MoveDirection
		local final = Vector3.new(moveDir.X, verticalMove, moveDir.Z)
		if final.Magnitude > 0 then
			ball.LinearVelocity.VectorVelocity = final.Unit * ballSpeed
		else
			ball.LinearVelocity.VectorVelocity = Vector3.zero
		end
	end
end)

-- ✅ Reset kalau mati
humanoid.Died:Connect(function()
	if controllingBall then
		controllingBall = false
		if ball then ball:Destroy() end
	end
	upButton.Visible = false
	downButton.Visible = false
	Camera.CameraSubject = humanoid
	task.wait(3)
	character, humanoid, hrp = waitCharacter()
end)

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	hrp = newChar:WaitForChild("HumanoidRootPart")
	Camera.CameraSubject = humanoid
	upButton.Visible = false
	downButton.Visible = false
end)
