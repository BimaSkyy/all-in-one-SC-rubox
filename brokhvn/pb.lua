-- ══════════════════════════════════════
--   Tent Orbit v5  |  by BmSky
--   + Ball Follow
--   + Minimize on header click
--   + List Action popup (semua mode)
--   + Height Slider
--   + Mode: Orbit, Follow, L-R, Love,
--           Road, DNA, Snake, Tornado
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════
--   STATE
-- ══════════════════════════════════════
local currentMode     = "none"
local orbitConnection = nil
local tentFolders     = {}
local orbitAngle      = 0
local ORBIT_RADIUS    = 8
local ORBIT_SPEED     = 1.2
local TOTAL_TENTS     = 2
local HEIGHT_OFFSET   = 0.025   -- diubah via slider
local PLAYER_NAME     = LocalPlayer.Name

-- Ball Follow
local ballFollowActive = false
local ball             = nil
local ballSpeed        = 60
local verticalMove     = 0

-- Minimize
local isMinimized  = false
local PANEL_W      = 230
local PANEL_H_FULL = 260
local PANEL_H_MIN  = 26

-- List Action popup
local listOpen = false

-- Path tenda
local wsCom        = workspace:FindFirstChild("WorkspaceCom")
local trafficCones = wsCom and wsCom:FindFirstChild("001_TrafficCones")
if not trafficCones then warn("[TentOrbit] 001_TrafficCones tidak ditemukan!"); return end

-- ══════════════════════════════════════
--   HELPER
-- ══════════════════════════════════════
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("Humanoid")
end
local function getTargetPosition()
    if ballFollowActive and ball and ball.Parent then return ball.Position end
    local hrp = getHRP(); return hrp and hrp.Position
end

-- ══════════════════════════════════════
--   BALL FOLLOW
-- ══════════════════════════════════════
local function spawnBall()
    if ball then ball:Destroy() end
    local hrp = getHRP(); if not hrp then return end
    ball             = Instance.new("Part")
    ball.Shape       = Enum.PartType.Ball
    ball.Size        = Vector3.new(2,2,2)
    ball.Material    = Enum.Material.Neon
    ball.Color       = Color3.fromRGB(255,255,255)
    ball.Anchored    = false
    ball.CanCollide  = false
    ball.Position    = hrp.Position + Vector3.new(0,3,0)
    ball.Parent      = workspace
    local att = Instance.new("Attachment", ball)
    local lv  = Instance.new("LinearVelocity", ball)
    lv.Attachment0    = att
    lv.MaxForce       = 1e9
    lv.VectorVelocity = Vector3.zero
    lv.RelativeTo     = Enum.ActuatorRelativeTo.World
end
local function destroyBall()
    if ball then ball:Destroy() end; ball = nil
end

-- ══════════════════════════════════════
--   GUI ROOT
-- ══════════════════════════════════════
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name           = "TentOrbitGuiV5"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ── Panel utama ───────────────────────
local panel = Instance.new("Frame", gui)
panel.Size             = UDim2.new(0, PANEL_W, 0, PANEL_H_FULL)
panel.Position         = UDim2.new(0.5, -PANEL_W/2, 0.5, -130)
panel.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
panel.BorderSizePixel  = 0
panel.ZIndex           = 10
panel.ClipsDescendants = true
local pc = Instance.new("UICorner", panel); pc.CornerRadius = UDim.new(0,10)
local ps = Instance.new("UIStroke", panel); ps.Color = Color3.fromRGB(90,60,200); ps.Thickness = 1.4

-- ── Header ────────────────────────────
local header = Instance.new("TextButton", panel)
header.Size             = UDim2.new(1, 0, 0, 26)
header.BackgroundColor3 = Color3.fromRGB(28, 20, 55)
header.Text             = "  ▼  Tent Orbit v5  |  BmSky"
header.TextColor3       = Color3.fromRGB(200, 180, 255)
header.Font             = Enum.Font.GothamBold
header.TextSize         = 11
header.TextXAlignment   = Enum.TextXAlignment.Left
header.AutoButtonColor  = false
header.ZIndex           = 12
local hc = Instance.new("UICorner", header); hc.CornerRadius = UDim.new(0,10)

-- Drag
local dragging, dragStart, startPos2, isDragging = false, nil, nil, false
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = false; dragging = true; dragStart = i.Position; startPos2 = panel.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        if d.Magnitude > 4 then isDragging = true end
        panel.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset+d.X, startPos2.Y.Scale, startPos2.Y.Offset+d.Y)
    end
end)

-- Minimize toggle
header.MouseButton1Click:Connect(function()
    if isDragging then isDragging=false; return end
    isMinimized = not isMinimized
    local h = isMinimized and PANEL_H_MIN or PANEL_H_FULL
    header.Text = string.format("  %s  Tent Orbit v5  |  BmSky", isMinimized and "▶" or "▼")
    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, PANEL_W, 0, h) }):Play()
end)

-- ── Helper buat widget ────────────────
local function makeBtn(text, x, y, w, h, parent)
    local b = Instance.new("TextButton", parent or panel)
    b.Size             = UDim2.new(0, w or 64, 0, h or 24)
    b.Position         = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(38, 36, 58)
    b.Text             = text
    b.TextColor3       = Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end
local function makeLbl(text, x, y, w, h, fs, col, parent)
    local l = Instance.new("TextLabel", parent or panel)
    l.Size = UDim2.new(0, w or PANEL_W-16, 0, h or 14)
    l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = col or Color3.fromRGB(180,180,200)
    l.Font = Enum.Font.Gotham
    l.TextSize = fs or 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

-- ── Status ────────────────────────────
local lblStatus = makeLbl("Status: idle", 8, 30, PANEL_W-16, 14, 10, Color3.fromRGB(140,220,160))

-- ── Tombol LIST ACTION ────────────────
local btnListAction = makeBtn("☰  List Action", 8, 48, PANEL_W-16, 26)
btnListAction.TextSize = 12
btnListAction.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
local bls = Instance.new("UIStroke", btnListAction); bls.Color = Color3.fromRGB(120,80,220); bls.Thickness=1

-- ── Separator ────────────────────────
local sep1 = Instance.new("Frame", panel)
sep1.Size = UDim2.new(1,-16,0,1); sep1.Position = UDim2.new(0,8,0,80)
sep1.BackgroundColor3 = Color3.fromRGB(60,50,90); sep1.BorderSizePixel=0

-- ── Slider helper ─────────────────────
local function createSlider(lbl, minV, maxV, initV, yPos, cb)
    local row = Instance.new("Frame", panel)
    row.Size = UDim2.new(1,-16,0,20); row.Position = UDim2.new(0,8,0,yPos)
    row.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", row)
    label.Size=UDim2.new(0,54,0,14); label.Position=UDim2.new(0,0,0,3)
    label.BackgroundTransparency=1; label.Text=lbl
    label.TextColor3=Color3.fromRGB(200,200,210); label.Font=Enum.Font.Gotham
    label.TextSize=10; label.TextXAlignment=Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size=UDim2.new(1,-90,0,8); track.Position=UDim2.new(0,58,0,6)
    track.BackgroundColor3=Color3.fromRGB(50,48,70); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,4)

    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(110,70,220)
    fill.BorderSizePixel=0; Instance.new("UICorner",fill).CornerRadius=UDim.new(0,4)

    local knob = Instance.new("TextButton", track)
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,-8,0.5,-8)
    knob.BackgroundColor3=Color3.fromRGB(190,170,255); knob.Text=""
    knob.AutoButtonColor=false; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size=UDim2.new(0,28,0,14); valLbl.Position=UDim2.new(1,-28,0,3)
    valLbl.BackgroundTransparency=1; valLbl.TextColor3=Color3.fromRGB(255,255,255)
    valLbl.Font=Enum.Font.Gotham; valLbl.TextSize=10
    valLbl.TextXAlignment=Enum.TextXAlignment.Right

    local value = initV
    local function updateUI()
        local frac = (value-minV)/(maxV-minV)
        local kx   = frac*(track.AbsoluteSize.X - knob.AbsoluteSize.X)
        knob.Position = UDim2.new(0, kx, 0.5, -knob.AbsoluteSize.Y/2)
        fill.Size     = UDim2.new(frac,0,1,0)
        valLbl.Text   = string.format("%.1f", value)
    end
    local function setValue(v)
        value = math.clamp(v, minV, maxV); updateUI(); cb(value)
    end
    local function posToVal(px)
        local bMin = track.AbsolutePosition.X + knob.AbsoluteSize.X/2
        local bMax = track.AbsolutePosition.X + track.AbsoluteSize.X - knob.AbsoluteSize.X/2
        setValue(minV + math.clamp((px-bMin)/(bMax-bMin),0,1)*(maxV-minV))
    end
    knob.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then posToVal(i.Position.X) end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then posToVal(i.Position.X) end
    end)
    setValue(initV)
    return { SetValue=setValue, GetValue=function() return value end }
end

-- Sliders
local sep2 = Instance.new("Frame", panel)
sep2.Size=UDim2.new(1,-16,0,1); sep2.Position=UDim2.new(0,8,0,84)
sep2.BackgroundColor3=Color3.fromRGB(60,50,90); sep2.BorderSizePixel=0

makeLbl("─ Settings ─", 8, 86, PANEL_W-16, 12, 9, Color3.fromRGB(100,80,160))

local radiusSlider = createSlider("Radius", 2, 20, ORBIT_RADIUS, 100, function(v) ORBIT_RADIUS = v end)
local speedSlider  = createSlider("Speed",  0.1, 5, ORBIT_SPEED,  124, function(v) ORBIT_SPEED  = v end)
local heightSlider = createSlider("Height", -10, 40, HEIGHT_OFFSET, 148, function(v) HEIGHT_OFFSET = v end)

-- ── Ball Follow + Naik/Turun ──────────
local sep3 = Instance.new("Frame", panel)
sep3.Size=UDim2.new(1,-16,0,1); sep3.Position=UDim2.new(0,8,0,176)
sep3.BackgroundColor3=Color3.fromRGB(60,50,90); sep3.BorderSizePixel=0

local btnBallFollow = makeBtn("● Ball Follow: OFF", 8, 182, PANEL_W-16, 24)
btnBallFollow.BackgroundColor3 = Color3.fromRGB(38,36,58)

local btnUp   = makeBtn("▲ Naik",  8,   210, (PANEL_W-20)/2, 22)
local btnDown = makeBtn("▼ Turun", 10+(PANEL_W-20)/2, 210, (PANEL_W-20)/2, 22)
btnUp.BackgroundColor3   = Color3.fromRGB(20,110,40)
btnDown.BackgroundColor3 = Color3.fromRGB(120,30,30)
btnUp.Visible   = false
btnDown.Visible = false

-- ══════════════════════════════════════
--   LIST ACTION POPUP (kanan panel, kecil, scrollable)
-- ══════════════════════════════════════
local MODES = {
    { id="orbit",     label="⊙ Orbit",      color=Color3.fromRGB(80,50,180)  },
    { id="follow",    label="➤ Follow",      color=Color3.fromRGB(50,90,180)  },
    { id="leftright", label="↔ L-Right",     color=Color3.fromRGB(50,140,180) },
    { id="love",      label="♥ Love",        color=Color3.fromRGB(200,40,100) },
    { id="road",      label="▤ Road",        color=Color3.fromRGB(60,130,60)  },
    { id="dna",       label="⬡ DNA",         color=Color3.fromRGB(0,160,160)  },
    { id="snake",     label="~ Snake",       color=Color3.fromRGB(30,180,80)  },
    { id="tornado",   label="@ Tornado",     color=Color3.fromRGB(100,100,200)},
}

-- ukuran panel list (compact, tetap di kanan)
local LIST_W      = 100   -- lebar panel list kecil
local LIST_BTN_H  = 26    -- tinggi tiap tombol
local LIST_GAP    = 3
local LIST_VIS    = 5     -- maksimal tombol terlihat sekaligus (sisanya scroll)
local LIST_INNER_H = #MODES * (LIST_BTN_H + LIST_GAP)  -- tinggi isi scroll
local LIST_SHOWN_H = math.min(LIST_VIS, #MODES) * (LIST_BTN_H + LIST_GAP)  -- tinggi visible area
local LIST_TOTAL_H = LIST_SHOWN_H + 22  -- +22 untuk header

-- Frame luar (container, clips)
local listFrame = Instance.new("Frame", gui)
listFrame.Size             = UDim2.new(0, LIST_W, 0, LIST_TOTAL_H)
listFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 26)
listFrame.BorderSizePixel  = 0
listFrame.ZIndex           = 20
listFrame.Visible          = false
listFrame.ClipsDescendants = true
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
local lfs = Instance.new("UIStroke", listFrame)
lfs.Color = Color3.fromRGB(100, 70, 200); lfs.Thickness = 1.2

-- Header list
local listHeader = Instance.new("TextLabel", listFrame)
listHeader.Size             = UDim2.new(1, 0, 0, 20)
listHeader.Position         = UDim2.new(0, 0, 0, 0)
listHeader.BackgroundColor3 = Color3.fromRGB(28, 18, 52)
listHeader.BorderSizePixel  = 0
listHeader.Text             = " Mode"
listHeader.TextColor3       = Color3.fromRGB(160, 130, 255)
listHeader.Font             = Enum.Font.GothamBold
listHeader.TextSize         = 10
listHeader.TextXAlignment   = Enum.TextXAlignment.Left
listHeader.ZIndex           = 21
Instance.new("UICorner", listHeader).CornerRadius = UDim.new(0, 8)

-- ScrollingFrame untuk tombol-tombol
local scrollArea = Instance.new("ScrollingFrame", listFrame)
scrollArea.Size                  = UDim2.new(1, 0, 1, -20)
scrollArea.Position              = UDim2.new(0, 0, 0, 20)
scrollArea.BackgroundTransparency = 1
scrollArea.BorderSizePixel       = 0
scrollArea.ScrollBarThickness    = 3
scrollArea.ScrollBarImageColor3  = Color3.fromRGB(100, 70, 200)
scrollArea.CanvasSize            = UDim2.new(0, 0, 0, LIST_INNER_H + 4)
scrollArea.ZIndex                = 21
scrollArea.ClipsDescendants      = true

-- Tombol-tombol mode di dalam scroll
local modeBtns = {}
for idx, m in ipairs(MODES) do
    local yy = (idx-1) * (LIST_BTN_H + LIST_GAP) + 2
    local mb  = Instance.new("TextButton", scrollArea)
    mb.Size             = UDim2.new(1, -8, 0, LIST_BTN_H)
    mb.Position         = UDim2.new(0, 4, 0, yy)
    mb.BackgroundColor3 = m.color
    mb.Text             = m.label
    mb.TextColor3       = Color3.new(1, 1, 1)
    mb.Font             = Enum.Font.GothamBold
    mb.TextSize         = 11
    mb.AutoButtonColor  = false
    mb.ZIndex           = 22
    mb.TextTruncate     = Enum.TextTruncate.AtEnd
    Instance.new("UICorner", mb).CornerRadius = UDim.new(0, 5)
    modeBtns[m.id] = mb
end

-- Posisi: tepat di kanan panel utama, sejajar dengan tombol List Action
local function positionList()
    local pp = panel.AbsolutePosition
    local ps = panel.AbsoluteSize
    local bp = btnListAction.AbsolutePosition
    -- X: sebelah kanan panel + gap 5px
    local lx = pp.X + ps.X + 5
    -- Y: sejajar tombol List Action, clamp supaya tidak keluar layar
    local ly = bp.Y
    local screenH = workspace.CurrentCamera.ViewportSize.Y
    ly = math.clamp(ly, 4, screenH - LIST_TOTAL_H - 4)
    listFrame.Position = UDim2.new(0, lx, 0, ly)
end

local function openList()
    listOpen = true
    positionList()
    -- animasi expand dari kiri (lebar 0 → LIST_W)
    listFrame.Size    = UDim2.new(0, 0, 0, LIST_TOTAL_H)
    listFrame.Visible = true
    TweenService:Create(listFrame,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, LIST_W, 0, LIST_TOTAL_H) }
    ):Play()
    btnListAction.BackgroundColor3 = Color3.fromRGB(90, 60, 160)
end

local function closeList()
    listOpen = false
    TweenService:Create(listFrame,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 0, 0, LIST_TOTAL_H) }
    ):Play()
    task.delay(0.13, function() if not listOpen then listFrame.Visible = false end end)
    btnListAction.BackgroundColor3 = Color3.fromRGB(60, 40, 110)
end

btnListAction.MouseButton1Click:Connect(function()
    if listOpen then closeList() else openList() end
end)

-- Update posisi list saat panel di-drag
RunService.RenderStepped:Connect(function()
    if listOpen and listFrame.Visible then positionList() end
end)

-- ══════════════════════════════════════
--   BUTTON STATES (highlight aktif)
-- ══════════════════════════════════════
local function setButtonStates()
    for _, m in ipairs(MODES) do
        local mb = modeBtns[m.id]
        if mb then
            if currentMode == m.id then
                mb.BackgroundColor3 = Color3.fromRGB(
                    math.min(m.color.R*255+60,255)/255,
                    math.min(m.color.G*255+60,255)/255,
                    math.min(m.color.B*255+60,255)/255
                )
                Instance.new("UIStroke", mb).Color = Color3.fromRGB(255,255,255)
            else
                mb.BackgroundColor3 = m.color
                local s = mb:FindFirstChildWhichIsA("UIStroke")
                if s then s:Destroy() end
            end
        end
    end
    btnBallFollow.BackgroundColor3 = ballFollowActive
        and Color3.fromRGB(20,150,60) or Color3.fromRGB(38,36,58)
    btnBallFollow.Text = (ballFollowActive and "● Ball Follow: ON" or "● Ball Follow: OFF")
    btnUp.Visible   = ballFollowActive
    btnDown.Visible = ballFollowActive

    PANEL_H_FULL = ballFollowActive and 240 or 240
    if not isMinimized then
        TweenService:Create(panel, TweenInfo.new(0.1),
            { Size = UDim2.new(0, PANEL_W, 0, PANEL_H_FULL) }):Play()
    end

    -- Update label di List Action button
    if currentMode ~= "none" then
        btnListAction.Text = "☰  " .. currentMode:upper() .. " aktif"
    else
        btnListAction.Text = "☰  List Action"
    end
end
setButtonStates()

-- ══════════════════════════════════════
--   TENT SPAWN & DETECT
-- ══════════════════════════════════════
local function getExistingTents()
    local out = {}
    for _, c in ipairs(trafficCones:GetChildren()) do
        if c.Name == "Prop"..PLAYER_NAME and c:IsA("Model") then
            table.insert(out, c)
        end
    end
    return out
end

local function spawnAutoTent()
    pcall(function()
        ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("RequestingPropName","BigTeePee","Big","Home")
    end)
    task.wait(0.5)
    local before = {}
    for _, f in ipairs(trafficCones:GetChildren()) do
        if f.Name=="Prop"..PLAYER_NAME then before[f]=true end
    end
    local nf = nil
    for _ = 1, 30 do
        for _, c in ipairs(trafficCones:GetChildren()) do
            if c.Name=="Prop"..PLAYER_NAME and not before[c] then nf=c; break end
        end
        if nf then break end
        task.wait(0.1)
    end
    if not nf then warn("[TentOrbit] Folder tenda tidak muncul"); return nil end
    local part = nf:FindFirstChild("Part") or nf:FindFirstChild("Wedge") or nf:FindFirstChildWhichIsA("BasePart")
    if not part then warn("[TentOrbit] Part tidak ditemukan"); return nil end
    local tp = getTargetPosition()
    if tp then
        local a = math.random()*math.pi*2
        pcall(function() workspace[PLAYER_NAME].PropMaker.Tool_PropMake:FireServer(part) end)
        task.wait(0.2)
        pcall(function()
            nf.SetCurrentCFrame:InvokeServer(CFrame.new(
                tp.X + math.cos(a)*ORBIT_RADIUS,
                tp.Y + HEIGHT_OFFSET,
                tp.Z + math.sin(a)*ORBIT_RADIUS
            ))
        end)
        task.wait(0.2)
    end
    return nf
end

local function refreshTents(needed)
    tentFolders = getExistingTents()
    if #tentFolders == 0 then return false end
    local target = needed or TOTAL_TENTS
    while #tentFolders < target do
        local nt = spawnAutoTent()
        if nt then table.insert(tentFolders, nt)
        else lblStatus.Text="Gagal spawn tenda ke-"..(#tentFolders+1); break end
        task.wait(0.5)
    end
    return true
end

-- ══════════════════════════════════════
--   SET CFRAME HELPER
-- ══════════════════════════════════════
local function setCF(folder, cf)
    if folder and folder.Parent then
        pcall(function() folder.SetCurrentCFrame:InvokeServer(cf) end)
        return true
    end
    return false
end

-- ══════════════════════════════════════
--   MODE UPDATE FUNCTIONS
-- ══════════════════════════════════════

-- ORBIT
local function updateOrbit(dt)
    orbitAngle = (orbitAngle + ORBIT_SPEED * dt) % (math.pi*2)
    local tp = getTargetPosition(); if not tp then return end
    for i = #tentFolders, 1, -1 do
        local f = tentFolders[i]
        local angle = orbitAngle + (i-1)*(math.pi*2/#tentFolders)
        if not setCF(f, CFrame.new(tp.X+math.cos(angle)*ORBIT_RADIUS, tp.Y+HEIGHT_OFFSET, tp.Z+math.sin(angle)*ORBIT_RADIUS)) then
            table.remove(tentFolders,i)
        end
    end
end

-- FOLLOW
local function updateFollow(dt)
    local hrp = getHRP(); local tp = getTargetPosition()
    if not hrp or not tp then return end
    local look = hrp.CFrame.LookVector
    local base = tp + look*(-4)
    for i = #tentFolders, 1, -1 do
        local off = (i-1)*3
        if not setCF(tentFolders[i], CFrame.new(base.X+look.X*(-off), base.Y+HEIGHT_OFFSET, base.Z+look.Z*(-off))) then
            table.remove(tentFolders,i)
        end
    end
end

-- LEFT-RIGHT
local function updateLeftRight(dt)
    local hrp = getHRP(); local tp = getTargetPosition()
    if not hrp or not tp then return end
    local t = os.clock()*0.8
    local bCF = hrp.CFrame
    local base = CFrame.new(tp)*(bCF - bCF.Position)*CFrame.new(0,0,-4)
    for i = #tentFolders, 1, -1 do
        local ox = 10*math.sin(t+(i%2==0 and 0 or math.pi))
        if not setCF(tentFolders[i], base*CFrame.new(ox, HEIGHT_OFFSET, 0)) then
            table.remove(tentFolders,i)
        end
    end
end

-- LOVE (hati bergerak, parametric heart curve)
local loveAngle = 0
local function updateLove(dt)
    loveAngle = (loveAngle + ORBIT_SPEED*0.6*dt) % (math.pi*2)
    local tp = getTargetPosition(); if not tp then return end
    local n = #tentFolders
    for i = #tentFolders, 1, -1 do
        -- parametric: x=16sin³t, y=13cos t−5cos2t−2cos3t−cos4t
        local t2 = loveAngle + (i-1)*(math.pi*2/n)
        local hx = 16*(math.sin(t2))^3 * (ORBIT_RADIUS*0.35)
        local hy = (13*math.cos(t2) - 5*math.cos(2*t2) - 2*math.cos(3*t2) - math.cos(4*t2)) * (ORBIT_RADIUS*0.27)
        if not setCF(tentFolders[i], CFrame.new(tp.X+hx, tp.Y+HEIGHT_OFFSET, tp.Z+hy)) then
            table.remove(tentFolders,i)
        end
    end
end

-- ROAD (dua baris di kiri kanan, bergerak ke depan)
local roadOffset = 0
local function updateRoad(dt)
    roadOffset = roadOffset + ORBIT_SPEED*8*dt
    local hrp = getHRP(); local tp = getTargetPosition()
    if not hrp or not tp then return end
    local look  = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local n     = #tentFolders
    local half  = math.floor(n/2)
    for i = #tentFolders, 1, -1 do
        local side    = (i <= half) and 1 or -1
        local row     = i <= half and i or (i - half)
        local fwdOff  = (row - 1)*4 - roadOffset%4
        local sideOff = side * ORBIT_RADIUS * 0.7
        local pos = tp + look*fwdOff + right*sideOff
        if not setCF(tentFolders[i], CFrame.new(pos.X, tp.Y+HEIGHT_OFFSET, pos.Z)) then
            table.remove(tentFolders,i)
        end
    end
end

-- DNA (double helix spiral)
local dnaAngle = 0
local function updateDNA(dt)
    dnaAngle = (dnaAngle + ORBIT_SPEED*dt) % (math.pi*2)
    local hrp = getHRP(); local tp = getTargetPosition()
    if not hrp or not tp then return end
    local look  = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local n     = #tentFolders
    for i = #tentFolders, 1, -1 do
        local t2     = dnaAngle + (i-1)*(math.pi*2/math.max(n,1))
        local strand  = (i % 2 == 0) and 1 or -1          -- dua untai
        local fwdOff  = (i - n/2)*2.5
        local sideOff = strand * math.cos(t2) * ORBIT_RADIUS
        local upOff   = math.sin(t2) * ORBIT_RADIUS * 0.5
        local pos = tp + look*fwdOff + right*sideOff
        if not setCF(tentFolders[i], CFrame.new(pos.X, tp.Y+HEIGHT_OFFSET+upOff, pos.Z)) then
            table.remove(tentFolders,i)
        end
    end
end

-- SNAKE (ular zig-zag ngikut belakang player)
local snakeTime = 0
local function updateSnake(dt)
    snakeTime = snakeTime + dt
    local hrp = getHRP(); local tp = getTargetPosition()
    if not hrp or not tp then return end
    local look  = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local n     = #tentFolders
    for i = #tentFolders, 1, -1 do
        local fwdOff  = -(i * 2.5)
        local zigzag  = math.sin(snakeTime * ORBIT_SPEED*2 + i*0.9) * ORBIT_RADIUS * 0.6
        local pos = tp + look*fwdOff + right*zigzag
        if not setCF(tentFolders[i], CFrame.new(pos.X, tp.Y+HEIGHT_OFFSET, pos.Z)) then
            table.remove(tentFolders,i)
        end
    end
end

-- TORNADO (spiral naik berputar)
local tornadoAngle = 0
local function updateTornado(dt)
    tornadoAngle = (tornadoAngle + ORBIT_SPEED*1.5*dt) % (math.pi*2)
    local tp = getTargetPosition(); if not tp then return end
    local n  = #tentFolders
    for i = #tentFolders, 1, -1 do
        local frac    = (i-1)/(math.max(n-1,1))           -- 0..1 dari bawah ke atas
        local angle   = tornadoAngle + (i-1)*(math.pi*2/math.max(n,1))
        local radius  = ORBIT_RADIUS * (1 - frac*0.85)    -- makin kecil ke atas
        local height  = frac * ORBIT_RADIUS * 1.5
        local x = tp.X + math.cos(angle)*radius
        local z = tp.Z + math.sin(angle)*radius
        if not setCF(tentFolders[i], CFrame.new(x, tp.Y+HEIGHT_OFFSET+height, z)) then
            table.remove(tentFolders,i)
        end
    end
end

-- ══════════════════════════════════════
--   MAIN LOOP
-- ══════════════════════════════════════
local modeUpdateFn = {
    orbit     = updateOrbit,
    follow    = updateFollow,
    leftright = updateLeftRight,
    love      = updateLove,
    road      = updateRoad,
    dna       = updateDNA,
    snake     = updateSnake,
    tornado   = updateTornado,
}

local function startLoop()
    if orbitConnection then return end
    orbitConnection = RunService.Heartbeat:Connect(function(dt)
        local fn = modeUpdateFn[currentMode]
        if fn then fn(dt) end
    end)
end

local function stopLoop()
    if orbitConnection then orbitConnection:Disconnect(); orbitConnection = nil end
end

-- jumlah tenda tiap mode
local modeTentCount = {
    orbit=2, follow=2, leftright=2,
    love=8, road=6, dna=6, snake=8, tornado=8
}

local function setMode(newMode)
    closeList()
    if currentMode == newMode then
        currentMode = "none"; stopLoop(); tentFolders = {}
        lblStatus.Text = "Status: idle"; setButtonStates(); return
    end
    stopLoop(); tentFolders = {}
    currentMode = newMode
    TOTAL_TENTS = modeTentCount[newMode] or 2
    local ok = refreshTents(TOTAL_TENTS)
    if not ok then
        lblStatus.Text = "Letakkan minimal 1 tenda dulu!"
        currentMode = "none"; setButtonStates(); return
    end
    local target = ballFollowActive and "bola" or "player"
    lblStatus.Text = string.format("%s aktif – %d tenda → %s", newMode, #tentFolders, target)
    startLoop(); setButtonStates()
end

-- Hubungkan semua tombol mode di popup
for _, m in ipairs(MODES) do
    local mb = modeBtns[m.id]
    if mb then
        mb.MouseButton1Click:Connect(function() setMode(m.id) end)
    end
end

-- ══════════════════════════════════════
--   BALL FOLLOW
-- ══════════════════════════════════════
local ballLoopConn = nil

local function startBallLoop()
    if ballLoopConn then return end
    ballLoopConn = RunService.RenderStepped:Connect(function()
        if ballFollowActive and ball and ball:FindFirstChild("LinearVelocity") then
            local hum = getHumanoid()
            local md  = hum and hum.MoveDirection or Vector3.zero
            local fin = Vector3.new(md.X, verticalMove, md.Z)
            ball.LinearVelocity.VectorVelocity = fin.Magnitude>0 and fin.Unit*ballSpeed or Vector3.zero
        end
    end)
end
local function stopBallLoop()
    if ballLoopConn then ballLoopConn:Disconnect(); ballLoopConn=nil end
end
local function restartMode()
    if currentMode ~= "none" then
        local saved = currentMode
        stopLoop(); tentFolders = {}
        currentMode = saved
        TOTAL_TENTS = modeTentCount[saved] or 2
        if refreshTents(TOTAL_TENTS) then startLoop() end
        local tgt = ballFollowActive and "bola" or "player"
        lblStatus.Text = string.format("%s aktif → %s", currentMode, tgt)
        setButtonStates()
    end
end

btnBallFollow.MouseButton1Click:Connect(function()
    ballFollowActive = not ballFollowActive
    local hum = getHumanoid()
    if ballFollowActive then
        spawnBall()
        Camera.CameraSubject = ball
        if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        startBallLoop()
    else
        stopBallLoop(); destroyBall()
        Camera.CameraSubject = hum
        if hum then hum.WalkSpeed=16; hum.JumpPower=50 end
        verticalMove = 0
    end
    setButtonStates(); restartMode()
end)

btnUp.MouseButton1Down:Connect(function()   verticalMove =  1 end)
btnUp.MouseButton1Up:Connect(function()     verticalMove =  0 end)
btnDown.MouseButton1Down:Connect(function() verticalMove = -1 end)
btnDown.MouseButton1Up:Connect(function()   verticalMove =  0 end)

-- ══════════════════════════════════════
--   RESPAWN
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    stopLoop(); stopBallLoop(); destroyBall()
    ballFollowActive = false; currentMode = "none"
    tentFolders = {}; verticalMove = 0
    task.wait(1)
    Camera.CameraSubject = newChar:WaitForChild("Humanoid")
    lblStatus.Text = "Status: respawned"
    setButtonStates()
end)

print("[OK] Tent Orbit v5 loaded –", PLAYER_NAME)
