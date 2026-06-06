-- ══════════════════════════════════════
--   Boat Spin Panel  |  by BmSky
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

local isRunning = false

local SPAWN_POS = Vector3.new(1697, -6, 344)
local ROUTE = {
    Vector3.new(-94, 1, -62),
    Vector3.new(-28, 1, -6),
    Vector3.new(14,  1, -61),
    Vector3.new(-94, 1, -62),
}
local DETECT_RADIUS   = 25
local DRIVER_KEYWORDS = {"driver","kemudi","pengemudi","supir","main","utama","steering","control"}

local function IsDriverSeat(seat)
    if seat:IsA("VehicleSeat") then return true end
    local n = seat.Name:lower()
    for _, kw in ipairs(DRIVER_KEYWORDS) do
        if n:find(kw) then return true end
    end
    return false
end

local function GetNearestSeat(hrp, preferDriver)
    local nearest, minDist = nil, DETECT_RADIUS
    for _, m in pairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LocalPlayer.Character then
            for _, s in pairs(m:GetDescendants()) do
                if (s:IsA("VehicleSeat") or s:IsA("Seat")) and s.Occupant == nil then
                    if (not preferDriver) or IsDriverSeat(s) then
                        local d = (hrp.Position - s.Position).Magnitude
                        if d < minDist then minDist = d; nearest = s end
                    end
                end
            end
        end
    end
    return nearest
end

local function IsInVehicle()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.SeatPart ~= nil
end

-- ══════════════════════════════════════
--   GUI
-- ══════════════════════════════════════
if PlayerGui:FindFirstChild("BoatSpinGui") then
    PlayerGui.BoatSpinGui:Destroy()
end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name           = "BoatSpinGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

local C = {
    BG      = Color3.fromRGB(12, 18, 28),
    Header  = Color3.fromRGB(15, 45, 80),
    HText   = Color3.fromRGB(130, 200, 255),
    Sep     = Color3.fromRGB(30, 60, 100),
    BtnOn   = Color3.fromRGB(20, 130, 200),
    BtnOff  = Color3.fromRGB(18, 75, 130),
    BtnStop = Color3.fromRGB(160, 30, 30),
    Text    = Color3.fromRGB(210, 230, 255),
    TextDim = Color3.fromRGB(100, 130, 160),
    Green   = Color3.fromRGB(80, 240, 150),
    Yellow  = Color3.fromRGB(255, 215, 60),
}

local panel = Instance.new("Frame", gui)
panel.Size             = UDim2.new(0, 170, 0, 110)
panel.Position         = UDim2.new(0, 220, 0, 200)
panel.BackgroundColor3 = C.BG
panel.BorderSizePixel  = 0
panel.ZIndex           = 10
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = C.Sep; panelStroke.Thickness = 1.2

local header = Instance.new("TextButton", panel)
header.Size             = UDim2.new(1, 0, 0, 24)
header.BackgroundColor3 = C.Header
header.Text             = ""
header.BorderSizePixel  = 0
header.ZIndex           = 11
header.AutoButtonColor  = false
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

local headerLbl = Instance.new("TextLabel", header)
headerLbl.Size             = UDim2.new(1, -10, 1, 0)
headerLbl.Position         = UDim2.new(0, 8, 0, 0)
headerLbl.BackgroundTransparency = 1
headerLbl.Text             = "Boat Spin"
headerLbl.TextColor3       = C.HText
headerLbl.Font             = Enum.Font.GothamBold
headerLbl.TextSize         = 12
headerLbl.TextXAlignment   = Enum.TextXAlignment.Left
headerLbl.ZIndex           = 12

local lblStatus = Instance.new("TextLabel", panel)
lblStatus.Size             = UDim2.new(1, -10, 0, 14)
lblStatus.Position         = UDim2.new(0, 5, 0, 28)
lblStatus.BackgroundTransparency = 1
lblStatus.Text             = "idle"
lblStatus.TextColor3       = C.TextDim
lblStatus.Font             = Enum.Font.Gotham
lblStatus.TextSize         = 10
lblStatus.TextXAlignment   = Enum.TextXAlignment.Left
lblStatus.ZIndex           = 11

local sep = Instance.new("Frame", panel)
sep.Size             = UDim2.new(1, -10, 0, 1)
sep.Position         = UDim2.new(0, 5, 0, 45)
sep.BackgroundColor3 = C.Sep
sep.BorderSizePixel  = 0
sep.ZIndex           = 11

local btnMain = Instance.new("TextButton", panel)
btnMain.Size             = UDim2.new(1, -10, 0, 36)
btnMain.Position         = UDim2.new(0, 5, 0, 52)
btnMain.BackgroundColor3 = C.BtnOff
btnMain.Text             = "get boat and spin"
btnMain.TextColor3       = C.Text
btnMain.Font             = Enum.Font.GothamBold
btnMain.TextSize         = 12
btnMain.BorderSizePixel  = 0
btnMain.ZIndex           = 11
btnMain.AutoButtonColor  = false
Instance.new("UICorner", btnMain).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", btnMain).Color = C.BtnOn

btnMain.MouseEnter:Connect(function()
    if not isRunning then
        TweenService:Create(btnMain, TweenInfo.new(0.1), {BackgroundColor3 = C.BtnOn}):Play()
    end
end)
btnMain.MouseLeave:Connect(function()
    if not isRunning then
        TweenService:Create(btnMain, TweenInfo.new(0.1), {BackgroundColor3 = C.BtnOff}):Play()
    end
end)

-- Drag
do
    local dragging, dStart, wStart = false, nil, nil
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = inp.Position; wStart = panel.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dStart
            panel.Position = UDim2.new(
                wStart.X.Scale, wStart.X.Offset + d.X,
                wStart.Y.Scale, wStart.Y.Offset + d.Y
            )
        end
    end)
end

-- ══════════════════════════════════════
--   HELPER: melayang ke pos sambil spin
-- ══════════════════════════════════════
local MOVE_SPEED = 55   -- studs/detik
local SPIN_RAD   = math.pi * 10  -- radian/detik

local function spinMoveTo(myHRP, targetPos)
    local startPos = myHRP.Position
    local dist     = (targetPos - startPos).Magnitude
    if dist < 0.5 then return true end
    local duration = dist / MOVE_SPEED
    local startT   = tick()
    local angle    = 0
    while isRunning do
        local elapsed = tick() - startT
        local t = math.min(elapsed / duration, 1)
        local curPos = startPos:Lerp(targetPos, t)
        angle = angle + SPIN_RAD * (1/60)
        pcall(function()
            myHRP.CFrame = CFrame.new(curPos) * CFrame.Angles(0, angle, 0)
        end)
        if t >= 1 then return true end
        task.wait(1/60)
    end
    return false
end

-- ══════════════════════════════════════
--   RESET UI helper
-- ══════════════════════════════════════
local function resetUI(statusTxt)
    isRunning = false
    btnMain.BackgroundColor3 = C.BtnOff
    btnMain.Text = "get boat and spin"
    lblStatus.Text = statusTxt or "stopped"
    lblStatus.TextColor3 = C.TextDim
end

-- ══════════════════════════════════════
--   MAIN BUTTON
-- ══════════════════════════════════════
btnMain.MouseButton1Click:Connect(function()
    if isRunning then
        resetUI("stopped")
        return
    end

    isRunning = true
    btnMain.BackgroundColor3 = C.BtnStop
    btnMain.Text = "stop"
    lblStatus.Text = "memulai..."
    lblStatus.TextColor3 = C.Yellow

    task.spawn(function()
        local myChar, myHRP, myHum

        local function refresh()
            myChar = LocalPlayer.Character
            myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            return myChar ~= nil and myHRP ~= nil and myHum ~= nil
        end

        if not refresh() then resetUI("char error"); return end

        -- ── Cek sudah dalam kendaraan atau belum ──
        local skipSetup = IsInVehicle()

        if skipSetup then
            lblStatus.Text = "already veh - skip setup"
            lblStatus.TextColor3 = C.Green
            task.wait(0.4)
        else
            -- 1. Hapus kendaraan
            lblStatus.Text = "hapus kendaraan..."
            pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("DeleteAllVehicles") end)
            task.wait(1.2)
            if not isRunning then resetUI("stopped"); return end

            -- 2. Teleport ke area spawn kapal
            lblStatus.Text = "tp ke spawn point..."
            refresh()
            pcall(function() myHRP.CFrame = CFrame.new(SPAWN_POS) end)
            task.wait(1.2)
            if not isRunning then resetUI("stopped"); return end

            -- 3. Spawn kapal
            lblStatus.Text = "spawn kapal..."
            pcall(function()
                ReplicatedStorage.RE["1Ca1r"]:FireServer("PickingBoat", "PirateFree", "Boat")
            end)
            task.wait(3)
            if not isRunning then resetUI("stopped"); return end

            -- 4. Naik ke kendaraan
            lblStatus.Text = "cari kursi..."
            local seated  = false
            local attempt = 0
            while not seated and attempt < 25 and isRunning do
                attempt = attempt + 1
                refresh()
                if myChar and myHRP and myHum then
                    -- coba driver seat dulu, fallback ke seat apapun
                    local s = GetNearestSeat(myHRP, true)
                    if not s then s = GetNearestSeat(myHRP, false) end
                    if s then
                        pcall(function() myHRP.CFrame = s.CFrame * CFrame.new(0, 1.5, 0) end)
                        task.wait(0.15)
                        pcall(function() s:Sit(myHum) end)
                        task.wait(0.35)
                        if myHum.SeatPart ~= nil then seated = true end
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.4)
                end
            end

            if not seated then
                lblStatus.Text = "gagal naik kapal!"
                lblStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(1.5)
                resetUI("gagal naik kapal")
                return
            end

            lblStatus.Text = "naik kapal ✓"
            lblStatus.TextColor3 = C.Green
            task.wait(0.4)
            if not isRunning then resetUI("stopped"); return end
        end

        -- ── Loop route: spin-move ke setiap titik, bolak-balik ──
        lblStatus.Text = "mulai route..."
        task.wait(0.2)

        -- Pertama teleport langsung ke titik pertama sambil spin sebentar
        refresh()
        if myHRP then
            local firstDest = ROUTE[1]
            lblStatus.Text = string.format("tp ke titik 1")
            -- langsung teleport ke koordinat pertama
            pcall(function() myHRP.CFrame = CFrame.new(firstDest) end)
            task.wait(0.2)
        end

        local routeIdx = 2  -- mulai dari titik kedua setelah teleport ke titik 1
        while isRunning do
            refresh()
            if not myChar or not myHRP then task.wait(0.3); continue end

            local dest = ROUTE[routeIdx]
            lblStatus.Text = string.format("titik %d  (%.0f, %.0f, %.0f)",
                routeIdx, dest.X, dest.Y, dest.Z)
            lblStatus.TextColor3 = C.Green

            local reached = spinMoveTo(myHRP, dest)
            if not reached then break end

            task.wait(0.05)
            -- Maju ke titik berikut, loop kembali ke awal kalau sudah di akhir
            -- Tapi karena titik ke-4 sama dengan titik ke-1 (-94,1,-62),
            -- setelah titik ke-4 lanjut ke titik ke-2 (bukan ke-1 lagi) supaya
            -- loop bola-balik berjalan smooth: 1->2->3->4(=1)->2->3->4...
            if routeIdx == #ROUTE then
                routeIdx = 2
            else
                routeIdx = routeIdx + 1
            end
        end

        resetUI("stopped")
    end)
end)

print("[OK] BoatSpin loaded")
