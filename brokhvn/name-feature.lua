-- Name Feature (Set Nama, RGB, Animasi Nama) – draggable
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local storedName = "BmSkyMods"
local rgbActive = false
local animActive = false

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "NameFeatureGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 180, 0, 120)
win.Position = UDim2.new(0, 16, 0.28, 0)
win.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
win.BorderSizePixel = 0
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", win).Color = Color3.fromRGB(50, 42, 80)

-- Title (sekarang TextButton agar bisa drag)
local title = Instance.new("TextButton", win)
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
title.Text = "Name Feature"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.AutoButtonColor = false
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 6)

-- Drag functionality
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = win.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- TextBox
local nameBox = Instance.new("TextBox", win)
nameBox.Size = UDim2.new(1, -16, 0, 26)
nameBox.Position = UDim2.new(0, 8, 0, 30)
nameBox.BackgroundColor3 = Color3.fromRGB(55, 45, 95)
nameBox.Text = storedName
nameBox.TextColor3 = Color3.new(1,1,1)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 11
nameBox.PlaceholderText = "Nama..."
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 4)

-- Tombol Set
local btnSet = Instance.new("TextButton", win)
btnSet.Size = UDim2.new(1, -16, 0, 26)
btnSet.Position = UDim2.new(0, 8, 0, 60)
btnSet.BackgroundColor3 = Color3.fromRGB(22, 65, 130)
btnSet.Text = "Set"
btnSet.TextColor3 = Color3.new(1,1,1)
btnSet.Font = Enum.Font.GothamBold
btnSet.TextSize = 11
Instance.new("UICorner", btnSet).CornerRadius = UDim.new(0, 4)

-- Tombol RGB
local btnRgb = Instance.new("TextButton", win)
btnRgb.Size = UDim2.new(0, 80, 0, 26)
btnRgb.Position = UDim2.new(0, 8, 0, 90)
btnRgb.BackgroundColor3 = Color3.fromRGB(22, 65, 130)
btnRgb.Text = "RGB: OFF"
btnRgb.TextColor3 = Color3.new(1,1,1)
btnRgb.Font = Enum.Font.GothamBold
btnRgb.TextSize = 11
Instance.new("UICorner", btnRgb).CornerRadius = UDim.new(0, 4)

-- Tombol Anim
local btnAnim = Instance.new("TextButton", win)
btnAnim.Size = UDim2.new(0, 80, 0, 26)
btnAnim.Position = UDim2.new(0, 92, 0, 90)
btnAnim.BackgroundColor3 = Color3.fromRGB(72, 32, 140)
btnAnim.Text = "Anim: OFF"
btnAnim.TextColor3 = Color3.new(1,1,1)
btnAnim.Font = Enum.Font.GothamBold
btnAnim.TextSize = 11
Instance.new("UICorner", btnAnim).CornerRadius = UDim.new(0, 4)

-- Fungsi notifikasi kecil
local function notify(msg)
    print("[NameFeature]", msg)
end

-- Logic
btnSet.MouseButton1Click:Connect(function()
    local name = nameBox.Text
    if name == "" then notify("Nama kosong!") return end
    storedName = name
    notify("Nama diset: " .. name)
    pcall(function()
        ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", storedName)
    end)
end)

btnRgb.MouseButton1Click:Connect(function()
    rgbActive = not rgbActive
    if rgbActive then
        btnRgb.Text = "RGB: ON"
        btnRgb.BackgroundColor3 = Color3.fromRGB(52,168,83)
        task.spawn(function()
            while rgbActive do
                pcall(function()
                    ReplicatedStorage.RE["1RPNam1eColo1r"]:FireServer("PickingRPNameColor", Color3.new(math.random(), math.random(), math.random()))
                end)
                task.wait(0.15)
            end
        end)
    else
        btnRgb.Text = "RGB: OFF"
        btnRgb.BackgroundColor3 = Color3.fromRGB(22, 65, 130)
    end
end)

btnAnim.MouseButton1Click:Connect(function()
    animActive = not animActive
    if animActive then
        btnAnim.Text = "Anim: ON"
        btnAnim.BackgroundColor3 = Color3.fromRGB(52,168,83)
        task.spawn(function()
            while animActive do
                local name = storedName
                local send = name
                local r = math.random(1,4)
                if r == 1 then
                    local sc = ""
                    for _=1,#name do sc = sc .. string.char(math.random(65,90)) end
                    send = sc
                elseif r == 2 then
                    local rev = math.random(1,#name)
                    send = string.sub(name,1,rev) .. string.rep(" ",#name-rev)
                elseif r == 3 then
                    send = string.reverse(name)
                end
                pcall(function()
                    ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", send)
                end)
                task.wait(0.3)
            end
            pcall(function()
                ReplicatedStorage.RE["1RPNam1eTex1t"]:FireServer("RolePlayName", storedName)
            end)
        end)
    else
        btnAnim.Text = "Anim: OFF"
        btnAnim.BackgroundColor3 = Color3.fromRGB(72, 32, 140)
    end
end)