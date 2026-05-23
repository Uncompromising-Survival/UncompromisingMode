local UMCommonFns = {}

UMCommonFns.Say = function(inst, string)
    local talker = not inst:HasTag("mime") and inst.components.talker
    if talker then talker:Say(string) end
end

UMCommonFns.GHOSTLIKE_TAGS = {"ghost", "playerghost", "shadow", "shadowcreature", "nightmarecreature", "shadowminion", "shadowthrall", "shadowchesspiece", "brightmare", "brightmareboss"}

UMCommonFns.KNOCKBACK_CANT_TAGS = {"fat_gang", "foodknockbackimmune", "heavybody"}
UMCommonFns.KNOCKBACK_ARMOR_CANT_TAGS = {"heavyarmor", "knockback_protection"}
UMCommonFns.ShouldKnockback = function(inst)
    local inventory = inst.components.inventory
    local bodyslot = inventory and inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    return not inst:HasAnyTag(UMCommonFns.KNOCKBACK_CANT_TAGS) and not (inst.sg and inst.sg:HasStateTag("shell")) and not (inst.components.rider and inst.components.rider:IsRiding())
        and (not bodyslot or not bodyslot:HasAnyTag(UMCommonFns.KNOCKBACK_ARMOR_CANT_TAGS))
end

UMCommonFns.IsAlly = function(inst, guy, tags) -- Used for UMIsAlly on certain creatures.
    local follower = inst.replica.follower
    local guy_combat, guy_follower = guy.replica.combat, guy.replica.follower
    if not (tags and guy_combat) or follower and follower:GetLeader() or guy_follower and guy_follower:GetLeader() then return false end
    return inst.replica.combat:GetTarget() ~= guy and guy.replica.combat:GetTarget() ~= inst and guy:HasAnyTag(tags)
end

UMCommonFns.IsNotFriendly = function(attacker, target) -- Is the target an ally or my leader's ally?
    if not target.components.health then return true end
    local attackercombat = attacker and attacker.components.combat
    local leader = attacker and attacker.components.follower and attacker.components.follower:GetLeader()
    local leadercombat = leader and leader.components.combat
    return attackercombat and (attackercombat.target == target or attackercombat:CanTarget(target) and not attackercombat:IsAlly(target)
        and (not leader or leadercombat and leadercombat:CanTarget(target) and not leadercombat:IsAlly(target)))
end

UMCommonFns.VetcurseUnequip = function(inst, owner, slot)
    if not owner:HasTag("vetcurse") and owner:HasTag("player") and not owner.components.inventory.isloading then
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
end

return UMCommonFns