-- 🔧 Konfigurasi
local PANEN_DELAY = 0.1 -- jeda antar panen buah
local SUBMIT_DELAY = 0.5   -- detik antar submit event
local CLAIM_DELAY = 0.5    -- jeda antar claim reward
local CLAIM_COUNT = 10   -- jumlah claim reward

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ge = ReplicatedStorage:WaitForChild("GameEvents")
local submitRemote = ge:WaitForChild("BeanstalkRESubmitAllPlant")
local claimRemote = ge:WaitForChild("BeanstalkREClaimReward")

-- Billboard Progress
local progressLabel = workspace.Interaction.UpdateItems.BeanstalkEvent.BeanstalkSprout
    .BeanStalkTimer.ProgressBilboard.UpgradeBar.ProgressionLabel

-- Categories mapping
local Categories = {
    ["Berry Plants"] = {"Blueberry","Strawberry","Grape"},
    ["Vegetable Plants"] = {"Tomato","Corn","Carrot","Beanstalk","Pepper","Cauliflower"},
    ["Flower Plants"] = {"Serenity"},
    ["Spicy Plants"] = {"Pepper","Jalapeno","Horned Dinoshroome"},
    ["Stalky Plants"] = {"Beanstalk"},
    ["Zen Plants"] = {"Serenity","Spiked Mango","Sakura Bush"},
    ["Sweet Plants"] = {"Blueberry","Mango","Sugar Apple","Sugarglaze","Strawberry"},
    ["Candy Plants"] = {"Easter Egg","Sugarglaze"},
    ["Toxic Plants"] = {"Foxglove"},
    ["Fungus Plants"] = {"Mushroom","Horned Dinoshroome"},
    ["Leafy Plants"] = {"Grape","Blueberry","Apple","Sugar Apple","Beanstalk","Strawberry"},
    ["Summer Plants"] = {"Tomato","Blueberry","Strawberry","Green Apple","Sugar Apple","Cauliflower"},
    ["Fruit Plants"] = {"Blueberry","Grape","Strawberry","Apple","Coconut"},
    ["Tropical Plants"] = {"Banana","Coconut","Dragon Fruit","Mango","Cocovine"},
    ["Woody Plants"] = {"Mango","Coconut","Moon Mango","Cacao","Giant Pinecone","Kiwi"},
    ["Prehistoric Plants"] = {"Horned Dinoshroome","Lingoberry","Amber Spine"},
    ["Prickly Plants"] = {"Moon Mango","Dragon Fruit","Spiked Mango","Celestiberry"},
    ["Night Plants"] = {"Celestiberry","Moon Mango","Blood Banana"},
}

-- State
local AutoEventRunning = false
local CurrentCategory, LastCategory = "", ""

-- === Helper: bersihin text dari tag <...> ===
local function stripTags(txt)
    if not txt then return "" end
    return (txt:gsub("<.->", "")):gsub("^%s+", ""):gsub("%s+$", "")
end

-- === Helper: Auto Panen sesuai category ===
local function autoHarvest(category)
    local farm
    for _, plot in pairs(workspace.Farm:GetChildren()) do
        local important = plot:FindFirstChild("Important")
        local data = important and important:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and owner.Value == player.Name then
            farm = important:FindFirstChild("Plants_Physical")
            break
        end
    end
    if not farm then return end

    local plants = Categories[category]
    if not plants then return end

    for _, plant in pairs(farm:GetChildren()) do
        if table.find(plants, plant.Name) and plant:FindFirstChild("Fruits") then
            for _, fruit in pairs(plant.Fruits:GetChildren()) do
                local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(PANEN_DELAY)
                end
            end
        end
    end
end

-- === GUI ===
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

-- Tombol drag kecil ✨
local dragBtn = Instance.new("ImageButton")
dragBtn.Size = UDim2.new(0,42,0,42)
dragBtn.Position = UDim2.new(1,-60,0.5,-21)
dragBtn.BackgroundTransparency = 1
dragBtn.Image = "rbxassetid://3926305904" -- icon default Roblox bulat
dragBtn.ImageRectOffset = Vector2.new(4,804) -- ikon bintang ✨
dragBtn.ImageRectSize = Vector2.new(36,36)
Instance.new("UICorner", dragBtn).CornerRadius = UDim.new(1,0)
dragBtn.Parent = gui

-- Panel modern
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0,220,0,190) -- Ukuran panel diperbesar menjadi 190
panel.Position = UDim2.new(1,-280,0.5,-95) -- Posisi panel disesuaikan
panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
panel.BackgroundTransparency = 0.1
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0.1,0)

-- Label kategori
local catLabel = Instance.new("TextLabel", panel)
catLabel.Size = UDim2.new(1,-20,0,25)
catLabel.Position = UDim2.new(0,10,0,10)
catLabel.BackgroundTransparency = 1
catLabel.TextColor3 = Color3.fromRGB(255,200,80)
catLabel.TextXAlignment = Enum.TextXAlignment.Left
catLabel.Font = Enum.Font.GothamBold
catLabel.TextSize = 16
catLabel.Text = "Category: -"
catLabel.Parent = panel

-- Tombol info fruit (mengganti fruitNeedLabel)
local fruitInfoBtn = Instance.new("TextButton", panel)
fruitInfoBtn.Size = UDim2.new(0.3, 0, 0, 25)
fruitInfoBtn.Position = UDim2.new(0.05, 0, 0, 40)
fruitInfoBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
fruitInfoBtn.TextColor3 = Color3.new(1, 1, 1)
fruitInfoBtn.Text = "info fruit"
fruitInfoBtn.Font = Enum.Font.GothamBold
fruitInfoBtn.TextSize = 12
Instance.new("UICorner", fruitInfoBtn).CornerRadius = UDim.new(1,0)
fruitInfoBtn.Parent = panel

-- Panel info buah
local fruitPanel = Instance.new("Frame", gui)
fruitPanel.Size = UDim2.new(0, 250, 0, 150)
fruitPanel.Position = UDim2.new(0.5, -125, 0.5, -75)
fruitPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fruitPanel.BackgroundTransparency = 0.1
fruitPanel.Visible = false
Instance.new("UICorner", fruitPanel).CornerRadius = UDim.new(0.1, 0)

-- Label judul fruit info
local fruitPanelTitle = Instance.new("TextLabel", fruitPanel)
fruitPanelTitle.Size = UDim2.new(1, 0, 0, 25)
fruitPanelTitle.Position = UDim2.new(0, 0, 0, 5)
fruitPanelTitle.BackgroundTransparency = 1
fruitPanelTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
fruitPanelTitle.Text = "Fruits in Category"
fruitPanelTitle.Font = Enum.Font.GothamBold
fruitPanelTitle.TextSize = 16
fruitPanelTitle.Parent = fruitPanel

-- Label list buah
local fruitListLabel = Instance.new("TextLabel", fruitPanel)
fruitListLabel.Size = UDim2.new(1, -20, 1, -60)
fruitListLabel.Position = UDim2.new(0, 10, 0, 35)
fruitListLabel.BackgroundTransparency = 1
fruitListLabel.TextColor3 = Color3.new(1, 1, 1)
fruitListLabel.TextXAlignment = Enum.TextXAlignment.Left
fruitListLabel.TextYAlignment = Enum.TextYAlignment.Top
fruitListLabel.Font = Enum.Font.SourceSans
fruitListLabel.TextSize = 14
fruitListLabel.TextWrapped = true
fruitListLabel.Parent = fruitPanel

-- Tombol close
local closeBtn = Instance.new("TextButton", fruitPanel)
closeBtn.Size = UDim2.new(0.2, 0, 0, 25)
closeBtn.Position = UDim2.new(0.4, 0, 1, -30)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "Close"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.2,0)
closeBtn.Parent = fruitPanel

-- Label progress
local progLabel = catLabel:Clone()
progLabel.Position = UDim2.new(0,10,0,65)
progLabel.TextColor3 = Color3.fromRGB(200,200,200)
progLabel.Text = "Progress: -"
progLabel.Parent = panel

-- Tombol start/stop
local toggleBtn = Instance.new("TextButton", panel)
toggleBtn.Size = UDim2.new(0.9,0,0,30)
toggleBtn.Position = UDim2.new(0.05,0,0,95)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60,180,80)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Text = "START"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0.2,0)
toggleBtn.Parent = panel

-- Deskripsi kecil
local descLabel = Instance.new("TextLabel", panel)
descLabel.Size = UDim2.new(1,-20,0,40) -- Ukuran diperbesar menjadi 40
descLabel.Position = UDim2.new(0,10,0,135)
descLabel.BackgroundTransparency = 1
descLabel.TextColor3 = Color3.fromRGB(200,200,200)
descLabel.TextScaled = true
descLabel.TextWrapped = true
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.Font = Enum.Font.SourceSans
descLabel.Text = "pastikan anda memiliki tanaman yang dibutuhkan di garden anda dan juga anda harus berada di dekat tanaman itu agar script bekerja dengan baik\n\nmake sure you have the required plants in your garden and also you have to be near those plants for the script to work properly"
descLabel.Parent = panel

-- Toggle panel
dragBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Toggle fruit panel
fruitInfoBtn.MouseButton1Click:Connect(function()
    local fruits = Categories[CurrentCategory]
    if fruits then
        fruitListLabel.Text = table.concat(fruits, "\n")
    else
        fruitListLabel.Text = "No fruits for this category."
    end
    fruitPanel.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
    fruitPanel.Visible = false
end)

-- Draggable button
do
    local dragging, dragInput, mousePos, btnPos
    local function update(input)
        local delta = input.Position - mousePos
        dragBtn.Position = UDim2.new(btnPos.X.Scale, btnPos.X.Offset + delta.X, btnPos.Y.Scale, btnPos.Y.Offset + delta.Y)
        panel.Position = dragBtn.Position - UDim2.new(0,240,0,0)
    end
    dragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            btnPos = dragBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- Toggle start/stop
toggleBtn.MouseButton1Click:Connect(function()
    AutoEventRunning = not AutoEventRunning
    toggleBtn.Text = AutoEventRunning and "STOP" or "START"
    toggleBtn.BackgroundColor3 = AutoEventRunning and Color3.fromRGB(200,60,60) or Color3.fromRGB(60,180,80)
end)

-- === Logic utama ===
task.spawn(function()
    local lastSubmitTime = tick()
    while task.wait(0.1) do -- Cek lebih sering untuk respons yang lebih baik
        -- ambil kategori dari server
        local found = nil
        for _,desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text:lower():match("^looking for") then
                found = desc.Text
                break
            end
        end
        if found then
            local raw = found:match("looking for%s+(.+)") or "-"
            CurrentCategory = stripTags(raw)
        end

        catLabel.Text = "Category: " .. (CurrentCategory or "-")

        -- progress
        local prog = progressLabel.Text or "-"
        progLabel.Text = "Progress: " .. prog

        -- auto logic
        if AutoEventRunning then
            if prog == "900/900" then
                if LastCategory ~= CurrentCategory then -- Klaim hanya jika kategori sudah berubah
                    LastCategory = CurrentCategory
                end
                -- Tetap menunggu di sini sampai kategori berubah atau progress turun
            else -- progress belum 900/900
                LastCategory = CurrentCategory
                -- panen otomatis sesuai kategori
                autoHarvest(CurrentCategory)

                -- submit event setiap SUBMIT_DELAY detik
                if tick() - lastSubmitTime >= SUBMIT_DELAY then
                    pcall(function() submitRemote:FireServer() end)
                    lastSubmitTime = tick()
                end
            end

            -- Lakukan klaim jika progress "900/900" dan sudah ada kategori baru.
            -- Cek progress kembali untuk memastikan tidak ada perubahan mendadak.
            if prog == "900/900" and LastCategory == CurrentCategory then
                 task.wait(10)
                 for i=1,CLAIM_COUNT do
                     if not AutoEventRunning then break end
                     pcall(function() claimRemote:FireServer(i) end)
                     task.wait(CLAIM_DELAY)
                 end
                 -- Setelah klaim, script akan menunggu di if prog == "900/900"
                 -- sampai kategori berubah atau progress turun.
            end
        else -- AutoEventRunning is false
             -- Reset LastCategory saat kategori berubah jika skrip tidak aktif
            if LastCategory ~= "" and CurrentCategory ~= LastCategory then
                LastCategory = ""
            end
        end
    end
end)
