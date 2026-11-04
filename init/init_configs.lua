local env = env
local _G = GLOBAL
GLOBAL.setfenv(1, GLOBAL)

local ServerConfigs = {}
local ClientConfigs = {}

function BuildConfigs()
    local config, _ = KnownModIndex:GetModConfigurationOptions_Internal(env.modname, false)
    local client_config, _ = KnownModIndex:GetModConfigurationOptions_Internal(env.modname, true)

    for i, data in pairs(config) do
        if type(data) == "table" then
            local config_name = string.gsub(data.name, " ", "_")

            --i hate lua i hate lua i hate lua
            --this took 1h of my fucking time
            --whycan't it be regex like a normal language
            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ServerConfigs[config_name] = env.GetModConfigData(data.name)
        elseif type(data) ~= "table" then
            local config_name = string.gsub(i, " ", "_")

            --i hate lua i hate lua i hate lua
            --this took 1h of my fucking time
            --whycan't it be regex like a normal language
            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ServerConfigs[config_name] = env.GetModConfigData(i)
        end
    end

    for i, data in pairs(client_config) do
        if data and not string.match(data.name, "section") and data.client then
            local config_name = string.gsub(data.name, " ", "_")

            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ClientConfigs[config_name] = env.GetModConfigData(data.name, true)
        end
    end
end

BuildConfigs()

rawset(_G, "UM_CLIENT_CONFIG", ClientConfigs)
rawset(_G, "UM_CONFIG", ServerConfigs)
rawset(env, "UM_CLIENT_CONFIG", ClientConfigs)
rawset(env, "UM_CONFIG", ServerConfigs)

--I'm not sure how efficient lua's GC is so i'll manually reset these.
ServerConfigs = nil
ClientConfigs = nil