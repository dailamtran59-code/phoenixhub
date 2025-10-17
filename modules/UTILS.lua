local HttpService = game:GetService("HttpService")
local M = {}
local canWrite = (type(writefile) == "function")
local cfgName = "PhoenixMenuConfig.json"

M.colorByName = {
    purple = Color3.fromRGB(140,58,200), red = Color3.fromRGB(255,0,0), blue = Color3.fromRGB(0,120,255),
    green = Color3.fromRGB(0,200,120), yellow = Color3.fromRGB(255,230,0), white = Color3.fromRGB(255,255,255)
}

function M.saveConfig(tbl)
    if not canWrite then return false, "writefile not available" end
    local ok, err = pcall(function() writefile(cfgName, HttpService:JSONEncode(tbl)) end)
    return ok, err
end

function M.loadConfig()
    if not canWrite or type(isfile) ~= "function" then return false end
    if not isfile(cfgName) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgName)) end)
    if ok and type(data) == "table" then return data end
    return false
end

return M

