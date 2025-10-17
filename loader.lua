-- loader.lua
local base = "https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/"

local files = {
    "esp.lua",
    "ui.lua",
    "phoenix.lua"
}

for _, file in ipairs(files) do
    loadstring(game:HttpGet(base .. file))()
end
