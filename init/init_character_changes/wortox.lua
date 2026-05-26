require "behaviours/chaseandattack"

local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local TheNet = GLOBAL.TheNet

if TUNING.DSTU.WORTOXCHANGES then

    
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Soul Changes, will eventually remove them after these lower-effort enemies have more nuance to killing a lot of them ] ----
    --------------------------------------------------------------------------------------------------------------------------------
    if TUNING.DSTU.BUTTERFLYWINGS_NERF == "stat_nerf" then
        AddPrefabPostInitAny(function(inst)
            if not GLOBAL.TheWorld.ismastersim then
                return
            end
            if inst:HasTag("butterfly") then
                inst:AddTag("soulless")
            end
        end)
    end
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Soul Healing Changes ] ----------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------    

    local function ShouldHeal(inst, target)
        if target.um_should_soul_heal_fn then return target:um_should_soul_heal_fn(inst) end
        return target.components.health:IsHurt() and not target:HasTag("health_as_oldage") -- Wanda tag. --or (inst.soul_heal_player_efficient and target.components.health.penalty and target.components.health.penalty > 0)
    end
    
    local SOULPROTECTOR_TICK_TIME = .1
    local function UncompromisingSoulHeal(inst)
        local healtargets = {}
        local healtargetscount = 0
        local sanitytargets = {}
        local sanitytargetscount = 0
        local x, y, z = inst.Transform:GetWorldPosition()
        local rangesq = TUNING.WORTOX_SOULHEAL_RANGE + (inst.soul_heal_range_modifier or 0)
        rangesq = rangesq * rangesq
        for i, v in ipairs(GLOBAL.AllPlayers) do
            if not (v.components.health:IsDead() or v:HasTag("playerghost"))
                and v.entity:IsVisible() and v:GetDistanceSqToPoint(x, y, z) < rangesq then
                -- NOTES(JBK): If the target is hurt put them on the list to do heals.
                if ShouldHeal(inst, v) then
                    table.insert(healtargets, v)
                    healtargetscount = healtargetscount + 1
                end
                -- NOTES(JBK): If the target is another "soulstealer" give some sanity even when they did not drop the soul but not in overload state.
                if not inst.soul_bursting and v._souloverloadtask == nil and v.components.sanity and v:HasTag("soulstealer") then
                    table.insert(sanitytargets, v)
                    sanitytargetscount = sanitytargetscount + 1
                end
            end
        end
        if healtargetscount > 0 then
            -- Healing adjustments are absolute from the releaser but can be debuffed by the receiver.
            local loss_per_player = TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER
            if inst.soul_heal_player_efficient then
                loss_per_player = loss_per_player * TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_4_LOSS_PER_PLAYER_MULT
            end
            local amt = math.max(TUNING.WORTOX_SOULHEAL_MINIMUM_HEAL, (TUNING.HEALING_MED * (inst.soul_heal_premult or 1) - loss_per_player * (healtargetscount - 1)) * (inst.soul_heal_mult or 1))
            local amt_naughty = amt * .5
            local cooldowntime = inst.um_soul_echo_cooldown_time

            for i = 1, healtargetscount do
                local v = healtargets[i]
                local adjusted_amt = v.wortox_inclination == "naughty" and amt_naughty or amt
                
                adjusted_amt = adjusted_amt / 2
                
                if inst.soul_doburst then -- Soul bastion 1 allows you to bypass SHOT
                    v.components.health:DoDelta(adjusted_amt, nil, inst.prefab)
                else
                    v.components.debuffable:AddDebuff("healthregenbuff_vetcurse_soul", "healthregenbuff_vetcurse_soul", {duration = (adjusted_amt * .1)})
                end        
                if cooldowntime and not v:HasDebuff("wortox_soulecho_buff") then -- Soul Bastion 2 applies Lifted Spirits I buff for others.
                    v:AddDebuff("wortox_soulecho_buff", "wortox_soulecho_buff", {duration = cooldowntime})
                end
                
                if v.components.combat then -- Always show fx now that the heals do special targeting to show the player that it stops working when everyone is full.
                    local fx = GLOBAL.SpawnPrefab("wortox_soul_heal_fx")
                    fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                    fx:Setup(v)
                end
            end
        end
        if sanitytargetscount > 0 then
            -- Sanity adjustments are relative to who sees it.
            local amt = TUNING.SANITY_TINY * .5
            local amt_nice = amt * TUNING.SKILLS.WORTOX.NICE_SANITY_MULT
            local amt_naughty = amt * TUNING.SKILLS.WORTOX.NAUGHTY_SANITY_MULT
            for i = 1, sanitytargetscount do
                local v = sanitytargets[i]
                local adjusted_amt = v.wortox_inclination == "nice" and amt_nice or v.wortox_inclination == "naughty" and amt_naughty or amt
                v.components.sanity:DoDelta(adjusted_amt)
            end
        end
    end


    --Override the healing function with a new one
    local wortox_soul_common = require("prefabs/wortox_soul_common")
    wortox_soul_common.DoHeal = UncompromisingSoulHeal

    AddPrefabPostInit("wortox_soul", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        local function CheckAllegiance(inst,owner)
            local skilltreeupdater = owner.components.skilltreeupdater
            if skilltreeupdater then
                if skilltreeupdater:IsActivated("wortox_allegiance_shadow_1") then
                    inst.components.upgrader.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
                elseif skilltreeupdater:IsActivated("wortox_allegiance_lunar_1") then
                    inst.components.upgrader.upgradetype = GLOBAL.UPGRADETYPES.SOUL_LUNAR
                else
                    inst.components.upgrader.upgradetype = nil
                end
            else
                inst.components.upgrader.upgradetype = nil
            end
        end

        local function ModifyStats(inst, owner) 
            local skilltreeupdater = owner.components.skilltreeupdater
            if skilltreeupdater then
                if skilltreeupdater:IsActivated("wortox_soulprotector_1") then
                    inst.soul_heal_range_modifier = (inst.soul_heal_range_modifier or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_RANGE
                    inst.soul_follow_speed = (inst.soul_follow_speed or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_SPEED
                    inst.soulprotector_task = inst:DoPeriodicTask(SOULPROTECTOR_TICK_TIME, inst.SoulProtectorTick, .3)
                end
                if skilltreeupdater:IsActivated("wortox_soulprotector_3") then
                    inst.soul_doburst = true
                end
                if skilltreeupdater:IsActivated("wortox_soulprotector_4") then
                    inst.soul_follow_speed = (inst.soul_follow_speed or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_4_SPEED
                    inst.soul_doburst_faster = true
                    inst.soul_heal_player_efficient = true
                    inst.um_soul_echo_cooldown_time = owner:GetSoulEchoCooldownTime()
                end
            end
            inst.owner = owner -- need to pass the owner so each soul can count how many souls the owner has
        end
        
        inst:AddComponent("tradable")

        inst:AddComponent("upgrader")
        
        inst.components.upgrader.upgradevalue = 2
        
        inst.components.inventoryitem:SetOnPutInInventoryFn(CheckAllegiance)
        inst.ModifyStats = ModifyStats
    end)
    
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Twin Tailed Heart ] -------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------        

    AddPrefabPostInit("wortox_reviver", function(inst)
        inst:RemoveTag("reviver")

        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        local function OnConsume(inst, owner)
            if inst.components.perishable and inst.components.perishable:GetPercent() > .5 then
                inst.components.perishable:SetPercent(inst.components.perishable:GetPercent()-.5) -- take 1/2 freshhness
            else    
                inst:Remove()
            end
        end        
            
        inst.OnConsume = OnConsume
    end)
    AllRecipes["wortox_reviver"].ingredients = {
        Ingredient("wortox_soul", 20),
    }        
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Soul Decoy Changes ] ------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------    

    AddPrefabPostInit("wortox_decoy", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        local COMBAT_MUSTHAVE_TAGS = { "_combat", "_health" }
        local COMBAT_CANTHAVE_TAGS = { "INLIMBO", "soul", "noauradamage", "companion" }
                
        local function DoThorns_decoy(inst)
            local ent = inst.decoythornstarget
            if ent and ent:IsValid() and ent.entity:IsVisible() and
                ent:HasAllTags(COMBAT_MUSTHAVE_TAGS) and not ent:HasAnyTag(COMBAT_CANTHAVE_TAGS) and
                inst.components.combat:CanTarget(ent) then
                local initial_damage = inst.components.combat.defaultdamage

                local decoyowner = inst.decoyowner and inst.decoyowner:IsValid() and inst.decoyowner or nil
                local damage = initial_damage * TUNING.SKILLS.WORTOX.SOULDECOY_THORNS_DAMAGE_MULT
                local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS
                local damage_percent = math.min(inst.decoyowner.soulcount or 0, souls_max)*.5/souls_max+1
                if decoyowner and decoyowner.wortox_inclination and decoyowner.wortox_inclination == "naughty" then
                    damage = damage * damage_percent
                    inst.components.combat:SetDefaultDamage(damage)
                end
                if wortox_soul_common.SoulDamageTest(inst, ent, decoyowner) then
                    local x, y, z = ent.Transform:GetWorldPosition()
                    local fx = GLOBAL.SpawnPrefab("wortox_soul_spawn_fx")
                    fx.Transform:SetPosition(x, y, z)
                    if decoyowner then
                        local damagetoent = damage
                        local explosiveresist = ent.components.explosiveresist
                        if explosiveresist then
                            damagetoent = damagetoent * (1 - explosiveresist:GetResistance())
                            explosiveresist:OnExplosiveDamage(damagetoent, decoyowner)
                        end
                        ent.components.combat:GetAttacked(decoyowner, damagetoent, nil, "soul")
                    else
                        inst.components.combat:DoAttack(ent)
                    end
                end

                inst.components.combat:SetDefaultDamage(initial_damage)
            end
        end


        local function DoExplosion_decoy(inst)
            if inst.decoythorns then
                inst:DoThorns()
            end
            local decoyowner = inst.decoyowner and inst.decoyowner:IsValid() and inst.decoyowner or nil
            local damage = inst.components.combat.defaultdamage
            local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS
            local damage_percent = math.min(inst.decoyowner.soulcount or 0, souls_max)*.5/souls_max+1
            if decoyowner and decoyowner.wortox_inclination and decoyowner.wortox_inclination == "naughty" then
                damage = damage * damage_percent
                inst.components.combat:SetDefaultDamage(damage)
            end
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, TUNING.SKILLS.WORTOX.SOULDECOY_EXPLODE_RADIUS, COMBAT_MUSTHAVE_TAGS, COMBAT_CANTHAVE_TAGS)
            for _, ent in ipairs(ents) do
                if ent:IsValid() and ent.entity:IsVisible() then
                    if inst.components.combat:CanTarget(ent) then
                        local shouldharm = inst.decoylured[ent]
                        if not shouldharm then
                            if ent.components.combat then
                                if ent.components.combat:TargetIs(inst) or decoyowner and ent.components.combat:TargetIs(decoyowner) then
                                    if wortox_soul_common.SoulDamageTest(inst, ent, decoyowner) then
                                        shouldharm = true
                                    end
                                end
                            end
                        end
                        if shouldharm then
                            if decoyowner then
                                local damagetoent = damage
                                local explosiveresist = ent.components.explosiveresist
                                if explosiveresist then
                                    damagetoent = damagetoent * (1 - explosiveresist:GetResistance())
                                    explosiveresist:OnExplosiveDamage(damagetoent, decoyowner)
                                end
                                ent.components.combat:GetAttacked(decoyowner, damagetoent, nil, "soul")
                            else
                                inst.components.combat:DoAttack(ent)
                            end
                        end
                    end
                end
            end
        end
        inst.DoExplosion = DoExplosion_decoy
        inst.DoThorns = DoThorns_decoy
    end)    
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Soul Pierce Changes ] -----------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------        

    local SOUL_SPEAR_TICK_TIME = .1
    local COMBAT_MUSTHAVE_TAGS = { "_combat", "_health" }
    local COMBAT_CANTHAVE_TAGS = { "INLIMBO", "soul", "noauradamage", "companion" }
    local function SoulSpearTick(inst, owner)
        if not owner:IsValid() then
            return
        end

        if inst.soul_spear_cooldown then
            inst.soul_spear_cooldown = inst.soul_spear_cooldown - 1
            if inst.soul_spear_cooldown <= 0 then
                inst.soul_spear_cooldown = nil
            else
                return
            end
        end

        local damage = TUNING.SKILLS.WORTOX.SOUL_SPEAR_DAMAGE
        local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS
        local damage_percent = math.min(owner.soulcount or 0, souls_max)*.5/souls_max+1
        if owner.wortox_inclination and owner.wortox_inclination == "naughty" then
            damage = damage * damage_percent
        end


        local hitsomething = false
        local r = inst:GetPhysicsRadius(0) + .5 -- Extra padding for visual ambiguity.
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, GLOBAL.MAX_PHYSICS_RADIUS, COMBAT_MUSTHAVE_TAGS, COMBAT_CANTHAVE_TAGS)
        for _, ent in ipairs(ents) do
            if ent.components.combat then
                local r2 = ent:GetPhysicsRadius(0)
                local x2, y2, z2 = ent.Transform:GetWorldPosition()
                local dx, dz = x2 - x, z2 - z
                local dsq = dx * dx + dz * dz
                local dr = r2 + r
                if dsq < dr * dr and wortox_soul_common.SoulDamageTest(inst, ent, owner) then
                    local damagetoent = damage
                    local explosiveresist = ent.components.explosiveresist
                    if explosiveresist then
                        damagetoent = damagetoent * (1 - explosiveresist:GetResistance())
                        explosiveresist:OnExplosiveDamage(damagetoent, owner)
                    end
                    ent.components.combat:GetAttacked(owner, damagetoent, nil, "soul")
                    hitsomething = true
                end
            end
        end

        if hitsomething then
            inst.soul_spear_cooldown = TUNING.SKILLS.WORTOX.SOUL_SPEAR_HIT_COOLDOWN / SOUL_SPEAR_TICK_TIME
        end
    end


    AddPrefabPostInit("wortox_soul_spawn", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        local _OnThrownFn = inst.components.projectile.onthrown
        
        local function OnThrownTimeout(inst)
            inst._timeouttask = nil
            inst.components.projectile:Miss(inst.components.projectile.target)
        end
        
        local function OnThrown(inst, owner, target, attacker)
            _OnThrownFn(inst, owner, target, attacker) -- we don't want to have to replace the whole function, just recheck the timeout
    
            
            local duration = TUNING.WORTOX_SOUL_PROJECTILE_LIFETIME
            if target and target.components.skilltreeupdater then --redo the timer w/ thief 1 instead of relying on thief 2
                if target.components.skilltreeupdater:IsActivated("wortox_thief_1") then
                    if inst._timeouttask ~= nil then
                        inst._timeouttask:Cancel()
                        inst._timeouttask = nil
                    end
                    duration = duration + TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_LIFETIME_BONUS
                    inst._timeouttask = inst:DoTaskInTime(duration, OnThrownTimeout)
                end
            end
        end    
        inst.components.projectile:SetOnThrownFn(OnThrown)
        inst.SoulSpearTick = SoulSpearTick
    end)        
    --------------------------------------------------- -- This is the cause...
    local function OnHit(inst, attacker, target)
        if target ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = GLOBAL.SpawnPrefab("wortox_soul_in_fx")
            fx.Transform:SetPosition(x, y, z)
            fx:Setup(target)
            --ignore .isvisible, as long as it's .isopen
            if target.components.inventory ~= nil and target.components.inventory.isopen then
                target.components.inventory:GiveItem(GLOBAL.SpawnPrefab("wortox_soul"), nil, target:GetPosition())
            else
                --reuse fx variable
                fx = GLOBAL.SpawnPrefab("wortox_soul")
                fx.Transform:SetPosition(x, y, z)
                fx.components.inventoryitem:OnDropped(true)
            end
        end
        inst:Remove()
    end
    
    local function RethrowProjectile(inst, speed, soulthiefreceiver)
        if soulthiefreceiver:IsValid() then
            inst.components.projectile:SetSpeed(speed)
            inst.components.projectile:SetHoming(true)

            local x, y, z = inst.Transform:GetWorldPosition()
            inst.components.projectile:SetBounced(true)
            inst.components.projectile.overridestartpos = GLOBAL.Vector3(x, 0, z)
            inst.components.projectile:SetOnHitFn(OnHit)
            inst.components.projectile:Throw(inst, soulthiefreceiver, soulthiefreceiver)
        end
    end
    

    local function ReleaseSoul(inst,target,inv_soul) -- manually throw the soul
        if inv_soul.components.stackable ~= nil and inv_soul.components.stackable:IsStack() then
            inv_soul.components.stackable:Get():Remove()
        else
            inv_soul:Remove()
        end
        local x1,y1,z1 = inst.Transform:GetWorldPosition()
        local x2,y2,z2 = target.Transform:GetWorldPosition()
        local x = (x1+x2)/2
        local z = (z1+z2)/2
        local soul = GLOBAL.SpawnPrefab("wortox_soul_spawn")

        soul.Transform:SetPosition(x,0,z)
        
        soul.soul_spear_task = soul:DoPeriodicTask(.1, soul.SoulSpearTick, 0, inst)
        soul:Setup(inst)
        local speed = TUNING.WORTOX_SOUL_PROJECTILE_SPEED
        soul.components.projectile:SetSpeed(-speed)
        soul.components.projectile:SetHoming(false)
        soul:DoTaskInTime(TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_REPEL_DURATION, RethrowProjectile, speed, inst)
        soul.components.projectile:SetOnHitFn(OnHit)
        soul.components.projectile:Throw(soul, inst, inst)
        soul.components.projectile:SetOnHitFn(function(soul) end)

    
    end
    
    local function GenerateSouls(inst,data)
        if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_thief_4") and not (data.stimuli and data.stimuli == "soul") then
            local souls = 0
            local ref_item = nil
            inst.components.inventory:ForEachItemSlot(function(item)
                if item.prefab == "wortox_soul" then
                    souls = souls + (item.components.stackable and item.components.stackable:StackSize() or 1)
                    ref_item = item
                end
            end)
            if souls >= 10 then
                if not inst.wortox_damage_recent then
                    inst.wortox_damage_recent = 0
                end
                inst.wortox_damage_recent = inst.wortox_damage_recent + (data.damage or 0)        
                if inst.wortox_damage_recent >= 176 then
                    inst.wortox_damage_recent = 0
                    ReleaseSoul(inst,data.target,ref_item)
                end                
            end
        end
    end
    
    AddPrefabPostInit("wortox", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        inst:ListenForEvent("onhitother", GenerateSouls)
    end)     -- This is the cause of tint crash, if it happens again.
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Shadow Weaving ] ----------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------    
    local function CheckToRemoveFollower(inst)
        if inst.components.leader then
            local shadows = inst.components.leader:GetFollowersByTag("shadow")
            if #shadows > 2 then
                local removed
                for i,v in ipairs(shadows) do
                    if (v.prefab == "stalker_minion1" or v.prefab == "stalker_minion2") and not removed then
                        inst.components.leader:RemoveFollower(v)
                        v.components.health:Kill()
                        removed = true
                    end
                end
                for i,v in ipairs(shadows) do
                    if (v.prefab == "crawlingnightmare") and not removed then
                        inst.components.leader:RemoveFollower(v)
                        v.components.health:Kill()
                        removed = true
                    end
                end
                for i,v in ipairs(shadows) do
                    if (v.prefab == "nightmarebeak") and not removed then
                        inst.components.leader:RemoveFollower(v)
                        v.components.health:Kill()
                        removed = true
                    end
                end
                if not removed then
                    local shadow = shadows[1]
                    inst.components.leader:RemoveFollower(shadow)
                    if shadow.components.health then
                        shadow.components.health:Kill()
                    else
                        shadow:Remove()
                    end
                end
                return .05
            else
                return 0
            end
        end
        return 0
    end
    
    local function SpawnWovenShadow(inst, upgrade_performer, obj)
        if inst.components.stackable then
            inst.components.stackable:Get(1):Remove()
            inst:RemoveComponent("upgradeable") -- reset the component, it sometimes loses the ability to be used when you take from stack
            inst:AddComponent("upgradeable")
            inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
            inst.components.upgradeable.onupgradefn = SpawnWovenShadow        
        else
            inst:Remove()
        end

        local rnd = math.random()

        local crechure = "stalker_minion"
        local skilltreeupdater = upgrade_performer.components.skilltreeupdater
        local mod = CheckToRemoveFollower(upgrade_performer)

        rnd = rnd - mod
        if (inst.prefab == "horrorfuel") then
            if skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") then -- 2x likelyhood for second shadow skill
                if rnd < .05 then -- If Pure Horror then crawlingnightmare, nightmarebeak, ruinsnightmare, shadowthrall_mouth (rictus)
                    crechure = "shadowthrall_mouth"
                elseif rnd < .2 then
                    crechure = "ruinsnightmare"
                elseif rnd < .6 then
                    crechure = "nightmarebeak"
                else
                    crechure = "crawlingnightmare"
                end
            else
                if rnd < .025 then
                    crechure = "shadowthrall_mouth"
                elseif rnd < .15 then
                    crechure = "ruinsnightmare"
                elseif rnd < .4 then
                    crechure = "nightmarebeak"
                else
                    crechure = "crawlingnightmare"
                end
            end        
        else
            if skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") then -- 2x likelyhood for second shadow skill
                if rnd < .02 then -- If Nightmarefuel then woven shadow, crawling nightmare, nightmarebeak, lurking nightmare
                    crechure = "ruinsnightmare"
                elseif rnd < .12 then
                    crechure = "nightmarebeak"
                elseif rnd < .4 then
                    crechure = "crawlingnightmare"
                end
            else
                if rnd < .01 then
                    crechure = "ruinsnightmare"
                elseif rnd < .06 then
                    crechure = "nightmarebeak"
                elseif rnd < .2 then
                    crechure = "crawlingnightmare"
                end
            end
        end
        local shadow = GLOBAL.SpawnPrefab(crechure) 
        shadow.wortox_minion = true -- These Guys are minions of Wortox
        
        local x,y,z = upgrade_performer.Transform:GetWorldPosition()
        local offset = GLOBAL.FindWalkableOffset(upgrade_performer:GetPosition(),math.random() * 2 * GLOBAL.PI, 4, 5)
        if offset then -- So it doesn't crash if the player is godmode on the ocean and tries to weave a shadow
            x = x + offset.x
            z = z + offset.z
        end
        shadow.Transform:SetPosition(x,y,z)
            
        local despawn = GLOBAL.SpawnPrefab("shadow_despawn")
        despawn.Transform:SetPosition(x, y, z)

        shadow:AddComponent("follower")
        upgrade_performer.components.leader:AddFollower(shadow)
        
        if crechure == "stalker_minion" then
            shadow:AddTag("shadow")
            shadow.die_off = shadow:DoTaskInTime(60,function(shadow) 
                if shadow.components.health and not shadow.components.health:IsDead() then 
                    shadow.components.health:Kill() 
                end 
            end)
        else
            shadow.die_off = shadow:DoPeriodicTask(1,function(shadow) 
                if shadow.components.health and not shadow.components.health:IsDead() then 
                    shadow.components.health:DoDelta(-5)
                end 
            end)        
        end
        
        --shadow.persists = false
        local fx = GLOBAL.SpawnPrefab("wortox_soulecho_buff_fx")
        shadow.bufffx = fx
        fx.entity:SetParent(shadow.entity)
        fx.Transform:SetScale(2,2,2)
        shadow:ListenForEvent("ondeath",function(shadow)
            if inst.bufffx and inst.bufffx:IsValid() then
                inst.bufffx:Remove()
            end
            inst.bufffx = nil
            inst:Remove()    
        end)
        if shadow.components.lootdropper then
            shadow.components.lootdropper:SetLoot(nil)
            shadow.components.lootdropper:SetChanceLootTable(nil)
        end
        if crechure == "stalker_minion" then
            shadow.sg:GoToState("emerge_noburst")
            shadow:OnSpawnedBy(upgrade_performer)
        end
        
        if crechure == "shadowthrall_mouth" then
            shadow:AddTag("shadow")
            shadow.components.combat:SetRetargetFunction(3, nil)
            shadow.components.combat:SetKeepTargetFunction(function(shadow) return true end)
        end
        shadow:RemoveComponent("sanityaura")
    end
    --------------------------------------------
    --[ Make Nightmarefuel "Upgradeable" ] -----
    --------------------------------------------
    
    AddPrefabPostInit("nightmarefuel", function(inst)
        inst:AddTag("SOUL_SHADOW_upgradeable")

        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        inst:AddComponent("upgradeable")
        inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
        inst.components.upgradeable.onupgradefn = SpawnWovenShadow        
    end)
    
    AddPrefabPostInit("horrorfuel", function(inst)
        inst:AddTag("SOUL_SHADOW_upgradeable")

        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        inst:AddComponent("upgradeable")
        inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
        inst.components.upgradeable.onupgradefn = SpawnWovenShadow        
    end)
    
    --------------------------------------------
    --[ Scythe Extending Lifetime of Shadows] --
    --------------------------------------------
    
    AddPrefabPostInit("voidcloth_scythe", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        local _OnAttack = inst.components.weapon.onattack
    
        local function OnAttack(inst, attacker, target) 
            local skilltreeupdater = attacker.components.skilltreeupdater
            local max_health = target.components.health ~= nil and target.components.health.maxhealth
            if target.components.health ~= nil and target.components.health:IsDead() and not target:HasTag("structure") and skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") and max_health and not (target:HasTag("soulless") or target:HasTag("chess") or target:HasTag("shadow"))then
                local x,y,z = attacker.Transform:GetWorldPosition()
                local shadows = TheSim:FindEntities(x,y,z,20,{"shadow"})
                local k = 0
                for i,shadow in ipairs(shadows) do -- find the division of health
                    if shadow.wortox_minion then
                        k = k + 1
                    end
                end
                for i,shadow in ipairs(shadows) do
                    if shadow.wortox_minion then
                        GLOBAL.SpawnPrefab("shadow_despawn").Transform:SetPosition(shadow.Transform:GetWorldPosition())
                        shadow.components.health:DoDelta(max_health/k)
                    end
                end
            end
            _OnAttack(inst,attacker,target)
        end
                
        inst.components.weapon:SetOnAttack(OnAttack)
    end)
    
    -- Other Shadow Weaponry
    local hitsparks_fx_colouroverride = {1, 0, 0} -- Try to get lunar colored
    local function TryToSparkOn(target, attacker)
        if target ~= nil and target:IsValid() then
            local spark = SpawnPrefab("hitsparks_fx")
            spark:Setup(attacker, target, nil, hitsparks_fx_colouroverride)
            spark.black:set(true)
        end
    end
    
    local function DoShadowAttack(inst, owner, target)
        if owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead()) then
            if target and target ~= owner and target:IsValid() and (target.components.health == nil or not target.components.health:IsDead() and not target:HasTag("structure") and not target:HasTag("wall")) then
                target.components.combat:GetAttacked(owner,34,inst)
                TryToSparkOn(target, owner)
            end
        end
    end
    
    local shadow_weapons = {"nightsword"}
    for i,v in ipairs(shadow_weapons) do
        AddPrefabPostInit(v, function(inst)
            if not GLOBAL.TheWorld.ismastersim then
                return
            end

            local _OnAttack = inst.components.weapon.onattack or function() end -- Dummy function here as the Fix if the weapon doesn't have an onattack.
            local function OnAttack(inst, attacker, target, ...) 
                local skilltreeupdater = attacker.components.skilltreeupdater
                if target.components.health ~= nil and target.components.health:IsDead() and not target:HasTag("structure") and skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") then
                    DoShadowAttack(inst, attacker, target)
                end

                _OnAttack(inst, attacker, target, ...)
            end

            inst.components.weapon:SetOnAttack(OnAttack)
        end)
    end
    
    -----------------------------
    --[ Shadow Brain Changes ] --
    -----------------------------
        
    --- Wortox Shadow brain changes
    local MIN_FOLLOW_LEADER = 2
    local MAX_FOLLOW_LEADER = 6
    local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2
    -- make woven shadow creatures follow wortox
    local function GetLeader(inst)
        return inst.components.follower ~= nil and inst.components.follower.leader or nil
    end

    local function ShadowCreatureFollow(self)
        table.insert(self.bt.root.children, 2, GLOBAL.WhileNode(function() return GetLeader(self.inst) end, "HasLeader",
            GLOBAL.Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER)))
    end

    AddBrainPostInit("nightmarecreaturebrain", ShadowCreatureFollow)
    AddBrainPostInit("shadowthrall_mouth_brain", ShadowCreatureFollow)
    
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Nabbag Damage Calculation Tweak ] -----------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------    
    
    AddPrefabPostInit("wortox_nabbag", function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        local BUCKET_NAMES = {
            "_empty",
            "_medium",
            "_full",
        }
        local BUCKET_SIZE = #BUCKET_NAMES

        local function UpdateStats(inst, percent, souls)
            -- Make the sizes into buckets.
            local bucket = math.clamp(math.ceil(percent * BUCKET_SIZE), 1, BUCKET_SIZE)
            local old_size = inst.nabbag_size
            inst.nabbag_size = BUCKET_NAMES[bucket]
            -- Scale percent to be percent of bucket.
            percent = (bucket - 1) / (BUCKET_SIZE - 1)

            local vfx_level = 0
            local owner = inst.components.inventoryitem.owner
            if inst.components.weapon then
                local maxdamage = 34
                if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wortox_souljar_3") then
                    maxdamage = 51
                end
                local mindamage = TUNING.SKILLS.WORTOX.NABBAG_DAMAGE_MIN
                local damage = (maxdamage - mindamage) * percent + mindamage
                if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wortox_souljar_3") then
                    local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS
                    local souls_clamped = math.min(souls, souls_max)
                    if souls_clamped == souls_max then -- NOTES(JBK): This is done like this to keep floating point precision out of the equation.
                        vfx_level = 3
                    elseif souls_clamped >= souls_max * .50 then
                        vfx_level = 2
                    elseif souls_clamped >= souls_max * .25 then
                        vfx_level = 1
                    end
                    local damage_percent = souls_clamped / souls_max
                    damage = damage * ((1 + (TUNING.SKILLS.WORTOX.SOUL_DAMAGE_NABBAG_BONUS_MULT - 1)/3 * damage_percent))
                end
                inst.components.weapon:SetDamage(damage)
                inst.components.weapon.attackwearmultipliers:SetModifier(inst, percent)
            end

            if inst.wortox_nabbag_body ~= nil then
                inst.wortox_nabbag_body.bodysize_netvar:set(bucket - 1)
                inst.wortox_nabbag_body.bodyvfx_souls:set(vfx_level)
                inst.wortox_nabbag_body:UpdateBodySize()
                if inst.wortox_nabbag_body.hiding then
                    if owner then
                        owner.AnimState:OverrideSymbol("swap_object", "swap_wortox_nabbag", "swap_wortox_nabbag" .. inst.nabbag_size)
                    end
                end
            end
            if inst.nabbag_size == "_empty" then
                inst.components.inventoryitem:ChangeImageName(nil) -- Default image name is the prefab name itself as a network optimization.
            else
                inst.components.inventoryitem:ChangeImageName("wortox_nabbag" .. inst.nabbag_size)
            end
        end

        inst.UpdateStats = UpdateStats
            
    end)
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Lunar I Stuff ] --=--------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    local function DeleteBackItem(inst)
        if inst._item and inst._item:IsValid() then
            inst._item:Remove()
            inst._item = nil
        end
        inst.components.inventory:DropEverything()
    end
    
    local function HauntItem(inst)
        inst.AnimState:SetMultColour(0,0,0,0)
        --inst._item.floating:Cancel()
        --inst._item.floating = nil
        inst._item.entity:SetParent(inst.entity)
        inst._item.entity:AddFollower()
        inst._item.Follower:FollowSymbol(inst.GUID, "blob_body", 0, 0, 0)
        inst._item.Transform:SetScale(1.25,1.25,1.25) -- offset scaling down the other gestalt

        inst._item:AddComponent("pickable")
        inst._item.components.pickable.canbepicked = true
        inst._item:RemoveComponent("stackable")
        inst._item.components.pickable.onpickedfn = function()
            inst._item:Remove()
            inst._item = nil
            inst.components.inventory:DropEverything()
            inst.components.trader.enabled = true
            inst.AnimState:SetMultColour(1,1,1,.6)
        end
        inst._item.AnimState:SetHaunted(true)        
    end
    
    local function StartBrain(inst)
        inst:RemoveEventCallback("animover",StartBrain)
        inst.brain:Start()
        HauntItem(inst)
    end
    
    local function Floattask(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x,y+.5/FRAMES,z)    
    end
    
    local function GestaltGotItem(inst, giver, item, count, name)
        inst.components.trader.enabled = false
        local item = string.lower(item.prefab) ~= nil and string.lower(item.prefab) or name ~= nil and name

        inst._item = GLOBAL.SpawnPrefab(item)
        if inst._item then
            inst._item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst._item.components.inventoryitem.canbepickedup = false
            inst.components.locomotor:Stop()
            inst.brain:Stop()
            if inst._item.components.edible then
                 inst._item:RemoveComponent("edible")
            end
            if inst._item.components.perishable then
                inst._item:RemoveComponent("perishable")
            end
            if inst._item.components.health then
                inst._item:RemoveComponent("health")
            end        
            if inst._item.brain then
                inst._item.brain:Stop()
            end    
            --inst._item.floating = inst._item:DoPeriodicTask(FRAMES,Floattask)
            inst:DoTaskInTime(0,function(inst)
                inst.AnimState:PlayAnimation("infest")
                inst:ListenForEvent("animover",StartBrain)
            end)
        end        
    end

    local function GestaltAcceptTest(inst, item, giver)
        return not item:HasTag("irreplaceable") and giver == inst.wortox
    end

    local function SpawnGestalt(inst, upgrade_performer, obj,time_left,inventory)
        if inst and inst.components.stackable then
            inst.components.stackable:Get(1):Remove()
            inst:RemoveComponent("upgradeable") -- reset the component, it sometimes loses the ability to be used when you take from stack
            inst:AddComponent("upgradeable")
            inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_LUNAR
            inst.components.upgradeable.onupgradefn = SpawnGestalt        
        elseif inst then
            inst:Remove()
        end
        
        local crechure = "lunarthrall_plant_gestalt"
        local skilltreeupdater = upgrade_performer.components.skilltreeupdater
        local gestalt = GLOBAL.SpawnPrefab(crechure) 
        gestalt.wortox_minion = true -- These Guys are minions of Wortox

        GLOBAL.MakeFlyingCharacterPhysics(gestalt, 1, .5)
        gestalt:AddTag("flying")

        local x,y,z = upgrade_performer.Transform:GetWorldPosition()
        local offset = GLOBAL.FindWalkableOffset(upgrade_performer:GetPosition(),math.random() * 2 * GLOBAL.PI, 4, 5)
        if offset then -- So it doesn't crash if the player is godmode on the ocean and tries to weave a gestalt
            x = x + offset.x
            z = z + offset.z
        end
    
        gestalt.Transform:SetPosition(x,y,z)
        gestalt.Transform:SetScale(.75, .75, .75)

        gestalt:AddComponent("follower")
        upgrade_performer.components.leader:AddFollower(gestalt)

        local timer = gestalt.components.timer or gestalt:AddComponent("timer")

        if (inst.prefab == "purebrilliance") then
            time_left = 60 * 8 * 8
        end

        timer:StartTimer("despawn",time_left ~= nil and time_left or 60 * 8 * 2)
        gestalt:ListenForEvent("timerdone",function(gestalt)
            DeleteBackItem(gestalt)
            gestalt:Remove()    
        end)

        local fx = GLOBAL.SpawnPrefab("wortox_soulecho_buff_fx")
        gestalt.bufffx = fx
        fx.entity:SetParent(gestalt.entity)
        fx.Transform:SetScale(2, 2, 2)
        gestalt:ListenForEvent("onremoved",function(gestalt)
            if gestalt.bufffx and gestalt.bufffx:IsValid() then
                gestalt.bufffx:Remove()
            end
            gestalt.bufffx = nil
            gestalt:Remove()    
        end)
        gestalt.wortox = upgrade_performer
        gestalt:AddComponent("trader")
        gestalt:AddComponent("inventory")
        if inventory then
            gestalt.components.inventory = inventory
            local item = gestalt.components.inventory:GetItemInSlot(1)
            if item then
                GestaltGotItem(gestalt, nil, item)
            end
        end
        gestalt.components.trader.enabled = true
        gestalt.components.trader:SetAcceptTest(GestaltAcceptTest)
        gestalt.components.trader.acceptnontradable = true
        gestalt.components.trader.onaccept = GestaltGotItem
        gestalt.components.trader:SetAcceptStacks()
        gestalt.components.trader.deleteitemonaccept = false
        gestalt:RemoveComponent("sanityaura")    
        --gestalt.persists = false
        gestalt.sg:GoToState("spawn")
    end
    
    --------------------------------------------
    --[ Make Moon Blossoms "Upgradeable" ] -----
    --------------------------------------------
        
    AddPrefabPostInit("moon_tree_blossom", function(inst)
        inst:AddTag("SOUL_LUNAR_upgradeable")

        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        inst:AddComponent("upgradeable")
        inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_LUNAR
        inst.components.upgradeable.onupgradefn = SpawnGestalt        
    end)
    
    AddPrefabPostInit("purebrilliance", function(inst)
        inst:AddTag("SOUL_LUNAR_upgradeable")

        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        
        inst:AddComponent("upgradeable")
        inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_LUNAR
        inst.components.upgradeable.onupgradefn = SpawnGestalt        
    end)
    
    -----------------------------
    --[ Lunarthrall Changes ] ---
    -----------------------------
    require "behaviours/faceentity"
    require "behaviours/doaction"
    local function GetFaceTargetFn(inst)
        return inst.components.follower.leader
    end    
    
    local function KeepFaceTargetFn(inst, target)
        return inst.components.follower.leader == target
    end


    local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "planted", "trap", "raidrat", "spider", "catchable", "fire", "irreplaceable", "heavy", "prey", "bird", "outofreach", "_container" }

    local function ItemNearby(inst)
        local prefab = inst._item.prefab
        local x,y,z = inst.Transform:GetWorldPosition()
        local items = GLOBAL.TheSim:FindEntities(x,y,z, 24, {"_inventoryitem"},NO_TAGS)
        for i,item in ipairs(items) do
            if item.components.inventoryitem.canbepickedup and item.prefab == prefab and item ~= inst._item then
                return item
            end
        end
    end
    
    local function StealAction(inst,item)
        return GLOBAL.BufferedAction(inst, item, GLOBAL.ACTIONS.PICKUP)
    end
        
    local function LunarCreatureFollow(self)
        table.insert(self.bt.root.children, 1,  GLOBAL.WhileNode(function() return self.inst._item ~= nil and ItemNearby(self.inst) end, "HasItem",
            GLOBAL.DoAction(self.inst, function() return StealAction(self.inst,ItemNearby(self.inst)) end, "steal", true),.25))
        table.insert(self.bt.root.children, 2, GLOBAL.WhileNode(function() return GetLeader(self.inst) end, "HasLeader",
            GLOBAL.Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER)))
        table.insert(self.bt.root.children, 3, GLOBAL.WhileNode(function() return GetLeader(self.inst) and not (self.inst._item ~= nil and ItemNearby(self.inst)) end, "HasLeader",
            GLOBAL.FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn )))
    end

    AddBrainPostInit("lunarthrall_plant_gestalt_brain", LunarCreatureFollow)
    
    AddStategraphPostInit("lunarthrall_plant_gestalt", function(inst)
        local states = {
            GLOBAL.State{
                name = "steal",
                tags = {"busy"},

                onenter = function(inst)
                    inst.Physics:Stop()
                    inst.AnimState:PlayAnimation("idle", true)
                    inst:DoTaskInTime(.25,function(inst) 
                        inst:PerformBufferedAction()
                        inst:DoTaskInTime(0,function(inst) 
                            if inst:GetBufferedAction() then
                                inst:ClearBufferedAction()
                            end
                            inst.sg:GoToState("idle") 
                        end) -- need a delay
                    end)
                end,
            }, 
        }

        for k, v in pairs(states) do
            inst.states[v.name] = v
        end
        
        --inst.states["idle"].onexit = function(inst) inst:ClearBufferedAction() end -- can sometimes get stuck in the idle animation (no way to clear the buffered action for picking)
    end)
    AddStategraphActionHandler("lunarthrall_plant_gestalt", GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICKUP, "steal"))

    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Lunar II Stuff ] --=-------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    
    -- Generic Prevention of repeat stealing... doesn't apply to despawning/respawning mobs...
    AddPrefabPostInitAny(function(inst)
        if inst.components.health then
            local old_OnSave = inst.OnSave
            inst.OnSave = function(inst, data, ...)
                if inst.wortox_stolen then
                    data.wortox_stolen = true
                end

                if old_OnSave ~= nil then
                    return old_OnSave(inst, data, ...)
                end
            end
            local old_OnLoad = inst.OnLoad
            inst.OnLoad = function(inst, data, ...)
                if data and data.wortox_stolen then
                    inst.wortox_stolen = true
                end

                if old_OnLoad ~= nil then
                    return old_OnLoad(inst, data, ...)
                end
            end
        end
    end)
    
    
    
    
    local STEAL_TABLE = GLOBAL.require("wortox_steals")

    local function findGuy(stringTable) -- We randomly weighted a table string name, now find it in umss_tables
        for i, v in pairs(STEAL_TABLE) do
            if v.name == stringTable then
                return v
            end
        end
    end
    

    
    local function SpecialSteal(inst,target)
        if (not target:HasTag("epic") and not target.wortox_stolen) or (target:HasTag("epic") and not inst.components.timer:TimerExists(target.prefab.."_stolen")) then
            if target:HasTag("epic") then
                inst.components.timer:StartTimer(target.prefab.."_stolen",60*8*10)
            else
                target.wortox_stolen = true
            end
            
            -- FX
            local fx = GLOBAL.SpawnPrefab("abigail_gestalt_hit_fx")
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
            fx.Transform:SetScale(.75,.75,.75)        
            
            local item
            local count
            local bonus
            local bonus_pool -- for multiple tries
            local bonus_count 
            local instakill 
            local matching = findGuy(target.prefab)
            --TheNet:Announce("looting")
            if matching then
                item = GLOBAL.weighted_random_choice(matching.weight)
                if matching.count and matching.count[item] then
                    count = matching.count[item]
                end
                if matching.bonus and matching.bonus[item] then
                    bonus = matching.bonus[item]
                end
                if matching.bonus_pool then
                    bonus_pool = matching.bonus_pool
                end                
                if matching.bonus_count then
                    bonus_count = matching.bonus_count
                end
                if matching.instakill and matching.instakill[item] then
                    instakill = matching.instakill[item]
                end
            -- TheNet:Announce("found")
            -- TheNet:Announce(item)    
            elseif target.components.lootdropper then
                --TheNet:Announce("didn't find")
                local loots = target.components.lootdropper:GenerateLoot()
                local omits = {}
                for i,v in ipairs(loots) do
                --TheNet:Announce(v)
                end
                local j = 1
                for i,prefab in ipairs(loots) do
                    if (prefab == "meat" or prefab == "monstermeat" or prefab == "monstersmallmeat" or prefab == "smallmeat" or prefab == "froglegs" or prefab == "drumstick"
                    or prefab == "pondfish" or prefab == "batwing" or prefab == "fishmeat" or prefab == "leafymeat") then -- filter out meats
                        omits[j] = i
                        j = j + 1
                    end
                end
                if #omits > 0 then
                    for i = #omits,1,-1 do
                        table.remove(loots,omits[i])
                    end
                end
                --TheNet:Announce("omitting")
                for i,v in ipairs(loots) do
                --TheNet:Announce(v)
                end
                --TheNet:Announce(#loots)
                if #loots > 0 then
                    item = loots[math.random(1,#loots)]
                else
                    item = loots[1]
                end
                
            end    
            
            if item then
                if not target.components.lootdropper then
                    target:AddComponent("lootdropper")
                end
                if not count then
                    count = 2
                end
                for i = 1,(count-1) do
                    target.components.lootdropper:SpawnLootPrefab(item)
                end
                if bonus then
                    for i,v in ipairs(bonus) do
                        target.components.lootdropper:SpawnLootPrefab(v)
                    end
                end
                if bonus_count then
                    for i = 1,bonus_count do
                        local temploot = bonus_pool[math.random(1,#bonus_pool)]
                        target.components.lootdropper:SpawnLootPrefab(temploot)
                    end
                end
                if instakill then
                    target.components.lootdropper:SetLoot(nil) -- no loot
                    target.components.lootdropper.chanceloottable = nil
                    target.components.health:Kill()
                end
            end        
        end
    end
    
    local function GenericSteal(inst, target)
        for i = 1, 100 do --Just do it a bunch, no way to steal "all" the inventory from thief component
            inst.components.thief:StealItem(target)
        end
    end

    local hitsparks_fx_colouroverride = {0, 1, 1} -- Try to get lunar colored
    local function TryToSparkOn(target, attacker)
        if target ~= nil and target:IsValid() then
            local spark = GLOBAL.SpawnPrefab("hitsparks_fx")
            spark:Setup(attacker, target, nil, hitsparks_fx_colouroverride)
            --spark.black:set(true)
        end
    end

    local NOT_LUNARTARGET_TAGS = {"structure", "wall"}
    local function DoLunarAttack(inst, owner, target)
        if owner ~= nil and (owner.components.health == nil or not owner.components.health:IsDead()) then
            if target and target ~= owner and target:IsValid() and (target.components.health == nil or not target.components.health:IsDead() and not target:HasAnyTag(NOT_LUNARTARGET_TAGS)) then
                owner:AddComponent("thief")
                GenericSteal(owner,target)
                TryToSparkOn(target, owner)
                SpecialSteal(owner,target)
                target.components.combat:GetAttacked(owner, 42.5, inst)
                owner:RemoveComponent("thief") -- just need thief for a second
            end
        end
    end

    local function WortoxLunarStuff(inst)
        local weapon = inst.components.weapon
        if weapon then
            local _OnAttack = weapon.onattack
            local function OnAttack(inst, attacker, target, ...)
                local ret = _OnAttack and _OnAttack(inst, attacker, target, ...) or nil
                if attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("wortox_allegiance_lunar") then
                    if attacker.finishportalhoptask and attacker:TryToPortalHop(1, false) then
                        DoLunarAttack(inst, attacker, target)
                    end
                end
                return ret
            end
            weapon:SetOnAttack(OnAttack)
        end
    end

    local moon_weapons = {"glasscutter", "moonglassaxe", "sword_lunarplant", "pickaxe_lunarplant"}
    for i, v in ipairs(moon_weapons) do
        AddPrefabPostInit(v, function(inst)
            if not GLOBAL.TheWorld.ismastersim then return end

            WortoxLunarStuff(inst)

            local forgerepairable = inst.components.forgerepairable
            if forgerepairable then
                local _OnRepaired = forgerepairable.onrepaired
                local function OnRepaired(inst, ...)
                    local isbroken = inst.isbroken and inst.isbroken:value()
                    local ret = _OnRepaired(inst, ...)
                    if isbroken then WortoxLunarStuff(inst) end
                    return ret
                end
                forgerepairable:SetOnRepaired(OnRepaired)
            end
        end)
    end
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Final Built Skilltree ] ---------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    
    modimport("init/init_character_changes/skilltree_wortox") -- Import New Wortox Tree


    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Wortox Remembers His Minions ] ---------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------

    -- local function SaveLunarAllies(inst)
        -- local gestalts = inst.components.leader:GetFollowersByTag("brightmare")
        -- if gestalts then
            -- local saved_gestalts
            -- for i,v in ipairs(gestalts) do
                -- saved_gestalts[i].inventory = v.components.inventory
                -- saved_gestalts[i].time_left = v.components.timer:GetTimeLeft("despawn")
            -- end
            -- return saved_gestalts
        -- end
    -- end

    -- local function LoadLunarAllies(inst,crechures)
        -- for i,v in ipairs(crechures) do
            -- SpawnGestalt(nil, inst, obj,v.time_left,v.inventory)
        -- end
    -- end
    
    
    
    
    -- local function KeepShadowsAndGestalts(inst)
        -- if not GLOBAL.TheWorld.ismastersim then
            -- return
        -- end
        -- inst.follower_table = {}

        -- local old_OnDespawn = inst.OnDespawn
        -- inst.OnDespawn = function(inst, migrationdata, ...)
            -- for k, v in pairs(inst.components.leader.followers) do
                -- if k:HasTag("gestalt") or k:HasTag("shadow") then
                    -- local savedata = k:GetSaveRecord()
                    -- table.insert(inst.follower_table, savedata)
                    -- k:AddTag("notarget")
                    -- k:AddTag("NOCLICK")
                    -- k.persists = false
                    -- if k.components.health then
                        -- k.components.health:SetInvincible(true)
                    -- end
                    -- k:DoTaskInTime(math.random()*.2, function(k)
                        -- local fx = GLOBAL.SpawnPrefab("spawn_fx_medium")
                        -- fx.Transform:SetPosition(k.Transform:GetWorldPosition())
                        -- if not k.components.colourtweener then
                            -- k:AddComponent("colourtweener")
                        -- end
                        -- k.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * GLOBAL.FRAMES, k.Remove)
                    -- end)
                -- end
            -- end
            -- return old_OnDespawn(inst, migrationdata, ...)
        -- end

        -- local old_OnSave = inst.OnSave
        -- inst.OnSave = function(inst, data, ...)
            -- print("saving")
            -- if not data.follower_table then
                -- for k, v in pairs(inst.components.leader.followers) do
                    -- if k:HasTag("gestalt") or k:HasTag("shadow") then
                        -- print("saving shadow")
                        -- local savedata = k:GetSaveRecord()
                        -- table.insert(inst.follower_table, savedata)
                        -- k:AddTag("notarget")
                        -- k:AddTag("NOCLICK")
                        -- if k.components.health then
                            -- k.components.health:SetInvincible(true)
                        -- end
                        -- k:DoTaskInTime(math.random()*.2, function(k)
                            -- local fx = GLOBAL.SpawnPrefab("spawn_fx_medium")
                            -- fx.Transform:SetPosition(k.Transform:GetWorldPosition())
                            -- if not k.components.colourtweener then
                                -- k:AddComponent("colourtweener")
                            -- end
                            -- k.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * GLOBAL.FRAMES)--, k.Remove)
                        -- end)
                    -- end
                -- end
            -- else
                -- data.follower_table = inst.follower_table
            -- end
            -- if old_OnSave ~= nil then
                -- return old_OnSave(inst, data, ...)
            -- end
        -- end

        -- local old_OnLoad = inst.OnLoad
        -- inst.OnLoad = function(inst, data, ...)
            -- print("loading")
            -- if data and data.follower_table then
                -- for k, v in pairs(data.follower_table) do
                    -- print("loading shadow")
                    -- inst:DoTaskInTime(.1, function(inst)
                        -- local follower = GLOBAL.SpawnSaveRecord(v)
                        -- inst.components.leader:AddFollower(follower)
                        -- follower:DoTaskInTime(0, function(follower)
                            -- local x, y, z = inst.Transform:GetWorldPosition()
                            -- if inst:IsValid() and not follower:IsNear(inst, 10) then
                                -- follower.Transform:SetPosition(x+math.random(-5, 5), y, z+math.random(-5, 5))
                                -- follower.sg:GoToState("idle")
                            -- end

                            -- local fx = GLOBAL.SpawnPrefab("spawn_fx_medium")
                            -- fx.Transform:SetPosition(follower.Transform:GetWorldPosition())
                        -- end)
                    -- end)
                -- end
            -- end
            -- if old_OnLoad ~= nil then
                -- return old_OnLoad(inst, data, ...)
            -- end
        -- end
    -- end    


    AddPrefabPostInit("wortox_souljar", function(inst)
        inst:AddTag("nosteal")
    end)
end


AddPrefabPostInit("wortox", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
    
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Give Wortox devil food cake affinity ] ------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
            
    if inst.components.foodaffinity ~= nil then
        inst.components.foodaffinity:AddPrefabAffinity("devilsfruitcake", 1.24)
    end
end)
