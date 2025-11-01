-- ✅ Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- ✅ GUI Tombol Bulet 👻
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

local Button = Instance.new("TextButton")
Button.Parent = ScreenGui
Button.Size = UDim2.new(0, 50, 0, 50)
Button.Position = UDim2.new(1, -60, 0.5, -25)
Button.Text = "👻"
Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
Button.TextScaled = true
Button.Draggable = true

-- ✅ Variabel
local aktif = false
local savedCFrame
local antiGravityForce

-- ✅ Fungsi untuk mengaktifkan Anti-Gravitasi
local function enableAntiGravity()
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local hrp = character.HumanoidRootPart
		antiGravityForce = Instance.new("BodyForce")
		antiGravityForce.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity, 0) -- lawan gravitasi
		antiGravityForce.Parent = hrp
	end
end

-- ✅ Fungsi untuk menonaktifkan Anti-Gravitasi
local function disableAntiGravity()
	if antiGravityForce then
		antiGravityForce:Destroy()
		antiGravityForce = nil
	end
end

-- ✅ Fungsi untuk Freeze Camera
local function freezeCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
end

-- ✅ Fungsi untuk Reset Camera
local function resetCamera()
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
end

-- ✅ Fungsi Teleport Super Cepat Antar Player
local function startRandomTP()
	task.spawn(function()
		while aktif do
			local allPlayers = Players:GetPlayers()
			if #allPlayers > 1 then
				local target = allPlayers[math.random(1, #allPlayers)]
				if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if myHRP then
						-- Teleport ke bawah kaki player
						myHRP.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
					end
				end
			end
			RunService.Heartbeat:Wait() -- ganti target tiap frame = super cepat
		end
	end)
end

-- ✅ Klik Tombol
Button.MouseButton1Click:Connect(function()
	aktif = not aktif
	if aktif then
		-- Simpan posisi sebelum aktif
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			savedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
		end

		-- Aktifkan anti-gravitasi dulu
		enableAntiGravity()

		-- Freeze camera
		freezeCamera()

		-- Jalankan teleport super cepat
		startRandomTP()

		Button.BackgroundColor3 = Color3.fromRGB(0,200,0)
	else
		-- Balikin ke posisi semula
		if savedCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = savedCFrame
		end

		-- Matikan anti-gravitasi
		disableAntiGravity()

		resetCamera()
		Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
	end
end)
