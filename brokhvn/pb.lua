-- ══════════════════════════════════════
--   Tent Orbit v4  |  by BmSky
--   + Ball Follow integration
--   + Minimize/Expand on header click
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ──────────────────────────────
local currentMode      = "none"   -- "orbit" | "follow" | "leftright"
local orbitConnection  = nil
local tentFolders      = {}
local orbitAngle       = 0
local ORBIT_RADIUS     = 8
local ORBIT_SPEED      = 1.2
local TOTAL_TENTS      = 2
local PLAYER_NAME      = LocalPlayer.Name

-- Ball Follow state
local ballFollowActive = false
local ball             = nil
local ballSpeed        = 60
local verticalMove     = 0

-- Minimize state
local isMinimized      = false
local PANEL_H_FULL     = 220   -- tinggi panel saat expand
local PANEL_H_MIN      = 26    -- tinggi panel saat minimize (cuma header)

-- ── Path tenda ────────────────────────
local wsCom        = workspace:FindFirstChild("WorkspaceCom")
local trafficCones = wsCom and wsCom:FindFirstChild("001_TrafficCones")
if not trafficCones then
    warn("001_TrafficCones tidak ditemukan!")
    return
end

-- ── Helper ────────────────────────────
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("Humanoid")
end

-- ══════════════════════════════════════
--   BALL: spawn & destroy
-- ══════════════════════════════════════
local function spawnBall()
    if ball then ball:Destroy() end
    local hrp = getHRP()
    if not hrp then return end
    ball          = Instance.new("Part")
    ball.Shape    = Enum.PartType.Ball
    ball.Size     = Vector3.new(2, 2, 2)
    ball.Material = Enum.Material.Neon
    ball.Color    = Color3.fromRGB(255, 255, 255)
    ball.Anchored    = false
    ball.CanCollide  = false
    ball.Position = hrp.Position + Vector3.new(0, 3, 0)
    ball.Parent   = workspace
    local att = Instance.new("Attachment", ball)
    local lv  = Instance.new("LinearVelocity", ball)
    lv.Attachment0    = att
    lv.MaxForce       = 1e9
    lv.VectorVelocity = Vector3.zero
    lv.RelativeTo     = Enum.ActuatorRelativeTo.World
end

local function destroyBall()
    if ball then ball:Destroy() end
    ball = nil
end

-- ── Target posisi (bola atau player) ──
local function getTargetPosition()
    if ballFollowActive and ball and ball.Parent then
        return ball.Position
    else
        local hrp = getHRP()
        return hrp and hrp.Position
    end
end

-- ══════════════════════════════════════
--   GUI
-- ══════════════════════════════════════
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name           = "TentOrbitGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame", gui)
panel.Size                = UDim2.new(0, 220, 0, PANEL_H_FULL)
panel.Position            = UDim2.new(0.5, -110, 0.5, -110)
panel.BackgroundColor3    = Color3.fromRGB(15, 20, 30)
panel.BorderSizePixel     = 0
panel.ZIndex              = 10
panel.ClipsDescendants    = true   -- ← kunci minimize: child terpotong saat height kecil
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(80, 60, 180)

-- ── Header (drag + minimize) ──────────
local header = Instance.new("TextButton", panel)
header.Size               = UDim2.new(1, 0, 0, 26)
header.BackgroundColor3   = Color3.fromRGB(30, 25, 60)
header.Text               = "  ▼ Tent Orbit v4 + Ball Follow"
header.TextColor3         = Color3.new(1, 1, 1)
header.Font               = Enum.Font.GothamBold
header.TextSize           = 11
header.TextXAlignment     = Enum.TextXAlignment.Left
header.AutoButtonColor    = false
header.ZIndex             = 11
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

-- ── Drag logic ────────────────────────
local dragging, dragStart, startPos
local isDragging = false

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        dragging   = true
        dragStart  = input.Position
        startPos   = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then isDragging = true end
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ── Minimize toggle on click (bukan drag) ──
header.MouseButton1Click:Connect(function()
    if isDragging then isDragging = false; return end

    isMinimized = not isMinimized
    local targetH = isMinimized and PANEL_H_MIN or PANEL_H_FULL
    local arrow   = isMinimized and "▶" or "▼"
    header.Text   = string.format("  %s Tent Orbit v4 + Ball Follow", arrow)

    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, targetH)
    }):Play()
end)

-- ── Status label ──────────────────────
local lblStatus = Instance.new("TextLabel", panel)
lblStatus.Size                = UDim2.new(1, -10, 0, 16)
lblStatus.Position            = UDim2.new(0, 5, 0, 30)
lblStatus.BackgroundTransparency = 1
lblStatus.Text                = "Status: idle"
lblStatus.TextColor3          = Color3.fromRGB(180, 180, 200)
lblStatus.Font                = Enum.Font.Gotham
lblStatus.TextSize            = 11
lblStatus.TextXAlignment      = Enum.TextXAlignment.Left

-- ── Mode buttons ──────────────────────
local function makeBtn(text, xOff, yOff, w)
    local b = Instance.new("TextButton", panel)
    b.Size             = UDim2.new(0, w or 60, 0, 26)
    b.Position         = UDim2.new(0, xOff, 0, yOff)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    b.Text             = text
    b.TextColor3       = Color3.new(1, 1, 1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 12
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local btnOrbit     = makeBtn("Orbit",  8,   52)
local btnFollow    = makeBtn("Follow", 80,  52)
local btnLeftRight = makeBtn("L-R",    152, 52)

-- ── Slider helper ─────────────────────
local function createSlider(parent, name, minVal, maxVal, initVal, yPos, callback)
    local container = Instance.new("Frame", parent)
    container.Size                 = UDim2.new(1, -16, 0, 24)
    container.Position             = UDim2.new(0, 8, 0, yPos)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0, 50, 0, 14); label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1; label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200); label.Font = Enum.Font.Gotham
    label.TextSize = 11; label.TextXAlignment = Enum.TextXAlignment.Left

    local barBg = Instance.new("Frame", container)
    barBg.Size = UDim2.new(1, -70, 0, 10); barBg.Position = UDim2.new(0, 60, 0, 2)
    barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70); barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 5)

    local fill = Instance.new("Frame", barBg)
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    fill.BorderSizePixel = 0; Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local knob = Instance.new("TextButton", barBg)
    knob.Size = UDim2.new(0, 18, 0, 18); knob.Position = UDim2.new(0, -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 255); knob.Text = ""
    knob.AutoButtonColor = false; Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local valLabel = Instance.new("TextLabel", container)
    valLabel.Size = UDim2.new(0, 30, 0, 14); valLabel.Position = UDim2.new(1, -30, 0, 0)
    valLabel.BackgroundTransparency = 1; valLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLabel.Font = Enum.Font.Gotham; valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local value = initVal
    local function updateUI()
        local frac  = (value - minVal) / (maxVal - minVal)
        local knobX = frac * (barBg.AbsoluteSize.X - knob.AbsoluteSize.X)
        knob.Position = UDim2.new(0, knobX, 0.5, -knob.AbsoluteSize.Y / 2)
        fill.Size     = UDim2.new(frac, 0, 1, 0)
        valLabel.Text = string.format("%.1f", value)
    end
    local function setValue(newVal)
        value = math.clamp(newVal, minVal, maxVal)
        updateUI(); callback(value)
    end

    knob.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local barMin = barBg.AbsolutePosition.X + knob.AbsoluteSize.X / 2
            local barMax = barBg.AbsolutePosition.X + barBg.AbsoluteSize.X - knob.AbsoluteSize.X / 2
            setValue(minVal + math.clamp((input.Position.X - barMin) / (barMax - barMin), 0, 1) * (maxVal - minVal))
        end
    end)
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local barMin = barBg.AbsolutePosition.X + knob.AbsoluteSize.X / 2
            local barMax = barBg.AbsolutePosition.X + barBg.AbsoluteSize.X - knob.AbsoluteSize.X / 2
            setValue(minVal + math.clamp((input.Position.X - barMin) / (barMax - barMin), 0, 1) * (maxVal - minVal))
        end
    end)

    setValue(initVal)
    return { SetValue = setValue, GetValue = function() return value end }
end

local radiusSlider = createSlider(panel, "Radius", 2, 20, ORBIT_RADIUS, 84,  function(v) ORBIT_RADIUS = v end)
local speedSlider  = createSlider(panel, "Speed",  0.2, 5, ORBIT_SPEED,  108, function(v) ORBIT_SPEED  = v end)

-- Info kecil
local lblInfo = Instance.new("TextLabel", panel)
lblInfo.Size                 = UDim2.new(1, -10, 0, 16)
lblInfo.Position             = UDim2.new(0, 8, 0, 136)
lblInfo.BackgroundTransparency = 1
lblInfo.Text                 = "Letakkan 1 tenda manual dulu"
lblInfo.TextColor3           = Color3.fromRGB(150, 150, 170)
lblInfo.Font                 = Enum.Font.Gotham
lblInfo.TextSize             = 10
lblInfo.TextXAlignment       = Enum.TextXAlignment.Left

-- ── Ball Follow button ────────────────
local btnBallFollow = makeBtn("Ball Follow: OFF", 8, 158, 204)

-- ── Naik / Turun bola ─────────────────
local btnUp   = makeBtn("+ Naik",  8,   188, 90)
local btnDown = makeBtn("- Turun", 116, 188, 90)
btnUp.BackgroundColor3   = Color3.fromRGB(0, 150, 0)
btnDown.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
btnUp.Visible   = false
btnDown.Visible = false

-- ══════════════════════════════════════
--   BUTTON STATE UPDATER
-- ══════════════════════════════════════
local function setButtonStates()
    btnOrbit.BackgroundColor3      = (currentMode == "orbit")     and Color3.fromRGB(100,70,200) or Color3.fromRGB(40,40,50)
    btnFollow.BackgroundColor3     = (currentMode == "follow")    and Color3.fromRGB(100,70,200) or Color3.fromRGB(40,40,50)
    btnLeftRight.BackgroundColor3  = (currentMode == "leftright") and Color3.fromRGB(100,70,200) or Color3.fromRGB(40,40,50)
    btnBallFollow.BackgroundColor3 = ballFollowActive and Color3.fromRGB(0,160,80) or Color3.fromRGB(40,40,50)
    btnBallFollow.Text             = "Ball Follow: " .. (ballFollowActive and "ON" or "OFF")
    btnUp.Visible   = ballFollowActive
    btnDown.Visible = ballFollowActive
    -- Sesuaikan PANEL_H_FULL kalau ball follow ON (butuh ruang tombol naik/turun)
    PANEL_H_FULL = ballFollowActive and 220 or 210
    if not isMinimized then
        TweenService:Create(panel, TweenInfo.new(0.12), { Size = UDim2.new(0, 220, 0, PANEL_H_FULL) }):Play()
    end
end
setButtonStates()

-- ══════════════════════════════════════
--   TENT SPAWN & DETECT
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
                newFolder = child; break
            end
        end
        if newFolder then break end
        task.wait(0.1)
    end
    if not newFolder then warn("Folder tenda baru tidak muncul!"); return nil end

    local part = newFolder:FindFirstChild("Part")
        or newFolder:FindFirstChild("Wedge")
        or newFolder:FindFirstChildWhichIsA("BasePart")
    if not part then warn("Part tidak ditemukan!"); return nil end

    local targetPos = getTargetPosition()
    if targetPos then
        local randomAngle = math.random() * math.pi * 2
        local x = math.cos(randomAngle) * ORBIT_RADIUS
        local z = math.sin(randomAngle) * ORBIT_RADIUS
        pcall(function() workspace[PLAYER_NAME].PropMaker.Tool_PropMake:FireServer(part) end)
        task.wait(0.2)
        pcall(function()
            newFolder.SetCurrentCFrame:InvokeServer(CFrame.new(
                targetPos.X + x, targetPos.Y + 0.025, targetPos.Z + z
            ))
        end)
        task.wait(0.2)
    end
    return newFolder
end

local function refreshTents()
    tentFolders = getExistingTents()
    if #tentFolders == 0 then return false end
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
--   MODE UPDATES
-- ══════════════════════════════════════
local function updateOrbit(dt)
    orbitAngle = (orbitAngle + ORBIT_SPEED * dt) % (math.pi * 2)
    local targetPos = getTargetPosition()
    if not targetPos then return end
    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local angle = orbitAngle + (i - 1) * (math.pi * 2 / #tentFolders)
            pcall(function()
                folder.SetCurrentCFrame:InvokeServer(CFrame.new(
                    targetPos.X + math.cos(angle) * ORBIT_RADIUS,
                    targetPos.Y + 0.025,
                    targetPos.Z + math.sin(angle) * ORBIT_RADIUS
                ))
            end)
        else
            table.remove(tentFolders, i)
            lblStatus.Text = string.format("Tenda %d hilang", i)
        end
    end
end

local function updateFollow(dt)
    local hrp       = getHRP()
    local targetPos = getTargetPosition()
    if not hrp or not targetPos then return end
    local look    = hrp.CFrame.LookVector
    local basePos = targetPos + look * (-4)
    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local off = (i - 1) * 3
            pcall(function()
                folder.SetCurrentCFrame:InvokeServer(CFrame.new(
                    basePos.X + look.X * (-off),
                    basePos.Y + 0.025,
                    basePos.Z + look.Z * (-off)
                ))
            end)
        else
            table.remove(tentFolders, i)
        end
    end
end

local function updateLeftRight(dt)
    local hrp       = getHRP()
    local targetPos = getTargetPosition()
    if not hrp or not targetPos then return end
    local baseCF  = hrp.CFrame
    local t       = os.clock() * 0.8
    local baseWithOrient = CFrame.new(targetPos) * (baseCF - baseCF.Position) * CFrame.new(0, 0, -4)
    for i = #tentFolders, 1, -1 do
        local folder = tentFolders[i]
        if folder and folder.Parent then
            local offsetX = 10 * math.sin(t + (i % 2 == 0 and 0 or math.pi))
            pcall(function()
                folder.SetCurrentCFrame:InvokeServer(baseWithOrient * CFrame.new(offsetX, 0.025, 0))
            end)
        else
            table.remove(tentFolders, i)
        end
    end
end

-- ── Main loop ─────────────────────────
local function startLoop()
    if orbitConnection then return end
    orbitConnection = RunService.Heartbeat:Connect(function(dt)
        if     currentMode == "orbit"     then updateOrbit(dt)
        elseif currentMode == "follow"    then updateFollow(dt)
        elseif currentMode == "leftright" then updateLeftRight(dt)
        end
    end)
end

local function stopLoop()
    if orbitConnection then orbitConnection:Disconnect(); orbitConnection = nil end
end

local function setMode(newMode)
    if currentMode == newMode then
        currentMode = "none"
        lblStatus.Text = "Status: idle"
        stopLoop(); tentFolders = {}
        setButtonStates(); return
    end
    stopLoop(); tentFolders = {}
    currentMode = newMode
    local success = refreshTents()
    if not success then
        lblStatus.Text = "Status: tidak ada tenda, letakkan manual"
        currentMode = "none"; setButtonStates(); return
    end
    local target = ballFollowActive and "bola" or "player"
    lblStatus.Text = string.format("Status: %s aktif, %d tenda → %s", newMode, #tentFolders, target)
    startLoop(); setButtonStates()
end

-- ══════════════════════════════════════
--   BALL FOLLOW TOGGLE
-- ══════════════════════════════════════
local ballLoopConnection = nil

local function startBallLoop()
    if ballLoopConnection then return end
    ballLoopConnection = RunService.RenderStepped:Connect(function()
        if ballFollowActive and ball and ball:FindFirstChild("LinearVelocity") then
            local hum     = getHumanoid()
            local moveDir = hum and hum.MoveDirection or Vector3.zero
            local final   = Vector3.new(moveDir.X, verticalMove, moveDir.Z)
            ball.LinearVelocity.VectorVelocity = final.Magnitude > 0
                and final.Unit * ballSpeed
                or Vector3.zero
        end
    end)
end

local function stopBallLoop()
    if ballLoopConnection then ballLoopConnection:Disconnect(); ballLoopConnection = nil end
end

local function restartModeWithNewTarget()
    if currentMode ~= "none" then
        local saved = currentMode
        stopLoop(); tentFolders = {}
        currentMode = saved
        if refreshTents() then startLoop() end
        local target = ballFollowActive and "bola" or "player"
        lblStatus.Text = string.format("Status: %s → %s", currentMode, target)
    end
end

btnBallFollow.MouseButton1Click:Connect(function()
    ballFollowActive = not ballFollowActive
    local hum = getHumanoid()

    if ballFollowActive then
        spawnBall()
        Camera.CameraSubject = ball
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
        startBallLoop()
    else
        stopBallLoop()
        destroyBall()
        Camera.CameraSubject = hum
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        verticalMove = 0
    end

    setButtonStates()
    restartModeWithNewTarget()
end)

btnUp.MouseButton1Down:Connect(function()   verticalMove =  1 end)
btnUp.MouseButton1Up:Connect(function()     verticalMove =  0 end)
btnDown.MouseButton1Down:Connect(function() verticalMove = -1 end)
btnDown.MouseButton1Up:Connect(function()   verticalMove =  0 end)

-- ── Mode button events ────────────────
btnOrbit.MouseButton1Click:Connect(function()     setMode("orbit")     end)
btnFollow.MouseButton1Click:Connect(function()    setMode("follow")    end)
btnLeftRight.MouseButton1Click:Connect(function() setMode("leftright") end)

-- ══════════════════════════════════════
--   RESPAWN HANDLER
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    stopLoop()
    stopBallLoop()
    destroyBall()
    ballFollowActive = false
    currentMode      = "none"
    tentFolders      = {}
    verticalMove     = 0
    task.wait(1)
    local hum = newChar:WaitForChild("Humanoid")
    Camera.CameraSubject = hum
    lblStatus.Text = "Status: respawned"
    setButtonStates()
end)

print("[OK] Tent Orbit v4 + Ball Follow loaded –", PLAYER_NAME)
