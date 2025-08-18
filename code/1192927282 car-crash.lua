---- Robust loader check (checks both PlaceId and GameId)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

---// Clean Loader Check (no debug prints/notifications)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- CONFIG: the ID you expect (PlaceId OR GameId)
local expectedId = 5683563195

-- Check match: true jika PlaceId atau GameId cocok
local matched = (tostring(game.PlaceId) == tostring(expectedId))
    or (tostring(game.GameId) == tostring(expectedId))

if not matched then
    -- Kalau tidak cocok, load fallback script dari GitHub
    local fallbackUrl = "https://raw.githubusercontent.com/BimaSkyy/all-in-one-SC-rubox/refs/heads/main/UI/1755511600.lua"
    local ok, err = pcall(function()
        local code = game:HttpGet(fallbackUrl)
        local fn = loadstring(code)
        if type(fn) == "function" then
            fn()
        end
    end)
    return -- stop script di sini
end

--// Elegant QuickLock UI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local targetPlayer, savePos

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuickLockGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- 🔮 Floating Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0.5, -22, 0.5, -22) -- center screen
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "🔮"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 26
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui

-- Round shape
local corner = Instance.new("UICorner", ToggleButton)
corner.CornerRadius = UDim.new(1,0)

-- Dragging logic
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	ToggleButton.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end
ToggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = ToggleButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
ToggleButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement 
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Search Frame
local SearchFrame = Instance.new("Frame", ScreenGui)
SearchFrame.Size = UDim2.new(0, 250, 0, 40)
SearchFrame.Position = UDim2.new(0.5, -125, 0.5, 35)
SearchFrame.BackgroundTransparency = 1
SearchFrame.Visible = false
SearchFrame.ZIndex = 10

-- Search Box
local SearchBox = Instance.new("TextBox", SearchFrame)
SearchBox.Size = UDim2.new(1, -60, 1, 0)
SearchBox.PlaceholderText = "Search player..."
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 16
SearchBox.Text = ""
SearchBox.ZIndex = 11
local scorner = Instance.new("UICorner", SearchBox)
scorner.CornerRadius = UDim.new(0,8)

-- Result Frame (Set button)
local ResultFrame = Instance.new("Frame", SearchFrame)
ResultFrame.Size = UDim2.new(0, 60, 1, 0)
ResultFrame.Position = UDim2.new(1, -60, 0, 0)
ResultFrame.BackgroundTransparency = 1
ResultFrame.ZIndex = 11

local ResultButtonTemplate = Instance.new("TextButton")
ResultButtonTemplate.Size = UDim2.new(1, 0, 1, 0)
ResultButtonTemplate.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
ResultButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
ResultButtonTemplate.Font = Enum.Font.GothamBold
ResultButtonTemplate.TextSize = 14
ResultButtonTemplate.Text = "Set"
ResultButtonTemplate.AutoButtonColor = false
ResultButtonTemplate.BorderSizePixel = 0
ResultButtonTemplate.ZIndex = 11
local rcorner = Instance.new("UICorner", ResultButtonTemplate)
rcorner.CornerRadius = UDim.new(0,8)

-- Action Button (Seruduk)
local SerudukButton = Instance.new("TextButton", ScreenGui)
SerudukButton.Size = UDim2.new(0, 110, 0, 32)
SerudukButton.Position = UDim2.new(0.5, -55, 0.5, 80)
SerudukButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
SerudukButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SerudukButton.Font = Enum.Font.GothamBold
SerudukButton.TextSize = 16
SerudukButton.Visible = false
SerudukButton.AutoButtonColor = false
SerudukButton.ZIndex = 10
local sbcorner = Instance.new("UICorner", SerudukButton)
sbcorner.CornerRadius = UDim.new(0,8)

-- Nametag function
local function createNametag(player)
	local function setupNametag(char)
		if not char then return end
		local head = char:FindFirstChild("Head")
		if not head then return end
		local old = head:FindFirstChild("QuickLockNametag")
		if old then old:Destroy() end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "QuickLockNametag"
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 100, 0, 20)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = math.huge
		billboard.Parent = head

		local label = Instance.new("TextLabel", billboard)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(0, 120, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextStrokeTransparency = 0.3
		label.Text = player.Name
	end

	if player.Character then setupNametag(player.Character) end
	player.CharacterAdded:Connect(function(c) task.wait(0.5); setupNametag(c) end)
end

for _, p in pairs(Players:GetPlayers()) do createNametag(p) end
Players.PlayerAdded:Connect(createNametag)

-- Helpers
local function clearResults()
	for _, c in pairs(ResultFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
end

local function showSearchResult(player)
	clearResults()
	local btn = ResultButtonTemplate:Clone()
	btn.Parent = ResultFrame
	btn.MouseButton1Click:Connect(function()
		targetPlayer = player
		SerudukButton.Text = "Target: " .. player.Name
		SerudukButton.Visible = true
		SearchFrame.Visible = false
		SearchBox.Text = ""
		clearResults()
	end)
end

local function searchPlayer(name)
	name = name:lower()
	clearResults()
	if name == "" then return end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Name:lower():find(name) then
			showSearchResult(p)
			return
		end
	end
end

-- Seruduk logic
local function serudukTarget()
	if not targetPlayer or not targetPlayer.Character then return end
	if not LocalPlayer.Character then return end
	local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then return end

	savePos = hrp.CFrame
	SerudukButton.Active = false

	hrp.CFrame = targetHRP.CFrame * CFrame.new(0,0,-2)
	local serudukCount, max = 0, 10
	local angle = 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if serudukCount >= max then
			conn:Disconnect()
			hrp.CFrame = savePos
			SerudukButton.Active = true
			return
		end
		local pos = targetHRP.Position
		angle = angle + math.rad(30)
		local offset = Vector3.new(math.cos(angle)*2,0,math.sin(angle)*2)
		hrp.CFrame = CFrame.new(pos+offset) * CFrame.Angles(0, angle+math.rad(180),0)
		serudukCount += 1
	end)
end

-- Events
ToggleButton.MouseButton1Click:Connect(function()
	SearchFrame.Visible = not SearchFrame.Visible
	if SearchFrame.Visible then SearchBox:CaptureFocus() else clearResults(); SearchBox.Text = "" end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchPlayer(SearchBox.Text)
end)

SerudukButton.MouseButton1Click:Connect(serudukTarget)
