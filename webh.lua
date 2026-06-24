-- ============================================================
-- WEBH.LUA — Direct Discord Webhook + Auto-Update GitHub
-- by BmSkyMods
-- ============================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1518959286523527168/yOIrqGiR2i159iMFjJQveCInzU3tejRJ1CmF3OHtS2CU6IY2ZJlPf4zp-1KPtG3t_oEf"
local GITHUB_URL  = "https://raw.githubusercontent.com/BimaSkyy/all-in-one-SC-rubox/refs/heads/main/webh.lua"

-- ============================================================
-- FLAG AKTIF — dimatikan otomatis saat update terdeteksi
-- ============================================================
local _running     = true
local _sourceAwal  = nil   -- konten script dari GitHub (referensi)

-- ============================================================
-- HTTP MULTI-METHOD FALLBACK
-- Dicoba satu per satu sampai ada yang berhasil
-- ============================================================
local function httpRequest(opts)
    local candidates = {
        -- 1. request() — paling umum (Synapse, KRNL, dll)
        function() return request(opts) end,
        -- 2. syn.request — Synapse lama
        function() return syn.request(opts) end,
        -- 3. http.request — beberapa executor lain
        function() return http.request(opts) end,
        -- 4. http_request — nama alternatif
        function() return http_request(opts) end,
        -- 5. fluxus.request — Fluxus executor
        function() return fluxus.request(opts) end,
        -- 6. getgenv fallback — cari di global env
        function() return (getgenv().request or getgenv().http_request)(opts) end,
        -- 7. HttpService RequestAsync — last resort
        function()
            return game:GetService("HttpService"):RequestAsync(opts)
        end,
    }
    for i, fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and res then
            return res, i  -- kembalikan juga nomor metode yang berhasil
        end
    end
    return nil, 0
end

local function httpGet(url)
    local res, metode = httpRequest({Url=url, Method="GET", Headers={}})
    if res and res.Body and #res.Body > 0 then
        return res.Body, metode
    end
    -- Fallback: game:HttpGet (GET only, Redfinger kadang support ini)
    local ok, r = pcall(function() return game:HttpGet(url, true) end)
    if ok and r and #r > 0 then return r, 99 end
    return nil, 0
end

-- ============================================================
-- ESCAPE JSON & FORMAT ANGKA
-- ============================================================
local function escapeStr(s)
    s = tostring(s or "")
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"',  '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

local function formatAngka(angka)
    if not angka or angka == 0 then return "0" end
    local abs = math.abs(angka)
    local suf, val = "", angka
    if     abs >= 1e12 then val = angka/1e12; suf = "T"
    elseif abs >= 1e9  then val = angka/1e9;  suf = "B"
    elseif abs >= 1e6  then val = angka/1e6;  suf = "M"
    elseif abs >= 1e3  then val = angka/1e3;  suf = "K" end
    return suf ~= "" and string.format("%.2f%s", val, suf) or string.format("%.0f", angka)
end

local function formatTimeLeft(detik)
    if not detik then return "-" end
    if detik < 0 then detik = 0 end
    local m = math.floor(detik / 60)
    local s = math.floor(detik % 60)
    if m > 60 then return string.format("%dh %dm", math.floor(m/60), m%60)
    elseif m > 0 then return string.format("%dm %02ds", m, s)
    else return string.format("%ds", s) end
end

-- ============================================================
-- KIRIM WEBHOOK — format Discord Embed
-- ============================================================
local function kirimWebhook(judul, fields, warna)
    warna = warna or 3066993  -- hijau default
    local fp = {}
    for _, f in ipairs(fields) do
        fp[#fp+1] = string.format(
            '{"name":"%s","value":"```\\n%s\\n```","inline":%s}',
            escapeStr(f.name), escapeStr(f.val), f.inline and "true" or "false"
        )
    end
    local embed = string.format(
        '{"title":"%s","color":%d,"fields":[%s],"footer":{"text":"BmSkyFarm \u{2022} %s"}}',
        escapeStr(judul), warna,
        table.concat(fp, ","),
        escapeStr(os.date("%H:%M:%S"))
    )
    local payload = '{"embeds":[' .. embed .. ']}'
    local res, metode = httpRequest({
        Url     = WEBHOOK_URL,
        Method  = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body    = payload
    })
    if res then
        -- print(string.format("[✅] Webhook terkirim (metode %d, status %s)", metode, tostring(res.StatusCode or "?")))
    else
        warn("[❌] Semua metode HTTP gagal — webhook tidak terkirim")
    end
    return res
end

-- ============================================================
-- AUTO-UPDATER: cek GitHub tiap 5 detik
-- ============================================================
task.spawn(function()
    -- Tunggu sebentar, ambil versi awal sebagai baseline
    task.wait(3)
    local src, m = httpGet(GITHUB_URL)
    if src then
        _sourceAwal = src
        -- print(string.format("[🔄] Auto-updater aktif — versi awal %d chars (metode %d)", #src, m))
    else
        warn("[🔄] Auto-updater: gagal ambil versi awal, akan retry tiap 5 detik")
    end

    while true do
        task.wait(5)
        if not _running then break end

        local newSrc = httpGet(GITHUB_URL)
        if not newSrc then continue end  -- gagal fetch, coba lagi nanti

        -- Jika sumber awal belum ada (retry setelah gagal), simpan dulu
        if not _sourceAwal then
            _sourceAwal = newSrc
            -- print("[🔄] Versi awal tersimpan (delayed):", #newSrc, "chars")
            continue
        end

        -- Ada perubahan?
        if newSrc ~= _sourceAwal then
            -- print("[🔄] UPDATE TERDETEKSI! Mematikan semua loop...")
            _running = false
            task.wait(0.3)

            -- Coba eksekusi script baru
            local ok, err = pcall(function()
                loadstring(newSrc)()
            end)
            if not ok then
                warn("[❌] Gagal eksekusi script baru: " .. tostring(err))
                -- Fallback: aktifkan lagi dengan source baru sebagai referensi
                _sourceAwal = newSrc
                _running = true
            end
            break  -- task ini selesai
        end
    end
end)

-- ============================================================
-- FUNGSI GAME: CUACA, RESTOCK, PET, PEMAIN
-- ============================================================
local RS = game:GetService("ReplicatedStorage")

local function getWeatherInfo()
    local cuaca, fase, faseEnd = "Unknown", "Unknown", nil
    pcall(function()
        local aw = workspace:GetAttribute("ActiveWeather")
        if aw then cuaca = tostring(aw) end
        local ap = workspace:GetAttribute("ActivePhase")
        if ap then fase = tostring(ap) end
        local pd = workspace:GetAttribute("PhaseDuration")
        if pd then faseEnd = tonumber(pd) - os.time() end
    end)
    return cuaca, fase, faseEnd
end

local function getRestockInfo()
    local seed, gear, crate = nil, nil, nil
    pcall(function()
        local sv = RS:FindFirstChild("StockValues")
        if not sv then return end
        local ss = sv:FindFirstChild("SeedShop")
        if ss and ss:FindFirstChild("UnixNextRestock") then seed  = tonumber(ss.UnixNextRestock.Value)   - os.time() end
        local gs = sv:FindFirstChild("GearShop")
        if gs and gs:FindFirstChild("UnixNextRestock") then gear  = tonumber(gs.UnixNextRestock.Value)   - os.time() end
        local cs = sv:FindFirstChild("CrateShop")
        if cs and cs:FindFirstChild("UnixNextRestock") then crate = tonumber(cs.UnixNextRestock.Value)   - os.time() end
    end)
    return seed, gear, crate
end

local function getWildPets()
    local hasil, seen = {}, {}
    local lokasi = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
    if not lokasi then return {} end
    for _, anak in ipairs(lokasi:GetChildren()) do
        local nama = anak:GetAttribute("PetName")
        if nama and not seen[nama] then
            seen[nama] = true
            hasil[#hasil+1] = "• " .. tostring(nama)
        end
    end
    return hasil
end

-- ============================================================
-- AMBIL DATA & KIRIM WEBHOOK
-- ============================================================
local daftarBeratSebelum = {}
local lastSendTime       = 0
local MIN_INTERVAL_SEND  = 20   -- min 20 detik antar kirim (Discord rate limit)
local PAKSA_KIRIM_TIAP   = 120  -- kirim paksa setiap 2 menit meskipun tidak ada perubahan

local function ambilDanKirim()
    if not _running then return end
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end

    local uang         = 0
    local hasilPanen   = {}
    local daftarBerat  = {}
    local totalBerat   = 0

    -- Uang
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local v = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if v then uang = v.Value end
        end
    end)

    -- Isi tas
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local nama   = item.Name
                local jumlah = item:GetAttribute("Count")  or 1
                local berat  = item:GetAttribute("Weight") or 0
                local mutasi = item:GetAttribute("Mutation") or ""
                if jumlah <= 0 then continue end
                if berat > 0 then
                    local np = (mutasi ~= "" and mutasi ~= "None") and (nama.." ["..mutasi.."]") or nama
                    daftarBerat[np]  = (daftarBerat[np]  or 0) + jumlah
                    hasilPanen[np]   = (hasilPanen[np]   or 0) + jumlah
                    totalBerat       = totalBerat + berat * jumlah
                end
            end
        end
    end

    -- Cek ada perubahan inventory?
    local adaPerubahan = false
    for n, j in pairs(daftarBerat) do
        if (daftarBeratSebelum[n] or 0) ~= j then adaPerubahan = true; break end
    end
    if not adaPerubahan then
        for n in pairs(daftarBeratSebelum) do
            if not daftarBerat[n] then adaPerubahan = true; break end
        end
    end
    daftarBeratSebelum = daftarBerat

    local now = os.time()
    -- Skip jika: tidak ada perubahan DAN belum 2 menit, ATAU interval minimum belum tercapai
    if (now - lastSendTime) < MIN_INTERVAL_SEND then return end
    if not adaPerubahan and (now - lastSendTime) < PAKSA_KIRIM_TIAP then return end
    lastSendTime = now

    -- ── Susun teks field ─────────────────────────────────────
    local cuaca, fase, faseEnd = getWeatherInfo()
    local sr, sg, sc           = getRestockInfo()

    local cuacaTeks = "🌤 " .. cuaca
    if fase ~= "Unknown" then
        cuacaTeks = cuacaTeks .. "\n🌙 Fase: " .. fase
        if faseEnd then cuacaTeks = cuacaTeks .. " (ganti " .. formatTimeLeft(faseEnd) .. ")" end
    end

    local restockTeks = "🌱 Seed:  " .. formatTimeLeft(sr) ..
                        "\n⚙️ Gear:  " .. formatTimeLeft(sg) ..
                        "\n📦 Crate: " .. formatTimeLeft(sc)

    local panenParts = {}
    for nama, jml in pairs(hasilPanen) do
        panenParts[#panenParts+1] = nama .. "  x" .. jml
    end
    table.sort(panenParts)
    local panenTeks = #panenParts > 0 and table.concat(panenParts, "\n") or "Kosong"

    local pets    = getWildPets()
    local petTeks = #pets > 0 and table.concat(pets, "\n") or "Tidak ada"

    local pemainList = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        local u2 = 0
        pcall(function()
            local ls = p:FindFirstChild("leaderstats")
            if ls then local v = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money"); if v then u2=v.Value end end
        end)
        pemainList[#pemainList+1] = p.Name .. "  —  " .. formatAngka(u2)
    end

    -- ── Kirim Embed ──────────────────────────────────────────
    kirimWebhook(
        "📊 " .. plr.Name .. "  ·  GAG Monitor",
        {
            {name="💰 Uang",        val=formatAngka(uang),       inline=true  },
            {name="⚖️ Berat Total", val=formatAngka(totalBerat), inline=true  },
            {name="🌤 Cuaca & Fase", val=cuacaTeks,              inline=false },
            {name="🔄 Restock",     val=restockTeks,             inline=false },
            {name="🎒 Isi Tas",     val=panenTeks,               inline=false },
            {name="🐾 Pet Liar",    val=petTeks,                 inline=true  },
            {name="👥 Pemain",      val=table.concat(pemainList,"\n"), inline=false },
        },
        3066993
    )
end

-- ============================================================
-- PEMANTAU RELOG (tetap pakai file lokal)
-- ============================================================
local folderPath      = "DataFarm"
local fileRelog       = folderPath .. "/relog.txt"
local fileRelogAccept = folderPath .. "/relogaccept.txt"
if not isfolder(folderPath) then makefolder(folderPath) end

task.spawn(function()
    while _running do
        task.wait(0.5)
        if isfile(fileRelog) then
            local isi = (readfile(fileRelog) or ""):gsub("%s+",""):lower()
            if isi == "true" then
                writefile(fileRelogAccept, "true")
                writefile(fileRelog, "")
                task.wait(0.2)
                game.StarterGui:SetCore("SendNotification",{Title="🔄 Pindah Server",Duration=2})
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(
                        game.PlaceId, game.JobId, game.Players.LocalPlayer
                    )
                end)
            end
        end
    end
end)

-- ============================================================
-- MULAI
-- ============================================================
-- print("[✅] webh.lua aktif — Discord webhook langsung, auto-update GitHub ON")
ambilDanKirim()
task.spawn(function()
    while _running do
        task.wait(2)
        ambilDanKirim()
    end
end)
