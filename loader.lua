-- loader.lua (dùng với executor như Synapse)
local base = "https://raw.githubusercontent.com/<user>/<repo>/main/"

local files = {
    "modules/CONFIG.lua",
    "modules/UTILS.lua",
    "modules/UI.lua",
    "modules/ESP.lua",
    "modules/AIMBOT.lua",
    "modules/MOVEMENT.lua",
    "PhoenixMain.lua",
}

local loaded = {}

for _,f in ipairs(files) do
    local url = base .. f
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then
        warn("Không tải được: ".. url)
    else
        -- set chunk environment so require() inside modules can work if you implement simple require shim
        local fn, err = loadstring(res)
        if not fn then
            warn("Lỗi parse:", err)
        else
            -- run the module and capture returned value in loaded table keyed by filename
            local ret = fn()
            loaded[f] = ret
        end
    end
end

-- Nếu bạn muốn hỗ trợ require giữa các module khi chạy bằng loader,
-- bạn có thể implement một require shim, ví dụ:
local function shimRequire(path)
    -- map "modules/CONFIG.lua" -> loaded[path]
    return loaded[path]
end

-- cuối cùng gọi main (nếu main dùng returned table)
if loaded["PhoenixMain.lua"] and type(loaded["PhoenixMain.lua"].start) == "function" then
    loaded["PhoenixMain.lua"].start(shimRequire)
end
