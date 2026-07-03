local UMCommonFns = {}
UMCommonFns.GHOSTLIKE_TAGS = {"ghost", "playerghost", "shadow", "shadowcreature", "nightmarecreature", "shadowminion", "shadowthrall", "shadowchesspiece", "brightmare", "brightmareboss"}

UMCommonFns.Say = function(inst, string)
    local talker = not inst:HasTag("mime") and inst.components.talker
    if talker then talker:Say(string) end
end

UMCommonFns.RestartTimer = function(inst, data)
    local timer = inst.components.timer
    if not (timer and data) then return end
    local name, time, paused, initialtime_override = data.name, data.time, data.paused, data.initialtime_override
    if timer:TimerExists(name) then timer:StopTimer(name) end
    if time then timer:StartTimer(name, time, paused, initialtime_override) end
end

UMCommonFns.StartRechargeableCooldown = function(inst, data)
    if not data then return end
    local cooldown = data.cooldown or 5
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local owner = inst.components.inventoryitem.owner
    for i, v in pairs(TheSim:FindEntities(x1, y1, z1, 8, data.tags or {})) do
        if v ~= inst then
            local vowner = v.components.inventoryitem:GetGrandOwner()
            if vowner and (vowner == owner or not vowner:HasTag("player")) or not vowner then
                v.components.rechargeable:Discharge(cooldown)
            end
        end
    end
    inst.components.rechargeable:Discharge(cooldown)
end

UMCommonFns.KNOCKBACK_CANT_TAGS = {"fat_gang", "foodknockbackimmune", "heavybody"}
UMCommonFns.KNOCKBACK_ARMOR_CANT_TAGS = {"heavyarmor", "knockback_protection"}
UMCommonFns.ShouldKnockback = function(inst)
    local inventory = inst.components.inventory
    local bodyslot = inventory and inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    return not inst:HasAnyTag(UMCommonFns.KNOCKBACK_CANT_TAGS) and not (inst.sg and inst.sg:HasStateTag("shell")) and not (inst.components.rider and inst.components.rider:IsRiding())
        and (not bodyslot or not bodyslot:HasAnyTag(UMCommonFns.KNOCKBACK_ARMOR_CANT_TAGS))
end

UMCommonFns.IsAlly_GetLeader = function(inst)
    local follower = inst.replica.follower
    return follower and follower:GetLeader()
end

UMCommonFns.IsAlly = function(inst, guy, tags) -- Used for UMIsAlly on certain creatures.
    local guy_combat = guy.replica.combat
    if not (tags and guy_combat) or not (inst.replica.combat:GetTarget() ~= guy and guy_combat and guy_combat:GetTarget() ~= inst) then return false end
    local myleader, guyleader = UMCommonFns.IsAlly_GetLeader(inst), UMCommonFns.IsAlly_GetLeader(guy)
    local myleader_leader, guyleader_leader = myleader and UMCommonFns.IsAlly_GetLeader(myleader), guyleader and UMCommonFns.IsAlly_GetLeader(guyleader)
    if myleader and myleader.isplayer or guyleader and guyleader.isplayer then return false end
    if myleader_leader and myleader_leader.isplayer or guyleader_leader and guyleader_leader.isplayer then return false end
    return guy:HasAnyTag(tags)
end

UMCommonFns.IsNotFriendly = function(attacker, target) -- Is the target an ally or my leader's ally?
    if not (attacker and attacker:IsValid()) or not target.components.health then return true end
    local attackercombat = attacker and attacker.components.combat
    local leader = attacker and attacker.components.follower and attacker.components.follower:GetLeader()
    local leadercombat = leader and leader.components.combat
    return attackercombat and (attackercombat.target == target or attackercombat:CanTarget(target) and not attackercombat:IsAlly(target)
        and (not leader or leadercombat and leadercombat:CanTarget(target) and not leadercombat:IsAlly(target)))
end

UMCommonFns.VetcurseUnequip = function(inst, owner, slot)
    if owner:HasTag("player") then
        if not owner:HasTag("vetcurse") and not owner.components.inventory.isloading then
            inst:DoTaskInTime(0, function(inst)
                --local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
                local tool = owner and owner.components.inventory:GetEquippedItem(slot)
                if tool and owner then
                    owner.components.inventory:Unequip(slot)
                    owner.components.inventory:DropItem(tool)
                    owner.components.inventory:GiveItem(inst)
                    UMCommonFns.Say(owner, GetString(owner, "CURSED_ITEM_EQUIP"))
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")
                    if owner.sg then owner.sg:GoToState("hit") end
                end
            end)
            return true
        end
    elseif not owner:HasTag("equipmentmodel") then
        local leader = owner.components.follower and owner.components.follower:GetLeader()
        if not leader or not leader:HasTag("vetcurse") then
            inst:DoTaskInTime(0, function(inst)
                if owner.components.inventory and inst:IsValid() and inst.components.inventoryitem and inst.components.inventoryitem.owner == owner then
                    owner.components.inventory:DropItem(inst)
                end
            end)
            return true
        end
    end
end

local ignoredactions = {ACTIONS.LOOKAT, ACTIONS.WALKTO}
UMCommonFns.HasRightClickAction = function(inst, doer, pos, target)
    if inst.um_checkingactions then return true end
    inst.um_checkingactions = true
    local _, rmb
    if doer.components.playeractionpicker then
        _, rmb = doer.components.playeractionpicker:DoGetMouseActions(pos, target)
    end
    inst.um_checkingactions = nil
    return rmb and not table.contains(ignoredactions, rmb.action)
end

-- Unified megaflare timer reduction used by all seasonal boss spawners
UMCommonFns.MegaFlareTimerReduction = function(time)
    if time > 480 * 8 then
        return time - 480 * math.random(4, 6)
    elseif time > 480 * 4 then
        return time - 480 * math.random(2, 4)
    elseif time > 480 * 2.5 then
        return time - 480 * 2
    else
        return time - 240
    end
end

return UMCommonFns