-- UI Button
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Buat tombol kecil 🔮
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 25, 0, 25)
Button.Position = UDim2.new(1, -30, 0.5, -12) -- kanan tengah
Button.AnchorPoint = Vector2.new(1, 0.5)
Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Button.Text = "🔮"
Button.TextScaled = true
Button.Parent = ScreenGui

-- Fungsi cari objek di bawah kaki
local function getObjectBelow()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local rootPos = char.HumanoidRootPart.Position
    local rayOrigin = rootPos
    local rayDirection = Vector3.new(0, -10, 0) -- ke bawah 10 stud

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

-- Klik tombol → jalankan fungsi
Button.MouseButton1Click:Connect(getObjectBelow)
