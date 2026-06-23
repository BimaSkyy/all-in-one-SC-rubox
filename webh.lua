-- ============================================================
-- VERSI RAPI UNTUK DELTA EXECUTOR - PAKAI VERCEL
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
-- FUNGSI KIRIM KE VERCEL
-- ============================================================

local function sendToVercel(isiTeks)
    pcall(function()
        local http = game:GetService("HttpService")
        -- Bentuk data agar jelas di tampilan web
        local dataKirim = {
            pengirim = "Roblox_Delta",
            waktu_lokal = os.date("%H:%M:%S"),
            konten = isiTeks
        }
        local isiJson = http:JSONEncode(dataKirim)

        local metodeKirim = {
            -- Cara standar Roblox
            function()
                http:PostAsync(webhook, isiJson, Enum.HttpContentType.ApplicationJson)
            end,
            -- Cara cadangan 1
            function()
                if http_request then
                    http_request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = isiJson
                    })
                end
            end,
            -- Cara cadangan 2
            function()
                if request then
                    request({
                        Url = webhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = isiJson
                    })
                end
            end
        }

        -- Coba semua cara sampai ada yang berhasil
        for _, coba in ipairs(metodeKirim) do
            pcall(coba)
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
    local plr = game:GetServi
