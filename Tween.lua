-- =====================================================
-- PLANT ESP + RADIUS TWEEN GLIDE | BmSkyMods
-- Grow a Garden | Standalone
-- Jalan = TweenService geser CFrame (kayak melayang)
-- Teleport CFrame hanya untuk switch dalam radius
-- =====================================================

local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- ── WALK SPEED (stud/detik, samain sama WalkSpeed default 16) ──
local WALK_SPEED = 34
local RADIUS     = 50

-- ── PLOT ──────────────────────────────────────────────
local function myPlotId() return LP:GetAttribute("PlotId") end
local function myPlot()
    local id = myPlotId()
    local g  = Workspace:FindFirstChild("Gardens")
    return id and g and g:FindFirstChild("Plot"..id)
end

-- ── CARI TANAMAN ──────────────────────────────────────
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

    local tomato     = #toms > 0 and toms[math.random(#toms)] or nil
    local strawberry = #strs > 0 and strs[math.random(#strs)] or nil
    return tomato, strawberry
end

-- ── POSISI PIVOT ──────────────────────────────────────
local function plantPos(plant)
    if not plant then return nil end
    local ok, p = pcall(function() return plant:GetPivot().Position end)
    if ok and p then return p end
    local bp = plant:FindFirstChildOfClass("BasePart")
    return bp and bp.Position or nil
end

-- ── ESP BILLBOARD ─────────────────────────────────────
local function makeESP(plant, label, color)
    if not plant then return end
    local adornee = plant:IsA("BasePart") and plant
                 or plant:FindFirstChildOfClass("BasePart")
                 or plant
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

-- ── LINGKARAN RADIUS ──────────────────────────────────
local function makeCircle(pos, color)
    if not pos then return end
    local p        = Instance.new("Part")
    p.Name         = "BmSkyRadius"
    p.Shape        = Enum.PartType.Cylinder
    p.Size         = Vector3.new(0.15, RADIUS * 2, RADIUS * 2)
    p.CFrame       = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.Neon
    p.Color        = color
    p.Transparency = 0.76
    p.Parent       = Workspace
end

-- ── TWEEN GLIDE ───────────────────────────────────────
local activeTween = nil

local function cancelTween()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
end

-- Geser player pakai TweenService dengan kecepatan WALK_SPEED stud/s
local function tweenWalkTo(targetPos)
    cancelTween()

    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Pertahankan Y player supaya tidak melayang di udara
    local dest = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
    local dist = (hrp.Position - dest).Magnitude

    if dist < 2 then return end -- udah deket, skip

    local duration = dist / WALK_SPEED  -- hitung waktu sesuai jarak

    -- Nonaktifkan Anchored sementara tidak perlu, kita tween RootPart langsung
    -- Tapi anchored default false, jadi langsung tween aja
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(dest) }
    )

    activeTween = tween
    tween:Play()

    -- Auto-clear handle setelah selesai
    tween.Completed:Connect(function()
        if activeTween == tween then
            activeTween = nil
        end
    end)
end

-- ── TELEPORT CFRAME (hanya switch dalam radius) ───────
local function teleportNear(plant)
    cancelTween()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = plantPos(plant)
    if not pos then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(10, 0, 0))
end

-- ── CEK GERAK / LOMPAT ────────────────────────────────
local function isMovingOrJumping()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.FloorMaterial == Enum.Material.Air then return true end
    local spd = Vector2.new(
        hrp.AssemblyLinearVelocity.X,
        hrp.AssemblyLinearVelocity.Z
    ).Magnitude
    return spd > 1.5
end

-- ═══════════════════════════════════════════════════════
-- MAIN
-- ═══════════════════════════════════════════════════════
local tomato, strawberry = findPlants()

if not tomato and not strawberry then
    warn("[BmSky] Tidak ditemukan Tomato / Strawberry di plot kamu.")
    return
end

print("[BmSky] Plant ESP + Radius Tween aktif")

makeESP(tomato,     "Tomato",     Color3.fromRGB(255, 80,  60))
makeESP(strawberry, "Strawberry", Color3.fromRGB(255, 130, 200))

local tPos = plantPos(tomato)
local sPos = plantPos(strawberry)

makeCircle(tPos, Color3.fromRGB(255, 80,  60))
makeCircle(sPos, Color3.fromRGB(255, 130, 200))

-- Target list bergantian
local targets   = {}
if tomato     then targets[#targets + 1] = tomato     end
if strawberry then targets[#targets + 1] = strawberry end
local targetIdx = 1

-- ── STATE ─────────────────────────────────────────────
local insideRadius = false
local stillTimer   = 0

-- ── LOOP SWITCH TANAMAN TIAP 10 DETIK (dalam radius) ──
task.spawn(function()
    while true do
        task.wait(10)
        if insideRadius and #targets > 0 then
            targetIdx = (targetIdx % #targets) + 1
            teleportNear(targets[targetIdx])
        end
    end
end)

-- ── HEARTBEAT: PANTAU PLAYER ──────────────────────────
RunService.Heartbeat:Connect(function(dt)
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pp    = hrp.Position
    local inRad = false
    if tPos and (pp - tPos).Magnitude <= RADIUS then inRad = true end
    if sPos and (pp - sPos).Magnitude <= RADIUS then inRad = true end

    if inRad then
        -- ── MASUK RADIUS ──────────────────────────────
        if not insideRadius then
            insideRadius = true
            cancelTween()              -- stop tween kalau lagi jalan
            teleportNear(targets[targetIdx])  -- langsung teleport ke target
        end
        stillTimer = 0

    else
        -- ── DI LUAR RADIUS ────────────────────────────
        if insideRadius then
            insideRadius = false
            stillTimer   = 0
            -- Jangan cancel tween di sini, biarkan player terus jalan
        end

        if isMovingOrJumping() and activeTween == nil then
            -- Player gerak sendiri (bukan dari tween kita) → reset timer diam
            stillTimer = 0
        elseif activeTween ~= nil then
            -- Lagi di-tween oleh script → jangan akumulasi timer
            stillTimer = 0
        else
            -- Diam + tidak ada tween aktif → akumulasi timer
            stillTimer = stillTimer + dt
            if stillTimer >= 15 then
                stillTimer = 0
                -- Glide jalan ke dekat tanaman target
                local dest = plantPos(targets[targetIdx])
                if dest then
                    tweenWalkTo(dest + Vector3.new(10, 0, 0))
                end
            end
        end
    end
end)

-- ── BERSIHKAN CONSOLE TIAP 30 DETIK ──────────────────
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() game:GetService("LogService"):ClearOutput() end)
        pcall(function() if consoleClear then consoleClear() end end)
    end
end)
