-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Vars
local ballActive = false
local ball, bv
local plusBtn, minusBtn, scanBtn, selectLabel, prevBtn, nextBtn
local setObjects = {}                -- daftar objek yang sudah di-set (persist hijau)
local espFolder = Instance.new("Folder", Workspace)
espFolder.Name = "ESP_Sets"
local verticalMove = 0
local ballSpeed = 70
local scanActive = false
local scanResults = {}
local currentIndex = 1
local redESP = nil                    -- highlight merah sementara untuk pilihan
local tpSequenceRunning = false

-- GUI root
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

-- main draggable CK
local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 40, 0, 40)
mainFrame.Position = UDim2.new(0.85, 0, 0.4, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.ZIndex = 3

local CK = Instance.new("TextButton", mainFrame)
CK.Size = UDim2.new(1,0,1,0)
CK.Text = "CK"
CK.TextSize = 14
CK.Font = Enum.Font.GothamBold
CK.BackgroundColor3 = Color3.fromRGB(40,40,40)
CK.TextColor3 = Color3.new(1,1,1)
CK.ZIndex = 4
local corner = Instance.new("UICorner", CK)
corner.CornerRadius = UDim.new(1,0)

-- menu list (hidden)
local buttonFrame = Instance.new("Frame", mainFrame)
buttonFrame.Size = UDim2.new(0, 160, 0, 320)
buttonFrame.Position = UDim2.new(1, 10, 0, 0)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Visible = false
buttonFrame.ZIndex = 4

local function makeBtn(name, order)
    local btn = Instance.new("TextButton", buttonFrame)
    btn.Size = UDim2.new(0, 160, 0, 28)
    btn.Position = UDim2.new(0, 0, 0, (order-1)*34)
    btn.Text = name
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.ZIndex = 4
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,6)
    return btn
end

local BallBtn   = makeBtn("Ball: OFF", 1)
local SetBtn    = makeBtn("Set", 2)
local ResetBtn  = makeBtn("Reset", 3)
local TpNowBtn  = makeBtn("TpNow", 4)
local GravBtn   = makeBtn("AntiGrav: OFF", 5)
local NoClipBtn = makeBtn("NoClip: OFF", 6)

-- utils
local function notify(text, time)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Info"; Text = text; Duration = time or 2})
    end)
end

local function alreadySet(part)
    for _, p in ipairs(setObjects) do
        if p == part then return true end
    end
    return false
end

-- tambahkan ESP hijau permanen (set)
local function addESP(obj)
    if not obj or not obj:IsA("BasePart") then return end
    for _, h in ipairs(espFolder:GetChildren()) do
        if h:IsA("Highlight") and h.Adornee == obj then return end
    end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = obj
    highlight.FillColor = Color3.fromRGB(0, 200, 50) -- hijau set
    highlight.OutlineColor = Color3.fromRGB(0,0,0)
    highlight.Parent = espFolder
end

-- red temporary highlight (pilihan)
local function clearRedESP()
    if redESP then redESP:Destroy() redESP = nil end
end

local function setRedESP(obj)
    clearRedESP()
    if not obj or not obj:IsA("BasePart") then return end
    redESP = Instance.new("Highlight")
    redESP.Adornee = obj
    redESP.FillColor = Color3.fromRGB(200, 0, 0) -- merah scanning
    redESP.OutlineColor = Color3.fromRGB(0,0,0)
    redESP.Parent = espFolder
end

-- scanning: cari BasePart dalam radius 5 (skip ball, skip Terrain, skip player's character, skip already set)
local function scanAroundBall()
    if not (ballActive and ball and scanActive) then return end
    scanResults = {}
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart")
        and part ~= ball
        and not alreadySet(part)
        and not part:IsDescendantOf(LocalPlayer.Character)
        and part.Name ~= "Terrain"
        and (part.Position - ball.Position).Magnitude <= 5 then
            table.insert(scanResults, part)
        end
    end

    if #scanResults > 0 then
        if currentIndex > #scanResults then currentIndex = 1 end
        setRedESP(scanResults[currentIndex])
        if selectLabel then selectLabel.Text = "< " .. tostring(scanResults[currentIndex].Name) .. " >" end
    else
        clearRedESP()
        if selectLabel then selectLabel.Text = "< None >" end
    end
end

-- spawn ball: create ball + create UI buttons as children of mainFrame (so they follow drag)
local function spawnBall()
    if ballActive then return end
    ballActive = true

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")

    ball = Instance.new("Part", Workspace)
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(3.5,3.5,3.5)
    ball.Position = (hrp and hrp.Position or char.PrimaryPart.Position) + Vector3.new(0,5,0)
    ball.Anchored = false
    ball.CanCollide = false
    ball.BrickColor = BrickColor.new("Bright blue")
    ball.Name = "ControlBall"

    bv = Instance.new("BodyVelocity", ball)
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0,0,0)

    -- + and - buttons (placed relative to mainFrame)
    plusBtn = Instance.new("TextButton", mainFrame)
    plusBtn.Size = UDim2.new(0, 34, 0, 34)
    plusBtn.Position = UDim2.new(0, -40, 0, -40)
    plusBtn.Text = "+"
    plusBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    plusBtn.ZIndex = 5
    Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(1,0)

    minusBtn = Instance.new("TextButton", mainFrame)
    minusBtn.Size = UDim2.new(0, 34, 0, 34)
    minusBtn.Position = UDim2.new(0, 6, 0, -40)
    minusBtn.Text = "-"
    minusBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    minusBtn.ZIndex = 5
    Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(1,0)

    -- Scan button + selectLabel + navigation (above +/-)
    scanBtn = Instance.new("TextButton", mainFrame)
    scanBtn.Size = UDim2.new(0, 120, 0, 28)
    scanBtn.Position = UDim2.new(0, -40, 0, -80)
    scanBtn.Text = "ScanObject: OFF"
    scanBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    scanBtn.ZIndex = 5
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0,6)

    selectLabel = Instance.new("TextLabel", mainFrame)
    selectLabel.Size = UDim2.new(0, 120, 0, 28)
    selectLabel.Position = UDim2.new(0, -40, 0, -112)
    selectLabel.Text = "< None >"
    selectLabel.BackgroundColor3 = Color3.fromRGB(60,60,60)
    selectLabel.TextColor3 = Color3.new(1,1,1)
    selectLabel.Font = Enum.Font.Gotham
    selectLabel.TextSize = 13
    selectLabel.ZIndex = 5
    Instance.new("UICorner", selectLabel).CornerRadius = UDim.new(0,6)

    prevBtn = Instance.new("TextButton", mainFrame)
    prevBtn.Size = UDim2.new(0, 28, 0, 28)
    prevBtn.Position = UDim2.new(0, -70, 0, -112)
    prevBtn.Text = "<"
    prevBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    prevBtn.ZIndex = 5
    Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0,6)

    nextBtn = Instance.new("TextButton", mainFrame)
    nextBtn.Size = UDim2.new(0, 28, 0, 28)
    nextBtn.Position = UDim2.new(0, 90, 0, -112)
    nextBtn.Text = ">"
    nextBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    nextBtn.ZIndex = 5
    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0,6)

    -- connections
    plusBtn.MouseButton1Down:Connect(function() verticalMove = 1 end)
    plusBtn.MouseButton1Up:Connect(function() verticalMove = 0 end)
    minusBtn.MouseButton1Down:Connect(function() verticalMove = -1 end)
    minusBtn.MouseButton1Up:Connect(function() verticalMove = 0 end)

    scanBtn.MouseButton1Click:Connect(function()
        scanActive = not scanActive
        scanBtn.Text = "ScanObject: " .. (scanActive and "ON" or "OFF")
        if not scanActive then
            clearRedESP()
            scanResults = {}
            selectLabel.Text = "< None >"
        else
            scanAroundBall()
        end
    end)

    prevBtn.MouseButton1Click:Connect(function()
        if #scanResults > 0 then
            currentIndex = (currentIndex - 2) % #scanResults + 1
            setRedESP(scanResults[currentIndex])
            selectLabel.Text = "< " .. scanResults[currentIndex].Name .. " >"
        end
    end)
    nextBtn.MouseButton1Click:Connect(function()
        if #scanResults > 0 then
            currentIndex = currentIndex % #scanResults + 1
            setRedESP(scanResults[currentIndex])
            selectLabel.Text = "< " .. scanResults[currentIndex].Name .. " >"
        end
    end)

    Camera.CameraSubject = ball
    BallBtn.Text = "Ball: ON"
    notify("Ball aktif", 2)
end

-- remove ball
local function removeBall()
    if not ballActive then return end
    ballActive = false

    if ball and ball.Parent then ball:Destroy() end
    ball = nil
    if bv then bv:Destroy() bv = nil end

    if plusBtn then plusBtn:Destroy() plusBtn = nil end
    if minusBtn then minusBtn:Destroy() minusBtn = nil end
    if scanBtn then scanBtn:Destroy() scanBtn = nil end
    if selectLabel then selectLabel:Destroy() selectLabel = nil end
    if prevBtn then prevBtn:Destroy() prevBtn = nil end
    if nextBtn then nextBtn:Destroy() nextBtn = nil end

    verticalMove = 0
    clearRedESP()
    scanResults = {}
    scanActive = false
    currentIndex = 1

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end

    BallBtn.Text = "Ball: OFF"
    notify("Ball nonaktif", 2)
end

-- Ball toggle
BallBtn.MouseButton1Click:Connect(function()
    if ballActive then removeBall() else spawnBall() end
end)

-- Set (use currently red highlighted object)
SetBtn.MouseButton1Click:Connect(function()
    if not redESP then
        notify("Tidak ada objek yang dipilih", 2)
        return
    end
    local target = redESP.Adornee
    if not target or not target:IsA("BasePart") then
        notify("Objek tidak valid", 2)
        return
    end
    if alreadySet(target) then
        notify("Objek sudah diset", 2)
        return
    end
    table.insert(setObjects, target)
    addESP(target) -- highlight hijau permanen
    notify("Objek diset: " .. tostring(target.Name), 2)

    -- hilangkan dari hasil scan
    for i = #scanResults, 1, -1 do
        if scanResults[i] == target then table.remove(scanResults, i) end
    end
    if #scanResults > 0 then
        currentIndex = ((currentIndex-1) % #scanResults) + 1
        setRedESP(scanResults[currentIndex])
        selectLabel.Text = "< " .. scanResults[currentIndex].Name .. " >"
    else
        clearRedESP()
        selectLabel.Text = "< None >"
    end
end)

-- Reset
ResetBtn.MouseButton1Click:Connect(function()
    setObjects = {}
    espFolder:ClearAllChildren()
    clearRedESP()
    scanResults = {}
    notify("Semua set direset",2)
end)

-- TpNow: perform super-fast sequential teleports to each set, then return to saved pos
TpNowBtn.MouseButton1Click:Connect(function()
    if tpSequenceRunning then
        notify("Teleport sequence already running", 2)
        return
    end
    if #setObjects == 0 then
        notify("Belum ada objek diset",2)
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then notify("Karakter tidak tersedia",2); return end

    tpSequenceRunning = true
    notify("Teleport sequence start", 1)

    -- simpan posisi awal
    local savedCFrame = hrp.CFrame

    -- super fast teleport to each setObject, brief tiny wait to allow engine update
    -- note: extremely small waits, visual nearly invisible
    for _, obj in ipairs(setObjects) do
        if not (obj and obj:IsA("BasePart") and obj.Parent) then
            -- skip invalid
        else
            -- place HRP so that head intersects/near top of object:
            local targetCFrame = obj.CFrame + Vector3.new(0, (hrp.Size and hrp.Size.Y or 2)/2, 0)
            hrp.CFrame = targetCFrame
            -- tiny wait; make as small as engine permits
            task.wait(0.001)
        end
    end

    -- kembali ke posisi semula; ulang beberapa kali bila posisi belum benar (karena lag/anticheat)
    local attempts = 0
    local maxAttempts = 60 -- up to ~60ms attempts * 0.001 waits, adjust if needed
    while attempts < maxAttempts do
        hrp.CFrame = savedCFrame
        task.wait(0.001)
        if (hrp.Position - savedCFrame.Position).Magnitude <= 1 then
            break
        end
        attempts = attempts + 1
    end

    -- final ensure
    hrp.CFrame = savedCFrame
    tpSequenceRunning = false
    notify("Teleport sequence selesai", 1)
end)

-- AntiGrav
GravBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = not hum.PlatformStand
        GravBtn.Text = "AntiGrav: " .. (hum.PlatformStand and "ON" or "OFF")
    end
end)

-- NoClip (toggles)
NoClipBtn.MouseButton1Click:Connect(function()
    local state = NoClipBtn:GetAttribute("state") or false
    state = not state
    NoClipBtn:SetAttribute("state", state)
    if state then
        -- enable
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    end
    NoClipBtn.Text = "NoClip: " .. (state and "ON" or "OFF")
end)

-- Drag support (mobile & PC) for mainFrame using CK
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

CK.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- if this is a click (not dragging), we still allow toggle via MouseButton1Click below
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

CK.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- toggle menu (keep separate from InputBegan to avoid conflict)
CK.MouseButton1Click:Connect(function()
    -- only toggle if not dragging (debounce small)
    if not dragging then
        buttonFrame.Visible = not buttonFrame.Visible
    end
end)

-- scanning + ball movement loop
RunService.RenderStepped:Connect(function()
    if ballActive and ball and bv then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local moveDir = hum and hum.MoveDirection or Vector3.zero
        local finalMove = Vector3.new(moveDir.X, verticalMove*0.9, moveDir.Z)
        bv.Velocity = (finalMove.Magnitude > 0) and (finalMove.Unit * ballSpeed) or Vector3.zero
    end

    if scanActive then
        scanAroundBall()
    end
end)
