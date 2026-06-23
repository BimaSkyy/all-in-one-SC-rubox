-- ============================================================
-- VERSI PERBAIKAN KHUSUS REDFINGER + DELTA
-- ============================================================

local webhook = "https://vercel-webhooktest.vercel.app/api/webhook"

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
-- FUNGSI KIRIM KE VERCEL - VERSI AMAN REDFINGER
-- ============================================================

local function sendToVercel(isiTeks)
    pcall(function()
        local httpSvc = game:GetService("HttpService")
        -- Pastikan layanan aktif
        if not httpSvc.HttpEnabled then
            pcall(function() httpSvc.HttpEnabled = true end)
        end

        local dataKirim = {
            pengirim = "Roblox_Redfinger",
            waktu_lokal = os.date("%H:%M:%S"),
            konten = isiTeks
        }
        local isiJson = httpSvc:JSONEncode(dataKirim)

        -- ✅ URUTAN DIUBAH: Utamakan fungsi yang paling pasti di Delta/Redfinger
        local metodeKirim = {
            -- Cara khas Executor biasanya lebih diizinkan di awan
            function()
                if typeof(request) == "function" then
                    return request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = isiJson
                    })
                end
            end,
            function()
                if typeof(http_request) == "function" then
                    return http_request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = isiJson
                    })
                end
            end,
            -- Cara bawaan Roblox (sering dibatasi di awan)
            function()
                return httpSvc:PostAsync(webhook, isiJson, Enum.HttpContentType.ApplicationJson)
            end
        }

        -- Coba satu per satu sampai berhasil
        for _, coba in ipairs(metodeKirim) do
            local ok, hasil = pcall(coba)
            if ok and hasil then
                print("[Vercel] Berhasil dikirim")
                break
            end
        end
    end)
end

-- ============================================================
-- BAGIAN CEK ITEM DAN DATA (TIDAK DIUBAH)
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

local function isHarvest(item)
    local weight = item:GetAttribute("Weight")
    local fruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")
    return weight and weight > 0 and fruit ~= nil
end

local function getData()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return "Player not found" end
    
    local sheckles = 0
    local items = {}
    local harvests = {}
    local totalHarvestWeight = 0
    local totalItems = 0
    
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local sv = ls:FindFirstChild("Sheckles")
            if sv then sheckles = sv.Value end
        end
    end)
    
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
                        
                        harvests[key] = harvests[key] or {count = 0, totalWeight = 0}
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
    
    local msg = {}
    msg[#msg + 1] = "📊 DATA FARM"
    msg[#msg + 1] = "👤 " .. plr.Name
    msg[#msg + 1] = ""
    msg[#msg + 1] = "💰 Jumlah Uang: " .. formatAngka(sheckles)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "🎒 Item Backpack:"
    if next(items) then
        local sortedItems = {}
        for nama, jml in pairs(items) do
            sortedItems[#sortedItems + 1] = {nama = nama, jml = jml}
        end
        table.sort(sortedItems, function(a, b) return a.jml > b.jml end)
        for _, item in ipairs(sortedItems) do
            msg[#msg + 1] = "  " .. item.nama .. " x" .. item.jml
        end
    else
        msg[#msg + 1] = "  (tidak ada item)"
    end
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "🌾 Hasil Panen:"
    if next(harvests) then
        local sortedHarvests = {}
        for nama, data in pairs(harvests) do
            sortedHarvests[#sortedHarvests + 1] = {nama = nama, data = data}
        end
        table.sort(sortedHarvests, function(a, b) return a.data.totalWeight > b.data.totalWeight end)
        for _, h in ipairs(sortedHarvests) do
            local avgWeight = h.data.totalWeight / h.data.count
            msg[#msg + 1] = string.format("  %s [%.2f KG] x%d", h.nama, avgWeight, h.data.count)
        end
    else
        msg[#msg + 1] = "  (belum ada hasil panen)"
    end
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "📦 Total Semua Panen: " .. formatAngka(totalHarvestWeight) .. " KG"
    msg[#msg + 1] = "📦 Total Semua Item: " .. totalItems .. " item"
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "🕐 Update at: " .. os.date("%H:%M:%S")
    
    return table.concat(msg, "\n")
end

-- ============================================================
-- JALANKAN
-- ============================================================

print("[Monitor] Versi Perbaikan untuk Redfinger")

local lastMessage = ""
local sameCount = 0
local maxSame = 5

task.spawn(function()
    local data = getData()
    sendToVercel(data)
    lastMessage = data
    
    while true do
        task.wait(10)
        pcall(function()
            local dataBaru = getData()
            if dataBaru ~= lastMessage then
                sendToVercel(dataBaru)
                lastMessage = dataBaru
                sameCount = 0
            else
                sameCount = sameCount + 1
                if sameCount >= maxSame then
                    sendToVercel(dataBaru .. "\n\n🔄 Masih Berjalan di Redfinger: " .. os.date("%H:%M:%S"))
                    sameCount = 0
                end
            end
        end)
    end
end)

print("[Monitor] Siap di Redfinger!")
