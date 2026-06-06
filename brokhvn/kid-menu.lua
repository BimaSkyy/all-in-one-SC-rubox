-- ══════════════════════════════════════
--   BmSkyMods  |  Kid Menu Only
-- ══════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────
local kidName      = "BmSky"
local isKidAnimOn  = false
local isKidRotationOn = false

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
    Text       = Color3.fromRGB(220, 220, 230),
    TextDim    = Color3.fromRGB(130, 125, 158),
    TextGreen  = Color3.fromRGB(90, 245, 140),
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
local WIN_H   = 200
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

-- ── Title bar ─────────────────────────
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

-- ── ScrollingFrame ────────────────────
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

-- ── Helper UI ─────────────────────────
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

-- ══════════════════════════════════════
--   LAYOUT (hanya Kid)
-- ══════════════════════════════════════
local Y = PAD

-- ── KID ───────────────────────────────
makeSep(Y); Y = Y + 3
makeLabel(Y, "  Kid", C.TextDim); Y = Y + 14
local btnBoyKid = makeBtn(Y, "Boy Kid", C.BtnTeal); Y = Y + ROW_H + 4
local btnGirlsKid = makeBtn(Y, "Girls Kid", C.BtnGold); Y = Y + ROW_H + 4

-- TextBox nama kid
local kidTextBox = Instance.new("TextBox", scrollFrame)
kidTextBox.Size             = UDim2.new(1, -10, 0, ROW_H)
kidTextBox.Position         = UDim2.new(0, 5, 0, Y)
kidTextBox.BackgroundColor3 = C.BtnDefault
kidTextBox.Text             = kidName
kidTextBox.PlaceholderText  = "Nama kid..."
kidTextBox.TextColor3       = C.Text
kidTextBox.Font             = Enum.Font.Gotham
kidTextBox.TextSize         = 11
kidTextBox.BorderSizePixel  = 0
kidTextBox.ZIndex           = 12
Instance.new("UICorner", kidTextBox).CornerRadius = UDim.new(0, 4)
Y = Y + ROW_H + 4

local btnSetKidName = makeBtn(Y, "Set Kid Name", C.BtnBlue); Y = Y + ROW_H + 4
local btnAnimKidName = makeBtn(Y, "Anim Kid: OFF", C.BtnPurple); local animKidOrigBg = C.BtnPurple; Y = Y + ROW_H + 4
local btnRotationKid = makeBtn(Y, "Rotation Kid: OFF", C.BtnRed); local rotKidOrigBg = C.BtnRed; Y = Y + ROW_H + PAD

-- ══════════════════════════════════════
--   LOGIKA KID
-- ══════════════════════════════════════

btnBoyKid.MouseButton1Click:Connect(function()
    pcall(function()
        ReplicatedStorage.RE["1Bab1yFollo1w"]:FireServer("SpawnChild","BabyBoy")
    end)
    showNotif("Spawn BabyBoy", true)
end)

btnGirlsKid.MouseButton1Click:Connect(function()
    pcall(function()
        ReplicatedStorage.RE["1Bab1yFollo1w"]:FireServer("SpawnChild","BabyGirl")
    end)
    showNotif("Spawn BabyGirl", true)
end)

btnSetKidName.MouseButton1Click:Connect(function()
    local newName = kidTextBox.Text
    if newName == "" then showNotif("Nama kid tidak boleh kosong!", false); return end
    kidName = newName
    showNotif("Nama kid diset ke: " .. kidName, true)
    pcall(function()
        ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayFollow", kidName)
    end)
end)

btnAnimKidName.MouseButton1Click:Connect(function()
    isKidAnimOn = not isKidAnimOn
    if isKidAnimOn then
        btnAnimKidName.Text = "Anim Kid: ON"
        btnAnimKidName.BackgroundColor3 = Color3.fromRGB(52,168,83)
        task.spawn(function()
            while isKidAnimOn do
                local name = kidName
                local sendText = name
                local rand = math.random(1,4)
                if rand == 1 then
                    local scrambled = ""
                    for _=1,#name do scrambled = scrambled .. string.char(math.random(65,90)) end
                    sendText = scrambled
                elseif rand == 2 then
                    local revealed = math.random(1,#name)
                    sendText = string.sub(name,1,revealed) .. string.rep(" ",#name-revealed)
                elseif rand == 3 then
                    sendText = string.reverse(name)
                end
                pcall(function()
                    ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayFollow", sendText)
                end)
                task.wait(0.3)
            end
            pcall(function()
                ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayFollow", kidName)
            end)
        end)
    else
        btnAnimKidName.Text = "Anim Kid: OFF"
        btnAnimKidName.BackgroundColor3 = animKidOrigBg
    end
end)

btnRotationKid.MouseButton1Click:Connect(function()
    isKidRotationOn = not isKidRotationOn
    if isKidRotationOn then
        btnRotationKid.Text = "Rotation Kid: ON"
        btnRotationKid.BackgroundColor3 = Color3.fromRGB(52,168,83)
        task.spawn(function()
            while isKidRotationOn do
                pcall(function()
                    ReplicatedStorage.RE["1Bab1yFollo1w"]:FireServer("SpawnChild","BabyBoy")
                end)
                task.wait(0.5)
                if not isKidRotationOn then break end
                pcall(function()
                    ReplicatedStorage.RE["1Bab1yFollo1w"]:FireServer("SpawnChild","BabyGirl")
                end)
                task.wait(0.5)
            end
        end)
        showNotif("Rotation Kid aktif", true)
    else
        btnRotationKid.Text = "Rotation Kid: OFF"
        btnRotationKid.BackgroundColor3 = rotKidOrigBg
        showNotif("Rotation Kid mati", false)
    end
end)

-- ══════════════════════════════════════
--   COLLAPSE & DRAG
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
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = inp.Position; wStart = win.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dStart
            win.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X, wStart.Y.Scale, wStart.Y.Offset + d.Y)
        end
    end)
end

print("[OK] BmSkyMods Kid loaded")