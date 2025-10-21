-- ========== CONFIG DEFAULTS ==========
local Config = {
    Theme = { 
        Background = Color3.fromRGB(16, 12, 24), 
        Accent = Color3.fromRGB(140, 58, 200), 
        SecondaryAccent = Color3.fromRGB(100, 40, 150),
        Text = Color3.fromRGB(230, 230, 230),
        Hover = Color3.fromRGB(180, 80, 240)
    },
    ESP = { Enabled = true, Color = "purple", FillTransparency = 0.6 },
    Aimbot = { Enabled = false, Key = Enum.UserInputType.MouseButton1, FOV = 150, Smoothness = 5, AimHead = true, ShowFOV = true },
    SilentAim = { 
        Enabled = false, 
        AimPart = "Head", 
        PredictMovement = true, 
        PredictionAmount = 0.13,
        FOV = 150,
        ShowFOV = true
    },
    TriggerBot = { Enabled = false, Key = Enum.UserInputType.MouseButton1, Delay = 0.01 },
    AutoReload = { Enabled = false, AmmoThreshold = 1 },
    UnlockGuns = { Enabled = false },
    Movement = { WalkspeedEnabled = false, Walkspeed = 30, FlyEnabled = false, FlySpeed = 3, JetpackSpeed = 6 },
    Teleport = { AutoTP = false, TPKey = Enum.KeyCode.F, TPBack = 3 },
    Rope = { Enabled = true },
    UI = { Visible = false },
}

-- ========== UTILITIES ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local canWrite = (type(writefile) == "function")
local ConfigFileName = "PhoenixMenuConfig.json"

-- Auto-detect remotes
local ShootRemote = nil
local function findShootRemote()
    local remotes = {
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("RemoteEvent"),
        game:GetService("ReplicatedFirst"):FindFirstChild("Remotes")
    }
    for _, remoteFolder in pairs(remotes) do
        if remoteFolder then
            local candidates = {"Shoot", "Fire", "ShootEvent", "FireWeapon", "ReplicateShot"}
            for _, name in pairs(candidates) do
                local remote = remoteFolder:FindFirstChild(name)
                if remote and remote:IsA("RemoteEvent") then
                    ShootRemote = remote
                    return remote
                end
            end
        end
    end
    return nil
end
ShootRemote = findShootRemote()

local ReloadRemote = nil
local function findReloadRemote()
    local remotes = {
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("RemoteEvent")
    }
    for _, remoteFolder in pairs(remotes) do
        if remoteFolder then
            local candidates = {"Reload", "ReloadWeapon", "ReplicateReload"}
            for _, name in pairs(candidates) do
                local remote = remoteFolder:FindFirstChild(name)
                if remote and remote:IsA("RemoteEvent") then
                    ReloadRemote = remote
                    return remote
                end
            end
        end
    end
    return nil
end
ReloadRemote = findReloadRemote()

local UnlockRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UnlockGun") or nil

local function deepCopy(table)
    local copy = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function saveConfig()
    if canWrite then
        local success, err = pcall(function()
            writefile(ConfigFileName, game:GetService("HttpService"):JSONEncode(Config))
        end)
        return success, err
    else
        return false, "writefile not available"
    end
end

local function loadConfig()
    if canWrite and isfile and readfile and isfile(ConfigFileName) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(ConfigFileName))
        end)
        if ok and type(data) == "table" then
            local default = deepCopy(Config)
            for k, v in pairs(data) do
                if default[k] ~= nil then
                    if type(v) == "table" and type(default[k]) == "table" then
                        for sk, sv in pairs(v) do
                            if default[k][sk] ~= nil then
                                default[k][sk] = sv
                            end
                        end
                    else
                        default[k] = v
                    end
                end
            end
            Config = default
            return true
        end
    end
    return false
end

local colorByName = {
    purple = Color3.fromRGB(140, 58, 200), 
    red = Color3.fromRGB(255,0,0), 
    blue = Color3.fromRGB(0,120,255),
    green = Color3.fromRGB(0,200,120), 
    yellow = Color3.fromRGB(255,230,0), 
    white = Color3.fromRGB(255,255,255)
}

local colorNames = {"purple", "red", "blue", "green", "yellow", "white"}

-- ========== UI CREATION ==========
local function createGui()
    pcall(function() workspace:FindFirstChild("Phoenix_Menu_ScreenGui"):Destroy() end)

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Phoenix_Menu_ScreenGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 450, 0, 450)
    Main.Position = UDim2.new(0.5, -225, 0.5, -225)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = false
    Main.Visible = Config.UI.Visible
    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, 16)
    
    local Gradient = Instance.new("UIGradient", Main)
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Theme.Background),
        ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
    })
    Gradient.Rotation = 45

    local Shadow = Instance.new("ImageLabel", Main)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://131604521"
    Shadow.ImageTransparency = 0.8
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = -1

    local BorderFrame = Instance.new("Frame", Main)
    BorderFrame.Name = "BorderFrame"
    BorderFrame.Size = UDim2.new(1, 10, 1, 10)
    BorderFrame.Position = UDim2.new(0, -5, 0, -5)
    BorderFrame.BackgroundTransparency = 1
    BorderFrame.BorderSizePixel = 0
    BorderFrame.Active = true
    BorderFrame.Draggable = true

    local TabsPanel = Instance.new("Frame", Main)
    TabsPanel.Name = "TabsPanel"
    TabsPanel.Size = UDim2.new(0, 120, 1, -40)
    TabsPanel.Position = UDim2.new(0, 10, 0, 40)
    TabsPanel.BackgroundTransparency = 1
    TabsPanel.BorderSizePixel = 0
    local TabsCorner = Instance.new("UICorner", TabsPanel)
    TabsCorner.CornerRadius = UDim.new(0, 12)

    local TabList = Instance.new("UIListLayout", TabsPanel)
    TabList.Padding = UDim.new(0, 10)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder

    local Content = Instance.new("Frame", Main)
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -140, 1, -40)
    Content.Position = UDim2.new(0, 130, 0, 40)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    local ContentCorner = Instance.new("UICorner", Content)
    ContentCorner.CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, -50, 0, 30) -- Điều chỉnh kích thước để chừa chỗ cho nút tắt
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Config.Theme.Accent
    Title.TextSize = 20
    Title.Text = "✨ Phoenix - TímĐen Menu"
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseButton = Instance.new("TextButton", Main)
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -40, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseButton.Text = "X"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 16
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.AutoButtonColor = false
    local CloseCorner = Instance.new("UICorner", CloseButton)
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseButton.MouseButton1Click:Connect(function()
        Config.UI.Visible = false
        Main.Visible = false
    end)
    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        }):Play()
    end)
    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
            BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        }):Play()
    end)

    local currentTab = "ESP"
    local function newTabButton(text)
        local btn = Instance.new("TextButton", TabsPanel)
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(26, 20, 34)
        btn.Font = Enum.Font.GothamBold
        btn.Text = text
        btn.TextSize = 15
        btn.TextColor3 = Config.Theme.Text
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 10)
        local btnGradient = Instance.new("UIGradient", btn)
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })
        btnGradient.Rotation = 90

        local function refreshHighlight()
            local isSelected = currentTab == text
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            TweenService:Create(btn, tweenInfo, {
                BackgroundColor3 = isSelected and Config.Theme.Accent or Color3.fromRGB(26, 20, 34),
                TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Config.Theme.Text
            }):Play()
            btnGradient.Enabled = not isSelected
        end

        btn.MouseEnter:Connect(function()
            if currentTab ~= text then
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundColor3 = Config.Theme.Hover
                }):Play()
            end
        end)

        btn.MouseLeave:Connect(function()
            if currentTab ~= text then
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundColor3 = Color3.fromRGB(26, 20, 34)
                }):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            currentTab = text
            for _, child in ipairs(TabsPanel:GetChildren()) do
                if child:IsA("TextButton") then
                    local isSelected = child.Text == text
                    TweenService:Create(child, tweenInfo, {
                        BackgroundColor3 = isSelected and Config.Theme.Accent or Color3.fromRGB(26, 20, 34),
                        TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Config.Theme.Text
                    }):Play()
                    child:FindFirstChildOfClass("UIGradient").Enabled = not isSelected
                end
            end
            for name, page in pairs(pages) do
                page.Visible = (name == text)
            end
        end)
        refreshHighlight()
        return btn, refreshHighlight
    end

    local pages = {}
    local function newPage(name)
        local frame = Instance.new("Frame", Content)
        frame.Name = name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Visible = false
        return frame
    end

    pages.ESP = newPage("ESP")
    pages.Aimbot = newPage("Aimbot")
    pages.SilentAim = newPage("SilentAim")
    pages.Combat = newPage("Combat")
    pages.Movement = newPage("Movement")
    pages.Teleport = newPage("Teleport")
    pages.Settings = newPage("Settings")

    local btnESP, espRefresh = newTabButton("ESP")
    local btnAimbot, aimRefresh = newTabButton("Aimbot")
    local btnSilent, silentRefresh = newTabButton("SilentAim")
    local btnCombat, combatRefresh = newTabButton("Combat")
    local btnMove, moveRefresh = newTabButton("Movement")
    local btnTP, tpRefresh = newTabButton("Teleport")
    local btnSet, setRefresh = newTabButton("Settings")

    pages.ESP.Visible = true

    local function makeToggle(parent, labelText, getterSet)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 40)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0.3, 0, 0.75, 0)
        btn.Position = UDim2.new(0.7, 0, 0.125, 0)
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        local function refresh()
            btn.Text = getterSet.get() and "✔ ON" or "OFF"
            btn.BackgroundColor3 = getterSet.get() and Config.Theme.Accent or Color3.fromRGB(36, 30, 44)
            btn.TextColor3 = Config.Theme.Text
        end

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = getterSet.get() and Config.Theme.Accent or Config.Theme.Hover
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundColor3 = getterSet.get() and Config.Theme.Accent or Color3.fromRGB(36, 30, 44)
            }):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            getterSet.set(not getterSet.get())
            refresh()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                Size = UDim2.new(0.32, 0, 0.8, 0)
            }):Play()
            wait(0.1)
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                Size = UDim2.new(0.3, 0, 0.75, 0)
            }):Play()
        end)
        refresh()
        return container
    end

    local function makeSlider(parent, labelText, valueTable, key, minV, maxV)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 50)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = labelText .. ": " .. tostring(valueTable[key])
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local sliderBg = Instance.new("Frame", container)
        sliderBg.Size = UDim2.new(1, 0, 0, 14)
        sliderBg.Position = UDim2.new(0, 0, 0, 28)
        sliderBg.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 8)
        local sliderGradient = Instance.new("UIGradient", sliderBg)
        sliderGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })

        local handle = Instance.new("Frame", sliderBg)
        handle.Size = UDim2.new((valueTable[key] - minV) / (maxV - minV), 0, 1, 0)
        handle.BackgroundColor3 = Config.Theme.Accent
        Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 8)
        local handleGradient = Instance.new("UIGradient", handle)
        handleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Accent),
            ColorSequenceKeypoint.new(1, Config.Theme.Hover)
        })

        local dragging = false
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new((valueTable[key] - minV) / (maxV - minV), 0, 1.2, 0)
                }):Play()
            end
        end)
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                TweenService:Create(handle, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new((valueTable[key] - minV) / (maxV - minV), 0, 1, 0)
                }):Play()
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                valueTable[key] = math.floor((minV + (maxV - minV) * rel) + 0.5)
                label.Text = labelText .. ": " .. tostring(valueTable[key])
                handle.Size = UDim2.new((valueTable[key] - minV) / (maxV - minV), 0, 1, 0)
            end
        end)
        return container
    end

    local function makeTextbox(parent, labelText, initial, onChange)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 50)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", container)
        box.Size = UDim2.new(1, 0, 0, 26)
        box.Position = UDim2.new(0, 0, 0, 24)
        box.Text = tostring(initial)
        box.ClearTextOnFocus = false
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.TextColor3 = Config.Theme.Text
        box.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        local boxGradient = Instance.new("UIGradient", box)
        boxGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })

        box.FocusLost:Connect(function(enter)
            if enter then
                onChange(box.Text)
                TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 28)
                }):Play()
                wait(0.1)
                TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 26)
                }):Play()
            end
        end)
        return container
    end

    local function makeDropdown(parent, labelText, options, initial, onSelect)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 50)
        container.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.Position = UDim2.new(0, 0, 0, 24)
        btn.Text = initial
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = Config.Theme.Text
        btn.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local btnGradient = Instance.new("UIGradient", btn)
        btnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })

        local listFrame = Instance.new("Frame", container)
        listFrame.Size = UDim2.new(1, 0, 0, #options * 26)
        listFrame.Position = UDim2.new(0, 0, 1, 2)
        listFrame.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        listFrame.Visible = false
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
        local listGradient = Instance.new("UIGradient", listFrame)
        listGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })
        Instance.new("UIListLayout", listFrame).Padding = UDim.new(0, 2)

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", listFrame)
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.Text = opt
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 14
            optBtn.TextColor3 = Config.Theme.Text
            optBtn.BackgroundTransparency = 1
            optBtn.MouseButton1Click:Connect(function()
                btn.Text = opt
                onSelect(opt)
                listFrame.Visible = false
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 28)
                }):Play()
                wait(0.1)
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 26)
                }):Play()
            end)
            optBtn.MouseEnter:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundTransparency = 0,
                    BackgroundColor3 = Config.Theme.Hover
                }):Play()
            end)
            optBtn.MouseLeave:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    BackgroundTransparency = 1
                }):Play()
            end)
        end

        btn.MouseButton1Click:Connect(function()
            listFrame.Visible = not listFrame.Visible
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                Size = UDim2.new(1, 0, 0, listFrame.Visible and 28 or 26)
            }):Play()
        end)

        return container
    end

    -- === ESP Page ===
    do
        local page = pages.ESP
        local y = 10
        local tgl = makeToggle(page, "Enable ESP", { get = function() return Config.ESP.Enabled end, set = function(v) Config.ESP.Enabled = v end })
        tgl.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local colorDropdown = makeDropdown(page, "Enemy Color", colorNames, Config.ESP.Color, function(selected)
            Config.ESP.Color = selected
        end)
        colorDropdown.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1, 0, 1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Aimbot Page ===
    do
        local page = pages.Aimbot
        local y = 10
        local tgl = makeToggle(page, "Enable Aimbot", { get = function() return Config.Aimbot.Enabled end, set = function(v) Config.Aimbot.Enabled = v end })
        tgl.Position = UDim2.new(0, 0, 0, y); y = y + 50
        local fov = makeSlider(page, "Aimbot FOV", Config.Aimbot, "FOV", 10, 500)
        fov.Position = UDim2.new(0, 0, 0, y); y = y + 60
        local smooth = makeSlider(page, "Smoothness", Config.Aimbot, "Smoothness", 1, 20)
        smooth.Position = UDim2.new(0, 0, 0, y); y = y + 60
        local headToggle = makeToggle(page, "Aim Head", { get = function() return Config.Aimbot.AimHead end, set = function(v) Config.Aimbot.AimHead = v end })
        headToggle.Position = UDim2.new(0, 0, 0, y); y = y + 50
        local showFOVToggle = makeToggle(page, "Show FOV Circle", { get = function() return Config.Aimbot.ShowFOV end, set = function(v) Config.Aimbot.ShowFOV = v end })
        showFOVToggle.Position = UDim2.new(0, 0, 0, y); y = y + 50
    end

    -- === Silent Aim Page ===
    do
        local page = pages.SilentAim
        local y = 10
        local tgl = makeToggle(page, "Enable Silent Aim", { get = function() return Config.SilentAim.Enabled end, set = function(v) Config.SilentAim.Enabled = v end })
        tgl.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local fovSlider = makeSlider(page, "Silent Aim FOV", Config.SilentAim, "FOV", 50, 500)
        fovSlider.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local showFOV = makeToggle(page, "Show FOV Circle", { get = function() return Config.SilentAim.ShowFOV end, set = function(v) Config.SilentAim.ShowFOV = v end })
        showFOV.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local partDropdown = makeDropdown(page, "Aim Part", {"Head", "Torso"}, Config.SilentAim.AimPart, function(selected)
            Config.SilentAim.AimPart = selected
        end)
        partDropdown.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local predToggle = makeToggle(page, "Predict Movement", { get = function() return Config.SilentAim.PredictMovement end, set = function(v) Config.SilentAim.PredictMovement = v end })
        predToggle.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local predSlider = makeSlider(page, "Prediction Amount", Config.SilentAim, "PredictionAmount", 0, 0.5)
        predSlider.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local infoLabel = Instance.new("TextLabel", page)
        infoLabel.Size = UDim2.new(1, 0, 0, 40)
        infoLabel.Position = UDim2.new(0, 0, 0, y)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 11
        infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        infoLabel.Text = "🎯 Camera KHÔNG QUAY - Chỉ đạn tự nhắm!"
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1, 0, 1, -y - 50)
        filler.BackgroundTransparency = 1
    end

    -- === Combat Page ===
    do
        local page = pages.Combat
        local y = 10
        local tglTrigger = makeToggle(page, "Enable TriggerBot", { get = function() return Config.TriggerBot.Enabled end, set = function(v) Config.TriggerBot.Enabled = v end })
        tglTrigger.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local triggerDelay = makeSlider(page, "Trigger Delay (s)", Config.TriggerBot, "Delay", 0, 0.5)
        triggerDelay.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local tglReload = makeToggle(page, "Enable Auto Reload", { get = function() return Config.AutoReload.Enabled end, set = function(v) Config.AutoReload.Enabled = v end })
        tglReload.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local ammoThreshold = makeSlider(page, "Reload Threshold", Config.AutoReload, "AmmoThreshold", 0, 10)
        ammoThreshold.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local tglUnlock = makeToggle(page, "Unlock All Guns", { get = function() return Config.UnlockGuns.Enabled end, set = function(v) Config.UnlockGuns.Enabled = v; if v then unlockAllGuns() end end })
        tglUnlock.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1, 0, 1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Movement Page ===
    do
        local page = pages.Movement
        local y = 10
        local tglWalk = makeToggle(page, "Enable Fast Walk", { get = function() return Config.Movement.WalkspeedEnabled end, set = function(v) Config.Movement.WalkspeedEnabled = v end })
        tglWalk.Position = UDim2.new(0, 0, 0, y); y = y + 50
        local ws = makeSlider(page, "WalkSpeed", Config.Movement, "Walkspeed", 1, 100)
        ws.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local tglFly = makeToggle(page, "Enable Fly (Space/Shift)", { get = function() return Config.Movement.FlyEnabled end, set = function(v) Config.Movement.FlyEnabled = v end })
        tglFly.Position = UDim2.new(0, 0, 0, y); y = y + 50
        local flySpeed = makeSlider(page, "Fly Speed (jetpack)", Config.Movement, "FlySpeed", 1, 12)
        flySpeed.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1, 0, 1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Teleport Page ===
    do
        local page = pages.Teleport
        local y = 10
        local tglTP = makeToggle(page, "Hold F to Auto-TP", { get = function() return Config.Teleport.AutoTP end, set = function(v) Config.Teleport.AutoTP = v end })
        tglTP.Position = UDim2.new(0, 0, 0, y); y = y + 50
        local tpBack = makeTextbox(page, "TP Back Offset (studs)", Config.Teleport.TPBack, function(txt)
            local n = tonumber(txt) or Config.Teleport.TPBack
            Config.Teleport.TPBack = n
        end)
        tpBack.Position = UDim2.new(0, 0, 0, y); y = y + 60

        local tglRope = makeToggle(page, "Enable Rope/Beam", { get = function() return Config.Rope.Enabled end, set = function(v) Config.Rope.Enabled = v end })
        tglRope.Position = UDim2.new(0, 0, 0, y); y = y + 50

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1, 0, 1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Settings Page ===
    do
        local page = pages.Settings
        local y = 10
        local saveBtn = Instance.new("TextButton", page)
        saveBtn.Size = UDim2.new(1, 0, 0, 40)
        saveBtn.Text = "Save Config"
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.TextSize = 14
        saveBtn.TextColor3 = Config.Theme.Text
        saveBtn.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)
        local saveGradient = Instance.new("UIGradient", saveBtn)
        saveGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })
        saveBtn.Position = UDim2.new(0, 0, 0, y); y = y + 50
        saveBtn.MouseButton1Click:Connect(function()
            local ok, err = saveConfig()
            if ok then
                saveBtn.Text = "Saved ✔"
                TweenService:Create(saveBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 42)
                }):Play()
                wait(1)
                TweenService:Create(saveBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 40)
                }):Play()
                saveBtn.Text = "Save Config"
            else
                saveBtn.Text = "Save Failed"
                warn(err)
                wait(1.2)
                saveBtn.Text = "Save Config"
            end
        end)

        local loadBtn = Instance.new("TextButton", page)
        loadBtn.Size = UDim2.new(1, 0, 0, 40)
        loadBtn.Text = "Load Config"
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 14
        loadBtn.TextColor3 = Config.Theme.Text
        loadBtn.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 10)
        local loadGradient = Instance.new("UIGradient", loadBtn)
        loadGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })
        loadBtn.Position = UDim2.new(0, 0, 0, y); y = y + 50
        loadBtn.MouseButton1Click:Connect(function()
            local ok = loadConfig()
            if ok then
                loadBtn.Text = "Loaded ✔"
                TweenService:Create(loadBtn, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 0, 0, 42)
                }):Play()
                wait(1)
                createGui()
            else
                loadBtn.Text = "Load Failed"
                wait(1.2)
                loadBtn.Text = "Load Config"
            end
        end)

        local toggleUI = Instance.new("TextButton", page)
        toggleUI.Size = UDim2.new(1, 0, 0, 40)
        toggleUI.Text = "Toggle UI (End)"
        toggleUI.Font = Enum.Font.GothamBold
        toggleUI.TextSize = 14
        toggleUI.TextColor3 = Config.Theme.Text
        toggleUI.BackgroundColor3 = Color3.fromRGB(36, 30, 44)
        Instance.new("UICorner", toggleUI).CornerRadius = UDim.new(0, 10)
        local toggleGradient = Instance.new("UIGradient", toggleUI)
        toggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Theme.Background),
            ColorSequenceKeypoint.new(1, Config.Theme.SecondaryAccent)
        })
        toggleUI.Position = UDim2.new(0, 0, 0, y); y = y + 50
        toggleUI.MouseButton1Click:Connect(function()
            Config.UI.Visible = not Config.UI.Visible
            Main.Visible = Config.UI.Visible
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
                ImageTransparency = Config.UI.Visible and 0 or 1
            }):Play()
        end)

        local info = Instance.new("TextLabel", page)
        info.Size = UDim2.new(1, 0, 0, 70)
        info.Position = UDim2.new(0, 0, 0, y)
        info.BackgroundTransparency = 1
        info.Font = Enum.Font.Gotham
        info.TextSize = 12
        info.TextColor3 = Config.Theme.Text
        info.Text = "Compatible: executor (writefile enabled) -> Save/Load works.\nAlso works when used via loadstring (pastes as single script).\nUse End key to toggle menu.\nNote: Adapt remotes for your game!"
        info.TextXAlignment = Enum.TextXAlignment.Left
    end

    task.delay(0.05, function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "ESP")
        end
    end)

    btnESP.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "ESP")
        end
    end)
    btnAimbot.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "Aimbot")
        end
    end)
    btnSilent.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "SilentAim")
        end
    end)
    btnCombat.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "Combat")
        end
    end)
    btnMove.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "Movement")
        end
    end)
    btnTP.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "Teleport")
        end
    end)
    btnSet.MouseButton1Click:Connect(function() 
        for name, page in pairs(pages) do
            page.Visible = (name == "Settings")
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.End then
            Config.UI.Visible = not Config.UI.Visible
            Main.Visible = Config.UI.Visible
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
                ImageTransparency = Config.UI.Visible and 0 or 1
            }):Play()
        end
    end)

    return ScreenGui, pages
end

-- Build GUI
local ScreenGui, Pages = createGui()

-- Unlock All Guns
local function unlockAllGuns()
    if not Config.UnlockGuns.Enabled then return end
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") and stat.Name:lower():find("level") then
                stat.Value = 100
            end
        end
    end
    if UnlockRemote then
        for i = 1, 100 do
            pcall(function() UnlockRemote:FireServer(i) end)
        end
    end
    print("Guns unlocked!")
end

local function getCurrentAmmo()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        local ammoValue = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
        return ammoValue and ammoValue.Value or 0
    end
    return 0
end

-- ========== SILENT AIM LOGIC ==========
local silentFOVCircle = Drawing.new("Circle")
silentFOVCircle.Visible = false
silentFOVCircle.Radius = Config.SilentAim.FOV
silentFOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
silentFOVCircle.Color = Color3.fromRGB(140, 58, 200)
silentFOVCircle.Thickness = 2
silentFOVCircle.NumSides = 64
silentFOVCircle.Transparency = 0.7

local function getSilentAimTarget()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestDist = math.huge
    local chosenPart = nil
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and 
           plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 then
            
            local aimPart = plr.Character:FindFirstChild(Config.SilentAim.AimPart) or 
                           (Config.SilentAim.AimPart == "Torso" and plr.Character:FindFirstChild("UpperTorso"))
            
            if aimPart then
                local screenPos, onScreen = camera:WorldToScreenPoint(aimPart.Position)
                if onScreen then
                    local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                    local distToCenter = (screenVec - center).Magnitude
                    
                    if distToCenter <= Config.SilentAim.FOV and distToCenter < closestDist then
                        local params = RaycastParams.new()
                        params.FilterDescendantsInstances = {LocalPlayer.Character}
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        local rayDir = (aimPart.Position - camera.CFrame.Position)
                        local raycast = workspace:Raycast(camera.CFrame.Position, rayDir.Unit * rayDir.Magnitude, params)
                        local clearLOS = not raycast or raycast.Instance:IsDescendantOf(plr.Character)
                        
                        if clearLOS then
                            closestDist = distToCenter
                            chosenPart = aimPart
                        end
                    end
                end
            end
        end
    end
    return chosenPart
end

local lastSilentShot = 0
local function handleSilentAim()
    if not Config.SilentAim.Enabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    if tick() - lastSilentShot < 0.05 then return end
    
    local targetPart = getSilentAimTarget()
    if not targetPart then return end
    
    local prediction = Vector3.new(0, 0, 0)
    if Config.SilentAim.PredictMovement then
        prediction = targetPart.Velocity * Config.SilentAim.PredictionAmount
    end
    local predictedPos = targetPart.Position + prediction
    
    local shootDirection = (predictedPos - camera.CFrame.Position).Unit
    
    if ShootRemote then
        pcall(function()
            ShootRemote:FireServer(shootDirection, predictedPos, camera.CFrame.Position)
        end)
    end
    
    lastSilentShot = tick()
end

-- TriggerBot
local lastTriggerTime = 0
local function checkTriggerBot()
    if not Config.TriggerBot.Enabled or not UserInputService:IsMouseButtonPressed(Config.TriggerBot.Key) then return end
    local now = tick()
    if now - lastTriggerTime < Config.TriggerBot.Delay then return end

    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local dist = (mousePos - center).Magnitude
    if dist > 20 then return end

    local targetHead = getClosestTarget()
    if targetHead then
        if ShootRemote then
            pcall(function() ShootRemote:FireServer(targetHead.Position) end)
        end
        lastTriggerTime = now
    end
end

-- Auto Reload
local lastReloadTime = 0
local function checkAutoReload()
    if not Config.AutoReload.Enabled then return end
    local ammo = getCurrentAmmo()
    if ammo <= Config.AutoReload.AmmoThreshold and tick() - lastReloadTime > 1 then
        if ReloadRemote then
            pcall(function() ReloadRemote:FireServer() end)
        end
        lastReloadTime = tick()
    end
end

-- CORE LOGIC
local enemyHighlights = {}
local enemyBeams = {}

local function ensureBeamBetween(localHRP, enemyHRP, id)
    if not localHRP or not enemyHRP then return end
    local slot = enemyBeams[id]
    if slot then
        if slot.att0 and slot.att0.Parent == localHRP and slot.att1 and slot.att1.Parent == enemyHRP and slot.beam then
            return
        else
            if slot.beam then slot.beam:Destroy() end
            if slot.att0 then slot.att0:Destroy() end
            if slot.att1 then slot.att1:Destroy() end
            enemyBeams[id] = nil
        end
    end
    local att0 = Instance.new("Attachment") att0.Parent = localHRP
    local att1 = Instance.new("Attachment") att1.Parent = enemyHRP
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 0.08
    beam.Width1 = 0.08
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(colorByName[Config.ESP.Color] or Config.Theme.Accent)
    beam.Parent = workspace
    enemyBeams[id] = {beam = beam, att0 = att0, att1 = att1}
end

local function removeBeamForPlayer(id)
    local slot = enemyBeams[id]
    if slot then
        if slot.beam then slot.beam:Destroy() end
        if slot.att0 then slot.att0:Destroy() end
        if slot.att1 then slot.att1:Destroy() end
        enemyBeams[id] = nil
    end
end

local function setupEnemyESP(player)
    if player == LocalPlayer or player.Team == LocalPlayer.Team then
        if enemyHighlights[player] then enemyHighlights[player]:Destroy() enemyHighlights[player] = nil end
        removeBeamForPlayer(player.UserId)
        return
    end
    local highlight = enemyHighlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = workspace
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        enemyHighlights[player] = highlight
    end
    if player.Character then
        highlight.Adornee = player.Character
        highlight.FillTransparency = Config.ESP.FillTransparency or 0.6
        highlight.FillColor = colorByName[Config.ESP.Color] or Config.Theme.Accent
        highlight.Enabled = Config.ESP.Enabled
    else
        highlight.Adornee = nil
    end
end

local function getClosestTarget()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closestDist = math.huge
    local chosenHead = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
            if onScreen then
                local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                local distToCenter = (screenVec - center).Magnitude
                if distToCenter <= Config.Aimbot.FOV and distToCenter < closestDist then
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {LocalPlayer.Character}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local dist = (myHRP.Position - head.Position).Magnitude
                    local rr = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * dist, params)
                    local clear = not rr or (rr.Instance and rr.Instance:IsDescendantOf(plr.Character))
                    if clear then
                        closestDist = distToCenter
                        chosenHead = head
                    end
                end
            end
        end
    end
    return chosenHead
end

local function teleportAndAim()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local targetHead = getClosestTarget()
    if not targetHead then return end
    local enemyHRP = targetHead.Parent:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end
    local offset = enemyHRP.CFrame.LookVector * -Config.Teleport.TPBack
    myHRP.CFrame = enemyHRP.CFrame + offset
    local origin = camera.CFrame.Position
    camera.CFrame = CFrame.lookAt(origin, targetHead.Position)
end

local function aimAt(targetPos)
    if not camera or not camera.CFrame then return end
    local origin = camera.CFrame.Position
    local desired = CFrame.lookAt(origin, targetPos)
    local smooth = 1 / math.max(1, Config.Aimbot.Smoothness or 5)
    camera.CFrame = camera.CFrame:Lerp(desired, smooth)
end

local function updateWalkspeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = Config.Movement.WalkspeedEnabled and Config.Movement.Walkspeed or 16
    end
end

local flyState = { active = false, velocity = Vector3.new(0, 0, 0) }
local function startFly()
    flyState.active = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Anchored = false
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = true end
end
local function stopFly()
    flyState.active = false
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = false end
end

local keysDown = {}
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard then
        keysDown[i.KeyCode] = true
    end
end)
UserInputService.InputEnded:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard then
        keysDown[i.KeyCode] = nil
    end
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = Config.Aimbot.FOV
fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Transparency = 0.8

-- MAIN LOOP
RunService.RenderStepped:Connect(function(delta)
    fovCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
    fovCircle.Radius = Config.Aimbot.FOV
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    silentFOVCircle.Visible = Config.SilentAim.Enabled and Config.SilentAim.ShowFOV
    silentFOVCircle.Radius = Config.SilentAim.FOV
    silentFOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                setupEnemyESP(plr)
                if Config.Rope.Enabled and plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character:FindFirstChild("HumanoidRootPart") then
                    ensureBeamBetween(myHRP, plr.Character.HumanoidRootPart, plr.UserId)
                else
                    removeBeamForPlayer(plr.UserId)
                end
            end
        end
    end

    updateWalkspeed()

    if Config.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Config.Aimbot.Key) then
        local targetHead = getClosestTarget()
        if targetHead then
            local aimPos = Config.Aimbot.AimHead and targetHead.Position or (targetHead.Position - Vector3.new(0, 1, 0))
            aimAt(aimPos)
        end
    end

    if Config.Teleport.AutoTP and UserInputService:IsKeyDown(Config.Teleport.TPKey) then
        teleportAndAim()
    end

    handleSilentAim()
    checkTriggerBot()
    checkAutoReload()

    if Config.Movement.FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if not flyState.active then startFly() end
        local up = (keysDown[Enum.KeyCode.Space] and 1 or 0)
        local down = (keysDown[Enum.KeyCode.LeftShift] and 1 or 0)
        local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        local back = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        local left = (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        local right = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)

        local vert = (up - down)
        local speed = math.clamp(Config.Movement.FlySpeed, 0.5, Config.Movement.JetpackSpeed or 6)
        local moveVec = Vector3.new((right - left), vert, (back - forward) * -1)
        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * speed
        else
            moveVec = Vector3.new(0, vert * speed, 0)
        end
        local camCF = workspace.CurrentCamera.CFrame
        local worldMove = (camCF.RightVector * moveVec.X) + (Vector3.new(0, 1, 0) * moveVec.Y) + (camCF.LookVector * moveVec.Z)
        hrp.CFrame = hrp.CFrame + worldMove * delta * 60
    else
        if flyState.active then stopFly() end
    end
end)

Players.PlayerRemoving:Connect(function(pl)
    if enemyHighlights[pl] then enemyHighlights[pl]:Destroy() enemyHighlights[pl] = nil end
    removeBeamForPlayer(pl.UserId)
end)

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function(ch)
        task.wait(0.05)
        setupEnemyESP(pl)
    end)
    if pl.Character then setupEnemyESP(pl) end
end)

print("✅ Phoenix Menu loaded - SILENT AIM: Camera KHÔNG QUAY, đạn tự nhắm!")
print("💜 Silent Aim FOV: Vòng tím | Aimbot FOV: Vòng trắng")
print("🔫 Click chuột bất kỳ đâu → Đạn tự bay về head enemy!")
