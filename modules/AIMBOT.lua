local Players = game:GetService("Players")
local camera = workspace.CurrentCamera
local CONFIG = require(script.Parent.CONFIG)

local M = {}

local function lineOfSightClear(head, plr)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local dist = (camera.CFrame.Position - head.Position).Magnitude
    local rr = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * dist, params)
    return not rr or (rr.Instance and rr.Instance:IsDescendantOf(plr.Character))
end

function M.getClosestTarget()
    local LocalPlayer = Players.LocalPlayer
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local smallest = math.huge
    local chosenHead = nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local dist = (myHRP.Position - head.Position).Magnitude
            local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
            if onScreen and dist < smallest and lineOfSightClear(head, plr) then
                smallest = dist
                chosenHead = head
            end
        end
    end
    return chosenHead
end

function M.aimAt(targetPos)
    local origin = camera.CFrame.Position
    local desired = CFrame.lookAt(origin, targetPos)
    local smooth = 1 / math.max(1, CONFIG.Config.Aimbot.Smoothness or 5)
    camera.CFrame = camera.CFrame:Lerp(desired, smooth)
end

return M

