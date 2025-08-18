-- di activity.lua
return function(id)
    local HttpService = game:GetService("HttpService")

    local url = "https://raw.githubusercontent.com/BimaSkyy/all-in-one-SC-rubox/refs/heads/main/"..id..".txt"
    local response = game:HttpGet(url)

    local text = response:match("text%s*=%s*(.-)\n")
    local link = response:match("url%s*=%s*(.-)\n")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InfoBar"
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 280, 0, 140)
    Frame.Position = UDim2.new(0.5, -140, 0.5, -70)
    Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Frame.BackgroundTransparency = 0.1
    Frame.Parent = ScreenGui
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 60)
    Label.Position = UDim2.new(0, 10, 0, 10)
    Label.Text = text or "No text found"
    Label.TextWrapped = true
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 16
    Label.TextColor3 = Color3.new(1,1,1)
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0.45, 0, 0, 35)
    CopyBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
    CopyBtn.Text = "Copy"
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 16
    CopyBtn.TextColor3 = Color3.new(1,1,1)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(40,170,80)
    CopyBtn.Parent = Frame
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 8)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0.45, 0, 0, 35)
    CloseBtn.Position = UDim2.new(0.5, 0, 0.65, 0)
    CloseBtn.Text = "Close"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.TextColor3 = Color3.new(1,1,1)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    CloseBtn.Parent = Frame
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

    CopyBtn.MouseButton1Click:Connect(function()
        if link then
            setclipboard(link)
            game.StarterGui:SetCore("SendNotification", {
                Title = "Success",
                Text = "Link successfully copied!",
                Duration = 3
            })
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "No link found",
                Duration = 3
            })
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end
