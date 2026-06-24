-- ============================================================
-- WEBH.LUA — Discord Webhook + Ball Cam + Plant ESP + Radius
-- by BmSkyMods (MERGED)
-- ============================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1518959286523527168/yOIrqGiR2i159iMFjJQveCInzU3tejRJ1CmF3OHtS2CU6IY2ZJlPf4zp-1KPtG3t_oEf"
local GITHUB_URL  = "https://raw.githubusercontent.com/BimaSkyy/all-in-one-SC-rubox/refs/heads/main/webh.lua"

-- ============================================================
-- FLAG AKTIF
-- ============================================================
local _running    = true
local _sourceAwal = nil

-- ============================================================
-- SERVICE
-- ============================================================
local Players      = game:GetService("Players")
local Workspace    = game:GetService("Workspace")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS           = game:GetService("ReplicatedStorage")
local LP           = Players.LocalPlayer

-- ============================================================
-- HTTP MULTI-METHOD FALLBACK
-- ============================================================
local function httpRequest(opts)
    local candidates = {
        function() return request(opts) end,
        function() return syn.request(opts) end,
        function() return http.request(opts) end,
        function() return http_request(opts) end,
        function() return fluxus.request(opts) end,
        function() return (getgenv().request or getgenv().http_request)(opts) end,
        function() return game:GetService("HttpService"):RequestAsync(opts) end,
    }
    for i, fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and res then return res, i end
    end
    return nil, 0
end

local function httpGet(url)
    local res, metode = httpRequest({Url=url, Method="GET", Headers={}})
    if res and res.Body and #res.Body > 0 then return res.Body, metode end
    local ok, r = pcall(function() return game:HttpGet(url, true) end)
    if ok and r and #r > 0 then return r, 99 end
    return nil, 0
end

-- ============================================================
-- ESCAPE JSON & FORMAT
-- ============================================================
local function escapeStr(s)
    s = tostring(s or "")
    s = s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
    return s
end

local function formatAngka(angka)
    if not angka or angka == 0 then return "0" end
    local abs = math.abs(angka)
    local suf, val = "", angka
    if     abs >= 1e12 then val=angka/1e12; suf="T"
    elseif abs >= 1e9  then val=angka/1e9;  suf="B"
    elseif abs >= 1e6  then val=angka/1e6;  suf="M"
    elseif abs >= 1e3  then val=angka/1e3;  suf="K" end
    return suf ~= "" and string.format("%.2f%s",val,suf) or string.format("%.0f",angka)
end

local function formatTimeLeft(detik)
    if not detik then return "-" end
    if detik < 0 then detik = 0 end
    local m = math.floor(detik/60)
    local s = math.floor(detik%60)
    if m > 60 then return string.format("%dh %dm", math.floor(m/60), m%60)
    elseif m > 0 then return string.format("%dm %02ds", m, s)
    else return string.format("%ds", s) end
end

-- ============================================================
-- KIRIM WEBHOOK
-- ============================================================
local function kirimWebhook(judul, fields, warna)
    warna = warna or 3066993
    local fp = {}
    for _, f in ipairs(fields) do
        fp[#fp+1] = string.format(
            '{"name":"%s","value":"```\\n%s\\n```","inline":%s}',
            escapeStr(f.name), escapeStr(f.val), f.inline and "true" or "false"
        )
    end
    local embed = string.format(
        '{"title":"%s","color":%d,"fields":[%s],"footer":{"text":"BmSkyFarm \u{2022} %s"}}',
        escapeStr(judul), warna, table.concat(fp,","), escapeStr(os.date("%H:%M:%S"))
    )
    local payload = '{"embeds":[' .. embed .. ']}'
    httpRequest({
        Url     = WEBHOOK_URL,
        Method  = "POST",
        Headers = {["Content-Type"]="application/json"},
        Body    = payload
    })
end

-- ============================================================
-- AUTO-UPDATER
-- ============================================================
task.spawn(function()
    task.wait(3)
    local src, m = httpGet(GITHUB_URL)
    if src then _sourceAwal = src end

    while true do
        task.wait(5)
        if not _running then break end
        local newSrc = httpGet(GITHUB_URL)
        if not newSrc then continue end
        if not _sourceAwal then _sourceAwal = newSrc; continue end
        if newSrc ~= _sourceAwal then
            _running = false
            task.wait(0.3)
            local ok, err = pcall(function() loadstring(newSrc)() end)
            if not ok then
                warn("[❌] Gagal eksekusi script baru: " .. tostring(err))
                _sourceAwal = newSrc
                _running = true
            end
            break
        end
    end
end)

-- ============================================================
-- FUNGSI GAME: CUACA, RESTOCK, PET
-- ============================================================
local function getWeatherInfo()
    local cuaca, fase, faseEnd = "Unknown","Unknown",nil
    pcall(function()
        local aw = workspace:GetAttribute("ActiveWeather");  if aw then cuaca=tostring(aw) end
        local ap = workspace:GetAttribute("ActivePhase");    if ap then fase=tostring(ap)  end
        local pd = workspace:GetAttribute("PhaseDuration");  if pd then faseEnd=tonumber(pd)-os.time() end
    end)
    return cuaca, fase, faseEnd
end

local function getRestockInfo()
    local seed,gear,crate = nil,nil,nil
    pcall(function()
        local sv = RS:FindFirstChild("StockValues"); if not sv then return end
        local ss = sv:FindFirstChild("SeedShop")
        if ss and ss:FindFirstChild("UnixNextRestock") then seed  = tonumber(ss.UnixNextRestock.Value)  - os.time() end
        local gs = sv:FindFirstChild("GearShop")
        if gs and gs:FindFirstChild("UnixNextRestock") then gear  = tonumber(gs.UnixNextRestock.Value)  - os.time() end
        local cs = sv:FindFirstChild("CrateShop")
        if cs and cs:FindFirstChild("UnixNextRestock") then crate = tonumber(cs.UnixNextRestock.Value)  - os.time() end
    end)
    return seed, gear, crate
end

local function getWildPets()
    local hasil, seen = {}, {}
    local lokasi = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
    if not lokasi then return {} end
    for _, anak in ipairs(lokasi:GetChildren()) do
        local nama = anak:GetAttribute("PetName")
        if nama and not seen[nama] then seen[nama]=true; hasil[#hasil+1]="• "..tostring(nama) end
    end
    return hasil
end

-- ============================================================
-- BALL + KAMERA SYSTEM
-- ============================================================
local BALL_HEIGHT = 80   -- stud di atas player
local ballPart    = nil

local function createBall()
    -- Hancurkan bola lama kalau ada
    if ballPart and ballPart.Parent then
        pcall(function() ballPart:Destroy() end)
    end

    local p           = Instance.new("Part")
    p.Name            = "BmSkyBall"
    p.Shape           = Enum.PartType.Ball
    p.Size            = Vector3.new(4, 4, 4)
    p.Anchored        = true
    p.CanCollide      = false
    p.CastShadow      = false
    p.Material        = Enum.Material.Neon
    p.Color           = Color3.fromRGB(0, 200, 255)
    p.Transparency    = 0.25
    p.Parent          = Workspace

    -- Posisi awal
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        p.CFrame = CFrame.new(hrp.Position + Vector3.new(0, BALL_HEIGHT, 0))
    end

    ballPart = p
    return p
end

local function attachCamera()
    if not ballPart or not ballPart.Parent then return end
    local cam = Workspace.CurrentCamera
    cam.CameraType    = Enum.CameraType.Custom
    cam.CameraSubject = ballPart
end

-- Validasi bola + kamera — dipanggil tiap sebelum kirim webhook
local function cekDanResetBall()
    local ballOk = ballPart ~= nil and ballPart.Parent ~= nil
    local camOk  = ballOk and (Workspace.CurrentCamera.CameraSubject == ballPart)

    if not ballOk or not camOk then
        createBall()
        attachCamera()
    end
end

-- Init pertama kali
createBall()
attachCamera()

-- Follow player real-time via Heartbeat
RunService.Heartbeat:Connect(function()
    if not ballPart or not ballPart.Parent then return end
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        ballPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, BALL_HEIGHT, 0))
    end
end)

-- Pastikan kamera tetap ke bola saat character respawn
LP.CharacterAdded:Connect(function()
    task.wait(1)
    cekDanResetBall()
end)

-- ============================================================
-- PLANT ESP + RADIUS TWEEN
-- ============================================================
local WALK_SPEED = 34
local RADIUS     = 50

-- ── Plot ──────────────────────────────────────────────────
local function myPlotId() return LP:GetAttribute("PlotId") end
local function myPlot()
    local id = myPlotId()
    local g  = Workspace:FindFirstChild("Gardens")
    return id and g and g:FindFirstChild("Plot"..id)
end

-- ── Cari tanaman ──────────────────────────────────────────
local function findPlants()
    local plot = myPlot()
    if not plot then return nil, nil end
    local folder = plot:FindFirstChild("Plants")
    if not folder then return nil, nil end

    local toms, strs = {}, {}
    for _, child in ipairs(folder:GetChildren()) do
        local seed = child:GetAttribute("SeedName")
        if seed == "Tomato"     then toms[#toms+1] = child end
        if seed == "Strawberry" then strs[#strs+1] = child end
    end

    return (#toms > 0 and toms[math.random(#toms)] or nil),
           (#strs > 0 and strs[math.random(#strs)] or nil)
end

-- ── Posisi pivot ──────────────────────────────────────────
local function plantPos(plant)
    if not plant then return nil end
    local ok, p = pcall(function() return plant:GetPivot().Position end)
    if ok and p then return p end
    local bp = plant:FindFirstChildOfClass("BasePart")
    return bp and bp.Position or nil
end

-- ── ESP Billboard ─────────────────────────────────────────
local function makeESP(plant, label, color)
    if not plant then return end
    local adornee = plant:IsA("BasePart") and plant
                 or plant:FindFirstChildOfClass("BasePart") or plant
    local bb         = Instance.new("BillboardGui")
    bb.Name          = "BmSkyESP_"..label
    bb.Adornee       = adornee
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.fromOffset(90, 22)
    bb.StudsOffset   = Vector3.new(0, 4, 0)
    bb.Parent        = game:GetService("CoreGui")
    local txt                  = Instance.new("TextLabel")
    txt.Size                   = UDim2.fromScale(1, 1)
    txt.BackgroundTransparency = 1
    txt.Text                   = label
    txt.TextColor3             = color
    txt.TextStrokeTransparency = 0
    txt.TextScaled             = true
    txt.Font                   = Enum.Font.GothamBold
    txt.Parent                 = bb
end

-- ── Lingkaran radius ──────────────────────────────────────
local function makeCircle(pos, color)
    if not pos then return end
    local p        = Instance.new("Part")
    p.Name         = "BmSkyRadius"
    p.Shape        = Enum.PartType.Cylinder
    p.Size         = Vector3.new(0.15, RADIUS*2, RADIUS*2)
    p.CFrame       = CFrame.new(pos + Vector3.new(0,0.15,0)) * CFrame.Angles(0, 0, math.pi/2)
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.Neon
    p.Color        = color
    p.Transparency = 0.76
    p.Parent       = Workspace
end

-- ── Tween glide ───────────────────────────────────────────
local activeTween = nil

local function cancelTween()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
end

local function tweenWalkTo(targetPos)
    cancelTween()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dest = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    local dist = (hrp.Position - dest).Magnitude
    if dist < 2 then return end
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(dist / WALK_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(dest) }
    )
    activeTween = tween
    tween:Play()
    tween.Completed:Connect(function()
        if activeTween == tween then activeTween = nil end
    end)
end

-- ── Teleport CFrame (hanya dalam radius, switch tanaman) ──
local function teleportNear(plant)
    cancelTween()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = plantPos(plant)
    if not pos then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(10, 0, 0))
end

-- ── Cek gerak/lompat ──────────────────────────────────────
local function isMovingOrJumping()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.FloorMaterial == Enum.Material.Air then return true end
    return Vector2.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Z).Magnitude > 1.5
end

-- ── Init plant ESP ────────────────────────────────────────
local tomato, strawberry = findPlants()

if tomato or strawberry then
    -- print("[BmSky] Plant ESP + Radius Tween aktif")
    makeESP(tomato,     "Tomato",     Color3.fromRGB(255, 80,  60))
    makeESP(strawberry, "Strawberry", Color3.fromRGB(255, 130, 200))
end

local tPos = plantPos(tomato)
local sPos = plantPos(strawberry)
makeCircle(tPos, Color3.fromRGB(255, 80,  60))
makeCircle(sPos, Color3.fromRGB(255, 130, 200))

local targets   = {}
if tomato     then targets[#targets+1] = tomato     end
if strawberry then targets[#targets+1] = strawberry end
local targetIdx = 1

-- ── State radius ──────────────────────────────────────────
local insideRadius = false
local stillTimer   = 0

-- ── Loop switch tanaman tiap 10 detik ─────────────────────
task.spawn(function()
    while true do
        task.wait(10)
        if insideRadius and #targets > 0 then
            targetIdx = (targetIdx % #targets) + 1
            teleportNear(targets[targetIdx])
        end
    end
end)

-- ── Heartbeat: pantau player radius + update bola ─────────
-- (Heartbeat sudah dipakai untuk bola di atas,
--  tapi kita pakai Stepped agar tidak conflict)
RunService.Stepped:Connect(function(_, dt)
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pp    = hrp.Position
    local inRad = false
    if tPos and (pp - tPos).Magnitude <= RADIUS then inRad = true end
    if sPos and (pp - sPos).Magnitude <= RADIUS then inRad = true end

    if inRad then
        if not insideRadius then
            insideRadius = true
            cancelTween()
            teleportNear(targets[targetIdx])
        end
        stillTimer = 0
    else
        if insideRadius then
            insideRadius = false
            stillTimer   = 0
        end
        if isMovingOrJumping() and activeTween == nil then
            stillTimer = 0
        elseif activeTween ~= nil then
            stillTimer = 0
        else
            stillTimer = stillTimer + dt
            if stillTimer >= 15 then
                stillTimer = 0
                local dest = plantPos(targets[targetIdx])
                if dest then tweenWalkTo(dest + Vector3.new(10, 0, 0)) end
            end
        end
    end
end)

-- ============================================================
-- AMBIL DATA & KIRIM WEBHOOK
-- ============================================================
local daftarBeratSebelum = {}
local lastSendTime       = 0
local MIN_INTERVAL_SEND  = 20
local PAKSA_KIRIM_TIAP   = 120

local function ambilDanKirim()
    if not _running then return end
    local plr = LP
    if not plr then return end

    local uang       = 0
    local toolsList  = {}   -- item tanpa berat = tools asli
    local buahList   = {}   -- item dengan berat > 0 = buah/panen
    local totalBerat = 0

    -- Uang
    pcall(function()
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            local v = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if v then uang = v.Value end
        end
    end)

    -- Isi tas — pisah tools vs buah
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local nama   = item.Name
                local jumlah = item:GetAttribute("Count")   or 1
                local berat  = item:GetAttribute("Weight")  or 0
                local mutasi = item:GetAttribute("Mutation") or ""
                if jumlah <= 0 then continue end

                if berat > 0 then
                    -- ── BUAH/PANEN (ada berat kg) ────────────
                    local np = (mutasi ~= "" and mutasi ~= "None")
                               and (nama.." ["..mutasi.."]") or nama
                    buahList[np]  = (buahList[np]  or 0) + jumlah
                    totalBerat    = totalBerat + berat * jumlah
                else
                    -- ── TOOLS ASLI ───────────────────────────
                    toolsList[nama] = (toolsList[nama] or 0) + jumlah
                end
            end
        end
    end

    -- Cek perubahan
    local adaPerubahan = false
    for n, j in pairs(buahList) do
        if (daftarBeratSebelum[n] or 0) ~= j then adaPerubahan=true; break end
    end
    if not adaPerubahan then
        for n in pairs(daftarBeratSebelum) do
            if not buahList[n] then adaPerubahan=true; break end
        end
    end
    daftarBeratSebelum = buahList

    local now = os.time()
    if (now - lastSendTime) < MIN_INTERVAL_SEND then return end
    if not adaPerubahan and (now - lastSendTime) < PAKSA_KIRIM_TIAP then return end
    lastSendTime = now

    -- ── Validasi bola + kamera sebelum kirim ─────────────
    cekDanResetBall()

    -- ── Susun field ───────────────────────────────────────
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

    -- Tools list
    local toolsParts = {}
    for nama, jml in pairs(toolsList) do
        toolsParts[#toolsParts+1] = string.format("%-20s x%d", nama, jml)
    end
    table.sort(toolsParts)
    local toolsTeks = #toolsParts > 0 and table.concat(toolsParts, "\n") or "Kosong"

    -- Buah/panen list
    local buahParts = {}
    for nama, jml in pairs(buahList) do
        buahParts[#buahParts+1] = string.format("%-20s x%d", nama, jml)
    end
    table.sort(buahParts)
    local buahTeks = #buahParts > 0 and table.concat(buahParts, "\n") or "Kosong"

    local pets    = getWildPets()
    local petTeks = #pets > 0 and table.concat(pets,"\n") or "Tidak ada"

    local pemainList = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        local u2 = 0
        pcall(function()
            local ls = p:FindFirstChild("leaderstats")
            if ls then
                local v = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
                if v then u2 = v.Value end
            end
        end)
        pemainList[#pemainList+1] = p.Name .. "  —  " .. formatAngka(u2)
    end

    -- ── Kirim Embed ───────────────────────────────────────
    kirimWebhook(
        "📊 " .. plr.Name .. "  ·  GAG Monitor",
        {
            {name="💰 Uang",          val=formatAngka(uang),            inline=true  },
            {name="⚖️ Berat Total",   val=formatAngka(totalBerat).."kg",inline=true  },
            {name="🌤 Cuaca & Fase",  val=cuacaTeks,                    inline=false },
            {name="🔄 Restock",       val=restockTeks,                  inline=false },
            {name="🧰 Tools",         val=toolsTeks,                    inline=false },
            {name="🌾 Panen",         val=buahTeks,                     inline=false },
            {name="🐾 Pet Liar",      val=petTeks,                      inline=true  },
            {name="👥 Pemain",        val=table.concat(pemainList,"\n"),inline=false },
        },
        3066993
    )
end

-- ============================================================
-- PEMANTAU RELOG
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
                        game.PlaceId, game.JobId, LP
                    )
                end)
            end
        end
    end
end)

-- ============================================================
-- BERSIHKAN CONSOLE TIAP 30 DETIK
-- ============================================================
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() game:GetService("LogService"):ClearOutput() end)
        pcall(function() if consoleClear then consoleClear() end end)
    end
end)

-- ============================================================
-- MULAI
-- ============================================================
ambilDanKirim()
task.spawn(function()
    while _running do
        task.wait(2)
        ambilDanKirim()
    end
end)
