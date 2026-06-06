-- ══════════════════════════════════════
--   BmSkyMods  |  by BmSky
--   v2: bring all cek kendaraan, log "already veh",
--       panel Car Throw Up dengan spektator + car throw
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Camera            = workspace.CurrentCamera

-- ── State ─────────────────────────────
local savedPos      = nil
local isBringingAll = false
local isEspOn       = false
local espObjects    = {}

-- Player Action state (panel lama)
local selectedPlayer  = nil
local isBanging       = false
local isSpectating    = false
local dropdownOpen    = false
local selectedMode    = "lari gila"
local modeOptions     = { "lari gila", "kanan 1000", "kiri 1000" }
local playerButtons   = {}

-- Car Throw panel state
local ctSelectedPlayer   = nil
local isCarThrowSpek     = false
local isCarThrowing      = false
local ctPlayerButtons    = {}

-- ── Passenger / vehicle config ────────
local DETECT_RADIUS   = 20
local DRIVER_KEYWORDS = {"driver","kemudi","pengemudi","supir","main","utama","steering","control"}

local function IsPassengerSeat(seat)
    if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then return false end
    if seat.Occupant ~= nil then return false end
    local n = seat.Name:lower()
    for _, kw in ipairs(DRIVER_KEYWORDS) do
        if n:find(kw) then return false end
    end
    return true
end

local function GetNearestPassengerSeat(hrp)
    local nearest, minDist = nil, DETECT_RADIUS
    for _, m in pairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LocalPlayer.Character then
            for _, s in pairs(m:GetDescendants()) do
                if IsPassengerSeat(s) then
                    local d = (hrp.Position - s.Position).Magnitude
                    if d < minDist then minDist = d; nearest = s end
                end
            end
        end
    end
    return nearest
end

-- Cek apakah player sedang dalam kendaraan (nyetir atau penumpang)
local function IsInVehicle()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.SeatPart ~= nil
end

-- Cari semua seat (termasuk driver) dalam radius
local function GetNearestAnySeat(hrp)
    local nearest, minDist = nil, DETECT_RADIUS
    for _, m in pairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LocalPlayer.Character then
            for _, s in pairs(m:GetDescendants()) do
                if (s:IsA("VehicleSeat") or s:IsA("Seat")) and s.Occupant == nil then
                    local d = (hrp.Position - s.Position).Magnitude
                    if d < minDist then minDist = d; nearest = s end
                end
            end
        end
    end
    return nearest
end

-- ══════════════════════════════════════
--   GUI ROOT
-- ══════════════════════════════════════
if PlayerGui:FindFirstChild("BmSkyGui") then
    PlayerGui.BmSkyGui:Destroy()
end

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name           = "BmSkyGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

-- ══════════════════════════════════════
--   WARNA TEMA
-- ══════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(15, 15, 20),
    Header     = Color3.fromRGB(28, 18, 55),
    HeaderText = Color3.fromRGB(200, 170, 255),
    Separator  = Color3.fromRGB(50, 42, 80),
    BtnDefault = Color3.fromRGB(55, 45, 95),
    BtnHover   = Color3.fromRGB(80, 65, 135),
    BtnGreen   = Color3.fromRGB(28, 105, 55),
    BtnBlue    = Color3.fromRGB(22, 65, 130),
    BtnPurple  = Color3.fromRGB(72, 32, 140),
    BtnTeal    = Color3.fromRGB(18, 95, 100),
    BtnGold    = Color3.fromRGB(120, 78, 8),
    BtnRed     = Color3.fromRGB(155, 28, 28),
    BtnOrange  = Color3.fromRGB(170, 80, 10),
    Text       = Color3.fromRGB(220, 220, 230),
    TextDim    = Color3.fromRGB(130, 125, 158),
    TextGreen  = Color3.fromRGB(90, 245, 140),
    TextYellow = Color3.fromRGB(255, 210, 70),
    Accent     = Color3.fromRGB(130, 85, 230),
    ScrollBar  = Color3.fromRGB(70, 55, 120),
}

-- ══════════════════════════════════════
--   NOTIFIKASI
-- ══════════════════════════════════════
local notifFrame = Instance.new("Frame", gui)
notifFrame.Size             = UDim2.new(0, 220, 0, 36)
notifFrame.Position         = UDim2.new(0.5, -110, 0, -50)
notifFrame.BackgroundColor3 = C.BG
notifFrame.BackgroundTransparency = 0.05
notifFrame.BorderSizePixel  = 0
notifFrame.ZIndex           = 40
notifFrame.Visible          = false
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 5)
local nfStroke = Instance.new("UIStroke", notifFrame)
nfStroke.Color = C.Accent; nfStroke.Thickness = 1.2

local notifText = Instance.new("TextLabel", notifFrame)
notifText.Size             = UDim2.new(1, -10, 1, 0)
notifText.Position         = UDim2.new(0, 5, 0, 0)
notifText.BackgroundTransparency = 1
notifText.Text             = ""
notifText.TextColor3       = C.Text
notifText.Font             = Enum.Font.Gotham
notifText.TextSize         = 12
notifText.TextXAlignment   = Enum.TextXAlignment.Center
notifText.ZIndex           = 41

local notifCancel = nil
local function showNotif(msg, isGood)
    if notifCancel then pcall(function() task.cancel(notifCancel) end) end
    notifText.Text     = msg
    nfStroke.Color     = isGood and Color3.fromRGB(45,195,85) or Color3.fromRGB(205,50,50)
    notifFrame.Visible = true
    notifFrame.Position = UDim2.new(0.5,-110,0,-50)
    TweenService:Create(notifFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5,-110,0,58)}):Play()
    notifCancel = task.delay(2.2, function()
        TweenService:Create(notifFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5,-110,0,-50)}):Play()
        task.wait(0.22)
        notifFrame.Visible = false
    end)
end

-- ══════════════════════════════════════
--   MAIN WINDOW
-- ══════════════════════════════════════
local WIN_W   = 175
local WIN_H   = 215
local ROW_H   = 26
local PAD     = 5
local TITLE_H = 22

local win = Instance.new("Frame", gui)
win.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
win.Position         = UDim2.new(0, 16, 0.28, 0)
win.BackgroundColor3 = C.BG
win.BorderSizePixel  = 0
win.ZIndex           = 10
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color = C.Separator; winStroke.Thickness = 1

local titleBar = Instance.new("TextButton", win)
titleBar.Size             = UDim2.new(1, 0, 0, TITLE_H)
titleBar.Position         = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = C.Header
titleBar.Text             = ""
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 12
titleBar.AutoButtonColor  = false
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 6)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size             = UDim2.new(1, -26, 1, 0)
titleText.Position         = UDim2.new(0, 8, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text             = "BmSkyMods"
titleText.TextColor3       = C.HeaderText
titleText.Font             = Enum.Font.GothamBold
titleText.TextSize         = 12
titleText.TextXAlignment   = Enum.TextXAlignment.Left
titleText.ZIndex           = 13

local collapseIco = Instance.new("TextLabel", titleBar)
collapseIco.Size             = UDim2.new(0, 18, 1, 0)
collapseIco.Position         = UDim2.new(1, -20, 0, 0)
collapseIco.BackgroundTransparency = 1
collapseIco.Text             = "-"
collapseIco.TextColor3       = C.TextDim
collapseIco.Font             = Enum.Font.GothamBold
collapseIco.TextSize         = 14
collapseIco.ZIndex           = 13

local SCROLL_H = WIN_H - TITLE_H
local scrollFrame = Instance.new("ScrollingFrame", win)
scrollFrame.Size                = UDim2.new(1, 0, 0, SCROLL_H)
scrollFrame.Position            = UDim2.new(0, 0, 0, TITLE_H)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel     = 0
scrollFrame.ZIndex              = 11
scrollFrame.ScrollBarThickness  = 3
scrollFrame.ScrollBarImageColor3 = C.ScrollBar
scrollFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ElasticBehavior     = Enum.ElasticBehavior.Never

local function makeSep(yPos)
    local sep = Instance.new("Frame", scrollFrame)
    sep.Size             = UDim2.new(1, -10, 0, 1)
    sep.Position         = UDim2.new(0, 5, 0, yPos)
    sep.BackgroundColor3 = C.Separator
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 12
    return sep
end

local function makeLabel(yPos, txt, color)
    local lbl = Instance.new("TextLabel", scrollFrame)
    lbl.Size             = UDim2.new(1, -10, 0, 14)
    lbl.Position         = UDim2.new(0, 5, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text             = txt
    lbl.TextColor3       = color or C.TextDim
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 12
    return lbl
end

local function makeBtn(yPos, txt, bg)
    local b = Instance.new("TextButton", scrollFrame)
    b.Size             = UDim2.new(1, -10, 0, ROW_H)
    b.Position         = UDim2.new(0, 5, 0, yPos)
    b.BackgroundColor3 = bg or C.BtnDefault
    b.Text             = txt
    b.TextColor3       = C.Text
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.BorderSizePixel  = 0
    b.ZIndex           = 12
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local origBg = bg or C.BtnDefault
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=C.BtnHover}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=origBg}):Play()
    end)
    return b
end

local Y = PAD
-- Weapon
makeSep(Y); Y = Y + 3
makeLabel(Y, "  Weapon", C.TextDim); Y = Y + 14
local btnGetW = makeBtn(Y, "getW", C.BtnGreen); Y = Y + ROW_H + PAD

-- Position
makeSep(Y); Y = Y + 3
makeLabel(Y, "  Position", C.TextDim); Y = Y + 14
local btnSavePos = makeBtn(Y, "save pos",  C.BtnBlue);   Y = Y + ROW_H + 4
local btnTpToPos = makeBtn(Y, "tp to pos", C.BtnGold);   Y = Y + ROW_H + PAD

-- Players
makeSep(Y); Y = Y + 3
makeLabel(Y, "  Players", C.TextDim); Y = Y + 14
local btnBringAll = makeBtn(Y, "bring all", C.BtnPurple); Y = Y + ROW_H + 4
local btnEspAll   = makeBtn(Y, "esp all",   C.BtnTeal);   Y = Y + ROW_H + PAD

-- Status
makeSep(Y); Y = Y + 3
local lblStatus = makeLabel(Y, "", C.TextGreen); Y = Y + 14 + PAD

-- Player Actions panel button
makeSep(Y); Y = Y + 3
makeLabel(Y, "  Player Actions", C.TextDim); Y = Y + 14
local btnOpenPlayerPanel = makeBtn(Y, "Player List", C.BtnPurple); Y = Y + ROW_H + 4

-- Car Throw panel button
local btnOpenCarThrow = makeBtn(Y, "Car Throw Up", C.BtnOrange); Y = Y + ROW_H + PAD

-- ══════════════════════════════════════
--   HELPER: Buat panel detached (draggable)
-- ══════════════════════════════════════
local function makeDraggablePanel(title, posX, posY, w, zIdx, headerColor, strokeColor)
    local panel = Instance.new("Frame", gui)
    panel.Size             = UDim2.new(0, w, 0, 0)
    panel.Position         = UDim2.new(0, posX, 0, posY)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    panel.BorderSizePixel  = 0
    panel.Visible          = false
    panel.ZIndex           = zIdx
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = strokeColor or Color3.fromRGB(90, 50, 160)

    local hdr = Instance.new("TextLabel", panel)
    hdr.Size             = UDim2.new(1, 0, 0, 26)
    hdr.BackgroundColor3 = headerColor or Color3.fromRGB(75, 45, 120)
    hdr.Text             = title
    hdr.TextColor3       = Color3.new(1, 1, 1)
    hdr.Font             = Enum.Font.GothamBold
    hdr.TextScaled       = true
    hdr.BorderSizePixel  = 0
    hdr.ZIndex           = zIdx + 1
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 10)

    -- drag
    do
        local dragging, dStart, wStart = false, nil, nil
        hdr.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dStart = inp.Position; wStart = panel.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        hdr.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - dStart
                panel.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X,
                                           wStart.Y.Scale, wStart.Y.Offset + d.Y)
            end
        end)
    end

    return panel, hdr
end

-- ══════════════════════════════════════
--   PLAYER ACTION PANEL (panel lama)
-- ══════════════════════════════════════
local playerPanel, pHeader = makeDraggablePanel(
    "Players", 20, 360, 180, 20,
    Color3.fromRGB(75, 45, 120), Color3.fromRGB(90, 50, 160)
)

local pScroller = Instance.new("ScrollingFrame", playerPanel)
pScroller.Size                 = UDim2.new(1, -8, 1, -84)
pScroller.Position             = UDim2.new(0, 4, 0, 82)
pScroller.CanvasSize           = UDim2.new(0, 0, 0, 0)
pScroller.ScrollBarThickness   = 4
pScroller.ScrollBarImageColor3 = Color3.fromRGB(160, 80, 255)
pScroller.BackgroundTransparency = 1
pScroller.ZIndex               = 21

local pLayout = Instance.new("UIListLayout", pScroller)
pLayout.Padding       = UDim.new(0, 3)
pLayout.SortOrder     = Enum.SortOrder.Name
pLayout.FillDirection = Enum.FillDirection.Vertical

local function updatePanelCanvas()
    task.wait(0.05)
    pScroller.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 6)
end

local function addPlayerBtn(plr)
    if plr == LocalPlayer then return end
    if playerButtons[plr.Name] then return end
    local btn = Instance.new("TextButton", pScroller)
    btn.Size             = UDim2.new(1, -4, 0, 26)
    btn.Text             = plr.Name
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.Font             = Enum.Font.Gotham
    btn.TextScaled       = true
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 22
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        if selectedPlayer == plr then
            selectedPlayer = nil
            if isSpectating then
                isSpectating = false
                local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                Camera.CameraType    = Enum.CameraType.Custom
                Camera.CameraSubject = myHum
            end
        else
            selectedPlayer = plr
        end
        for _, data in pairs(playerButtons) do
            if data.btn and data.btn.Parent then
                data.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
            end
        end
        if selectedPlayer then
            btn.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
        end
    end)
    playerButtons[plr.Name] = { btn = btn, player = plr }
    updatePanelCanvas()
end

local function removePlayerBtn(plr)
    local data = playerButtons[plr.Name]
    if data then
        if data.btn and data.btn.Parent then data.btn:Destroy() end
        playerButtons[plr.Name] = nil
    end
    if selectedPlayer == plr then
        selectedPlayer = nil
        if isSpectating then
            isSpectating = false
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType    = Enum.CameraType.Custom
            Camera.CameraSubject = myHum
        end
    end
    updatePanelCanvas()
end

for _, plr in ipairs(Players:GetPlayers()) do addPlayerBtn(plr) end
Players.PlayerAdded:Connect(addPlayerBtn)
Players.PlayerRemoving:Connect(removePlayerBtn)

-- Dropdown mode
local btnMode = Instance.new("TextButton", playerPanel)
btnMode.Size             = UDim2.new(1, -12, 0, 22)
btnMode.Position         = UDim2.new(0, 6, 0, 28)
btnMode.Text             = "▾  " .. selectedMode
btnMode.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
btnMode.TextColor3       = Color3.fromRGB(200, 180, 255)
btnMode.Font             = Enum.Font.GothamBold
btnMode.TextScaled       = true
btnMode.BorderSizePixel  = 0
btnMode.ZIndex           = 22
Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0, 6)

local dropFrame = Instance.new("Frame", playerPanel)
dropFrame.Size             = UDim2.new(1, -12, 0, #modeOptions * 24 + 4)
dropFrame.Position         = UDim2.new(0, 6, 0, 52)
dropFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
dropFrame.BorderSizePixel  = 0
dropFrame.Visible          = false
dropFrame.ZIndex           = 25
dropFrame.ClipsDescendants = false
Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", dropFrame).Color = Color3.fromRGB(120, 70, 200)

for i, opt in ipairs(modeOptions) do
    local ob = Instance.new("TextButton", dropFrame)
    ob.Size             = UDim2.new(1, -4, 0, 22)
    ob.Position         = UDim2.new(0, 2, 0, (i-1)*24 + 2)
    ob.Text             = opt
    ob.BackgroundColor3 = Color3.fromRGB(40, 40, 62)
    ob.TextColor3       = Color3.new(1, 1, 1)
    ob.Font             = Enum.Font.Gotham
    ob.TextScaled       = true
    ob.BorderSizePixel  = 0
    ob.ZIndex           = 26
    Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 5)
    ob.MouseButton1Click:Connect(function()
        selectedMode = opt
        btnMode.Text = "▾  " .. opt
        dropFrame.Visible = false
        dropdownOpen = false
        btnMode.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
    end)
end

btnMode.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    dropFrame.Visible = dropdownOpen
    btnMode.BackgroundColor3 = dropdownOpen and Color3.fromRGB(80, 55, 130) or Color3.fromRGB(50, 50, 75)
end)

-- Action buttons panel lama
local function makeActionBtn(parent, x, y, w, h, text, color, zIdx)
    local b = Instance.new("TextButton", parent)
    b.Size             = UDim2.new(0, w, 0, h)
    b.Position         = UDim2.new(0, x, 0, y)
    b.Text             = text
    b.BackgroundColor3 = color
    b.TextColor3       = Color3.new(1, 1, 1)
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.BorderSizePixel  = 0
    b.ZIndex           = zIdx or 22
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local btnBang   = makeActionBtn(playerPanel, 6,  56, 48, 26, "bang",      Color3.fromRGB(210, 40, 40))
local btnSpek   = makeActionBtn(playerPanel, 60, 56, 70, 26, "spektator", Color3.fromRGB(30, 90, 180))
local btnTpHim  = makeActionBtn(playerPanel, 136,56, 38, 26, "tp",        Color3.fromRGB(160, 100, 20))

local playerPanelOpen = false
btnOpenPlayerPanel.MouseButton1Click:Connect(function()
    playerPanelOpen = not playerPanelOpen
    if playerPanelOpen then
        playerPanel.Visible = true
        TweenService:Create(playerPanel,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 180, 0, 220) }):Play()
    else
        TweenService:Create(playerPanel,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 180, 0, 0) }):Play()
        task.delay(0.16, function() playerPanel.Visible = false end)
    end
end)

-- ══════════════════════════════════════
--   CAR THROW UP PANEL (baru)
-- ══════════════════════════════════════
local ctPanel, ctPanelHdr = makeDraggablePanel(
    "Car Throw Up", 210, 200, 185, 30,
    Color3.fromRGB(120, 55, 10), Color3.fromRGB(200, 100, 20)
)

-- Label status car throw
local ctStatus = Instance.new("TextLabel", ctPanel)
ctStatus.Size             = UDim2.new(1, -12, 0, 14)
ctStatus.Position         = UDim2.new(0, 6, 0, 30)
ctStatus.BackgroundTransparency = 1
ctStatus.Text             = "select player dulu"
ctStatus.TextColor3       = C.TextDim
ctStatus.Font             = Enum.Font.Gotham
ctStatus.TextSize         = 10
ctStatus.TextXAlignment   = Enum.TextXAlignment.Left
ctStatus.ZIndex           = 31

-- List player (scroll)
local ctScroller = Instance.new("ScrollingFrame", ctPanel)
ctScroller.Size                 = UDim2.new(1, -8, 0, 100)
ctScroller.Position             = UDim2.new(0, 4, 0, 48)
ctScroller.CanvasSize           = UDim2.new(0, 0, 0, 0)
ctScroller.ScrollBarThickness   = 4
ctScroller.ScrollBarImageColor3 = Color3.fromRGB(200, 100, 30)
ctScroller.BackgroundColor3     = Color3.fromRGB(12, 12, 20)
ctScroller.BackgroundTransparency = 0.3
ctScroller.ZIndex               = 31
Instance.new("UICorner", ctScroller).CornerRadius = UDim.new(0, 6)

local ctLayout = Instance.new("UIListLayout", ctScroller)
ctLayout.Padding       = UDim.new(0, 3)
ctLayout.SortOrder     = Enum.SortOrder.Name
ctLayout.FillDirection = Enum.FillDirection.Vertical

local function ctUpdateCanvas()
    task.wait(0.05)
    ctScroller.CanvasSize = UDim2.new(0, 0, 0, ctLayout.AbsoluteContentSize.Y + 6)
end

local function ctAddPlayerBtn(plr)
    if plr == LocalPlayer then return end
    if ctPlayerButtons[plr.Name] then return end
    local btn = Instance.new("TextButton", ctScroller)
    btn.Size             = UDim2.new(1, -4, 0, 24)
    btn.Text             = plr.Name
    btn.BackgroundColor3 = Color3.fromRGB(40, 30, 15)
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.Font             = Enum.Font.Gotham
    btn.TextScaled       = true
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 32
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function()
        ctSelectedPlayer = (ctSelectedPlayer == plr) and nil or plr
        -- reset warna semua
        for _, data in pairs(ctPlayerButtons) do
            if data.btn and data.btn.Parent then
                data.btn.BackgroundColor3 = Color3.fromRGB(40, 30, 15)
            end
        end
        if ctSelectedPlayer then
            btn.BackgroundColor3 = Color3.fromRGB(180, 80, 10)
            ctStatus.Text = "target: " .. plr.Name
            ctStatus.TextColor3 = C.TextYellow
        else
            ctStatus.Text = "select player dulu"
            ctStatus.TextColor3 = C.TextDim
        end
    end)
    ctPlayerButtons[plr.Name] = { btn = btn, player = plr }
    ctUpdateCanvas()
end

local function ctRemovePlayerBtn(plr)
    local data = ctPlayerButtons[plr.Name]
    if data then
        if data.btn and data.btn.Parent then data.btn:Destroy() end
        ctPlayerButtons[plr.Name] = nil
    end
    if ctSelectedPlayer == plr then
        ctSelectedPlayer = nil
        if isCarThrowSpek then
            isCarThrowSpek = false
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType    = Enum.CameraType.Custom
            Camera.CameraSubject = myHum
        end
        ctStatus.Text = "select player dulu"
        ctStatus.TextColor3 = C.TextDim
    end
    ctUpdateCanvas()
end

for _, plr in ipairs(Players:GetPlayers()) do ctAddPlayerBtn(plr) end
Players.PlayerAdded:Connect(ctAddPlayerBtn)
Players.PlayerRemoving:Connect(ctRemovePlayerBtn)

-- Tombol aksi car throw
local btnCtSpek  = makeActionBtn(ctPanel, 6,  154, 82, 26, "spektator",   Color3.fromRGB(30, 90, 180), 31)
local btnCtThrow = makeActionBtn(ctPanel, 95, 154, 84, 26, "car throw",   Color3.fromRGB(170, 60, 10), 31)

local ctPanelOpen = false
btnOpenCarThrow.MouseButton1Click:Connect(function()
    ctPanelOpen = not ctPanelOpen
    if ctPanelOpen then
        ctPanel.Visible = true
        TweenService:Create(ctPanel,
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 185, 0, 190) }):Play()
    else
        TweenService:Create(ctPanel,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 185, 0, 0) }):Play()
        task.delay(0.16, function() ctPanel.Visible = false end)
    end
end)

-- ══════════════════════════════════════
--   HELPER FUNCTIONS
-- ══════════════════════════════════════
local function isToolEquipped()
    local c = LocalPlayer.Character; if not c then return false end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    return false
end

local function equipTool()
    local c   = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum or isToolEquipped() then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then hum:EquipTool(v); task.wait(0.08); return end
        end
    end
end

local function unequipTool(hum)
    if not hum then return end
    local t = 0
    while isToolEquipped() and t < 0.4 do
        pcall(function() hum:UnequipTools() end)
        task.wait(0.04); t = t + 0.04
    end
end

local function equipToolIfNeeded()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then hum:EquipTool(v); task.wait(0.15); return true end
        end
    end
    return false
end

-- Spin di posisi player target (real time ngikutin target)
local function doSpin(myHRP, targetHRP, duration)
    if not myHRP or not targetHRP then return end
    local startT = tick()
    local angle  = 0
    local SPEED  = math.pi * 14
    while true do
        local dt = tick() - startT
        if dt >= duration then break end
        angle = angle + SPEED * (1/60)
        local h = targetHRP.Parent and targetHRP.Parent:FindFirstChild("HumanoidRootPart")
        local pos = h and h.Position or targetHRP.Position
        pcall(function()
            myHRP.CFrame = CFrame.new(pos) * CFrame.Angles(0, angle, 0)
        end)
        task.wait(1/60)
    end
end

-- Spin di CFrame pos (untuk balik ke savedPos sambil muter)
local function doSpinAtPos(myHRP, targetCF, duration)
    if not myHRP or not targetCF then return end
    local startT = tick()
    local angle  = 0
    local SPEED  = math.pi * 14
    local pos    = targetCF.Position
    while true do
        local dt = tick() - startT
        if dt >= duration then break end
        angle = angle + SPEED * (1/60)
        pcall(function()
            myHRP.CFrame = CFrame.new(pos) * CFrame.Angles(0, angle, 0)
        end)
        task.wait(1/60)
    end
    pcall(function() myHRP.CFrame = targetCF end)
end

-- Dudukkan player di kendaraan (spawn baru atau yang sudah ada)
-- Kembalikan true jika berhasil duduk
local function ensureSeated(myChar, myHRP, myHum, lblLog)
    -- Cek sudah duduk
    if myHum.SeatPart ~= nil then
        if lblLog then lblLog.Text = "already veh"; lblLog.TextColor3 = Color3.fromRGB(90, 255, 200) end
        showNotif("already veh ✓", true)
        return true
    end
    -- Cek ada kendaraan di sekitar (mungkin baru spawn tapi belum duduk)
    local seat = GetNearestAnySeat(myHRP)
    if seat then
        if lblLog then lblLog.Text = "duduk di veh..." end
        pcall(function() myHRP.CFrame = seat.CFrame * CFrame.new(0,1.5,0) end)
        task.wait(0.15)
        pcall(function() seat:Sit(myHum) end)
        task.wait(0.3)
        if myHum.SeatPart ~= nil then
            if lblLog then lblLog.Text = "duduk ✓" end
            return true
        end
    end
    -- Perlu spawn baru
    if lblLog then lblLog.Text = "hapus kendaraan..." end
    pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("DeleteAllVehicles") end)
    task.wait(1.2)
    if lblLog then lblLog.Text = "spawn Bus..." end
    pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("PickingCar","Bus","Work") end)
    task.wait(2.5)
    -- Coba duduk
    local attempt = 0
    local seated  = false
    while not seated and attempt < 20 do
        attempt = attempt + 1
        myChar = LocalPlayer.Character
        myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if myChar and myHRP and myHum then
            local s = GetNearestPassengerSeat(myHRP)
            if s then
                if lblLog then lblLog.Text = "masuk kursi..." end
                pcall(function() myHRP.CFrame = s.CFrame * CFrame.new(0,1.5,0) end)
                task.wait(0.15)
                pcall(function() s:Sit(myHum) end)
                task.wait(0.3)
                if myHum.Sit or myHum.SeatPart ~= nil then seated = true end
            else task.wait(0.5) end
        else task.wait(0.4) end
    end
    if lblLog then
        if seated then
            lblLog.Text = "duduk ✓"; lblLog.TextColor3 = C.TextGreen
        else
            lblLog.Text = "gagal masuk veh"; lblLog.TextColor3 = Color3.fromRGB(255,90,90)
        end
    end
    return seated
end

-- ══════════════════════════════════════
--   getW
-- ══════════════════════════════════════
btnGetW.MouseButton1Click:Connect(function()
    pcall(function() ReplicatedStorage.RE["1Too1l"]:InvokeServer("PickingTools","Couch") end)
    btnGetW.BackgroundColor3 = Color3.fromRGB(48,195,105)
    task.wait(0.2)
    btnGetW.BackgroundColor3 = C.BtnGreen
    showNotif("Item diambil!", true)
end)

-- ══════════════════════════════════════
--   Save Pos / TP to Pos
-- ══════════════════════════════════════
btnSavePos.MouseButton1Click:Connect(function()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then showNotif("Karakter belum siap", false); return end
    savedPos = myHRP.CFrame
    btnSavePos.BackgroundColor3 = Color3.fromRGB(48,125,215)
    showNotif("Posisi disimpan!", true)
    task.wait(0.3)
    btnSavePos.BackgroundColor3 = C.BtnBlue
end)

btnTpToPos.MouseButton1Click:Connect(function()
    if not savedPos then showNotif("Belum ada pos tersimpan", false); return end
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    pcall(function() myHRP.CFrame = savedPos end)
    task.wait(0.04)
    pcall(function() myHRP.CFrame = savedPos end)
    btnTpToPos.BackgroundColor3 = Color3.fromRGB(205,155,28)
    showNotif("Teleport ke posisi!", true)
    task.wait(0.25)
    btnTpToPos.BackgroundColor3 = C.BtnGold
end)

-- ══════════════════════════════════════
--   ESP All
-- ══════════════════════════════════════
local function addEsp(plr)
    if plr == LocalPlayer then return end
    if espObjects[plr.Name] then return end
    local function build()
        local char = plr.Character; if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        local bb = Instance.new("BillboardGui", head)
        bb.Name="BmEspDot"; bb.Size=UDim2.new(0,13,0,13)
        bb.StudsOffset=Vector3.new(0,3.2,0); bb.AlwaysOnTop=true; bb.Enabled=true
        local dot = Instance.new("Frame", bb)
        dot.Size=UDim2.new(1,0,1,0); dot.BackgroundColor3=Color3.fromRGB(0,255,80)
        dot.BorderSizePixel=0
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        local dg = Instance.new("UIStroke",dot)
        dg.Color=Color3.fromRGB(0,255,80); dg.Thickness=2.2; dg.Transparency=0.2
        local nl = Instance.new("TextLabel", bb)
        nl.Size=UDim2.new(0,80,0,15); nl.Position=UDim2.new(0.5,-40,0,-18)
        nl.BackgroundTransparency=1; nl.Text=plr.Name
        nl.TextColor3=Color3.fromRGB(80,255,130); nl.Font=Enum.Font.GothamBold
        nl.TextScaled=true; nl.BorderSizePixel=0
        local selBox = Instance.new("SelectionBox", workspace)
        selBox.Name="BmEspBox_"..plr.Name; selBox.Adornee=char
        selBox.Color3=Color3.fromRGB(0,255,80); selBox.LineThickness=0.05
        selBox.SurfaceTransparency=1; selBox.SurfaceColor3=Color3.fromRGB(0,255,80)
        espObjects[plr.Name] = {bb=bb, selBox=selBox}
    end
    if plr.Character then build() end
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        local old = espObjects[plr.Name]
        if old then pcall(function() old.bb:Destroy() end) pcall(function() old.selBox:Destroy() end) espObjects[plr.Name] = nil end
        build()
    end)
end

local function removeEsp(plr)
    local obj = espObjects[plr.Name]; if not obj then return end
    pcall(function() obj.bb:Destroy() end) pcall(function() obj.selBox:Destroy() end)
    espObjects[plr.Name] = nil
end

local function clearAllEsp()
    for name, obj in pairs(espObjects) do
        pcall(function() obj.bb:Destroy() end) pcall(function() obj.selBox:Destroy() end)
        espObjects[name] = nil
    end
end

btnEspAll.MouseButton1Click:Connect(function()
    isEspOn = not isEspOn
    if isEspOn then
        btnEspAll.BackgroundColor3 = Color3.fromRGB(18,175,115)
        btnEspAll.Text = "esp: ON"
        for _, plr in ipairs(Players:GetPlayers()) do addEsp(plr) end
        Players.PlayerAdded:Connect(function(plr) if isEspOn then task.wait(1); addEsp(plr) end end)
        Players.PlayerRemoving:Connect(removeEsp)
        showNotif("ESP aktif", true)
    else
        btnEspAll.BackgroundColor3 = C.BtnTeal
        btnEspAll.Text = "esp all"
        clearAllEsp()
        showNotif("ESP dimatikan", false)
    end
end)

-- ══════════════════════════════════════
--   BRING ALL  (dengan cek kendaraan)
-- ══════════════════════════════════════
btnBringAll.MouseButton1Click:Connect(function()
    if isBringingAll then isBringingAll = false; return end
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myChar or not myHRP or not myHum then return end

    local basePos = savedPos or myHRP.CFrame
    if not savedPos then showNotif("Pakai posisi sekarang sebagai base", false) end

    isBringingAll = true
    btnBringAll.BackgroundColor3 = C.BtnRed
    btnBringAll.Text = "stop"
    lblStatus.Text = "persiapan..."
    lblStatus.TextColor3 = C.TextYellow

    local frozenCF = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame     = frozenCF

    task.spawn(function()
        local function shuffle(tbl)
            for i = #tbl, 2, -1 do local j = math.random(1,i); tbl[i],tbl[j]=tbl[j],tbl[i] end
            return tbl
        end

        -- ── Cek / pastikan duduk di kendaraan ──
        myChar = LocalPlayer.Character
        myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")

        local alreadyIn = myHum and myHum.SeatPart ~= nil
        if alreadyIn then
            -- Sudah dalam kendaraan, langsung lanjut
            lblStatus.Text = "already veh - mulai bring"
            lblStatus.TextColor3 = Color3.fromRGB(90, 255, 200)
            showNotif("already veh ✓", true)
            task.wait(0.4)
        else
            -- Perlu spawn dan duduk
            local ok = ensureSeated(myChar, myHRP, myHum, lblStatus)
            if not ok then
                isBringingAll = false
                btnBringAll.BackgroundColor3 = C.BtnPurple
                btnBringAll.Text = "bring all"
                Camera.CameraType = Enum.CameraType.Custom
                local hf2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hf2 then Camera.CameraSubject = hf2 end
                return
            end
            if not isBringingAll then
                isBringingAll = false
                btnBringAll.BackgroundColor3 = C.BtnPurple
                btnBringAll.Text = "bring all"
                Camera.CameraType = Enum.CameraType.Custom
                local hfx = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hfx then Camera.CameraSubject = hfx end
                return
            end
            lblStatus.Text = "di kursi - mulai bring"
            lblStatus.TextColor3 = C.TextGreen
            task.wait(0.5)
        end

        -- ── Loop utama bring all ──
        while isBringingAll do
            myChar = LocalPlayer.Character
            myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not myChar or not myHRP or not myHum then task.wait(0.3); continue end

            local targets = {}
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(targets, plr)
                end
            end
            if #targets == 0 then lblStatus.Text = "no players"; task.wait(0.5); continue end
            shuffle(targets)

            for _,target in ipairs(targets) do
                if not isBringingAll then break end
                myChar = LocalPlayer.Character
                myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not myChar or not myHRP or not myHum then break end

                local tChar = target.Character
                local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                if not tHRP then continue end

                basePos = savedPos or basePos
                lblStatus.Text = "→ " .. target.Name

                -- Equip item
                equipTool()
                local wt = 0
                while not isToolEquipped() and wt < 0.8 do task.wait(0.05); wt += 0.05 end
                if not isBringingAll then break end

                -- Teleport ke player lalu spin (ngikutin gerak player)
                pcall(function() myHRP.CFrame = tHRP.CFrame end)
                task.wait(0.03)
                doSpin(myHRP, tHRP, 0.18)
                if not isBringingAll then break end

                -- Balik ke basePos sambil spin, unequip saat sampai
                doSpinAtPos(myHRP, basePos, 0.15)
                unequipTool(myHum)
                task.wait(0.03)
            end
        end

        -- cleanup setelah loop selesai
        myChar = LocalPlayer.Character
        myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHum then pcall(function() myHum:UnequipTools() end); unequipTool(myHum) end
        if myHRP then
            local finalPos = savedPos or basePos
            pcall(function() myHRP.CFrame = finalPos end)
            task.wait(0.04)
            pcall(function() myHRP.CFrame = finalPos end)
        end
        Camera.CameraType = Enum.CameraType.Custom
        local hf = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if hf then Camera.CameraSubject = hf end
        isBringingAll = false
        btnBringAll.BackgroundColor3 = C.BtnPurple
        btnBringAll.Text = "bring all"
        lblStatus.Text = "done"; lblStatus.TextColor3 = C.TextGreen
        task.delay(2, function() if lblStatus.Text == "done" then lblStatus.Text = "" end end)
    end)
end)

-- ══════════════════════════════════════
--   PLAYER ACTION PANEL - logika tombol lama
-- ══════════════════════════════════════
btnSpek.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end
    if not isSpectating then
        local targetChar = selectedPlayer.Character
        if not targetChar then return end
        local sub = targetChar:FindFirstChildOfClass("Humanoid") or targetChar:FindFirstChild("HumanoidRootPart")
        if not sub then return end
        isSpectating = true
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = sub
        btnSpek.Text             = "stop spek"
        btnSpek.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    else
        isSpectating = false
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = myHum
        btnSpek.Text             = "spektator"
        btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
    end
end)

btnTpHim.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end
    local targetChar = selectedPlayer.Character
    if not targetChar then return end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    pcall(function() myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3) end)
    btnTpHim.BackgroundColor3 = Color3.fromRGB(220, 160, 40)
    task.wait(0.2)
    btnTpHim.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
end)

btnBang.MouseButton1Click:Connect(function()
    if isBanging then return end
    if not selectedPlayer then return end
    local target     = selectedPlayer
    local targetChar = target.Character
    if not targetChar then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    isBanging = true
    btnBang.BackgroundColor3 = Color3.fromRGB(100, 25, 25)
    btnBang.Text = "..."

    task.spawn(function()
        local originalCFrame = myHRP.CFrame
        equipToolIfNeeded()
        local t = 0
        while not isToolEquipped() and t < 1.5 do task.wait(0.05); t += 0.05 end
        local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if tHRP then
            pcall(function() myHRP.CFrame = CFrame.new(tHRP.Position + Vector3.new(0, -2, 0)) end)
        end
        task.wait(0.03)
        local activeMode = selectedMode
        local p1Done = false; local p1Start = tick(); local p1Conn
        p1Conn = RunService.Heartbeat:Connect(function()
            local dt = tick() - p1Start
            if dt >= 1 then p1Conn:Disconnect(); p1Done = true; return end
            local h = targetChar:FindFirstChild("HumanoidRootPart")
            if not h then return end
            pcall(function()
                myHRP.CFrame = CFrame.new(h.Position + Vector3.new(0, -2, 0))
                            * CFrame.Angles(0, dt * math.pi * 12, 0)
            end)
        end)
        repeat task.wait(0.03) until p1Done
        if activeMode == "lari gila" then
            local skyBase = myHRP.Position + Vector3.new(0, 500, 0)
            pcall(function() myHRP.CFrame = CFrame.new(skyBase) end)
            task.wait(0.03)
            local p2Done = false; local p2Start = tick(); local unequipped = false; local rng = Random.new()
            local p2Conn = RunService.Heartbeat:Connect(function()
                local dt = tick() - p2Start
                if dt >= 1.2 then
                    if not unequipped then unequipped = true; pcall(function() myHum:UnequipTools() end) end
                    pcall(function() myHRP.CFrame = CFrame.new(skyBase) end)
                    if dt >= 1.5 then p2Conn:Disconnect(); p2Done = true end
                    return
                end
                local r = 30 + dt * 15
                pcall(function()
                    myHRP.CFrame = CFrame.new(skyBase + Vector3.new(
                        rng:NextNumber(-r,r), rng:NextNumber(-8,8), rng:NextNumber(-r,r)
                    )) * CFrame.Angles(0, dt * math.pi * 20, 0)
                end)
            end)
            repeat task.wait(0.03) until p2Done
        else
            local baseP = myHRP.Position
            local dir = (activeMode == "kanan 1000") and 1 or -1
            local p2Done = false; local p2Start = tick(); local unequipped = false
            local p2Conn = RunService.Heartbeat:Connect(function()
                local dt = tick() - p2Start
                if dt < 0.8 then
                    local dist = (dt / 0.8) * 100
                    pcall(function() myHRP.CFrame = CFrame.new(baseP + Vector3.new(dir*dist,0,0))
                                * CFrame.Angles(0, dt * math.pi * 20, 0) end)
                else
                    if not unequipped then unequipped = true; pcall(function() myHum:UnequipTools() end) end
                    pcall(function() myHRP.CFrame = CFrame.new(baseP + Vector3.new(dir*100,0,0)) end)
                    if dt >= 1.1 then p2Conn:Disconnect(); p2Done = true end
                end
            end)
            repeat task.wait(0.03) until p2Done
        end
        local t2 = 0
        while isToolEquipped() and t2 < 1 do
            pcall(function() myHum:UnequipTools() end)
            task.wait(0.05); t2 += 0.05
        end
        task.wait(0.05)
        pcall(function() myHRP.CFrame = originalCFrame end)
        task.wait(0.08)
        pcall(function() myHRP.CFrame = originalCFrame end)
        isBanging = false
        btnBang.BackgroundColor3 = Color3.fromRGB(210, 40, 40)
        btnBang.Text = "bang"
    end)
end)

-- ══════════════════════════════════════
--   CAR THROW - Spektator
-- ══════════════════════════════════════
btnCtSpek.MouseButton1Click:Connect(function()
    if not ctSelectedPlayer then
        showNotif("Pilih player dulu!", false); return
    end
    if not isCarThrowSpek then
        local targetChar = ctSelectedPlayer.Character
        if not targetChar then return end
        local sub = targetChar:FindFirstChildOfClass("Humanoid") or targetChar:FindFirstChild("HumanoidRootPart")
        if not sub then return end
        isCarThrowSpek = true
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = sub
        btnCtSpek.Text             = "stop spek"
        btnCtSpek.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    else
        isCarThrowSpek = false
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = myHum
        btnCtSpek.Text             = "spektator"
        btnCtSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
    end
end)

-- ══════════════════════════════════════
--   CAR THROW HIM - logika utama
-- ══════════════════════════════════════
btnCtThrow.MouseButton1Click:Connect(function()
    if isCarThrowing then return end
    if not ctSelectedPlayer then
        showNotif("Pilih player dulu!", false); return
    end
    local target     = ctSelectedPlayer
    local targetChar = target.Character
    if not targetChar then showNotif("Player ga ada char", false); return end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myChar or not myHRP or not myHum then return end

    isCarThrowing = true
    btnCtThrow.BackgroundColor3 = Color3.fromRGB(80, 30, 5)
    btnCtThrow.Text = "..."
    ctStatus.Text = "memulai..."
    ctStatus.TextColor3 = C.TextYellow

    local originalCF = myHRP.CFrame

    task.spawn(function()
        -- ── Cek apakah sudah dalam kendaraan ──
        local alreadyInVeh = myHum.SeatPart ~= nil
        local throwOk = true

        if alreadyInVeh then
            -- === PATH: sudah dalam kendaraan ===
            ctStatus.Text = "already veh ✓"
            ctStatus.TextColor3 = Color3.fromRGB(90, 255, 200)
            showNotif("already veh - langsung throw!", true)
            task.wait(0.3)

            -- Teleport ke target
            ctStatus.Text = "tp ke target..."
            local tC2 = target.Character
            local tHRP2 = tC2 and tC2:FindFirstChild("HumanoidRootPart")
            if not tHRP2 then
                throwOk = false
            else
                pcall(function() myHRP.CFrame = tHRP2.CFrame end)
                task.wait(0.1)

                -- Turun 100 stud
                ctStatus.Text = "turun 100..."
                pcall(function() myHRP.CFrame = myHRP.CFrame + Vector3.new(0, -100, 0) end)
                task.wait(1)

                -- Keluar dari kendaraan dulu, lalu loncat
                ctStatus.Text = "keluar veh..."
                pcall(function() myHum:UnequipTools() end)
                -- Force keluar seat dengan teleport sedikit ke atas
                local waitOut = 0
                while myHum.SeatPart ~= nil and waitOut < 1 do
                    pcall(function() myHRP.CFrame = myHRP.CFrame + Vector3.new(0, 0.8, 0) end)
                    task.wait(0.05); waitOut += 0.05
                end
                task.wait(0.08)

                -- Loncat setelah keluar seat
                ctStatus.Text = "loncat!"
                pcall(function() myHum.Jump = true end)
                task.wait(0.12)
                pcall(function() myHum.Jump = true end)
            end

        else
            -- === PATH: belum dalam kendaraan, spawn dulu ===
            ctStatus.Text = "hapus kendaraan..."
            pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("DeleteAllVehicles") end)
            task.wait(1.2)

            ctStatus.Text = "spawn Bus..."
            pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("PickingCar","Bus","Work") end)
            task.wait(2.5)

            ctStatus.Text = "cari kursi..."
            local seated  = false
            local attempt = 0
            while not seated and attempt < 20 do
                attempt = attempt + 1
                myChar = LocalPlayer.Character
                myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if myChar and myHRP and myHum then
                    local s = GetNearestPassengerSeat(myHRP)
                    if s then
                        pcall(function() myHRP.CFrame = s.CFrame * CFrame.new(0,1.5,0) end)
                        task.wait(0.15)
                        pcall(function() s:Sit(myHum) end)
                        task.wait(0.3)
                        if myHum.Sit or myHum.SeatPart ~= nil then seated = true end
                    else task.wait(0.5) end
                else task.wait(0.4) end
            end

            if not seated then
                ctStatus.Text = "gagal masuk veh!"
                ctStatus.TextColor3 = Color3.fromRGB(255,90,90)
                showNotif("Gagal masuk Bus!", false)
                throwOk = false
            else
                ctStatus.Text = "duduk ✓ - spinning..."
                ctStatus.TextColor3 = C.TextGreen
                task.wait(0.3)

                -- Spin realtime selama 2 detik ngikutin target
                ctStatus.Text = "spinning di target..."
                local spinStart = tick()
                local spinAngle = 0
                local SPIN_SPEED = math.pi * 20
                while tick() - spinStart < 2 do
                    local tC3 = target.Character
                    local th   = tC3 and tC3:FindFirstChild("HumanoidRootPart")
                    if th then
                        spinAngle = spinAngle + SPIN_SPEED * (1/60)
                        pcall(function()
                            myHRP.CFrame = CFrame.new(th.Position) * CFrame.Angles(0, spinAngle, 0)
                        end)
                    end
                    task.wait(1/60)
                end

                -- Turun 100 stud
                ctStatus.Text = "turun 100..."
                pcall(function() myHRP.CFrame = myHRP.CFrame + Vector3.new(0, -100, 0) end)
                task.wait(1)

                -- Hapus kendaraan
                ctStatus.Text = "hapus veh..."
                pcall(function() ReplicatedStorage.RE["1Ca1r"]:FireServer("DeleteAllVehicles") end)
                task.wait(0.3)
            end
        end

        -- Kembali ke posisi semula (selalu, terlepas throwOk atau tidak)
        if throwOk then
            ctStatus.Text = "kembali ke pos..."
            showNotif("Car Throw selesai!", true)
        end
        myChar = LocalPlayer.Character
        myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            pcall(function() myHRP.CFrame = originalCF end)
            task.wait(0.06)
            pcall(function() myHRP.CFrame = originalCF end)
        end

        isCarThrowing = false
        btnCtThrow.BackgroundColor3 = Color3.fromRGB(170, 60, 10)
        btnCtThrow.Text = "car throw"
        ctStatus.Text = ctSelectedPlayer and ("target: " .. ctSelectedPlayer.Name) or "select player dulu"
        ctStatus.TextColor3 = ctSelectedPlayer and C.TextYellow or C.TextDim
    end)
end)

-- ══════════════════════════════════════
--   COLLAPSE & DRAG (main window)
-- ══════════════════════════════════════
local collapsed = false
titleBar.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    if collapsed then
        collapseIco.Text = "+"
        TweenService:Create(win, TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, WIN_W, 0, TITLE_H)}):Play()
    else
        collapseIco.Text = "-"
        TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, WIN_W, 0, WIN_H)}):Play()
    end
end)

do
    local dragging, dStart, wStart = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = inp.Position; wStart = win.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dStart
            win.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X,
                                     wStart.Y.Scale, wStart.Y.Offset + d.Y)
        end
    end)
end

print("[OK] BmSkyMods v2 loaded")
