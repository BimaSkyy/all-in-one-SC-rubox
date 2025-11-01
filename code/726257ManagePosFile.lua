-- ✅ Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

-- ✅ Pastikan folder DEBUGING ada
if not isfolder("DEBUGING") then
    makefolder("DEBUGING")
end

-- ✅ Variabel
local selectedFile = nil
local listGui = nil
local isEditing = false -- Variabel baru untuk mengecek status editing

-- ✅ GUI Utama
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "FileManagerGui"
ScreenGui.ResetOnSpawn = false

-- Tombol utama ⚙️
local MainButton = Instance.new("TextButton", ScreenGui)
MainButton.Size = UDim2.new(0,35,0,35)
MainButton.Position = UDim2.new(1,-60,0.5,-15)
MainButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
MainButton.Text = "⚙️"
MainButton.TextScaled = true
MainButton.Draggable = true
MainButton.AutoButtonColor = true
MainButton.Active = true

-- Frame tombol bawah ⚙️
local ExtraFrame = Instance.new("Frame", MainButton)
ExtraFrame.Size = UDim2.new(1,80,0,150)
ExtraFrame.Position = UDim2.new(0,0,1,5)
ExtraFrame.BackgroundTransparency = 0.3
ExtraFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
ExtraFrame.Visible = false

-- ✅ Notifikasi kecil
local function notify(msg)
    local n = Instance.new("TextLabel", ScreenGui)
    n.Size = UDim2.new(0,220,0,30)
    n.Position = UDim2.new(0.5,-110,0,60)
    n.BackgroundColor3 = Color3.fromRGB(0,0,0)
    n.TextColor3 = Color3.fromRGB(255,255,255)
    n.TextScaled = true
    n.Text = msg
    n.ZIndex = 10
    Debris:AddItem(n,2)
end

-- ✅ Helper file
local function writeJson(path, tbl)
    writefile(path, HttpService:JSONEncode(tbl))
end

local function readJson(path)
    return HttpService:JSONDecode(readfile(path))
end

-- ✅ Label status file
local FileLabel = Instance.new("TextLabel", ExtraFrame)
FileLabel.Size = UDim2.new(1,0,0,20)
FileLabel.Position = UDim2.new(0,0,0,0)
FileLabel.BackgroundTransparency = 1
FileLabel.TextColor3 = Color3.fromRGB(255,255,255)
FileLabel.TextScaled = true
FileLabel.Text = "file ${} dipilih"

-- ✅ Fungsi tombol
local function newFile()
    if isEditing then
        notify("Harap klik done dahulu sebelum membuat file baru✨")
        return
    end

    isEditing = true

    local editFrame = Instance.new("Frame", ScreenGui)
    editFrame.Size = UDim2.new(0, 150, 0, 90)
    editFrame.Position = UDim2.new(0.5, -75, 0.5, -45)
    editFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    editFrame.Active = true
    editFrame.Draggable = true

    local inputBox = Instance.new("TextBox", editFrame)
    inputBox.Size = UDim2.new(1,0,0,25)
    inputBox.Position = UDim2.new(0,0,0,0)
    inputBox.PlaceholderText = "Nama file"
    inputBox.Text = ""
    inputBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    inputBox.TextColor3 = Color3.fromRGB(255,255,255)

    local saveBtn = Instance.new("TextButton", editFrame)
    saveBtn.Size = UDim2.new(1,0,0,25)
    saveBtn.Position = UDim2.new(0,0,0,30)
    saveBtn.Text = "Save"
    saveBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    saveBtn.TextColor3 = Color3.fromRGB(255,255,255)

    local cancelBtn = Instance.new("TextButton", editFrame)
    cancelBtn.Size = UDim2.new(1,0,0,25)
    cancelBtn.Position = UDim2.new(0,0,0,60)
    cancelBtn.Text = "Cancel"
    cancelBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    cancelBtn.TextColor3 = Color3.fromRGB(255,255,255)

    saveBtn.MouseButton1Click:Connect(function()
        local name = inputBox.Text
        if name == "" then return end
        local path = "DEBUGING/"..name..".json"
        if isfile(path) then
            notify("File dengan nama itu sudah ada, gunakan nama lain!")
        else
            writeJson(path,{})
            notify("File "..name.." sudah dibuat👻")
        end
        editFrame:Destroy()
        isEditing = false
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        editFrame:Destroy()
        isEditing = false
    end)
end

local function selectFile()
    if listGui then
        listGui:Destroy()
        listGui = nil
        return
    end

    local files = listfiles("DEBUGING")
    if #files == 0 then
        notify("Tidak ada file di dalam folder")
        return
    end

    listGui = Instance.new("ScrollingFrame", ScreenGui)
    listGui.Size = UDim2.new(0, 220, 0, 90)
    listGui.Position = UDim2.new(0.5, -110, 0.5, -45)
    listGui.BackgroundColor3 = Color3.fromRGB(20,20,20)
    listGui.ScrollBarThickness = 6
    listGui.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local y = 0
    for _, path in ipairs(files) do
        if path:match("%.json$") then
            local btn = Instance.new("TextButton", listGui)
            btn.Size = UDim2.new(1,0,0,20)
            btn.Position = UDim2.new(0,0,0,y)
            btn.Text = path:match("DEBUGING/(.+)")
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.TextScaled = true
            y = y + 25

            btn.MouseButton1Click:Connect(function()
                selectedFile = path
                FileLabel.Text = "file "..btn.Text.." dipilih"
                listGui:Destroy()
                listGui = nil
            end)
        end
    end
end

local function newPos()
    if not selectedFile then
        notify("Belum ada file yang kamu pilih, silakan pilih dulu dong!")
        return
    end

    if isEditing then
        notify("Harap klik done dahulu sebelum membuat file baru✨")
        return
    end

    isEditing = true

    local editFrame = Instance.new("Frame", ScreenGui)
    editFrame.Size = UDim2.new(0, 150, 0, 90)
    editFrame.Position = UDim2.new(0.5, -75, 0.5, -45)
    editFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    editFrame.Active = true
    editFrame.Draggable = true

    local inputBox = Instance.new("TextBox", editFrame)
    inputBox.Size = UDim2.new(1,0,0,25)
    inputBox.Position = UDim2.new(0,0,0,0)
    inputBox.PlaceholderText = "Nama posisi"
    inputBox.Text = ""
    inputBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    inputBox.TextColor3 = Color3.fromRGB(255,255,255)

    local saveBtn = Instance.new("TextButton", editFrame)
    saveBtn.Size = UDim2.new(1,0,0,25)
    saveBtn.Position = UDim2.new(0,0,0,30)
    saveBtn.Text = "Save"
    saveBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    saveBtn.TextColor3 = Color3.fromRGB(255,255,255)

    local cancelBtn = Instance.new("TextButton", editFrame)
    cancelBtn.Size = UDim2.new(1,0,0,25)
    cancelBtn.Position = UDim2.new(0,0,0,60)
    cancelBtn.Text = "Cancel"
    cancelBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    cancelBtn.TextColor3 = Color3.fromRGB(255,255,255)

    saveBtn.MouseButton1Click:Connect(function()
        local name = inputBox.Text
        if name == "" then return end
        local data = readJson(selectedFile)
        for _,pos in ipairs(data) do
            if pos.name == name then
                notify("Nama pos itu sudah ada, pilih nama lain!")
                editFrame:Destroy()
                isEditing = false
                return
            end
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            table.insert(data, {
                name = name,
                y = hrp.Position.Y,
                x = hrp.Position.X,
                z = hrp.Position.Z
            })
            writeJson(selectedFile, data)
            notify("Posisi disimpan ke "..selectedFile)
        end
        editFrame:Destroy()
        isEditing = false
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        editFrame:Destroy()
        isEditing = false
    end)
end

local function done()
    selectedFile = nil
    FileLabel.Text = "file ${} dipilih"
    if listGui then listGui:Destroy() listGui=nil end
    notify("Reset selesai")
end

-- ✅ Fungsi bikin tombol
local function makeBtn(name, order, color, func)
    local b = Instance.new("TextButton", ExtraFrame)
    b.Size = UDim2.new(1,0,0,25)
    b.Position = UDim2.new(0,0,0,20+(order*30))
    b.Text = name
    b.BackgroundColor3 = color
    b.TextScaled = true
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.MouseButton1Click:Connect(func)
    return b
end

-- ✅ Tambahin tombol
makeBtn("NewFile",1,Color3.fromRGB(0,200,0),newFile)
makeBtn("SelectFile",2,Color3.fromRGB(0,150,255),selectFile)
makeBtn("NewPos",3,Color3.fromRGB(200,200,0),newPos)
makeBtn("Done",4,Color3.fromRGB(200,0,0),done)

-- ✅ Toggle menu
MainButton.MouseButton1Click:Connect(function()
    ExtraFrame.Visible = not ExtraFrame.Visible
end)
