-- ══════════════════════════════════════
--   Tent Orbit v6.3 | by BmSky
--   + Input Sign ID di panel Bahlil
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
local HEIGHT_OFFSET   = 0.025
local PLAYER_NAME     = LocalPlayer.Name

-- Ball Follow
local ballFollowActive = false
local ball             = nil
local ballSpeed        = 60
local verticalMove     = 0

-- Minimize
local isMinimized  = false
local PANEL_W      = 230
local PANEL_H_FULL = 244
local PANEL_H_MIN  = 26

-- List Action popup
local listOpen = false

-- Bahlil state
local bahlilActive     = false
local bahlilIndex      = 1
local bahlilTexts      = {}
local bahlilDefault    = {
    "🗑️MBG🗑️", "🙈MAS🙈", "😎BAHLIL 😎", "🔥GANTENG🔥",
    "BUAH APA YANG PALING MANIS?🤔", "🔥BUAHLIL!!!!🔥",
    "TAMBAH ", "🤓GANTENG AJA🤓", "😎MY LITTLE BOLU KETAN😎"
}
local bahlilPanelOpen  = false
local bahlilSignID     = "21"    -- ⬅️ UBAH ID DI PANEL, BUKAN DI SINI
local bahlilInputRows  = {}
local bahlilHistSelIdx = 1

-- ── Another Player state ─────────────
local targetPlayer      = nil
local apPanelOpen       = false
local apActionOpen      = false

-- Auto RGB state
local autoRGBActive  = false
local autoRGBConn    = nil
local autoRGBHue     = 0   -- 0..1, berputar

-- Forward declarations
local restartMode, stopLoop, startLoop, closeApPanel, setButtonStates, stopAutoRGB
local isSpektating = false
local stopSpektator

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
    if targetPlayer and targetPlayer.Parent then
        local char = targetPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end
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
gui.Name           = "TentOrbitGuiV6"
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
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(90,60,200); panelStroke.Thickness = 1.4

-- ── Header ────────────────────────────
local header = Instance.new("TextButton", panel)
header.Size             = UDim2.new(1, 0, 0, 26)
header.BackgroundColor3 = Color3.fromRGB(28, 20, 55)
header.Text = "  ▼  Tent Orbit v6.3  |  BmSky"
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
    header.Text = string.format("  %s  Tent Orbit v6.3  |  BmSky", isMinimized and "▶" or "▼")
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

local btnAnotherPlayer = makeBtn("👤 Another Player", 8, 210, PANEL_W-16, 24)
btnAnotherPlayer.BackgroundColor3 = Color3.fromRGB(30, 60, 120)
local apStroke = Instance.new("UIStroke", btnAnotherPlayer)
apStroke.Color = Color3.fromRGB(60,130,220); apStroke.Thickness = 1

-- ── Tombol AUTO RGB ───────────────────
local btnAutoRGB = makeBtn("🌈 Auto RGB: OFF", 8, 238, PANEL_W-16, 24)
btnAutoRGB.BackgroundColor3 = Color3.fromRGB(35, 30, 60)
local argbStroke = Instance.new("UIStroke", btnAutoRGB)
argbStroke.Color = Color3.fromRGB(150, 60, 220); argbStroke.Thickness = 1

-- ── Tombol Naik/Turun FLOATING ────────────
local BTN_CORNER_W = 52
local BTN_CORNER_H = 36
local BTN_CORNER_MARGIN = 12

local floatBtnUp = Instance.new("TextButton", gui)
floatBtnUp.Size             = UDim2.new(0, BTN_CORNER_W, 0, BTN_CORNER_H)
floatBtnUp.Position         = UDim2.new(1, -(BTN_CORNER_W + BTN_CORNER_MARGIN), 1, -(BTN_CORNER_H*2 + BTN_CORNER_MARGIN + 6))
floatBtnUp.BackgroundColor3 = Color3.fromRGB(20, 110, 40)
floatBtnUp.Text             = "+"
floatBtnUp.TextColor3       = Color3.new(1,1,1)
floatBtnUp.Font             = Enum.Font.GothamBold
floatBtnUp.TextSize         = 22
floatBtnUp.AutoButtonColor  = false
floatBtnUp.ZIndex           = 50
floatBtnUp.Visible          = false
Instance.new("UICorner", floatBtnUp).CornerRadius = UDim.new(0, 8)
local fuStroke = Instance.new("UIStroke", floatBtnUp)
fuStroke.Color = Color3.fromRGB(40,200,80); fuStroke.Thickness = 1.5

local floatBtnDown = Instance.new("TextButton", gui)
floatBtnDown.Size             = UDim2.new(0, BTN_CORNER_W, 0, BTN_CORNER_H)
floatBtnDown.Position         = UDim2.new(1, -(BTN_CORNER_W + BTN_CORNER_MARGIN), 1, -(BTN_CORNER_H + BTN_CORNER_MARGIN))
floatBtnDown.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
floatBtnDown.Text             = "−"
floatBtnDown.TextColor3       = Color3.new(1,1,1)
floatBtnDown.Font             = Enum.Font.GothamBold
floatBtnDown.TextSize         = 22
floatBtnDown.AutoButtonColor  = false
floatBtnDown.ZIndex           = 50
floatBtnDown.Visible          = false
Instance.new("UICorner", floatBtnDown).CornerRadius = UDim.new(0, 8)
local fdStroke = Instance.new("UIStroke", floatBtnDown)
fdStroke.Color = Color3.fromRGB(200,60,60); fdStroke.Thickness = 1.5

local btnUp   = floatBtnUp
local btnDown = floatBtnDown

-- ══════════════════════════════════════
--   LIST ACTION POPUP
-- ══════════════════════════════════════
local MODES = {
    { id="orbit",     label="⊙ Orbit",      color=Color3.fromRGB(80,50,180)   },
    { id="leftright", label="↔ L-Right",     color=Color3.fromRGB(50,140,180)  },
    { id="love",      label="♥ Love",        color=Color3.fromRGB(200,40,100)  },
    { id="tornado",   label="@ Tornado",     color=Color3.fromRGB(100,100,200) },
    { id="ekor",      label="🐍 Ekor",        color=Color3.fromRGB(60,160,80)   },
    { id="games",     label="🎮 Games",       color=Color3.fromRGB(200,140,20)  },
    { id="wings",     label="🦋 Wings",       color=Color3.fromRGB(80,180,220)  },
    { id="mahkota",   label="👑 Mahkota",     color=Color3.fromRGB(220,180,20)  },
    { id="bodyside",  label="⬛ Body Side",   color=Color3.fromRGB(140,80,200)  },
    { id="bahlil",    label="😎 Bahlil",      color=Color3.fromRGB(200,100,0), special=true },
}

local LIST_W       = 100
local LIST_BTN_H   = 26
local LIST_GAP     = 3
local LIST_VIS     = 6
local LIST_INNER_H = #MODES * (LIST_BTN_H + LIST_GAP)
local LIST_SHOWN_H = math.min(LIST_VIS, #MODES) * (LIST_BTN_H + LIST_GAP)
local LIST_TOTAL_H = LIST_SHOWN_H + 22

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

local function positionList()
    local pp  = panel.AbsolutePosition
    local ps2 = panel.AbsoluteSize
    local bp  = btnListAction.AbsolutePosition
    local lx  = pp.X + ps2.X + 5
    local ly  = bp.Y
    local screenH = workspace.CurrentCamera.ViewportSize.Y
    ly = math.clamp(ly, 4, screenH - LIST_TOTAL_H - 4)
    listFrame.Position = UDim2.new(0, lx, 0, ly)
end

local function openList()
    listOpen = true
    positionList()
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

RunService.RenderStepped:Connect(function()
    if listOpen and listFrame.Visible then positionList() end
end)

-- ══════════════════════════════════════
--   BUTTON STATES
-- ══════════════════════════════════════
setButtonStates = function()
    for _, m in ipairs(MODES) do
        local mb = modeBtns[m.id]
        if mb then
            local isActive = (currentMode == m.id) or (m.id == "bahlil" and bahlilActive)
            if isActive then
                mb.BackgroundColor3 = Color3.fromRGB(
                    math.min(m.color.R*255+60, 255)/255,
                    math.min(m.color.G*255+60, 255)/255,
                    math.min(m.color.B*255+60, 255)/255
                )
                local s = mb:FindFirstChildWhichIsA("UIStroke")
                if not s then s = Instance.new("UIStroke", mb) end
                s.Color = Color3.fromRGB(255,255,255)
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
    floatBtnUp.Visible   = ballFollowActive
    floatBtnDown.Visible = ballFollowActive
    if targetPlayer and targetPlayer.Parent then
        btnAnotherPlayer.BackgroundColor3 = Color3.fromRGB(20,80,180)
        btnAnotherPlayer.Text = "👤 " .. targetPlayer.Name
    else
        btnAnotherPlayer.BackgroundColor3 = Color3.fromRGB(30,60,120)
        btnAnotherPlayer.Text = "👤 Another Player"
    end

    PANEL_H_FULL = 270
    if not isMinimized then
        TweenService:Create(panel, TweenInfo.new(0.1),
            { Size = UDim2.new(0, PANEL_W, 0, PANEL_H_FULL) }):Play()
    end

    btnAutoRGB.BackgroundColor3 = autoRGBActive
        and Color3.fromRGB(120,20,180) or Color3.fromRGB(35,30,60)
    btnAutoRGB.Text = autoRGBActive and "🌈 Auto RGB: ON" or "🌈 Auto RGB: OFF"
    argbStroke.Color = autoRGBActive
        and Color3.fromRGB(255,100,255) or Color3.fromRGB(150,60,220)

    if currentMode ~= "none" then
        btnListAction.Text = "☰  " .. currentMode:upper() .. " aktif"
    elseif bahlilActive then
        btnListAction.Text = "☰  BAHLIL aktif 😎"
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

-- LOVE (parametric heart curve)
local loveAngle = 0
local function updateLove(dt)
    loveAngle = (loveAngle + ORBIT_SPEED*0.6*dt) % (math.pi*2)
    local tp = getTargetPosition(); if not tp then return end
    local n = #tentFolders
    for i = #tentFolders, 1, -1 do
        local t2 = loveAngle + (i-1)*(math.pi*2/n)
        local hx = 16*(math.sin(t2))^3 * (ORBIT_RADIUS*0.35)
        local hy = (13*math.cos(t2) - 5*math.cos(2*t2) - 2*math.cos(3*t2) - math.cos(4*t2)) * (ORBIT_RADIUS*0.27)
        if not setCF(tentFolders[i], CFrame.new(tp.X+hx, tp.Y+HEIGHT_OFFSET, tp.Z+hy)) then
            table.remove(tentFolders,i)
        end
    end
end

-- TORNADO
local tornadoAngle = 0
local function updateTornado(dt)
    tornadoAngle = (tornadoAngle + ORBIT_SPEED*1.5*dt) % (math.pi*2)
    local tp = getTargetPosition(); if not tp then return end
    local n  = #tentFolders
    for i = #tentFolders, 1, -1 do
        local frac    = (i-1)/(math.max(n-1,1))
        local angle   = tornadoAngle + (i-1)*(math.pi*2/math.max(n,1))
        local radius  = ORBIT_RADIUS * (1 - frac*0.85)
        local height  = frac * ORBIT_RADIUS * 1.5
        local x = tp.X + math.cos(angle)*radius
        local z = tp.Z + math.sin(angle)*radius
        if not setCF(tentFolders[i], CFrame.new(x, tp.Y+HEIGHT_OFFSET+height, z)) then
            table.remove(tentFolders,i)
        end
    end
end

-- ══════════════════════════════════════
--   EKOR – rantai ekor ular sejati
--   Node disimpan dalam "history" posisi player tiap tick
--   Tiap tenda ikut posisi history N*spacing detik lalu
-- ══════════════════════════════════════
local ekorHistory    = {}   -- {pos=Vector3, t=number} posisi HRP tiap frame
local EKOR_HIST_MAX  = 600  -- simpan max 600 titik

local function updateEkor(dt)
    local hrp = getHRP()
    if not hrp then return end

    local n = #tentFolders
    if n == 0 then return end

    -- Rekam posisi player setiap frame
    local now = os.clock()
    local hrpPos = hrp.Position + Vector3.new(0, HEIGHT_OFFSET, 0)
    table.insert(ekorHistory, 1, { pos=hrpPos, t=now })
    -- Buang history lama
    while #ekorHistory > EKOR_HIST_MAX do
        table.remove(ekorHistory)
    end

    if #ekorHistory < 2 then return end

    -- Jarak antar node ekor
    local spacing = math.max(1.5, ORBIT_RADIUS * 0.5)

    -- Tiap tenda = ambil titik dari history yang akumulasi jaraknya = i * spacing
    for i = 1, n do
        local f = tentFolders[n - i + 1]   -- tenda 1 paling dekat, n paling jauh
        if not f or not f.Parent then
            table.remove(tentFolders, n - i + 1)
            break
        end

        -- Cari titik di history yg jaraknya sekitar i*spacing dari player
        local targetDist = i * spacing
        local accDist    = 0
        local targetPos  = ekorHistory[#ekorHistory].pos  -- fallback: ujung history

        for h = 1, #ekorHistory - 1 do
            local segDist = (ekorHistory[h].pos - ekorHistory[h+1].pos).Magnitude
            if accDist + segDist >= targetDist then
                -- Interpolasi dalam segmen ini
                local frac = (targetDist - accDist) / math.max(segDist, 0.001)
                targetPos = ekorHistory[h].pos:Lerp(ekorHistory[h+1].pos, frac)
                break
            end
            accDist = accDist + segDist
        end

        -- Animasi gelombang ular: sedikit oscillate kiri-kanan
        local waveAmp   = ORBIT_RADIUS * 0.18
        local waveFreq  = ORBIT_SPEED * 3
        local phase     = now * waveFreq - i * 0.5
        local rightVec  = hrp.CFrame.RightVector
        local waveOff   = rightVec * math.sin(phase) * waveAmp

        local finalPos = Vector3.new(
            targetPos.X + waveOff.X,
            targetPos.Y,
            targetPos.Z + waveOff.Z
        )
        setCF(f, CFrame.new(finalPos.X, finalPos.Y, finalPos.Z))
    end
end

-- ══════════════════════════════════════
--   MAHKOTA – semua prop numpuk tepat 2 stud di atas kepala player
--   Cari Head part player (atau HRP sebagai fallback)
--   Animasi: tiap prop berputar kecil di sekitar pusat mahkota
-- ══════════════════════════════════════
local mahkotaAngle = 0

local function getMahkotaCenter()
    local char = nil
    if targetPlayer and targetPlayer.Parent then
        char = targetPlayer.Character
    else
        char = LocalPlayer.Character
    end
    if not char then return nil end
    -- Cari Head part
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position + Vector3.new(0, head.Size.Y * 0.5 + 2, 0)
    end
    -- Fallback ke HRP
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 3.5 + HEIGHT_OFFSET, 0) end
    return nil
end

local function updateMahkota(dt)
    mahkotaAngle = (mahkotaAngle + ORBIT_SPEED * 1.5 * dt) % (math.pi * 2)
    local center = getMahkotaCenter()
    if not center then return end

    local n = #tentFolders
    if n == 0 then return end

    -- Semua prop berputar pelan di atas kepala (orbit kecil biar kelihatan semua)
    local crownR = math.min(ORBIT_RADIUS * 0.25, 1.2)  -- radius kecil = numpuk tapi sedikit berputar

    for i = #tentFolders, 1, -1 do
        local f = tentFolders[i]
        if not f or not f.Parent then
            table.remove(tentFolders, i)
        else
            local a  = mahkotaAngle + (i - 1) * (math.pi * 2 / n)
            local bx = center.X + math.cos(a) * crownR
            local bz = center.Z + math.sin(a) * crownR
            -- Sedikit tumpuk tinggi per prop (biar ada kedalaman)
            local yStack = (i - 1) * 0.1
            setCF(f, CFrame.new(bx, center.Y + yStack, bz))
        end
    end
end

-- ══════════════════════════════════════
--   BODY SIDE – prop kiri 5 stud & kanan 5 stud
--   Satu-satu bergerak: orbit 3x → atas kepala → terbang ke sisi tujuan
--   Prop berikutnya HANYA bergerak setelah prop sebelumnya SELESAI + delay 3-4 detik
-- ══════════════════════════════════════
local bodySideSides     = {}   -- 1=kanan, -1=kiri per tenda
local bodySidePositions = {}   -- posisi lerp per tenda
local bodySideActive    = nil  -- index tenda yang lagi transit (nil = semua idle)
local bodySideOrbitState= nil  -- state animasi transit
local bodySideIdleTimer = 0    -- timer idle antar transit
local bodySideIdleDelay = 3.5  -- detik delay setelah 1 prop selesai

local BODY_DIST   = 5
local BODY_ORBITS = 3

local function bodySideInitSides(n)
    bodySideSides    = {}
    bodySidePositions= {}
    bodySideActive   = nil
    bodySideOrbitState = nil
    bodySideIdleTimer  = 0
    local half = math.floor(n / 2)
    for i = 1, n do
        bodySideSides[i] = (i <= half) and 1 or -1
    end
end

local function updateBodySide(dt)
    local tp  = getTargetPosition(); if not tp then return end
    local n   = #tentFolders
    if n == 0 then return end

    if #bodySideSides ~= n then bodySideInitSides(n) end

    local lerpSp    = math.clamp(ORBIT_SPEED * 8 * dt, 0, 1)
    local headCenter= getMahkotaCenter() or (tp + Vector3.new(0, 4.5, 0))

    -- ── SEMUA TENDA: idle di posisinya ───
    for i = 1, n do
        local f = tentFolders[i]
        if not f or not f.Parent then
            -- Bersihkan
            if bodySideActive == i then
                bodySideActive = nil; bodySideOrbitState = nil; bodySideIdleTimer = 0
            end
            table.remove(tentFolders, i); table.remove(bodySideSides, i)
            table.remove(bodySidePositions, i)
            break
        end

        -- Tenda yg lagi transit: posisinya di-update di blok transit di bawah
        if bodySideActive == i then continue end

        -- Idle: lerp ke posisi sisi
        local destPos = Vector3.new(tp.X + bodySideSides[i] * BODY_DIST, tp.Y + HEIGHT_OFFSET, tp.Z)
        if not bodySidePositions[i] then bodySidePositions[i] = destPos end
        bodySidePositions[i] = bodySidePositions[i]:Lerp(destPos, lerpSp)
        setCF(f, CFrame.new(bodySidePositions[i].X, bodySidePositions[i].Y, bodySidePositions[i].Z))
    end

    -- ── ANIMASI TRANSIT ───────────────────
    if bodySideActive then
        local i   = bodySideActive
        local st  = bodySideOrbitState
        local f   = tentFolders[i]
        if not f or not f.Parent then
            bodySideActive = nil; bodySideOrbitState = nil; bodySideIdleTimer = 0
        else
            st.progress = st.progress + dt * ORBIT_SPEED * 0.55

            local p   = st.progress
            local pos

            if p <= BODY_ORBITS then
                -- Orbit 3x keliling player
                local a      = st.startAngle + (p / BODY_ORBITS) * math.pi * 2 * BODY_ORBITS
                local yRise  = (p / BODY_ORBITS) * 1.5
                pos = Vector3.new(
                    tp.X + math.cos(a) * ORBIT_RADIUS,
                    tp.Y + HEIGHT_OFFSET + yRise,
                    tp.Z + math.sin(a) * ORBIT_RADIUS
                )
                st.lastAngle = a

            elseif p <= BODY_ORBITS + 0.6 then
                -- Naik ke atas kepala
                local t2      = (p - BODY_ORBITS) / 0.6
                local exitPos = Vector3.new(
                    tp.X + math.cos(st.lastAngle) * ORBIT_RADIUS,
                    tp.Y + HEIGHT_OFFSET + 1.5,
                    tp.Z + math.sin(st.lastAngle) * ORBIT_RADIUS
                )
                pos = exitPos:Lerp(headCenter, t2)

            else
                -- Terbang ke sisi tujuan
                local t3     = math.min((p - BODY_ORBITS - 0.6) / 0.5, 1)
                local destPos= Vector3.new(tp.X + st.toSide * BODY_DIST, tp.Y + HEIGHT_OFFSET, tp.Z)
                pos = headCenter:Lerp(destPos, t3)

                if t3 >= 1 then
                    -- Selesai transit
                    bodySideSides[i]     = st.toSide
                    bodySidePositions[i] = destPos
                    bodySideActive       = nil
                    bodySideOrbitState   = nil
                    bodySideIdleTimer    = 0   -- mulai hitung delay sebelum prop berikutnya
                end
            end

            if pos then
                if not bodySidePositions[i] then bodySidePositions[i] = pos end
                bodySidePositions[i] = bodySidePositions[i]:Lerp(pos, math.min(lerpSp * 2, 1))
                setCF(f, CFrame.new(bodySidePositions[i].X, bodySidePositions[i].Y, bodySidePositions[i].Z))
            end
        end
    end

    -- ── PILIH PROP BERIKUTNYA setelah delay ──
    if not bodySideActive then
        bodySideIdleTimer = bodySideIdleTimer + dt
        local delay = math.max(2.0, bodySideIdleDelay / math.max(ORBIT_SPEED, 0.1))
        if bodySideIdleTimer >= delay then
            bodySideIdleTimer = 0
            -- Cari 1 idle prop yang bisa pindah sisi
            -- Ganti secara antrian: kanan ke kiri, lalu kiri ke kanan, bergantian
            local candidates = {}
            for i = 1, n do
                table.insert(candidates, i)
            end
            -- Shuffle kecil, pilih 1
            for k = #candidates, 2, -1 do
                local j = math.random(1, k)
                candidates[k], candidates[j] = candidates[j], candidates[k]
            end

            local chosen = candidates[1]
            local fromSide = bodySideSides[chosen]
            local toSide   = -fromSide
            -- Hitung angle awal dari posisi idle prop ke orbit player
            local idlePos = bodySidePositions[chosen] or Vector3.new(tp.X + fromSide * BODY_DIST, tp.Y, tp.Z)
            local startA  = math.atan2(idlePos.Z - tp.Z, idlePos.X - tp.X)

            bodySideActive     = chosen
            bodySideOrbitState = {
                progress   = 0,
                fromSide   = fromSide,
                toSide     = toSide,
                startAngle = startA,
                lastAngle  = startA,
            }
        end
    end
end

-- ══════════════════════════════════════
--   GAMES – dua orbit bulatan di kanan & kiri player
--   Satu-satu tukar sisi (random pair swap) sambil orbit terus
-- ══════════════════════════════════════
local gamesAngle      = 0      -- sudut orbit utama (berputar terus)
local gamesSwapTimer  = 0
local gamesSwapDelay  = 1.4    -- detik antar swap
local gamesSides      = {}     -- 1 = kanan, -1 = kiri, per tenda
local gamesPositions  = {}     -- lerp positions

local function gamesInitSides(n)
    gamesSides    = {}
    gamesPositions = {}
    local half = math.floor(n / 2)
    for i = 1, n do
        gamesSides[i] = (i <= half) and 1 or -1
    end
end

local function updateGames(dt)
    local tp = getTargetPosition(); if not tp then return end
    local n  = #tentFolders
    if n == 0 then return end

    if #gamesSides ~= n then gamesInitSides(n) end

    -- Orbit angle berputar terus
    gamesAngle = (gamesAngle + ORBIT_SPEED * dt) % (math.pi * 2)

    local centerDist = ORBIT_RADIUS          -- jarak pusat orbit dari player
    local orbitR     = ORBIT_RADIUS * 0.55   -- radius orbit bulatan di tiap sisi
    local lerpSpeed  = math.clamp(ORBIT_SPEED * 7 * dt, 0, 1)

    -- Hitung berapa tenda per sisi (real-time)
    local countR, countL = 0, 0
    for i = 1, n do
        if gamesSides[i] == 1 then countR = countR + 1 else countL = countL + 1 end
    end
    local idxR, idxL = 0, 0

    for i = 1, n do
        local f = tentFolders[i]
        if not f or not f.Parent then
            table.remove(tentFolders, i)
            table.remove(gamesSides, i)
            table.remove(gamesPositions, i)
            break
        end

        local side = gamesSides[i]  -- 1=kanan, -1=kiri
        local memberIdx, memberCount
        if side == 1 then
            idxR = idxR + 1
            memberIdx   = idxR
            memberCount = countR
        else
            idxL = idxL + 1
            memberIdx   = idxL
            memberCount = countL
        end

        -- Tiap tenda punya sudut orbit sendiri di dalam lingkaran sisinya
        local angleOffset = (memberIdx - 1) * (math.pi * 2 / math.max(memberCount, 1))
        local a = gamesAngle + angleOffset

        -- Pusat orbit ada di kanan/kiri player
        local cx = tp.X + side * centerDist
        local cy = tp.Y + HEIGHT_OFFSET
        local cz = tp.Z

        -- Posisi di orbit bulatan itu
        local targetPos = Vector3.new(
            cx + math.cos(a) * orbitR,
            cy + math.sin(a * 0.5) * (orbitR * 0.4),   -- sedikit naik-turun biar 3D
            cz + math.sin(a) * orbitR
        )

        if not gamesPositions[i] then
            gamesPositions[i] = targetPos
        end
        gamesPositions[i] = gamesPositions[i]:Lerp(targetPos, lerpSpeed)
        local cp = gamesPositions[i]
        setCF(f, CFrame.new(cp.X, cp.Y, cp.Z))
    end

    -- Swap: tiap delay, 1 tenda kanan + 1 tenda kiri tukar sisi barengan (random)
    gamesSwapTimer = gamesSwapTimer + dt
    local swapInterval = math.max(0.4, gamesSwapDelay / math.max(ORBIT_SPEED, 0.1))
    if gamesSwapTimer >= swapInterval and n >= 2 then
        gamesSwapTimer = 0
        -- Kumpulkan index kanan dan kiri
        local rightList, leftList = {}, {}
        for i = 1, n do
            if gamesSides[i] == 1 then
                table.insert(rightList, i)
            else
                table.insert(leftList, i)
            end
        end
        -- Swap 1 random dari kanan dengan 1 random dari kiri
        if #rightList > 0 and #leftList > 0 then
            local ri = rightList[math.random(1, #rightList)]
            local li = leftList[math.random(1, #leftList)]
            gamesSides[ri] = -1
            gamesSides[li] =  1
        end
    end
end

-- ══════════════════════════════════════
--   WINGS – sayap mengepak di kiri-kanan player
--   Part tersusun kayak bulu sayap: semakin ke ujung makin naik
--   Animasi mengepak: gelombang sinusoidal berjalan dari pangkal ke ujung
-- ══════════════════════════════════════
local wingsAngle   = 0   -- fase animasi kepak
local wingsPositions = {}

local function updateWings(dt)
    local hrp = getHRP()
    local tp  = getTargetPosition()
    if not hrp or not tp then return end

    local n = #tentFolders
    if n == 0 then return end

    wingsAngle = wingsAngle + ORBIT_SPEED * 2.2 * dt

    local half   = math.ceil(n / 2)   -- separuh kanan, sisanya kiri
    local lerpSp = math.clamp(ORBIT_SPEED * 9 * dt, 0, 1)

    -- Ambil orientation player (XZ)
    local rightVec = hrp.CFrame.RightVector
    local upVec    = Vector3.new(0, 1, 0)
    local backVec  = -hrp.CFrame.LookVector

    -- Base sayap: 1 stud di belakang player
    local wingBase = Vector3.new(
        tp.X + backVec.X * 1,
        tp.Y + HEIGHT_OFFSET,
        tp.Z + backVec.Z * 1
    )

    -- Spread per bulu: jarak antar bulu di sepanjang sayap
    local featherSpread = math.max(1.2, ORBIT_RADIUS * 0.45)

    for i = #tentFolders, 1, -1 do
        local f = tentFolders[i]
        if not f or not f.Parent then
            table.remove(tentFolders, i)
            table.remove(wingsPositions, i)
        else
            -- Tentukan apakah ini sayap kanan (1..half) atau kiri (half+1..n)
            local isRight = (i <= half)
            local featherIdx  -- index bulu dari pangkal (1) ke ujung (half)
            local sideSign    -- +1 kanan, -1 kiri
            if isRight then
                featherIdx = i
                sideSign   = 1
            else
                featherIdx = i - half
                sideSign   = -1
            end

            -- Posisi bulu: semakin ke ujung semakin ke samping DAN semakin naik
            local t     = (featherIdx - 1) / math.max(half - 1, 1)  -- 0=pangkal, 1=ujung
            local xOff  = sideSign * featherIdx * featherSpread
            local yBase = t * t * ORBIT_RADIUS * 0.7   -- kurva naik kuadratik

            -- Animasi kepak: gelombang berjalan dari pangkal ke ujung
            -- Fase bergeser per bulu → efek ripple/wave
            local phaseShift = t * math.pi * 1.4
            local flapAmp    = ORBIT_RADIUS * 0.35 * (0.3 + t * 0.7)  -- ujung lebih lebar
            local flapY      = math.sin(wingsAngle - phaseShift) * flapAmp

            -- Sedikit gerakan depan-belakang (Z) juga biar 3D
            local flapZ      = math.cos(wingsAngle - phaseShift) * flapAmp * 0.25

            local targetPos = Vector3.new(
                wingBase.X + rightVec.X * xOff + backVec.X * flapZ,
                wingBase.Y + yBase + flapY,
                wingBase.Z + rightVec.Z * xOff + backVec.Z * flapZ
            )

            if not wingsPositions[i] then
                wingsPositions[i] = targetPos
            end
            wingsPositions[i] = wingsPositions[i]:Lerp(targetPos, lerpSp)
            local cp = wingsPositions[i]
            setCF(f, CFrame.new(cp.X, cp.Y, cp.Z))
        end
    end
end

-- ══════════════════════════════════════
--   MAIN LOOP
-- ══════════════════════════════════════
local modeUpdateFn = {
    orbit     = updateOrbit,
    leftright = updateLeftRight,
    love      = updateLove,
    tornado   = updateTornado,
    ekor      = updateEkor,
    games     = updateGames,
    wings     = updateWings,
    mahkota   = updateMahkota,
    bodyside  = updateBodySide,
}

startLoop = function()
    if orbitConnection then return end
    orbitConnection = RunService.Heartbeat:Connect(function(dt)
        local fn = modeUpdateFn[currentMode]
        if fn then fn(dt) end
    end)
end
stopLoop = function()
    if orbitConnection then orbitConnection:Disconnect(); orbitConnection = nil end
end

local modeTentCount = {
    orbit=2, leftright=2,
    love=8, tornado=8,
    ekor=6, games=6, wings=8,
    mahkota=4, bodyside=4,
}

-- ══════════════════════════════════════
--   BAHLIL TEXT CYCLER (dengan Sign ID)
-- ══════════════════════════════════════
local function getBahlilList()
    return (#bahlilTexts > 0) and bahlilTexts or bahlilDefault
end

local function startBahlilCycle()
    bahlilActive = true
    bahlilIndex  = 1
    task.spawn(function()
        while bahlilActive do
            local list = getBahlilList()
            local text = list[bahlilIndex]
            if text and text ~= "" then
                pcall(function()
                    ReplicatedStorage.RE["1Cemeter1y"]:FireServer("ReturningBigSign3Name", bahlilSignID, text)
                end)
            end
            bahlilIndex = (bahlilIndex % #list) + 1
            task.wait(2)
        end
    end)
end

local function stopBahlilCycle()
    bahlilActive = false
end

-- ══════════════════════════════════════
--   BAHLIL PANEL GUI
-- ══════════════════════════════════════
local BP_W   = 372
local BP_H   = 325
local BP_COL = 166

local bahlilFrame = Instance.new("Frame", gui)
bahlilFrame.Size             = UDim2.new(0, BP_W, 0, BP_H)
bahlilFrame.Position         = UDim2.new(0.5, -BP_W/2, 0.5, -BP_H/2)
bahlilFrame.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
bahlilFrame.BorderSizePixel  = 0
bahlilFrame.ZIndex           = 30
bahlilFrame.Visible          = false
bahlilFrame.ClipsDescendants = false
Instance.new("UICorner", bahlilFrame).CornerRadius = UDim.new(0,10)
local bpStroke = Instance.new("UIStroke", bahlilFrame)
bpStroke.Color = Color3.fromRGB(200,100,0); bpStroke.Thickness = 1.6

local bpHeader = Instance.new("Frame", bahlilFrame)
bpHeader.Size             = UDim2.new(1,0,0,28)
bpHeader.BackgroundColor3 = Color3.fromRGB(35,20,5)
bpHeader.BorderSizePixel  = 0
bpHeader.ZIndex           = 31
Instance.new("UICorner", bpHeader).CornerRadius = UDim.new(0,10)

local bpTitle = Instance.new("TextLabel", bpHeader)
bpTitle.Size             = UDim2.new(1,-90,1,0)
bpTitle.Position         = UDim2.new(0,8,0,0)
bpTitle.BackgroundTransparency = 1
bpTitle.Text             = "😎 Bahlil Editor"
bpTitle.TextColor3       = Color3.fromRGB(255,160,50)
bpTitle.Font             = Enum.Font.GothamBold
bpTitle.TextSize         = 13
bpTitle.TextXAlignment   = Enum.TextXAlignment.Left
bpTitle.ZIndex           = 32

local bpBtnToggle = Instance.new("TextButton", bpHeader)
bpBtnToggle.Size             = UDim2.new(0, 58, 0, 20)
bpBtnToggle.Position         = UDim2.new(1, -82, 0.5, -10)
bpBtnToggle.BackgroundColor3 = Color3.fromRGB(50,180,60)
bpBtnToggle.Text             = "▶ Start"
bpBtnToggle.TextColor3       = Color3.new(1,1,1)
bpBtnToggle.Font             = Enum.Font.GothamBold
bpBtnToggle.TextSize         = 10
bpBtnToggle.AutoButtonColor  = false
bpBtnToggle.ZIndex           = 33
Instance.new("UICorner", bpBtnToggle).CornerRadius = UDim.new(0,5)

local bpBtnClose = Instance.new("TextButton", bpHeader)
bpBtnClose.Size             = UDim2.new(0, 20, 0, 20)
bpBtnClose.Position         = UDim2.new(1, -24, 0.5, -10)
bpBtnClose.BackgroundColor3 = Color3.fromRGB(180,40,40)
bpBtnClose.Text             = "✕"
bpBtnClose.TextColor3       = Color3.new(1,1,1)
bpBtnClose.Font             = Enum.Font.GothamBold
bpBtnClose.TextSize         = 11
bpBtnClose.AutoButtonColor  = false
bpBtnClose.ZIndex           = 33
Instance.new("UICorner", bpBtnClose).CornerRadius = UDim.new(0,5)

-- ── Baris Sign ID ────────────────────
local bpIdRow = Instance.new("Frame", bahlilFrame)
bpIdRow.Size             = UDim2.new(1, -8, 0, 26)
bpIdRow.Position         = UDim2.new(0, 4, 0, 30)
bpIdRow.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
bpIdRow.BorderSizePixel  = 0
bpIdRow.ZIndex           = 31
Instance.new("UICorner", bpIdRow).CornerRadius = UDim.new(0,5)

local bpIdLabel = Instance.new("TextLabel", bpIdRow)
bpIdLabel.Size             = UDim2.new(0, 46, 1, 0)
bpIdLabel.Position         = UDim2.new(0, 4, 0, 0)
bpIdLabel.BackgroundTransparency = 1
bpIdLabel.Text             = "Sign ID:"
bpIdLabel.TextColor3       = Color3.fromRGB(200, 160, 80)
bpIdLabel.Font             = Enum.Font.GothamBold
bpIdLabel.TextSize         = 11
bpIdLabel.TextXAlignment   = Enum.TextXAlignment.Left
bpIdLabel.ZIndex           = 32

local bpIdBox = Instance.new("TextBox", bpIdRow)
bpIdBox.Size             = UDim2.new(1, -54, 1, -4)
bpIdBox.Position         = UDim2.new(0, 50, 0, 2)
bpIdBox.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
bpIdBox.BorderSizePixel  = 0
bpIdBox.Text             = bahlilSignID
bpIdBox.PlaceholderText  = "ID angka/huruf"
bpIdBox.TextColor3       = Color3.fromRGB(255, 210, 100)
bpIdBox.PlaceholderColor3 = Color3.fromRGB(100, 80, 60)
bpIdBox.Font             = Enum.Font.Gotham
bpIdBox.TextSize         = 11
bpIdBox.ClearTextOnFocus = false
bpIdBox.ZIndex           = 33
Instance.new("UICorner", bpIdBox).CornerRadius = UDim.new(0,3)

bpIdBox.FocusLost:Connect(function(enterPressed)
    bahlilSignID = bpIdBox.Text
end)

-- ── Kiri: input area ──────────────────
local bpLeft = Instance.new("Frame", bahlilFrame)
bpLeft.Size             = UDim2.new(0, BP_COL, 1, -36)
bpLeft.Position         = UDim2.new(0, 4, 0, 60)
bpLeft.BackgroundColor3 = Color3.fromRGB(18,14,28)
bpLeft.BorderSizePixel  = 0
bpLeft.ZIndex           = 31
Instance.new("UICorner", bpLeft).CornerRadius = UDim.new(0,7)

local bpLeftTitle = Instance.new("TextLabel", bpLeft)
bpLeftTitle.Size             = UDim2.new(1,0,0,18)
bpLeftTitle.Position         = UDim2.new(0,4,0,3)
bpLeftTitle.BackgroundTransparency = 1
bpLeftTitle.Text             = "✏️ Tambah Teks (max 100)"
bpLeftTitle.TextColor3       = Color3.fromRGB(200,160,255)
bpLeftTitle.Font             = Enum.Font.GothamBold
bpLeftTitle.TextSize         = 9
bpLeftTitle.TextXAlignment   = Enum.TextXAlignment.Left
bpLeftTitle.ZIndex           = 32

local bpInputScroll = Instance.new("ScrollingFrame", bpLeft)
bpInputScroll.Size                  = UDim2.new(1,-4,1,-46)
bpInputScroll.Position              = UDim2.new(0,2,0,22)
bpInputScroll.BackgroundTransparency = 1
bpInputScroll.BorderSizePixel       = 0
bpInputScroll.ScrollBarThickness    = 3
bpInputScroll.ScrollBarImageColor3  = Color3.fromRGB(180,100,0)
bpInputScroll.CanvasSize            = UDim2.new(0,0,0,0)
bpInputScroll.ZIndex                = 32
bpInputScroll.ClipsDescendants      = true
local bpInputLayout = Instance.new("UIListLayout", bpInputScroll)
bpInputLayout.Padding = UDim.new(0,3)

local bpBtnAdd = Instance.new("TextButton", bpLeft)
bpBtnAdd.Size             = UDim2.new(0, 46, 0, 20)
bpBtnAdd.Position         = UDim2.new(0, 4, 1, -23)
bpBtnAdd.BackgroundColor3 = Color3.fromRGB(50,100,180)
bpBtnAdd.Text             = "+ Add"
bpBtnAdd.TextColor3       = Color3.new(1,1,1)
bpBtnAdd.Font             = Enum.Font.GothamBold
bpBtnAdd.TextSize         = 10
bpBtnAdd.AutoButtonColor  = false
bpBtnAdd.ZIndex           = 33
Instance.new("UICorner", bpBtnAdd).CornerRadius = UDim.new(0,5)

local bpBtnSave = Instance.new("TextButton", bpLeft)
bpBtnSave.Size             = UDim2.new(0, 52, 0, 20)
bpBtnSave.Position         = UDim2.new(1, -56, 1, -23)
bpBtnSave.BackgroundColor3 = Color3.fromRGB(30,160,80)
bpBtnSave.Text             = "💾 Save"
bpBtnSave.TextColor3       = Color3.new(1,1,1)
bpBtnSave.Font             = Enum.Font.GothamBold
bpBtnSave.TextSize         = 10
bpBtnSave.AutoButtonColor  = false
bpBtnSave.ZIndex           = 33
Instance.new("UICorner", bpBtnSave).CornerRadius = UDim.new(0,5)

-- ── Divider tengah ────────────────────
local bpDiv = Instance.new("Frame", bahlilFrame)
bpDiv.Size             = UDim2.new(0, 1, 1, -36)
bpDiv.Position         = UDim2.new(0, BP_COL+8, 0, 60)
bpDiv.BackgroundColor3 = Color3.fromRGB(80,50,30)
bpDiv.BorderSizePixel  = 0
bpDiv.ZIndex           = 31

-- ── Kanan: riwayat ────────────────────
local bpRight = Instance.new("Frame", bahlilFrame)
bpRight.Size             = UDim2.new(0, BP_W - BP_COL - 18, 1, -36)
bpRight.Position         = UDim2.new(0, BP_COL+13, 0, 60)
bpRight.BackgroundColor3 = Color3.fromRGB(18,14,28)
bpRight.BorderSizePixel  = 0
bpRight.ZIndex           = 31
Instance.new("UICorner", bpRight).CornerRadius = UDim.new(0,7)

local bpRightTitle = Instance.new("TextLabel", bpRight)
bpRightTitle.Size             = UDim2.new(1,0,0,18)
bpRightTitle.Position         = UDim2.new(0,4,0,3)
bpRightTitle.BackgroundTransparency = 1
bpRightTitle.Text             = "📋 Riwayat (klik untuk edit)"
bpRightTitle.TextColor3       = Color3.fromRGB(200,160,255)
bpRightTitle.Font             = Enum.Font.GothamBold
bpRightTitle.TextSize         = 9
bpRightTitle.TextXAlignment   = Enum.TextXAlignment.Left
bpRightTitle.ZIndex           = 32

local bpEditBox = Instance.new("TextBox", bpRight)
bpEditBox.Size             = UDim2.new(1,-8,0,20)
bpEditBox.Position         = UDim2.new(0,4,0,22)
bpEditBox.BackgroundColor3 = Color3.fromRGB(28,22,42)
bpEditBox.BorderSizePixel  = 0
bpEditBox.Text             = ""
bpEditBox.PlaceholderText  = "Klik item di bawah..."
bpEditBox.TextColor3       = Color3.fromRGB(255,220,150)
bpEditBox.PlaceholderColor3 = Color3.fromRGB(100,80,60)
bpEditBox.Font             = Enum.Font.Gotham
bpEditBox.TextSize         = 10
bpEditBox.ClearTextOnFocus = false
bpEditBox.ZIndex           = 33
Instance.new("UICorner", bpEditBox).CornerRadius = UDim.new(0,4)
local bpEditStroke = Instance.new("UIStroke", bpEditBox)
bpEditStroke.Color = Color3.fromRGB(150,100,0); bpEditStroke.Thickness = 1

local bpBtnUpdate = Instance.new("TextButton", bpRight)
bpBtnUpdate.Size             = UDim2.new(1,-8,0,18)
bpBtnUpdate.Position         = UDim2.new(0,4,0,44)
bpBtnUpdate.BackgroundColor3 = Color3.fromRGB(90,55,180)
bpBtnUpdate.Text             = "✎ Update Teks"
bpBtnUpdate.TextColor3       = Color3.new(1,1,1)
bpBtnUpdate.Font             = Enum.Font.GothamBold
bpBtnUpdate.TextSize         = 10
bpBtnUpdate.AutoButtonColor  = false
bpBtnUpdate.ZIndex           = 33
Instance.new("UICorner", bpBtnUpdate).CornerRadius = UDim.new(0,4)

local bpHistScroll = Instance.new("ScrollingFrame", bpRight)
bpHistScroll.Size                  = UDim2.new(1,-4,1,-92)
bpHistScroll.Position              = UDim2.new(0,2,0,65)
bpHistScroll.BackgroundTransparency = 1
bpHistScroll.BorderSizePixel       = 0
bpHistScroll.ScrollBarThickness    = 3
bpHistScroll.ScrollBarImageColor3  = Color3.fromRGB(180,100,0)
bpHistScroll.CanvasSize            = UDim2.new(0,0,0,0)
bpHistScroll.ZIndex                = 32
bpHistScroll.ClipsDescendants      = true
local bpHistLayout = Instance.new("UIListLayout", bpHistScroll)
bpHistLayout.Padding = UDim.new(0,2)

local bpBtnDelAll = Instance.new("TextButton", bpRight)
bpBtnDelAll.Size             = UDim2.new(1,-8,0,20)
bpBtnDelAll.Position         = UDim2.new(0,4,1,-23)
bpBtnDelAll.BackgroundColor3 = Color3.fromRGB(160,30,30)
bpBtnDelAll.Text             = "🗑️ Delete All"
bpBtnDelAll.TextColor3       = Color3.new(1,1,1)
bpBtnDelAll.Font             = Enum.Font.GothamBold
bpBtnDelAll.TextSize         = 10
bpBtnDelAll.AutoButtonColor  = false
bpBtnDelAll.ZIndex           = 33
Instance.new("UICorner", bpBtnDelAll).CornerRadius = UDim.new(0,4)

-- ── Drag Bahlil panel ─────────────────
local bpDragging, bpDragStart, bpStartPos = false, nil, nil
local bpIsDragging = false
bpHeader.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        bpIsDragging = false; bpDragging = true
        bpDragStart = i.Position; bpStartPos = bahlilFrame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then bpDragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if bpDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - bpDragStart
        if d.Magnitude > 4 then bpIsDragging = true end
        bahlilFrame.Position = UDim2.new(bpStartPos.X.Scale, bpStartPos.X.Offset+d.X, bpStartPos.Y.Scale, bpStartPos.Y.Offset+d.Y)
    end
end)

-- ── Bahlil Panel Logic ────────────────
local function refreshBahlilHistory()
    for _, c in ipairs(bpHistScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local list = getBahlilList()
    local ROW_H = 22
    for idx, txt in ipairs(list) do
        local row = Instance.new("Frame", bpHistScroll)
        row.Size             = UDim2.new(1,-4,0,ROW_H)
        row.BackgroundColor3 = (idx == bahlilHistSelIdx)
            and Color3.fromRGB(65,40,105) or Color3.fromRGB(24,18,38)
        row.BorderSizePixel  = 0
        row.ZIndex           = 33
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)

        local numLbl = Instance.new("TextLabel", row)
        numLbl.Size             = UDim2.new(0,20,1,0)
        numLbl.BackgroundTransparency = 1
        numLbl.Text             = tostring(idx).."."
        numLbl.TextColor3       = Color3.fromRGB(160,130,220)
        numLbl.Font             = Enum.Font.Gotham
        numLbl.TextSize         = 9
        numLbl.ZIndex           = 34

        local txtLbl = Instance.new("TextLabel", row)
        txtLbl.Size             = UDim2.new(1,-22,1,0)
        txtLbl.Position         = UDim2.new(0,20,0,0)
        txtLbl.BackgroundTransparency = 1
        txtLbl.Text             = txt
        txtLbl.TextColor3       = (idx == bahlilHistSelIdx)
            and Color3.fromRGB(255,200,80) or Color3.fromRGB(195,185,215)
        txtLbl.Font             = Enum.Font.Gotham
        txtLbl.TextSize         = 9
        txtLbl.TextXAlignment   = Enum.TextXAlignment.Left
        txtLbl.TextTruncate     = Enum.TextTruncate.AtEnd
        txtLbl.ZIndex           = 34

        local hitBtn = Instance.new("TextButton", row)
        hitBtn.Size             = UDim2.new(1,0,1,0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text             = ""
        hitBtn.ZIndex           = 35
        local captIdx = idx
        hitBtn.MouseButton1Click:Connect(function()
            bahlilHistSelIdx = captIdx
            bpEditBox.Text = getBahlilList()[captIdx] or ""
            refreshBahlilHistory()
        end)
    end
    bpHistScroll.CanvasSize = UDim2.new(0,0,0, #list * (ROW_H+2))
end

local function addInputRow(text)
    if #bahlilInputRows >= 100 then return end
    local ROW_H = 24

    local row = Instance.new("Frame", bpInputScroll)
    row.Size             = UDim2.new(1,-4,0,ROW_H)
    row.BackgroundColor3 = Color3.fromRGB(24,18,36)
    row.BorderSizePixel  = 0
    row.ZIndex           = 33
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)

    local tb = Instance.new("TextBox", row)
    tb.Size             = UDim2.new(1,-28,1,-4)
    tb.Position         = UDim2.new(0,2,0,2)
    tb.BackgroundColor3 = Color3.fromRGB(20,15,32)
    tb.BorderSizePixel  = 0
    tb.Text             = text or ""
    tb.PlaceholderText  = "Ketik teks..."
    tb.TextColor3       = Color3.fromRGB(255,230,180)
    tb.PlaceholderColor3 = Color3.fromRGB(80,70,60)
    tb.Font             = Enum.Font.Gotham
    tb.TextSize         = 10
    tb.ClearTextOnFocus = false
    tb.ZIndex           = 34
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,3)

    local delBtn = Instance.new("TextButton", row)
    delBtn.Size             = UDim2.new(0,22,0,ROW_H-4)
    delBtn.Position         = UDim2.new(1,-24,0,2)
    delBtn.BackgroundColor3 = Color3.fromRGB(140,30,30)
    delBtn.Text             = "✕"
    delBtn.TextColor3       = Color3.new(1,1,1)
    delBtn.Font             = Enum.Font.GothamBold
    delBtn.TextSize         = 9
    delBtn.AutoButtonColor  = false
    delBtn.ZIndex           = 35
    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0,3)

    local entry = { frame=row, textbox=tb }
    table.insert(bahlilInputRows, entry)

    local function updateCanvas()
        bpInputScroll.CanvasSize = UDim2.new(0,0,0, #bahlilInputRows*(ROW_H+3)+4)
        local sy = bpInputScroll.CanvasSize.Y.Offset
        local vy = bpInputScroll.AbsoluteSize.Y
        bpInputScroll.CanvasPosition = Vector2.new(0, math.max(0, sy - vy))
    end
    updateCanvas()

    delBtn.MouseButton1Click:Connect(function()
        for i2, e in ipairs(bahlilInputRows) do
            if e.frame == row then table.remove(bahlilInputRows, i2); break end
        end
        row:Destroy()
        updateCanvas()
    end)
end

local function openBahlilPanel()
    bahlilPanelOpen = true
    for _, e in ipairs(bahlilInputRows) do e.frame:Destroy() end
    bahlilInputRows = {}
    addInputRow("")
    bahlilHistSelIdx = 1
    bpEditBox.Text   = ""
    bpIdBox.Text = bahlilSignID
    refreshBahlilHistory()
    local pp  = panel.AbsolutePosition
    local ps2 = panel.AbsoluteSize
    local sx  = workspace.CurrentCamera.ViewportSize.X
    local sy  = workspace.CurrentCamera.ViewportSize.Y
    local px  = math.clamp(pp.X + ps2.X + 8, 4, sx - BP_W - 4)
    local py  = math.clamp(pp.Y, 4, sy - BP_H - 4)
    bahlilFrame.Position = UDim2.new(0, px, 0, py)
    bahlilFrame.Visible  = true
    bpBtnToggle.BackgroundColor3 = bahlilActive
        and Color3.fromRGB(200,60,60) or Color3.fromRGB(50,180,60)
    bpBtnToggle.Text = bahlilActive and "■ Stop" or "▶ Start"
end

local function closeBahlilPanel()
    bahlilPanelOpen = false
    bahlilFrame.Visible = false
end

bpBtnSave.MouseButton1Click:Connect(function()
    local newList = {}
    for _, entry in ipairs(bahlilInputRows) do
        local t = entry.textbox.Text
        if t ~= "" then table.insert(newList, t) end
    end
    bahlilTexts      = newList
    bahlilHistSelIdx = 1
    bpEditBox.Text   = ""
    refreshBahlilHistory()
    bpBtnSave.BackgroundColor3 = Color3.fromRGB(255,210,0)
    task.delay(0.4, function() bpBtnSave.BackgroundColor3 = Color3.fromRGB(30,160,80) end)
end)

bpBtnAdd.MouseButton1Click:Connect(function()
    addInputRow("")
end)

bpBtnUpdate.MouseButton1Click:Connect(function()
    local list = getBahlilList()
    if bahlilHistSelIdx < 1 or bahlilHistSelIdx > #list then return end
    if #bahlilTexts == 0 then
        for _, v in ipairs(bahlilDefault) do table.insert(bahlilTexts, v) end
    end
    bahlilTexts[bahlilHistSelIdx] = bpEditBox.Text
    refreshBahlilHistory()
    bpBtnUpdate.BackgroundColor3 = Color3.fromRGB(255,210,0)
    task.delay(0.4, function() bpBtnUpdate.BackgroundColor3 = Color3.fromRGB(90,55,180) end)
end)

bpBtnDelAll.MouseButton1Click:Connect(function()
    bahlilTexts      = {}
    bahlilHistSelIdx = 1
    bpEditBox.Text   = ""
    refreshBahlilHistory()
    bpBtnDelAll.BackgroundColor3 = Color3.fromRGB(255,80,80)
    task.delay(0.4, function() bpBtnDelAll.BackgroundColor3 = Color3.fromRGB(160,30,30) end)
end)

bpBtnToggle.MouseButton1Click:Connect(function()
    if bahlilActive then
        stopBahlilCycle()
        bpBtnToggle.BackgroundColor3 = Color3.fromRGB(50,180,60)
        bpBtnToggle.Text = "▶ Start"
        lblStatus.Text   = "Bahlil: stopped"
    else
        startBahlilCycle()
        bpBtnToggle.BackgroundColor3 = Color3.fromRGB(200,60,60)
        bpBtnToggle.Text = "■ Stop"
        lblStatus.Text   = "Bahlil: cycling 😎"
    end
    setButtonStates()
end)

bpBtnClose.MouseButton1Click:Connect(function()
    closeBahlilPanel()
end)

-- ══════════════════════════════════════
--   ANOTHER PLAYER PANEL
-- ══════════════════════════════════════
local AP_W     = 170
local AP_BTN_H = 26
local AP_GAP   = 3

local apFrame = Instance.new("Frame", gui)
apFrame.Size             = UDim2.new(0, AP_W, 0, 320)
apFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
apFrame.BorderSizePixel  = 0
apFrame.ZIndex           = 25
apFrame.Visible          = false
apFrame.ClipsDescendants = false
Instance.new("UICorner", apFrame).CornerRadius = UDim.new(0,10)
local apFrameStroke = Instance.new("UIStroke", apFrame)
apFrameStroke.Color = Color3.fromRGB(60,130,220); apFrameStroke.Thickness = 1.4

local apHeader = Instance.new("Frame", apFrame)
apHeader.Size             = UDim2.new(1,0,0,26)
apHeader.BackgroundColor3 = Color3.fromRGB(20,30,70)
apHeader.BorderSizePixel  = 0
apHeader.ZIndex           = 27
Instance.new("UICorner", apHeader).CornerRadius = UDim.new(0,10)

local apHeaderLbl = Instance.new("TextLabel", apHeader)
apHeaderLbl.Size             = UDim2.new(1,-28,1,0)
apHeaderLbl.Position         = UDim2.new(0,8,0,0)
apHeaderLbl.BackgroundTransparency = 1
apHeaderLbl.Text             = "👤 Players"
apHeaderLbl.TextColor3       = Color3.fromRGB(120,180,255)
apHeaderLbl.Font             = Enum.Font.GothamBold
apHeaderLbl.TextSize         = 11
apHeaderLbl.TextXAlignment   = Enum.TextXAlignment.Left
apHeaderLbl.ZIndex           = 28

local apBtnClose = Instance.new("TextButton", apHeader)
apBtnClose.Size             = UDim2.new(0,20,0,20)
apBtnClose.Position         = UDim2.new(1,-22,0,3)
apBtnClose.BackgroundColor3 = Color3.fromRGB(160,30,30)
apBtnClose.Text             = "✕"
apBtnClose.TextColor3       = Color3.new(1,1,1)
apBtnClose.Font             = Enum.Font.GothamBold
apBtnClose.TextSize         = 10
apBtnClose.AutoButtonColor  = false
apBtnClose.ZIndex           = 28
Instance.new("UICorner", apBtnClose).CornerRadius = UDim.new(0,4)

local apDragging, apDragStart, apStartPos = false, nil, nil
apHeader.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        apDragging = true; apDragStart = i.Position; apStartPos = apFrame.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then apDragging = false end end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if apDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - apDragStart
        apFrame.Position = UDim2.new(apStartPos.X.Scale, apStartPos.X.Offset+d.X, apStartPos.Y.Scale, apStartPos.Y.Offset+d.Y)
    end
end)

local apInfoLbl = Instance.new("TextLabel", apFrame)
apInfoLbl.Size             = UDim2.new(1,-8,0,14)
apInfoLbl.Position         = UDim2.new(0,4,0,29)
apInfoLbl.BackgroundTransparency = 1
apInfoLbl.Text             = "Belum ada target"
apInfoLbl.TextColor3       = Color3.fromRGB(160,200,255)
apInfoLbl.Font             = Enum.Font.Gotham
apInfoLbl.TextSize         = 9
apInfoLbl.TextXAlignment   = Enum.TextXAlignment.Left
apInfoLbl.TextTruncate     = Enum.TextTruncate.AtEnd
apInfoLbl.ZIndex           = 26

local btnSpektator = Instance.new("TextButton", apFrame)
btnSpektator.Size             = UDim2.new(0.5,-6,0,26)
btnSpektator.Position         = UDim2.new(0,4,0,45)
btnSpektator.BackgroundColor3 = Color3.fromRGB(20,80,160)
btnSpektator.Text             = "🎥 Spek"
btnSpektator.TextColor3       = Color3.new(1,1,1)
btnSpektator.Font             = Enum.Font.GothamBold
btnSpektator.TextSize         = 10
btnSpektator.AutoButtonColor  = false
btnSpektator.ZIndex           = 27
Instance.new("UICorner", btnSpektator).CornerRadius = UDim.new(0,6)

local btnTPHim = Instance.new("TextButton", apFrame)
btnTPHim.Size             = UDim2.new(0.5,-6,0,26)
btnTPHim.Position         = UDim2.new(0.5,2,0,45)
btnTPHim.BackgroundColor3 = Color3.fromRGB(140,60,0)
btnTPHim.Text             = "⚡TP to Him"
btnTPHim.TextColor3       = Color3.new(1,1,1)
btnTPHim.Font             = Enum.Font.GothamBold
btnTPHim.TextSize         = 10
btnTPHim.AutoButtonColor  = false
btnTPHim.ZIndex           = 27
Instance.new("UICorner", btnTPHim).CornerRadius = UDim.new(0,6)

local apSep = Instance.new("Frame", apFrame)
apSep.Size             = UDim2.new(1,-16,0,1)
apSep.Position         = UDim2.new(0,8,0,74)
apSep.BackgroundColor3 = Color3.fromRGB(50,60,100)
apSep.BorderSizePixel  = 0

local apScroll = Instance.new("ScrollingFrame", apFrame)
apScroll.Size                   = UDim2.new(1,-6,1,-78)
apScroll.Position               = UDim2.new(0,3,0,78)
apScroll.BackgroundTransparency = 1
apScroll.BorderSizePixel        = 0
apScroll.ScrollBarThickness     = 3
apScroll.ScrollBarImageColor3   = Color3.fromRGB(60,130,220)
apScroll.CanvasSize             = UDim2.new(0,0,0,0)
apScroll.ZIndex                 = 26
apScroll.ClipsDescendants       = true

local function positionApPanelInitial()
    local pp  = panel.AbsolutePosition
    local ps2 = panel.AbsoluteSize
    local sx  = workspace.CurrentCamera.ViewportSize.X
    local sy  = workspace.CurrentCamera.ViewportSize.Y
    local px  = math.clamp(pp.X + ps2.X + 8, 4, sx - AP_W - 4)
    local py  = math.clamp(pp.Y, 4, sy - apFrame.AbsoluteSize.Y - 4)
    apFrame.Position = UDim2.new(0, px, 0, py)
end

local apPlayerBtns = {}

local function clearApList()
    for _, e in ipairs(apPlayerBtns) do e.btn:Destroy() end
    apPlayerBtns = {}
end

local function buildApList()
    clearApList()
    local plrs = Players:GetPlayers()
    local yy   = 2
    local ROW  = AP_BTN_H + AP_GAP
    for _, plr in ipairs(plrs) do
        if plr == LocalPlayer then continue end
        local btn = Instance.new("TextButton", apScroll)
        btn.Size             = UDim2.new(1,-6,0,AP_BTN_H)
        btn.Position         = UDim2.new(0,3,0,yy)
        btn.BackgroundColor3 = (targetPlayer == plr) and Color3.fromRGB(30,90,180) or Color3.fromRGB(28,32,52)
        btn.Text             = plr.Name
        btn.TextColor3       = Color3.new(1,1,1)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 10
        btn.AutoButtonColor  = false
        btn.TextTruncate     = Enum.TextTruncate.AtEnd
        btn.ZIndex           = 27
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

        local entry = { btn=btn, playerObj=plr }
        table.insert(apPlayerBtns, entry)

        btn.MouseButton1Click:Connect(function()
            if isSpektating then stopSpektator() end
            if targetPlayer == plr then
                -- Unselect: kembalikan ke player sendiri
                targetPlayer = nil
                apInfoLbl.Text = "Target: dirimu sendiri"
                lblStatus.Text = "Target: kembali ke player sendiri"
            else
                targetPlayer = plr
                apInfoLbl.Text = "Target: " .. plr.Name
                lblStatus.Text = "Target: " .. plr.Name
            end
            for _, e in ipairs(apPlayerBtns) do
                e.btn.BackgroundColor3 = (e.playerObj == targetPlayer)
                    and Color3.fromRGB(30,90,180) or Color3.fromRGB(28,32,52)
            end
            if currentMode ~= "none" then restartMode() end
            setButtonStates()
        end)

        yy = yy + ROW
    end
    apScroll.CanvasSize = UDim2.new(0,0,0, yy + 2)
end

local function openApPanel()
    apPanelOpen = true
    buildApList()
    if isSpektating then
        btnSpektator.BackgroundColor3 = Color3.fromRGB(180,30,30)
        btnSpektator.Text = "⏹ Stop Spek"
    else
        btnSpektator.BackgroundColor3 = Color3.fromRGB(20,80,160)
        btnSpektator.Text = "🎥 Spek"
    end
    if targetPlayer and targetPlayer.Parent then
        apInfoLbl.Text = "Target: " .. targetPlayer.Name
    else
        apInfoLbl.Text = "Belum ada target"
    end
    if not apFrame.Visible then
        positionApPanelInitial()
    end
    apFrame.Visible = true
end

closeApPanel = function()
    apPanelOpen = false
    apFrame.Visible = false
end

apBtnClose.MouseButton1Click:Connect(function()
    closeApPanel()
end)

Players.PlayerAdded:Connect(function()
    if apPanelOpen then buildApList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if targetPlayer == plr then
        targetPlayer = nil
        apInfoLbl.Text = "Target keluar!"
        if isSpektating then stopSpektator() end
        stopLoop()
        currentMode = "none"
        setButtonStates()
        lblStatus.Text = "Target player keluar"
    end
    if apPanelOpen then buildApList() end
end)

stopSpektator = function()
    isSpektating = false
    Camera.CameraSubject = getHumanoid()
    btnSpektator.BackgroundColor3 = Color3.fromRGB(20,80,160)
    btnSpektator.Text = "🎥 Spek"
    lblStatus.Text = "Spektator: berhenti"
end

btnSpektator.MouseButton1Click:Connect(function()
    if isSpektating then
        stopSpektator(); return
    end
    if not targetPlayer or not targetPlayer.Parent then
        lblStatus.Text = "Pilih player dulu!"; return
    end
    local char = targetPlayer.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum then
        isSpektating = true
        Camera.CameraSubject = hum
        lblStatus.Text = "Spektator: " .. targetPlayer.Name
        btnSpektator.BackgroundColor3 = Color3.fromRGB(180,30,30)
        btnSpektator.Text = "⏹ Stop Spek"
    end
end)

btnTPHim.MouseButton1Click:Connect(function()
    if not targetPlayer or not targetPlayer.Parent then
        lblStatus.Text = "Pilih player dulu!"; return
    end
    local char = targetPlayer.Character
    local tHrp = char and char:FindFirstChild("HumanoidRootPart")
    local myHrp = getHRP()
    if tHrp and myHrp then
        pcall(function()
            myHrp.CFrame = tHrp.CFrame + Vector3.new(2, 0, 0)
        end)
        lblStatus.Text = "TP ke: " .. targetPlayer.Name
        btnTPHim.BackgroundColor3 = Color3.fromRGB(200,100,0)
        task.delay(0.4, function() btnTPHim.BackgroundColor3 = Color3.fromRGB(140,60,0) end)
    end
end)

btnAnotherPlayer.MouseButton1Click:Connect(function()
    if apPanelOpen then
        closeApPanel()
    else
        openApPanel()
    end
end)

-- ══════════════════════════════════════
--   AUTO COLOR (dulu Auto RGB)
--   Setiap giliran: pilih 1 warna solid, ubah tenda satu-satu
--   Setelah semua tenda warna itu → pilih warna berikutnya
-- ══════════════════════════════════════
local AUTO_COLORS = {
    Color3.fromRGB(255, 50,  50),   -- merah
    Color3.fromRGB(255, 150, 20),   -- oranye
    Color3.fromRGB(255, 230, 0),    -- kuning
    Color3.fromRGB(50,  220, 50),   -- hijau
    Color3.fromRGB(0,   180, 255),  -- biru muda
    Color3.fromRGB(60,  60,  255),  -- biru
    Color3.fromRGB(180, 0,   255),  -- ungu
    Color3.fromRGB(255, 0,   180),  -- pink
    Color3.fromRGB(255, 255, 255),  -- putih
}
local autoColorIndex    = 1   -- index warna sekarang di AUTO_COLORS
local autoColorTentIdx  = 1   -- giliran tenda mana yang akan dicat
local autoColorAllDone  = false  -- semua tenda sudah satu warna?

stopAutoRGB = function()
    autoRGBActive = false
    if autoRGBConn then autoRGBConn:Disconnect(); autoRGBConn = nil end
    setButtonStates()
end

local function startAutoRGB()
    autoRGBActive   = true
    autoColorIndex  = 1
    autoColorTentIdx= 1
    autoColorAllDone= false
    if autoRGBConn then autoRGBConn:Disconnect() end

    -- Pakai task.spawn loop biar bisa task.wait antar tenda
    autoRGBConn = nil
    task.spawn(function()
        while autoRGBActive do
            local n = #tentFolders
            if n == 0 then task.wait(0.5); continue end

            local col = AUTO_COLORS[autoColorIndex]

            -- Cat tenda satu demi satu
            for idx = 1, n do
                if not autoRGBActive then break end
                local f = tentFolders[idx]
                if f and f.Parent then
                    pcall(function()
                        f.ChangePropColor:InvokeServer(col)
                    end)
                end
                task.wait(0.25)  -- jeda antar tenda ~0.25 detik
            end

            if not autoRGBActive then break end

            -- Semua tenda sudah satu warna, delay sebentar lalu ganti warna
            task.wait(1.2)

            autoColorIndex = (autoColorIndex % #AUTO_COLORS) + 1
        end
    end)

    setButtonStates()
end

btnAutoRGB.MouseButton1Click:Connect(function()
    if autoRGBActive then
        stopAutoRGB()
        lblStatus.Text = "Auto Color: OFF"
    else
        startAutoRGB()
        lblStatus.Text = "Auto Color: ON 🎨"
    end
end)

-- ══════════════════════════════════════
--   SET MODE
-- ══════════════════════════════════════
local function setMode(newMode)
    closeList()

    if newMode == "bahlil" then
        openBahlilPanel()
        return
    end

    if currentMode == newMode then
        currentMode = "none"; stopLoop(); tentFolders = {}
        lblStatus.Text = "Status: idle"; setButtonStates(); return
    end
    stopLoop(); tentFolders = {}

    if newMode == "ekor" then
        ekorHistory = {}
    end
    if newMode == "games" then
        gamesPositions = {}; gamesSides = {}; gamesSwapTimer = 0
    end
    if newMode == "wings" then
        wingsPositions = {}; wingsAngle = 0
    end
    if newMode == "mahkota" then
        mahkotaAngle = 0
    end
    if newMode == "bodyside" then
        bodySideSides={}; bodySidePositions={}; bodySideOrbit={}; bodySideSwapTimer=0
    end

    currentMode = newMode
    TOTAL_TENTS = modeTentCount[newMode] or 2
    local ok = refreshTents(TOTAL_TENTS)
    if not ok then
        lblStatus.Text = "Letakkan minimal 1 tenda dulu!"
        currentMode = "none"; setButtonStates(); return
    end
    local target = ballFollowActive and "bola" or (targetPlayer and targetPlayer.Name) or "player"
    lblStatus.Text = string.format("%s aktif – %d tenda → %s", newMode, #tentFolders, target)
    startLoop(); setButtonStates()
end

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

restartMode = function()
    if currentMode ~= "none" then
        local saved = currentMode
        stopLoop(); tentFolders = {}
        currentMode = saved
        TOTAL_TENTS = modeTentCount[saved] or 2
        if refreshTents(TOTAL_TENTS) then startLoop() end
        local tgt = ballFollowActive and "bola" or (targetPlayer and targetPlayer.Name) or "player"
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
    stopLoop(); stopBallLoop(); destroyBall(); stopBahlilCycle(); stopAutoRGB()
    ballFollowActive = false; currentMode = "none"
    targetPlayer = nil
    closeApPanel()
    tentFolders = {}; verticalMove = 0
    ekorHistory = {}
    gamesPositions = {}; gamesSides = {}; gamesSwapTimer = 0
    wingsPositions = {}; wingsAngle = 0
    mahkotaAngle = 0
    bodySideSides={}; bodySidePositions={}; bodySideOrbit={}; bodySideSwapTimer=0
    task.wait(1)
    Camera.CameraSubject = newChar:WaitForChild("Humanoid")
    lblStatus.Text = "Status: respawned"
    setButtonStates()
end)

print("[OK] Tent Orbit v6.3 loaded –", PLAYER_NAME)
