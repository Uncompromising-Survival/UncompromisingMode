local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMUpvalueHacker = require("tools/um_upvaluehacker")

env.AddSimPostInit(function()
    local _DoBreakApart = UMUpvalueHacker.TryGetUpvalue(Prefabs.snowman.fn, "OnWork", "DoBreakApart")
    if _DoBreakApart then
        local function DoBreakApart(inst, isdestroyed)
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("snowball_shatter_fx").Transform:SetPosition(x, y, z)
            inst:Remove()
        end
        UMUpvalueHacker.SetUpvalue(Prefabs.snowman.fn, DoBreakApart, "OnWork", "DoBreakApart")
    end
end)

--[[env.AddPrefabPostInit("snowman", function(inst)
    if not TheWorld.ismastersim then return end
end)]]