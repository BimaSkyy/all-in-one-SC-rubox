-- Skybox Trolling (Skybox ON/OFF, Spin ON/OFF) – draggable
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local isSkyboxOn = false
local skyboxTrack = nil
local isSpinOn = false
local spinBodyVel = nil

-- Fungsi anim2track
local function anim2track(id)
    local objs = game:GetObjects(id)
    for _, obj in ipairs(objs) do
        if obj:IsA("Animation") then return obj.AnimationId end
    end
    return id
end

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "SkyboxTrollGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 180, 0, 80)
win.Position = UDim2.new(0, 390, 0.28, 0)
win.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
win.BorderSizePixel = 0
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", win).Color = Color3.fromRGB(50, 42, 80)

-- Title (TextButton untuk drag)
local title = Instance.new("TextButton", win)
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
title.Text = "Skybox Trolling"
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

-- Tombol Skybox
local btnSky = Instance.new("TextButton", win)
btnSky.Size = UDim2.new(1, -16, 0, 26)
btnSky.Position = UDim2.new(0, 8, 0, 28)
btnSky.BackgroundColor3 = Color3.fromRGB(72, 32, 140)
btnSky.Text = "Skybox: OFF"
btnSky.TextColor3 = Color3.new(1,1,1)
btnSky.Font = Enum.Font.GothamBold
btnSky.TextSize = 11
Instance.new("UICorner", btnSky).CornerRadius = UDim.new(0, 4)

-- Tombol Spin
local btnSpin = Instance.new("TextButton", win)
btnSpin.Size = UDim2.new(1, -16, 0, 26)
btnSpin.Position = UDim2.new(0, 8, 0, 58)
btnSpin.BackgroundColor3 = Color3.fromRGB(155, 28, 28)
btnSpin.Text = "Spin: OFF"
btnSpin.TextColor3 = Color3.new(1,1,1)
btnSpin.Font = Enum.Font.GothamBold
btnSpin.TextSize = 11
Instance.new("UICorner", btnSpin).CornerRadius = UDim.new(0, 4)

-- Notif
local function notify(msg)
    print("[SkyboxTroll]", msg)
end

-- Logic
btnSky.MouseButton1Click:Connect(function()
    isSkyboxOn = not isSkyboxOn
    if isSkyboxOn then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum then notify("Humanoid tidak ada"); isSkyboxOn = false; return end
        local asset = "rbxassetid://93224413172183"
        local realId = anim2track(asset)
        local anim = Instance.new("Animation")
        anim.AnimationId = realId
        skyboxTrack = hum:LoadAnimation(anim)
        skyboxTrack.Priority = Enum.AnimationPriority.Movement
        skyboxTrack:Play()
        btnSky.Text = "Skybox: ON"
        btnSky.BackgroundColor3 = Color3.fromRGB(52,168,83)
        notify("Skybox animasi mulai")
    else
        if skyboxTrack then skyboxTrack:Stop(); skyboxTrack:Destroy(); skyboxTrack = nil end
        btnSky.Text = "Skybox: OFF"
        btnSky.BackgroundColor3 = Color3.fromRGB(72, 32, 140)
        notify("Skybox animasi berhenti")
    end
end)

btnSpin.MouseButton1Click:Connect(function()
    isSpinOn = not isSpinOn
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if isSpinOn then
        if not hrp then notify("Karakter belum siap"); isSpinOn = false; return end
        local vel = Instance.new("BodyAngularVelocity")
        vel.AngularVelocity = Vector3.new(0, 50, 0)
        vel.MaxTorque = Vector3.new(0, 1e5, 0)
        vel.Parent = hrp
        spinBodyVel = vel
        btnSpin.Text = "Spin: ON"
        btnSpin.BackgroundColor3 = Color3.fromRGB(52,168,83)
        notify("Spin aktif")
    else
        if spinBodyVel then spinBodyVel:Destroy(); spinBodyVel = nil end
        btnSpin.Text = "Spin: OFF"
        btnSpin.BackgroundColor3 = Color3.fromRGB(155, 28, 28)
        notify("Spin mati")
    end
end)