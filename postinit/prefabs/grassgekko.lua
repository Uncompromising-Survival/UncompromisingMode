local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
-----------------------------------------------------------------
local function CLIENT_PlayGrowTailSound(inst)
    local parent = inst.entity:GetParent()
    local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
    if container ~= nil and container:IsOpenedBy(ThePlayer) then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/creatures/together/grass_gekko/tail_regrow")
    end
end

local function PlayGrowTailSound(inst)
    inst.playgrowtailsound:push()
    --Dedicated server does not need to trigger sfx
    if not TheNet:IsDedicated() then
        CLIENT_PlayGrowTailSound(inst)
    end
end

local function GrassGekkoFunctions(inst)
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
            inst.AnimState:Hide("tail")
            inst.hasTail = false
            local t = inst.components.timer:GetTimeLeft("growTail")
            if t and t < data.growTail then
                inst.components.timer:SetTimeLeft("growTail", data.growTail)
                return
            end
            inst.components.timer:StartTimer("growTail", data.growTail, inst:IsInLimbo())
        end
    end

    if inst.components.lootdropper then
        inst.components.lootdropper:AddChanceLoot("dug_grass", 1.00)
    end

    if inst.components.health then
        inst.components.health.murdersound = "dontstarve/creatures/together/grass_gekko/hit"
    end
    inst.incineratesound = "dontstarve/creatures/together/grass_gekko/death"
    
    if not inst.components.inventoryitem then
        local inventoryitem = inst:AddComponent("inventoryitem")
        --inventoryitem.atlasname = "images/inventoryimages/grassgekko.xml"
        inventoryitem.nobounce = true
        inventoryitem.canbepickedup = false
        inventoryitem.canbepickedupalive = true
        inventoryitem:SetSinks(true)
    end

    MakeFeedableSmallLivestock(inst, TUNING.RABBIT_PERISH_TIME, OnInventory, OnDropped)
    
    local Oldontimerdone = UpvalueHacker.GetUpvalue(Prefabs.grassgekko.fn, "ontimerdone") or function() end
    local function ontimerdone(inst, data, ...)
        if data.name == "growTail" and inst:IsInLimbo() then
           PlayGrowTailSound(inst)
        end
        Oldontimerdone(inst, data, ...)
    end
    inst:RemoveEventCallback("timerdone", Oldontimerdone)
    UpvalueHacker.SetUpvalue(Prefabs.grassgekko.fn, ontimerdone, "ontimerdone")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.settrapdata = SetGekkoTrapData
    inst.restoredatafromtrap = RestoreGekkoFromTrap
end

env.AddPrefabPostInit("grassgekko", function(inst)
    inst:AddTag("canbetrapped")
    inst.playgrowtailsound = net_event(inst.GUID, "grassgekko.playgrowtailsound")

    if not TheWorld.ismastersim then
        --delayed because we don't want any old events
        inst:DoTaskInTime(0, inst.ListenForEvent, "grassgekko.playgrowtailsound", CLIENT_PlayGrowTailSound)
        return inst
    end

    GrassGekkoFunctions(inst)
end)