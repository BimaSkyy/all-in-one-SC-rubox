-- ══════════════════════════════════════
--   Tent Orbit v4  |  by BmSky
--   Perbaikan: refresh tenda setiap aktivasi, validasi real-time
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local currentMode = "none"          -- "orbit", "follow", "leftright"
local orbitConnection = nil
local tentFolders = {}              -- array of folder objects
local orbitAngle = 0
local ORBIT_RADIUS = 8
local ORBIT_SPEED = 1.2
local TOTAL_TENTS = 2               -- jumlah total tenda yang diinginkan
local PLAYER_NAME = "BimaSky77"    -- ganti dengan username kamu

-- Path ke folder
local wsCom = workspace:FindFirstChild("WorkspaceCom")
local trafficCones = wsCom and wsCom:FindFirstChild("001_TrafficCones")

if not trafficCones then
    warn("001_TrafficCones tidak ditemukan!")
    return
end

-- ══════════════════════════════════════
--   GUI
-- ══════════════════════════════════════
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "TentOrbitGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 180)
panel.Position = UDim2.new(0.5, -110, 0.5, -90)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
panel.BorderSizePixel = 0
panel.ZIndex = 10
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(80, 60, 180)

-- Header (drag handle)
local header = Instance.new("TextButton", panel)
header.Size = UDim2.new(1, 0, 0, 26)
header.BackgroundColor3 = Color3.fromRGB(30, 25, 60)
header.Text = "  Tent Orbit v4"
header.TextColor3 = Color3.new(1,1,1)
header.Font = Enum.Font.GothamBold
header.TextSize = 12
header.TextXAlignment = Enum.TextXAlignment.Left
header.AutoButtonColor = false
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

-- Drag functionality
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Status label
local lblStatus = Instance.new("TextLabel", panel)
lblStatus.Size = UDim2.new(1, -10, 0, 16)
lblStatus.Position = UDim2.new(0, 5, 0, 30)
lblStatus.BackgroundTransparency = 1
lblStatus.Text = "Status: idle"
lblStatus.TextColor3 = Color3.fromRGB(180,180,200)
lblStatus.Font = Enum.Font.Gotham
lblStatus.TextSize = 11
lblStatus.TextXAlignment = Enum.TextXAlignment.Left

-- Mode toggle buttons (Orbit, Follow, LeftRight)
local btnOrbit = Instance.new("TextButton", panel)
btnOrbit.Size = UDim2.new(0, 60, 0, 26)
btnOrbit.Position = UDim2.new(0, 8, 0, 52)
btnOrbit.BackgroundColor3 = Color3.fromRGB(40,40,50)
btnOrbit.Text = "Orbit"
btnOrbit.TextColor3 = Color3.new(1,1,1)
btnOrbit.Font = Enum.Font.GothamBold
btnOrbit.TextSize = 12
btnOrbit.AutoButtonColor = false
Instance.new("UICorner", btnOrbit).CornerRadius = UDim.new(0, 6)

local btnFollow = Instance.new("TextButton", panel)
btnFollow.Size = UDim2.new(0, 60, 0, 26)
btnFollow.Position = UDim2.new(0, 80, 0, 52)
btnFollow.BackgroundColor3 = Color3.fromRGB(40,40,50)
btnFollow.Text = "Follow"
btnFollow.TextColor3 = Color3.new(1,1,1)
btnFollow.Font = Enum.Font.GothamBold
btnFollow.TextSize = 12
btnFollow.AutoButtonColor = false
Instance.new("UICorner", btnFollow).CornerRadius = UDim.new(0, 6)

local btnLeftRight = Instance.new("TextButton", panel)
btnLeftRight.Size = UDim2.new(0, 60, 0, 26)
btnLeftRight.Position = UDim2.new(0, 152, 0, 52)
btnLeftRight.BackgroundColor3 = Color3.fromRGB(40,40,50)
btnLeftRight.Text = "L‑R"
btnLeftRight.TextColor3 = Color3.new(1,1,1)
btnLeftRight.Font = Enum.Font.GothamBold
btnLeftRight.TextSize = 12
btnLeftRight.AutoButtonColor = false
Instance.new("UICorner", btnLeftRight).CornerRadius = UDim.new(0, 6)

-- Slider untuk Radius Orbit
local function createSlider(parent, name, minVal, maxVal, initVal, yPos, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -16, 0, 24)
    container.Position = UDim2.new(0, 8, 0, yPos)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0, 50, 0, 14)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200,200,200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local barBg = Instance.new("Frame", container)
    barBg.Size = UDim2.new(1, -70, 0, 10)
    barBg.Position = UDim2.new(0, 60, 0, 2)
    barBg.BackgroundColor3 = Color3.fromRGB(60,60,70)
    barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 5)

    local fill = Instance.new("Frame", barBg)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120,80,220)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local knob = Instance.new("TextButton", barBg)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200,200,255)
    knob.Text = ""
    knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local valLabel = Instance.new("TextLabel", container)
    valLabel.Size = UDim2.new(0, 30, 0, 14)
    valLabel.Position = UDim2.new(1, -30, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(initVal)
    valLabel.TextColor3 = Color3.fromRGB(255,255,255)
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local value = initVal
    local function updateUI()
        local frac = (value - minVal) / (maxVal - minVal)
        local knobX = frac * (barBg.AbsoluteSize.X - knob.AbsoluteSize.X)
        knob.Position = UDim2.new(0, knobX, 0.5, -knob.AbsoluteSize.Y/2)
        fill.Size = UDim2.new(frac, 0, 1, 0)
        valLabel.Text = string.format("%.1f", value)
    end

    local function setValue(newVal)
        value = math.clamp(newVal, minVal, maxVal)
        updateUI()
        callback(value)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local moveConnection
            local releaseConnection
            moveConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    moveConnection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
            releaseConnection = knob.InputEnded:Connect(function()
                moveConnection:Disconnect()
                releaseConnection:Disconnect()
            end)
        end
    end)
    knob.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = input.Position
            local barMin = barBg.AbsolutePosition.X + knob.AbsoluteSize.X/2
            local barMax = barBg.AbsolutePosition.X + barBg.AbsoluteSize.X - knob.AbsoluteSize.X/2
            local frac = (mousePos.X - barMin) / (barMax - barMin)
            frac = math.clamp(frac, 0, 1)
            setValue(minVal + frac * (maxVal - minVal))
        end
    end)

    -- Klik pada bar langsung
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local barMin = barBg.AbsolutePosition.X + knob.AbsoluteSize.X/2
            local barMax = barBg.AbsolutePosition.X + barBg.AbsoluteSize.X - knob.AbsoluteSize.X/2
            local frac = (input.Position.X - barMin) / (barMax - barMin)
            frac = math.clamp(frac, 0, 1)
            setValue(minVal + frac * (maxVal - minVal))
        end
    end)

    setValue(initVal)
    return {
        SetValue = setValue,
        GetValue = function() return value end
    }
end

-- Slider untuk radius dan speed
local radiusSlider = createSlider(panel, "Radius", 2, 20, ORBIT_RADIUS, 84, function(v) ORBIT_RADIUS = v end)
local speedSlider = createSlider(panel, "Speed", 0.2, 5, ORBIT_SPEED, 108, function(v) ORBIT_SPEED = v end)

-- Info kecil
local lblInfo = Instance.new("TextLabel", panel)
lblInfo.Size = UDim2.new(1, -10, 0, 16)
lblInfo.Position = UDim2.new(0, 8, 0, 136)
lblInfo.BackgroundTransparency = 1
lblInfo.Text = "Letakkan 1 tenda manual dulu"
lblInfo.TextColor3 = Color3.fromRGB(150,150,170)
lblInfo.Font = Enum.Font.Gotham
lblInfo.TextSize = 10
lblInfo.TextXAlignment = Enum.TextXAlignment.Left

-- Highlight active button
local function setButtonStates()
    if currentMode == "orbit" then
        btnOrbit.BackgroundColor3 = Color3.fromRGB(100,70,200)
        btnFollow.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnLeftRight.BackgroundColor3 = Color3.fromRGB(40,40,50)
    elseif currentMode == "follow" then
        btnOrbit.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnFollow.BackgroundColor3 = Color3.fromRGB(100,70,200)
        btnLeftRight.BackgroundColor3 = Color3.fromRGB(40,40,50)
    elseif currentMode == "leftright" then
        btnOrbit.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnFollow.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnLeftRight.BackgroundColor3 = Color3.fromRGB(100,70,200)
    else
        btnOrbit.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnFollow.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btnLeftRight.BackgroundColor3 = Color3.fromRGB(40,40,50)
    end
end
setButtonStates()

-- ══════════════════════════════════════
--   FUNGSI DETEKSI & SPAWN
-- ══════════════════════════════════════
local function getExistingTents()
    local folders = {}
    for _, child in ipairs(trafficCones:GetChildren()) do
        if child.Name == "Prop" .. PLAYER_NAME and child:IsA("Model") then
            table.insert(folders, child)
        end
    end
    return folders
end

local function spawnAutoTent()
    pcall(function()
        ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("RequestingPropName", "BigTeePee", "Big", "Home")
    end)
    task.wait(0.5)

    local beforeFolders = {}
    for _, f in ipairs(trafficCones:GetChildren()) do
        if f.Name == "Prop" .. PLAYER_NAME then beforeFolders[f] = true end
    end

    local newFolder = nil
    for _ = 1, 30 do
        for _, child in ipairs(trafficCones:GetChildren()) do
            if child.Name == "Prop" .. PLAYER_NAME and not beforeFolders[child] then
                newFolder = child
                break
            end
        end
        if newFolder then break end
        task.wait(0.1)
    end

    if not newFolder then
        warn("Folder tenda baru tidak muncul!")
        return nil
    end

    local part = newFolder:FindFirstChild("Part") or newFolder:FindFirstChild("Wedge") or newFolder:FindFirstChildWhichIsA("BasePart")
    if not part then
        warn("Part tidak ditemukan di folder baru!")
        return nil
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local randomAngle = math.random() * math.pi * 2
        local x = math.cos(randomAngle) * ORBIT_RADIUS
        local z = math.sin(randomAngle) * ORBIT_RADIUS
        pcall(function()
            workspace[PLAYER_NAME].PropMaker.Tool_PropMake:FireServer(part)
        end)
        task.wait(0.2)
        pcall(function()
            newFolder.SetCurrentCFrame:InvokeServer(CFrame.new(
                hrp.Position.X + x,
                hrp.Position.Y + 0.025,
                hrp.Position.Z + z
            ))
        end)
        task.wait(0.2)
    end
    return newFolder
end

-- ══════════════════════════════════════
--   REFRESH TENT LIST (panggil setiap aktivasi)
-- ══════════════════════════════════════
local function refreshTents()
    -- Ambil semua tenda yang ada di workspace
    tentFolders = getExistingTents()
    if #tentFolders == 0 then
        return false
    end

    -- Tambah tenda jika masih kurang
    while #tentFolders < TOTAL_TENTS do
        local newTent = spawnAutoTent()
        if newTent then
            table.insert(tentFolders, newTent)
        else
            lblStatus.Text = "Gagal spawn tenda ke-" .. (#tentFolders + 1)
            break
        end
        task.wait(0.5)
    end
    return true
end

-- ══════════════════════════════════════
--   MODE UPDATES (real-time dengan validasi)
-- ══════════════════════════════════════
local function updateOrbit(dt)
    orbitAngle = (orbitAngle + ORBIT_SPEED * dt) % (math.pi * 2)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local playerPos = hrp.Position

    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local angle = orbitAngle + (i - 1) * (math.pi * 2 / #tentFolders)
            local x = math.cos(angle) * ORBIT_RADIUS
            local z = math.sin(angle) * ORBIT_RADIUS
            local targetCFrame = CFrame.new(playerPos.X + x, playerPos.Y + 0.025, playerPos.Z + z)
            pcall(function() folder.SetCurrentCFrame:InvokeServer(targetCFrame) end)
        else
            -- Hapus folder yang sudah tidak valid
            table.remove(tentFolders, i)
            lblStatus.Text = string.format("Tenda %d hilang", i)
        end
    end
end

local function updateFollow(dt)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.CFrame then return end
    local lookVector = hrp.CFrame.LookVector
    local basePos = hrp.Position + lookVector * (-4)  -- 4 stud di belakang

    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local offset = (i - 1) * 3
            local targetPos = basePos + lookVector * (-offset)
            local targetCFrame = CFrame.new(targetPos.X, targetPos.Y + 0.025, targetPos.Z)
            pcall(function() folder.SetCurrentCFrame:InvokeServer(targetCFrame) end)
        else
            table.remove(tentFolders, i)
        end
    end
end

local function updateLeftRight(dt)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.CFrame then return end
    local baseCFrame = hrp.CFrame * CFrame.new(0, 0, -4)  -- 4 stud di belakang
    local speed = 0.8
    local amplitude = 10
    local t = os.clock() * speed

    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local offsetX = amplitude * math.sin(t + (i % 2 == 0 and 0 or math.pi))
            local targetCFrame = baseCFrame * CFrame.new(offsetX, 0.025, 0)
            pcall(function() folder.SetCurrentCFrame:InvokeServer(targetCFrame) end)
        else
            table.remove(tentFolders, i)
        end
    end
end

-- ══════════════════════════════════════
--   MAIN LOOP START/STOP
-- ══════════════════════════════════════
local function startLoop()
    if orbitConnection then return end  -- sudah berjalan
    orbitConnection = RunService.Heartbeat:Connect(function(dt)
        if currentMode == "orbit" then
            updateOrbit(dt)
        elseif currentMode == "follow" then
            updateFollow(dt)
        elseif currentMode == "leftright" then
            updateLeftRight(dt)
        end
    end)
end

local function stopLoop()
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end
end

local function setMode(newMode)
    -- Jika tombol yang sama ditekan lagi → matikan mode
    if currentMode == newMode then
        currentMode = "none"
        lblStatus.Text = "Status: idle"
        stopLoop()
        tentFolders = {}         -- ✨ reset daftar
        setButtonStates()
        return
    end

    -- Matikan mode sebelumnya, lalu siapkan mode baru
    stopLoop()
    tentFolders = {}             -- ✨ reset daftar
    currentMode = newMode

    -- Refresh daftar tenda dari workspace
    local success = refreshTents()
    if not success then
        lblStatus.Text = "Status: tidak ada tenda, letakkan manual"
        currentMode = "none"
        setButtonStates()
        return
    end

    lblStatus.Text = string.format("Status: %s aktif, %d tenda", newMode, #tentFolders)
    startLoop()
    setButtonStates()
end

-- ══════════════════════════════════════
--   BUTTON EVENTS
-- ══════════════════════════════════════
btnOrbit.MouseButton1Click:Connect(function()
    setMode("orbit")
end)
btnFollow.MouseButton1Click:Connect(function()
    setMode("follow")
end)
btnLeftRight.MouseButton1Click:Connect(function()
    setMode("leftright")
end)

-- ══════════════════════════════════════
--   RESPAWN HANDLER
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    if currentMode ~= "none" then
        stopLoop()
        currentMode = "none"
        tentFolders = {}
        lblStatus.Text = "Status: respawned"
        setButtonStates()
    end
end)

print("[OK] Tent Orbit v4 loaded – perbaikan aktivasi ulang & validasi")
