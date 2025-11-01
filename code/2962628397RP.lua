-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- helper sound
local function playSound(soundId)
    local ok, _ = pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. soundId
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end)
end
playSound("2865227271") -- startup sound

---
---
local force = 80
local ringPartsEnabled = false
local radius = 50
local rotationSpeed = 10
local attractionStrength = 1000

local spinSpeed = 200

local modes = {
    "Orbit Player",
    "Dorong Atas",
    "Dorong Kanan",
    "Dorong Kiri",
    "Memutar",
    "Dorong Depan"
}
local modeIndex = 1

-- Orbit target (nil = orbit ke self)
local selectedPlayer = nil

---
---
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }
    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
        end
    end
    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = workspace
        RunService.Heartbeat:Connect(function()
            pcall(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                for _, Part in pairs(Network.BaseParts) do
                    if Part:IsDescendantOf(workspace) then
                        Part.Velocity = Network.Velocity
                    end
                end
            end)
        end)
    end
    EnablePartControl()
end

---
---
local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end
        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        return true
    end
    return false
end

local parts = {}
local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end
local function removePart(part)
    local idx = table.find(parts, part)
    if idx then table.remove(parts, idx) end
end

for _, part in pairs(workspace:GetDescendants()) do addPart(part) end
workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

---
---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingPartsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 300)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(205, 170, 125)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 20)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "Super Ring Parts v3"
Title.TextColor3 = Color3.fromRGB(101, 67, 33)
Title.BackgroundColor3 = Color3.fromRGB(222, 184, 135)
Title.Font = Enum.Font.Fondamento
Title.TextSize = 22
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 20)
TitleCorner.Parent = Title

-- Toggle
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0.16, 0)
ToggleButton.Text = "Ring Parts Off"
ToggleButton.BackgroundColor3 = Color3.fromRGB(160, 82, 45)
ToggleButton.TextColor3 = Color3.fromRGB(255, 248, 220)
ToggleButton.Font = Enum.Font.Fondamento
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame
local ToggleCorner = Instance.new("UICorner"); ToggleCorner.CornerRadius = UDim.new(0,10); ToggleCorner.Parent = ToggleButton

-- Mode controls
local ModePrev = Instance.new("TextButton")
ModePrev.Size = UDim2.new(0.2, 0, 0, 28)
ModePrev.Position = UDim2.new(0.05, 0, 0.44, 0)
ModePrev.Text = "<"
ModePrev.Font = Enum.Font.Fondamento
ModePrev.TextSize = 16
ModePrev.BackgroundColor3 = Color3.fromRGB(139,69,19)
ModePrev.TextColor3 = Color3.fromRGB(255,248,220)
ModePrev.Parent = MainFrame
local ModePrevCorner = Instance.new("UICorner"); ModePrevCorner.CornerRadius = UDim.new(0,10); ModePrevCorner.Parent = ModePrev

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(0.5, 0, 0, 28)
ModeLabel.Position = UDim2.new(0.25, 0, 0.44, 0)
ModeLabel.Text = "Mode: " .. modes[modeIndex]
ModeLabel.BackgroundColor3 = Color3.fromRGB(210,180,140)
ModeLabel.TextColor3 = Color3.fromRGB(101,67,33)
ModeLabel.Font = Enum.Font.Fondamento
ModeLabel.TextSize = 14
ModeLabel.Parent = MainFrame
local ModeLabelCorner = Instance.new("UICorner"); ModeLabelCorner.CornerRadius = UDim.new(0,10); ModeLabelCorner.Parent = ModeLabel

local ModeNext = Instance.new("TextButton")
ModeNext.Size = UDim2.new(0.2, 0, 0, 28)
ModeNext.Position = UDim2.new(0.75, 0, 0.44, 0)
ModeNext.Text = ">"
ModeNext.Font = Enum.Font.Fondamento
ModeNext.TextSize = 16
ModeNext.BackgroundColor3 = Color3.fromRGB(139,69,19)
ModeNext.TextColor3 = Color3.fromRGB(255,248,220)
ModeNext.Parent = MainFrame
local ModeNextCorner = Instance.new("UICorner"); ModeNextCorner.CornerRadius = UDim.new(0,10); ModeNextCorner.Parent = ModeNext

-- Force controls
local DecreaseBtn = Instance.new("TextButton")
DecreaseBtn.Size = UDim2.new(0.22, 0, 0, 34)
DecreaseBtn.Position = UDim2.new(0.05, 0, 0.62, 0)
DecreaseBtn.Text = "<"
DecreaseBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
DecreaseBtn.TextColor3 = Color3.fromRGB(255, 248, 220)
DecreaseBtn.Font = Enum.Font.Fondamento
DecreaseBtn.TextSize = 18
DecreaseBtn.Parent = MainFrame
local DecreaseCorner = Instance.new("UICorner"); DecreaseCorner.CornerRadius = UDim.new(0,10); DecreaseCorner.Parent = DecreaseBtn

local IncreaseBtn = Instance.new("TextButton")
IncreaseBtn.Size = UDim2.new(0.22, 0, 0, 34)
IncreaseBtn.Position = UDim2.new(0.74, 0, 0.62, 0)
IncreaseBtn.Text = ">"
IncreaseBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
IncreaseBtn.TextColor3 = Color3.fromRGB(255, 248, 220)
IncreaseBtn.Font = Enum.Font.Fondamento
IncreaseBtn.TextSize = 18
IncreaseBtn.Parent = MainFrame
local IncreaseCorner = Instance.new("UICorner"); IncreaseCorner.CornerRadius = UDim.new(0,10); IncreaseCorner.Parent = IncreaseBtn

local ForceDisplay = Instance.new("TextLabel")
ForceDisplay.Size = UDim2.new(0.46, 0, 0, 34)
ForceDisplay.Position = UDim2.new(0.27, 0, 0.62, 0)
ForceDisplay.Text = "Force: " .. force
ForceDisplay.BackgroundColor3 = Color3.fromRGB(210, 180, 140)
ForceDisplay.TextColor3 = Color3.fromRGB(101, 67, 33)
ForceDisplay.Font = Enum.Font.Fondamento
ForceDisplay.TextSize = 16
ForceDisplay.Parent = MainFrame
local ForceCorner = Instance.new("UICorner"); ForceCorner.CornerRadius = UDim.new(0,10); ForceCorner.Parent = ForceDisplay

-- Spin controls
local SpinPanel = Instance.new("Frame")
SpinPanel.Size = UDim2.new(0, 200, 0, 46)
SpinPanel.Position = UDim2.new(0.5, -100, 0.75, -10)
SpinPanel.BackgroundColor3 = Color3.fromRGB(222, 184, 135)
SpinPanel.Parent = MainFrame
SpinPanel.Visible = false
local SpinPanelCorner = Instance.new("UICorner"); SpinPanelCorner.CornerRadius = UDim.new(0,12); SpinPanelCorner.Parent = SpinPanel

local SpinPrev = Instance.new("TextButton")
SpinPrev.Size = UDim2.new(0.22, 0, 0, 34)
SpinPrev.Position = UDim2.new(0.02, 0, 0.1, 0)
SpinPrev.Text = "<"
SpinPrev.Font = Enum.Font.Fondamento
SpinPrev.TextSize = 14
SpinPrev.BackgroundColor3 = Color3.fromRGB(139,69,19)
SpinPrev.TextColor3 = Color3.fromRGB(255,248,220)
SpinPrev.Parent = SpinPanel
local SpinPrevCorner = Instance.new("UICorner"); SpinPrevCorner.CornerRadius = UDim.new(0,8); SpinPrevCorner.Parent = SpinPrev

local SpinLabel = Instance.new("TextLabel")
SpinLabel.Size = UDim2.new(0.56, 0, 0, 34)
SpinLabel.Position = UDim2.new(0.24, 0, 0.1, 0)
SpinLabel.Text = "Spin: " .. spinSpeed
SpinLabel.BackgroundTransparency = 1
SpinLabel.TextColor3 = Color3.fromRGB(101,67,33)
SpinLabel.Font = Enum.Font.Fondamento
SpinLabel.TextSize = 14
SpinLabel.Parent = SpinPanel

local SpinNext = Instance.new("TextButton")
SpinNext.Size = UDim2.new(0.22, 0, 0, 34)
SpinNext.Position = UDim2.new(0.76, 0, 0.1, 0)
SpinNext.Text = ">"
SpinNext.Font = Enum.Font.Fondamento
SpinNext.TextSize = 14
SpinNext.BackgroundColor3 = Color3.fromRGB(139,69,19)
SpinNext.TextColor3 = Color3.fromRGB(255,248,220)
SpinNext.Parent = SpinPanel
local SpinNextCorner = Instance.new("UICorner"); SpinNextCorner.CornerRadius = UDim.new(0,8); SpinNextCorner.Parent = SpinNext

-- Watermark
local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, 0, 0, 20)
Watermark.Position = UDim2.new(0, 0, 1, -20)
Watermark.Text = "Super Ring [V3] - Cracked By Projeto LKB"
Watermark.TextColor3 = Color3.fromRGB(101, 67, 33)
Watermark.BackgroundTransparency = 1
Watermark.Font = Enum.Font.Fondamento
Watermark.TextSize = 14
Watermark.Parent = MainFrame

-- Minimize
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
MinimizeButton.Text = "-"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
MinimizeButton.TextColor3 = Color3.fromRGB(255, 248, 220)
MinimizeButton.Font = Enum.Font.Fondamento
MinimizeButton.TextSize = 18
MinimizeButton.Parent = MainFrame
local MinimizeCorner = Instance.new("UICorner"); MinimizeCorner.CornerRadius = UDim.new(0,15); MinimizeCorner.Parent = MinimizeButton

local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0,220,0,60),"Out","Quad",0.25,true)
        MinimizeButton.Text = "+"
        ToggleButton.Visible = false
        DecreaseBtn.Visible = false
        IncreaseBtn.Visible = false
        ForceDisplay.Visible = false
        ModePrev.Visible = false
        ModeNext.Visible = false
        ModeLabel.Visible = false
        SpinPanel.Visible = false
        Watermark.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0,220,0,300),"Out","Quad",0.25,true)
        MinimizeButton.Text = "-"
        ToggleButton.Visible = true
        DecreaseBtn.Visible = true
        IncreaseBtn.Visible = true
        ForceDisplay.Visible = true
        ModePrev.Visible = true
        ModeNext.Visible = true
        ModeLabel.Visible = true
        Watermark.Visible = true
        -- show spin only if in Memutar
        if modes[modeIndex] == "Memutar" then
            SpinPanel.Visible = true
        end
    end
    playSound("12221967")
end)

-- Dragging MainFrame
local dragging; local dragInput; local dragStart; local startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

---
---
local playerListGui -- holds the ScreenGui instance for list
local playerListFrame -- The main frame of the player list
local playerListMinimized = false
local selectedPlayerTick = nil -- Reference to the green tick mark
local lastSelectedButton = nil -- Reference to the last clicked button

local function updateTickMark()
    -- Clear previous tick mark
    if selectedPlayerTick and selectedPlayerTick.Parent then
        selectedPlayerTick:Destroy()
        selectedPlayerTick = nil
    end

    -- Add new tick mark if a player is selected and their button exists
    if selectedPlayer and lastSelectedButton then
        selectedPlayerTick = Instance.new("TextLabel")
        selectedPlayerTick.Size = UDim2.new(0, 20, 0, 20)
        selectedPlayerTick.Position = UDim2.new(0, 4, 0.5, -10)
        selectedPlayerTick.BackgroundColor3 = Color3.fromRGB(85, 170, 85) -- Green background
        selectedPlayerTick.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectedPlayerTick.Text = "✔"
        selectedPlayerTick.Font = Enum.Font.SourceSansBold
        selectedPlayerTick.TextSize = 16
        selectedPlayerTick.TextScaled = false
        selectedPlayerTick.Parent = lastSelectedButton

        local tickCorner = Instance.new("UICorner")
        tickCorner.CornerRadius = UDim.new(0, 4)
        tickCorner.Parent = selectedPlayerTick
    end
end

local function createPlayerListGui()
    if playerListGui then return end

    playerListGui = Instance.new("ScreenGui")
    playerListGui.Name = "SR_PlayerList"
    playerListGui.ResetOnSpawn = false
    playerListGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(0, 140, 0, 240)
    playerListFrame.Position = UDim2.new(1, -150, 0.25, 0)
    playerListFrame.AnchorPoint = Vector2.new(0,0)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(230, 217, 200)
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = playerListGui
    local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0,14); oc.Parent = playerListFrame

    -- Minimize button for player list
    local MinimizeListBtn = Instance.new("TextButton")
    MinimizeListBtn.Size = UDim2.new(0, 20, 0, 20)
    MinimizeListBtn.Position = UDim2.new(1, -25, 0, 5)
    MinimizeListBtn.Text = "-"
    MinimizeListBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
    MinimizeListBtn.TextColor3 = Color3.fromRGB(255, 248, 220)
    MinimizeListBtn.Font = Enum.Font.Fondamento
    MinimizeListBtn.TextSize = 18
    MinimizeListBtn.Parent = playerListFrame
    local minCorner = Instance.new("UICorner"); minCorner.CornerRadius = UDim.new(0,10); minCorner.Parent = MinimizeListBtn

    local title = Instance.new("TextLabel")
    title.Name = "TitleLabel"
    title.Size = UDim2.new(1, -12, 0, 30)
    title.Position = UDim2.new(0, 6, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Players"
    title.Font = Enum.Font.Fondamento
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(80,50,30)
    title.Parent = playerListFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -12, 0, 28)
    searchBox.Position = UDim2.new(0, 6, 0, 40)
    searchBox.PlaceholderText = "Search..."
    searchBox.Text = ""
    searchBox.Font = Enum.Font.Fondamento
    searchBox.TextSize = 14
    searchBox.TextColor3 = Color3.fromRGB(50,50,50)
    searchBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
    searchBox.Parent = playerListFrame
    local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0,10); sbc.Parent = searchBox

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ScrollFrame"
    scroll.Size = UDim2.new(1, -12, 0, 150)
    scroll.Position = UDim2.new(0, 6, 0, 74)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1
    scroll.Parent = playerListFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scroll
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0,6)

    -- update canvas size automatically
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)

    local function buildList(filter)
        -- clear
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local lowerFilter = filter and string.lower(filter) or ""
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local name = plr.Name or plr.DisplayName or "Player"
                if lowerFilter == "" or string.find(string.lower(name), lowerFilter, 1, true) or string.find(string.lower(plr.DisplayName or ""), lowerFilter, 1, true) then
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 34)
                    btn.BackgroundColor3 = Color3.fromRGB(245, 240, 235)
                    btn.Text = "" -- Text will be handled by a label
                    btn.Parent = scroll
                    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0,17); btnCorner.Parent = btn

                    -- Text label for the name
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, -30, 1, 0)
                    nameLabel.Position = UDim2.new(0, 30, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextColor3 = Color3.fromRGB(60,40,30)
                    nameLabel.Text = name
                    nameLabel.Font = Enum.Font.Fondamento
                    nameLabel.TextSize = 13
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Parent = btn

                    -- Small avatar circle on left
                    local avatar = Instance.new("Frame")
                    avatar.Size = UDim2.new(0, 28, 0, 28)
                    avatar.Position = UDim2.new(0, 6, 0, 3)
                    avatar.BackgroundColor3 = Color3.fromRGB(200,180,160)
                    avatar.Parent = btn
                    local avc = Instance.new("UICorner"); avc.CornerRadius = UDim.new(0,14); avc.Parent = avatar

                    -- click choose
                    btn.MouseButton1Click:Connect(function()
                        selectedPlayer = plr
                        lastSelectedButton = btn
                        playSound("12221967")
                        updateTickMark()
                    end)

                    -- Check if this is the currently selected player and add a tick
                    if selectedPlayer == plr then
                        lastSelectedButton = btn
                        updateTickMark()
                    end
                end
            end
        end
    end

    -- Dragging PlayerListFrame
    local draggingPL; local dragInputPL; local dragStartPL; local startPosPL
    local function updatePL(input)
        local delta = input.Position - dragStartPL
        playerListFrame.Position = UDim2.new(startPosPL.X.Scale, startPosPL.X.Offset + delta.X, startPosPL.Y.Scale, startPosPL.Y.Offset + delta.Y)
    end
    playerListFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingPL = true; dragStartPL = input.Position; startPosPL = playerListFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then draggingPL = false end end)
        end
    end)
    playerListFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInputPL = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInputPL and draggingPL then updatePL(input) end end)

    MinimizeListBtn.MouseButton1Click:Connect(function()
        playerListMinimized = not playerListMinimized
        if playerListMinimized then
            playerListFrame:TweenSize(UDim2.new(0,140,0,40),"Out","Quad",0.25,true)
            MinimizeListBtn.Text = "+"
            searchBox.Visible = false
            scroll.Visible = false
        else
            playerListFrame:TweenSize(UDim2.new(0,140,0,240),"Out","Quad",0.25,true)
            MinimizeListBtn.Text = "-"
            searchBox.Visible = true
            scroll.Visible = true
        end
        playSound("12221967")
    end)


    -- initial build
    buildList("")

    -- connections
    local addedConn = Players.PlayerAdded:Connect(function() buildList(searchBox.Text) end)
    local removedConn = Players.PlayerRemoving:Connect(function(plr)
        if selectedPlayer == plr then
            selectedPlayer = nil
            lastSelectedButton = nil
            updateTickMark()
        end
        buildList(searchBox.Text)
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        buildList(searchBox.Text)
    end)

    -- cleanup when hiding
    playerListGui.Destroying:Connect(function()
        if addedConn then addedConn:Disconnect() end
        if removedConn then removedConn:Disconnect() end
    end)
end

local function destroyPlayerListGui()
    if playerListGui then
        playerListGui:Destroy()
        playerListGui = nil
        playerListFrame = nil
        selectedPlayer = nil
        selectedPlayerTick = nil
        lastSelectedButton = nil
    end
end


local function updateModeVisibility()
    local cur = modes[modeIndex]
    ModeLabel.Text = "Mode: " .. cur

    if cur == "Memutar" then
        SpinPanel.Visible = true
    else
        SpinPanel.Visible = false
    end

    if cur == "Orbit Player" then
        createPlayerListGui()
    else
        destroyPlayerListGui()
    end
end

ModePrev.MouseButton1Click:Connect(function()
    modeIndex = modeIndex - 1
    if modeIndex < 1 then modeIndex = #modes end
    playSound("12221967")
    updateModeVisibility()
end)
ModeNext.MouseButton1Click:Connect(function()
    modeIndex = modeIndex + 1
    if modeIndex > #modes then modeIndex = 1 end
    playSound("12221967")
    updateModeVisibility()
end)

-- Toggle ring
ToggleButton.MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    ToggleButton.Text = ringPartsEnabled and "Ring Parts On" or "Ring Parts Off"
    ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(160, 82, 45)
    playSound("12221967")
    if not ringPartsEnabled then
        for _, p in pairs(parts) do
            if p and p:IsA("BasePart") and p:IsDescendantOf(workspace) then
                p.Velocity = Vector3.new(0, 0, 0)
                p.RotVelocity = Vector3.new(0, 0, 0)
                p.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                p.CanCollide = false
            end
        end
    end
end)

-- Force buttons
DecreaseBtn.MouseButton1Click:Connect(function()
    force = math.max(5, force - 5)
    ForceDisplay.Text = "Force: " .. force
    playSound("12221967")
end)
IncreaseBtn.MouseButton1Click:Connect(function()
    force = math.min(1000, force + 5)
    ForceDisplay.Text = "Force: " .. force
    playSound("12221967")
end)

-- Spin buttons
SpinPrev.MouseButton1Click:Connect(function()
    spinSpeed = math.max(10, spinSpeed - 10)
    SpinLabel.Text = "Spin: " .. spinSpeed
    playSound("12221967")
end)
SpinNext.MouseButton1Click:Connect(function()
    spinSpeed = math.min(3000, spinSpeed + 10)
    SpinLabel.Text = "Spin: " .. spinSpeed
    playSound("12221967")
end)

-- if a selected player leaves, clear selection
Players.PlayerRemoving:Connect(function(plr)
    if selectedPlayer == plr then
        selectedPlayer = nil
        lastSelectedButton = nil
        updateTickMark()
    end
end)

-- simpan state dash per part
local dashState = {}

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    -- tentukan center untuk Orbit Player
    local orbitCenter = nil
    if modes[modeIndex] == "Orbit Player" then
        if selectedPlayer and selectedPlayer.Character then
            local hrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then orbitCenter = hrp.Position end
        end
        -- fallback ke localplayer
        if not orbitCenter and humanoidRootPart then
            orbitCenter = humanoidRootPart.Position
        end
    end

    for i, part in pairs(parts) do
        if part and part.Parent and not part:IsDescendantOf(LocalPlayer.Character) then
            if part.Anchored then pcall(function() part.Anchored = false end) end
            part.CanCollide = false

            local mode = modes[modeIndex]

            if mode == "Dorong Atas" then
                part.AssemblyLinearVelocity = Vector3.new(0, force, 0)

            elseif mode == "Dorong Kanan" then
                if humanoidRootPart then
                    local right = humanoidRootPart.CFrame.RightVector
                    part.AssemblyLinearVelocity = right * force
                else
                    part.AssemblyLinearVelocity = Vector3.new(force, 0, 0)
                end

            elseif mode == "Dorong Kiri" then
                if humanoidRootPart then
                    local right = humanoidRootPart.CFrame.RightVector
                    part.AssemblyLinearVelocity = -right * force
                else
                    part.AssemblyLinearVelocity = Vector3.new(-force, 0, 0)
                end

            elseif mode == "Dorong Depan" then
                if humanoidRootPart then
                    local forward = humanoidRootPart.CFrame.LookVector
                    part.AssemblyLinearVelocity = forward * force
                else
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, force)
                end

            elseif mode == "Orbit Player" then
                if orbitCenter then
                    -- bikin offset tetap 1 stud di depan, belakang, kiri, kanan
                    local offsets = {
                        Vector3.new(1, 0, 0),   -- kanan
                        Vector3.new(-1, 0, 0),  -- kiri
                        Vector3.new(0, 0, 1),   -- depan
                        Vector3.new(0, 0, -1),  -- belakang
                    }
                    -- pilih offset sesuai urutan part
                    local offset = offsets[((i - 1) % #offsets) + 1]
                    local targetPos = orbitCenter + offset
                    local dir = targetPos - part.Position

                    if dir.Magnitude > 0.01 then
                        part.AssemblyLinearVelocity = dir.Unit * attractionStrength
                    else
                        part.AssemblyLinearVelocity = Vector3.zero
                    end
                else
                    -- fallback spin kalau center nggak ketemu
                    part.AssemblyLinearVelocity = Vector3.new(-part.Position.Z, 0, part.Position.X).Unit * force
                end

            elseif mode == "Memutar" then
                if part and part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(0, -force, 0)
                    part.RotVelocity = Vector3.new(0, spinSpeed, 0)
                end

            else
                -- safety default
                part.AssemblyLinearVelocity = Vector3.new(0, -force, 0)
            end
        end
    end
end)

-- initial visibility update (in case default mode is Orbit Player)
updateModeVisibility()

-- Notification
StarterGui:SetCore("SendNotification", {
    Title = "Super Ring",
    Text = "GUI Ready",
    Duration = 3
})

-- optional: decorative thumbnail notify
pcall(function()
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync("NannaDev") end)
    if success and type(userId) == "number" then
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size420x420
        local content = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        StarterGui:SetCore("SendNotification", {Title="BmSkyMods", Text="InfinityTrolling", Icon=content, Duration=3})
    end
end)
