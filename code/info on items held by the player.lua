-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- GUI kecil di kanan atas
local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local Button = Instance.new("TextButton")
Button.Parent = ScreenGui
Button.Size = UDim2.new(0, 25, 0, 25)
Button.Position = UDim2.new(1, -30, 0, 5)
Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Text = "📋"
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 14

-- Tombol click → deteksi item di tangan
Button.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        warn("Tidak ada item yang dipegang!")
        return
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle then
        warn("Tool tidak memiliki Handle!")
        return
    end

    -- Ambil info objek
    local info = {
        Name = tool.Name,
        HandleName = handle.Name,
        Position = handle.Position,
        Size = handle.Size,
        Parent = handle.Parent.Name
    }

    -- Encode ke JSON agar gampang disalin
    local json = HttpService:JSONEncode(info)

    -- Salin ke clipboard (hanya di exploit yang support setclipboard)
    if setclipboard then
        setclipboard(json)
        print("✅ Info item disalin ke clipboard!")
    else
        print("🔹 Hasil JSON:", json)
    end
end)
