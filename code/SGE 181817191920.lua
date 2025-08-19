-- ✅ Cek Game
if game.PlaceId ~= 126884695634066 then return end
while not game:IsLoaded() do game.Loaded:Wait() end

-- ✅ Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ✅ Remotes
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local BuySeedRemote = GameEvents:WaitForChild("BuySeedStock")
local BuyGearRemote = GameEvents:WaitForChild("BuyGearStock")
local BuyEggRemote = GameEvents:WaitForChild("BuyPetEgg")

-- ✅ Data
local seedData = require(ReplicatedStorage.Data.SeedData)
local gearData = require(ReplicatedStorage.Data.GearData)
local eggNames = {
    "Common Egg", "Uncommon Egg", "Rare Egg",
    "Legendary Egg", "Mythical Egg",
    "Common Summer Egg", "Paradise Egg", "Bug Egg"
}

-- Kumpulin nama seed & gear dari data module
local seedNames, gearNames = {}, {}
for k,v in pairs(seedData) do if v.DisplayInShop then table.insert(seedNames,k) end end
for _,v in pairs(gearData) do if v.DisplayInShop then table.insert(gearNames,v.GearName) end end

-- ✅ State toggle
local autoBuySeeds, autoBuyGear, autoBuyEggs = false, false, false

-- ✅ GUI
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "AutoFarmGui"
screenGui.ResetOnSpawn = false

-- Tombol utama bulat 🔮
local mainBtn = Instance.new("ImageButton")
mainBtn.Size = UDim2.new(0,42,0,42)
mainBtn.Position = UDim2.new(1,-60,0.5,-21)
mainBtn.BackgroundColor3 = Color3.fromRGB(50,50,80)
mainBtn.Image = "rbxassetid://3926305904" -- bulat icon
mainBtn.ImageRectOffset = Vector2.new(4,4)
mainBtn.ImageRectSize = Vector2.new(36,36)
mainBtn.Parent = screenGui
Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(1,0)

-- Panel toggle compact
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,160,0,120)
frame.Position = UDim2.new(1,-210,0.5,-60)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0.1,0)

-- Fungsi buat toggle kecil rapi
local function makeToggle(text, order, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-10,0,28)
    btn.Position = UDim2.new(0,5,0,(order-1)*35+5)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text..": OFF"
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text..": "..(state and "ON" or "OFF")
        callback(state)
    end)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.2,0)
end

-- Toggle frame buka/tutup
mainBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- ✅ Toggle buttons
makeToggle("Auto Buy Seeds 🌱", 1, function(v) autoBuySeeds=v end)
makeToggle("Auto Buy Gear ⚙️", 2, function(v) autoBuyGear=v end)
makeToggle("Auto Buy Eggs 🥚", 3, function(v) autoBuyEggs=v end)

-- ✅ Loop Auto Buy
task.spawn(function()
    while task.wait(0.5) do
        if autoBuySeeds then
            for _, name in ipairs(seedNames) do
                pcall(function() BuySeedRemote:FireServer(name) end)
                task.wait(0.1)
            end
        end
        if autoBuyGear then
            for _, name in ipairs(gearNames) do
                pcall(function() BuyGearRemote:FireServer(name) end)
                task.wait(0.1)
            end
        end
        if autoBuyEggs then
            for _, name in ipairs(eggNames) do
                pcall(function() BuyEggRemote:FireServer(name) end)
                task.wait(0.3)
            end
        end
    end
end)

-- ✅ Drag main button (Android & PC)
do
    local dragging, dragInput, mousePos, btnPos
    local function update(input)
        local delta = input.Position - mousePos
        mainBtn.Position = UDim2.new(btnPos.X.Scale, btnPos.X.Offset + delta.X,
                                     btnPos.Y.Scale, btnPos.Y.Offset + delta.Y)
        frame.Position = mainBtn.Position - UDim2.new(0,170,0,0)
    end
    mainBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            btnPos = mainBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    mainBtn.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            dragInput=input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input==dragInput and dragging then update(input) end
    end)
end
