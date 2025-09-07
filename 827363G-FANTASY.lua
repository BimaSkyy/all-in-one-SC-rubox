-- Perbaikan lengkap: Combo loop + konfirmasi + robust feet-check
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ambil character & humanoid
local function getChar()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    return c, hrp, hum
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ComboGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ComboBtn = Instance.new("TextButton")
ComboBtn.Size = UDim2.new(0, 80, 0, 26)
ComboBtn.Position = UDim2.new(1, -90, 0.5, -13)
ComboBtn.AnchorPoint = Vector2.new(0, 0.5)
ComboBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ComboBtn.TextColor3 = Color3.new(1,1,1)
ComboBtn.Font = Enum.Font.GothamBold
ComboBtn.TextSize = 13
ComboBtn.Text = "COMBO: OFF"
ComboBtn.Parent = ScreenGui
ComboBtn.AutoButtonColor = true

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(0, 340, 0, 130)
ConfirmFrame.Position = UDim2.new(0.5, -170, 0.5, -65)
ConfirmFrame.AnchorPoint = Vector2.new(0.5,0.5)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
ConfirmFrame.Visible = false
ConfirmFrame.Parent = ScreenGui

local ConfirmLabel = Instance.new("TextLabel")
ConfirmLabel.Size = UDim2.new(1, -20, 0.5, -10)
ConfirmLabel.Position = UDim2.new(0, 10, 0, 10)
ConfirmLabel.Text = "Yakin ingin mematikan script ini?\nScript sedang loop tanpa henti untuk menambah Sumbit kamu"
ConfirmLabel.TextWrapped = true
ConfirmLabel.TextColor3 = Color3.new(1,1,1)
ConfirmLabel.Font = Enum.Font.GothamBold
ConfirmLabel.TextSize = 14
ConfirmLabel.BackgroundTransparency = 1
ConfirmLabel.Parent = ConfirmFrame

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0.45, 0, 0.3, 0)
YesBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
YesBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
YesBtn.Text = "YA MATIKAN"
YesBtn.TextColor3 = Color3.new(1,1,1)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 14
YesBtn.Parent = ConfirmFrame

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0.45, 0, 0.3, 0)
NoBtn.Position = UDim2.new(0.5, 0, 0.65, 0)
NoBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
NoBtn.Text = "TIDAK JADI"
NoBtn.TextColor3 = Color3.new(1,1,1)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 14
NoBtn.Parent = ConfirmFrame

-- vars
local comboRunning = false
local flyConn = nil

-- fixed positions (pakai posisi kamu)
local fixedPositions = {
    {name="Pos1",x=-764.202,y=29.153,z=-430.170},
    {name="Pos2",x=-521.144,y=177.210,z=-269.229},
    {name="Pos3",x=-407.782,y=283.767,z=170.991},
    {name="Pos4",x=-13.746,y=265.581,z=349.532},
    {name="Pos5",x=293.411,y=326.254,z=432.064},
    {name="Pos6",x=625.434,y=304.356,z=509.964},
    {name="Pos7",x=1186.559,y=749.284,z=599.574},
    {name="Pos8",x=1095.342,y=871.278,z=878.681},
    {name="Pos9",x=-472.617,y=1268.618,z=994.449},
    {name="Pos10",x=-967.143,y=1518.381,z=1440.195},
    {name="Pos11",x=-971.164,y=1523.381,z=1445.054},
    {name="Pos12",x=-979.487,y=1523.381,z=1453.082},
    {name="Pos13",x=-985.657,y=1523.381,z=1458.698},
    {name="Pos14",x=-992.709,y=1523.381,z=1464.812},
}

-- helper notify
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = text or "", Duration = dur or 2})
    end)
end

-- utility: set collision state for all character parts (try/catch)
local function setCharacterCollisions(char, state)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = state end)
        end
    end
end

-- fly mode: freeze physics + noclip
local function startFlyMode()
    local char, hrp, hum = getChar()
    if not (char and hrp and hum) then return end
    hum.PlatformStand = true
    setCharacterCollisions(char, false)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    flyConn = RunService.Stepped:Connect(function()
        char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp2.Velocity = Vector3.new(0,0,0)
            hrp2.RotVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function stopFlyMode()
    local ok, char = pcall(function() return LocalPlayer.Character end)
    if ok and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.PlatformStand = false end) end
        setCharacterCollisions(char, true)
    end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

-- lebih andal: cek kaki menyentuh ground
-- kombinasi: Humanoid.FloorMaterial, Humanoid state, raycast dari HRP ke bawah, dan Y distance ke target pos
local function waitUntilFeetTouch(targetPos, timeout)
    timeout = timeout or 6
    local start = tick()
    local char, hrp, hum = getChar()
    if not (char and hrp and hum) then return false, "nohum" end

    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {char}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.IgnoreWater = true

    while tick() - start < timeout do
        if not hum or hum.Health <= 0 then return false, "died" end

        -- floor material quick check
        if hum.FloorMaterial and hum.FloorMaterial ~= Enum.Material.Air then
            return true, "touched"
        end

        -- humanoid landed/running states
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.RunningNoPhysics then
            return true, "touched"
        end

        -- raycast straight down from HRP a few studs
        local origin = hrp.Position
        local dir = Vector3.new(0, -6, 0)
        local res = Workspace:Raycast(origin, dir, rp)
        if res and res.Instance and res.Instance:IsA("BasePart") then
            -- ensure it's not part of character
            return true, "touched"
        end

        -- if we know targetPos, check Y closeness (some maps)
        if targetPos then
            local dy = hrp.Position.Y - targetPos.y
            if dy <= 1.5 then
                return true, "touched"
            end
        end

        task.wait(0.08)
    end

    return false, "timeout"
end

-- tunggu sampai character mati lalu respawn dan settle
local function waitUntilDeadThenRespawn(oldChar, lastPos)
    -- 1) tunggu dia mati (atau treat kalau humanoid nil)
    local died = false
    if oldChar then
        local hum = oldChar:FindFirstChildOfClass("Humanoid")
        if hum then
            local con
            con = hum.Died:Connect(function()
                died = true
                if con then con:Disconnect() end
            end)
        else
            died = true
        end
    else
        died = true
    end

    local waited = 0
    while not died and waited < 30 do
        task.wait(0.5)
        waited = waited + 0.5
    end

    -- 2) tunggu CharacterAdded yang baru (bukan oldChar)
    local newChar = LocalPlayer.Character
    if newChar == oldChar or not newChar then
        newChar = LocalPlayer.CharacterAdded:Wait()
    end

    -- 3) tunggu HRP & Humanoid valid
    local newHRP = newChar:WaitForChild("HumanoidRootPart", 10)
    local newHum = newChar:WaitForChild("Humanoid", 10)
    task.wait(1.5) -- settle

    -- 4) tunggu health > 0 dan (opsional) posisi jauh dari lastPos
    local maxWait = 12
    local elapsed = 0
    local minDist = 40
    if not lastPos then minDist = 0 end

    while elapsed < maxWait do
        if not newHum or not newHRP then break end
        if newHum.Health > 0 then
            if minDist <= 0 then break end
            local dist = (newHRP.Position - Vector3.new(lastPos.x, lastPos.y, lastPos.z)).Magnitude
            if dist >= minDist then break end
        end
        task.wait(0.5)
        elapsed = elapsed + 0.5
    end

    return newChar, newHRP, newHum
end

-- stop combo: pastikan UI di-reset & cleanup
local function stopCombo()
    comboRunning = false
    stopFlyMode()
    ConfirmFrame.Visible = false
    ComboBtn.Text = "COMBO: OFF"
    ComboBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
    notify("Combo", "Dihentikan", 2)
end

-- main runner
local comboThread
local function startCombo()
    if comboRunning then return end
    comboRunning = true
    ComboBtn.Text = "COMBO: ON"
    ComboBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    notify("Combo","Dimulai",2)

    comboThread = task.spawn(function()
        local currentIndex = 1
        while comboRunning do
            for i = currentIndex, #fixedPositions do
                if not comboRunning then break end
                local p = fixedPositions[i]

                local char, hrp, hum = getChar()
                if not hum or hum.Health <= 0 then
                    notify("Combo","Humanoid mati sebelum teleport, menunggu respawn...",2)
                    local newChar, newHRP, newHum = waitUntilDeadThenRespawn(char, p)
                    char, hrp, hum = newChar, newHRP, newHum
                end

                if not (char and hrp and hum) then
                    -- if still invalid, break out cleanly
                    notify("Combo","Karakter invalid, stop loop",2)
                    comboRunning = false
                    break
                end

                -- subscribe died flag
                local diedFlag = false
                local diedConn
                diedConn = hum.Died:Connect(function() diedFlag = true end)

                -- teleport with fly lock -> drop -> wait touch
                startFlyMode()
                pcall(function()
                    char:PivotTo(CFrame.new(p.x, p.y + 5, p.z))
                end)
                task.wait(0.12)
                stopFlyMode()

                -- tunggu kaki menyentuh ground, lebih andal
                local touched, reason = waitUntilFeetTouch(p, 8)

                if diedConn then diedConn:Disconnect(); diedConn = nil end

                if not comboRunning then break end

                if reason == "died" or diedFlag then
                    notify("Combo", ("Player mati saat menuju %s, menunggu respawn..."):format(p.name or tostring(i)), 3)
                    local newChar, newHRP, newHum = waitUntilDeadThenRespawn(char, p)
                    char, hrp, hum = newChar, newHRP, newHum
                    currentIndex = i -- ulang dari posisi yang sama
                    break
                elseif reason == "timeout" and not touched then
                    -- fallback: re-enable fly and continue to next
                    startFlyMode()
                    notify("Combo", ("Tidak mendeteksi ground di %s (timeout), skip..."):format(p.name or tostring(i)), 2)
                    currentIndex = i + 1
                    task.wait(0.1)
                else
                    -- sukses touch -> lock posisi dan lanjut
                    startFlyMode()
                    notify("Combo", ("Tiba di %s"):format(p.name or tostring(i)), 1)
                    currentIndex = i + 1
                    task.wait(0.08)
                end
            end

            -- semua posisi sudah dilewati
            if comboRunning and currentIndex > #fixedPositions then
                stopFlyMode()
                notify("Combo","Folloe BmSkyMods For New Script👻.",3)
                task.wait(3)

                -- catat old char & last pos
                local oldChar, oldHRP, oldHum = getChar()
                local lastPos = fixedPositions[#fixedPositions]

                -- teleport ke bawah untuk void kill (safe pcall)
                if oldChar and oldHRP and oldHum and oldHum.Health > 0 then
                    pcall(function()
                        oldChar:PivotTo(oldHRP.CFrame * CFrame.new(0, -1500, 0))
                    end)
                end

                -- tunggu mati + respawn + settle
                local newChar, newHRP, newHum = waitUntilDeadThenRespawn(oldChar, lastPos)
                notify("Combo","Respawn terdeteksi. Menunggu settle sebelum lanjut...",2)
                task.wait(2)

                -- reset dan lanjut dari Pos1
                currentIndex = 1
            end
        end

        -- akhir: cleanup
        stopFlyMode()
        ComboBtn.Text = "COMBO: OFF"
        ComboBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
        notify("Combo","Dihentikan",2)
    end)
end

-- UI events
ComboBtn.MouseButton1Click:Connect(function()
    if comboRunning then
        ConfirmFrame.Visible = true
    else
        startCombo()
    end
end)

YesBtn.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = false
    stopCombo()
end)

NoBtn.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = false
end)
