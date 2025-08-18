-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- GUI utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InfoItemGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tombol utama (📋)
local MainButton = Instance.new("TextButton")
MainButton.Name = "MainButton"
MainButton.Parent = ScreenGui
MainButton.Size = UDim2.new(0, 40, 0, 40)
MainButton.Position = UDim2.new(1, -50, 0, 10)
MainButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainButton.Text = "🔍"
MainButton.Font = Enum.Font.SourceSansBold
MainButton.TextSize = 22
MainButton.AutoButtonColor = true
MainButton.BackgroundTransparency = 0.1
MainButton.BorderSizePixel = 0
MainButton.ClipsDescendants = true
MainButton.Active = true
MainButton.Draggable = false -- manual drag agar support Android

-- Label info hover
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = MainButton
InfoLabel.Size = UDim2.new(1, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 0, 1, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.Font = Enum.Font.SourceSansBold
InfoLabel.TextScaled = true
InfoLabel.Text = "Klik untuk salin\nClick to copy"

-- Fungsi drag agar support PC & Android
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainButton.Position =
        UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RS.RenderStepped:Connect(function()
    if dragging and dragInput then
        update(dragInput)
    end
end)

-- Event klik tombol → deteksi item di tangan
MainButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        warn("❌ Tidak ada item yang dipegang! | No item in hand!")
        return
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle then
        warn("❌ Tool tidak memiliki Handle! | Tool has no Handle!")
        return
    end

    -- Ambil info objek
    local info = {
        Name = tool.Name,
        HandleName = handle.Name,
        Position = tostring(handle.Position),
        Size = tostring(handle.Size),
        Parent = handle.Parent.Name
    }

    -- Encode ke JSON
    local json = HttpService:JSONEncode(info)

    -- Salin ke clipboard
    if setclipboard then
        setclipboard(json)
        print("✅ Info item berhasil disalin ke clipboard! | Copied to clipboard!")
    else
        print("🔹 Hasil JSON | JSON Result:", json)
    end
end)
