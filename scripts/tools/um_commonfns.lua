local UMCommonFns = {}
UMCommonFns.GHOSTLIKE_TAGS = {"ghost", "playerghost", "shadow", "shadowcreature", "nightmarecreature", "shadowminion", "shadowthrall", "shadowchesspiece", "brightmare", "brightmareboss"}

UMCommonFns.Say = function(inst, string)
    local talker = inst.components.talker
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
    local attackercombat = attacker and attacker:IsValid() and attacker.components.combat
    if not attackercombat or not target.components.health then return true end
    local leader = attacker and attacker.components.follower and attacker.components.follower:GetLeader()
    local leadercombat = leader and leader.components.combat
    return attackercombat and (attackercombat.target == target or attackercombat:CanTarget(target) and not attackercombat:IsAlly(target)
        and (not leader or leadercombat and leadercombat:CanTarget(target) and not leadercombat:IsAlly(target)))
end

UMCommonFns.IsRangedWeapon = function(ent)
    if UPDATE_CHECK and IsRangedWeapon then return IsRangedWeapon(ent) end
    return ent ~= nil and
        (    ent.components.projectile ~= nil or
            (ent.components.weapon ~= nil and ent.components.weapon:CanRangedAttack()) or
            ent:HasTag("pseudorangedweapon")
        )
end

local SpDamageUtil = require("components/spdamageutil")
local CANT_EXPLODE_TAGS = { "INLIMBO", "notarget" }
UMCommonFns.DoAOEExplosion = function(inst, um_explodeparams) -- Modified copy of explosive:OnBurnt().
    if not um_explodeparams then return end
    if not um_explodeparams.skip_camera_flash then
        for i, v in ipairs(AllPlayers) do
            local distSq = v:GetDistanceSqToInst(inst)
            local k = math.max(0, math.min(1, distSq / 400))
            local intensity = k * 0.75 * (k - 2) + 0.75 --easing.outQuad(k, 1, -1, 1)
            if intensity > 0 then
                v:ScreenFlash(intensity)
                v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 2)
            end
        end
    end

    if um_explodeparams.onexplodefn_pre then
        um_explodeparams.onexplodefn_pre(inst)
    end

    local stacksize = inst.components.stackable and inst.components.stackable:StackSize() or 1
    local totaldamage = um_explodeparams.explosivedamage * stacksize

    local x, y, z = inst.Transform:GetWorldPosition()

    local world = TheWorld
    if um_explodeparams.damagedocks and world.components.dockmanager then
        world.components.dockmanager:DamageDockAtPoint(x, y, z, totaldamage)
    end

    local attacker = um_explodeparams.attacker or um_explodeparams.pvpattacker

    local workablecount = TUNING.EXPLOSIVE_MAX_WORKABLE_INVENTORYITEMS
    local ents = TheSim:FindEntities(x, y, z, um_explodeparams.explosiverange, nil, CANT_EXPLODE_TAGS, um_explodeparams.oneoftags)
    for i, v in ipairs(ents) do
        if v ~= inst and not v:IsInLimbo() and v:IsValid() and (not um_explodeparams.pvpattacker or v == um_explodeparams.pvpattacker or not v:HasTag("player")) then
            local damagetypemult = inst.components.damagetypebonus and self.inst.components.damagetypebonus:GetBonus(v) or 1

            if v.components.workable and v.components.workable:CanBeWorked() then
                -- NOTES(JBK): Stackable inventory items can be placed down 1 by 1 making this a convenience to players to not have to drop them down 1 by 1 first for maximum potential output.
                local buildingdamage = FunctionOrValue(um_explodeparams.buildingdamage, inst, v)
                if buildingdamage then
                    local workdamage = buildingdamage * stacksize * damagetypemult
                    local dowork = true
                    if v.components.inventoryitem then
                        if workablecount > 0 then
                            workablecount = workablecount - 1
                            workdamage = workdamage * (v.components.stackable and v.components.stackable:StackSize() or 1)
                        else
                            dowork = false
                        end
                    end
                    if dowork then
                        v.components.workable:WorkedBy(inst, workdamage)
                    end
                end
            end

            --Recheck valid after work
            if not v:IsInLimbo() and v:IsValid() then
                if um_explodeparams.lightonexplode and not v.components.fueled
                    and v.components.burnable and not v.components.burnable:IsBurning() and not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end

                if not (v.components.health and v.components.health:IsDead()) and
                    v.components.combat and v.components.combat:CanBeAttacked()
                then
                    local dmg = totaldamage * damagetypemult
                    if not um_explodeparams.ignoreexplosiveresist and v.components.explosiveresist ~= nil then
                        dmg = dmg * (1 - v.components.explosiveresist:GetResistance())
                        v.components.explosiveresist:OnExplosiveDamage(dmg, inst)
                    end

                    local spdmg = SpDamageUtil.CollectSpDamage(inst)
                    if spdmg and damagetypemult ~= 1 then
                        spdmg = SpDamageUtil.ApplyMult(spdmg, damagetypemult)
                    end

                    --V2C: still passing self.inst instead of attacker here, so we don't
                    --     use attacker for calculating damage mods.
                    v.components.combat:GetAttacked(inst, dmg, nil, nil, spdmg) -- NOTES(JBK): The component combat might remove itself in the GetAttacked callback!

                    if attacker and v.components.combat and not (v.components.health and v.components.health:IsDead()) and v:IsValid() then
                        if attacker:IsValid() then
                            v.components.combat:SuggestTarget(attacker)
                        else
                            attacker = nil
                        end
                    end
                end

                v:PushEvent("explosion", { explosive = inst })
            end
        end
    end

    if um_explodeparams.onexplodefn_pst then
        um_explodeparams.onexplodefn_pst(inst)
    end

    for i = 1, stacksize do
        world:PushEvent("explosion", { damage = um_explodeparams.explosivedamage })
    end

    if inst.components.health ~= nil then
        -- NOTES(JBK): Make sure to keep the events fired up to date with the health component.
        world:PushEvent("entity_death", { inst = inst, explosive = true, })
        inst:PushEvent("death")
    end

    inst:Remove()
end

UMCommonFns.VetcurseUnequip = function(inst, owner, slot)
    if owner.components.inventory.isloading then return end
    if owner:HasTag("player") then
        if not owner:HasTag("vetcurse") then
            inst:DoTaskInTime(0, function(inst)
                --local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
                local inventory = owner and owner.components.inventory
                local tool = inventory and inventory:GetEquippedItem(slot)
                if tool then
                    inventory:Unequip(slot)
                    inventory:DropItem(tool)
                    inventory:GiveItem(inst)
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
                if inst.components.inventoryitem and inst.components.inventoryitem.owner == owner and owner.components.inventory then
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

UMCommonFns.DefaultCanCastOnTarget = function(inst, doer, pos, target, actioncount)
    return not actioncount
end

UMCommonFns.SpawnHoundLightning = function(inst, data)
    if not data then return end
    local lightning = SpawnPrefab("hound_lightning")
    local pos = data.pos
    if pos then lightning.Transform:SetPosition(pos.x, 0, pos.z) end
    lightning.owner = data.owner or inst
    if data.canttags then lightning.NoTags = JoinArrays(lightning.NoTags, data.canttags) end
    if data.delay then lightning.Delay = data.delay end
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