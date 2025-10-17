-- 🔥 ESP & Aimbot Script Cải Tiến Tối Đa (TP Liên tục + Tự Aim sau TP + Fly Speed + Rope)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ⚙️ Settings
local ESP_ENABLED = true
local ENEMY_COLOR = Color3.fromRGB(255, 0, 0)

-- ⚙️ Aimbot Settings
local AIMBOT_ENABLED = false
-- Đổi sang chuột trái để tự động aim khi giữ chuột trái
local AIMBOT_KEY = Enum.UserInputType.MouseButton1
local AIMBOT_FOV = 350
local AIMBOT_SMOOTHNESS = 5
local AIMBOT_HEAD = true -- Mục tiêu Aimbot mặc định là Head

-- ⚙️ Camera Settings
local DEFAULT_CAMERA_FOV = 70
local CURRENT_CAMERA_FOV = DEFAULT_CAMERA_FOV

-- 🚀 Movement Settings
local WALKSPEED_ENABLED = false
local WALKSPEED_VALUE = 30
local DEFAULT_WALKSPEED = 16
local FLY_ENABLED = false
local FLYSPEED_VALUE = 3

-- ⚔️ Teleport Settings
local AUTOTP_ENABLED = false
local AUTOTP_KEY = Enum.KeyCode.F -- GIỮ PHÍM F để dịch chuyển liên tục và tự ghim tâm
local TP_OFFSET_BACK = 3 -- Khoảng cách dịch chuyển phía sau lưng kẻ địch (studs)

-- 🧩 Bảng quản lý Highlight & Beam
local enemyHighlights = {}
local enemyBeams = {} -- lưu các Beam/Attachment cho mỗi người

-- Tùy chọn dây (mặc định bật)
local ROPE_ENABLED = true

-- --------------------------------------------------------------------------------
-- 🪄 UI Menu ĐẸP HƠN (Không thay đổi cấu trúc, chỉ cập nhật tên nút)
-- --------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 640)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -320)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Border = Instance.new("Frame", MainFrame)
Border.Size = UDim2.new(1, 0, 1, 0)
Border.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Border.BackgroundTransparency = 0.8
Border.ZIndex = 0

local TitleBar = Instance.new("TextLabel", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleBar.Text = "✨ Phoenix Cheat Menu"
TitleBar.TextColor3 = Color3.new(1, 1, 1)
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextSize = 18
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -20, 1, -40)
Content.Position = UDim2.new(0, 10, 0, 35)
Content.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function createCheckbox(parent, name, initialText)
    local Button = Instance.new("TextButton", parent)
    Button.Name = name
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.Text = initialText
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Button.Font = Enum.Font.SourceSans
    Button.TextSize = 16
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    return Button
end

local function createSettingSection(parent, name, labelText, initialValue)
    local Container = Instance.new("Frame", parent)
    Container.Name = name .. "Container"
    Container.Size = UDim2.new(1, 0, 0, 55)
    Container.BackgroundTransparency = 1

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.Text = labelText
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 14

    local TextBox = Instance.new("TextBox", Container)
    TextBox.Name = name .. "Textbox"
    TextBox.Size = UDim2.new(1, 0, 0, 25)
    TextBox.Position = UDim2.new(0, 0, 0, 25)
    TextBox.PlaceholderText = tostring(initialValue)
    TextBox.Text = tostring(initialValue)
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TextBox.TextColor3 = Color3.new(1, 1, 1)
    TextBox.Font = Enum.Font.SourceSans
    TextBox.TextSize = 16
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 5)

    return Label, TextBox, Container
end

-- ESP & Aimbot Controls
local CheckboxESP = createCheckbox(Content, "CheckboxESP", ESP_ENABLED and "[✔] Highlight ESP" or "[ ] Highlight ESP")
local CheckboxAimbot = createCheckbox(Content, "CheckboxAimbot", AIMBOT_ENABLED and "[✔] Aimbot Enabled" or "[ ] Aimbot Disabled")
local CheckboxRope = createCheckbox(Content, "CheckboxRope", ROPE_ENABLED and "[✔] Red Rope" or "[ ] Red Rope")
local ColorLabel, ColorBox = createSettingSection(Content, "Color", "Enemy Color (red/blue...):", "red")
ColorBox.Text = "red"
local AimbotFOVLabel, AimbotFOVTextbox = createSettingSection(Content, "AimbotFOV", "Aimbot FOV: 150", AIMBOT_FOV)
local CameraFOVLabel, CameraFOVTextbox = createSettingSection(Content, "CameraFOV", "Camera FOV (30-120): 70", DEFAULT_CAMERA_FOV)

-- Movement Controls
local CheckboxWalkspeed = createCheckbox(Content, "CheckboxWalkspeed", WALKSPEED_ENABLED and "[✔] Fast Walk" or "[ ] Fast Walk")
local WalkspeedLabel, WalkspeedTextbox = createSettingSection(Content, "Walkspeed", "WalkSpeed (1-100): " .. WALKSPEED_VALUE, WALKSPEED_VALUE)
local CheckboxFly = createCheckbox(Content, "CheckboxFly", FLY_ENABLED and "[✔] Fly Enabled (Z-Up, X-Down)" or "[ ] Fly Disabled")
local FlyspeedLabel, FlyspeedTextbox = createSettingSection(Content, "Flyspeed", "Fly Speed (1-50): " .. FLYSPEED_VALUE, FLYSPEED_VALUE)

-- Teleport Controls
local CheckboxAutoTP = createCheckbox(Content, "CheckboxAutoTP", AUTOTP_ENABLED and "[✔] Hold F for TP Kill" or "[ ] Hold F for TP Kill")

-- Crosshair (Giữ nguyên)
local Crosshair = Instance.new("Frame", ScreenGui)
Crosshair.Name = "Crosshair"
Crosshair.BackgroundTransparency = 1
Crosshair.BorderSizePixel = 1
Crosshair.BorderColor3 = Color3.fromRGB(255, 255, 255)
Crosshair.ZIndex = 10
Crosshair.Size = UDim2.new(0, AIMBOT_FOV * 2, 0, AIMBOT_FOV * 2)
Crosshair.Position = UDim2.new(0.5, -AIMBOT_FOV, 0.5, -AIMBOT_FOV)
Crosshair.Visible = false

local UICorner = Instance.new("UICorner", Crosshair)
UICorner.CornerRadius = UDim.new(1, 0)

local CenterDot = Instance.new("Frame", Crosshair)
CenterDot.Size = UDim2.new(0, 3, 0, 3)
CenterDot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
CenterDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CenterDot.ZIndex = 11

-- --------------------------------------------------------------------------------
-- 🧠 Logic Functions
-- --------------------------------------------------------------------------------

-- 🧠 Hàm quản lý WalkSpeed (cải tiến: luôn cố gắng đặt đúng WalkSpeed khi bật)
local function updateWalkSpeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if WALKSPEED_ENABLED then
            humanoid.WalkSpeed = WALKSPEED_VALUE
        else
            humanoid.WalkSpeed = DEFAULT_WALKSPEED
        end
    end
end

-- 🧠 Hàm quản lý Fly (Giữ nguyên)
local function updateFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp then
        hrp.Anchored = FLY_ENABLED
        hrp.CanCollide = not FLY_ENABLED
    end

    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if FLY_ENABLED then
            humanoid.PlatformStand = true
        else
            humanoid.PlatformStand = false
        end
    end
end

-- ⚔️ NEW: Hàm tạo hoặc cập nhật Beam đỏ giữa tôi và kẻ địch
local function ensureBeamBetween(localHRP, enemyHRP, playerKey)
    if not localHRP or not enemyHRP then return end

    -- nếu đã tồn tại beam cho player thì kiểm tra attachment vẫn hợp lệ
    local slot = enemyBeams[playerKey]
    if slot and slot.beam and slot.att0 and slot.att1 then
        -- kiểm tra parent vẫn hợp lệ
        if slot.att0.Parent ~= localHRP or slot.att1.Parent ~= enemyHRP then
            -- destroy cũ, tạo mới
            if slot.beam then slot.beam:Destroy() end
            if slot.att0 then slot.att0:Destroy() end
            if slot.att1 then slot.att1:Destroy() end
            slot = nil
            enemyBeams[playerKey] = nil
        else
            return -- beam hợp lệ, không cần tạo lại
        end
    end

    -- tạo attachments và beam mới
    local att0 = Instance.new("Attachment")
    att0.Name = "Phoenix_Attachment_Local_" .. tostring(playerKey)
    att0.Parent = localHRP

    local att1 = Instance.new("Attachment")
    att1.Name = "Phoenix_Attachment_Enemy_" .. tostring(playerKey)
    att1.Parent = enemyHRP

    local beam = Instance.new("Beam")
    beam.Name = "Phoenix_Rope_Beam_" .. tostring(playerKey)
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.FaceCamera = true
    beam.Width0 = 0.08
    beam.Width1 = 0.08
    beam.LightEmission = 0.7
    beam.Transparency = NumberSequence.new(0)
    beam.Parent = workspace

    -- màu đỏ
    local cs = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    beam.Color = cs

    enemyBeams[playerKey] = {beam = beam, att0 = att0, att1 = att1}
end

local function removeBeamForPlayer(playerKey)
    local slot = enemyBeams[playerKey]
    if slot then
        if slot.beam then slot.beam:Destroy() end
        if slot.att0 then slot.att0:Destroy() end
        if slot.att1 then slot.att1:Destroy() end
        enemyBeams[playerKey] = nil
    end
end

-- ⚔️ NEW: Hàm Dịch Chuyển và Aim Đến Kẻ Địch Gần Nhất
local function teleportAndAimAtClosestEnemy()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local targetHead = nil
    local targetHRP = nil
    local smallestDistance = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character then
            local enemyHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            local enemyHead = plr.Character:FindFirstChild("Head")
            local enemyHumanoid = plr.Character:FindFirstChildOfClass("Humanoid")

            if enemyHRP and enemyHead and enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (myHRP.Position - enemyHRP.Position).Magnitude
                if distance < smallestDistance then
                    smallestDistance = distance
                    targetHRP = enemyHRP
                    targetHead = enemyHead
                end
            end
        end
    end

    if targetHRP and targetHead then
        local offset = targetHRP.CFrame.LookVector * -TP_OFFSET_BACK
        local tpCFrame = targetHRP.CFrame + offset
        myHRP.CFrame = tpCFrame

        if camera.CFrame and LocalPlayer.Character then
            local targetPos = targetHead.Position
            local origin = camera.CFrame.Position
            local desiredCFrame = CFrame.lookAt(origin, targetPos)
            camera.CFrame = desiredCFrame
        end
    end
end

-- 🧠 Bật/tắt ESP
CheckboxESP.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    CheckboxESP.Text = ESP_ENABLED and "[✔] Highlight ESP" or "[ ] Highlight ESP"
end)

-- 🧠 Bật/tắt Aimbot (giờ mặc định dùng chuột trái)
CheckboxAimbot.MouseButton1Click:Connect(function()
    AIMBOT_ENABLED = not AIMBOT_ENABLED
    CheckboxAimbot.Text = AIMBOT_ENABLED and "[✔] Aimbot Enabled" or "[ ] Aimbot Disabled"
    Crosshair.Visible = AIMBOT_ENABLED
end)

-- Bật/tắt Rope
CheckboxRope.MouseButton1Click:Connect(function()
    ROPE_ENABLED = not ROPE_ENABLED
    CheckboxRope.Text = ROPE_ENABLED and "[✔] Red Rope" or "[ ] Red Rope"
    if not ROPE_ENABLED then
        -- xóa tất cả beam hiện tại
        for k, _ in pairs(enemyBeams) do
            removeBeamForPlayer(k)
        end
    end
end)

-- 🚀 Bật/tắt Fast Walk
CheckboxWalkspeed.MouseButton1Click:Connect(function()
    WALKSPEED_ENABLED = not WALKSPEED_ENABLED
    CheckboxWalkspeed.Text = WALKSPEED_ENABLED and "[✔] Fast Walk" or "[ ] Fast Walk"
    updateWalkSpeed()
end)

-- 🚀 Đổi giá trị WalkSpeed
WalkspeedTextbox.FocusLost:Connect(function()
    local newSpeed = tonumber(WalkspeedTextbox.Text)
    if newSpeed and newSpeed >= 1 and newSpeed <= 100 then
        WALKSPEED_VALUE = newSpeed
        WalkspeedLabel.Text = "WalkSpeed (1-100): " .. WALKSPEED_VALUE
        updateWalkSpeed()
        WalkspeedTextbox.Text = tostring(WALKSPEED_VALUE)
    else
        WalkspeedTextbox.Text = tostring(WALKSPEED_VALUE)
    end
end)

-- 🚀 Bật/tắt Fly
CheckboxFly.MouseButton1Click:Connect(function()
    FLY_ENABLED = not FLY_ENABLED
    CheckboxFly.Text = FLY_ENABLED and "[✔] Fly Enabled (Z-Up, X-Down)" or "[ ] Fly Disabled"
    updateFly()
end)

-- 🚀 Đổi giá trị Fly Speed
FlyspeedTextbox.FocusLost:Connect(function()
    local newSpeed = tonumber(FlyspeedTextbox.Text)
    if newSpeed and newSpeed >= 1 and newSpeed <= 50 then
        FLYSPEED_VALUE = newSpeed
        FlyspeedLabel.Text = "Fly Speed (1-50): " .. FLYSPEED_VALUE
        FlyspeedTextbox.Text = tostring(FLYSPEED_VALUE)
    else
        FlyspeedTextbox.Text = tostring(FLYSPEED_VALUE)
    end
end)

-- ⚔️ Bật/tắt Auto TP
CheckboxAutoTP.MouseButton1Click:Connect(function()
    AUTOTP_ENABLED = not AUTOTP_ENABLED
    CheckboxAutoTP.Text = AUTOTP_ENABLED and "[✔] Hold F for TP Kill" or "[ ] Hold F for TP Kill"
end)

-- 🧠 Đổi màu kẻ địch
ColorBox.FocusLost:Connect(function()
    local colorName = string.lower(ColorBox.Text)
    local colors = {
        red = Color3.fromRGB(255, 0, 0), blue = Color3.fromRGB(0, 0, 255), green = Color3.fromRGB(0, 255, 0),
        yellow = Color3.fromRGB(255, 255, 0), purple = Color3.fromRGB(170, 0, 255), pink = Color3.fromRGB(255, 100, 200),
        cyan = Color3.fromRGB(0, 255, 255), orange = Color3.fromRGB(255, 120, 0), white = Color3.fromRGB(255, 255, 255),
    }
    if colors[colorName] then
        ENEMY_COLOR = colors[colorName]
        ColorBox.Text = colorName
        for _, highlight in pairs(enemyHighlights) do
            highlight.FillColor = ENEMY_COLOR
        end
    else
        ColorBox.Text = "red"
    end
end)

-- (Các hàm thay đổi FOV và getClosestTarget giữ nguyên)
AimbotFOVTextbox.FocusLost:Connect(function()
    local newFOV = tonumber(AimbotFOVTextbox.Text)
    if newFOV and newFOV >= 10 and newFOV <= 500 then
        AIMBOT_FOV = newFOV
        AimbotFOVLabel.Text = "Aimbot FOV: " .. AIMBOT_FOV
        Crosshair.Size = UDim2.new(0, AIMBOT_FOV * 2, 0, AIMBOT_FOV * 2)
        Crosshair.Position = UDim2.new(0.5, -AIMBOT_FOV, 0.5, -AIMBOT_FOV)
        AimbotFOVTextbox.Text = tostring(AIMBOT_FOV)
    else
        AimbotFOVTextbox.Text = tostring(AIMBOT_FOV)
    end
end)

CameraFOVTextbox.FocusLost:Connect(function()
    local newFOV = tonumber(CameraFOVTextbox.Text)
    if newFOV and newFOV >= 30 and newFOV <= 120 then
        CURRENT_CAMERA_FOV = newFOV
        CameraFOVLabel.Text = "Camera FOV (30-120): " .. CURRENT_CAMERA_FOV
        camera.FieldOfView = CURRENT_CAMERA_FOV
        CameraFOVTextbox.Text = tostring(CURRENT_CAMERA_FOV)
    else
        CameraFOVTextbox.Text = tostring(CURRENT_CAMERA_FOV)
    end
end)

local function getClosestTarget()
    local closestTarget = nil
    local smallestWorldDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local worldDistance = (myHRP.Position - head.Position).Magnitude
            local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
            local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
            local screenDistance = (screenPoint - screenCenter).Magnitude
            if onScreen and screenDistance < AIMBOT_FOV then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character, plr.Character}
                local raycastResult = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * worldDistance, params)
                local isClear = not raycastResult or (raycastResult.Instance and raycastResult.Instance:IsDescendantOf(plr.Character))
                if isClear then
                    if worldDistance < smallestWorldDistance then
                        smallestWorldDistance = worldDistance
                        closestTarget = head
                    end
                end
            end
        end
    end
    return closestTarget
end

-- 🧩 Hàm quản lý Highlight và Beam
local function setupEnemyESP(player)
    -- dọn highlight/beam nếu player là mình hoặc đồng đội
    if player == LocalPlayer or player.Team == LocalPlayer.Team then
        if enemyHighlights[player] then
            enemyHighlights[player]:Destroy()
            enemyHighlights[player] = nil
        end
        removeBeamForPlayer(player.UserId)
        return
    end

    local highlight = enemyHighlights[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = workspace
        highlight.FillTransparency = 0.6
        enemyHighlights[player] = highlight
    end

    local char = player.Character
    if char then
        highlight.Adornee = char
        highlight.FillColor = ENEMY_COLOR
        highlight.Enabled = ESP_ENABLED
    else
        highlight.Adornee = nil
        removeBeamForPlayer(player.UserId)
    end
end

-- --------------------------------------------------------------------------------
-- 🔁 Vòng lặp chính và Quản lý sự kiện
-- --------------------------------------------------------------------------------

-- 🔁 Vòng lặp chính (RenderStepped)
RunService.RenderStepped:Connect(function()
    -- 1. Đảm bảo FOV camera luôn được giữ
    if camera.FieldOfView ~= CURRENT_CAMERA_FOV then
        camera.FieldOfView = CURRENT_CAMERA_FOV
    end

    -- 2. Cập nhật trạng thái Highlight
    for plr, highlight in pairs(enemyHighlights) do
        if highlight.Enabled ~= ESP_ENABLED then
            highlight.Enabled = ESP_ENABLED
        end
        if highlight.FillColor ~= ENEMY_COLOR then
            highlight.FillColor = ENEMY_COLOR
        end
        if not highlight.Adornee and plr.Character then
            highlight.Adornee = plr.Character
        end
    end

    -- Cập nhật WalkSpeed liên tục (fix menu không hoạt động)
    -- Gọi nhẹ mỗi frame: updateWalkSpeed sẽ chỉ thay đổi humanoid khi cần
    updateWalkSpeed()

    -- 3. Aimbot Logic: giờ dùng chuột trái khi AIMBOT_ENABLED
    if AIMBOT_ENABLED and UserInputService:IsMouseButtonPressed(AIMBOT_KEY) then
        local targetHead = getClosestTarget()
        if targetHead and camera.CFrame and LocalPlayer.Character then
            local targetPos = targetHead.Position
            local origin = camera.CFrame.Position

            -- Nếu muốn mượt: dùng Lerp, nếu muốn tức thì thì bỏ Lerp
            local desiredCFrame = CFrame.lookAt(origin, targetPos)
            local currentCFrame = camera.CFrame
            local smoothCFrame = currentCFrame:Lerp(desiredCFrame, 1 / AIMBOT_SMOOTHNESS)

            camera.CFrame = smoothCFrame
        end
    end

    -- 4. Fly Movement Logic
    if FLY_ENABLED and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local moveSpeed = FLYSPEED_VALUE

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveSpeed = moveSpeed * 2
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then hrp.CFrame = hrp.CFrame + hrp.CFrame.lookVector * moveSpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then hrp.CFrame = hrp.CFrame - hrp.CFrame.lookVector * moveSpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then hrp.CFrame = hrp.CFrame - hrp.CFrame.rightVector * moveSpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then hrp.CFrame = hrp.CFrame + hrp.CFrame.rightVector * moveSpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.Z) then hrp.CFrame = hrp.CFrame + Vector3.new(0, moveSpeed, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.X) then hrp.CFrame = hrp.CFrame - Vector3.new(0, moveSpeed, 0) end
    end

    -- ⚔️ Dịch chuyển liên tục khi giữ phím F
    if AUTOTP_ENABLED and UserInputService:IsKeyDown(AUTOTP_KEY) then
        teleportAndAimAtClosestEnemy()
    end

    -- ⚔️ Cập nhật/beams: nếu rope bật thì tạo beam tới kẻ địch gần hoặc mọi kẻ địch (ở đây tạo beam tới mọi kẻ địch visible)
    if ROPE_ENABLED and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHRP = LocalPlayer.Character.HumanoidRootPart
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Team ~= LocalPlayer.Team then
                ensureBeamBetween(myHRP, plr.Character.HumanoidRootPart, plr.UserId)
            else
                removeBeamForPlayer(plr.UserId)
            end
        end
    else
        -- nếu rope tắt thì dọn sạch
        if not ROPE_ENABLED then
            for k, _ in pairs(enemyBeams) do
                removeBeamForPlayer(k)
            end
        end
    end
end)

-- ⌨️ Bắt sự kiện Input Bắt đầu (cho Toggle Menu)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Toggle menu bằng phím End
    if input.KeyCode == Enum.KeyCode.End then
        MainFrame.Visible = not MainFrame.Visible
        UserInputService.MouseBehavior = MainFrame.Visible and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    end
end)

-- 🧍 Quản lý người chơi và Character
local function onCharacterAdded(char)
    local player = Players:GetPlayerFromCharacter(char)
    if player then
        task.wait(0.1)
        setupEnemyESP(player)

        if player == LocalPlayer then
            updateWalkSpeed()
            updateFly()
            -- khi local player spawn lại, cần đảm bảo attachments beam cũ được tạo lại đúng parent
            for k, slot in pairs(enemyBeams) do
                -- nếu att0 đã hỏng, dọn slot; ensureBeamBetween sẽ tái tạo
                if not (slot.att0 and slot.att0.Parent) then
                    removeBeamForPlayer(k)
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end)

Players.PlayerRemoving:Connect(function(playerRemoved)
    if enemyHighlights[playerRemoved] then
        enemyHighlights[playerRemoved]:Destroy()
        enemyHighlights[playerRemoved] = nil
    end
    removeBeamForPlayer(playerRemoved.UserId)
end)

-- Khởi tạo ESP và Movement
for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        setupEnemyESP(plr)
    end
    plr.CharacterAdded:Connect(onCharacterAdded)
end

updateWalkSpeed()
updateFly()
