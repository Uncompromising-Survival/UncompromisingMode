--This file is loaded BEFORE every other file, so it can be used both in worldgen and otherwise.

local ServerConfigs = {}
local ClientConfigs = {}

function BuildConfigs(modname)
    local config, _ = KnownModIndex:GetModConfigurationOptions_Internal(modname, false)
    local client_config, _ = KnownModIndex:GetModConfigurationOptions_Internal(modname, true)

    for i, data in pairs(config) do
        if type(data) == "table" and not data.client then
            local config_name = string.gsub(data.name, " ", "_")

            --i hate lua i hate lua i hate lua
            --this took 1h of my fucking time
            --whycan't it be regex like a normal language
            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ServerConfigs[config_name] = data.saved_server ~= nil and data.saved_server or data.saved ~= nil and data.saved or data.default
        elseif type(data) ~= "table" then --handling server configs on the client. Values are different on the client.
            local config_name = string.gsub(i, " ", "_")

            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ServerConfigs[config_name] = data
        end
    end

    for i, data in pairs(client_config) do
        if data and not string.match(data.name, "section") and data.client then
            local config_name = string.gsub(data.name, " ", "_")

            --i hate lua i hate lua i hate lua
            --this took 1h of my fucking time
            --whycan't it be regex like a normal language
            config_name = string.gsub(config_name, "^_", "")
            config_name = string.gsub(config_name, "_$", "")
            config_name = string.upper(string.gsub(config_name, "'", ""))

            ClientConfigs[config_name] = data.saved_client ~= nil and data.saved_client or data.saved ~= nil and data.saved or data.default
        end
    end
end

return {
    ServerConfigs = ServerConfigs,
    ClientConfigs = ClientConfigs,
    BuildConfigs = BuildConfigs
}
