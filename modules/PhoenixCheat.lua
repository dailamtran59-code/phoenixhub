-- Phoenix Cheat Menu — Tabbed UI (Tím & Đen)
-- Tương thích: chạy trực tiếp trên executor (Synapse/Fluxus/...) hoặc qua loadstring(game:HttpGet(url))
-- Tính năng: ESP, Aimbot, Movement (Walkspeed, Fly), Teleport+Rope, Save/Load config
-- Fly control: Space = lên, LeftShift = xuống (jetpack vừa phải)
-- Lưu cấu hình nếu executor hỗ trợ writefile/readfile

-- ========== CONFIG DEFAULTS ==========
local Config = {
    Theme = { Background = Color3.fromRGB(16,12,24), Accent = Color3.fromRGB(140, 58, 200), Text = Color3.fromRGB(230,230,230) },

    ESP = { Enabled = true, Color = "purple", FillTransparency = 0.6 },
    Aimbot = { Enabled = false, Key = Enum.UserInputType.MouseButton1, FOV = 150, Smoothness = 5, AimHead = true },
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
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local canWrite = (type(writefile) == "function")
local ConfigFileName = "PhoenixMenuConfig.json"

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
            Config = data
            return true
        end
    end
    return false
end

-- small helper for color by name
local colorByName = {
    purple = Color3.fromRGB(140, 58, 200), red = Color3.fromRGB(255,0,0), blue = Color3.fromRGB(0,120,255),
    green = Color3.fromRGB(0,200,120), yellow = Color3.fromRGB(255,230,0), white = Color3.fromRGB(255,255,255)
}

-- ========== UI CREATION ==========
local function createGui()
    -- remove previous if exists (safer for re-execution)
    pcall(function() workspace:FindFirstChild("Phoenix_Menu_ScreenGui"):Destroy() end)

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Phoenix_Menu_ScreenGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- Main frame
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 420, 0, 380)
    Main.Position = UDim2.new(0.5, -210, 0.5, -190)
    Main.AnchorPoint = Vector2.new(0.5,0.5)
    Main.BackgroundColor3 = Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Visible = Config.UI.Visible
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    -- Left tabs panel
    local TabsPanel = Instance.new("Frame", Main)
    TabsPanel.Name = "TabsPanel"
    TabsPanel.Size = UDim2.new(0, 110, 1, -20)
    TabsPanel.Position = UDim2.new(0, 8, 0, 10)
    TabsPanel.BackgroundTransparency = 1

    local TabList = Instance.new("UIListLayout", TabsPanel)
    TabList.Padding = UDim.new(0, 8)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Right content container
    local Content = Instance.new("Frame", Main)
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -130, 1, -20)
    Content.Position = UDim2.new(0, 122, 0, 10)
    Content.BackgroundTransparency = 1
    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

    -- Title
    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Config.Theme.Accent
    Title.TextSize = 18
    Title.Text = "✨ Phoenix - TímĐen Menu"
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- helper to create tab button
    local function newTabButton(text)
        local btn = Instance.new("TextButton", TabsPanel)
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(26,20,34)
        btn.Font = Enum.Font.Gotham
        btn.Text = text
        btn.TextSize = 14
        btn.TextColor3 = Config.Theme.Text
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    -- create content pages
    local pages = {}
    local function newPage(name)
        local frame = Instance.new("Frame", Content)
        frame.Name = name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Position = UDim2.new(1, 0, 0, 0) -- off-screen to the right initially
        frame.BackgroundTransparency = 1
        frame.Visible = true
        return frame
    end

    pages.ESP = newPage("ESP")
    pages.Aimbot = newPage("Aimbot")
    pages.Movement = newPage("Movement")
    pages.Teleport = newPage("Teleport")
    pages.Settings = newPage("Settings")

    -- create tab buttons
    local btnESP = newTabButton("ESP")
    local btnAimbot = newTabButton("Aimbot")
    local btnMove = newTabButton("Movement")
    local btnTP = newTabButton("Teleport-Rope")
    local btnSet = newTabButton("Settings")

    -- simple slide function
    local function slideTo(pageName)
        for name, pg in pairs(pages) do
            local goal = {Position = UDim2.new(name == pageName and 0 or 1, 0, 0, 0)}
            TweenService:Create(pg, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), goal):Play()
        end
    end

    -- populate pages with controls (small helper functions)
    local function makeToggle(parent, labelText, getterSet)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 36)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0.28, 0, 0.8, 0)
        btn.Position = UDim2.new(0.72, 0, 0.1, 0)
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        local function refresh()
            btn.Text = getterSet.get() and "[✔] ON" or "[ ] OFF"
            btn.BackgroundColor3 = getterSet.get() and Config.Theme.Accent or Color3.fromRGB(40,36,46)
            btn.TextColor3 = Config.Theme.Text
        end
        btn.MouseButton1Click:Connect(function()
            getterSet.set(not getterSet.get())
            refresh()
        end)
        refresh()
        return container
    end

    local function makeSlider(parent, labelText, valueTable, key, minV, maxV)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1,0,0,48)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1,0,0,18)
        label.BackgroundTransparency = 1
        label.Text = labelText .. ": " .. tostring(valueTable[key])
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local sliderBg = Instance.new("Frame", container)
        sliderBg.Size = UDim2.new(1,0,0,12)
        sliderBg.Position = UDim2.new(0,0,0,26)
        sliderBg.BackgroundColor3 = Color3.fromRGB(36,30,44)
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0,6)

        local handle = Instance.new("Frame", sliderBg)
        handle.Size = UDim2.new((valueTable[key]-minV)/(maxV-minV), 0, 1, 0)
        handle.BackgroundColor3 = Config.Theme.Accent
        Instance.new("UICorner", handle).CornerRadius = UDim.new(0,6)

        local dragging = false
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X, 0, 1)
                valueTable[key] = math.floor((minV + (maxV-minV)*rel)+0.5)
                label.Text = labelText .. ": " .. tostring(valueTable[key])
                handle.Size = UDim2.new((valueTable[key]-minV)/(maxV-minV), 0, 1, 0)
            end
        end)
        return container
    end

    local function makeTextbox(parent, labelText, initial, onChange)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1,0,0,48)
        container.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1,0,0,18)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = Config.Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", container)
        box.Size = UDim2.new(1,0,0,24)
        box.Position = UDim2.new(0,0,0,22)
        box.Text = tostring(initial)
        box.ClearTextOnFocus = false
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.TextColor3 = Config.Theme.Text
        box.BackgroundColor3 = Color3.fromRGB(36,30,44)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
        box.FocusLost:Connect(function(enter)
            if enter then
                onChange(box.Text)
            end
        end)
        return container
    end

    -- === ESP Page ===
    do
        local page = pages.ESP
        local y = 6
        local tgl = makeToggle(page, "Enable ESP", { get = function() return Config.ESP.Enabled end, set = function(v) Config.ESP.Enabled = v end })
        tgl.Position = UDim2.new(0,0,0, y); y = y + 44

        local colorBox = makeTextbox(page, "Enemy Color (name)", "purple", function(txt)
            local name = string.lower(tostring(txt))
            if colorByName[name] then
                Config.ESP.Color = name
            else
                Config.ESP.Color = "purple"
            end
        end)
        colorBox.Position = UDim2.new(0,0,0,y); y = y + 54

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1,0,1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Aimbot Page ===
    do
        local page = pages.Aimbot
        local y = 6
        local tgl = makeToggle(page, "Enable Aimbot", { get = function() return Config.Aimbot.Enabled end, set = function(v) Config.Aimbot.Enabled = v end })
        tgl.Position = UDim2.new(0,0,0,y); y = y + 44
        local fov = makeSlider(page, "Aimbot FOV", Config.Aimbot, "FOV", 10, 500)
        fov.Position = UDim2.new(0,0,0,y); y = y + 56
        local smooth = makeSlider(page, "Smoothness", Config.Aimbot, "Smoothness", 1, 20)
        smooth.Position = UDim2.new(0,0,0,y); y = y + 56
        local headToggle = makeToggle(page, "Aim Head", { get = function() return Config.Aimbot.AimHead end, set = function(v) Config.Aimbot.AimHead = v end })
        headToggle.Position = UDim2.new(0,0,0,y); y = y + 44
    end

    -- === Movement Page ===
    do
        local page = pages.Movement
        local y = 6
        local tglWalk = makeToggle(page, "Enable Fast Walk", { get = function() return Config.Movement.WalkspeedEnabled end, set = function(v) Config.Movement.WalkspeedEnabled = v end })
        tglWalk.Position = UDim2.new(0,0,0,y); y = y + 44
        local ws = makeSlider(page, "WalkSpeed", Config.Movement, "Walkspeed", 1, 100)
        ws.Position = UDim2.new(0,0,0,y); y = y + 56

        local tglFly = makeToggle(page, "Enable Fly (Space/Shift)", { get = function() return Config.Movement.FlyEnabled end, set = function(v) Config.Movement.FlyEnabled = v end })
        tglFly.Position = UDim2.new(0,0,0,y); y = y + 44
        local flySpeed = makeSlider(page, "Fly Speed (jetpack)", Config.Movement, "FlySpeed", 1, 12)
        flySpeed.Position = UDim2.new(0,0,0,y); y = y + 56

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1,0,1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Teleport Page ===
    do
        local page = pages.Teleport
        local y = 6
        local tglTP = makeToggle(page, "Hold F to Auto-TP", { get = function() return Config.Teleport.AutoTP end, set = function(v) Config.Teleport.AutoTP = v end })
        tglTP.Position = UDim2.new(0,0,0,y); y = y + 44
        local tpBack = makeTextbox(page, "TP Back Offset (studs)", Config.Teleport.TPBack, function(txt)
            local n = tonumber(txt) or Config.Teleport.TPBack
            Config.Teleport.TPBack = n
        end)
        tpBack.Position = UDim2.new(0,0,0,y); y = y + 54

        local tglRope = makeToggle(page, "Enable Rope/Beam", { get = function() return Config.Rope.Enabled end, set = function(v) Config.Rope.Enabled = v end })
        tglRope.Position = UDim2.new(0,0,0,y); y = y + 44

        local filler = Instance.new("Frame", page)
        filler.Size = UDim2.new(1,0,1, -y)
        filler.BackgroundTransparency = 1
    end

    -- === Settings Page ===
    do
        local page = pages.Settings
        local y = 6
        local saveBtn = Instance.new("TextButton", page)
        saveBtn.Size = UDim2.new(1,0,0,36)
        saveBtn.Text = "Save Config"
        saveBtn.Font = Enum.Font.Gotham
        saveBtn.TextSize = 14
        saveBtn.TextColor3 = Config.Theme.Text
        saveBtn.BackgroundColor3 = Color3.fromRGB(36,30,44)
        Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,8)
        saveBtn.Position = UDim2.new(0,0,0,y); y = y + 44
        saveBtn.MouseButton1Click:Connect(function()
            local ok, err = saveConfig()
            if ok then
                saveBtn.Text = "Saved ✔"
                wait(1)
                saveBtn.Text = "Save Config"
            else
                saveBtn.Text = "Save Failed"
                warn(err)
                wait(1.2)
                saveBtn.Text = "Save Config"
            end
        end)

        local loadBtn = Instance.new("TextButton", page)
        loadBtn.Size = UDim2.new(1,0,0,36)
        loadBtn.Text = "Load Config"
        loadBtn.Font = Enum.Font.Gotham
        loadBtn.TextSize = 14
        loadBtn.TextColor3 = Config.Theme.Text
        loadBtn.BackgroundColor3 = Color3.fromRGB(36,30,44)
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0,8)
        loadBtn.Position = UDim2.new(0,0,0,y); y = y + 44
        loadBtn.MouseButton1Click:Connect(function()
            local ok = loadConfig()
            if ok then
                loadBtn.Text = "Loaded ✔"
                wait(1)
                -- rebuild GUI with new config
                createGui()
            else
                loadBtn.Text = "Load Failed"
                wait(1.2)
                loadBtn.Text = "Load Config"
            end
        end)

        local toggleUI = Instance.new("TextButton", page)
        toggleUI.Size = UDim2.new(1,0,0,36)
        toggleUI.Text = "Toggle UI (End)"
        toggleUI.Font = Enum.Font.Gotham
        toggleUI.TextSize = 14
        toggleUI.TextColor3 = Config.Theme.Text
        toggleUI.BackgroundColor3 = Color3.fromRGB(36,30,44)
        Instance.new("UICorner", toggleUI).CornerRadius = UDim.new(0,8)
        toggleUI.Position = UDim2.new(0,0,0,y); y = y + 44
        toggleUI.MouseButton1Click:Connect(function()
            Config.UI.Visible = not Config.UI.Visible
            Main.Visible = Config.UI.Visible
        end)

        local info = Instance.new("TextLabel", page)
        info.Size = UDim2.new(1,0,0,70)
        info.Position = UDim2.new(0,0,0,y)
        info.BackgroundTransparency = 1
        info.Font = Enum.Font.Gotham
        info.TextSize = 12
        info.TextColor3 = Config.Theme.Text
        info.Text = "Compatible: executor (writefile enabled) -> Save/Load works.\nAlso works when used via loadstring (pastes as single script).\nUse End key to toggle menu."
        info.TextXAlignment = Enum.TextXAlignment.Left

    end

    -- initial slide to ESP
    task.delay(0.05, function() slideTo("ESP") end)

    -- tab click handlers
    btnESP.MouseButton1Click:Connect(function() slideTo("ESP") end)
    btnAimbot.MouseButton1Click:Connect(function() slideTo("Aimbot") end)
    btnMove.MouseButton1Click:Connect(function() slideTo("Movement") end)
    btnTP.MouseButton1Click:Connect(function() slideTo("Teleport") end)
    btnSet.MouseButton1Click:Connect(function() slideTo("Settings") end)

    -- key for toggle
    UserInputService.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.End then
            Config.UI.Visible = not Config.UI.Visible
            Main.Visible = Config.UI.Visible
        end
    end)

    return ScreenGui, pages
end

-- build GUI
local ScreenGui, Pages = createGui()

-- ========== CORE LOGIC (ESP / Aimbot / Movement / Teleams) ==========
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

-- getClosestTarget (used by aimbot & teleport)
local function getClosestTarget()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local smallest = math.huge
    local chosenHead = nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local dist = (myHRP.Position - head.Position).Magnitude
            local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
            if onScreen and dist < smallest then
                -- line of sight check
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local rr = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * dist, params)
                local clear = not rr or (rr.Instance and rr.Instance:IsDescendantOf(plr.Character))
                if clear then
                    smallest = dist
                    chosenHead = head
                end
            end
        end
    end
    return chosenHead
end

-- Teleport & Aim to closest
local function teleportAndAim()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local targetHead = getClosestTarget()
    if not targetHead then return end
    local enemyHRP = targetHead.Parent:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end
    local offset = enemyHRP.CFrame.LookVector * -Config.Teleport.TPBack
    myHRP.CFrame = enemyHRP.CFrame + offset
    -- set camera to look at head
    local origin = camera.CFrame.Position
    camera.CFrame = CFrame.lookAt(origin, targetHead.Position)
end

-- Aimbot smooth look
local function aimAt(targetPos)
    if not camera or not camera.CFrame then return end
    local origin = camera.CFrame.Position
    local desired = CFrame.lookAt(origin, targetPos)
    local smooth = 1 / math.max(1, Config.Aimbot.Smoothness or 5)
    camera.CFrame = camera.CFrame:Lerp(desired, smooth)
end

-- Movement helpers
local function updateWalkspeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = Config.Movement.WalkspeedEnabled and Config.Movement.Walkspeed or 16
    end
end

-- Fly system (jetpack-like, Space up, Shift down)
local flyState = { active = false, velocity = Vector3.new(0,0,0) }
local function startFly()
    flyState.active = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.Anchored = false
    -- use PlatformStand to smooth control
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

-- Input handling for fly
local keysDown = {}
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard then
        keysDown[i.KeyCode] = true
    end
end)
UserInputService.InputEnded:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard then
        keysDown[i.KeyCode] = nil
    end
end)

-- Main RenderStepped update
RunService.RenderStepped:Connect(function(delta)
    -- maintain camera FOV if needed (page might set elsewhere in extended builds)

    -- update ESP highlights & beams
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

    -- update walkspeed continuously
    updateWalkspeed()

    -- Aimbot
    if Config.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Config.Aimbot.Key) then
        local targetHead = getClosestTarget()
        if targetHead then
            local aimPos = Config.Aimbot.AimHead and targetHead.Position or (targetHead.Position - Vector3.new(0,1,0))
            aimAt(aimPos)
        end
    end

    -- Auto TP while holding F
    if Config.Teleport.AutoTP and UserInputService:IsKeyDown(Config.Teleport.TPKey) then
        teleportAndAim()
    end

    -- Fly control
    if Config.Movement.FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        -- enable state
        if not flyState.active then startFly() end
        local up = (keysDown[Enum.KeyCode.Space] and 1 or 0)
        local down = (keysDown[Enum.KeyCode.LeftShift] and 1 or 0)
        local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        local back = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        local left = (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        local right = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)

        local vert = (up - down)
        local speed = math.clamp(Config.Movement.FlySpeed, 0.5, Config.Movement.JetpackSpeed or 6)
        -- build movement vector in local space
        local moveVec = Vector3.new((right-left), vert, (forward-back))
        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit * speed
        else
            moveVec = Vector3.new(0, vert * speed, 0)
        end
        -- apply movement relative to camera
        local camCF = workspace.CurrentCamera.CFrame
        local worldMove = (camCF.RightVector * moveVec.X) + (Vector3.new(0,1,0) * moveVec.Y) + (camCF.LookVector * moveVec.Z)
        hrp.CFrame = hrp.CFrame + worldMove * delta * 60
    else
        if flyState.active then stopFly() end
    end
end)

-- cleanup on player leaving characters
Players.PlayerRemoving:Connect(function(pl)
    if enemyHighlights[pl] then enemyHighlights[pl]:Destroy() enemyHighlights[pl] = nil end
    removeBeamForPlayer(pl.UserId)
end)

-- handle CharacterAdded to re-setup esp etc
Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function(ch)
        task.wait(0.05)
        setupEnemyESP(pl)
    end)
    if pl.Character then setupEnemyESP(pl) end
end)

-- final note: script ready
print("Phoenix Menu (TímĐen) loaded. Press End to toggle UI.")

-- End of script
