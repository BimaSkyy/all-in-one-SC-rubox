-- // ============================================================ \\ --
-- //            AUTO STEAL VALUABLE + HOP (FAST)                  \\ --
-- // ============================================================ \\ --
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Modules (diperlukan untuk steal & kalkulasi nilai)
local Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
local FruitValueCalc = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("FruitValueCalc"))

-- ====================== BLACKLIST ======================
local BlacklistedNames = {
    ["BimaSky77"] = true,
    ["KianetsuTwo"] = true,
}

-- ====================== FUNGSI DASAR ======================
local function GetHumanoid(player)
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(player)
    local hum = GetHumanoid(player)
    return hum and hum.RootPart
end

local Plots = Workspace.Gardens
local function GetPlot(player)
    for _, plot in ipairs(Plots:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == player.UserId then
            return plot
        end
    end
    return nil
end

local function PlotUnlocked(player)
    local plot = GetPlot(player)
    if not plot then return true end
    local visual = plot:FindFirstChild("Visual")
    local area = visual and visual:FindFirstChild("PlotSizeReferenceVisual")
    if not area then return true end

    for _, part in ipairs(Workspace:GetPartBoundsInBox(area.CFrame, area.Size)) do
        if part:IsDescendantOf(player.Character) then
            return false
        end
    end
    return true
end

local function CalculateValue(fruit)
    local fruitName = fruit:GetAttribute("CorePartName") or fruit:GetAttribute("PlantName")
    local sizeMultiplier = fruit:GetAttribute("SizeMulti") or fruit:GetAttribute("Age")
    local mutation = fruit:GetAttribute("Mutation")
    return FruitValueCalc(fruitName, sizeMultiplier, mutation, LocalPlayer, 1)
end

local function GetValuable()
    local bestValue = 0
    local bestItem = nil

    for _, plot in ipairs(Plots:GetChildren()) do
        local ownerId = plot:GetAttribute("OwnerUserId") or LocalPlayer.UserId
        local owner = Players:GetPlayerByUserId(ownerId)
        if not owner or owner == LocalPlayer then continue end

        -- BLACKLIST CHECK
        if BlacklistedNames[owner.Name] then
            continue
        end

        local hum = GetHumanoid(owner)
        if hum and hum.Sit then continue end  -- abaikan yang sedang duduk

        local plants = plot:FindFirstChild("Plants")
        if not plants then continue end

        for _, plant in ipairs(plants:GetChildren()) do
            local fruitsFolder = plant:FindFirstChild("Fruits")
            local found = {}

            if fruitsFolder then
                for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                    local harvestPart = fruit:FindFirstChild("HarvestPart")
                    if harvestPart and harvestPart:FindFirstChild("StealPrompt") then
                        found[fruit] = CalculateValue(fruit)
                    end
                end
            else
                local harvestPart = plant:FindFirstChild("HarvestPart")
                if harvestPart and harvestPart:FindFirstChild("StealPrompt") then
                    found[plant] = CalculateValue(plant)
                end
            end

            for item, val in pairs(found) do
                if val > bestValue then
                    bestValue = val
                    bestItem = item
                end
            end
        end
    end

    return bestItem, bestValue
end

local function Fling(targetPlayer)
    local myRoot = GetRoot(LocalPlayer)
    local myHum = GetHumanoid(LocalPlayer)
    if not myRoot or not myHum then return end
    local oldPos = myRoot.CFrame

    local flinging = true
    task.spawn(function()
        local movel = 0.1
        while flinging do
            local vel = myRoot.Velocity
            myRoot.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if myRoot and myRoot.Parent then
                myRoot.Velocity = vel
            end
            RunService.Stepped:Wait()
            if myRoot and myRoot.Parent then
                myRoot.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
            if not flinging then break end
            task.wait()
        end
    end)

    local targetHum = GetHumanoid(targetPlayer)
    local targetRoot = GetRoot(targetPlayer)
    if targetHum and targetRoot then
        local start = tick()
        repeat
            local success, _ = pcall(function()
                sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
            end)
            local mag = targetRoot.Velocity.Magnitude
            local dir = targetHum.MoveDirection or Vector3.zero
            local offset
            if mag < 5 or success then
                offset = Vector3.new(0, math.random(-0.5, 0.4), 0)
            else
                offset = dir * (mag / Random.new():NextNumber(0.7, 8)) - Vector3.new(0, math.random(-1, 1), 0)
            end
            myHum.Sit = false
            workspace.CurrentCamera.CameraSubject = targetHum
            myRoot.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(offset) * CFrame.Angles(0, math.rad(math.random(0,360)), 0)
            task.wait()
        until (tick() - start >= 2) or (targetRoot.Velocity.Magnitude > 200) or not myRoot.Parent or not targetRoot.Parent
    end

    flinging = false
    myRoot.CFrame = oldPos
    workspace.CurrentCamera.CameraSubject = myHum
    pcall(function()
        sethiddenproperty(myRoot, "PhysicsRepRootPart", nil)
    end)
end

local function ReturnToPlot()
    local plot = GetPlot(LocalPlayer)
    if not plot then return end
    local ref = plot:FindFirstChild("PlotSizeReference")
    if not ref then return end
    for _ = 1, 5 do                       -- lebih cepat: 5 kali saja
        local root = GetRoot(LocalPlayer)
        if root then
            root.CFrame = ref.CFrame
            task.wait(0.02)               -- delay minimal
        end
    end
end

local function NightTime()
    local night = ReplicatedStorage:FindFirstChild("Night")
    return night and night.Value == true
end

local function Steal(fruit)
    if not NightTime() then return end
    local harvestPart = fruit and fruit:FindFirstChild("HarvestPart")
    local stealPrompt = harvestPart and harvestPart:FindFirstChild("StealPrompt")
    if not stealPrompt then return end

    local userId = tonumber(fruit:GetAttribute("UserId"))
    local plantId = fruit:GetAttribute("PlantId")
    local fruitId = fruit:GetAttribute("FruitId")
    local owner = Players:GetPlayerByUserId(userId)

    if owner and BlacklistedNames[owner.Name] then
        return
    end

    if owner and not PlotUnlocked(owner) then
        Fling(owner)
    end

    local root = GetRoot(LocalPlayer)
    if root then
        root.CFrame = harvestPart.CFrame
        Networking.Steal.BeginSteal:Fire(userId, plantId, fruitId or "")
        Networking.Steal.CompleteSteal:Fire()
        task.wait(0.01)                  -- lebih cepat dari 0.05 sebelumnya
    end
end

-- ====================== ANTI FLING (SELALU ON) ======================
local antiFlingConnection = nil
local function enableAntiFling()
    if antiFlingConnection then return end
    antiFlingConnection = RunService.Stepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
end

-- ====================== STATE & GUI ======================
local Settings = {
    StealActive = false,
    Minimized = false,
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValuableStealTool"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

-- Header
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 26)
TitleBar.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 6)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.Text = "Valuable Steal"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
MinimizeBtn.Position = UDim2.new(1, -26, 0, 2)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TitleBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

-- Content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -26)
ContentFrame.Position = UDim2.new(0, 0, 0, 26)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Tombol AutoSteal
local AutoStealButton = Instance.new("TextButton")
AutoStealButton.Size = UDim2.new(1, -10, 0, 24)
AutoStealButton.Position = UDim2.new(0, 5, 0, 4)
AutoStealButton.Text = "AutoSteal: ON"
AutoStealButton.Font = Enum.Font.GothamBold
AutoStealButton.TextSize = 10
AutoStealButton.TextColor3 = Color3.new(1, 1, 1)
AutoStealButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
AutoStealButton.BorderSizePixel = 0
AutoStealButton.Parent = ContentFrame
Instance.new("UICorner", AutoStealButton).CornerRadius = UDim.new(0, 4)

-- Tombol Hop Server
local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(1, -10, 0, 24)
HopButton.Position = UDim2.new(0, 5, 0, 34)
HopButton.Text = "Hop Server"
HopButton.Font = Enum.Font.GothamBold
HopButton.TextSize = 10
HopButton.TextColor3 = Color3.new(1, 1, 1)
HopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
HopButton.BorderSizePixel = 0
HopButton.Parent = ContentFrame
Instance.new("UICorner", HopButton).CornerRadius = UDim.new(0, 4)

-- Ukuran frame (dua tombol, tinggi total 26 + 58 = 84)
local expandedHeight = 26 + 58
MainFrame.Size = UDim2.new(0, 120, 0, expandedHeight)
MainFrame.Position = UDim2.new(0.5, -60, 0, 10)

-- Minimize logic
local function applyMinimizeState()
    if Settings.Minimized then
        MainFrame.Size = UDim2.new(0, 120, 0, 26)
        MinimizeBtn.Text = "+"
        ContentFrame.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 120, 0, expandedHeight)
        MinimizeBtn.Text = "-"
        ContentFrame.Visible = true
    end
end

MinimizeBtn.MouseButton1Click:Connect(function()
    Settings.Minimized = not Settings.Minimized
    applyMinimizeState()
end)

-- ====================== LOOP UTAMA (lebih cepat) ======================
task.spawn(function()
    while true do
        task.wait(0.5)   -- cek lebih sering
        if Settings.StealActive and NightTime() then
            -- Curi 5 buah per putaran agar perjalanan pulang lebih jarang
            for _ = 1, 5 do
                if not Settings.StealActive or not NightTime() then break end
                local valuable = GetValuable()
                Steal(valuable)
            end
            if Settings.StealActive and NightTime() then
                ReturnToPlot()
            end
        end
    end
end)

AutoStealButton.MouseButton1Click:Connect(function()
    Settings.StealActive = not Settings.StealActive
    if Settings.StealActive then
        AutoStealButton.Text = "AutoSteal: ON"
        AutoStealButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    else
        AutoStealButton.Text = "AutoSteal: OFF"
        AutoStealButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end
end)

-- ====================== HOP SERVER ======================
HopButton.MouseButton1Click:Connect(function()
    pcall(function()
        Networking.AntiAfk.RequestHop:Fire()
    end)
end)

-- ====================== DEFAULT ON ======================
Settings.StealActive = true
enableAntiFling()

LocalPlayer.CharacterAdded:Connect(function()
    enableAntiFling()
end)

print("Valuable Steal tool loaded. AntiFling always ON, fast steal, Hop button ready.")
