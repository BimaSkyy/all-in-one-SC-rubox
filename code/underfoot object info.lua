-- Modern UI Button (ID & EN)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Tombol logo kecil
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 38, 0, 38)
Button.Position = UDim2.new(1, -45, 0.5, -19) -- kanan tengah
Button.AnchorPoint = Vector2.new(1, 0.5)
Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button.Text = "🔧"
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.AutoButtonColor = true
Button.Parent = ScreenGui

-- Rounded corner
local UICorner = Instance.new("UICorner", Button)
UICorner.CornerRadius = UDim.new(0, 10)

-- Shadow effect
local UIStroke = Instance.new("UIStroke", Button)
UIStroke.Color = Color3.fromRGB(90, 90, 90)
UIStroke.Thickness = 1.5

-- Frame info elegan
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 80)
Frame.Position = UDim2.new(1, -230, 0.5, -40)
Frame.AnchorPoint = Vector2.new(1, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Visible = false
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", Frame).Color = Color3.fromRGB(80, 80, 80)

-- Label bahasa (multi language)
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -20, 0.6, -10)
Label.Position = UDim2.new(0, 10, 0, 10)
Label.BackgroundTransparency = 1
Label.Font = Enum.Font.GothamSemibold
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextScaled = true
Label.Text = "🔍 Klik untuk salin nama objek\n(EN) Click to copy object name"
Label.TextWrapped = true
Label.Parent = Frame

-- Tombol copy
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 90, 0, 25)
CopyButton.Position = UDim2.new(0.5, -45, 1, -30)
CopyButton.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
CopyButton.Text = "Salin / Copy"
CopyButton.TextScaled = true
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextColor3 = Color3.new(1,1,1)
CopyButton.Parent = Frame

Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 8)

-- Fungsi cari objek di bawah kaki
local function getObjectBelow()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local rootPos = char.HumanoidRootPart.Position
    local rayOrigin = rootPos
    local rayDirection = Vector3.new(0, -10, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if result and result.Instance then
        local objectName = result.Instance.Name
        if setclipboard then
            setclipboard(objectName)
            warn("✅ Nama objek disalin:", objectName)
        else
            warn("Clipboard tidak tersedia. Objek:", objectName)
        end
    else
        warn("Tidak ada objek di bawah kaki.")
    end
end

-- Klik tombol logo → toggle menu
Button.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)

-- Klik tombol salin → jalankan fungsi
CopyButton.MouseButton1Click:Connect(getObjectBelow)

-- Fungsi drag (support PC & Mobile)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    Button.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

Button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Button.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Button.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
