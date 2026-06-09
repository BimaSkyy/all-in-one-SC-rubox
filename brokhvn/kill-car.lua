
-- CarKill GUI by BmSky
-- Fitur: List Player (real-time), Kill Car, Spektator

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local SelectedPlayer = nil
local _savedCFrame = nil
local viewing = false
local viewConn = nil

-- ==============================================
-- SCREENGUI
-- ==============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CarKillGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- ==============================================
-- PANEL UTAMA (imgui style)
-- ==============================================
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0, 230, 0, 42) -- mulai collapsed
Panel.Position = UDim2.new(0.5, -115, 0.1, 0)
Panel.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
Panel.BorderSizePixel = 0
Panel.ZIndex = 2
Panel.Parent = ScreenGui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 7)

local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = Color3.fromRGB(70, 70, 85)
PanelStroke.Thickness = 1

-- Title Bar
local TitleBar = Instance.new("TextButton")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
TitleBar.BorderSizePixel = 0
TitleBar.Text = ""
TitleBar.AutoButtonColor = false
TitleBar.ZIndex = 3
TitleBar.Parent = Panel

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 7)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🚖  Car Kill GUI"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 15
TitleText.TextColor3 = Color3.fromRGB(220, 220, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 4
TitleText.Parent = TitleBar

-- Tombol minimize [–] / [+]
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -34, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "+"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 5
MinBtn.Parent = TitleBar

Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

-- Content Frame
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -42)
Content.Position = UDim2.new(0, 0, 0, 42)
Content.BackgroundTransparency = 1
Content.Visible = false
Content.ZIndex = 3
Content.Parent = Panel

-- ==============================================
-- HELPER: Buat tombol standar
-- ==============================================
local function makeButton(parent, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(55, 100, 200)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    return btn
end

-- ==============================================
-- TOMBOL LIST PLAYER
-- ==============================================
local listOpen = false

local ListBtn = makeButton(Content, "📋  List Player", 8, Color3.fromRGB(50, 110, 210))

-- Panel player list
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(1, -20, 0, 140)
PlayerListFrame.Position = UDim2.new(0, 10, 0, 50)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.Visible = false
PlayerListFrame.ZIndex = 4
PlayerListFrame.Parent = Content

Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 5)
local PlStroke = Instance.new("UIStroke", PlayerListFrame)
PlStroke.Color = Color3.fromRGB(55, 55, 70)
PlStroke.Thickness = 1

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -8, 1, -8)
Scroll.Position = UDim2.new(0, 4, 0, 4)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex = 5
Scroll.Parent = PlayerListFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = Scroll

-- ==============================================
-- SELECTED LABEL
-- ==============================================
local SelLabel = Instance.new("TextLabel")
SelLabel.Size = UDim2.new(1, -20, 0, 22)
SelLabel.Position = UDim2.new(0, 10, 0, 198)
SelLabel.BackgroundTransparency = 1
SelLabel.Text = "Target: —"
SelLabel.Font = Enum.Font.Gotham
SelLabel.TextSize = 12
SelLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
SelLabel.TextXAlignment = Enum.TextXAlignment.Left
SelLabel.ZIndex = 4
SelLabel.Parent = Content

-- ==============================================
-- TOMBOL KILL
-- ==============================================
local KillBtn = makeButton(Content, "🚌  Car Him", 226, Color3.fromRGB(90, 60, 150))

-- ==============================================
-- SEPARATOR
-- ==============================================
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -20, 0, 1)
Sep.Position = UDim2.new(0, 10, 0, 268)
Sep.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Sep.BorderSizePixel = 0
Sep.ZIndex = 4
Sep.Parent = Content

-- ==============================================
-- TOMBOL SPEKTATOR (toggle)
-- ==============================================
local SpekBtn = makeButton(Content, "👁  Spektator", 277, Color3.fromRGB(70, 70, 90))
local spekActive = false

-- Total tinggi content = 277 + 34 + 10 = 321
local CONTENT_HEIGHT = 321

-- ==============================================
-- MINIMIZE LOGIC
-- ==============================================
local expanded = false

local function setExpanded(val)
    expanded = val
    if expanded then
        Panel.Size = UDim2.new(0, 230, 0, 42 + CONTENT_HEIGHT)
        Content.Visible = true
        MinBtn.Text = "–"
    else
        Panel.Size = UDim2.new(0, 230, 0, 42)
        Content.Visible = false
        MinBtn.Text = "+"
    end
end

MinBtn.MouseButton1Click:Connect(function()
    setExpanded(not expanded)
end)

TitleBar.MouseButton1Click:Connect(function()
    setExpanded(not expanded)
end)

-- ==============================================
-- DRAG PANEL (dari title bar)
-- ==============================================
local dragActive = false
local dragStart = nil
local panelStart = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = true
        dragStart = input.Position
        panelStart = Panel.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(
            panelStart.X.Scale,
            panelStart.X.Offset + delta.X,
            panelStart.Y.Scale,
            panelStart.Y.Offset + delta.Y
        )
    end
end)

-- ==============================================
-- REFRESH PLAYER LIST
-- ==============================================
local function RefreshList()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
            btn.BorderSizePixel = 0
            btn.Text = p.Name
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextColor3 = Color3.fromRGB(200, 200, 215)
            btn.AutoButtonColor = false
            btn.ZIndex = 6
            btn.Parent = Scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            btn.MouseButton1Click:Connect(function()
                SelectedPlayer = p.Name
                SelLabel.Text = "Target: " .. p.Name
                -- highlight
                for _, b in ipairs(Scroll:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
                        b.TextColor3 = Color3.fromRGB(200, 200, 215)
                    end
                end
                btn.BackgroundColor3 = Color3.fromRGB(50, 140, 80)
                btn.TextColor3 = Color3.new(1, 1, 1)
            end)
        end
    end

    task.wait(0.05)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
end

-- Auto refresh real-time
Players.PlayerAdded:Connect(function()
    if listOpen then RefreshList() end
end)
Players.PlayerRemoving:Connect(function()
    if listOpen then
        task.wait(0.1)
        RefreshList()
        -- reset kalau player yang dipilih keluar
    end
    task.wait(0.1)
    if SelectedPlayer and not Players:FindFirstChild(SelectedPlayer) then
        SelectedPlayer = nil
        SelLabel.Text = "Target: —"
    end
end)

ListBtn.MouseButton1Click:Connect(function()
    listOpen = not listOpen
    PlayerListFrame.Visible = listOpen
    if listOpen then
        RefreshList()
        ListBtn.Text = "📋  Hide List"
        ListBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
        -- geser tombol bawah ke bawah list
        SelLabel.Visible = true
        KillBtn.Visible = true
        Sep.Visible = true
        SpekBtn.Visible = true
    else
        ListBtn.Text = "📋  List Player"
        ListBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 210)
    end
end)

-- ==============================================
-- CAR HIM FUNCTION (Bus + penumpang + follow + spin + trigger sit)
-- ==============================================
local carHimAktif = false

local function hapusSemuaKendaraan()
    local RE2 = ReplicatedStorage:FindFirstChild("RE")
    if RE2 then
        pcall(function() RE2:FindFirstChild("1Ca1r"):FireServer("DeleteAllVehicles") end)
    end
end

local function resetKillBtn()
    carHimAktif = false
    KillBtn.Text = "🚌  Car Him"
    KillBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 150)
end

KillBtn.MouseButton1Click:Connect(function()
    -- Kalau sedang aktif → STOP
    if carHimAktif then
        carHimAktif = false
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then hum.Sit = false end
        if hrp and _savedCFrame then
            task.wait(0.1)
            hrp.CFrame = _savedCFrame
        end
        hapusSemuaKendaraan()
        resetKillBtn()
        return
    end

    if not SelectedPlayer then
        warn("Pilih pemain dulu!")
        return
    end

    local RE = ReplicatedStorage:FindFirstChild("RE")
    if not RE then warn("RE tidak ditemukan!") return end

    carHimAktif = true
    KillBtn.Text = "⏹  Stop"
    KillBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

    task.spawn(function()
        local char = LocalPlayer.Character
        if not char then resetKillBtn() return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local Vehicles = workspace:FindFirstChild("Vehicles")

        if not (hum and hrp and Vehicles) then
            warn("Karakter atau Vehicles tidak ada!")
            resetKillBtn()
            return
        end

        -- Simpan posisi awal
        _savedCFrame = hrp.CFrame

        -- ── STEP 1: Teleport ke spawn bus ──
        hrp.CFrame = CFrame.new(1158, 2, 744)
        task.wait(0.6)
        if not carHimAktif then hapusSemuaKendaraan() resetKillBtn() return end

        -- ── STEP 2: Spawn Bus ──
        if not Vehicles:FindFirstChild(LocalPlayer.Name .. "Car") then
            pcall(function() RE:FindFirstChild("1Ca1r"):FireServer("PickingCar", "SchoolBus") end)
            task.wait(1)
        end
        if not carHimAktif then hapusSemuaKendaraan() resetKillBtn() return end

        local bus = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
        if not bus then
            warn("Bus tidak muncul!")
            resetKillBtn()
            return
        end

        -- ── STEP 3: Naik sebagai PENUMPANG (cari Seat bukan VehicleSeat) ──
        -- Cari semua Seat di dalam bus, hindari VehicleSeat (itu kursi pengemudi)
        local passengerSeat = nil
        local function cariPassengerSeat(parent)
            for _, v in ipairs(parent:GetDescendants()) do
                if v:IsA("Seat") and not v:IsA("VehicleSeat") then
                    passengerSeat = v
                    return
                end
            end
        end
        cariPassengerSeat(bus)

        -- Fallback: kalau tidak ada Seat biasa, tetap pakai VehicleSeat tapi paksa duduk terus
        -- sampai karakter duduk (server akan assign sebagai penumpang jika seat terisi)
        if not passengerSeat then
            -- coba seat apapun selain index pertama (biasanya pengemudi)
            local allSeats = {}
            for _, v in ipairs(bus:GetDescendants()) do
                if v:IsA("VehicleSeat") or v:IsA("Seat") then
                    table.insert(allSeats, v)
                end
            end
            if #allSeats >= 2 then
                passengerSeat = allSeats[2]
            elseif #allSeats == 1 then
                passengerSeat = allSeats[1]
            end
        end

        if passengerSeat then
            local timeout = 0
            repeat
                task.wait(0.1)
                timeout = timeout + 0.1
                hrp.CFrame = passengerSeat.CFrame * CFrame.new(0, 1, 0)
            until hum.Sit or timeout > 5 or not carHimAktif
        end

        if not carHimAktif then hapusSemuaKendaraan() resetKillBtn() return end

        task.wait(0.3)

        -- ── STEP 4: Teleport bus ke target + spin terus-menerus ──
        local targetPlr = Players:FindFirstChild(SelectedPlayer)
        if not targetPlr then
            warn("Target tidak ditemukan!")
            hapusSemuaKendaraan()
            resetKillBtn()
            return
        end

        local spinConn = nil
        local currentRot = 0

        spinConn = RunService.Heartbeat:Connect(function(dt)
            if not carHimAktif or not bus or not bus.PrimaryPart then
                spinConn:Disconnect()
                return
            end

            local tChar = targetPlr.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if not tHrp then return end

            -- ── Cek target SIT → trigger jatuh + hapus ──
            if tHum and tHum.Sit then
                spinConn:Disconnect()
                -- Jatuhkan bus ke bawah
                bus:SetPrimaryPartCFrame(CFrame.new(tHrp.Position.X, -470, tHrp.Position.Z))
                task.wait(0.3)
                -- Keluarkan dari kursi
                if hum.SeatPart then hum.Sit = false end
                task.wait(0.1)
                hapusSemuaKendaraan()
                -- Kembalikan ke posisi awal
                task.wait(0.1)
                if _savedCFrame then hrp.CFrame = _savedCFrame end
                resetKillBtn()
                return
            end

            -- Spin bus di atas target
            currentRot = currentRot + math.rad(720) * dt
            local offset = Vector3.new(0, 2, 0)
            bus:SetPrimaryPartCFrame(
                CFrame.new(tHrp.Position + offset) *
                CFrame.Angles(
                    math.rad(math.random(-30, 30)),
                    currentRot,
                    math.rad(math.random(-30, 30))
                )
            )
        end)
    end)
end)

-- ==============================================
-- SPEKTATOR TOGGLE
-- ==============================================
SpekBtn.MouseButton1Click:Connect(function()
    spekActive = not spekActive
    viewing = spekActive

    if spekActive then
        -- Mulai spektator
        if not SelectedPlayer then
            warn("Pilih pemain dulu!")
            spekActive = false
            viewing = false
            return
        end

        SpekBtn.Text = "⏹  Stop Spektator"
        SpekBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 30)

        task.spawn(function()
            while viewing do
                local target = Players:FindFirstChild(SelectedPlayer)
                if not (target and target.Character and target.Character:FindFirstChild("Humanoid")) then
                    break
                end
                CurrentCamera.CameraSubject = target.Character.Humanoid
                task.wait()
            end

            -- Kembalikan kamera ke diri sendiri
            local selfChar = LocalPlayer.Character
            if selfChar and selfChar:FindFirstChild("Humanoid") then
                CurrentCamera.CameraSubject = selfChar.Humanoid
            end

            -- Reset tombol kalau loop berhenti sendiri (target kabur)
            if not viewing then return end
            spekActive = false
            viewing = false
            SpekBtn.Text = "👁  Spektator"
            SpekBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
        end)
    else
        -- Stop spektator
        viewing = false
        SpekBtn.Text = "👁  Spektator"
        SpekBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)

        local selfChar = LocalPlayer.Character
        if selfChar and selfChar:FindFirstChild("Humanoid") then
            CurrentCamera.CameraSubject = selfChar.Humanoid
        end
    end
end)
