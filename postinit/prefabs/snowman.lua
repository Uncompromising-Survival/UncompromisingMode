local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")

env.AddPrefabPostInit("world", function(inst) -- Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not TheWorld.ismastersim then return inst end
    local _DoBreakApart = UpvalueHacker.GetUpvalue(Prefabs.snowman.fn, "OnWork", "DoBreakApart")
    if _DoBreakApart then
        local function DoBreakApart(inst, isdestroyed)
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("snowball_shatter_fx").Transform:SetPosition(x, y, z)
            inst:Remove()
        end
        UpvalueHacker.SetUpvalue(Prefabs.snowman.fn, DoBreakApart, "OnWork", "DoBreakApart")
    end
end)

--[[env.AddPrefabPostInit("snowman", function(inst)
    if not TheWorld.ismastersim then return inst end
end)]]