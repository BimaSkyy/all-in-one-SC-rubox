-- Items Troll (Take All, Hand All, Remove All) – draggable
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local isActionRunning = false
local ITEM_LIST = {
    "Laptop","GeigerCounter","Phone","Tablet","ShoppingCart","Paperbag",
    "Sign","Score Card","Book","Newspaper","Envelope","Paper","ClipBoard",
    "Ticket","Licence","BabyBoy","BabyGirl","BabyBottle","BabyRattle",
    "Stroller","BabyHippo","BabyMonkey","Stretcher","Stethoscope","Medicine",
    "DuffleBagMoney","DuffleBag","Ear","Money","CreditCardBoy","Megaphone",
    "GhostMeter","HandRadio","CreditCardGirl","DSLR Camera","ClapperBoard",
    "Microphone","Camcorder","Axe","Hammer","StopSign","FireX","Wrench",
    "Cones","GlowingBatons","Ladder","Shovel","Wheelbarrow","LawnMower",
    "WateringCan","HorseBrush","Vacuum","PaintRoller","WhistleAndRefereeCards",
    "Mop","SWATShield","Cuffs","Taser","Glock","GlockBrown","Shotgun",
    "AA-12","Assault","AUG","Sniper","Bow","SwordWood","Katana",
    "HandheldFan","Bomb","SnackBox","FoodCart","TakeOutHappyBurger",
    "TakeOut","FoodTray","TakeOutPizza","PrisonTray","BreakfestPlate1",
    "SubwayTray","DinnerPlate3","DinnerPlate1"
}

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "ItemsTrollGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 180, 0, 120)
win.Position = UDim2.new(0, 200, 0.28, 0)
win.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
win.BorderSizePixel = 0
win.ClipsDescendants = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", win).Color = Color3.fromRGB(50, 42, 80)

-- Title (TextButton agar bisa drag)
local title = Instance.new("TextButton", win)
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundColor3 = Color3.fromRGB(28, 18, 55)
title.Text = "Items Troll"
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

-- Helper tombol
local function makeBtn(y, text, color)
    local b = Instance.new("TextButton", win)
    b.Size = UDim2.new(1, -16, 0, 26)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local btnTake = makeBtn(30, "Take All", Color3.fromRGB(28, 105, 55))
local btnHand = makeBtn(62, "Hand All", Color3.fromRGB(120, 78, 8))
local btnRemove = makeBtn(94, "Remove All", Color3.fromRGB(155, 28, 28))

-- Notif
local function notify(msg)
    print("[ItemsTroll]", msg)
end

-- State action
local function startAction(btn, name)
    if isActionRunning then
        notify("Tunggu " .. name .. " selesai!")
        return false
    end
    isActionRunning = true
    btn.Text = "Loading..."
    btn.Active = false
    return true
end

local function finishAction(btn, original)
    btn.Text = original
    btn.Active = true
    isActionRunning = false
end

-- Logika
btnTake.MouseButton1Click:Connect(function()
    if not startAction(btnTake, "Take All") then return end
    task.spawn(function()
        local re = ReplicatedStorage:FindFirstChild("RE")
        if not re or not re:FindFirstChild("1Too1l") then
            notify("Remote tidak ada!")
            finishAction(btnTake, "Take All")
            return
        end
        local remote = re["1Too1l"]
        local ok = 0
        for _, item in ipairs(ITEM_LIST) do
            task.wait(0.3)
            if pcall(function() remote:InvokeServer("PickingTools", item) end) then ok = ok + 1 end
        end
        notify(ok .. "/" .. #ITEM_LIST .. " item diambil")
        finishAction(btnTake, "Take All")
    end)
end)

btnHand.MouseButton1Click:Connect(function()
    if not startAction(btnHand, "Hand All") then return end
    task.spawn(function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        if not bp or not char then
            notify("Tidak ada inventory/char")
            finishAction(btnHand, "Hand All")
            return
        end
        local count = 0
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                task.wait(0.15)
                pcall(function() tool.Parent = char end)
                count = count + 1
            end
        end
        notify(count .. " item dipegang")
        finishAction(btnHand, "Hand All")
    end)
end)

btnRemove.MouseButton1Click:Connect(function()
    if not startAction(btnRemove, "Remove All") then return end
    task.spawn(function()
        pcall(function()
            ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("ClearAllTools")
        end)
        notify("Semua item dihapus")
        finishAction(btnRemove, "Remove All")
    end)
end)