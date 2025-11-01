-- ✅ LocalScript dalam StarterGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Buat GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame kecil kanan atas
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 40)
frame.Position = UDim2.new(1, -210, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BackgroundTransparency = 0.2
frame.Parent = screenGui

-- TextBox untuk input ID
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.7, -5, 1, -10)
textBox.Position = UDim2.new(0, 5, 0, 5)
textBox.PlaceholderText = "Masukkan ID animasi"
textBox.Text = ""
textBox.ClearTextOnFocus = false
textBox.Parent = frame

-- Tombol Try/Stop
local button = Instance.new("TextButton")
button.Size = UDim2.new(0.3, -5, 1, -10)
button.Position = UDim2.new(0.7, 0, 0, 5)
button.Text = "Try"
button.Parent = frame

-- Variabel animasi
local loadedAnim

-- Fungsi klik tombol
button.MouseButton1Click:Connect(function()
	if button.Text == "Try" then
		local animId = textBox.Text
		if animId ~= "" then
			-- Pastikan karakter ada
			character = player.Character or player.CharacterAdded:Wait()
			humanoid = character:WaitForChild("Humanoid")

			-- Buat animasi
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://"..animId

			-- Load animasi
			loadedAnim = humanoid:LoadAnimation(animation)
			loadedAnim:Play()

			-- Ubah tombol ke Stop
			button.Text = "Stop"
		end
	else
		-- Stop animasi
		if loadedAnim then
			loadedAnim:Stop()
			loadedAnim = nil
		end
		button.Text = "Try"
	end
end)
