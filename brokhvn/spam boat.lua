--[[
Auto Spawn Boat + Teleport
Lokasi tombol: Workspace.WorkspaceCom.001_CanoeCloneButton.Button.ClickDetector
Lokasi spawn: -231, 0, 1014
Lokasi cek duduk: -230, -1, 990
Lokasi tujuan: -18, 2, -12 (acak dalam radius 20 stud)
Cek SEMUA kendaraan yang bisa dikendarai - Radius 50 stud
]]

-- Layanan
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Tunggu sampai pemain siap sepenuhnya
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then repeat task.wait() until LocalPlayer end

-- Tunggu karakter dan PlayerGui
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 10)
local RootPart = Character:WaitForChild("HumanoidRootPart", 10)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Variabel status
local autoSpam = false
local lokasiSpawn = Vector3.new(-231, 0, 1014)
local lokasiCekDuduk = Vector3.new(-230, -1, 990) -- ✅ Posisi cek duduk
local lokasiTujuanPusat = Vector3.new(-18, 2, -12)
local radiusSpawn = 50
local daftarKendaraanDiproses = {}

-- Fungsi notifikasi/log
local function Notifikasi(pesan)
    print("[AutoBoat] " .. pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Boat",
            Text = pesan,
            Duration = 2
        })
    end)
end

-- ✅ GUI DIPERBAIKI - PASTI MUNCUL
task.wait(1)

-- Hapus GUI lama jika ada
pcall(function()
    if PlayerGui:FindFirstChild("AutoBoatGUI") then
        PlayerGui.AutoBoatGUI:Destroy()
    end
end)

-- Buat GUI baru
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBoatGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Tombol utama
local Tombol = Instance.new("TextButton")
Tombol.Name = "ToggleBtn"
Tombol.Size = UDim2.new(0, 150, 0, 50)
Tombol.Position = UDim2.new(0.82, 0, 0.15, 0)
Tombol.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Tombol.BorderSizePixel = 3
Tombol.BorderColor3 = Color3.fromRGB(255, 0, 0)
Tombol.Text = "OFF"
Tombol.Font = Enum.Font.GothamBold
Tombol.TextSize = 18
Tombol.TextColor3 = Color3.new(1, 1, 1)
Tombol.AutoButtonColor = false
Tombol.Active = true
Tombol.Visible = true
Tombol.ZIndex = 100
Tombol.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Tombol

-- Fungsi klik tombol spawn
local function KlikTombolSpawn()
    local sukses = pcall(function()
        local WsCom = Workspace:FindFirstChild("WorkspaceCom")
        if not WsCom then return false end

        local CanoeBtn = WsCom:FindFirstChild("001_CanoeCloneButton")
        if not CanoeBtn then return false end

        local ButtonPart = CanoeBtn:FindFirstChild("Button")
        if not ButtonPart then return false end

        local ClickDet = ButtonPart:FindFirstChild("ClickDetector")
        if not ClickDet then return false end

        fireclickdetector(ClickDet)
        return true
    end)
    return sukses
end

-- 🔍 Cek kendaraan dan duduk otomatis
local function CekDanDudukKendaraan()
    local sukses, hasil = pcall(function()
        local WsCom = Workspace:FindFirstChild("WorkspaceCom")
        if not WsCom then return nil end

        local PenyimpananKapal = WsCom:FindFirstChild("001_CanoeStorage")
        if not PenyimpananKapal then return nil end

        for _, kendaraan in ipairs(PenyimpananKapal:GetChildren()) do
            if table.find(daftarKendaraanDiproses, kendaraan) then continue end

            local kursi = kendaraan:FindFirstChildOfClass("VehicleSeat")
            if not kursi then continue end
            if not kendaraan:IsDescendantOf(Workspace) then continue end

            local posKendaraan = kendaraan.PrimaryPart and kendaraan.PrimaryPart.Position or kendaraan:GetPivot().Position
            local jarak = (posKendaraan - lokasiSpawn).Magnitude
            if jarak > radiusSpawn then continue end

            if not kendaraan.PrimaryPart then kendaraan.PrimaryPart = kursi end

            -- Coba duduk
            for _ = 1, 5 do
                RootPart.CFrame = kursi.CFrame * CFrame.new(0, 1.2, 0.2)
                task.wait(0.15)
                if Humanoid.Sit then
                    table.insert(daftarKendaraanDiproses, kendaraan)
                    Notifikasi("Berhasil duduk di kapal")
                    return true
                end
            end
        end
        return false
    end)
    return sukses and hasil or false
end

-- Buat posisi acak tujuan
local function AmbilPosisiAcak()
    local acakX = math.random(-20, 20)
    local acakY = math.random(2, 20)
    local acakZ = math.random(-20, 20)
    return lokasiTujuanPusat + Vector3.new(acakX, acakY, acakZ)
end

-- ✅ FUNGSI UTAMA SESUAI PERMINTAAN
local function ProsesSiklus()
    Notifikasi("Memulai siklus...")

    -- Reset status
    Humanoid.Sit = false
    task.wait(0.2)

    -- Ulang sampai berhasil duduk
    local sudahDuduk = false
    local percobaan = 0

    repeat
        percobaan += 1
        Notifikasi("Percobaan ke-"..percobaan.." spawn kapal")

        -- 1. Klik spawn kapal
        KlikTombolSpawn()
        task.wait(0.3)

        -- 2. Teleport ke posisi cek
        if RootPart and RootPart:IsDescendantOf(Workspace) then
            RootPart.CFrame = CFrame.new(lokasiCekDuduk)
            task.wait(0.4)
        end

        -- 3. Cek dan coba duduk
        sudahDuduk = CekDanDudukKendaraan()
        task.wait(0.3)

    until sudahDuduk or percobaan >= 10 -- Maks 10x percobaan

    if not sudahDuduk then
        Notifikasi("Gagal dapat kapal, ulangi siklus")
        return
    end

    -- 4. Kalau sudah duduk, teleport ke tujuan
    Notifikasi("Memindahkan kapal ke tujuan...")
    local posisiTujuan = AmbilPosisiAcak()
    local cframeTujuan = CFrame.new(posisiTujuan)

    -- Ambil kapal yang sedang dikendarai
    local kendaraanDikendarai = Humanoid.SeatPart and Humanoid.SeatPart:FindFirstAncestorOfClass("Model")
    if kendaraanDikendarai and kendaraanDikendarai:IsDescendantOf(Workspace) and kendaraanDikendarai.PrimaryPart then
        kendaraanDikendarai:SetPrimaryPartCFrame(cframeTujuan)
        RootPart.CFrame = cframeTujuan * CFrame.new(0, 1, 0)
        Notifikasi("Berhasil dipindahkan!")
        task.wait(0.5)
    end

    -- 5. Turun dan kembali ke spawn
    Humanoid.Sit = false
    task.wait(0.3)

    local cobaTurun = 0
    while Humanoid.Sit and cobaTurun < 5 do
        Humanoid.Sit = false
        task.wait(0.15)
        cobaTurun += 1
    end

    if RootPart and RootPart:IsDescendantOf(Workspace) then
        RootPart.CFrame = CFrame.new(lokasiSpawn)
    end
    task.wait(0.4)
end

-- Jalankan / Hentikan
local function MulaiSpam()
    autoSpam = true
    table.clear(daftarKendaraanDiproses)
    Tombol.Text = "ON"
    Tombol.BackgroundColor3 = Color3.fromRGB(70, 180, 90)
    Notifikasi("✅ AKTIF - Alur baru diterapkan")

    task.spawn(function()
        while autoSpam do
            if not Character or not Character:IsDescendantOf(Workspace) then
                Character = LocalPlayer.CharacterAdded:Wait()
                Humanoid = Character:WaitForChild("Humanoid", 10)
                RootPart = Character:WaitForChild("HumanoidRootPart", 10)
            end
            ProsesSiklus()
            task.wait(0.5)
        end
    end)
end

local function HentikanSpam()
    autoSpam = false
    table.clear(daftarKendaraanDiproses)
    Tombol.Text = "OFF"
    Tombol.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    Notifikasi("❌ DIMATIKAN")
end

Tombol.MouseButton1Click:Connect(function()
    if autoSpam then HentikanSpam() else MulaiSpam() end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid", 10)
    RootPart = newChar:WaitForChild("HumanoidRootPart", 10)
end)

print("✅ Script siap: Alur spawn → cek duduk → teleport tujuan!")
