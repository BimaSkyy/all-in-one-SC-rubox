-- BangGui – Sidebar kiri: Mode dropdown, Panel kanan: daftar pemain & tombol aksi vertikal
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Camera            = workspace.CurrentCamera

-- ── State ─────────────────────────────
local selectedPlayer  = nil
local isBanging       = false
local isSpectating    = false
local selectedMode    = "lari gila"
local modeOptions     = { "lari gila", "kanan 1000", "kiri 1000" }
local playerButtons   = {}

-- ── GUI ───────────────────────────────
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name           = "BangGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

-- Container utama (tengah layar, draggable)
local container = Instance.new("Frame", gui)
container.Size             = UDim2.new(0, 260, 0, 320)
container.Position         = UDim2.new(0.5, -130, 0.5, -160)  -- tengah layar
container.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
container.BorderSizePixel  = 0
container.ZIndex           = 10
container.ClipsDescendants = true
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", container).Color = Color3.fromRGB(90, 50, 160)

-- ── Header (drag handle) ─────────────
local header = Instance.new("TextButton", container)
header.Size             = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(75, 45, 120)
header.Text             = "  Player Actions"
header.TextColor3       = Color3.new(1,1,1)
header.Font             = Enum.Font.GothamBold
header.TextSize         = 13
header.TextXAlignment   = Enum.TextXAlignment.Left
header.AutoButtonColor  = false
header.ZIndex           = 20
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

-- Drag container
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── SIDEBAR KIRI (mode dropdown) ─────
local leftSidebar = Instance.new("Frame", container)
leftSidebar.Size             = UDim2.new(0, 90, 1, -28)
leftSidebar.Position         = UDim2.new(0, 0, 0, 28)
leftSidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
leftSidebar.BorderSizePixel  = 0
leftSidebar.ZIndex           = 11

local sidebarLabel = Instance.new("TextLabel", leftSidebar)
sidebarLabel.Size             = UDim2.new(1, 0, 0, 20)
sidebarLabel.Position         = UDim2.new(0, 0, 0, 4)
sidebarLabel.BackgroundTransparency = 1
sidebarLabel.Text             = "Mode"
sidebarLabel.TextColor3       = Color3.fromRGB(180,170,200)
sidebarLabel.Font             = Enum.Font.GothamBold
sidebarLabel.TextSize         = 11
sidebarLabel.ZIndex           = 12

-- Dropdown mode
local btnMode = Instance.new("TextButton", leftSidebar)
btnMode.Size             = UDim2.new(1, -12, 0, 26)
btnMode.Position         = UDim2.new(0, 6, 0, 26)
btnMode.Text             = selectedMode
btnMode.Font             = Enum.Font.GothamBold
btnMode.TextSize         = 11
btnMode.BackgroundColor3 = Color3.fromRGB(55,50,80)
btnMode.TextColor3       = Color3.new(1,1,1)
btnMode.ZIndex           = 13
Instance.new("UICorner", btnMode).CornerRadius = UDim.new(0, 6)

local dropFrame = Instance.new("Frame", leftSidebar)
dropFrame.Size             = UDim2.new(1, -12, 0, #modeOptions*24+6)
dropFrame.Position         = UDim2.new(0, 6, 0, 54)
dropFrame.BackgroundColor3 = Color3.fromRGB(30,30,45)
dropFrame.Visible          = false
dropFrame.ZIndex           = 14
Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0,6)

for i, opt in ipairs(modeOptions) do
    local ob = Instance.new("TextButton", dropFrame)
    ob.Size             = UDim2.new(1, -4, 0, 22)
    ob.Position         = UDim2.new(0, 2, 0, (i-1)*24+2)
    ob.Text             = opt
    ob.Font             = Enum.Font.Gotham
    ob.TextSize         = 11
    ob.BackgroundColor3 = Color3.fromRGB(40,40,60)
    ob.TextColor3       = Color3.new(1,1,1)
    ob.ZIndex           = 15
    Instance.new("UICorner", ob).CornerRadius = UDim.new(0,5)
    ob.MouseButton1Click:Connect(function()
        selectedMode = opt
        btnMode.Text = opt
        dropFrame.Visible = false
    end)
end

btnMode.MouseButton1Click:Connect(function()
    dropFrame.Visible = not dropFrame.Visible
end)

-- ── PANEL KANAN (daftar pemain + tombol aksi) ──
local rightPanel = Instance.new("Frame", container)
rightPanel.Size             = UDim2.new(1, -90, 1, -28)
rightPanel.Position         = UDim2.new(0, 90, 0, 28)
rightPanel.BackgroundColor3 = Color3.fromRGB(18,18,28)
rightPanel.BorderSizePixel  = 0
rightPanel.ZIndex           = 11

-- Tombol aksi (vertikal kanan atas)
local actionFrame = Instance.new("Frame", rightPanel)
actionFrame.Size     = UDim2.new(0, 60, 1, 0)
actionFrame.Position = UDim2.new(1, -60, 0, 0)
actionFrame.BackgroundTransparency = 1
actionFrame.ZIndex   = 12

local actionLayout = Instance.new("UIListLayout", actionFrame)
actionLayout.Padding       = UDim.new(0, 5)
actionLayout.SortOrder     = Enum.SortOrder.LayoutOrder
actionLayout.FillDirection = Enum.FillDirection.Vertical
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
actionLayout.Padding       = UDim.new(0, 5)

local function makeActionBtn(text, color)
    local btn = Instance.new("TextButton", actionFrame)
    btn.Size             = UDim2.new(1, -10, 0, 28)
    btn.Text             = text
    btn.BackgroundColor3 = color
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.ZIndex           = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local btnBang   = makeActionBtn("bang", Color3.fromRGB(210, 40, 40))
local btnSpek   = makeActionBtn("spek", Color3.fromRGB(30, 90, 180))
local btnTpHim  = makeActionBtn("tp",   Color3.fromRGB(160, 100, 20))
local btnGetW   = makeActionBtn("getW", Color3.fromRGB(30, 130, 80))

-- Scroller daftar pemain (sisa space di kiri actionFrame)
local scroller = Instance.new("ScrollingFrame", rightPanel)
scroller.Size             = UDim2.new(1, -64, 1, -4)
scroller.Position         = UDim2.new(0, 2, 0, 2)
scroller.BackgroundTransparency = 1
scroller.ScrollBarThickness   = 3
scroller.ScrollBarImageColor3 = Color3.fromRGB(160, 80, 255)
scroller.CanvasSize       = UDim2.new(0, 0, 0, 0)
scroller.ZIndex           = 12

local layout = Instance.new("UIListLayout", scroller)
layout.Padding       = UDim.new(0, 3)
layout.SortOrder     = Enum.SortOrder.Name
layout.FillDirection = Enum.FillDirection.Vertical

-- ── Player List ───────────────────────
local function updateCanvasSize()
    task.wait(0.05)
    scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
end

local function setSelected(plr)
    for _, data in pairs(playerButtons) do
        if data.btn and data.btn.Parent then
            data.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
        end
    end
    if selectedPlayer == plr then
        selectedPlayer = nil
        if isSpectating then
            isSpectating = false
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            Camera.CameraType    = Enum.CameraType.Custom
            Camera.CameraSubject = myHum
            btnSpek.Text = "spek"
            btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
        end
    else
        selectedPlayer = plr
        local d = playerButtons[plr.Name]
        if d and d.btn and d.btn.Parent then
            d.btn.BackgroundColor3 = Color3.fromRGB(130, 50, 200)
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
            btnSpek.Text = "spek"
            btnSpek.BackgroundColor3 = Color3.fromRGB(30, 90, 180)
        end
    end
    updateCanvasSize()
end

for _, plr in ipairs(Players:GetPlayers()) do addPlayerBtn(plr) end
Players.PlayerAdded:Connect(addPlayerBtn)
Players.PlayerRemoving:Connect(removePlayerBtn)

-- ── Action Functions ─────────────────
btnGetW.MouseButton1Click:Connect(function()
    pcall(function()
        ReplicatedStorage.RE["1Too1l"]:InvokeServer("PickingTools","Couch")
    end)
    btnGetW.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
    task.wait(0.25)
    btnGetW.BackgroundColor3 = Color3.fromRGB(30, 130, 80)
end)

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
        btnSpek.Text = "stop"
        btnSpek.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    else
        isSpectating = false
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Camera.CameraType    = Enum.CameraType.Custom
        Camera.CameraSubject = myHum
        btnSpek.Text = "spek"
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
    pcall(function() myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,-3) end)
    btnTpHim.BackgroundColor3 = Color3.fromRGB(220, 160, 40)
    task.wait(0.2)
    btnTpHim.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
end)

-- ── Helpers (equip & spin) ───────────
local function isToolEquipped()
    local c = LocalPlayer.Character; if not c then return false end
    for _, v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return true end end
    return false
end

local function equipToolFromBackpack()
    local c = LocalPlayer.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if isToolEquipped() then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") then hum:EquipTool(v); task.wait(0.15); return true end end end
    return false
end

local function waitEquip(mx)
    local t=0 while not isToolEquipped() and t<mx do task.wait(0.05); t+=0.05 end
end

local function waitUnequip(hum, mx)
    local t=0 while isToolEquipped() and t<mx do pcall(function() hum:UnequipTools() end) task.wait(0.05); t+=0.05 end
end

-- ── BANG ──────────────────────────────
btnBang.MouseButton1Click:Connect(function()
    if isBanging then return end
    if not selectedPlayer then return end
    local target=selectedPlayer; local tc=target.Character; if not tc then return end
    local mc=LocalPlayer.Character; if not mc then return end
    local myHRP=mc:FindFirstChild("HumanoidRootPart"); local myHum=mc:FindFirstChildOfClass("Humanoid")
    if not myHRP or not myHum then return end

    isBanging=true
    btnBang.BackgroundColor3=Color3.fromRGB(100,25,25); btnBang.Text="..."

    task.spawn(function()
        local orig=myHRP.CFrame
        equipToolFromBackpack(); waitEquip(1.5)
        local tHRP=tc:FindFirstChild("HumanoidRootPart")
        if tHRP then pcall(function() myHRP.CFrame=CFrame.new(tHRP.Position+Vector3.new(0,-2,0)) end) end
        task.wait(0.03)
        local mode=selectedMode

        local p1Done=false; local p1Start=tick(); local p1Conn
        p1Conn=RunService.Heartbeat:Connect(function()
            local t=tick()-p1Start
            if t>=1 then p1Conn:Disconnect(); p1Done=true; return end
            local h=tc:FindFirstChild("HumanoidRootPart"); if not h then return end
            pcall(function() myHRP.CFrame=CFrame.new(h.Position+Vector3.new(0,-2,0))*CFrame.Angles(0,t*math.pi*12,0) end)
        end)
        repeat task.wait(0.03) until p1Done

        if mode=="lari gila" then
            local sky=myHRP.Position+Vector3.new(0,500,0)
            pcall(function() myHRP.CFrame=CFrame.new(sky) end)
            task.wait(0.03)
            local p2Done=false; local p2Start=tick(); local ueq=false; local rng=Random.new(); local p2Conn
            p2Conn=RunService.Heartbeat:Connect(function()
                local t=tick()-p2Start
                if t>=1.2 then
                    if not ueq then ueq=true; pcall(function() myHum:UnequipTools() end) end
                    pcall(function() myHRP.CFrame=CFrame.new(sky) end)
                    if t>=1.5 then p2Conn:Disconnect(); p2Done=true end
                    return
                end
                local r=30+t*15
                pcall(function() myHRP.CFrame=CFrame.new(sky+Vector3.new(rng:NextNumber(-r,r),rng:NextNumber(-8,8),rng:NextNumber(-r,r)))*CFrame.Angles(0,t*math.pi*20,0) end)
            end)
            repeat task.wait(0.03) until p2Done
        else
            local base=myHRP.Position; local dir=(mode=="kanan 1000")and 1 or-1
            local p2Done=false; local p2Start=tick(); local ueq=false; local p2Conn
            p2Conn=RunService.Heartbeat:Connect(function()
                local t=tick()-p2Start
                if t<0.8 then
                    local dist=(t/0.8)*100
                    pcall(function() myHRP.CFrame=CFrame.new(base+Vector3.new(dir*dist,0,0))*CFrame.Angles(0,t*math.pi*20,0) end)
                else
                    if not ueq then ueq=true; pcall(function() myHum:UnequipTools() end) end
                    pcall(function() myHRP.CFrame=CFrame.new(base+Vector3.new(dir*100,0,0)) end)
                    if t>=1.1 then p2Conn:Disconnect(); p2Done=true end
                end
            end)
            repeat task.wait(0.03) until p2Done
        end

        waitUnequip(myHum,1)
        task.wait(0.05); pcall(function() myHRP.CFrame=orig end)
        task.wait(0.08); pcall(function() myHRP.CFrame=orig end)
        isBanging=false
        btnBang.BackgroundColor3=Color3.fromRGB(210,40,40); btnBang.Text="bang"
    end)
end)