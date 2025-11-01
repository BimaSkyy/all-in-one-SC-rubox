-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for local character
local function waitCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	return char, hum, hrp
end

local character, humanoid, hrp = waitCharacter()

-- === Config ===
local RADIUS = 100 -- stud radius
local VISIBLE_ROWS = 5
local ROW_HEIGHT = 24
local LIST_PADDING = 6

-- === GUI ===
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "ClueSystem_v4"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Main button
local mainButton = Instance.new("TextButton")
mainButton.Name = "MainButton"
mainButton.Size = UDim2.new(0,50,0,50)
mainButton.Position = UDim2.new(0.8,0,0.5,0)
mainButton.AnchorPoint = Vector2.new(0.5,0.5)
mainButton.Text = "✍️"
mainButton.TextScaled = true
mainButton.BackgroundColor3 = Color3.fromRGB(45,45,45)
mainButton.TextColor3 = Color3.fromRGB(255,255,255)
mainButton.Parent = gui
Instance.new("UICorner", mainButton).CornerRadius = UDim.new(1,0)

-- Container below main button (holds 3 buttons + separator + list)
local container = Instance.new("Frame", gui)
container.Name = "Container"
container.Size = UDim2.new(0,170,0, (50 + 10) + (3*48) + 8 + ((ROW_HEIGHT * VISIBLE_ROWS) + (LIST_PADDING*2)) )
container.BackgroundTransparency = 1
container.Position = UDim2.new(0.8,0,0.5,55)
container.Visible = false

-- small button creator
local function makeSmallBtn(text, color, posY)
	local b = Instance.new("TextButton", container)
	b.Size = UDim2.new(0,150,0,40)
	b.Position = UDim2.new(0,10,0,posY)
	b.Text = text
	b.TextScaled = true
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.BorderSizePixel = 0
	local c = Instance.new("UICorner", b)
	c.CornerRadius = UDim.new(0,6)
	return b
end

local makeBtn = makeSmallBtn("Make Clue", Color3.fromRGB(50,150,255), 6)
local delBtn = makeSmallBtn("Del Clue", Color3.fromRGB(220,60,60), 6 + 48)
local startBtn = makeSmallBtn("Start", Color3.fromRGB(70,200,70), 6 + 48*2)

-- separator
local separator = Instance.new("Frame", container)
separator.Size = UDim2.new(1,-20,0,2)
separator.Position = UDim2.new(0,10,0,6 + 48*3 + 4)
separator.BackgroundColor3 = Color3.fromRGB(255,255,255)
separator.BorderSizePixel = 0
Instance.new("UICorner", separator).CornerRadius = UDim.new(0,2)

-- List Scroller (under separator)
local listScroller = Instance.new("ScrollingFrame", container)
listScroller.Name = "PlayerList"
listScroller.Size = UDim2.new(1, -20, 0, (ROW_HEIGHT * VISIBLE_ROWS) + (LIST_PADDING*2))
listScroller.Position = UDim2.new(0,10,0,6 + 48*3 + 10)
listScroller.BackgroundColor3 = Color3.fromRGB(20,20,20)
listScroller.BorderSizePixel = 0
listScroller.CanvasSize = UDim2.new(0,0,0,0)
listScroller.ScrollBarThickness = 6
Instance.new("UICorner", listScroller).CornerRadius = UDim.new(0,6)

-- Layout for list
local listLayout = Instance.new("UIListLayout", listScroller)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0,4)

-- watch changes to layout to update CanvasSize
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	listScroller.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + LIST_PADDING)
end)

-- template for a single player row (not parented)
local function makePlayerRowTemplate()
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	frame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", frame)
	label.Name = "NameLabel"
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Position = UDim2.new(0,4,0,0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(230,230,230)
	label.Text = "PlayerName |"
	label.ClipsDescendants = true

	local btn = Instance.new("TextButton", frame)
	btn.Name = "TrackBtn"
	btn.Size = UDim2.new(0,26,0,20)
	btn.Position = UDim2.new(1, -30, 0, 2)
	btn.BackgroundColor3 = Color3.fromRGB(255,165,0)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Text = "⚡"
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

	return frame
end

-- === State ===
local cluePart = nil
local staticRunning = false
local staticMoveConn, staticNoclipConn = nil, nil

local followRunning = false
local followMoveConn, followNoclipConn, followTrackingConn = nil, nil, nil
local trackedPlayer = nil
local trackedDiedConn, trackedLeftConn, trackedCharRemovingConn = nil, nil, nil

local playerRows = {} -- map player.Name -> {Frame, Btn, Label}

-- === Utilities ===
local function notify(text)
	StarterGui:SetCore("SendNotification", {Title = "ClueSystem"; Text = text; Duration = 2})
end

-- create clue at position (radius RADIUS)
local function createClue(pos)
	if cluePart then cluePart:Destroy() cluePart = nil end
	local p = Instance.new("Part")
	p.Name = "ClueArea"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(RADIUS*2, RADIUS*2, RADIUS*2)
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(0,180,255)
	p.Transparency = 0.9
	p.Position = pos
	p.Parent = workspace
	cluePart = p
end

local function destroyClue()
	if cluePart then
		cluePart:Destroy()
		cluePart = nil
	end
end

-- noclip helper (returns connection)
local function enableNoclipForChar(char, activeFn)
	return RunService.Stepped:Connect(function()
		if not activeFn() then return end
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- chaos movement: getCenterFunc() should return Vector3 (center), stopFn() returns bool to stop
local function startChaosMovement(getCenterFunc, stopFn)
	local myChar = player.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
	local myRoot = myChar.HumanoidRootPart
	local myHum = myChar:FindFirstChildOfClass("Humanoid")
	if myHum then myHum.Sit = true end

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if stopFn() then
			conn:Disconnect()
			return
		end
		if not myRoot then return end
		local center = getCenterFunc()
		if not center then return end

		-- collect players inside radius for bounce points
		local targets = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
				local pos = pl.Character.HumanoidRootPart.Position
				if (pos - center).Magnitude <= RADIUS then
					table.insert(targets, pos)
				end
			end
		end

		local dest
		if #targets > 0 and math.random() < 0.6 then
			dest = targets[math.random(1,#targets)]
		else
			dest = center + Vector3.new(
				math.random(-RADIUS, RADIUS),
				math.random(-RADIUS, RADIUS),
				math.random(-RADIUS, RADIUS)
			)
		end

		local speed = math.random(300, 700) -- super fast
		myRoot.CFrame = myRoot.CFrame:Lerp(CFrame.new(dest), math.clamp(dt * speed, 0, 1))

		-- brutal spin
		local spin = math.rad(math.random(1200, 4000)) * dt
		myRoot.CFrame = myRoot.CFrame * CFrame.Angles(spin, spin, spin)

		if myHum then myHum.Sit = true end
	end)

	return conn
end

-- stop static mode
local function stopStaticMode()
	if staticMoveConn then staticMoveConn:Disconnect(); staticMoveConn = nil end
	if staticNoclipConn then staticNoclipConn:Disconnect(); staticNoclipConn = nil end
	staticRunning = false
	startBtn.Text = "Start"
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false end
end

-- start static mode (center = cluePart.Position)
local function startStaticMode()
	if staticRunning then
		stopStaticMode()
		return
	end
	if not cluePart then
		notify("Harap buat clue dahulu")
		return
	end

	staticRunning = true
	startBtn.Text = "Stop"

	-- noclip
	staticNoclipConn = enableNoclipForChar(player.Character, function() return staticRunning end)

	-- movement
	staticMoveConn = startChaosMovement(function()
		if cluePart then return cluePart.Position end
		return nil
	end, function() return not staticRunning end)

	notify("Static clue mode aktif")
end

-- === Tracking (follow) ===
local function cleanupTrackedConnections()
	if trackedDiedConn then trackedDiedConn:Disconnect(); trackedDiedConn = nil end
	if trackedLeftConn then trackedLeftConn:Disconnect(); trackedLeftConn = nil end
	if trackedCharRemovingConn then trackedCharRemovingConn:Disconnect(); trackedCharRemovingConn = nil end
	if followMoveConn then followMoveConn:Disconnect(); followMoveConn = nil end
	if followNoclipConn then followNoclipConn:Disconnect(); followNoclipConn = nil end
	if followTrackingConn then followTrackingConn:Disconnect(); followTrackingConn = nil end
end

local function stopTracking()
	if not trackedPlayer then return end

	-- reset UI
	local info = playerRows[trackedPlayer.Name]
	if info and info.Btn and info.Btn.Parent then
		info.Btn.Text = "⚡"
		info.Btn.BackgroundColor3 = Color3.fromRGB(255,165,0)
	end

	-- cleanup
	cleanupTrackedConnections()

	-- destroy clue
	destroyClue()

	-- stop chaos movement if running due to follow
	followRunning = false

	-- reset camera
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraType = Enum.CameraType.Custom
	end

	-- make sure startBtn text is correct
	startBtn.Text = "Start"

	trackedPlayer = nil
end

local function onTargetLeftOrDied()
	notify("Target hilang atau mati — follow dihentikan")
	stopTracking()
end

local function startTracking(target)
	if not target or target == player then return end

	-- if already tracking same, toggle off
	if trackedPlayer and trackedPlayer == target then
		stopTracking()
		return
	end

	-- stop previous if any
	if trackedPlayer then stopTracking() end

	-- check target valid
	if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		notify("Target belum siap")
		return
	end

	trackedPlayer = target
	followRunning = true

	-- update UI button
	local info = playerRows[target.Name]
	if info and info.Btn and info.Btn.Parent then
		info.Btn.Text = "🛑"
		info.Btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end

	-- set camera to target humanoid so you can rotate like normal
	local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
	if targetHum then
		camera.CameraSubject = targetHum
		camera.CameraType = Enum.CameraType.Custom
	end

	-- create clue at target pos
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if targetRoot then
		createClue(targetRoot.Position)
	else
		notify("Target tidak memiliki HRP")
		stopTracking()
		return
	end

	-- start noclip for our char
	followNoclipConn = enableNoclipForChar(player.Character, function() return followRunning end)

	-- start chaos movement centered on target HRP (dynamic)
	followMoveConn = startChaosMovement(function()
		if trackedPlayer and trackedPlayer.Character and trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
			return trackedPlayer.Character.HumanoidRootPart.Position
		end
		return nil
	end, function() return not followRunning end)

	-- trackingConn: update clue position & teleport our player to target pos each frame
	followTrackingConn = RunService.Stepped:Connect(function()
		if not followRunning or not trackedPlayer then
			return
		end
		if not trackedPlayer.Character or not trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
			-- target died or despawned
			onTargetLeftOrDied()
			return
		end

		local tRoot = trackedPlayer.Character.HumanoidRootPart
		-- move clue to target
		if cluePart then
			cluePart.Position = tRoot.Position
		end
		-- teleport our player to target pos each frame (so we "follow" their position)
		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if myRoot then
			myRoot.CFrame = tRoot.CFrame
		end
	end)

	-- listen for target death
	if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
		trackedDiedConn = target.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
			onTargetLeftOrDied()
		end)
	end

	-- listen for player leaving
	trackedLeftConn = Players.PlayerRemoving:Connect(function(rem)
		if rem == target then
			onTargetLeftOrDied()
		end
	end)

	-- if their character is removed then rebind death when respawn
	trackedCharRemovingConn = target.CharacterRemoving:Connect(function()
		-- wait a bit and rebind on new character
		spawn(function()
			wait(0.5)
			if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
				-- reconnect died
				local h = target.Character:FindFirstChildOfClass("Humanoid")
				if h then
					trackedDiedConn = h.Died:Connect(function() onTargetLeftOrDied() end)
				end
			end
		end)
	end)

	notify("Mengikuti " .. target.Name)
end

-- === Player list management ===
local function createPlayerRow(p)
	if p == player then return end
	-- avoid duplicates
	if playerRows[p.Name] then return end

	local template = makePlayerRowTemplate()
	template.Name = p.Name
	template.Parent = listScroller

	local label = template:FindFirstChild("NameLabel")
	local btn = template:FindFirstChild("TrackBtn")

	label.Text = p.Name .. " |"

	btn.MouseButton1Click:Connect(function()
		-- toggle follow
		if trackedPlayer and trackedPlayer == p then
			stopTracking()
		else
			startTracking(p)
		end
	end)

	playerRows[p.Name] = {Frame = template, Btn = btn, Label = label, Player = p}
end

local function removePlayerRow(p)
	if not p then return end
	local info = playerRows[p.Name]
	if info then
		if info.Frame and info.Frame.Parent then info.Frame:Destroy() end
		playerRows[p.Name] = nil
	end
	-- if we were tracking them, stop
	if trackedPlayer == p then
		stopTracking()
	end
end

local function refreshAllPlayers()
	-- create rows for all players (except local)
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player then
			createPlayerRow(pl)
		end
	end
	-- remove rows for players who left
	for name, info in pairs(playerRows) do
		local exists = false
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Name == name then exists = true break end
		end
		if not exists then
			removePlayerRow(info.Player)
		end
	end
end

-- initial populate
refreshAllPlayers()
-- connect add/remove
Players.PlayerAdded:Connect(function(pl)
	if pl ~= player then createPlayerRow(pl) end
end)
Players.PlayerRemoving:Connect(function(pl)
	removePlayerRow(pl)
end)

-- === Button behaviors ===
makeBtn.MouseButton1Click:Connect(function()
	-- cannot make clue while following someone else (we already create moving clue)
	if trackedPlayer then
		notify("Clue sedang mengikuti player. Hentikan tracking dahulu.")
		return
	end
	if cluePart then
		notify("Clue sudah di buat")
		return
	end
	if not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then return end
	createClue(player.Character.HumanoidRootPart.Position)
	notify("Clue dibuat (radius " .. RADIUS .. " stud)")
end)

delBtn.MouseButton1Click:Connect(function()
	if trackedPlayer then
		stopTracking()
		return
	end
	if cluePart then
		destroyClue()
		stopStaticMode()
		notify("Clue dihapus")
	else
		notify("Tidak ada clue untuk dihapus")
	end
end)

startBtn.MouseButton1Click:Connect(function()
	-- if following mode active, tell user to use Del Clue to stop
	if trackedPlayer then
		notify("Chaos Mode mengikuti player. Gunakan 'Del Clue' untuk menghentikan.")
		return
	end

	if staticRunning then
		stopStaticMode()
		return
	end

	if not cluePart then
		notify("Harap buat clue dahulu")
		return
	end

	startStaticMode()
end)

-- === Drag system (mobile-friendly) ===
do
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function updateDrag(input)
		if not dragStart or not startPos then return end
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
		mainButton.Position = newPos
		container.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset, newPos.Y.Scale, newPos.Y.Offset + 55)
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

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			pcall(updateDrag, input)
		end
	end)
end

-- toggle container visibility
mainButton.MouseButton1Click:Connect(function()
	container.Visible = not container.Visible
end)

-- cleanup on local death/respawn
humanoid.Died:Connect(function()
	-- stop everything
	if staticRunning then stopStaticMode() end
	if trackedPlayer then stopTracking() end

	wait(2)
	character, humanoid, hrp = waitCharacter()
end)

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	hrp = newChar:WaitForChild("HumanoidRootPart")
	-- reset camera subject
	if camera and humanoid then camera.CameraSubject = humanoid end
	-- stop modes to avoid weirdness
	if staticRunning then stopStaticMode() end
	if trackedPlayer then stopTracking() end
end)
