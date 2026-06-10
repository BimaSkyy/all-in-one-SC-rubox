--[[
    CarLock GUI v2 - BmSkyMods
    Fix: layout pakai UIListLayout di body, tombol List Player toggle dropdown
    Layout: TitleBar | [List Player btn] | [ScrollList - collapsible] | [Selected label] | [Lock btn] | [Status]
]]

-- ===================== SERVICES =====================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid", 15)
local RootPart  = Character:WaitForChild("HumanoidRootPart", 15)

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid", 15)
    RootPart  = char:WaitForChild("HumanoidRootPart", 15)
end)

-- ===================== STATE =====================
local selectedPlayer = nil
local lockActive     = false
local savedPos       = nil
local targetCar      = nil
local listOpen       = false   -- toggle dropdown list

-- ===================== KONSTANTA UKURAN =====================
local W           = 230   -- lebar panel
local TITLE_H     = 28
local BTN_H       = 30    -- tinggi tiap tombol utama
local LIST_MAX_H  = 130   -- tinggi max scroll list saat terbuka
local ITEM_H      = 26    -- tinggi tiap item player di list
local SEL_H       = 18    -- tinggi label selected
local STATUS_H    = 16    -- tinggi status
local PAD         = 6     -- padding kiri/kanan/antar elemen

-- tinggi panel = dynamic, dihitung ulang tiap toggle
local function CalcPanelH()
    local h = TITLE_H + PAD
    h = h + BTN_H + PAD   -- tombol List Player
    if listOpen then
        h = h + LIST_MAX_H + PAD
    end
    h = h + SEL_H + PAD   -- selected label
    h = h + BTN_H + PAD   -- tombol Lock
    h = h + STATUS_H + PAD
    return h
end

-- ===================== SCREENGUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "CarLockGUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

-- ===================== PANEL =====================
local Panel = Instance.new("Frame")
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, W, 0, CalcPanelH())
Panel.Position         = UDim2.new(0, 40, 0, 40)
Panel.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Active           = true
Panel.Parent           = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 7)
local ps = Instance.new("UIStroke", Panel)
ps.Color     = Color3.fromRGB(75, 75, 115)
ps.Thickness = 1

-- ===================== TITLE BAR =====================
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, TITLE_H)
TitleBar.Position         = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(42, 42, 62)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 3
TitleBar.Parent           = Panel
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 7)
-- fill sudut bawah
local tf = Instance.new("Frame", TitleBar)
tf.Size             = UDim2.new(1, 0, 0, 8)
tf.Position         = UDim2.new(0, 0, 1, -8)
tf.BackgroundColor3 = Color3.fromRGB(42, 42, 62)
tf.BorderSizePixel  = 0
tf.ZIndex           = 3

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size               = UDim2.new(1, -56, 1, 0)
TitleLabel.Position           = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "🔒 CarLock"
TitleLabel.TextColor3         = Color3.fromRGB(210, 210, 255)
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextSize           = 13
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.ZIndex             = 4

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = UDim2.new(0, 22, 0, 22)
MinBtn.Position         = UDim2.new(1, -48, 0.5, -11)
MinBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 110)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "—"
MinBtn.TextColor3       = Color3.new(1,1,1)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 11
MinBtn.ZIndex           = 4
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.new(0, 22, 0, 22)
CloseBtn.Position         = UDim2.new(1, -24, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.new(1,1,1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 11
CloseBtn.ZIndex           = 4
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

-- ===================== BODY (container isi) =====================
-- Semua elemen di bawah title diposisikan manual dengan offset Y
-- Kita hitung posisi Y setiap elemen secara programatik

local function MakeElem(class, parent)
    local e = Instance.new(class)
    e.BorderSizePixel = 0
    e.Parent = parent
    return e
end

-- ---- Tombol List Player ----
local ListToggleBtn = MakeElem("TextButton", Panel)
ListToggleBtn.Size             = UDim2.new(1, -PAD*2, 0, BTN_H)
ListToggleBtn.Position         = UDim2.new(0, PAD, 0, TITLE_H + PAD)
ListToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
ListToggleBtn.Text             = "▶  List Player"
ListToggleBtn.TextColor3       = Color3.fromRGB(200, 200, 240)
ListToggleBtn.Font             = Enum.Font.GothamBold
ListToggleBtn.TextSize         = 12
ListToggleBtn.TextXAlignment   = Enum.TextXAlignment.Left
Instance.new("UICorner", ListToggleBtn).CornerRadius = UDim.new(0, 5)
local lp = Instance.new("UIPadding", ListToggleBtn)
lp.PaddingLeft = UDim.new(0, 8)

-- ---- Scroll List (hidden by default) ----
local ListFrame = Instance.new("ScrollingFrame", Panel)
ListFrame.Size                 = UDim2.new(1, -PAD*2, 0, LIST_MAX_H)
ListFrame.Position             = UDim2.new(0, PAD, 0, TITLE_H + PAD + BTN_H + PAD)
ListFrame.BackgroundColor3     = Color3.fromRGB(20, 20, 28)
ListFrame.BorderSizePixel      = 0
ListFrame.ScrollBarThickness   = 4
ListFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 150)
ListFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
ListFrame.Visible              = false
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 5)

local ListLayout = Instance.new("UIListLayout", ListFrame)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 2)

local ListPad = Instance.new("UIPadding", ListFrame)
ListPad.PaddingTop    = UDim.new(0, 3)
ListPad.PaddingBottom = UDim.new(0, 3)
ListPad.PaddingLeft   = UDim.new(0, 4)
ListPad.PaddingRight  = UDim.new(0, 4)

-- ---- Fungsi posisi Y elemen di bawah list ----
local function GetYBelowList()
    local base = TITLE_H + PAD + BTN_H + PAD
    if listOpen then base = base + LIST_MAX_H + PAD end
    return base
end

-- ---- Selected Label ----
local SelectedLabel = MakeElem("TextLabel", Panel)
SelectedLabel.Size               = UDim2.new(1, -PAD*2, 0, SEL_H)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text               = "Pilih player dulu"
SelectedLabel.TextColor3         = Color3.fromRGB(110, 110, 155)
SelectedLabel.Font               = Enum.Font.Gotham
SelectedLabel.TextSize           = 10
SelectedLabel.TextXAlignment     = Enum.TextXAlignment.Left
SelectedLabel.TextTruncate       = Enum.TextTruncate.AtEnd

-- ---- Tombol Lock ----
local LockBtn = MakeElem("TextButton", Panel)
LockBtn.Size             = UDim2.new(1, -PAD*2, 0, BTN_H)
LockBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
LockBtn.Text             = "🔒 Lock"
LockBtn.TextColor3       = Color3.fromRGB(140, 140, 180)
LockBtn.Font             = Enum.Font.GothamBold
LockBtn.TextSize         = 13
LockBtn.Visible          = false
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0, 5)

-- ---- Status Label ----
local StatusLabel = MakeElem("TextLabel", Panel)
StatusLabel.Size               = UDim2.new(1, -PAD*2, 0, STATUS_H)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text               = ""
StatusLabel.TextColor3         = Color3.fromRGB(90, 200, 90)
StatusLabel.Font               = Enum.Font.Gotham
StatusLabel.TextSize           = 10
StatusLabel.TextXAlignment     = Enum.TextXAlignment.Left
StatusLabel.TextTruncate       = Enum.TextTruncate.AtEnd

-- ===================== LAYOUT UPDATE =====================
local function UpdateLayout()
    local y = TITLE_H + PAD

    -- Tombol List Player
    ListToggleBtn.Position = UDim2.new(0, PAD, 0, y)
    ListToggleBtn.Text     = (listOpen and "▼  List Player" or "▶  List Player")
    y = y + BTN_H + PAD

    -- Scroll List
    if listOpen then
        ListFrame.Position = UDim2.new(0, PAD, 0, y)
        ListFrame.Visible  = true
        y = y + LIST_MAX_H + PAD
    else
        ListFrame.Visible  = false
    end

    -- Selected Label
    SelectedLabel.Position = UDim2.new(0, PAD, 0, y)
    y = y + SEL_H + PAD

    -- Lock Button
    LockBtn.Position = UDim2.new(0, PAD, 0, y)
    y = y + BTN_H + PAD

    -- Status
    StatusLabel.Position = UDim2.new(0, PAD, 0, y)
    y = y + STATUS_H + PAD

    -- Resize panel
    Panel.Size = UDim2.new(0, W, 0, y)
end

UpdateLayout()

-- ===================== HELPERS =====================
local function setStatus(msg, color)
    StatusLabel.Text       = msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(90, 200, 90)
end

local function FindPlayerCar(playerName)
    local VehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not VehiclesFolder then return nil end
    local lower = playerName:lower()
    for _, model in ipairs(VehiclesFolder:GetChildren()) do
        if model:IsA("Model") then
            local mlow = model.Name:lower()
            if mlow == lower .. "car"
            or (mlow:sub(-3) == "car" and mlow:sub(1, #lower) == lower) then
                return model
            end
        end
    end
    return nil
end

local function GetPlayersWithCar()
    local result = {}
    local VehiclesFolder = workspace:FindFirstChild("Vehicles")
    if not VehiclesFolder then return result end
    for _, model in ipairs(VehiclesFolder:GetChildren()) do
        if model:IsA("Model") then
            local name = model.Name
            if name:sub(-3):lower() == "car" then
                local prefix = name:sub(1, #name - 3)
                if prefix ~= "" then
                    table.insert(result, {playerName = prefix, carModel = model})
                end
            end
        end
    end
    return result
end

-- ===================== LIST PLAYER =====================
local playerButtons = {}

local function RefreshList()
    for _, btn in pairs(playerButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    playerButtons = {}

    local list = GetPlayersWithCar()

    if #list == 0 then
        local e = Instance.new("TextLabel", ListFrame)
        e.Size               = UDim2.new(1, 0, 0, ITEM_H)
        e.BackgroundTransparency = 1
        e.Text               = "(tidak ada)"
        e.TextColor3         = Color3.fromRGB(100, 100, 130)
        e.Font               = Enum.Font.Gotham
        e.TextSize           = 11
        e.TextXAlignment     = Enum.TextXAlignment.Center
        playerButtons["__empty"] = e
        return
    end

    for _, entry in ipairs(list) do
        local pname = entry.playerName
        local btn   = Instance.new("TextButton", ListFrame)
        btn.Size             = UDim2.new(1, 0, 0, ITEM_H)
        btn.BackgroundColor3 = (selectedPlayer == pname)
            and Color3.fromRGB(55, 55, 105)
            or  Color3.fromRGB(33, 33, 48)
        btn.BorderSizePixel  = 0
        btn.Text             = "  " .. pname
        btn.TextColor3       = Color3.fromRGB(195, 195, 230)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 11
        btn.TextXAlignment   = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            selectedPlayer           = pname
            SelectedLabel.Text       = "Selected: " .. pname
            SelectedLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
            LockBtn.Visible          = true
            if not lockActive then
                LockBtn.Text             = "🔒 Lock " .. pname
                LockBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 40)
                LockBtn.TextColor3       = Color3.new(1,1,1)
            end
            RefreshList()
        end)

        playerButtons[pname] = btn
    end
end

-- ===================== TOGGLE LIST =====================
ListToggleBtn.MouseButton1Click:Connect(function()
    listOpen = not listOpen
    if listOpen then
        RefreshList()
    end
    UpdateLayout()
end)

-- ===================== DRAG =====================
local dragging       = false
local dragStartMouse = nil
local dragStartPos   = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging       = true
        dragStartMouse = input.Position
        dragStartPos   = Panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
     or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = input.Position - dragStartMouse
        Panel.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + d.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ===================== MINIMIZE =====================
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ListToggleBtn.Visible = not minimized
    ListFrame.Visible     = not minimized and listOpen
    SelectedLabel.Visible = not minimized
    LockBtn.Visible       = not minimized and (selectedPlayer ~= nil) and not lockActive
    StatusLabel.Visible   = not minimized
    MinBtn.Text = minimized and "▢" or "—"
    Panel.Size  = minimized
        and UDim2.new(0, W, 0, TITLE_H)
        or  UDim2.new(0, W, 0, CalcPanelH())
    if not minimized then UpdateLayout() end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ===================== LOCK MECHANIC =====================
local function TryCobaDuduk(carModel)
    local seat = carModel:FindFirstChildWhichIsA("Seat", true)
              or carModel:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if seat.Occupant then return false end
    for _ = 1, 6 do
        RootPart.CFrame = seat.CFrame * CFrame.new(0, 1.2, 0)
        task.wait(0.15)
        if Humanoid.Sit then return true end
    end
    return false
end

local function CarInRadius(carModel, pos, radius)
    local pp = carModel.PrimaryPart or carModel:FindFirstChildWhichIsA("BasePart")
    if not pp then return false end
    return (pp.Position - pos).Magnitude <= radius
end

local function TarikMobil(carModel, pos)
    if not carModel.PrimaryPart then
        carModel.PrimaryPart = carModel:FindFirstChildWhichIsA("BasePart")
    end
    if not carModel.PrimaryPart then return false end
    carModel:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(0, 1, 0)))
    return true
end

local function StopLock()
    lockActive = false
    LockBtn.Text             = "🔒 Lock " .. (selectedPlayer or "")
    LockBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 40)
    LockBtn.TextColor3       = Color3.new(1,1,1)
    setStatus("Lock dihentikan", Color3.fromRGB(200, 90, 90))
end

local function MulaiLock()
    if not selectedPlayer then return end
    local carModel = FindPlayerCar(selectedPlayer)
    if not carModel then
        setStatus("Mobil tidak ditemukan!", Color3.fromRGB(220, 90, 90))
        return
    end

    lockActive = true
    targetCar  = carModel
    savedPos   = RootPart.Position

    LockBtn.Text             = "⏹ Stop"
    LockBtn.BackgroundColor3 = Color3.fromRGB(155, 45, 45)
    LockBtn.TextColor3       = Color3.new(1,1,1)
    setStatus("Teleport ke mobil...", Color3.fromRGB(255, 195, 50))

    task.spawn(function()
        if not Character or not Character:IsDescendantOf(workspace) then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Humanoid  = Character:WaitForChild("Humanoid", 15)
            RootPart  = Character:WaitForChild("HumanoidRootPart", 15)
        end

        -- FASE 1: coba duduk
        local duduk = false
        for attempt = 1, 20 do
            if not lockActive then return end
            local pp = targetCar.PrimaryPart or targetCar:FindFirstChildWhichIsA("BasePart")
            if pp then RootPart.CFrame = pp.CFrame * CFrame.new(0, 2, 2) end
            task.wait(0.15)
            duduk = TryCobaDuduk(targetCar)
            if duduk then break end
            setStatus("Duduk... " .. attempt, Color3.fromRGB(255, 195, 50))
            task.wait(0.2)
        end
        if not lockActive then return end

        if duduk then
            setStatus("Duduk berhasil, balik...", Color3.fromRGB(90, 215, 90))
            task.wait(0.3)
        else
            setStatus("Gagal duduk, tarik paksa", Color3.fromRGB(255, 145, 45))
        end

        -- FASE 2: teleport balik
        RootPart.CFrame = CFrame.new(savedPos)
        task.wait(0.25)
        if Humanoid.Sit then Humanoid.Sit = false task.wait(0.2) end

        -- FASE 3: loop tarik
        while lockActive do
            if not targetCar or not targetCar:IsDescendantOf(workspace) then
                targetCar = FindPlayerCar(selectedPlayer)
                if not targetCar then
                    setStatus("Mobil hilang, cari...", Color3.fromRGB(200, 145, 45))
                    task.wait(1)
                    continue
                end
            end
            if CarInRadius(targetCar, savedPos, 10) then
                setStatus("✅ Terkunci di posisi", Color3.fromRGB(50, 215, 90))
                task.wait(0.5)
            else
                TarikMobil(targetCar, savedPos)
                local pp = targetCar.PrimaryPart or targetCar:FindFirstChildWhichIsA("BasePart")
                local dist = pp and (pp.Position - savedPos).Magnitude or 0
                setStatus(string.format("Menarik... %.1f stud", dist), Color3.fromRGB(255, 195, 50))
                task.wait(0.3)
            end
        end
    end)
end

LockBtn.MouseButton1Click:Connect(function()
    if lockActive then StopLock() else MulaiLock() end
end)

-- ===================== REALTIME REFRESH =====================
task.spawn(function()
    while true do
        task.wait(2)
        if listOpen then pcall(RefreshList) end
    end
end)

print("[CarLock v2] GUI loaded - BmSkyMods")
