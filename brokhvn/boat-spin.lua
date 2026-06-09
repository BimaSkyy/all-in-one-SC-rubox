if not game:IsLoaded() then game.Loaded:Wait() end

-- Layanan
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

-- Remote
local RE = ReplicatedStorage:WaitForChild("RE")

-- Status
local tersembunyi = false
local dragging, dragStart, startPos = false, nil, nil

-- ==============================================
-- BUAT GUI
-- ==============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "TornadoTrollGui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = Players.LocalPlayer.PlayerGui

-- Panel Utama
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 240, 0, 150)
Panel.Position = UDim2.new(0.2, 0, 0.25, 0)
Panel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
local PanelCorner = Instance.new("UICorner", Panel)
PanelCorner.CornerRadius = UDim.new(0, 8)
local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = Color3.fromRGB(80, 80, 100)
PanelStroke.Thickness = 1
Panel.Parent = Gui

-- Header (Drag Area)
local Header = Instance.new("TextButton")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Header.Text = "🌪️ Tornado Troll"
Header.TextColor3 = Color3.fromRGB(230, 230, 255)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 14
Header.AutoButtonColor = false
Header.Parent = Panel
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 8)
local HeaderStroke = Instance.new("UIStroke", Header)
HeaderStroke.Color = Color3.fromRGB(80, 80, 100)
HeaderStroke.Thickness = 1

-- Tombol Minimize
local TombolMin = Instance.new("TextButton")
TombolMin.Size = UDim2.new(0, 28, 0, 24)
TombolMin.Position = UDim2.new(1, -32, 0, 4)
TombolMin.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
TombolMin.Text = "−"
TombolMin.TextColor3 = Color3.new(1,1,1)
TombolMin.Font = Enum.Font.GothamBold
TombolMin.TextSize = 16
TombolMin.AutoButtonColor = false
TombolMin.Parent = Header
local MinCorner = Instance.new("UICorner", TombolMin)
MinCorner.CornerRadius = UDim.new(0, 6)

-- Konten Panel
local Konten = Instance.new("Frame")
Konten.Name = "Konten"
Konten.Size = UDim2.new(1, 0, 1, -32)
Konten.Position = UDim2.new(0, 0, 0, 32)
Konten.BackgroundTransparency = 1
Konten.Parent = Panel

-- Tombol Tornado Kapal
local TombolTornado = Instance.new("TextButton")
TombolTornado.Size = UDim2.new(0.9, 0, 0, 45)
TombolTornado.Position = UDim2.new(0.05, 0, 0.05, 0)
TombolTornado.BackgroundColor3 = Color3.fromRGB(90, 60, 120)
TombolTornado.Text = "🌪️ Aktifkan Tornado Kapal"
TombolTornado.TextColor3 = Color3.new(1,1,1)
TombolTornado.Font = Enum.Font.GothamBold
TombolTornado.TextSize = 13
TombolTornado.AutoButtonColor = false
TombolTornado.Parent = Konten
local TornadoCorner = Instance.new("UICorner", TombolTornado)
TornadoCorner.CornerRadius = UDim.new(0, 6)

-- Tombol Cancel
local TombolCancel = Instance.new("TextButton")
TombolCancel.Size = UDim2.new(0.9, 0, 0, 45)
TombolCancel.Position = UDim2.new(0.05, 0, 0.55, 0)
TombolCancel.BackgroundColor3 = Color3.fromRGB(120, 40, 60)
TombolCancel.Text = "❌ Hentikan & Hapus Kapal"
TombolCancel.TextColor3 = Color3.new(1,1,1)
TombolCancel.Font = Enum.Font.GothamBold
TombolCancel.TextSize = 13
TombolCancel.AutoButtonColor = false
TombolCancel.Parent = Konten
local CancelCorner = Instance.new("UICorner", TombolCancel)
CancelCorner.CornerRadius = UDim.new(0, 6)

-- ==============================================
-- FUNGSI DRAG
-- ==============================================
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==============================================
-- FUNGSI MINIMIZE
-- ==============================================
TombolMin.MouseButton1Click:Connect(function()
    tersembunyi = not tersembunyi
    if tersembunyi then
        TweenService:Create(Panel, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 240, 0, 32)
        }):Play()
        TombolMin.Text = "+"
        Konten.Visible = false
    else
        TweenService:Create(Panel, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 240, 0, 150)
        }):Play()
        TombolMin.Text = "−"
        Konten.Visible = true
    end
end)

-- ==============================================
-- FUNGSI TORNADO KAPAL (TANPA PESAN CHAT)
-- ==============================================
local TornadoAktif = false
local HatiHati = nil

local function AktifkanTornado()
    if TornadoAktif then return end
    TornadoAktif = true

    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")
    local Vehicles = workspace:WaitForChild("Vehicles", 10)
    if not Vehicles then return end

    -- ✅ BAGIAN PESAN CHAT SUDAH DIHAPUS

    -- Suara
    local selectedAudioID = 9068077052
    task.spawn(function()
        for i = 1, 5 do
            if not TornadoAktif then break end
            local args = { workspace, selectedAudioID, 1 }
            pcall(function() RE:FindFirstChild("1Gu1nSound1s"):FireServer(unpack(args)) end)

            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://"..selectedAudioID
            sound.Parent = RootPart
            sound:Play()
            task.wait(1.5)
            sound:Destroy()
        end
    end)

    -- Spawn Kapal
    local function spawnBoat()
        RootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function() RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "PirateFree") end)
        task.wait(1)
        return Vehicles:FindFirstChild(Player.Name .. "Car")
    end

    local PCar = spawnBoat()
    if not PCar then TornadoAktif = false return end

    local Seat = PCar:FindFirstChild("Body") and PCar.Body:FindFirstChild("VehicleSeat")
    if not Seat then TornadoAktif = false return end

    -- Masuk ke kursi
    repeat
        task.wait(0.1)
        RootPart.CFrame = Seat.CFrame * CFrame.new(0, 1, 0)
    until not TornadoAktif or Humanoid.SeatPart == Seat

    -- Keluar otomatis setelah 4 detik
    HatiHati = task.delay(4, function()
        if Humanoid.SeatPart then Humanoid.Sit = false end
        RootPart.CFrame = CFrame.new(0, 0, 0)
    end)

    -- Putar kapal
    local RE_Flip = RE:WaitForChild("1Player1sCa1r", 5)
    task.spawn(function()
        while TornadoAktif and PCar and PCar.Parent do
            pcall(function() RE_Flip:FireServer("Flip") end)
            task.wait(0.5)
        end
    end)

    -- Gerakan & rotasi
    local waypoints = {
        Vector3.new(-16, 0, -47),
        Vector3.new(-110, 0, -45),
        Vector3.new(16, 0, -55)
    }
    local currentIndex = 1
    local nextIndex = 2
    local moveSpeed = 15
    local rotationSpeed = math.rad(720)
    local progress = 0
    local currentRotation = 0

    local con = RunService.Heartbeat:Connect(function(dt)
        if not TornadoAktif or not PCar or not PCar.PrimaryPart then con:Disconnect() return end

        local startPos = waypoints[currentIndex]
        local endPos = waypoints[nextIndex]
        progress += (moveSpeed * dt) / (startPos - endPos).Magnitude
        if progress >= 1 then
            progress = 0
            currentIndex = nextIndex
            nextIndex = (nextIndex % #waypoints) + 1
        end

        local newPos = CFrame.new(startPos):Lerp(CFrame.new(endPos), progress).Position
        currentRotation += rotationSpeed * dt
        PCar:SetPrimaryPartCFrame(CFrame.new(newPos) * CFrame.Angles(0, currentRotation, 0))
    end)
end

-- ==============================================
-- FUNGSI CANCEL
-- ==============================================
local function CancelTornado()
    TornadoAktif = false
    if HatiHati then task.cancel(HatiHati) end
    pcall(function() RE:FindFirstChild("1Ca1r"):FireServer("DeleteAllVehicles") end)
end

-- ==============================================
-- KONEKSI TOMBOL
-- ==============================================
TombolTornado.MouseButton1Click:Connect(AktifkanTornado)
TombolCancel.MouseButton1Click:Connect(CancelTornado)

print("[OK] Tanpa pesan chat!")
