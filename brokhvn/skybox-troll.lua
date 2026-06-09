-- Skybox Trolling Lengkap & Stabil
if not game:IsLoaded() then game.Loaded:Wait() end

-- Layanan Utama
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local isSkyboxOn = false
local skyboxTrack = nil
local savedBody = {}
local isSpinOn = false
local spinBodyVel = nil

-- Ambil Remote Tubuh
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local ChangeBody = Remotes:WaitForChild("ChangeCharacterBody", 5)
local ResetBody = Remotes:WaitForChild("ResetCharacterAppearance", 5)

-- Fungsi Simpan/Kembalikan Tubuh
local function saveCurrentBody(humanoid)
    if not humanoid then return {} end
    local desc = humanoid:GetAppliedDescription()
    return {
        Torso = desc.Torso,
        RightArm = desc.RightArm,
        LeftArm = desc.LeftArm,
        RightLeg = desc.RightLeg,
        LeftLeg = desc.LeftLeg,
        Head = desc.Head
    }
end

local function restoreBody(saved)
    if not saved or next(saved) == nil then return end
    local args = {
        saved.Torso,
        saved.RightArm,
        saved.LeftArm,
        saved.RightLeg,
        saved.LeftLeg,
        saved.Head
    }
    pcall(function() ChangeBody:InvokeServer(args) end)
end

-- Fungsi Animasi
local function playAnim(humanoid, animId, speed)
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0.1, 1, speed or 1)
    return track
end

-- ==============================================
-- GUI Dapat Digeser (Draggable)
-- ==============================================
local gui = Instance.new("ScreenGui")
gui.Name = "SkyboxTrollHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

-- Jendela Utama
local Window = Instance.new("Frame")
Window.Name = "MainWindow"
Window.Size = UDim2.new(0, 190, 0, 95)
Window.Position = UDim2.new(0.35, 0, 0.3, 0)
Window.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", Window).Color = Color3.fromRGB(60, 50, 90)
Instance.new("UIStroke", Window).Thickness = 1.5
Window.Parent = gui

-- Bilah Judul (untuk geser)
local TitleBar = Instance.new("TextButton")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 26)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 25, 65)
TitleBar.Text = "🌌 Skybox V4 + Spin"
TitleBar.TextColor3 = Color3.new(1, 1, 1)
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextSize = 12
TitleBar.AutoButtonColor = false
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 7)
TitleBar.Parent = Window

-- Fungsi Geser
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

TitleBar.InputEnded:Connect(function() dragging = false end)

-- Tombol Skybox
local BtnSkybox = Instance.new("TextButton")
BtnSkybox.Name = "BtnSkybox"
BtnSkybox.Size = UDim2.new(1, -20, 0, 28)
BtnSkybox.Position = UDim2.new(0, 10, 0, 34)
BtnSkybox.BackgroundColor3 = Color3.fromRGB(85, 45, 160)
BtnSkybox.Text = "Skybox: OFF"
BtnSkybox.TextColor3 = Color3.new(1, 1, 1)
BtnSkybox.Font = Enum.Font.GothamBold
BtnSkybox.TextSize = 11
BtnSkybox.AutoButtonColor = false
Instance.new("UICorner", BtnSkybox).CornerRadius = UDim.new(0, 5)
BtnSkybox.Parent = Window

-- Tombol Spin
local BtnSpin = Instance.new("TextButton")
BtnSpin.Name = "BtnSpin"
BtnSpin.Size = UDim2.new(1, -20, 0, 28)
BtnSpin.Position = UDim2.new(0, 10, 0, 66)
BtnSpin.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
BtnSpin.Text = "Spin: OFF"
BtnSpin.TextColor3 = Color3.new(1, 1, 1)
BtnSpin.Font = Enum.Font.GothamBold
BtnSpin.TextSize = 11
BtnSpin.AutoButtonColor = false
Instance.new("UICorner", BtnSpin).CornerRadius = UDim.new(0, 5)
BtnSpin.Parent = Window

-- ==============================================
-- Logika Skybox V4
-- ==============================================
BtnSkybox.MouseButton1Click:Connect(function()
    isSkyboxOn = not isSkyboxOn
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    if isSkyboxOn then
        savedBody = saveCurrentBody(hum)
        -- Terapkan tubuh khusus Skybox V4
        local bodyArgs = {
            96655874457685,
            123402086843885,
            78300682916056,
            86276701020724,
            78409653958165,
            120668655481073
        }
        pcall(function() ChangeBody:InvokeServer(bodyArgs) end)
        task.wait(0.2)
        -- Mainkan animasi
        skyboxTrack = playAnim(hum, "rbxassetid://70883871260184", 1)
        BtnSkybox.Text = "Skybox: ON"
        BtnSkybox.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
    else
        -- Hentikan animasi & kembalikan tubuh asli
        if skyboxTrack then pcall(function() skyboxTrack:Stop() skyboxTrack:Destroy() end) end
        restoreBody(savedBody)
        savedBody = {}
        skyboxTrack = nil
        BtnSkybox.Text = "Skybox: OFF"
        BtnSkybox.BackgroundColor3 = Color3.fromRGB(85, 45, 160)
    end
end)

-- ==============================================
-- Logika Spin
-- ==============================================
BtnSpin.MouseButton1Click:Connect(function()
    isSpinOn = not isSpinOn
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if isSpinOn then
        -- Aktifkan putaran
        spinBodyVel = Instance.new("BodyAngularVelocity")
        spinBodyVel.AngularVelocity = Vector3.new(0, 55, 0)
        spinBodyVel.MaxTorque = Vector3.new(0, 1e5, 0)
        spinBodyVel.P = 100000
        spinBodyVel.Parent = hrp
        BtnSpin.Text = "Spin: ON"
        BtnSpin.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
    else
        -- Matikan putaran
        if spinBodyVel then spinBodyVel:Destroy() spinBodyVel = nil end
        BtnSpin.Text = "Spin: OFF"
        BtnSpin.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
    end
end)

-- Perbarui jika karakter respawn
LocalPlayer.CharacterAdded:Connect(function()
    isSkyboxOn = false
    isSpinOn = false
    BtnSkybox.Text = "Skybox: OFF"
    BtnSkybox.BackgroundColor3 = Color3.fromRGB(85, 45, 160)
    BtnSpin.Text = "Spin: OFF"
    BtnSpin.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
end)
