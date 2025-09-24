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

    local lootdropper = inst.components.lootdropper
    if lootdropper then
        lootdropper:AddChanceLoot("dug_grass", 1.00)
    end

    local health = inst.components.health
    if health then
        health.murdersound = "dontstarve/creatures/together/grass_gekko/hit"
    end
    inst.incineratesound = "dontstarve/creatures/together/grass_gekko/death"
    

    local inventoryitem = inst.components.inventoryitem or inst:AddComponent("inventoryitem")
    if inventoryitem then
        --inventoryitem.atlasname = "images/inventoryimages/grassgekko.xml"
        inventoryitem.nobounce = true
        inventoryitem.canbepickedup = false
        inventoryitem.canbepickedupalive = true
        inventoryitem:SetSinks(true)
    end

    MakeFeedableSmallLivestock(inst, TUNING.RABBIT_PERISH_TIME, OnInventory, OnDropped)

    inst.settrapdata = SetGekkoTrapData
    inst.restoredatafromtrap = RestoreGekkoFromTrap
end

env.AddPrefabPostInit("world", function(inst) -- Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not TheWorld.ismastersim then return inst end
    local _ontimerdone = UpvalueHacker.GetUpvalue(Prefabs.grassgekko.fn, "ontimerdone")
    if _ontimerdone then
        local function ontimerdone(inst, data, ...)
            if data.name == "growTail" and inst:IsInLimbo() then
               PlayGrowTailSound(inst)
            end
            return _ontimerdone(inst, data, ...)
        end
        UpvalueHacker.SetUpvalue(Prefabs.grassgekko.fn, ontimerdone, "ontimerdone")
    end
end)

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