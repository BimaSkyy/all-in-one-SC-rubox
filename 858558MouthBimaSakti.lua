-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- =========================
-- Character management (robust)
-- =========================
local currentChar = nil
local currentHRP = nil
local currentHum = nil
local charConn = nil
local humDiedConn = nil

local pausedForRespawn = false

local function clearCharRefs()
    if humDiedConn then
        pcall(function() humDiedConn:Disconnect() end)
        humDiedConn = nil
    end
    currentChar = nil
    currentHRP = nil
    currentHum = nil
end

local function onHumanoidDied()
    -- dipanggil saat humanoid mati
    pausedForRespawn = true
    -- hentikan fly mode dari luar (combo thread akan menunggu)
    -- beri notif
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Info", Text = "Kamu mati, menunggu respawn...", Duration = 5})
    end)
end

local function onCharacterAdded(char)
    clearCharRefs()
    currentChar = char
    -- tunggu bagian penting
    currentHRP = char:WaitForChild("HumanoidRootPart", 2) or char:FindFirstChild("HumanoidRootPart")
    currentHum = char:FindFirstChildOfClass("Humanoid") or (char:WaitForChild("Humanoid", 2) and char:FindFirstChildOfClass("Humanoid"))
    if currentHum then
        humDiedConn = currentHum.Died:Connect(onHumanoidDied)
    end

    -- ketika muncul kembali, clear paused flag & notif
    pausedForRespawn = false
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Info", Text = "melanjutkan...", Duration = 3})
    end)
end

-- attach character listeners
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
-- reconnect CharacterAdded
if charConn then pcall(function() charConn:Disconnect() end) end
charConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer then
        clearCharRefs()
    end
end)

-- helper to wait until respawned (non-blocking outside of its caller)
local function waitForRespawn()
    -- tunggu sampai pausedForRespawn jadi false dan currentChar valid
    while pausedForRespawn do
        task.wait(0.15)
    end
    -- pastikan char ready
    while not (currentChar and currentChar.Parent) do
        task.wait(0.15)
    end
    -- small safety delay
    task.wait(0.25)
end

-- =========================
-- GUI
-- =========================
local function safeParentGui(gui)
    -- pastikan PlayerGui ada lalu parent
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
    if pg then
        gui.Parent = pg
    else
        -- fallback ke CoreGui via SetCore? (tidak ideal) -> taruh di PlayerGui yang belum ada
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ComboGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10
ScreenGui.IgnoreGuiInset = false
safeParentGui(ScreenGui)

local ComboBtn = Instance.new("TextButton")
ComboBtn.Size = UDim2.new(0, 60, 0, 60)
-- atur agar muncul aman di mobile & PC (anchor kanan-tengah)
ComboBtn.AnchorPoint = Vector2.new(1, 0.5)
ComboBtn.Position = UDim2.new(1, -20, 0.5, 0)
ComboBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- hijau = OFF
ComboBtn.TextColor3 = Color3.fromRGB(255,255,255)
ComboBtn.Font = Enum.Font.GothamBold
ComboBtn.TextSize = 18
ComboBtn.Text = "ATP"
ComboBtn.AutoButtonColor = true
ComboBtn.Draggable = true
ComboBtn.Parent = ScreenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(1, 0)
buttonCorner.Parent = ComboBtn

-- center message helper (for final message)
local function showCenterMessage(text, dur)
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    safeParentGui(gui)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.8, 0, 0.18, 0)
    lbl.Position = UDim2.new(0.1, 0, 0.42, 0)
    lbl.AnchorPoint = Vector2.new(0,0)
    lbl.BackgroundTransparency = 0.35
    lbl.BackgroundColor3 = Color3.new(0,0,0)
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 28
    lbl.TextWrapped = true
    lbl.Text = text
    lbl.Parent = gui
    task.spawn(function()
        task.wait(dur or 3)
        pcall(function() gui:Destroy() end)
    end)
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text or "", Duration = dur or 3 })
    end)
end

-- =========================
-- Fly mode (noclip & zero velocity)
-- =========================
local flyConn = nil

local function startFlyMode()
    if flyConn then return end
    if not currentHum then return end
    pcall(function() currentHum.PlatformStand = true end)
    -- disable collisions once
    if currentChar then
        for _, part in ipairs(currentChar:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
    flyConn = RunService.Stepped:Connect(function()
        if not currentChar or not currentChar.Parent then return end
        -- keep collisions off
        for _, part in ipairs(currentChar:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
        local hrp = currentHRP
        if hrp and hrp.Parent then
            pcall(function()
                hrp.Velocity = Vector3.new(0,0,0)
                hrp.RotVelocity = Vector3.new(0,0,0)
            end)
        end
    end)
end

local function stopFlyMode()
    pcall(function()
        if currentHum then currentHum.PlatformStand = false end
    end)
    if flyConn then
        pcall(function() flyConn:Disconnect() end)
        flyConn = nil
    end
    -- re-enable collisions so player bisa mendarat
    if currentChar and currentChar.Parent then
        for _, part in ipairs(currentChar:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

-- =========================
-- Ground detection & flyTo (robust)
-- =========================
local function isGroundedCheck()
    if not currentHum then return false end
    local ok, fm = pcall(function() return currentHum.FloorMaterial end)
    if ok and fm and fm ~= Enum.Material.Air then
        return true
    end
    local ok2, state = pcall(function() return currentHum:GetState() end)
    if ok2 and (state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Seated) then
        return true
    end
    return false
end

local function waitUntilGrounded(timeout)
    timeout = timeout or nil
    local startTick = tick()
    -- ensure collisions & platformstand off
    pcall(function() if currentHum then currentHum.PlatformStand = false end end)
    if currentChar then
        for _, part in ipairs(currentChar:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
    if isGroundedCheck() then return end
    while (not timeout or (tick() - startTick) < timeout) do
        if isGroundedCheck() then break end
        task.wait(0.1)
    end
end

local function flyTo(targetPos, speed)
    speed = speed or 100
    -- loop will keep checking currentHRP each iteration, so it survives respawn transitions
    while true do
        -- stop if combo stopped externally or respawn pause
        if pausedForRespawn then return end
        if not currentHRP or not currentHRP.Parent then
            -- no hrp now: give small wait for respawn or HRP to exist, then try again or abort
            task.wait(0.15)
            if not currentHRP or not currentHRP.Parent then
                -- if still not present, bail out of this flyTo (outer loop will manage)
                return
            end
        end
        local hrp = currentHRP
        if not hrp or not hrp.Parent then return end
        local dist = (hrp.Position - targetPos).Magnitude
        if dist <= 5 then break end
        local dt = RunService.Heartbeat:Wait()
        local dir = (targetPos - hrp.Position)
        if dir.Magnitude == 0 then break end
        local unit = dir.Unit
        local move = math.min(speed * dt, dir.Magnitude)
        pcall(function() hrp.CFrame = CFrame.new(hrp.Position + unit * move) end)
        -- safety tiny wait
        task.wait()
    end
end

-- =========================
-- Fixed positions (tidak diubah)
-- =========================
local fixedPositions = {
    {name="Pos1",x=-443.32159423828127,y=157.84396362304688,z=61.579803466796878},
    {name="Pos2",x=-537.000244140625,y=78.1837158203125,z=-677.938720703125},
    {name="Pos3",x=-216.0156707763672,y=175.60833740234376,z=-883.5723876953125},
    {name="Pos4",x=436.1916198730469,y=104.39456176757813,z=-743.33984375},
    {name="Pos5",x=289.8649597167969,y=72.95804595947266,z=-1330.371337890625},
    {name="Pos6",x=193.64501953125,y=78.92662048339844,z=-1552.40087890625},
    {name="Pos7",x=-304.603271484375,y=84.7536392211914,z=-2492.676025390625},
    {name="Pos8",x=-909.1669311523438,y=114.25981903076172,z=-2929.643310546875},
    {name="Pos9",x=-1613.3358154296876,y=157.67434692382813,z=-2631.208251953125},
    {name="Pos10",x=-2644.153564453125,y=140.99801635742188,z=-3025.344970703125},
    {name="Pos11",x=-3290.1708984375,y=144.95590209960938,z=-4039.913818359375},
    {name="Pos12",x=-3503.77880859375,y=70.99162292480469,z=-4643.203125},
    {name="Pos13",x=1732.00537109375,y=47.276580810546878,z=-1858.5960693359376},
    {name="Pos14",x=1836.5277099609376,y=89.83660125732422,z=-2010.7518310546876},
    {name="Pos15",x=1838.127197265625,y=90.4114761352539,z=-2011.8055419921876}
}

-- =========================
-- State vars & main combo
-- =========================
local comboRunning = false
local comboThread = nil
local currentIndex = 1
local isMovingToTarget = false
local isWaitingGround = false

local function startCombo()
    if comboRunning then return end
    comboRunning = true
    ComboBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    notify("Info","Follow BmSkyMods for new script👻",3)

    comboThread = task.spawn(function()
        currentIndex = currentIndex or 1

        while comboRunning and currentIndex <= #fixedPositions do
            -- jika harus menunggu respawn, tunggu dulu
            if pausedForRespawn then
                -- hentikan fly jika berjalan
                stopFlyMode()
                waitForRespawn()
                if not comboRunning then break end
            end

            local p = fixedPositions[currentIndex]
            if not p then break end
            local target = Vector3.new(p.x, p.y + 5, p.z)

            -- pastikan character available
            while comboRunning and (not currentChar or not currentChar.Parent or not currentHRP) do
                -- menunggu respawn/character
                waitForRespawn()
                if not comboRunning then break end
            end
            if not comboRunning then break end

            -- start fly jika belum
            if not flyConn then startFlyMode() end
            isMovingToTarget = true
            notify("Info", "Try "..p.name, 2)

            -- bergerak ke target (flyTo akan memeriksa HRP tiap iterasi)
            flyTo(target, 200)

            -- jika selama fly terjadi respawn/pause, flyTo bisa keluar lebih awal
            if pausedForRespawn then
                -- jika mati di tengah, loop akan kembali dan resume saat respawn
                isMovingToTarget = false
                stopFlyMode()
                continue
            end

            -- re-attach handled by CharacterAdded automatic logic

            -- arrived: stop fly mode and wait until grounded
            isMovingToTarget = false
            stopFlyMode()
            isWaitingGround = true
            waitUntilGrounded()
            isWaitingGround = false

            if not comboRunning then break end

            -- special handling for Pos12
            if p.name == "Pos12" then
                notify("Info","TUNGGU KAMU AKAN DI TELEPORT",5)
                local pos13Entry = fixedPositions[13]
                if pos13Entry then
                    local pos13Vec = Vector3.new(pos13Entry.x, pos13Entry.y, pos13Entry.z)
                    -- check current HRP exist
                    local hrpCheck = currentHRP
                    if hrpCheck and hrpCheck.Parent then
                        local initialDist = (hrpCheck.Position - pos13Vec).Magnitude
                        if initialDist <= 500 then
                            notify("Info","Follow BmSkyMods for new script👻.",3)
                            currentIndex = currentIndex + 1
                            if comboRunning then startFlyMode() end
                        else
                            local teleported = false
                            while comboRunning do
                                task.wait(0.5)
                                if pausedForRespawn then break end
                                local hrpNow = currentHRP
                                if not hrpNow or not hrpNow.Parent then break end
                                local curDist = (hrpNow.Position - pos13Vec).Magnitude
                                if curDist <= 500 then
                                    teleported = true
                                    break
                                end
                            end
                            if teleported and comboRunning then
                                notify("Info","dikit lagi.",3)
                                currentIndex = currentIndex + 1
                                if comboRunning then startFlyMode() end
                            else
                                if not comboRunning then break end
                                -- else lanjut normal fallback
                                currentIndex = currentIndex + 1
                                if comboRunning then startFlyMode() end
                            end
                        end
                    else
                        notify("Warn","Humanoid Pos13 tidak ditemukan, lanjut.",2)
                        currentIndex = currentIndex + 1
                        if comboRunning then startFlyMode() end
                    end
                else
                    notify("Warn","Pos13 tidak ditemukan, lanjut.",2)
                    currentIndex = currentIndex + 1
                    if comboRunning then startFlyMode() end
                end
            else
                -- normal: naik ke posisi berikutnya
                currentIndex = currentIndex + 1
                if comboRunning then startFlyMode() end
            end

            -- handle final position special behavior
            if currentIndex > #fixedPositions and comboRunning then
                -- reached past last pos -> execute final sequence at last pos
                showCenterMessage("BERSIAPLAH BUNG KITA AKAN TERBANG KE ANGKASA DAN KAMU AKAN MATI DAN MELANJUTKAN SUMBIT BARU👻", 3.5)
                notify("Info","cihuyy..",3)
                -- ensure we have character
                while comboRunning and (not currentChar or not currentChar.Parent or not currentHRP) do
                    waitForRespawn()
                end
                if not comboRunning then break end

                -- start flying up 500 stud from current hrp pos
                startFlyMode()
                local hrpFinal = currentHRP
                if hrpFinal and hrpFinal.Parent then
                    local upTarget = hrpFinal.Position + Vector3.new(0,2000,0)
                    flyTo(upTarget, 250)
                    -- reached top: stop fly mode but ensure collisions on so player jatuh
                    stopFlyMode()
                    -- re-enable collisions and platformstand to fall naturally
                    if currentChar and currentChar.Parent then
                        for _, part in ipairs(currentChar:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.CanCollide = true end)
                            end
                        end
                    end
                    if currentHum then pcall(function() currentHum.PlatformStand = false end) end
                    notify("Info","damn!!.",6)
                    -- wait until humanoid dies, then loop restarts from Pos1 after respawn
                    local died = false
                    if currentHum then
                        local dconn = currentHum.Died:Connect(function() died = true end)
                        repeat task.wait(0.3) until died
                        pcall(function() dconn:Disconnect() end)
                    else
                        -- if no humanoid, just wait briefly and reset
                        task.wait(1)
                    end
                    -- wait for respawn
                    while not (currentChar and currentChar.Parent and currentHRP) do
                        task.wait(0.2)
                    end
                    currentIndex = 1
                    notify("Info","oke kita lanjut lagi ya dari 0.",3)
                    startFlyMode()
                else
                    currentIndex = 1
                    notify("Info","Gagal menemukan HRP final. Reset ke Pos1.",3)
                end
            end
        end -- while

        -- cleanup
        stopFlyMode()
        comboRunning = false
        ComboBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        notify("Selesai","Combo selesai/berhenti.",2)
    end)
end

local function stopCombo()
    comboRunning = false
    stopFlyMode()
    ComboBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
end

ComboBtn.MouseButton1Click:Connect(function()
    if comboRunning then
        stopCombo()
    else
        startCombo()
    end
end)

local function clean()
    stopCombo()
    if ScreenGui and ScreenGui.Parent then
        pcall(function() ScreenGui:Destroy() end)
    end
end

-- expose cleaning (if needed)
return { Gui = ScreenGui, Stop = clean }
