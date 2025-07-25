local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")

env.AddPrefabPostInit("snowman", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    local workable = inst.components.workable
    if workable and workable.onwork then
        local _DoBreakApart = UpvalueHacker.GetUpvalue(workable.onwork, "DoBreakApart")
        if _DoBreakApart then
            local function DoBreakApart(inst, isdestroyed)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("snowball_shatter_fx").Transform:SetPosition(x, y, z)
                inst:Remove()
            end
            UpvalueHacker.SetUpvalue(workable.onwork, DoBreakApart, "DoBreakApart")
        end
    end
end)