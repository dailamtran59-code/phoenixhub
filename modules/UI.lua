local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CONFIG = require(script.Parent.CONFIG) -- trong Roblox ModuleScript; nếu dùng executor, loader sẽ set môi trường require thích hợp

local M = {}

function M.createGui()
    -- dùng code UI của bạn (đã có trong Phoenix script).
    -- hàm này trả về ScreenGui và pages table
    -- ví dụ rút gọn:
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Phoenix_Menu_ScreenGui"
    local pages = {}
    -- ... xây GUI giống như script gốc ...
    return ScreenGui, pages
end

return M

