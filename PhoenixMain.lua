-- nếu dùng ModuleScript: local modules = script.Parent.modules
local CONFIG = require(script.modules.CONFIG)
local UTILS = require(script.modules.UTILS)
local UI = require(script.modules.UI)
local ESP = require(script.modules.ESP)
local AIM = require(script.modules.AIMBOT)
local MOV = require(script.modules.MOVEMENT)

local ScreenGui, Pages = UI.createGui()
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- ví dụ đăng ký RenderStepped
local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function(dt)
    -- ESP update
    ESP.updateAll()
    -- Movement update
    MOV.updateWalkspeed()
    -- Aimbot active check ...
end)
