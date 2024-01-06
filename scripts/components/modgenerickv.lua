--[[
    This file belongs to monti1811's "Configurable Skilltrees" mod; adapted for Uncompromising Mode. All credits go to Monti.
]]

local ModGenericKV = Class(function(self)
    self.kvs = {}
end)

function ModGenericKV:SetValue(userid, key, value)
    value = value or 1
    if not self.kvs[userid] then
        self.kvs[userid] = {}
    end
    self.kvs[userid][key] = value
end

function ModGenericKV:GetValue(userid, key)
    return self.kvs[userid] and self.kvs[userid][key] or nil
end

function ModGenericKV:IncreaseValue(userid, key, value, max)
    value = value or 1
    if not self.kvs[userid] then
        self.kvs[userid] = {}
    end
    self.kvs[userid][key] = math.min((self.kvs[userid][key] or 0) + value, max or math.huge)
end

function ModGenericKV:SendToShard(userid, shard_id)
    if self.kvs[userid] then
        for key, value in pairs(self.kvs[userid]) do
            --dprint("Sending to shard", key, value ~= 1 and value or nil)
            SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "SendModdedGenericKVToShard"), shard_id, userid, key, value ~= 1 and value or nil)
        end
    end
end

function ModGenericKV:SendToClient(userid)
    if self.kvs[userid] then
        for key, value in pairs(self.kvs[userid]) do
            --dprint("Sending to client", key, value ~= 1 and value or nil)
            SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "SetModdedGenericKV"), userid, key, value ~= 1 and value or nil)
        end
    end
end

function ModGenericKV:OnLoad(data)
    if data then
        self.kvs = data.kvs or {}
    end
end

function ModGenericKV:OnSave()
    return {
        kvs = self.kvs,
    }
end


return ModGenericKV