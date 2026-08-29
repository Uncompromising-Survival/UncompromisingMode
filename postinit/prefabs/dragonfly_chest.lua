local env = env
GLOBAL.setfenv(1, GLOBAL)

function HeatItems(inst)
    if inst.components.container == nil then
        return
    end

    for slot = 1, inst.components.container:GetNumSlots() do
        local item = inst.components.container:GetItemInSlot(slot)

        if item ~= nil then
            if item.components.temperature ~= nil then
                item.components.temperature:DoDelta(TUNING.DSTU.DFLYCHEST_HEATVALUE, true)
            end
        end
    end
end

env.AddPrefabPostInit("dragonflychest", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.heat_items = inst:DoPeriodicTask(TUNING.DSTU.DFLYCHEST_HEATPERIOD, HeatItems)
end)