local modules = {
    CONFIG = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/CONFIG.lua"))(),
    UTILS = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/UTILS.lua"))(),
    UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/UI.lua"))(),
    ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/ESP.lua"))(),
    AIMBOT = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/AIMBOT.lua"))(),
    MOVEMENT = loadstring(game:HttpGet("https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/MOVEMENT.lua"))(),
}

local Config = modules.CONFIG
local UI = modules.UI
local UTILS = modules.UTILS

-- Khởi tạo GUI
local ScreenGui, Pages = UI.createGui(Config)

print("PhoenixMain loaded successfully!")
