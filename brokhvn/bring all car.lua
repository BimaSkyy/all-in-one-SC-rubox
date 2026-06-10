--[[
Auto Teleport Kendaraan
Lokasi kendaraan: Workspace.Vehicles
Kriteria: Semua kendaraan yang ada tempat duduknya
Lokasi tujuan: -33, 2, -23
Radius aman: 20 stud
Fitur: Real-time deteksi, tidak berhenti jika gagal, lewati yang sudah diproses
]]

-- Layanan
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

-- Tunggu pemain siap
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 15)
local RootPart = Character:WaitForChild("HumanoidRootPart", 15)

-- Variabel
local autoJalankan = false
local lokasiTujuan = Vector3.new(-33, 2, -23)
local radiusAman = 20
local daftarSelesai = {}

-- Notifikasi
local function Notifikasi(pesan)
    print("[AutoCar] " .. pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Teleport Car",
            Text = pesan,
            Duration = 1.5
        })
    end)
end

-- ✅ TOMBOL LANGSUNG DI LAYAR (PASTI MUNCUL)
local Tombol = Instance.new("Part")
Tombol.Name = "AutoCarButton"
Tombol.Size = Vector3.new(4, 1, 2)
Tombol.Position = Vector3.new(0, 100, 0) -- Posisi awal
Tombol.Anchored = true
Tombol.CanCollide = false
Tombol.CastShadow = false
Tombol.BrickColor = BrickColor.new("Dark gray")
Tombol.Parent = Workspace

-- Teks di tombol
local SurfaceGui = Instance.new("SurfaceGui")
SurfaceGui.Face = Enum.NormalId.Front
SurfaceGui.Parent = Tombol

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 1, 0)
Label.BackgroundTransparency = 1
Label.Text = "OFF"
Label.TextColor3 = Color3.new(1,1,1)
Label.Font = Enum.Font.GothamBold
Label.TextSize = 24
Label.Parent = SurfaceGui

-- Ikuti posisi kamera agar selalu terlihat
RunService.RenderStepped:Connect(function()
    local kamera = Workspace.CurrentCamera
    if kamera then
        Tombol.CFrame = kamera.CFrame * CFrame.new(3, -1.5, -5) -- Kanan atas layar
    end
end)

-- Fungsi klik tombol
local function KlikTombol()
    autoJalankan = not autoJalankan
    if autoJalankan then
        Tombol.BrickColor = BrickColor.new("Bright green")
        Label.Text = "ON"
        Notifikasi("✅ Aktif")
    else
        Tombol.BrickColor = BrickColor.new("Dark gray")
        Label.Text = "OFF"
        Notifikasi("❌ Berhenti")
    end
end

-- Deteksi klik
local ClickDetector = Instance.new("ClickDetector")
ClickDetector.MaxActivationDistance = 1000
ClickDetector.MouseClick:Connect(KlikTombol)
ClickDetector.Parent = Tombol

print("✅ Tombol siap! Terlihat di kanan atas layar.")

-- 🔍 CARI SEMUA KENDARAAN DENGAN KURSI
local function CariSemuaKendaraan()
    local VehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if not VehiclesFolder then
        Notifikasi("Folder Vehicles tidak ditemukan!")
        return {}
    end

    local daftarKendaraan = {}

    for _, kendaraan in ipairs(VehiclesFolder:GetChildren()) do
        if not kendaraan:IsA("Model") then continue end
        if table.find(daftarSelesai, kendaraan) then continue end

        local kursi = kendaraan:FindFirstChildWhichIsA("VehicleSeat", true) 
                   or kendaraan:FindFirstChildWhichIsA("Seat", true)
        if not kursi then continue end

        if not kendaraan.PrimaryPart then
            kendaraan.PrimaryPart = kendaraan:FindFirstChildWhichIsA("BasePart")
            if not kendaraan.PrimaryPart then continue end
        end

        local jarak = (kendaraan.PrimaryPart.Position - lokasiTujuan).Magnitude
        if jarak <= radiusAman then
            table.insert(daftarSelesai, kendaraan)
            continue
        end

        table.insert(daftarKendaraan, {Kendaraan = kendaraan, Kursi = kursi})
    end

    return daftarKendaraan
end

-- 🪑 COBA DUDUK, LEWATI JIKA GAGAL
local function CobaDuduk(kursi)
    if not kursi or not kursi:IsDescendantOf(Workspace) then return false end
    if kursi.Occupant then return false end

    for _ = 1, 5 do
        RootPart.CFrame = kursi.CFrame * CFrame.new(0, 1.4, 0.2)
        task.wait(0.15)
        if Humanoid.Sit then return true end
    end
    return false
end

-- ⚡ PROSES SATU KENDARAAN
local function ProsesSatuKendaraan(data)
    local kendaraan = data.Kendaraan
    local kursi = data.Kursi

    Notifikasi("Coba: " .. kendaraan.Name)

    RootPart.CFrame = kursi.CFrame * CFrame.new(0, 2.5, 0)
    task.wait(0.2)

    if not CobaDuduk(kursi) then
        Notifikasi("Gagal/ada orang, lewati")
        table.insert(daftarSelesai, kendaraan)
        return false
    end

    Notifikasi("Berhasil duduk")
    task.wait(0.3)

    kendaraan:SetPrimaryPartCFrame(CFrame.new(lokasiTujuan))
    RootPart.CFrame = CFrame.new(lokasiTujuan) * CFrame.new(0, 1, 0)
    Notifikasi("Dipindahkan")
    task.wait(0.4)

    Humanoid.Sit = false
    task.wait(0.2)
    for _ = 1, 4 do
        if not Humanoid.Sit then break end
        Humanoid.Sit = false
        task.wait(0.1)
    end

    table.insert(daftarSelesai, kendaraan)
    Notifikasi("Selesai")
    return true
end

-- 🔄 LOOP UTAMA TERUS BERJALAN
task.spawn(function()
    while true do
        if autoJalankan then
            if not Character or not Character:IsDescendantOf(Workspace) then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                Humanoid = Character:WaitForChild("Humanoid", 15)
                RootPart = Character:WaitForChild("HumanoidRootPart", 15)
            end

            local daftar = CariSemuaKendaraan()

            if #daftar == 0 then
                Notifikasi("Menunggu kendaraan baru...")
                task.wait(1)
                continue
            end

            for _, data in ipairs(daftar) do
                if not autoJalankan then break end
                ProsesSatuKendaraan(data)
                task.wait(0.3)
            end
        end
        task.wait(0.5)
    end
end)

print("✅ Script siap! Tombol hijau/abu-abu ada di kanan atas layar.")
