-- ============================================================
-- MONITOR DATA FARM - FORMAT JSON & REALTIME
-- ============================================================

local folderPath = "DataFarm"
local fileName = "datagag.json" -- ✅ UBAH JADI JSON
local fullPath = folderPath .. "/" .. fileName

-- Buat folder kalau belum ada
if not isfolder(folderPath) then
    makefolder(folderPath)
end

-- ============================================================
-- FUNGSI PENDUKUNG
-- ============================================================

-- Format angka (K/M/B/T)
local function formatAngka(angka)
    if not angka or angka == 0 then return "0" end
    local abs = math.abs(angka)
    local suf, val = "", angka
    if abs >= 1e12 then val = angka/1e12; suf = "T"
    elseif abs >= 1e9 then val = angka/1e9; suf = "B"
    elseif abs >= 1e6 then val = angka/1e6; suf = "M"
    elseif abs >= 1e3 then val = angka/1e3; suf = "K" end
    return suf~="" and string.format("%.2f%s",val,suf) or string.format("%.0f",angka)
end

-- Cek apakah barang adalah barang pertanian
local function isFarmingItem(item)
    local name = item.Name
    local daftarLewat = {
        "Humanoid","HumanoidRootPart","Billboard_UI","Health","Animate",
        "PetState","Body Colors","CharacterMesh","Shirt","Pants","Left Leg",
        "Left Arm","Right Leg","Right Arm","Torso","Head","Hair","Hat",
        "Accessory","Handle","Grip"
    }
    for _,l in daftarLewat do if name==l then return false end end

    local adaSifat = item:GetAttribute("Fruit") or item:GetAttribute("SeedTool") 
                  or item:GetAttribute("Pet") or item:GetAttribute("Weight")
    local alat = item:IsA("Tool") and adaSifat

    local kataKunci = {
        "Seed","Fruit","Berry","Apple","Mushroom","Tomato","Strawberry",
        "Blueberry","Grape","Cherry","Pineapple","Mango","Coconut","Banana",
        "Sprinkler","Watering","Can","Trowel","Shovel","Pot","Ladder","Crate",
        "Pet","Egg","Owl","Bee","Deer","Robin","Mutant","Starstruck"
    }
    for _,k in kataKunci do if name:find(k,1,true) then return true end end

    return alat
end

-- Ubah tabel jadi teks JSON sederhana
local function tabelKeJson(tbl)
    if type(tbl)~="table" then return "{}" end
    local bagian = {}
    for k,v in pairs(tbl) do
        if type(v)=="string" then
            bagian[#bagian+1] = string.format('"%s":"%s"',k,v:gsub('"','\\"'))
        elseif type(v)=="number" then
            bagian[#bagian+1] = string.format('"%s":%s',k,v)
        elseif type(v)=="table" then
            bagian[#bagian+1] = string.format('"%s":%s',k,tabelKeJson(v))
        end
    end
    return "{"..table.concat(bagian,",").."}"
end

-- ============================================================
-- AMBIL DATA & TULIS KE BERKAS
-- ============================================================

local dataSebelum = "" -- cegah tulis ulang kalau tidak berubah

local function ambilDanTulis()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end

    local uang = 0
    local barang = {}       -- ✅ Barang biasa
    local hasilPanen = {}    -- ✅ Hasil panen dengan berat
    local totalBerat = 0
    local totalSemua = 0

    -- Ambil uang
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local val = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if val then uang = val.Value end
        end
    end)

    -- ✅ CEK SEMUA TEMPAT: Karakter + Tas + Penyimpanan Lain
    local lokasi = {plr.Character, plr:FindFirstChildOfClass("Backpack")}
    for _,tempat in lokasi do
        if tempat then
            for _,item in tempat:GetChildren() do
                if isFarmingItem(item) then
                    local nama = item.Name
                    local jumlah = item:GetAttribute("Count") or 1
                    local berat = item:GetAttribute("Weight") or 0
                    varian = item:GetAttribute("Mutation") or ""

                    -- ✅ LEWATI JUMLAH 0
                    if jumlah <= 0 then continue end

                    if berat > 0 then
                        -- Masuk kategori Panen
                        local namaPenuh = varian~="" and varian~="None" 
                            and string.format("%s [%s]", nama, varian) or nama
                        if not hasilPanen[namaPenuh] then
                            hasilPanen[namaPenuh] = {jumlah=0, beratTotal=0, beratRata=0}
                        end
                        hasilPanen[namaPenuh].jumlah += jumlah
                        hasilPanen[namaPenuh].beratTotal += berat * jumlah
                        totalBerat += berat * jumlah
                    else
                        -- Masuk kategori Barang Biasa
                        barang[nama] = (barang[nama] or 0) + jumlah
                    end
                    totalSemua += jumlah
                end
            end
        end
    end

    -- ✅ SUSUN DATA FORMAT JSON
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

    -- Hanya tulis jika ada perubahan nyata
    local teksAkhir = tabelKeJson(data)
    if teksAkhir ~= dataSebelum then
        dataSebelum = teksAkhir
        writefile(fullPath, teksAkhir)
        -- Notifikasi singkat
        game.StarterGui:SetCore("SendNotification",{
            Title="✅ Data Diperbarui", Text="Terkirim", Duration=1
        })
    end
end

-- ============================================================
-- JALANKAN LEBIH CEPAT
-- ============================================================

print("[✅] Pemantau JSON AKTIF - Cek setiap 2 detik")
ambilDanTulis()
task.spawn(function()
    while true do
        task.wait(2) -- ✅ Lebih cepat tapi aman
        ambilDanTulis()
    end
end)
