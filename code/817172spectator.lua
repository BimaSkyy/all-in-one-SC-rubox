-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- UI
local screenGui = Instance.new("ScreenGui", player.PlayerGui)

local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Size = UDim2.new(0, 60, 0, 30)
toggleButton.Position = UDim2.new(1, -70, 0.4, 0)
toggleButton.Text = "OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)

local tpButton = Instance.new("TextButton", screenGui)
tpButton.Size = UDim2.new(0, 60, 0, 30)
tpButton.Position = UDim2.new(1, -70, 0.45, 0)
tpButton.Text = "TP"
tpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
tpButton.TextColor3 = Color3.new(1, 1, 1)

-- Tombol baru untuk kontrol vertikal
local upButton = Instance.new("TextButton", screenGui)
upButton.Size = UDim2.new(0, 40, 0, 40)
upButton.Position = UDim2.new(1, -50, 1, -100) -- Kanan bawah
upButton.Text = "+"
upButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
upButton.TextColor3 = Color3.new(1, 1, 1)
upButton.Visible = false

local downButton = Instance.new("TextButton", screenGui)
downButton.Size = UDim2.new(0, 40, 0, 40)
downButton.Position = UDim2.new(1, -50, 1, -55) -- Kanan bawah
downButton.Text = "-"
downButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
downButton.TextColor3 = Color3.new(1, 1, 1)
downButton.Visible = false

-- Variabel
local controllingBall = false
local ball
local ballSpeed = 50
local verticalMove = 0

-- Fungsi spawn bola
local function spawnBall()
	if ball then ball:Destroy() end
	ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Color = Color3.fromRGB(255, 255, 255)
	ball.Anchored = false
	ball.CanCollide = false
	ball.Position = hrp.Position + Vector3.new(0, 3, 0)
	ball.Parent = workspace
	local bv = Instance.new("BodyVelocity", ball)
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Velocity = Vector3.zero
end

-- Kontrol vertikal melalui tombol
upButton.MouseButton1Down:Connect(function()
	verticalMove = 1
end)
upButton.MouseButton1Up:Connect(function()
	verticalMove = 0
end)

downButton.MouseButton1Down:Connect(function()
	verticalMove = -1
end)
downButton.MouseButton1Up:Connect(function()
	verticalMove = 0
end)

-- Tombol ON/OFF
toggleButton.MouseButton1Click:Connect(function()
	controllingBall = not controllingBall
	if controllingBall then
		toggleButton.Text = "ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		spawnBall()
		Camera.CameraSubject = ball
		-- Tampilkan tombol vertikal
		upButton.Visible = true
		downButton.Visible = true
	else
		toggleButton.Text = "OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		if ball then ball:Destroy() end
		Camera.CameraSubject = humanoid
		-- Sembunyikan tombol vertikal
		upButton.Visible = false
		downButton.Visible = false
		verticalMove = 0
	end
end)

-- Tombol TP
tpButton.MouseButton1Click:Connect(function()
	if ball and ball.Parent then
		hrp.CFrame = CFrame.new(ball.Position)
	end
end)

-- Loop untuk pergerakan bola
RunService.RenderStepped:Connect(function()
	if controllingBall and ball and ball:FindFirstChildOfClass("BodyVelocity") then
		local moveDir = humanoid.MoveDirection
		
		-- Buat vektor gerakan horizontal dari analog
		local horizontalDir = Vector3.new(moveDir.X, 0, moveDir.Z)
		
		-- Buat vektor gerakan vertikal dari tombol
		local verticalDir = Vector3.new(0, verticalMove, 0)
		
		-- Gabungkan gerakan horizontal dan vertikal
		local finalMove = (horizontalDir + verticalDir)
		
		if finalMove.Magnitude > 0 then
			ball.BodyVelocity.Velocity = finalMove.Unit * ballSpeed
		else
			ball.BodyVelocity.Velocity = Vector3.zero
		end
	end
end)
