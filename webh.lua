-- ============================================================
-- VERSI HANYA TULIS KE BERKAS - REDFINGER
-- ============================================================

local folderPath = "DataFarm"
local fileName = "datagag.txt"
local fullPath = folderPath .. "/" .. fileName

-- Buat folder kalau belum ada
if not isfolder(folderPath) then
    makefolder(folderPath)
end

-- ============================================================
-- FUNGSI FORMAT ANGKA
-- ============================================================

local function formatAngka(angka)
    if not angka or angka == 0 then return "0" end
    
    local abs = math.abs(angka)
    local suffix = ""
    local value = angka
    
    if abs >= 1e12 then
        value = angka / 1e12
        suffix = "T"
    elseif abs >= 1e9 then
        value = angka / 1e9
        suffix = "B"
    elseif abs >= 1e6 then
        value = angka / 1e6
        suffix = "M"
    elseif abs >= 1e3 then
        value = angka / 1e3
        suffix = "K"
    end
    
    if suffix ~= "" then
        return string.format("%.2f%s", value, suffix)
    else
        return string.format("%.0f", angka)
    end
end

-- ============================================================
-- CEK ITEM FARMING
-- ============================================================

local function isFarmingItem(item)
    local name = item.Name
    
    local skipList = {
        "Humanoid", "HumanoidRootPart", "Billboard_UI", "GalaxyTexture",
        "Health", "Animate", "PetState", "Body Colors", "CharacterMesh",
        "Shirt", "Pants", "Left Leg", "Left Arm", "Right Leg", "Right Arm",
        "Torso", "Head", "BoySpaceHair", "GirlHair", "Hat", "Accessory",
        "Handle", "Grip"
    }
    
    for _, skip in ipairs(skipList) do
        if name == skip then return false end
    end
    
    local hasFruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")
    local hasSeed = item:GetAttribute("SeedTool") or item:GetAttribute("SeedName")
    local hasPet = item:GetAttribute("Pet") or item:GetAttribute("PetId")
    local hasWeight = item:GetAttribute("Weight")
    local isTool = item:IsA("Tool")
    
    if isTool and (hasFruit or hasSeed or hasPet or hasWeight) then
        return true
    end
    
    local farmingKeywords = {
        "Seed", "Fruit", "Berry", "Apple", "Mushroom", "Bamboo", "Cactus",
        "Tomato", "Corn", "Pumpkin", "Grape", "Mango", "Coconut", "Banana",
        "Pineapple", "Dragon", "Venus", "Moon", "Sunflower", "Lotus",
        "Sprinkler", "Watering", "Trowel", "Shovel", "Pot", "Gnome",
        "Pet", "Egg", "Owl", "Bear", "Bee", "Unicorn", "Dragonfly",
        "Raccoon", "Monkey", "Deer", "Frog", "Robin", "Ladder", "Crate"
    }
    
    for _, keyword in ipairs(farmingKeywords) do
        if name:find(keyword, 1, true) then
            return true
        end
    end
    
    return false
end

-- ============================================================
-- AMBIL DATA & TULIS KE BERKAS
-- ============================================================

local function getDataDanTulis()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end

    local sheckles = 0
    local items = {}
    local harvests = {}
    local totalHarvestWeight = 0
    local totalItems = 0

    -- Ambil uang
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local sv = ls:FindFirstChild("Sheckles")
            if sv then sheckles = sv.Value end
        end
    end)

    -- Ambil barang
    for _, holder in ipairs({plr.Character, plr:FindFirstChildOfClass("Backpack")}) do
        if holder then
            for _, item in ipairs(holder:GetChildren()) do
                if isFarmingItem(item) then
                    local nama = item.Name
                    local jml = item:GetAttribute("Count") or 1
                    local weight = item:GetAttribute("Weight") or 0
                    local fruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")

                    if weight > 0 and fruit then
                        local mutasi = item:GetAttribute("Mutation")
                        local key = nama
                        if mutasi and mutasi ~= "" and mutasi ~= "None" then
                            key = nama .. " [" .. mutasi .. "]"
                        end
                        harvests[key] = harvests[key] or {count=0, totalWeight=0}
                        harvests[key].count = harvests[key].count + jml
                        harvests[key].totalWeight = harvests[key].totalWeight + (weight * jml)
                        totalHarvestWeight = totalHarvestWeight + (weight * jml)
                    else
                        items[nama] = (items[nama] or 0) + jml
                    end
                    totalItems = totalItems + jml
                end
            end
        end
    end

    -- Susun teks
    local msg = {}
    msg[#msg+1] = "📊 DATA FARM"
    msg[#msg+1] = "👤 " .. plr.Name
    msg[#msg+1] = ""
    msg[#msg+1] = "💰 Jumlah Uang: " .. formatAngka(sheckles)
    msg[#msg+1] = ""
    msg[#msg+1] = "──────────────────────────────"
    msg[#msg+1] = ""
    msg[#msg+1] = "🎒 Item Backpack:"
    if next(items) then
        local sorted = {}
        for n,j in pairs(items) do sorted[#sorted+1]={n=n,j=j} end
        table.sort(sorted,function(a,b)return a.j>b.j end)
        for _,v in ipairs(sorted) do msg[#msg+1] = "  "..v.n.." x"..v.j end
    else
        msg[#msg+1] = "  (tidak ada item)"
    end
    msg[#msg+1] = ""
    msg[#msg+1] = "──────────────────────────────"
    msg[#msg+1] = ""
    msg[#msg+1] = "🌾 Hasil Panen:"
    if next(harvests) then
        local sorted = {}
        for n,d in pairs(harvests) do sorted[#sorted+1]={n=n,d=d} end
        table.sort(sorted,function(a,b)return a.d.totalWeight>b.d.totalWeight end)
        for _,v in ipairs(sorted) do
            local rata = v.d.totalWeight / v.d.count
            msg[#msg+1] = string.format("  %s [%.2f KG] x%d", v.n, rata, v.d.count)
        end
    else
        msg[#msg+1] = "  (belum ada hasil panen)"
    end
    msg[#msg+1] = ""
    msg[#msg+1] = "──────────────────────────────"
    msg[#msg+1] = ""
    msg[#msg+1] = "📦 Total Berat: "..formatAngka(totalHarvestWeight).." KG"
    msg[#msg+1] = "📦 Total Item: "..totalItems.." buah"
    msg[#msg+1] = ""
    msg[#msg+1] = "🕐 Waktu: "..os.date("%H:%M:%S")

    -- ✅ HANYA TULIS KE BERKAS
    tulis = table.concat(msg, "\n")
    writefile(fullPath, tulis)

    -- Notifikasi saja
    game.StarterGui:SetCore("SendNotification", {
        Title = "💾 Data Disimpan",
        Text = "Berkas diperbarui",
        Duration = 2
    })
end

-- ============================================================
-- JALANKAN BERKALA
-- ============================================================

print("[Monitor] Mode Tulis Berkas Aktif")

task.spawn(function()
    getDataDanTulis() -- tulis pertama kali
    while true do
        task.wait(10) -- perbarui setiap 10 detik
        getDataDanTulis()
    end
end)
