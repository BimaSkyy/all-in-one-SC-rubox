local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

-- 🧹 Bersihkan GUI lama
if playerGui:FindFirstChild("SpeedUI") then
	playerGui.SpeedUI:Destroy()
end

-- GUI utama
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- 🟩 Navigasi bar
local nav = Instance.new("Frame")
nav.Name = "NavBar"
nav.AnchorPoint = Vector2.new(1, 0)
nav.Position = UDim2.new(1, -20, 0, 20)
nav.Size = UDim2.new(0, 60, 0, 5)
nav.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
nav.BorderSizePixel = 0
nav.BackgroundTransparency = 0.2
nav.Parent = gui
nav.ClipsDescendants = true
nav.Active = true
Instance.new("UICorner", nav).CornerRadius = UDim.new(0, 3)

-- ⚙️ Panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 30)
panel.Size = UDim2.new(0, 200, 0, 40)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BackgroundTransparency = 0.3
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
panel.ClipsDescendants = true
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

-- 🔘 Tombol
local layout = Instance.new("UIListLayout", panel)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 6)
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeButton(txt)
	local b = Instance.new("TextButton")
	b.Text = txt
	b.Size = UDim2.new(0, 35, 0, 25)
	b.Font = Enum.Font.SourceSansSemibold
	b.TextSize = 16
	b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	return b
end

local plus = makeButton("+")
local minus = makeButton("-")
local set = makeButton("Set")
local reset = makeButton("Reset")

local num = Instance.new("TextLabel")
num.Size = UDim2.new(0, 40, 0, 25)
num.BackgroundTransparency = 1
num.TextColor3 = Color3.fromRGB(255, 255, 255)
num.Font = Enum.Font.GothamSemibold
num.TextSize = 16

plus.Parent = panel
num.Parent = panel
minus.Parent = panel
set.Parent = panel
reset.Parent = panel

-- 🧮 Logic Speed
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
local defaultSpeed = hum and hum.WalkSpeed or 16
local currentSpeed = defaultSpeed
num.Text = tostring(currentSpeed)

local function updateDisplay()
	num.Text = tostring(currentSpeed)
end

plus.MouseButton1Click:Connect(function()
	currentSpeed += 1
	updateDisplay()
end)

minus.MouseButton1Click:Connect(function()
	currentSpeed -= 1
	updateDisplay()
end)

set.MouseButton1Click:Connect(function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = currentSpeed end
end)

reset.MouseButton1Click:Connect(function()
	currentSpeed = defaultSpeed
	updateDisplay()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = defaultSpeed end
end)

-- 🎛️ Toggle panel
local isOpen = false
nav.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isOpen = not isOpen
		if isOpen then
			panel.Visible = true
			TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 200, 0, 35)}):Play()
		else
			TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 200, 0, 0)}):Play()
			task.wait(0.3)
			panel.Visible = false
		end
	end
end)

-- 🌈 Efek pulse + ganti warna
local colors = {
	Color3.fromRGB(255, 255, 255), -- putih
	Color3.fromRGB(0, 150, 255),   -- biru
	Color3.fromRGB(180, 0, 255),   -- ungu
	Color3.fromRGB(255, 60, 60),   -- merah
	Color3.fromRGB(60, 255, 120),  -- hijau
}
local colorIndex = 1

task.spawn(function()
	while task.wait(0.1) do
		-- 🔄 fade transparansi (kedap kedip)
		local fadeOut = TweenService:Create(nav, TweenInfo.new(0.6), {BackgroundTransparency = 0.8})
		local fadeIn = TweenService:Create(nav, TweenInfo.new(0.6), {BackgroundTransparency = 0.2})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		fadeIn:Play()

		-- 🎨 ubah warna setiap cycle
		colorIndex += 1
		if colorIndex > #colors then colorIndex = 1 end
		local nextColor = colors[colorIndex]
		TweenService:Create(nav, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = nextColor
		}):Play()
	end
end)
