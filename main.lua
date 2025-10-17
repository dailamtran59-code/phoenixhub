-- 🧠 Main Script
local repo = "https://raw.githubusercontent.com/TenGitHubCuaBan/ten-repo/main/modules/" 

-- Load các module
local CONFIG = loadstring(game:HttpGet(repo .. "CONFIG.lua"))()
local ESP = loadstring(game:HttpGet(repo .. "ESP.lua"))()
local AIMBOT = loadstring(game:HttpGet(repo .. "AIMBOT.lua"))()
local UI = loadstring(game:HttpGet(repo .. "UI.lua"))()
local UTILS = loadstring(game:HttpGet(repo .. "UTILS.lua"))()

-- Gọi hàm khởi tạo UI (tùy vào UI.lua bạn viết)
if UI and UI.CreateMenu then
    UI.CreateMenu()
else
    warn("⚠️ UI.lua chưa có hàm CreateMenu hoặc bị lỗi")
end
