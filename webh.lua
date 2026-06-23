-- ============================================================
-- VERSI RAPI UNTUK DELTA EXECUTOR
-- ============================================================

local webhook = "https://discord.com/api/webhooks/1518974323656753323/mtoqg0QW-Co8vZK2rW7XavRx69J6J8KsnIzY7pNaHWIKIiWjZBrvSSr1Z5muddjHwPm1"

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
-- FUNGSI KIRIM KE DISCORD
-- ============================================================

local function sendToDiscord(msg)
    pcall(function()
        local methods = {
            function()
                local http = game:GetService("HttpService")
                local data = { content = msg }
                http:PostAsync(webhook, http:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
            end,
            function()
                if http_request then
                    http_request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = game:GetService("HttpService"):JSONEncode({content = msg})
                    })
                end
            end,
            function()
                if request then
                    request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = game:GetService("HttpService"):JSONEncode({content = msg})
                    })
                end
            end
        }
        
        for _, method in ipairs(methods) do
            pcall(method)
        end
    end)
end

-- ============================================================
-- CEK APAKAH ITEM FARMING / HASIL PANEN
-- ============================================================

local function isFarmingItem(item)
    local name = item.Name
    
    -- Skip item karakter
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
    
    -- Cek apakah item punya atribut farming
    local hasFruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")
    local hasSeed = item:GetAttribute("SeedTool") or item:GetAttribute("SeedName")
    local hasPet = item:GetAttribute("Pet") or item:GetAttribute("PetId")
    local hasWeight = item:GetAttribute("Weight")
    local isTool = item:IsA("Tool")
    
    if isTool and (hasFruit or hasSeed or hasPet or hasWeight) then
        return true
    end
    
    -- Nama item yang mengandung kata kunci farming
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

-- Cek apakah item adalah hasil panen (punya berat)
local function isHarvest(item)
    local weight = item:GetAttribute("Weight")
    local fruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")
    return weight and weight > 0 and fruit ~= nil
end

-- ============================================================
-- AMBIL DATA FARMING
-- ============================================================

local function getData()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return "Player not found" end
    
    -- Variabel untuk menyimpan data
    local sheckles = 0
    local items = {}          -- item backpack (non-harvest)
    local harvests = {}       -- hasil panen (punya berat)
    local totalHarvestWeight = 0
    local totalItems = 0
    
    -- Ambil Sheckles
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local sv = ls:FindFirstChild("Sheckles")
            if sv then sheckles = sv.Value end
        end
    end)
    
    -- Ambil semua item
    for _, holder in ipairs({plr.Character, plr:FindFirstChildOfClass("Backpack")}) do
        if holder then
            for _, item in ipairs(holder:GetChildren()) do
                if isFarmingItem(item) then
                    local nama = item.Name
                    local jml = item:GetAttribute("Count") or 1
                    local weight = item:GetAttribute("Weight") or 0
                    
                    -- Cek apakah hasil panen
                    local fruit = item:GetAttribute("Fruit") or item:GetAttribute("FruitName")
                    
                    if weight > 0 and fruit then
                        -- HASIL PANEN: kelompokkan berdasarkan nama + mutasi
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
                        -- ITEM BACKPACK (non-harvest)
                        items[nama] = (items[nama] or 0) + jml
                    end
                    
                    totalItems = totalItems + jml
                end
            end
        end
    end
    
    -- ============================================================
    -- SUSUN PESAN
    -- ============================================================
    
    local msg = {}
    
    -- Header
    msg[#msg + 1] = "📊 DATA FARM"
    msg[#msg + 1] = "👤 " .. plr.Name
    msg[#msg + 1] = ""
    
    -- Jumlah Uang
    msg[#msg + 1] = "💰 Jumlah Uang: " .. formatAngka(sheckles)
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    
    -- Item Backpack (non-harvest)
    msg[#msg + 1] = "🎒 Item Backpack:"
    if next(items) then
        -- Sortir items
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
    
    -- Hasil Panen
    msg[#msg + 1] = "🌾 Hasil Panen:"
    if next(harvests) then
        -- Sortir harvest berdasarkan total berat
        local sortedHarvests = {}
        for nama, data in pairs(harvests) do
            sortedHarvests[#sortedHarvests + 1] = {nama = nama, data = data}
        end
        table.sort(sortedHarvests, function(a, b) 
            return a.data.totalWeight > b.data.totalWeight 
        end)
        
        for _, h in ipairs(sortedHarvests) do
            local avgWeight = h.data.totalWeight / h.data.count
            msg[#msg + 1] = string.format("  %s [%.2f KG] x%d", 
                h.nama, 
                avgWeight, 
                h.data.count
            )
        end
    else
        msg[#msg + 1] = "  (belum ada hasil panen)"
    end
    msg[#msg + 1] = ""
    msg[#msg + 1] = "─" .. string.rep("─", 30)
    msg[#msg + 1] = ""
    
    -- Total
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

print("[Monitor] Script jalan untuk Delta Executor")

local lastMessage = ""
local sameCount = 0
local maxSame = 5

task.spawn(function()
    -- Kirim pertama kali
    local data = getData()
    sendToDiscord("```" .. data .. "```")
    lastMessage = data
    
    while true do
        task.wait(10)
        
        pcall(function()
            local data = getData()
            
            if data ~= lastMessage then
                sendToDiscord("```" .. data .. "```")
                lastMessage = data
                sameCount = 0
                print("[Monitor] Data berubah, mengirim update")
            else
                sameCount = sameCount + 1
                if sameCount >= maxSame then
                    -- Kirim ulang sebagai heartbeat
                    local heartbeatData = data .. "\n\n🔄 Heartbeat: " .. os.date("%H:%M:%S")
                    sendToDiscord("```" .. heartbeatData .. "```")
                    sameCount = 0
                    print("[Monitor] Heartbeat dikirim")
                end
            end
        end)
    end
end)

print("[Monitor] Siap!")
