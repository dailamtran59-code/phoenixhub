local UTILS = {}

local HttpService = game:GetService("HttpService")
local ConfigFileName = "PhoenixMenuConfig.json"
local canWrite = (type(writefile) == "function")

function UTILS.saveConfig(Config)
    if canWrite then
        local success, err = pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(Config))
        end)
        return success, err
    else
        return false, "writefile not available"
    end
end

function UTILS.loadConfig()
    if canWrite and isfile and readfile and isfile(ConfigFileName) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return nil
end

return UTILS
