-- safe_loader.lua
local base = "https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/modules/"
local mainRaw = "https://raw.githubusercontent.com/dailamtran59-code/phoenixhub/main/PhoenixMain.lua"

local modulesList = {
    "CONFIG.lua",
    "UTILS.lua",
    "UI.lua",
    "ESP.lua",
    "AIMBOT.lua",
    "MOVEMENT.lua",
}

local loaded = {}

local function safeLoadUrl(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok then return false, ("HttpGet failed: %s"):format(tostring(res)) end
    if not res or res == "" then return false, "Empty response" end
    local fn, err = loadstring(res)
    if not fn then return false, ("loadstring parse error: %s"):format(tostring(err)) end
    local ok2, ret = pcall(fn)
    if not ok2 then return false, ("runtime error executing chunk: %s"):format(tostring(ret)) end
    return true, ret
end

for _,f in ipairs(modulesList) do
    local url = base..f
    local ok, ret = safeLoadUrl(url)
    if ok then
        print("[loader] loaded module:", f)
        loaded[f] = ret
    else
        warn("[loader] failed to load", f, "->", ret)
        loaded[f] = nil
    end
end

-- ensure stub for critical modules if missing
local function makeStub(name)
    local s = {}
    if name:lower():find("esp") then
        s.updateAll = function() end
        s.setupEnemyESP = function() end
    elseif name:lower():find("aim") then
        s.getClosestTarget = function() return nil end
        s.aimAt = function() end
    end
    return s
end

if not loaded["CONFIG.lua"] then
    warn("CONFIG missing -> aborting because config is required")
    return
end

-- load main
local ok, ret = safeLoadUrl(mainRaw)
if not ok then
    error("Failed to load PhoenixMain.lua: "..tostring(ret))
end
print("[loader] PhoenixMain loaded, starting...")

-- if main expects modules via global table, expose loaded
_G.PhoenixModules = loaded

-- if PhoenixMain returns a function start(), call it
if type(ret) == "table" and type(ret.start) == "function" then
    local success, err = pcall(ret.start, loaded)
    if not success then warn("PhoenixMain.start error:", err) end
elseif type(ret) == "function" then
    local success, err = pcall(ret, loaded)
    if not success then warn("PhoenixMain call error:", err) end
else
    print("PhoenixMain returned non-callable; loader finished.")
end
