local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function OnInventory(inst, owner)
    if inst.components.herdmember and inst.components.herdmember.enabled then
        inst.components.herdmember:Enable(false)
    end
end

local function OnDropped(inst)
    if inst.components.herdmember and not inst.components.herdmember.enabled then
        inst.components.herdmember:Enable(true)
    end
    if inst.tailGrowthPending then
        inst.tailGrowthPending = nil
        inst.AnimState:Show("tail")
        inst.hasTail = true
    end
end

local function SetGekkoTrapData(inst)
    local t = inst.components.timer:GetTimeLeft("growTail")
    return t and {growTail = t} or nil
end

local function RestoreGekkoFromTrap(inst, data)
    if data and data.growTail then
        if inst.components.health and inst.components.health:IsDead() then return end
        inst.hasTail = false
        inst.AnimState:Hide("tail")
        local t = inst.components.timer:GetTimeLeft("growTail")
        if t and t < data.growTail then
            inst.components.timer:SetTimeLeft("growTail", data.growTail)
            return
        end
        inst.components.timer:StartTimer("growTail", data.growTail, inst:IsInLimbo())
    end
end

env.AddPrefabPostInit("grassgekko", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("canbetrapped")
    inst:AddTag("animal")
    inst:AddTag("donotautopick")
    inst.components.lootdropper:AddChanceLoot("dug_grass",1.00)
    inst:AddComponent("inventoryitem")

    inst.components.inventoryitem.atlasname = "images/inventoryimages/grassgekko.xml"
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem:SetSinks(true)

    MakeFeedableSmallLivestock(inst, TUNING.RABBIT_PERISH_TIME, OnInventory, OnDropped)

    inst.settrapdata = SetGekkoTrapData
    inst.restoredatafromtrap = RestoreGekkoFromTrap
end)