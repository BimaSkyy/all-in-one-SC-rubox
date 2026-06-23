-- ============================================================
-- MONITOR DATA FARM - CARA SEDERHANA & PASTI JALAN
-- ============================================================

local folderPath = "DataFarm"
local fileName = "datagag.json"
local fullPath = folderPath .. "/" .. fileName

-- Buat folder kalau belum ada
if not isfolder(folderPath) then
    makefolder(folderPath)
end

-- ============================================================
-- FUNGSI PENDUKUNG
-- ============================================================

-- Format angka jadi K/M/B/T
local function formatAngka(angka)
    if not angka or angka == 0 then return "0" end
    local abs = math.abs(angka)
    local suf, val = "", angka
    if abs >= 1e12 then val = angka / 1e12; suf = "T"
    elseif abs >= 1e9 then val = angka / 1e9; suf = "B"
    elseif abs >= 1e6 then val = angka / 1e6; suf = "M"
    elseif abs >= 1e3 then val = angka / 1e3; suf = "K" end
    return suf ~= "" and string.format("%.2f%s", val, suf) or string.format("%.0f", angka)
end

-- Ubah tabel jadi teks JSON sederhana
local function tabelKeJson(tbl)
    if type(tbl) ~= "table" then return "{}" end
    local bagian = {}
    for k, v in pairs(tbl) do
        if type(v) == "string" then
            bagian[#bagian + 1] = string.format('"%s":"%s"', k, v:gsub('"', '\\"'))
        elseif type(v) == "number" then
            bagian[#bagian + 1] = string.format('"%s":%s', k, v)
        elseif type(v) == "table" then
            bagian[#bagian + 1] = string.format('"%s":%s', k, tabelKeJson(v))
        end
    end
    return "{" .. table.concat(bagian, ",") .. "}"
end

-- ============================================================
-- AMBIL SEMUA BARANG TANPA PENYARINGAN RUMIT
-- ============================================================

local dataSebelum = "" -- Cegah tulis ulang kalau tidak berubah

local function ambilDanTulis()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end

    local uang = 0
    local barang = {}       -- Semua barang biasa
    local hasilPanen = {}    -- Barang yang punya berat (hasil panen)
    local totalBerat = 0
    local totalSemua = 0

    -- Ambil jumlah uang
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local val = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if val then uang = val.Value end
        end
    end)

    -- ✅ CARI SEMUA DI SINI: Backpack + Karakter
    local lokasi = {
        plr:FindFirstChildOfClass("Backpack"),
        plr.Character
    }

    for _, tempat in lokasi do
        if tempat then
            -- AMBIL SETIAP ANAK YANG ADA, TANPA SYARAT RUMIT
            for _, item in tempat:GetChildren() do
                -- Hanya ambil yang berjenis Alat (Tool) — ini yang selalu dipakai barang di tas
                if item:IsA("Tool") then
                    local nama = item.Name
                    -- Ambil jumlah dari atribut, kalau tidak ada pakai 1
                    local jumlah = item:GetAttribute("Count") or 1
                    local berat = item:GetAttribute("Weight") or 0
                    local mutasi = item:GetAttribute("Mutation") or ""

                    -- ✅ LEWATI JIKA JUMLAH 0
                    if jumlah <= 0 then continue end

                    -- Pisahkan kategori: ada berat = panen, tidak ada = barang biasa
                    if berat > 0 then
                        -- Buat nama lengkap kalau ada mutasi
                        local namaPenuh = nama
                        if mutasi ~= "" and mutasi ~= "None" then
                            namaPenuh = nama .. " [" .. mutasi .. "]"
                        end
                        -- Tambah hitungan
                        if not hasilPanen[namaPenuh] then
                            hasilPanen[namaPenuh] = {jumlah = 0, beratTotal = 0}
                        end
                        hasilPanen[namaPenuh].jumlah += jumlah
                        hasilPanen[namaPenuh].beratTotal += berat * jumlah
                        totalBerat += berat * jumlah
                    else
                        -- Masuk daftar barang biasa
                        barang[nama] = (barang[nama] or 0) + jumlah
                    end

                    totalSemua += jumlah
                end
            end
        end
    end

    -- ✅ SUSUN DATA LENGKAP KE JSON
    local data = {
        waktu = os.date("%H:%M:%S"),
        namaPemain = plr.Name,
        uang = uang,
        uangFormat = formatAngka(uang),
        barang = barang,
        panen = hasilPanen,
        totalBerat = totalBerat,
        totalBeratFormat = formatAngka(totalBerat),
        totalItem = totalSemua
    }

    -- Tulis ke berkas HANYA kalau ada perubahan
    local teksAkhir = tabelKeJson(data)
    if teksAkhir ~= dataSebelum then
        dataSebelum = teksAkhir
        writefile(fullPath, teksAkhir)
        -- Notifikasi kalau berhasil
        game.StarterGui:SetCore("SendNotification", {
            Title = "✅ Data Diperbarui",
            Text = "Tersimpan ke berkas",
            Duration = 1
        })
    end
end

-- ============================================================
-- JALANKAN BERKALA
-- ============================================================

print("[✅] Pemantau Sederhana AKTIF - Cek setiap 2 detik")
ambilDanTulis() -- Jalankan pertama kali langsung

task.spawn(function()
    while true do
        task.wait(2) -- Cek ulang cepat tapi aman
        ambilDanTulis()
    end
end)
