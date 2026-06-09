if not game:IsLoaded() then game.Loaded:Wait() end

-- Layanan
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

-- Remote sesuai debug kamu
local RE          = ReplicatedStorage:WaitForChild("RE")
local RemoteTeks  = RE:WaitForChild("1RPNam1eTex1t")
local RemoteWarna = RE:WaitForChild("1RPNam1eColo1r")
local RemotesAura = ReplicatedStorage:WaitForChild("Remotes")

-- Status
local aktif        = false
local loopBerjalan = false
local tersembunyi  = false
local indexAura    = 1

-- Daftar Aura Otomatis
local daftarAura = {
    {Id = "18637074370", Nama = "030FireWhite"},
    {Id = "18637025451", Nama = "031FireOrange"},
    {Id = "18637078598", Nama = "032FireGreen"},
    {Id = "18637076370", Nama = "033FireBlue"},
    {Id = "18637070174", Nama = "034FirePurple"},
    {Id = "18637072603", Nama = "035FireBlack"}
}

-- ==============================================
-- BUAT GUI PANEL (DIPERBESAR AGAR MUAT TOMBOL)
-- ==============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "HandlerPanel"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

-- Panel Utama
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 280, 0, 320)
Panel.Position = UDim2.new(0.1, 0, 0.2, 0)
Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
local PanelCorner = Instance.new("UICorner", Panel)
PanelCorner.CornerRadius = UDim.new(0, 10)
local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = Color3.fromRGB(100, 100, 120)
PanelStroke.Thickness = 1
Panel.Parent = Gui

-- Header (untuk drag & judul)
local Header = Instance.new("TextButton")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
Header.Text = "🎭 Mode Handler"
Header.TextColor3 = Color3.fromRGB(220, 220, 220)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 14
Header.AutoButtonColor = false
Header.Parent = Panel
local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 10)

-- Tombol Sembunyikan/Tampilkan
local TombolHide = Instance.new("TextButton")
TombolHide.Size = UDim2.new(0, 30, 0, 22)
TombolHide.Position = UDim2.new(1, -35, 0, 4)
TombolHide.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
TombolHide.Text = "−"
TombolHide.TextColor3 = Color3.new(1,1,1)
TombolHide.Font = Enum.Font.GothamBold
TombolHide.TextSize = 16
TombolHide.Parent = Header
local HideCorner = Instance.new("UICorner", TombolHide)
HideCorner.CornerRadius = UDim.new(0, 6)

-- Tombol ON/OFF Utama
local TombolHandler = Instance.new("TextButton")
TombolHandler.Size = UDim2.new(0, 240, 0, 35)
TombolHandler.Position = UDim2.new(0.5, -120, 0, 40)
TombolHandler.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
TombolHandler.Text = "AKTIFKAN HANDLER"
TombolHandler.TextColor3 = Color3.new(1,1,1)
TombolHandler.Font = Enum.Font.GothamBold
TombolHandler.TextSize = 14
TombolHandler.AutoButtonColor = false
TombolHandler.Parent = Panel
local TombolCorner = Instance.new("UICorner", TombolHandler)
TombolCorner.CornerRadius = UDim.new(0, 8)

-- Teks Status
local TeksStatus = Instance.new("TextLabel")
TeksStatus.Size = UDim2.new(1, -20, 0, 20)
TeksStatus.Position = UDim2.new(0, 10, 0, 80)
TeksStatus.BackgroundTransparency = 1
TeksStatus.Text = "Status: Mati"
TeksStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
TeksStatus.Font = Enum.Font.Gotham
TeksStatus.TextSize = 12
TeksStatus.Parent = Panel

-- Garis Pemisah
local Garis1 = Instance.new("Frame")
Garis1.Size = UDim2.new(1, -20, 0, 1)
Garis1.Position = UDim2.new(0, 10, 0, 105)
Garis1.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Garis1.BorderSizePixel = 0
Garis1.Parent = Panel

-- Label Aura Khusus
local LabelAura = Instance.new("TextLabel")
LabelAura.Size = UDim2.new(1, -20, 0, 20)
LabelAura.Position = UDim2.new(0, 10, 0, 115)
LabelAura.BackgroundTransparency = 1
LabelAura.Text = "✨ Aura Khusus"
LabelAura.TextColor3 = Color3.fromRGB(200, 200, 220)
LabelAura.Font = Enum.Font.GothamBold
LabelAura.TextSize = 12
LabelAura.TextXAlignment = Enum.TextXAlignment.Center
LabelAura.Parent = Panel

-- Tombol Aura Hati
local TombolAuraHati = Instance.new("TextButton")
TombolAuraHati.Size = UDim2.new(0, 115, 0, 30)
TombolAuraHati.Position = UDim2.new(0, 12, 0, 140)
TombolAuraHati.BackgroundColor3 = Color3.fromRGB(120, 50, 80)
TombolAuraHati.Text = "❤️ Hati"
TombolAuraHati.TextColor3 = Color3.new(1,1,1)
TombolAuraHati.Font = Enum.Font.GothamBold
TombolAuraHati.TextSize = 12
TombolAuraHati.AutoButtonColor = false
TombolAuraHati.Parent = Panel
local CornerHati = Instance.new("UICorner", TombolAuraHati)
CornerHati.CornerRadius = UDim.new(0, 6)

-- Tombol Aura Bintang
local TombolAuraBintang = Instance.new("TextButton")
TombolAuraBintang.Size = UDim2.new(0, 115, 0, 30)
TombolAuraBintang.Position = UDim2.new(0, 143, 0, 140)
TombolAuraBintang.BackgroundColor3 = Color3.fromRGB(140, 100, 40)
TombolAuraBintang.Text = "⭐ Bintang"
TombolAuraBintang.TextColor3 = Color3.new(1,1,1)
TombolAuraBintang.Font = Enum.Font.GothamBold
TombolAuraBintang.TextSize = 12
TombolAuraBintang.AutoButtonColor = false
TombolAuraBintang.Parent = Panel
local CornerBintang = Instance.new("UICorner", TombolAuraBintang)
CornerBintang.CornerRadius = UDim.new(0, 6)

-- Garis Pemisah
local Garis2 = Instance.new("Frame")
Garis2.Size = UDim2.new(1, -20, 0, 1)
Garis2.Position = UDim2.new(0, 10, 0, 178)
Garis2.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
Garis2.BorderSizePixel = 0
Garis2.Parent = Panel

-- Label Senjata
local LabelSenjata = Instance.new("TextLabel")
LabelSenjata.Size = UDim2.new(1, -20, 0, 20)
LabelSenjata.Position = UDim2.new(0, 10, 0, 188)
LabelSenjata.BackgroundTransparency = 1
LabelSenjata.Text = "🔫 Senjata & Alat"
LabelSenjata.TextColor3 = Color3.fromRGB(200, 200, 220)
LabelSenjata.Font = Enum.Font.GothamBold
LabelSenjata.TextSize = 12
LabelSenjata.TextXAlignment = Enum.TextXAlignment.Center
LabelSenjata.Parent = Panel

-- Baris 1 Senjata
local TombolAir = Instance.new("TextButton")
TombolAir.Size = UDim2.new(0, 80, 0, 28)
TombolAir.Position = UDim2.new(0, 12, 0, 213)
TombolAir.BackgroundColor3 = Color3.fromRGB(40, 80, 120)
TombolAir.Text = "💧 Air"
TombolAir.TextColor3 = Color3.new(1,1,1)
TombolAir.Font = Enum.Font.GothamBold
TombolAir.TextSize = 11
TombolAir.AutoButtonColor = false
TombolAir.Parent = Panel
Instance.new("UICorner", TombolAir).CornerRadius = UDim.new(0, 5)

local TombolUang = Instance.new("TextButton")
TombolUang.Size = UDim2.new(0, 80, 0, 28)
TombolUang.Position = UDim2.new(0, 100, 0, 213)
TombolUang.BackgroundColor3 = Color3.fromRGB(120, 100, 20)
TombolUang.Text = "💰 Uang"
TombolUang.TextColor3 = Color3.new(1,1,1)
TombolUang.Font = Enum.Font.GothamBold
TombolUang.TextSize = 11
TombolUang.AutoButtonColor = false
TombolUang.Parent = Panel
Instance.new("UICorner", TombolUang).CornerRadius = UDim.new(0, 5)

local TombolSky = Instance.new("TextButton")
TombolSky.Size = UDim2.new(0, 80, 0, 28)
TombolSky.Position = UDim2.new(0, 188, 0, 213)
TombolSky.BackgroundColor3 = Color3.fromRGB(80, 120, 140)
TombolSky.Text = "⛷️ Sky"
TombolSky.TextColor3 = Color3.new(1,1,1)
TombolSky.Font = Enum.Font.GothamBold
TombolSky.TextSize = 11
TombolSky.AutoButtonColor = false
TombolSky.Parent = Panel
Instance.new("UICorner", TombolSky).CornerRadius = UDim.new(0, 5)

-- Baris 2 Senjata
local TombolPapan = Instance.new("TextButton")
TombolPapan.Size = UDim2.new(0, 115, 0, 28)
TombolPapan.Position = UDim2.new(0, 12, 0, 247)
TombolPapan.BackgroundColor3 = Color3.fromRGB(100, 120, 160)
TombolPapan.Text = "🏂 Papan Salju"
TombolPapan.TextColor3 = Color3.new(1,1,1)
TombolPapan.Font = Enum.Font.GothamBold
TombolPapan.TextSize = 11
TombolPapan.AutoButtonColor = false
TombolPapan.Parent = Panel
Instance.new("UICorner", TombolPapan).CornerRadius = UDim.new(0, 5)

local TombolPistolEs = Instance.new("TextButton")
TombolPistolEs.Size = UDim2.new(0, 153, 0, 28)
TombolPistolEs.Position = UDim2.new(0, 135, 0, 247)
TombolPistolEs.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
TombolPistolEs.Text = "❄️ Pistol Es"
TombolPistolEs.TextColor3 = Color3.new(1,1,1)
TombolPistolEs.Font = Enum.Font.GothamBold
TombolPistolEs.TextSize = 11
TombolPistolEs.AutoButtonColor = false
TombolPistolEs.Parent = Panel
Instance.new("UICorner", TombolPistolEs).CornerRadius = UDim.new(0, 5)

-- ==============================================
-- FUNGSI DRAG PANEL
-- ==============================================
local dragging, dragStart, startPos = false, nil, nil

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
-- FUNGSI SEMBUNYIKAN/TAMPILKAN
-- ==============================================
TombolHide.MouseButton1Click:Connect(function()
    tersembunyi = not tersembunyi
    if tersembunyi then
        TweenService:Create(Panel, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 280, 0, 30)
        }):Play()
        TombolHide.Text = "+"
    else
        TweenService:Create(Panel, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 280, 0, 320)
        }):Play()
        TombolHide.Text = "−"
    end
end)

-- ==============================================
-- FUNGSI TOMBOL AURA KHUSUS
-- ==============================================
TombolAuraHati.MouseButton1Click:Connect(function()
    RemotesAura.ApplyEmmiter:InvokeServer("18635726250","005HeartsPink")
end)

TombolAuraBintang.MouseButton1Click:Connect(function()
    RemotesAura.ApplyEmmiter:InvokeServer("18637946172","091StarOrange")
end)

-- ==============================================
-- FUNGSI TOMBOL SPASW SENJATA
-- ==============================================
TombolAir.MouseButton1Click:Connect(function()
    RE["1Playe1rTrigge1rEven1t"]:FireServer("AcceptedToolToServer","FireHose",Players.LocalPlayer)
end)

TombolUang.MouseButton1Click:Connect(function()
    RE["1Playe1rTrigge1rEven1t"]:FireServer("AcceptedToolToServer","MoneyGun",Players.LocalPlayer)
end)

TombolSky.MouseButton1Click:Connect(function()
    RE["1Playe1rTrigge1rEven1t"]:FireServer("AcceptedToolToServer","Skis",Players.LocalPlayer)
end)

TombolPapan.MouseButton1Click:Connect(function()
    RE["1Playe1rTrigge1rEven1t"]:FireServer("AcceptedToolToServer","Snowboard",Players.LocalPlayer)
end)

TombolPistolEs.MouseButton1Click:Connect(function()
    RE["1Playe1rTrigge1rEven1t"]:FireServer("AcceptedToolToServer","SnowballCannon",Players.LocalPlayer)
end)

-- ==============================================
-- FUNGSI AKTIF/MATIKAN HANDLER + AURA OTOMATIS
-- ==============================================
local function AktifkanHandler()
    if aktif then return end
    aktif = true
    loopBerjalan = true

    TombolHandler.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    TombolHandler.Text = "MATIKAN HANDLER"
    TeksStatus.Text = "Status: Aktif"
    TeksStatus.TextColor3 = Color3.fromRGB(120, 220, 140)

    -- Waktu ganti
    local waktuGantiNama = 60    -- Nama ganti tiap 1 menit
    local waktuGantiBio  = 60    -- Bio ganti tiap 1 menit
    local waktuGantiWarna = 0.15 -- Warna nama/bio berkedip
    local waktuGantiAura = 1     -- Aura ganti tiap 1 detik
    local waktuTerakhirNama = 0
    local waktuTerakhirBio  = 0
    local waktuTerakhirAura = 0

    task.spawn(function()
        -- Set awal
        RemoteTeks:FireServer("RolePlayName", "BmSkyMods " .. math.random(6,7))
        RemoteTeks:FireServer("RolePlayBio", "BH Server Staff " .. math.random(1,10))

        while loopBerjalan do
            local waktuSekarang = os.clock()

            -- Ganti Nama setiap 1 menit
            if waktuSekarang - waktuTerakhirNama >= waktuGantiNama then
                local nomorNama = math.random(6,7)
                RemoteTeks:FireServer("RolePlayName", "HANDLER " .. nomorNama)
                waktuTerakhirNama = waktuSekarang
            end

            -- Ganti Bio setiap 1 menit
            if waktuSekarang - waktuTerakhirBio >= waktuGantiBio then
                local nomorBio = math.random(1,10)
                RemoteTeks:FireServer("RolePlayBio", "BH Server Staff " .. nomorBio)
                waktuTerakhirBio = waktuSekarang
            end

            -- Ganti Aura setiap 1 detik
            if waktuSekarang - waktuTerakhirAura >= waktuGantiAura then
                local aura = daftarAura[indexAura]
                RemotesAura.ApplyEmmiter:InvokeServer(aura.Id, aura.Nama)
                indexAura = indexAura % #daftarAura + 1
                waktuTerakhirAura = waktuSekarang
            end

            -- Warna nama + bio berkedip hitam ↔ putih
            local warna = math.random(0,1) == 0 and Color3.new(0,0,0) or Color3.new(1,1,1)
            RemoteWarna:FireServer("PickingRPNameColor", warna)
            RemoteWarna:FireServer("PickingRPBioColor", warna)

            task.wait(waktuGantiWarna)
        end
    end)
end

local function MatikanHandler()
    if not aktif then return end
    aktif = false
    loopBerjalan = false

    task.wait(0.2)

    -- Tetap jadi Staff Off saat dimatikan
    RemoteTeks:FireServer("RolePlayName", "Staff Off")
    RemoteTeks:FireServer("RolePlayBio", "")
    RemoteWarna:FireServer("PickingRPNameColor", Color3.new(1,1,1))
    RemoteWarna:FireServer("PickingRPBioColor", Color3.new(1,1,1))

    TombolHandler.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    TombolHandler.Text = "AKTIFKAN HANDLER"
    TeksStatus.Text = "Status: Mati"
    TeksStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
end

-- Tombol ON/OFF
TombolHandler.MouseButton1Click:Connect(function()
    if aktif then
        MatikanHandler()
    else
        AktifkanHandler()
    end
end)

print("[OK] Semua fitur ditambahkan! Aura otomatis, tombol aura khusus & senjata siap")
