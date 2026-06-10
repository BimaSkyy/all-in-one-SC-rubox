-- ============================================================
--   BmSkyMods | Truck Him Tool
--   GUI: ImGui-style (draggable + minimizable)
--   Features: Player List, Truck Him / Stop, Spectator
--   Fixed: GUI/setStatus order, Stop Spectator, TrailerRelease klik, delay 5s
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────── Shared State ────────────────────────────
local running             = false
local connection          = nil
local flingConnection     = nil
local savedPosition       = nil
local selectedPlayer      = nil
local isSpectating        = false
local spectateConn        = nil
local stopSpectating_impl = nil  -- diisi saat startSpectate dipanggil

-- ─────────────────── Forward declare setStatus ───────────────
-- Akan diisi setelah GUI dibuat, tapi bisa dipanggil dari mana saja
local setStatus

-- ─────────────────── Helper Functions ────────────────────────
local function disableCarClient()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = true
    end
end

local function enableCarClient()
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local carClient = backpack:FindFirstChild("CarClient")
    if carClient and carClient:IsA("LocalScript") then
        carClient.Disabled = false
    end
end

local function stopFling()
    running = false
    if connection then connection:Disconnect(); connection = nil end
    if flingConnection then flingConnection:Disconnect(); flingConnection = nil end

    disableCarClient()

    pcall(function()
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer("DeleteAllVehicles")
    end)

    local character = LocalPlayer.Character
    if character then
        local myHRP    = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if myHRP and savedPosition then
            pcall(function()
                myHRP.Anchored = true
                myHRP.CFrame   = CFrame.new(savedPosition + Vector3.new(0, 5, 0))
                task.wait(0.2)
                myHRP.Velocity    = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
                myHRP.Anchored    = false
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide  = true
                part.Velocity    = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
        local myHumanoid = character:FindFirstChild("Humanoid")
        if myHumanoid then
            myHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        end
    end

    for _, seat in ipairs(Workspace:GetDescendants()) do
        if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
            seat.Disabled = false
        end
    end
    pcall(function()
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Clothe1s"):FireServer("CharacterSizeUp", 1)
    end)
end

-- ─────────────────── Truck Him Core ──────────────────────────
local function flingWithTruck(targetPlayer, onStop)
    if not targetPlayer or not targetPlayer.Character or not LocalPlayer.Character then return end
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid  = character:FindFirstChildOfClass("Humanoid")
    local myHRP     = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not myHRP then return end

    savedPosition = myHRP.Position

    local TRUK_POS_ASLI      = CFrame.new(Vector3.new(1176.56, 79.90, -1166.65))
    local BATAS_JARAK_AMAN   = 3
    local TARIK_KEMBALI      = 0.3
    local KECEPATAN_MAKSIMAL = 120

    -- 1) Teleport ke posisi spawn truk
    pcall(function()
        myHRP.Anchored = true
        myHRP.CFrame   = CFrame.new(Vector3.new(1181.83, 76.08, -1158.83))
        task.wait(0.2)
        myHRP.Velocity    = Vector3.zero
        myHRP.RotVelocity = Vector3.zero
        myHRP.Anchored    = false
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
    task.wait(0.5)

    -- 2) Bersihkan kendaraan lama
    disableCarClient()
    pcall(function()
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer("DeleteAllVehicles")
    end)
    task.wait(0.5)

    -- 3) Spawn truk Semi
    pcall(function()
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer("PickingCar", "Semi")
    end)
    task.wait(1.5)

    -- 4) Cari truk
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not vehiclesFolder then stopFling(); if onStop then onStop() end return end
    local truckName = LocalPlayer.Name .. "Car"
    local truck = vehiclesFolder:FindFirstChild(truckName)
    if not truck then stopFling(); if onStop then onStop() end return end

    -- Atur fisika awal
    pcall(function()
        truck:PivotTo(TRUK_POS_ASLI)
        for _, part in ipairs(truck:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored    = false
                part.CanCollide  = true
                part.Velocity    = Vector3.zero
                part.RotVelocity = Vector3.zero
                part:SetNetworkOwner(nil)
                part.CustomPhysicalProperties = PhysicalProperties.new(3, 0.5, 0.3)
            end
        end
    end)

    -- 5) Teleport dekat kursi
    pcall(function()
        myHRP.Anchored = true
        myHRP.CFrame   = TRUK_POS_ASLI * CFrame.new(0, 2, -5)
        task.wait(0.2)
        myHRP.Velocity    = Vector3.zero
        myHRP.RotVelocity = Vector3.zero
        myHRP.Anchored    = false
    end)

    -- 6) Tunggu masuk duduk
    local sitStart = tick()
    repeat
        task.wait()
        if tick() - sitStart > 12 then
            if setStatus then setStatus("Gagal masuk truk!", Color3.fromRGB(220,100,100)) end
            stopFling(); if onStop then onStop() end return
        end
    until humanoid.Sit

    -- ✅ 6b) Klik TrailerRelease setelah masuk
    if setStatus then setStatus("Naik truk, klik TrailerRelease...", Color3.fromRGB(100, 180, 255)) end
    pcall(function()
        local body = truck:FindFirstChild("Body")
        if body then
            local trailerRelease = body:FindFirstChild("TrailerRelease")
            if trailerRelease then
                local clickDet = trailerRelease:FindFirstChild("ClickDetector")
                if clickDet then
                    fireclickdetector(clickDet)
                    print("✅ TrailerRelease diklik!")
                else
                    warn("⚠ ClickDetector tidak ditemukan di TrailerRelease")
                end
            else
                warn("⚠ TrailerRelease tidak ditemukan di Body")
            end
        else
            warn("⚠ Body tidak ditemukan di truk")
        end
    end)
    task.wait(0.3)

    -- ✅ Delay 5 detik
    if setStatus then setStatus("Sudah naik, tunggu 5 detik...", Color3.fromRGB(100, 180, 255)) end
    task.wait(5)
    if setStatus then setStatus("Memulai aksi...", Color3.fromRGB(100, 220, 130)) end

    -- Setelah masuk: reset fisika
    pcall(function()
        truck:PivotTo(TRUK_POS_ASLI)
        for _, part in ipairs(truck:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "Trailer" then
                part.Anchored    = false
                part.CanCollide  = true
                part:SetNetworkOwner(nil)
                part.CustomPhysicalProperties = PhysicalProperties.new(3, 0.5, 0.3)
            end
        end
    end)

    -- Trailer
    local trailer = truck:FindFirstChild("Body") and truck.Body:FindFirstChild("Trailer")
    if not trailer then stopFling(); if onStop then onStop() end return end
    pcall(function()
        trailer.Anchored    = true
        trailer.CanCollide  = false
        trailer.Transparency = 0
        trailer:SetNetworkOwner(nil)
    end)

    -- 7) Loop utama PENGAMAN
    running = true
    connection = RunService.Stepped:Connect(function()
        if not running then return end

        local posSekarang = truck:GetPivot().Position
        local jarak = (posSekarang - TRUK_POS_ASLI.Position).Magnitude
        if jarak > BATAS_JARAK_AMAN then
            truck:PivotTo(truck:GetPivot():Lerp(TRUK_POS_ASLI, TARIK_KEMBALI))
        end

        for _, part in ipairs(truck:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "Trailer" then
                if part.Velocity.Magnitude > KECEPATAN_MAKSIMAL then
                    part.Velocity = part.Velocity.Unit * KECEPATAN_MAKSIMAL
                end
                part.RotVelocity = part.RotVelocity * 0.7
                part.Velocity    = part.Velocity + Vector3.new(0, -15, 0)
            end
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)

    local startTime     = tick()
    local lastFlingTime = 0
    flingConnection = RunService.Heartbeat:Connect(function()
        if not running then return end
        if not targetPlayer or not targetPlayer.Character then running = false return end
        local newTargetHRP      = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local newTargetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if not newTargetHRP or not newTargetHumanoid then running = false return end
        if not myHRP or not humanoid then running = false return end

        local getaran = math.sin(tick() * 25) * 2.5
        pcall(function()
            trailer:PivotTo(CFrame.new(newTargetHRP.Position + Vector3.new(0, getaran, 0)))
        end)

        local jarakTrailer = (trailer.Position - newTargetHRP.Position).Magnitude
        if jarakTrailer < 5 and tick() - lastFlingTime > 0.3 then
            lastFlingTime = tick()
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            local fling = Instance.new("BodyVelocity")
            fling.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            fling.Velocity = Vector3.new(
                math.random(-8,8), 50, math.random(-8,8)
            ).Unit * 750000 + Vector3.new(0, 320000, 0)
            fling.Parent = newTargetHRP
            task.delay(0.3, function()
                fling:Destroy()
                for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end)
        end

        local targetDuduk = false
        for _, seat in ipairs(truck:GetDescendants()) do
            if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant == newTargetHumanoid then
                targetDuduk = true; break
            end
        end

        if targetDuduk or tick() - startTime > 12 then
            running = false
            if connection then connection:Disconnect(); connection = nil end
            if flingConnection then flingConnection:Disconnect(); flingConnection = nil end
            pcall(function() truck:Destroy() end)
            task.wait(0.3)
            stopFling()
            if onStop then onStop() end
        end
    end)
end

-- ─────────────────── Spectator ───────────────────────────────
local function startSpectate(targetPlayer)
    -- Definisi ulang setiap kali startSpectate dipanggil
    stopSpectating_impl = function()
        isSpectating = false
        if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
        local cam = Workspace.CurrentCamera
        cam.CameraType    = Enum.CameraType.Custom
        cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end

    if isSpectating then stopSpectating_impl() end
    if not targetPlayer or not targetPlayer.Character then return end

    isSpectating = true
    local cam = Workspace.CurrentCamera
    cam.CameraType    = Enum.CameraType.Custom
    cam.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

    spectateConn = Players.PlayerRemoving:Connect(function(p)
        if p == targetPlayer then stopSpectating_impl() end
    end)
end

local function stopSpectate()
    if stopSpectating_impl then
        stopSpectating_impl()
    else
        -- Fallback jika stopSpectating_impl belum diisi
        isSpectating = false
        if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
        local cam = Workspace.CurrentCamera
        cam.CameraType    = Enum.CameraType.Custom
        cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end

-- ═══════════════════════════════════════════════════════════
--  G U I  (dibuat sebelum setStatus didefinisikan)
-- ═══════════════════════════════════════════════════════════
if PlayerGui:FindFirstChild("BmSkyTruckGui") then
    PlayerGui.BmSkyTruckGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "BmSkyTruckGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- Warna tema ImGui-dark
local C = {
    Bg        = Color3.fromRGB(30,  30,  35),
    Header    = Color3.fromRGB(22,  22,  27),
    Accent    = Color3.fromRGB(90,  60, 200),
    AccentHov = Color3.fromRGB(110, 80, 220),
    AccentRed = Color3.fromRGB(180, 40,  40),
    AccentRedH= Color3.fromRGB(210, 60,  60),
    AccentGrn = Color3.fromRGB(40, 160,  80),
    AccentGrnH= Color3.fromRGB(60, 190, 100),
    Text      = Color3.fromRGB(230, 230, 230),
    TextDim   = Color3.fromRGB(140, 140, 155),
    Border    = Color3.fromRGB(55,  55,  65),
    Row       = Color3.fromRGB(38,  38,  46),
    RowSel    = Color3.fromRGB(70,  50, 160),
    Item      = Color3.fromRGB(48,  48,  58),
}

local function applyCorner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 5)
end
local function applyStroke(parent, color, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color     = color or C.Border
    s.Thickness = thick or 1
end
local function makeLabel(parent, text, size, color, weight)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text           = text
    l.TextColor3     = color or C.Text
    l.TextSize       = size  or 13
    l.Font           = weight or Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end
local function makeBtn(parent, text, bg, bgHov)
    local btn = Instance.new("TextButton", parent)
    btn.BackgroundColor3 = bg or C.Accent
    btn.TextColor3       = C.Text
    btn.TextSize         = 13
    btn.Font             = Enum.Font.GothamBold
    btn.Text             = text
    btn.AutoButtonColor  = false
    applyCorner(btn, 4)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = bgHov or C.AccentHov end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = bg    or C.Accent    end)
    return btn
end

-- Jendela utama
local Window = Instance.new("Frame", ScreenGui)
Window.Name             = "Window"
Window.Size             = UDim2.new(0, 300, 0, 380)
Window.Position         = UDim2.new(0.5, -150, 0.5, -190)
Window.BackgroundColor3 = C.Bg
Window.BorderSizePixel  = 0
Window.ClipsDescendants = true
applyCorner(Window, 7)
applyStroke(Window, C.Border, 1)

-- Title bar
local TitleBar = Instance.new("Frame", Window)
TitleBar.Size             = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = C.Header
TitleBar.BorderSizePixel  = 0
applyCorner(TitleBar, 7)

local TitleLabel = makeLabel(TitleBar, "  🚚  BmSkyMods | Truck Tool", 14, C.Text, Enum.Font.GothamBold)
TitleLabel.Size     = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = UDim2.new(0, 24, 0, 24)
MinBtn.Position         = UDim2.new(1, -54, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
MinBtn.TextColor3       = Color3.fromRGB(50, 30, 0)
MinBtn.Text             = "—"
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 14
MinBtn.AutoButtonColor  = false
applyCorner(MinBtn, 12)
MinBtn.MouseEnter:Connect(function() MinBtn.BackgroundColor3 = Color3.fromRGB(255,200,80) end)
MinBtn.MouseLeave:Connect(function() MinBtn.BackgroundColor3 = Color3.fromRGB(255,165,0)  end)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.new(0, 24, 0, 24)
CloseBtn.Position         = UDim2.new(1, -26, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 14
CloseBtn.AutoButtonColor  = false
applyCorner(CloseBtn, 12)
CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundColor3 = Color3.fromRGB(240,80,80) end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50) end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Body
local Body = Instance.new("Frame", Window)
Body.Name                   = "Body"
Body.Size                   = UDim2.new(1, 0, 1, -32)
Body.Position               = UDim2.new(0, 0, 0, 32)
Body.BackgroundTransparency = 1

-- Player List section
local PlrListHeader = Instance.new("Frame", Body)
PlrListHeader.Size             = UDim2.new(1, -16, 0, 30)
PlrListHeader.Position         = UDim2.new(0, 8, 0, 8)
PlrListHeader.BackgroundColor3 = C.Header
PlrListHeader.BorderSizePixel  = 0
applyCorner(PlrListHeader, 5)
applyStroke(PlrListHeader, C.Border)

local PlrListLabel = makeLabel(PlrListHeader, " 👥  Player List", 13, C.TextDim)
PlrListLabel.Size     = UDim2.new(1, -80, 1, 0)
PlrListLabel.Position = UDim2.new(0, 0, 0, 0)

local RefreshBtn = makeBtn(PlrListHeader, "↻ Refresh", C.Item, C.Border)
RefreshBtn.Size     = UDim2.new(0, 72, 0, 22)
RefreshBtn.Position = UDim2.new(1, -78, 0.5, -11)
RefreshBtn.TextSize = 12

local ScrollOuter = Instance.new("Frame", Body)
ScrollOuter.Size             = UDim2.new(1, -16, 0, 150)
ScrollOuter.Position         = UDim2.new(0, 8, 0, 46)
ScrollOuter.BackgroundColor3 = C.Header
ScrollOuter.BorderSizePixel  = 0
applyCorner(ScrollOuter, 5)
applyStroke(ScrollOuter, C.Border)

local ScrollFrame = Instance.new("ScrollingFrame", ScrollOuter)
ScrollFrame.Size                 = UDim2.new(1, -4, 1, -4)
ScrollFrame.Position             = UDim2.new(0, 2, 0, 2)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel      = 0
ScrollFrame.ScrollBarThickness   = 4
ScrollFrame.ScrollBarImageColor3 = C.Accent
ScrollFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 2)

local ListPadding = Instance.new("UIPadding", ScrollFrame)
ListPadding.PaddingLeft  = UDim.new(0, 4)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.PaddingTop   = UDim.new(0, 4)

local Divider = Instance.new("Frame", Body)
Divider.Size             = UDim2.new(1, -16, 0, 1)
Divider.Position         = UDim2.new(0, 8, 0, 204)
Divider.BackgroundColor3 = C.Border
Divider.BorderSizePixel  = 0

local SelLabel = makeLabel(Body, "  Selected: —", 12, C.TextDim)
SelLabel.Size     = UDim2.new(1, -16, 0, 22)
SelLabel.Position = UDim2.new(0, 8, 0, 212)

local ActionFrame = Instance.new("Frame", Body)
ActionFrame.Size                   = UDim2.new(1, -16, 0, 40)
ActionFrame.Position               = UDim2.new(0, 8, 0, 240)
ActionFrame.BackgroundTransparency = 1

local TruckBtn = makeBtn(ActionFrame, "🚚  Truck Him", C.Accent, C.AccentHov)
TruckBtn.Size     = UDim2.new(0.5, -4, 1, 0)
TruckBtn.Position = UDim2.new(0, 0, 0, 0)

local SpecBtn = makeBtn(ActionFrame, "👁  Spectator", C.Item, C.Border)
SpecBtn.Size     = UDim2.new(0.5, -4, 1, 0)
SpecBtn.Position = UDim2.new(0.5, 4, 0, 0)

local StatusLabel = makeLabel(Body, "  Status: Idle", 11, C.TextDim, Enum.Font.Gotham)
StatusLabel.Size             = UDim2.new(1, -16, 0, 18)
StatusLabel.Position         = UDim2.new(0, 8, 0, 288)
StatusLabel.TextXAlignment   = Enum.TextXAlignment.Left

local AutoBadge = Instance.new("TextLabel", Body)
AutoBadge.Size                   = UDim2.new(1, -16, 0, 18)
AutoBadge.Position               = UDim2.new(0, 8, 1, -24)
AutoBadge.BackgroundTransparency = 1
AutoBadge.Text                   = "  Auto-refresh aktif  •  BmSkyMods"
AutoBadge.TextColor3             = C.TextDim
AutoBadge.TextSize               = 10
AutoBadge.Font                   = Enum.Font.Gotham
AutoBadge.TextXAlignment         = Enum.TextXAlignment.Left

-- ═══════════════════════════════════════════════════════════
--  Definisi setStatus (setelah StatusLabel ada)
-- ═══════════════════════════════════════════════════════════
setStatus = function(txt, color)
    StatusLabel.Text       = "  Status: " .. txt
    StatusLabel.TextColor3 = color or C.TextDim
end

-- ═══════════════════════════════════════════════════════════
--  Player List Logic
-- ═══════════════════════════════════════════════════════════
local function selectPlayer(plr)
    selectedPlayer = plr
    if plr then
        SelLabel.Text      = "  Selected: " .. plr.Name
        SelLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
    else
        SelLabel.Text      = "  Selected: —"
        SelLabel.TextColor3 = C.TextDim
    end
end

local function buildPlayerList()
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local row = Instance.new("TextButton", ScrollFrame)
            row.Size             = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = (selectedPlayer == plr) and C.RowSel or C.Row
            row.TextColor3       = C.Text
            row.Text             = "  " .. plr.Name
            row.TextSize         = 13
            row.Font             = Enum.Font.GothamMedium
            row.TextXAlignment   = Enum.TextXAlignment.Left
            row.AutoButtonColor  = false
            row.BorderSizePixel  = 0
            applyCorner(row, 4)
            row.MouseEnter:Connect(function()
                if selectedPlayer ~= plr then row.BackgroundColor3 = Color3.fromRGB(55,45,90) end
            end)
            row.MouseLeave:Connect(function()
                if selectedPlayer ~= plr then row.BackgroundColor3 = C.Row end
            end)
            row.MouseButton1Click:Connect(function()
                for _, r in ipairs(ScrollFrame:GetChildren()) do
                    if r:IsA("TextButton") then r.BackgroundColor3 = C.Row end
                end
                row.BackgroundColor3 = C.RowSel
                selectPlayer(plr)
            end)
        end
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        buildPlayerList()
        task.wait(3)
    end
end)

RefreshBtn.MouseButton1Click:Connect(function()
    buildPlayerList()
    setStatus("List di-refresh!", Color3.fromRGB(100, 220, 130))
    task.delay(2, function() setStatus("Idle") end)
end)

Players.PlayerAdded:Connect(buildPlayerList)
Players.PlayerRemoving:Connect(function(p)
    if p == selectedPlayer then selectPlayer(nil) end
    task.defer(buildPlayerList)
end)

-- ═══════════════════════════════════════════════════════════
--  Truck Him Button Logic
-- ═══════════════════════════════════════════════════════════
local isTrucking = false

local function setTruckBtnStop()
    TruckBtn.Text             = "■  Stop"
    TruckBtn.BackgroundColor3 = C.AccentRed
    TruckBtn.MouseEnter:Connect(function() TruckBtn.BackgroundColor3 = C.AccentRedH end)
    TruckBtn.MouseLeave:Connect(function() TruckBtn.BackgroundColor3 = C.AccentRed  end)
end
local function setTruckBtnNormal()
    TruckBtn.Text             = "🚚  Truck Him"
    TruckBtn.BackgroundColor3 = C.Accent
    TruckBtn.MouseEnter:Connect(function() TruckBtn.BackgroundColor3 = C.AccentHov end)
    TruckBtn.MouseLeave:Connect(function() TruckBtn.BackgroundColor3 = C.Accent    end)
end

TruckBtn.MouseButton1Click:Connect(function()
    if isTrucking then
        isTrucking = false
        stopFling()
        setTruckBtnNormal()
        setStatus("Stopped.", C.TextDim)
    else
        if not selectedPlayer then
            setStatus("Pilih player dulu!", Color3.fromRGB(220, 100, 100))
            task.delay(2, function() setStatus("Idle") end)
            return
        end
        if not selectedPlayer.Character then
            setStatus("Player tidak ada di game!", Color3.fromRGB(220, 100, 100))
            task.delay(2, function() setStatus("Idle") end)
            return
        end
        isTrucking = true
        setTruckBtnStop()
        setStatus("Trucking: " .. selectedPlayer.Name .. "...", Color3.fromRGB(255, 180, 50))
        task.spawn(function()
            flingWithTruck(selectedPlayer, function()
                isTrucking = false
                setTruckBtnNormal()
                setStatus("Selesai.", C.TextDim)
            end)
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  Spectator Button Logic
-- ═══════════════════════════════════════════════════════════
local isSpec = false

SpecBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then
        setStatus("Pilih player dulu!", Color3.fromRGB(220, 100, 100))
        task.delay(2, function() setStatus("Idle") end)
        return
    end
    if isSpec then
        isSpec = false
        stopSpectate()
        SpecBtn.Text             = "👁  Spectator"
        SpecBtn.BackgroundColor3 = C.Item
        setStatus("Spectate dihentikan.", C.TextDim)
    else
        isSpec = true
        startSpectate(selectedPlayer)
        SpecBtn.Text             = "✖  Stop Spec"
        SpecBtn.BackgroundColor3 = C.AccentGrn
        setStatus("Spectating: " .. selectedPlayer.Name, Color3.fromRGB(100, 220, 130))
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p == selectedPlayer and isSpec then
        isSpec = false
        SpecBtn.Text             = "👁  Spectator"
        SpecBtn.BackgroundColor3 = C.Item
        setStatus("Target meninggalkan game.", Color3.fromRGB(220, 100, 100))
    end
end)

-- ═══════════════════════════════════════════════════════════
--  Minimize Toggle
-- ═══════════════════════════════════════════════════════════
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Body.Visible = not isMinimized
    if isMinimized then
        Window:TweenSize(UDim2.new(0, 300, 0, 32), "Out", "Quad", 0.18, true)
        MinBtn.Text = "▢"
    else
        Window:TweenSize(UDim2.new(0, 300, 0, 380), "Out", "Quad", 0.18, true)
        MinBtn.Text = "—"
        task.delay(0.05, function() Body.Visible = true end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  Drag Logic
-- ═══════════════════════════════════════════════════════════
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ─── Done ────────────────────────────────────────────────────
buildPlayerList()
setStatus("Idle")
print("[BmSkyMods] Truck Him Tool loaded!")
