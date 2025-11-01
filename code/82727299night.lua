local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Services y Referencias
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ItemsFolder = Workspace:WaitForChild("Items")

-- States of the mod
local ModState = {
    killAura = false,
    speed = false,
    infiniteJump = false,
    enemyEsp = false,
    itemEsp = false,
    chestEsp = false, -- NEW: Chest ESP state
    isOpen = false,
    minimized = false
}

local Connections = {}
local originalWalkSpeed = Humanoid.WalkSpeed
local originalJumpPower = Humanoid.JumpPower

-- Tools and their damage IDs
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982", 
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- Camp position
local campPosition = Vector3.new(0, 8, 0)

-- Clean up previous GUI
pcall(function()
    if LocalPlayer.PlayerGui:FindFirstChild("BmSkyNightsForest") then
        LocalPlayer.PlayerGui:FindFirstChild("BmSkyNightsForest"):Destroy()
    end
    if game:GetService("CoreGui"):FindFirstChild("BmSkyIcon") then
        game:GetService("CoreGui"):FindFirstChild("BmSkyIcon"):Destroy()
    end
end)

-- Function to get an usable tool
local function getToolWithDamageID()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return nil, nil end
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = inventory:FindFirstChild(toolName)
        if tool then
            return tool, damageID
        end
    end
    return nil, nil
end

-- Function to equip a tool
local function equipTool(tool)
    if tool then
        pcall(function()
            RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
        end)
    end
end

-- Kill Aura System
local function startKillAura()
    if Connections.killAuraLoop then return end
    
    Connections.killAuraLoop = RunService.Heartbeat:Connect(function()
        if not ModState.killAura then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local tool, damageID = getToolWithDamageID()
        if not tool or not damageID then return end
        
        equipTool(tool)
        
        for _, mob in pairs(Workspace.Characters:GetChildren()) do
            if mob:IsA("Model") and mob ~= character then
                local part = mob:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - hrp.Position).Magnitude <= 50 then
                    pcall(function()
                        RemoteEvents.ToolDamageObject:InvokeServer(
                            mob, tool, damageID, CFrame.new(part.Position)
                        )
                    end)
                end
            end
        end
        
        task.wait(0.1)
    end)
end

local function stopKillAura()
    if Connections.killAuraLoop then
        Connections.killAuraLoop:Disconnect()
        Connections.killAuraLoop = nil
    end
end

-- Toggle Kill Aura function
local function toggleKillAura()
    ModState.killAura = not ModState.killAura
    if ModState.killAura then
        startKillAura()
    else
        stopKillAura()
    end
end

-- Speed function
local function toggleSpeed()
    ModState.speed = not ModState.speed
    if ModState.speed then
        Humanoid.WalkSpeed = originalWalkSpeed * 2
        Connections.speedConnection = Humanoid.Changed:Connect(function(property)
            if property == "WalkSpeed" and ModState.speed then
                Humanoid.WalkSpeed = originalWalkSpeed * 2
            end
        end)
    else
        if Connections.speedConnection then
            Connections.speedConnection:Disconnect()
            Connections.speedConnection = nil
        end
        Humanoid.WalkSpeed = originalWalkSpeed
    end
end

-- Infinite Jump function
local function toggleInfiniteJump()
    ModState.infiniteJump = not ModState.infiniteJump
    if ModState.infiniteJump then
        Connections.jumpConnection = UserInputService.JumpRequest:Connect(function()
            if ModState.infiniteJump and Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if Connections.jumpConnection then
            Connections.jumpConnection:Disconnect()
            Connections.jumpConnection = nil
        end
    end
end

-- =========================================================================
-- ESP SCRIPT INTEGRATION
-- =========================================================================

local ESPFolder = {}
local tracers = {}
local billboardTags = {}
local espConnection = nil
local scanTask = nil
local itemNameTags = {}

local espSettings = {
    PlayerESP = true,
    Fairy = true,
    Wolf = true,
    Bunny = true,
    Cultist = true,
    CrossBow = true,
    PeltTrader = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 16,
    HPBarSize = Vector2.new(60, 6),
    BillboardOverheadNames = true,
    MaxDistance = 500
}

local function createBillboard(model)
    if billboardTags[model] then return end
    local head = model:FindFirstChild("Head")
    if not head then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "NameTag"
    gui.Adornee = head
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 100, 0, 20)
    gui.StudsOffset = Vector3.new(0, 2, 0)

    local label = Instance.new("TextLabel")
    label.Parent = gui
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = model.Name
    label.TextColor3 = espSettings.NameColor
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold

    gui.Parent = head
    billboardTags[model] = gui
end

local function removeBillboards()
    for model, gui in pairs(billboardTags) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    billboardTags = {}
end

local function createESP(model)
    if ESPFolder[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not head then return end

    ESPFolder[model] = {
        head = head,
        name = Drawing.new("Text"),
        hpBack = Drawing.new("Square"),
        hpBar = Drawing.new("Square"),
        model = model
    }

    local d = ESPFolder[model]
    d.name.Size = espSettings.NameSize
    d.name.Center = true
    d.name.Outline = true
    d.name.Color = espSettings.NameColor
    d.name.Visible = false

    d.hpBack.Color = Color3.new(0, 0, 0)
    d.hpBack.Filled = true
    d.hpBack.Transparency = 0.7
    d.hpBack.Visible = false

    d.hpBar.Color = Color3.new(0, 1, 0)
    d.hpBar.Filled = true
    d.hpBar.Transparency = 0.9
    d.hpBar.Visible = false
end

local function clearESP()
    for _, data in pairs(ESPFolder) do
        if data.name then data.name:Remove() end
        if data.hpBack then data.hpBack:Remove() end
        if data.hpBar then data.hpBar:Remove() end
    end
    ESPFolder = {}

    for _, line in pairs(tracers) do
        line:Remove()
    end
    tracers = {}

    removeBillboards()
end

local function toggleEnemyESP(state: boolean)
    ModState.enemyEsp = state
    if ModState.enemyEsp then
        scanTask = task.spawn(function()
            while ModState.enemyEsp do
                task.wait(1)
                for _, model in pairs(workspace:GetDescendants()) do
                    if model:IsA("Model") and model:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(model) then
                        if not ESPFolder[model] and model:IsDescendantOf(workspace.Characters) then
                            createESP(model)
                            if espSettings.BillboardOverheadNames then
                                createBillboard(model)
                            end
                        end
                    end
                end
            end
        end)

        espConnection = RunService.Heartbeat:Connect(function(dt)
            for i = #tracers, 1, -1 do
                tracers[i].Visible = false
            end

            local screenMid = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            local i = 1

            for model, data in pairs(ESPFolder) do
                local head = data.head
                if not model:IsDescendantOf(workspace) then
                    data.name:Remove()
                    data.hpBack:Remove()
                    data.hpBar:Remove()
                    ESPFolder[model] = nil
                    continue
                end

                local visible = false
                local labelText = ""
                local dist = (Camera.CFrame.Position - head.Position).Magnitude

                if dist > espSettings.MaxDistance then
                    data.name.Visible = false
                    data.hpBack.Visible = false
                    data.hpBar.Visible = false
                    continue
                end

                local n = model.Name:lower()
                if espSettings.Fairy and n:find("fairy") then
                    labelText = "Fairy {" .. math.floor(dist) .. "m}"
                    visible = true
                elseif espSettings.Wolf and (n:find("wolf") or n:find("alpha")) then
                    labelText = "Wolf {" .. math.floor(dist) .. "m}"
                    visible = true
                elseif espSettings.Bunny and n:find("bunny") then
                    labelText = "Bunny {" .. math.floor(dist) .. "m}"
                    visible = true
                elseif espSettings.Cultist and n:find("cultist") and not n:find("cross") then
                    labelText = "Cultist {" .. math.floor(dist) .. "m}"
                    visible = true
                elseif espSettings.CrossBow and n:find("cross") then
                    labelText = "Crossbow Cultist {" .. math.floor(dist) .. "m}"
                    visible = true
                elseif espSettings.PeltTrader and n:find("pelt") then
                    labelText = "Pelt Trader {" .. math.floor(dist) .. "m}"
                    visible = true
                end

                if visible then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        data.name.Text = labelText
                        data.name.Position = Vector2.new(pos.X, pos.Y - 25)
                        data.name.Visible = true

                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local bw, bh = espSettings.HPBarSize.X, espSettings.HPBarSize.Y
                            local x = pos.X - bw / 2
                            local y = pos.Y - 5

                            data.hpBack.Position = Vector2.new(x, y)
                            data.hpBack.Size = Vector2.new(bw, bh)
                            data.hpBack.Visible = true

                            data.hpBar.Position = Vector2.new(x, y)
                            data.hpBar.Size = Vector2.new(bw * hp, bh)
                            data.hpBar.Color = Color3.new(1 - hp, hp, 0)
                            data.hpBar.Visible = true
                        else
                            data.hpBack.Visible = false
                            data.hpBar.Visible = false
                        end

                        if not tracers[i] then
                            tracers[i] = Drawing.new("Line")
                        end
                        local line = tracers[i]
                        line.From = screenMid - Vector2.new(0, 10)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Color = Color3.fromRGB(255, 0, 0)
                        line.Thickness = 1
                        line.Visible = true
                        i += 1
                    else
                        data.name.Visible = false
                        data.hpBack.Visible = false
                        data.hpBar.Visible = false
                    end
                else
                    data.name.Visible = false
                    data.hpBack.Visible = false
                    data.hpBar.Visible = false
                end
            end
        end)
    else
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        if scanTask then
            task.cancel(scanTask)
            scanTask = nil
        end
        clearESP()
    end
end

local function createItemNameTag(item)
    if itemNameTags[item] then return end
    local adornee = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end

    local tag = Instance.new("BillboardGui")
    tag.Name = "ItemNameTag"
    tag.Adornee = adornee
    tag.AlwaysOnTop = true
    tag.Size = UDim2.new(0, 50, 0, 10) 
    tag.StudsOffset = Vector3.new(0, 1, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = item.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = tag

    tag.Parent = adornee
    itemNameTags[item] = tag
end

local function removeAllItemNameTags()
    for item, tag in pairs(itemNameTags) do
        if tag and tag.Parent then
            tag:Destroy()
        end
    end
    itemNameTags = {}
end

local function toggleItemESP(state: boolean)
    ModState.itemEsp = state
    if ModState.itemEsp then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item:IsA("Model") or item:IsA("BasePart") then
                createItemNameTag(item)
            end
        end

        Connections.itemAdded = ItemsFolder.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if ModState.itemEsp and (child:IsA("Model") or child:IsA("BasePart")) then
                createItemNameTag(child)
            end
        end)

        Connections.itemRemoved = ItemsFolder.ChildRemoved:Connect(function(child)
            if itemNameTags[child] then
                itemNameTags[child]:Destroy()
                itemNameTags[child] = nil
            end
        end)
    else
        if Connections.itemAdded then
            Connections.itemAdded:Disconnect()
            Connections.itemAdded = nil
        end
        if Connections.itemRemoved then
            Connections.itemRemoved:Disconnect()
            Connections.itemRemoved = nil
        end
        removeAllItemNameTags()
    end
end


-- =========================================================================
-- MODIFIED CHEST ESP SCRIPT
-- =========================================================================

local chestEspTags = {}
local chestEspConnection = nil
local chestScanTask = nil

local function createChestEspDrawing(chest)
    if chestEspTags[chest] then return end
    local adornee = chest:FindFirstChild("Handle") or chest:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end
    
    local textDrawing = Drawing.new("Text")
    textDrawing.Visible = false
    
    local circleDrawing = Drawing.new("Circle")
    circleDrawing.Visible = false
    
    chestEspTags[chest] = {
        adornee = adornee,
        text = textDrawing,
        circle = circleDrawing,
        isClose = false -- NEW: State untuk menyimpan apakah pemain pernah dekat dengan peti
    }
end

local function removeAllChestEspDrawings()
    for chest, data in pairs(chestEspTags) do
        if data.text then data.text:Remove() end
        if data.circle then data.circle:Remove() end
    end
    chestEspTags = {}
end

local function toggleChestESP(state: boolean)
    ModState.chestEsp = state
    if ModState.chestEsp then
        -- Initial scan for chests
        chestScanTask = task.spawn(function()
            while ModState.chestEsp do
                task.wait(1)
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    local itemNameLower = item.Name:lower()
                    if itemNameLower:find("chest") then
                        createChestEspDrawing(item)
                    end
                end
            end
        end)

        Connections.chestAdded = ItemsFolder.ChildAdded:Connect(function(child)
            task.wait(0.1)
            local itemNameLower = child.Name:lower()
            if ModState.chestEsp and itemNameLower:find("chest") then
                createChestEspDrawing(child)
            end
        end)

        Connections.chestRemoved = ItemsFolder.ChildRemoved:Connect(function(child)
            if chestEspTags[child] then
                chestEspTags[child].text:Remove()
                chestEspTags[child].circle:Remove()
                chestEspTags[child] = nil
            end
        end)
        
        chestEspConnection = RunService.Heartbeat:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for chest, data in pairs(chestEspTags) do
                if not chest:IsDescendantOf(ItemsFolder) or not data.adornee then
                    if data.text then data.text:Remove() end
                    if data.circle then data.circle:Remove() end
                    chestEspTags[chest] = nil
                    continue
                end

                local dist = (hrp.Position - data.adornee.Position).Magnitude
                local pos, onScreen = Camera:WorldToViewportPoint(data.adornee.Position)
                
                -- Update isClose state
                if dist <= 10 then
                    data.isClose = true
                end

                if onScreen and dist <= 500 then -- Range diperluas
                    if data.isClose then
                        -- Jika sudah pernah dekat, selalu tampilkan titik hijau
                        data.text.Visible = false
                        data.circle.Visible = true
                        data.circle.Color = Color3.fromRGB(0, 255, 0)
                        data.circle.Radius = 4
                        data.circle.Filled = true
                        data.circle.Position = Vector2.new(pos.X, pos.Y)
                    else
                        -- Tampilkan teks "Chest | *m"
                        data.text.Visible = true
                        data.circle.Visible = false
                        data.text.Text = "Chest | " .. math.floor(dist) .. "m"
                        data.text.Size = 16
                        data.text.Center = true
                        data.text.Outline = true
                        data.text.Color = Color3.fromRGB(255, 255, 255)
                        data.text.Position = Vector2.new(pos.X, pos.Y)
                    end
                else
                    data.text.Visible = false
                    data.circle.Visible = false
                end
            end
        end)
    else
        if chestScanTask then
            task.cancel(chestScanTask)
            chestScanTask = nil
        end
        if Connections.chestAdded then
            Connections.chestAdded:Disconnect()
            Connections.chestAdded = nil
        end
        if Connections.chestRemoved then
            Connections.chestRemoved:Disconnect()
            Connections.chestRemoved = nil
        end
        if chestEspConnection then
            chestEspConnection:Disconnect()
            chestEspConnection = nil
        end
        removeAllChestEspDrawings()
    end
end

-- =========================================================================
-- GUI BmSky CODE
-- =========================================================================

-- Create BmSky icon
local function createFloatingIcon()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BmSkyIcon"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 45, 0, 45)
    iconFrame.Position = UDim2.new(1, -60, 0, 10)
    iconFrame.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = screenGui
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconFrame
    
    local iconGradient = Instance.new("UIGradient")
    iconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 0))
    }
    iconGradient.Rotation = 45
    iconGradient.Parent = iconFrame
    
    local iconText = Instance.new("TextLabel")
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Text = "BmSky"
    iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconText.TextSize = 14
    iconText.Font = Enum.Font.GothamBold
    iconText.TextStrokeTransparency = 0
    iconText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    iconText.Parent = iconFrame
    
    local iconButton = Instance.new("TextButton")
    iconButton.Size = UDim2.new(1, 0, 1, 0)
    iconButton.BackgroundTransparency = 1
    iconButton.Text = ""
    iconButton.Parent = iconFrame
    
    return {
        gui = screenGui,
        frame = iconFrame,
        button = iconButton
    }
end

-- Create main menu
local function createModMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BmSkyNightsForest"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 340) -- Adjusted size
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -170) -- Adjusted position
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 139, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 0))
    }
    headerGradient.Rotation = 45
    headerGradient.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BmSky - 99 Nights"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 7.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 5)
    closeBtnCorner.Parent = closeBtn
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -50)
    content.Position = UDim2.new(0, 8, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = content
    layout.Padding = UDim.new(0, 5)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Kill Aura Toggle
    local killAuraSection = Instance.new("Frame")
    killAuraSection.Size = UDim2.new(1, 0, 0, 40)
    killAuraSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    killAuraSection.BorderSizePixel = 0
    killAuraSection.LayoutOrder = 1
    killAuraSection.Parent = content
    
    local killAuraCorner = Instance.new("UICorner")
    killAuraCorner.CornerRadius = UDim.new(0, 6)
    killAuraCorner.Parent = killAuraSection
    
    local killAuraLabel = Instance.new("TextLabel")
    killAuraLabel.Size = UDim2.new(1, -60, 1, 0)
    killAuraLabel.Position = UDim2.new(0, 10, 0, 0)
    killAuraLabel.BackgroundTransparency = 1
    killAuraLabel.Text = "Kill Aura"
    killAuraLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    killAuraLabel.TextSize = 12
    killAuraLabel.Font = Enum.Font.Gotham
    killAuraLabel.TextXAlignment = Enum.TextXAlignment.Left
    killAuraLabel.Parent = killAuraSection
    
    local killAuraToggle = Instance.new("TextButton")
    killAuraToggle.Size = UDim2.new(0, 45, 0, 22)
    killAuraToggle.Position = UDim2.new(1, -50, 0.5, -11)
    killAuraToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    killAuraToggle.Text = "OFF"
    killAuraToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    killAuraToggle.TextSize = 10
    killAuraToggle.Font = Enum.Font.GothamBold
    killAuraToggle.Parent = killAuraSection
    
    local killAuraToggleCorner = Instance.new("UICorner")
    killAuraToggleCorner.CornerRadius = UDim.new(0, 5)
    killAuraToggleCorner.Parent = killAuraToggle
    
    -- Speed Toggle
    local speedSection = Instance.new("Frame")
    speedSection.Size = UDim2.new(1, 0, 0, 40)
    speedSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    speedSection.BorderSizePixel = 0
    speedSection.LayoutOrder = 2
    speedSection.Parent = content
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = speedSection
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -60, 1, 0)
    speedLabel.Position = UDim2.new(0, 10, 0, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Speed x2"
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.TextSize = 12
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedSection
    
    local speedToggle = Instance.new("TextButton")
    speedToggle.Size = UDim2.new(0, 45, 0, 22)
    speedToggle.Position = UDim2.new(1, -50, 0.5, -11)
    speedToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    speedToggle.Text = "OFF"
    speedToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedToggle.TextSize = 10
    speedToggle.Font = Enum.Font.GothamBold
    speedToggle.Parent = speedSection
    
    local speedToggleCorner = Instance.new("UICorner")
    speedToggleCorner.CornerRadius = UDim.new(0, 5)
    speedToggleCorner.Parent = speedToggle
    
    -- Infinite Jump Toggle
    local jumpSection = Instance.new("Frame")
    jumpSection.Size = UDim2.new(1, 0, 0, 40)
    jumpSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    jumpSection.BorderSizePixel = 0
    jumpSection.LayoutOrder = 3
    jumpSection.Parent = content
    
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.CornerRadius = UDim.new(0, 6)
    jumpCorner.Parent = jumpSection
    
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(1, -60, 1, 0)
    jumpLabel.Position = UDim2.new(0, 10, 0, 0)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.Text = "Infinite Jump"
    jumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpLabel.TextSize = 12
    jumpLabel.Font = Enum.Font.Gotham
    jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
    jumpLabel.Parent = jumpSection
    
    local jumpToggle = Instance.new("TextButton")
    jumpToggle.Size = UDim2.new(0, 45, 0, 22)
    jumpToggle.Position = UDim2.new(1, -50, 0.5, -11)
    jumpToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    jumpToggle.Text = "OFF"
    jumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    jumpToggle.TextSize = 10
    jumpToggle.Font = Enum.Font.GothamBold
    jumpToggle.Parent = jumpSection
    
    local jumpToggleCorner = Instance.new("UICorner")
    jumpToggleCorner.CornerRadius = UDim.new(0, 5)
    jumpToggleCorner.Parent = jumpToggle
    
    -- Enemy ESP Toggle
    local enemyEspSection = Instance.new("Frame")
    enemyEspSection.Size = UDim2.new(1, 0, 0, 40)
    enemyEspSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    enemyEspSection.BorderSizePixel = 0
    enemyEspSection.LayoutOrder = 4
    enemyEspSection.Parent = content
    
    local enemyEspCorner = Instance.new("UICorner")
    enemyEspCorner.CornerRadius = UDim.new(0, 6)
    enemyEspCorner.Parent = enemyEspSection
    
    local enemyEspLabel = Instance.new("TextLabel")
    enemyEspLabel.Size = UDim2.new(1, -60, 1, 0)
    enemyEspLabel.Position = UDim2.new(0, 10, 0, 0)
    enemyEspLabel.BackgroundTransparency = 1
    enemyEspLabel.Text = "Enemy ESP"
    enemyEspLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    enemyEspLabel.TextSize = 12
    enemyEspLabel.Font = Enum.Font.Gotham
    enemyEspLabel.TextXAlignment = Enum.TextXAlignment.Left
    enemyEspLabel.Parent = enemyEspSection
    
    local enemyEspToggle = Instance.new("TextButton")
    enemyEspToggle.Size = UDim2.new(0, 45, 0, 22)
    enemyEspToggle.Position = UDim2.new(1, -50, 0.5, -11)
    enemyEspToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    enemyEspToggle.Text = "OFF"
    enemyEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    enemyEspToggle.TextSize = 10
    enemyEspToggle.Font = Enum.Font.GothamBold
    enemyEspToggle.Parent = enemyEspSection
    
    local enemyEspToggleCorner = Instance.new("UICorner")
    enemyEspToggleCorner.CornerRadius = UDim.new(0, 5)
    enemyEspToggleCorner.Parent = enemyEspToggle
    
    -- Item ESP Toggle
    local itemEspSection = Instance.new("Frame")
    itemEspSection.Size = UDim2.new(1, 0, 0, 40)
    itemEspSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    itemEspSection.BorderSizePixel = 0
    itemEspSection.LayoutOrder = 5
    itemEspSection.Parent = content
    
    local itemEspCorner = Instance.new("UICorner")
    itemEspCorner.CornerRadius = UDim.new(0, 6)
    itemEspCorner.Parent = itemEspSection
    
    local itemEspLabel = Instance.new("TextLabel")
    itemEspLabel.Size = UDim2.new(1, -60, 1, 0)
    itemEspLabel.Position = UDim2.new(0, 10, 0, 0)
    itemEspLabel.BackgroundTransparency = 1
    itemEspLabel.Text = "Item ESP"
    itemEspLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemEspLabel.TextSize = 12
    itemEspLabel.Font = Enum.Font.Gotham
    itemEspLabel.TextXAlignment = Enum.TextXAlignment.Left
    itemEspLabel.Parent = itemEspSection
    
    local itemEspToggle = Instance.new("TextButton")
    itemEspToggle.Size = UDim2.new(0, 45, 0, 22)
    itemEspToggle.Position = UDim2.new(1, -50, 0.5, -11)
    itemEspToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    itemEspToggle.Text = "OFF"
    itemEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemEspToggle.TextSize = 10
    itemEspToggle.Font = Enum.Font.GothamBold
    itemEspToggle.Parent = itemEspSection
    
    local itemEspToggleCorner = Instance.new("UICorner")
    itemEspToggleCorner.CornerRadius = UDim.new(0, 5)
    itemEspToggleCorner.Parent = itemEspToggle

    -- NEW: Chest ESP Toggle
    local chestEspSection = Instance.new("Frame")
    chestEspSection.Size = UDim2.new(1, 0, 0, 40)
    chestEspSection.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
    chestEspSection.BorderSizePixel = 0
    chestEspSection.LayoutOrder = 6
    chestEspSection.Parent = content
    
    local chestEspCorner = Instance.new("UICorner")
    chestEspCorner.CornerRadius = UDim.new(0, 6)
    chestEspCorner.Parent = chestEspSection
    
    local chestEspLabel = Instance.new("TextLabel")
    chestEspLabel.Size = UDim2.new(1, -60, 1, 0)
    chestEspLabel.Position = UDim2.new(0, 10, 0, 0)
    chestEspLabel.BackgroundTransparency = 1
    chestEspLabel.Text = "Chest ESP"
    chestEspLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    chestEspLabel.TextSize = 12
    chestEspLabel.Font = Enum.Font.Gotham
    chestEspLabel.TextXAlignment = Enum.TextXAlignment.Left
    chestEspLabel.Parent = chestEspSection
    
    local chestEspToggle = Instance.new("TextButton")
    chestEspToggle.Size = UDim2.new(0, 45, 0, 22)
    chestEspToggle.Position = UDim2.new(1, -50, 0.5, -11)
    chestEspToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    chestEspToggle.Text = "OFF"
    chestEspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    chestEspToggle.TextSize = 10
    chestEspToggle.Font = Enum.Font.GothamBold
    chestEspToggle.Parent = chestEspSection
    
    local chestEspToggleCorner = Instance.new("UICorner")
    chestEspToggleCorner.CornerRadius = UDim.new(0, 5)
    chestEspToggleCorner.Parent = chestEspToggle

    -- TP to Camp Button
    local campBtn = Instance.new("TextButton")
    campBtn.Size = UDim2.new(1, 0, 0, 30)
    campBtn.Position = UDim2.new(0, 0, 0, 280) -- Adjusted position
    campBtn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    campBtn.Text = "Teleport to Camp"
    campBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    campBtn.TextSize = 12
    campBtn.Font = Enum.Font.GothamBold
    campBtn.LayoutOrder = 7
    campBtn.Parent = content
    
    local campBtnCorner = Instance.new("UICorner")
    campBtnCorner.CornerRadius = UDim.new(0, 6)
    campBtnCorner.Parent = campBtn
    
    return {
        gui = screenGui,
        mainFrame = mainFrame,
        content = content,
        closeBtn = closeBtn,
        killAuraToggle = killAuraToggle,
        speedToggle = speedToggle,
        jumpToggle = jumpToggle,
        enemyEspToggle = enemyEspToggle,
        itemEspToggle = itemEspToggle,
        chestEspToggle = chestEspToggle, -- NEW: Chest ESP toggle button
        campBtn = campBtn
    }
end

-- Create GUI system
local icon = createFloatingIcon()
local menu = createModMenu()

-- Function to set menu visibility
local function toggleMenu()
    ModState.isOpen = not ModState.isOpen
    menu.mainFrame.Visible = ModState.isOpen
    
    if ModState.isOpen then
        menu.mainFrame.Size = UDim2.new(0, 0, 0, 0)
        menu.mainFrame:TweenSize(
            UDim2.new(0, 280, 0, 340), -- Adjusted size
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Back,
            0.3,
            true
        )
    end
end

-- Function to update toggle UI
local function updateToggleUI(button, enabled)
    if enabled then
        button.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
        button.Text = "ON"
    else
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        button.Text = "OFF"
    end
end

-- Icon events
icon.button.MouseButton1Click:Connect(function()
    icon.frame:TweenSize(
        UDim2.new(0, 40, 0, 40),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.1,
        true,
        function()
            icon.frame:TweenSize(
                UDim2.new(0, 45, 0, 45),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end
    )
    toggleMenu()
end)

-- Main menu events
menu.closeBtn.MouseButton1Click:Connect(function()
    ModState.isOpen = false
    menu.mainFrame:TweenSize(
        UDim2.new(0, 0, 0, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Back,
        0.2,
        true,
        function()
            menu.mainFrame.Visible = false
        end
    )
end)

-- Mod functions events
menu.killAuraToggle.MouseButton1Click:Connect(function()
    toggleKillAura()
    updateToggleUI(menu.killAuraToggle, ModState.killAura)
end)

menu.speedToggle.MouseButton1Click:Connect(function()
    toggleSpeed()
    updateToggleUI(menu.speedToggle, ModState.speed)
end)

menu.jumpToggle.MouseButton1Click:Connect(function()
    toggleInfiniteJump()
    updateToggleUI(menu.jumpToggle, ModState.infiniteJump)
end)

menu.enemyEspToggle.MouseButton1Click:Connect(function()
    toggleEnemyESP(not ModState.enemyEsp)
    updateToggleUI(menu.enemyEspToggle, ModState.enemyEsp)
end)

menu.itemEspToggle.MouseButton1Click:Connect(function()
    toggleItemESP(not ModState.itemEsp)
    updateToggleUI(menu.itemEspToggle, ModState.itemEsp)
end)

menu.chestEspToggle.MouseButton1Click:Connect(function()
    toggleChestESP(not ModState.chestEsp)
    updateToggleUI(menu.chestEspToggle, ModState.chestEsp)
end)

menu.campBtn.MouseButton1Click:Connect(function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(campPosition)
        
        -- Visual feedback
        menu.campBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        menu.campBtn.Text = "DONE!"
        task.wait(0.3)
        menu.campBtn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
        menu.campBtn.Text = "Teleport to Camp"
    end
end)

-- Make menu draggable
local dragging = false
local dragStart = nil
local startPos = nil

menu.mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menu.mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

menu.mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            menu.mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- Auto-refresh on character respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    
    originalWalkSpeed = Humanoid.WalkSpeed
    originalJumpPower = Humanoid.JumpPower
    
    -- Re-apply active mod statuses
    if ModState.speed then
        Humanoid.WalkSpeed = originalWalkSpeed * 2
        if Connections.speedConnection then
            Connections.speedConnection:Disconnect()
        end
        Connections.speedConnection = Humanoid.Changed:Connect(function(property)
            if property == "WalkSpeed" and ModState.speed then
                Humanoid.WalkSpeed = originalWalkSpeed * 2
            end
        end)
    end
    
    if ModState.killAura then
        stopKillAura()
        startKillAura()
    end
    
    if ModState.enemyEsp then
        toggleEnemyESP(true)
    end

    if ModState.itemEsp then
        toggleItemESP(true)
    end

    if ModState.chestEsp then
        toggleChestESP(true)
    end
end)

-- Show successful load notification
local function showLoadNotification()
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "BmSkyLoadNotification"
    notificationGui.Parent = game:GetService("CoreGui")
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 280, 0, 60)
    notification.Position = UDim2.new(0.5, -140, 0, -80)
    notification.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 8)
    notificationCorner.Parent = notification
    
    local notificationText = Instance.new("TextLabel")
    notificationText.Size = UDim2.new(1, -16, 1, 0)
    notificationText.Position = UDim2.new(0, 8, 0, 0)
    notificationText.BackgroundTransparency = 1
    notificationText.Text = "BmSky Mod Menu Loaded!\nClick BmSky icon to open"
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.TextSize = 12
    notificationText.TextScaled = false
    notificationText.Font = Enum.Font.GothamBold
    notificationText.Parent = notification

    -- Tween notification in
    notification:TweenPosition(
        UDim2.new(0.5, -140, 0, 10),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        0.5,
        true
    )

    -- Wait 3 seconds and remove notification
    task.wait(3)
    notification:TweenPosition(
        UDim2.new(0.5, -140, 0, -80),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Quart,
        0.5,
        true,
        function()
            notificationGui:Destroy()
        end
    )
end

-- Call the notification function after all scripts are loaded
showLoadNotification()

