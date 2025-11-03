-- Professional Auto-ESP + Crosshair Lock (LocalScript)
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====== Config ======
local CIRCLE_SIZE = 220            -- diameter (px)
local DOT_SIZE = 18                -- size for billboard dot
local LERP_SPEED = 8               -- camera lerp speed
local REFRESH_SCAN_SECONDS = 1.0   -- how often to scan workspace for NPC models

local TEAM_COLOR = Color3.fromRGB(0,200,0)
local ENEMY_COLOR = Color3.fromRGB(255,40,40)

-- ====== UI setup ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoLockESP_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- draggable small center button (initially center)
local LockButton = Instance.new("TextButton")
LockButton.Name = "LockBtn"
LockButton.Size = UDim2.new(0, 28, 0, 28)
LockButton.Position = UDim2.new(0.5, -14, 0.5, -14) -- middle
LockButton.AnchorPoint = Vector2.new(0.5,0.5)
LockButton.Text = "🎯"
LockButton.TextScaled = true
LockButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
LockButton.BorderSizePixel = 0
LockButton.Parent = screenGui
LockButton.ZIndex = 100

-- circle crosshair (visible when enabled)
local Circle = Instance.new("Frame")
Circle.Name = "CrossCircle"
Circle.Size = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE)
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.Position = UDim2.new(0.5, 0, 0.5, 0)
Circle.BackgroundTransparency = 1
Circle.Parent = screenGui
Circle.ZIndex = 50
local stroke = Instance.new("UIStroke", Circle)
stroke.Thickness = 1.2
stroke.Color = Color3.fromRGB(0,255,120)
local corner = Instance.new("UICorner", Circle)
corner.CornerRadius = UDim.new(1,0)
Circle.Visible = false

-- state
local lockEnabled = false
local entities = {}       -- map model -> data {type="player"/"npc", source=player or model}
local espMap = {}         -- model -> BillboardGui
local lastScan = 0

-- ====== Utilities ======
local function isPlayerModel(model)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character == model then return plr end
    end
    return nil
end

local function isValidLivingModel(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function topPartOfModel(model)
    if not model then return nil end
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    -- fallback: search for largest part
    local best
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and (not best or p.Size.Y > best.Size.Y) then best = p end
    end
    return best
end

-- create BillboardGui dot above head (3D, follows model)
local function createESP(model)
    if espMap[model] then return espMap[model] end
    local adornee = topPartOfModel(model)
    if not adornee then return nil end

    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_Bill"
    bill.Size = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE)
    bill.ExtentsOffset = Vector3.new(0, 1.6, 0)
    bill.Adornee = adornee
    bill.AlwaysOnTop = true
    bill.ResetOnSpawn = false
    bill.Parent = screenGui

    local frame = Instance.new("Frame", bill)
    frame.Size = UDim2.new(1,0,1,0)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,0.5,0,0)
    frame.BackgroundColor3 = ENEMY_COLOR
    frame.BorderSizePixel = 0
    frame.ZIndex = 200
    local uc = Instance.new("UICorner", frame)
    uc.CornerRadius = UDim.new(1,0)

    espMap[model] = {bill = bill, frame = frame}
    return espMap[model]
end

local function removeESP(model)
    local data = espMap[model]
    if data then
        pcall(function() data.bill:Destroy() end)
        espMap[model] = nil
    end
end

-- scan workspace for NPCs (models with Humanoid that are not player characters)
local function scanEntities()
    entities = {}
    -- players
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isValidLivingModel(plr.Character) then
            entities[plr.Character] = {type="player", source=plr}
        end
    end
    -- scan workspace top level & some common folders
    local containers = {Workspace}
    for _, name in ipairs({"Monsters","NPCs","Enemies","Zombies"}) do
        local f = Workspace:FindFirstChild(name)
        if f and (f:IsA("Folder") or f:IsA("Model")) then table.insert(containers, f) end
    end
    for _, c in ipairs(containers) do
        for _, child in ipairs(c:GetChildren()) do
            if child:IsA("Model") and isValidLivingModel(child) then
                if not isPlayerModel(child) then
                    entities[child] = {type="npc", source=child}
                end
            end
        end
    end
end

-- line-of-sight check: returns true if visible (not blocked by non-character object)
local function isVisibleFromCamera(model)
    local part = topPartOfModel(model)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true
    local res = Workspace:Raycast(origin, direction, params)
    if not res then
        return false
    end
    -- visible if hit is inside the model (descendant)
    return res.Instance and res.Instance:IsDescendantOf(model)
end

-- calculate screen center and radius
local function screenCenter()
    return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end

-- pick closest valid entity inside circle and visible and not dead
local function pickBestTarget()
    local center = screenCenter()
    local radius = Circle.AbsoluteSize.X/2
    local best, bestDist = nil, math.huge
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for model, meta in pairs(entities) do
        if isValidLivingModel(model) then
            -- Kode ini sudah dihapus agar tidak ada filter tim, sehingga semua pemain (tim dan musuh) dapat di-lock.
            local top = topPartOfModel(model)
            if top then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(top.Position + Vector3.new(0, 0.6, 0))
                if onScreen then
                    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local d = (screenPos - center).Magnitude
                    if d <= radius then
                        -- visible check (line of sight)
                        if isVisibleFromCamera(model) then
                            -- distance prioritization in world space
                            local distWorld = myHRP and (top.Position - myHRP.Position).Magnitude or 0
                            if distWorld < bestDist then
                                bestDist = distWorld
                                best = model
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ====== Events: Keep ESP map updated ======
-- remove old esp when model removed
local function refreshESP()
    -- create for current entities
    for model, meta in pairs(entities) do
        if isValidLivingModel(model) then
            local d = createESP(model)
            if d then
                -- set color
                if meta.type == "player" then
                    local pl = meta.source
                    if LocalPlayer.Team and pl.Team and LocalPlayer.Team == pl.Team then
                        d.frame.BackgroundColor3 = TEAM_COLOR
                    else
                        d.frame.BackgroundColor3 = ENEMY_COLOR
                    end
                else
                    d.frame.BackgroundColor3 = ENEMY_COLOR
                end
            end
        end
    end
    -- remove for models no longer entities
    for model, data in pairs(espMap) do
        if not entities[model] then
            removeESP(model)
        end
    end
end

-- watch player char add/remove to rescan quickly
Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function() task.wait(0.2); scanEntities(); refreshESP() end)
end)
Players.PlayerRemoving:Connect(function(pl) scanEntities(); refreshESP() end)

-- periodic scan for NPCs/monsters
task.spawn(function()
    while true do
        local now = tick()
        if now - lastScan >= REFRESH_SCAN_SECONDS then
            lastScan = now
            scanEntities()
            refreshESP()
        end
        task.wait(0.25)
    end
end)

-- also rescan on character spawn for local player
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.2); scanEntities(); refreshESP() end)

-- ====== Dragging for LockButton ======
do
    local dragging = false
    local dragInput, dragStart, startPos

    LockButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = LockButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    LockButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            LockButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            -- keep circle centered screen center (circle is UI overlay, not attached to button)
        end
    end)
end

-- toggle behavior
LockButton.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    LockButton.BackgroundColor3 = lockEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
    Circle.Visible = lockEnabled
    if lockEnabled then
        scanEntities()
        refreshESP()
    else
        -- hide ESP frames when disabled
        for model, data in pairs(espMap) do
            if data and data.frame then data.frame.Visible = false end
        end
    end
end)

-- ====== Main loop: pick and smooth-lock camera ======
local currentTargetModel = nil
local lastTargetUpdate = 0

RunService.RenderStepped:Connect(function(dt)
    -- keep ESP visible only when enabled
    if lockEnabled then
        for m,data in pairs(espMap) do
            if data and data.frame then data.frame.Visible = true end
        end
    end

    -- update selection/lock
    if lockEnabled then
        -- refresh entities if needed (scan runs periodically already)
        local picked = pickBestTarget()
        if picked ~= currentTargetModel then
            currentTargetModel = picked
            lastTargetUpdate = tick()
        end

        -- if have a target, smooth the camera lookAt
        if currentTargetModel and isValidLivingModel(currentTargetModel) then
            local top = topPartOfModel(currentTargetModel)
            if top then
                local lookPos = top.Position
                local targetCFrame = CFrame.new(Camera.CFrame.Position, lookPos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(dt * LERP_SPEED, 0, 1))
            end
        end
    else
        -- not enabled: ensure ESP hidden/clean
        currentTargetModel = nil
        for m,data in pairs(espMap) do
            if data and data.frame then data.frame.Visible = false end
        end
    end
end)
