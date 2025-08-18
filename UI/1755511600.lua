-- Modern Popup GUI by ChatGPT
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Hapus GUI lama kalau ada
if player.PlayerGui:FindFirstChild("PopupUI") then
    player.PlayerGui.PopupUI:Destroy()
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PopupUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Buat Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 160)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -80)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Round Corner
local UICorner = Instance.new("UICorner", mainFrame)
UICorner.CornerRadius = UDim.new(0, 15)

-- UI Gradient biar ada warna modern
local UIGradient = Instance.new("UIGradient", mainFrame)
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 90, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 200))
}
UIGradient.Rotation = 45

-- Label Teks
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -20, 0, 80)
textLabel.Position = UDim2.new(0, 10, 0, 10)
textLabel.BackgroundTransparency = 1
textLabel.Text = "script ini untuk game car crash tidak tersedia untuk game yang anda mainkan saat ini\n\nThis script for the game car crash is not available for the game you are currently playing"
textLabel.TextWrapped = true
textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
textLabel.TextSize = 15
textLabel.Font = Enum.Font.GothamSemibold
textLabel.Parent = mainFrame

-- Buat Container tombol
local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(1, -20, 0, 40)
buttonFrame.Position = UDim2.new(0, 10, 1, -50)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = mainFrame

-- UI List Layout biar tombol sejajar
local UIListLayout = Instance.new("UIListLayout", buttonFrame)
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0, 15)

-- Fungsi bikin tombol modern
local function createButton(text, color1, color2)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = buttonFrame

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient", btn)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    grad.Rotation = 90

    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.TextSize = 18
    end)
    btn.MouseLeave:Connect(function()
        btn.TextSize = 16
    end)

    return btn
end

-- Buat tombol Copy
local copyBtn = createButton("Copy", Color3.fromRGB(80, 160, 255), Color3.fromRGB(50, 100, 200))
local closeBtn = createButton("Close", Color3.fromRGB(255, 100, 100), Color3.fromRGB(200, 50, 50))

-- Fungsi tombol Copy
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard("https://www.roblox.com/share?code=cd6e1a8bb55adc4b8e06cf1fc70d5202&type=ExperienceDetails&stamp=1755513448013")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Copied!",
            Text = "Link successfully copied to clipboard",
            Duration = 3
        })
    end
end)

-- Fungsi tombol Close
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)
