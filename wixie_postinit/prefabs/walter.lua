local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local NO_RIGHTCLICK_TAGS = {"woby", "customwobytag", "shadow", "shadowcreature", "shadowminion", "heavy", "heavyobject", "player"}
local function RightClickPicker(inst, target, pos)
    local notexamine
    if target then
        local actions = inst.components.playeractionpicker:GetSceneActions(target, true)
        --CollectActions("SCENE")

        --inst:CollectActions("SCENE", target, inst, actions, right)

        for i, v in pairs(actions) do
            if target:IsActionValid(v.action, true) or v.action.rmb or v.action ~= ACTIONS.WALKTO and v.action ~= ACTIONS.LOOKAT and v.action ~= ACTIONS.PICKUP and v.action ~= ACTIONS.DIG and v.action ~= ACTIONS.HARVEST and v.action ~= ACTIONS.PICK and v.action ~= ACTIONS.FEED then
                notexamine = true
            end
        end
    end

    local validtargetaction
    local useitem = inst.replica.inventory:GetActiveItem()
    local equipitem = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipitem and equipitem:IsValid() then
        if target then
            local equipactions = inst.components.playeractionpicker:GetEquippedItemActions(target, equipitem, true)
            for i, v in pairs(equipactions) do
                validtargetaction = v
            end
        end
    end

    return target and target ~= inst and (not inst:GetCurrentPlatform() and not target:HasTag("outofreach")
        and (TUNING.DSTU.ISLAND_ADVENTURES or target:IsOnPassablePoint()) or target:HasTag("_combat"))
        and not target:HasAnyTag(NO_RIGHTCLICK_TAGS) and not validtargetaction and not notexamine and not useitem
        and inst.components.playeractionpicker:SortActionList({ACTIONS.WOBY_COMMAND}, target, nil) or nil, true
end

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and not useitem and not TheWorld.Map:IsGroundTargetBlocked(pos) then
        local rider = inst.replica.rider
        --[[local walter = TheSim:FindEntities(pos.x, 0, pos.z, 3, {"pinetreepioneer"})
        for i, v in pairs(walter) do
            if v and v == inst then
                if rider and rider:IsRiding() then
                    return {ACTIONS.WOBY_OPEN}
                else
                    return {ACTIONS.WOBY_HERE}
                end
            end
        end]]
        if not rider or not rider:IsRiding() then
            local walter = TheSim:FindEntities(pos.x, 0, pos.z, 3, {"pinetreepioneer"})
            for i, v in pairs(walter) do
                if v ~= nil and v == inst then
                    return {ACTIONS.WOBY_HERE}
                end
            end
        end
        return {ACTIONS.WOBY_STAY}
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker then
        inst.components.playeractionpicker.rightclickoverride = RightClickPicker
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

local function OnKilledOther(inst, data)
    if data and data.victim and data.victim.prefab then
        local naughtiness = NAUGHTY_VALUE[data.victim.prefab]
        if naughtiness ~= nil then
            local naughty_val = FunctionOrValue(naughtiness, inst, data)
            local naughtyresolve = naughty_val * (data.stackmult or 1)
            inst.components.sanity:DoDelta(-naughtyresolve)
        end
    end
end

local function Mounted(inst)
    if inst.replica.rider and inst.replica.rider:IsRiding() and inst.replica.rider:GetMount() and inst.replica.rider:GetMount():HasTag("woby")
        and not inst:HasTag("dismounting") and not TheWorld.state.isnight then
        inst:PushEvent("playwobymusic")
    end
end

env.modimport("init/init_character_changes/skilltree_walter") -- Import New Walter Tree

local function WalterFunctions(inst)
    if inst._update_tree_sanity_task then
        inst._update_tree_sanity_task:Cancel()
        inst._update_tree_sanity_task = nil
    end

    inst.starting_inventory = {"walterhat", "meatrack_hat", "meat", "monstermeat"}

    if inst.components.foodaffinity then
        local foodaffinities = {
            ["meat_dried"] = TUNING.AFFINITY_15_CALORIES_MED,
            ["fishmeat_dried"] = TUNING.AFFINITY_15_CALORIES_MED,
            ["jellyjerky"] = TUNING.AFFINITY_15_CALORIES_MED,
            ["smallmeat_dried"] = TUNING.AFFINITY_15_CALORIES_SMALL,
            ["smallfishmeat_dried"] = TUNING.AFFINITY_15_CALORIES_SMALL,
            ["seaweed_dried"] = TUNING.AFFINITY_15_CALORIES_SMALL,
            ["kelp_dried"] = TUNING.AFFINITY_15_CALORIES_TINY
        }
        for name, gain in pairs(foodaffinities) do
            inst.components.foodaffinity:AddPrefabAffinity(name, gain)
        end
    end

    --[[if inst.components.builder then
        local unlockrecipes = {"trap", "birdtrap", "fishingrod", "healingsalve", "bandage", "floral_bandage", "um_rimeweed_icepack", "tillweedsalve", "rope", "papyrus"}
        for _, recipe in pairs(unlockrecipes) do
            inst.components.builder:UnlockRecipe(recipe)
        end
    end]]

    if inst.components.sanity.custom_rate_fn then
        local _OldRate = inst.components.sanity.custom_rate_fn
        local function NewCustom(inst, dt)
            local wobystarving = inst.woby and inst.woby.wobystarving and -0.1 or 0
            
            local rate = _OldRate(inst, dt)

            return rate + wobystarving
        end
        inst.components.sanity.custom_rate_fn = NewCustom
    end

    --inst:ListenForEvent("killed", OnKilledOther)
end

env.AddPrefabPostInit("walter", function(inst) 
    inst:AddTag("polite")
    inst:RemoveTag("pebblemaker")
    inst:RemoveTag("slingshot_sharpshooter")
    inst:RemoveTag("allow_special_point_action_on_impassable")

    inst:ListenForEvent("setowner", OnSetOwner)

    inst:DoPeriodicTask(2, Mounted)

    if not TheWorld.ismastersim then
        return
    end

    WalterFunctions(inst)
end)

local function new_bonus_damage_via_allergy(inst, target, damage, weapon)
    local targetinventory = target.components.inventory
    local hasbeearmor
    if targetinventory then
        local helm = targetinventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        local helmarmor = helm and helm.components.armor
        if helmarmor and helmarmor.tags then
            for i, tag in ipairs(helmarmor.tags) do
                if tag == "bee" then
                    hasbeearmor = true
                    break
                end
            end
        end
    end
    return (target:HasTag("allergictobees") and (hasbeearmor and TUNING.DSTU.BEE_ALLERGY_PROTECTION_EXTRADAMAGE or TUNING.BEE_ALLERGY_EXTRADAMAGE)) or 0
end

local bonus_dmg_via_allergy_prefablist = {"bee", "killerbee", "beequeen", "beeguard"}
for _, bee in pairs(bonus_dmg_via_allergy_prefablist) do
    env.AddPrefabPostInit(bee, function(inst)
        if inst.components.combat then
            inst.components.combat.bonusdamagefn = new_bonus_damage_via_allergy
        end
    end)
end

env.AddPrefabPostInit("bandage_butterflywings", function(inst)    
    if inst.components.healer ~= nil and inst.components.healer.health ~= nil then
        local old_health = inst.components.healer.health
        inst.components.healer:SetHealthAmount(old_health / 3)
    end
end)