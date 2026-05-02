local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local frozenstates = {"frozen", "thaw", "thaw_break"}
local function OnUnfreeze(inst)
    local state = inst.sg and inst.sg.currentstate.name
    if inst.components.health and not inst.components.health:IsDead() and state and not table.contains(frozenstates, state) then
        inst.um_frozendeath = true
        inst.components.health:Kill() -- Doing this for now since we're never supposed to exit being frozen.
    end
end

local function ondeath(inst)
    local slime = SpawnPrefab("lavaeslime")
    if slime ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        slime.Transform:SetPosition(x, y, z)
    end
end

env.AddPrefabPostInit("lavae", function(inst)
    inst:AddTag("insect")
    inst:AddTag("um_magmatic_defense")

    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("unfreeze", OnUnfreeze)
    inst:ListenForEvent("death", ondeath)
end)