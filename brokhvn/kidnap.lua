-- BringGui by BmSky
-- Fitur: List Player real-time, Bring (couch+spin+trigger sit), Spektator
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ── State ─────────────────────────────────
local selectedPlayer  = nil
local isBringing      = false
local isSpectating    = false
local playerButtons   = {}
local savedCFrame     = nil

-- ── GUI ───────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "BringGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent         = game:GetService("CoreGui")

-- Container utama
local container = Instance.new("Frame", gui)
container.Size             = UDim2.new(0, 250, 0, 300)
container.Position         = UDim2.new(0.5, -125, 0.5, -150)
container.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
container.BorderSizePixel  = 0
container.ZIndex           = 10
container.ClipsDescendants = true
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", container)
mainStroke.Color = Color3.fromRGB(70, 50, 130)
mainStroke.Thickness = 1.5

-- ── Header / drag handle ──────────────────
local header = Instance.new("TextButton", container)
header.Size             = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(55, 40, 100)
header.Text             = "  🎯 Bring GUI"
header.TextColor3       = Color3.new(1,1,1)
header.Font             = Enum.Font.GothamBold
header.TextSize         = 13
header.TextXAlignment   = Enum.TextXAlignment.Left
header.AutoButtonColor  = false
header.ZIndex           = 20
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

-- Tombol minimize [–]/[+]
local minBtn = Instance.new("TextButton", header)
minBtn.Size             = UDim2.new(0, 24, 0, 22)
minBtn.Position         = UDim2.new(1, -28, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 130)
minBtn.Text             = "–"
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 14
minBtn.TextColor3       = Color3.new(1,1,1)
minBtn.AutoButtonColor  = false
minBtn.ZIndex           = 25
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

-- Minimize state
local isMinimized = false
local FULL_HEIGHT = 300

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        container.Size = UDim2.new(0, 250, 0, 30)
        rightPanel.Visible = false
        minBtn.Text = "+"
    else
        container.Size = UDim2.new(0, 250, 0, FULL_HEIGHT)
        rightPanel.Visible = true
        minBtn.Text = "–"
    end
end)

-- Drag logic
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = container.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── Panel kanan: tombol aksi ──────────────
local rightPanel = Instance.new("Frame", container)
rightPanel.Size             = UDim2.new(1, 0, 1, -30)
rightPanel.Position         = UDim2.new(0, 0, 0, 30)
rightPanel.BackgroundTransparency = 1
rightPanel.ZIndex           = 11

-- Action frame (kolom kanan)
local actionFrame = Instance.new("Frame", rightPanel)
actionFrame.Size     = UDim2.new(0, 58, 1, 0)
actionFrame.Position = UDim2.new(1, -58, 0, 0)
actionFrame.BackgroundTransparency = 1
actionFrame.ZIndex   = 12

local actionLayout = Instance.new("UIListLayout", actionFrame)
actionLayout.Padding            = UDim.new(0, 5)
actionLayout.SortOrder          = Enum.SortOrder.LayoutOrder
actionLayout.FillDirection      = Enum.FillDirection.Vertical
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment  = Enum.VerticalAlignment.Top

local function makeActionBtn(text, color)
    local btn = Instance.new("TextButton", actionFrame)
    btn.Size             = UDim2.new(1, -6, 0, 30)
    btn.Text             = text
    btn.BackgroundColor3 = color
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.AutoButtonColor  = false
    btn.ZIndex           = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local btnBring = makeActionBtn("bring", Color3.fromRGB(130, 50, 200))
local btnSpek  = makeActionBtn("spek",  Color3.fromRGB(30, 90, 180))

-- ── Scroller list player ──────────────────
local scroller = Instance.new("ScrollingFrame", rightPanel)
scroller.Size                 = UDim2.new(1, -62, 1, -4)
scroller.Position             = UDim2.new(0, 2, 0, 2)
scroller.BackgroundTransparency = 1
scroller.ScrollBarThickness   = 3
scroller.ScrollBarImageColor3 = Color3.fromRGB(130, 80, 220)
scroller.CanvasSize           = UDim2.new(0, 0, 0, 0)
scroller.ZIndex               = 12

local listLayout = Instance.new("UIListLayout", scroller)
listLayout.Padding       = UDim.new(0, 3)
listLayout.SortOrder     = Enum.SortOrder.Name
listLayout.FillDirection = Enum.FillDirection.Vertical

-- ── Player list logic ─────────────────────
local function updateCanvasSize()
    task.wait(0.05)
    scroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end

local function setSelected(plr)
    -- Reset highlight semua
    for _, data in pairs(playerButtons) do
        if data.btn and data.btn.Parent then
            data.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
        end
    end
    if selectedPlayer == plr then
        -- Deselect
        selectedPlayer = nil
        if isSpectating then
            isSpectating = false
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType    = Enum.CameraType.Custom
            Camera.CameraSubject = myHum
            btnSpek.Text             = "spek"
            btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
        end
    else
        selectedPlayer = plr
        local d = playerButtons[plr.Name]
        if d and d.btn and d.btn.Parent then
            d.btn.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
        end
    end
end

local function addPlayerBtn(plr)
    if plr == LocalPlayer then return end
    if playerButtons[plr.Name] then return end
    local btn = Instance.new("TextButton", scroller)
    btn.Size             = UDim2.new(1, -4, 0, 26)
    btn.Text             = plr.Name
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.AutoButtonColor  = false
    btn.ZIndex           = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() setSelected(plr) end)
    playerButtons[plr.Name] = { btn = btn, player = plr }
    updateCanvasSize()
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
            btnSpek.Text             = "spek"
            btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
        end
    end
    updateCanvasSize()
end

for _, plr in ipairs(Players:GetPlayers()) do addPlayerBtn(plr) end
Players.PlayerAdded:Connect(addPlayerBtn)
Players.PlayerRemoving:Connect(removePlayerBtn)

-- ── Helper: hapus semua tool ──────────────
local function clearTools()
    pcall(function()
        ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("ClearAllTools")
    end)
end

-- ── BRING FUNCTION ────────────────────────
btnBring.MouseButton1Click:Connect(function()
    -- STOP jika sedang aktif
    if isBringing then
        isBringing = false
        clearTools()
        -- Kembalikan ke posisi semula
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP and savedCFrame then
            task.wait(0.1)
            pcall(function() myHRP.CFrame = savedCFrame end)
        end
        btnBring.Text             = "bring"
        btnBring.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
        return
    end

    if not selectedPlayer then return end

    isBringing = true
    btnBring.Text             = "stop"
    btnBring.BackgroundColor3 = Color3.fromRGB(180, 40, 40)

    task.spawn(function()
        local myChar = LocalPlayer.Character
        if not myChar then
            isBringing = false
            btnBring.Text             = "bring"
            btnBring.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
            return
        end

        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then
            isBringing = false
            btnBring.Text             = "bring"
            btnBring.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
            return
        end

        -- Simpan posisi awal
        savedCFrame = myHRP.CFrame

        -- ── STEP 1: Bersihkan tool dulu ──
        clearTools()
        task.wait(0.3)
        if not isBringing then return end

        -- ── STEP 2: Spawn & equip Couch ──
        pcall(function() ReplicatedStorage.RE["1Too1l"]:InvokeServer("PickingTools", "Couch") end)
        task.wait(0.5)
        if not isBringing then clearTools() return end

        -- Equip dari backpack kalau belum ke-equip
        local function isEquipped()
            local c = LocalPlayer.Character
            if not c then return false end
            for _, v in ipairs(c:GetChildren()) do
                if v:IsA("Tool") then return true end
            end
            return false
        end

        if not isEquipped() then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                for _, v in ipairs(bp:GetChildren()) do
                    if v:IsA("Tool") then
                        pcall(function() myHum:EquipTool(v) end)
                        task.wait(0.2)
                        break
                    end
                end
            end
        end

        if not isBringing then clearTools() return end

        -- ── STEP 3: Pantau target diam 2 detik dulu ──
        local function getTargetState(tHum, tHRP)
            if not tHum or not tHRP then return "tidak ditemukan" end
            if tHum.Sit then return "duduk" end
            local speed = tHRP.Velocity.Magnitude
            if tHum.Jump or tHRP.Position.Y > (tHRP.Position.Y + 1) then return "lompat" end
            if speed > 1.5 then return "jalan" end
            return "diam"
        end

        -- Tunggu target diam minimal 2 detik
        local diamTimer = 0
        local DIAM_NEEDED = 2.0
        local lastLogState = ""

        while isBringing do
            local tChar = selectedPlayer and selectedPlayer.Character
            local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if not tHRP then
                diamTimer = 0
                task.wait(0.1)
            else
                local state = getTargetState(tHum, tHRP)

                if state == "diam" then
                    diamTimer = diamTimer + 0.1
                    if diamTimer >= DIAM_NEEDED then
                        break  -- target sudah diam cukup lama, lanjut
                    end
                else
                    -- Reset timer kalau gerak lagi
                    diamTimer = 0
                    if state ~= lastLogState then
                        print("[BringGui] target sedang " .. state .. " — menunggu diam dulu")
                        lastLogState = state
                    end
                end
            end
            task.wait(0.1)
        end

        if not isBringing then clearTools() return end
        print("[BringGui] target sudah diam, gas teleport!")

        -- ── STEP 4: Follow target + spin terus, pantau sit ──
        local currentRot = 0
        local spinConn = nil

        spinConn = RunService.Heartbeat:Connect(function(dt)
            if not isBringing then
                spinConn:Disconnect()
                return
            end

            local tChar = selectedPlayer and selectedPlayer.Character
            local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if not tHRP then return end

            -- ── Cek target SIT → trigger teleport ke koordinat ──
            if tHum and tHum.Sit then
                spinConn:Disconnect()
                isBringing = false

                -- Teleport player ke lokasi tujuan
                pcall(function() myHRP.CFrame = CFrame.new(177, 2, -465) end)
                task.wait(0.3)

                -- Hapus tool
                clearTools()
                task.wait(0.2)

                -- Kembali ke posisi semula
                pcall(function() myHRP.CFrame = savedCFrame end)

                btnBring.Text             = "bring"
                btnBring.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
                return
            end

            -- Spin + ikuti target real-time
            currentRot = currentRot + math.rad(2000) * dt
            local offset = Vector3.new(0, -1, 0)
            pcall(function()
                myHRP.CFrame = CFrame.new(tHRP.Position + offset) * CFrame.Angles(0, currentRot, 0)
            end)
        end)
    end)
end)

-- ── SPEKTATOR TOGGLE ──────────────────────
btnSpek.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end

    if not isSpectating then
        local targetChar = selectedPlayer.Character
        if not targetChar then return end
        local sub = targetChar:FindFirstChildOfClass("Humanoid") or targetChar:FindFirstChild("HumanoidRootPart")
        if not sub then return end
        isSpectating         = true
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = sub
        btnSpek.Text             = "stop"
        btnSpek.BackgroundColor3 = Color3.fromRGB(160, 50, 50)

        -- Loop ikuti target kalau ganti character
        task.spawn(function()
            while isSpectating do
                local tc = selectedPlayer and selectedPlayer.Character
                if tc then
                    local s = tc:FindFirstChildOfClass("Humanoid") or tc:FindFirstChild("HumanoidRootPart")
                    if s then Camera.CameraSubject = s end
                end
                task.wait(0.5)
            end
        end)
    else
        isSpectating = false
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = myHum
        btnSpek.Text             = "spek"
        btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
    end
end)

print("[OK] BringGui loaded!")
