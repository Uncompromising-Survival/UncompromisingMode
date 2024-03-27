-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------
----------------------------------ATTACH---------------------------------
local function ForceToTakeMoreDamage(inst)
    local self = inst.components.combat
    local _GetAttacked = self.GetAttacked
    self.GetAttacked = function(self, attacker, damage, weapon, stimuli, ...)
        if attacker and damage then
            -- Take extra damage
            damage = damage * (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
    end
end

local function ForceToTakeMoreHunger(inst)
    local self = inst.components.hunger
    local _DoDelta = self.DoDelta
    self.DoDelta = function(self, delta, overtime, ignore_invincible)
        if delta and overtime and delta < 0 then
            -- Take extra hunger
            delta = delta * (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _DoDelta(self, delta, overtime, ignore_invincible)
    end
end

local function ForceToTakeMoreTime(inst)
    local self = inst.components.oldager
    local _OnTakeDamage = self.OnTakeDamage
    self.OnTakeDamage = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if amount and overtime and amount < 0 then
            -- Take extra time
            amount = amount * (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
end

----------------------------------DETACH---------------------------------

local function ForceToTakeUsualDamage(inst)
    local self = inst.components.combat
    local _GetAttacked = self.GetAttacked
    self.GetAttacked = function(self, attacker, damage, weapon, stimuli, ...)
        if attacker and damage then
            -- Take normal damage
            damage = damage / (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
    end
end

local function ForceToTakeUsualHunger(inst)
    local self = inst.components.hunger
    local _DoDelta = self.DoDelta
    self.DoDelta = function(self, delta, overtime, ignore_invincible, ...)
        if delta and overtime and delta < 0 then
            -- Take normal hunger
            delta = delta / (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _DoDelta(self, delta, overtime, ignore_invincible, ...)
    end
end

local function ForceToTakeUsualTime(inst)
    local self = inst.components.oldager
    local _OnTakeDamage = self.OnTakeDamage
    self.OnTakeDamage = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
        if amount and overtime and amount < 0 then
            -- Take extra time
            amount = amount / (1 + ((inst.um_deathcount + 1) / 10))
        end
        return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end
end

--------------------------------------------------------------------------

local function oneat(inst, data)
    if inst.modded_healthabsorption == nil then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if inst.modded_hungerabsorption == nil then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if inst.modded_sanityabsorption == nil then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.wolfgang_vetcurse and 0 or inst.modded_hungerabsorption or 1, 0)

    local stack_mult = inst.components.eater.eatwholestack and data.food.components.stackable ~= nil and data.food.components.stackable:StackSize() or 1

    local base_mult = inst.components.foodmemory ~= nil and inst.components.foodmemory:GetFoodMultiplier(data.food.prefab) or 1

    local warlybuff = inst:HasTag("warlybuffed") and 1.2 or 1

    local health_delta = 0
    local hunger_delta = 0
    local sanity_delta = 0

    if inst.components.health ~= nil and
        (data.food.components.edible.healthvalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        health_delta = data.food.components.edible:GetHealth(inst) * base_mult * inst.modded_healthabsorption * warlybuff
    end

    if inst.components.hunger ~= nil and
        (data.food.components.edible.hungervalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        hunger_delta = data.food.components.edible:GetHunger(inst) * base_mult * inst.modded_hungerabsorption * warlybuff
    end

    if inst.components.sanity ~= nil and
        (data.food.components.edible.sanityvalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        sanity_delta = data.food.components.edible:GetSanity(inst) * base_mult * inst.modded_sanityabsorption * warlybuff
    end

    if inst.components.eater.custom_stats_mod_fn ~= nil then
        health_delta, hunger_delta, sanity_delta = inst.components.eater.custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, data.food, data.feeder)
    end

    --[[local foodaffinitysanitybuff = inst:HasTag("playermerm") and (data.food.prefab == "kelp" or data.food.prefab == "kelp_cooked") and 0 or inst.components.foodaffinity:HasPrefabAffinity(data.food) and 15 or 0
	sanity_delta = sanity_delta + foodaffinitysanitybuff]]

    if health_delta > 3 then
        inst.components.debuffable:AddDebuff("healthregenbuff_vetcurse_" .. data.food.prefab, "healthregenbuff_vetcurse", { duration = (health_delta * 0.1) })
    else
        inst.components.health:DoDelta(health_delta)
    end

    if inst.wolfgang_vetcurse then
        if hunger_delta > 1 then
            inst.components.debuffable:AddDebuff("hungerregenbuff_vetcurse_" .. data.food.prefab, "hungerregenbuff_vetcurse", { duration = (hunger_delta * 0.1) })
        else
            inst.components.hunger:DoDelta(hunger_delta)
        end
    end

    if sanity_delta > 3 then
        inst.components.debuffable:AddDebuff("sanityregenbuff_vetcurse_" .. data.food.prefab, "sanityregenbuff_vetcurse", { duration = (sanity_delta * 0.1) })
    else
        inst.components.sanity:DoDelta(sanity_delta)
    end
end

local function ForceOvertimeFoodEffects(inst)
    if inst.modded_healthabsorption == nil then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if inst.modded_hungerabsorption == nil then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if inst.modded_sanityabsorption == nil then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.wolfgang_vetcurse and 0 or inst.modded_hungerabsorption or 1, 0)

    inst:ListenForEvent("oneat", oneat)
end

local function ForceUsualFoodEffects(inst)
    inst.components.eater:SetAbsorptionModifiers(inst.modded_healthabsorption, inst.modded_hungerabsorption, inst.modded_sanityabsorption)

    inst:RemoveEventCallback("oneat", oneat)
end

local function ForceWilsonCurse_On(inst, target)
    target:AddTag("wilson_vetcurse")

    target.wilson_vetcurse = true
end

local function ForceWilsonCurse_Off(inst, target)
    target:RemoveTag("wilson_vetcurse")
    target.wilson_vetcurse = nil
end

local function ForceWalterCurse_On(inst, target)
    target:AddTag("walter_vetcurse")
    target.walter_vetcurse = true

    target.walter_curse = target:ListenForEvent("attacked", function(target, data)
        if data ~= nil and data.damage ~= nil then
            local attacker = data.attacker.prefab ~= nil and data.attacker.prefab or "_projectile_attack"

            target.components.debuffable:AddDebuff("healthregenbuff_vetcurse_walter_curse" .. attacker, "healthregenbuff_vetcurse_walter_curse", { duration = data.damage * 0.1, negative_value = true })
        end
    end)
end

local function ForceWalterCurse_Off(inst, target)
    target:RemoveTag("walter_vetcurse")

    if target.walter_curse ~= nil then
        target.walter_curse:Cancel()
    end

    target.walter_curse = nil
    target.walter_vetcurse = nil
end

local function ForceWortoxCurse_On(inst, target)
    target:AddTag("wortox_vetcurse")
    target.wortox_vetcurse = true

    target.wortox_curse = target:ListenForEvent("killed", function(target, data)
        if data ~= nil and data.victim ~= nil and data.victim:IsValid() then
            local explosive = SpawnPrefab("explosive_vetscurse_soul")
            explosive.Transform:SetPosition(data.victim.Transform:GetWorldPosition())

            if data.victim.components.health ~= nil then
                explosive.damage = data.victim.components.health.maxhealth / 10
            end
        end
    end)
end

local function ForceWortoxCurse_Off(inst, target)
    target:RemoveTag("wortox_vetcurse")

    if target.wortox_curse ~= nil then
        target.wortox_curse:Cancel()
    end

    target.wortox_curse = nil
    target.wortox_vetcurse = nil
end

local function ForceMaxwellCurse_On(inst, target)
    target.maxwell_vetcurse = true
    target:AddTag("shambler_target")
    if target.maxwell_shambler == nil then
        local shambler = SpawnPrefab("um_shambler")
        target.maxwell_shambler = shambler
        shambler:LinkToPlayer(target)
        shambler.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function ForceMaxwellCurse_Off(inst, target)
    target.maxwell_vetcurse = nil
    target:RemoveTag("shambler_target")

    if target.maxwell_shambler ~= nil then
        target.maxwell_shambler.sg:GoToState("disssipate")
    end
end

local function ForceWillowCurse_On(inst, target)
    target:AddTag("willow_vetcurse")
    target.willow_vetcurse = true

    target.willow_curse_check = target:ListenForEvent("sanitydelta", function(target)
        if target.components.sanity ~= nil and target.components.sanity:GetPercent() < 0.4 then
            if target.willow_curse == nil then
                target.willow_curse = target:DoPeriodicTask(1, function(target)
                    if target.components.sanity ~= nil and target.components.sanity:GetPercent() <= 0.4 then
                        local x, y, z = target.Transform:GetWorldPosition()
                        local fires = TheSim:FindEntities(x, y, z, 3, { "um_shadowfire" })

                        if #fires > 0 then
                            fire:AdvanceStage()
                        else
                            SpawnPrefab("um_shadowfire").Transform:SetPosition(x, y, z)
                        end
                    end
                end)
            end
        else
            if target.willow_curse ~= nil then
                target.willow_curse:Cancel()
            end

            target.willow_curse = nil
        end
    end)
end

local function ForceWillowCurse_Off(inst, target)
    target:RemoveTag("willow_vetcurse")
    target.willow_vetcurse = nil

    if target.willow_curse_check ~= nil then
        target.willow_curse_check:Cancel()
    end

    if target.willow_curse ~= nil then
        target.willow_curse:Cancel()
    end

    target.willow_curse = nil
end

local function ForceWarlyCurse_On(inst, target)
    target:AddTag("warly_vetcurse")
    target.warly_vetcurse = true

    target.warly_curse = target:ListenForEvent("onpreeat", function(target, data)
        if target:HasTag("vetcurse") and data.food ~= nil and data.food.components.edible ~= nil and data.food.components.edible.hungervalue ~= nil then
            local overstuffed = target.components.hunger.current + (data.food.components.edible.hungervalue * target.components.eater.hungerabsorption)
            local maxhunger = target.components.hunger.max
            local clampvalue = overstuffed - maxhunger

            if target.components.grogginess ~= nil then
                if overstuffed > maxhunger then
                    if target.components.grogginess:HasGrogginess() then
                        target.components.talker:Say(GetString(target, "ANNOUNCE_OVER_EAT", "OVERSTUFFED"))
                        target.components.grogginess:MaximizeGrogginess()
                    else
                        target.components.talker:Say(GetString(target, "ANNOUNCE_OVER_EAT", "STUFFED"))
                        local delta = math.clamp(clampvalue / 10, 0.1, 2.9)
                        target.components.grogginess:AddGrogginess(delta)
                    end
                end
            end
        end
    end)
end

local function ForceWarlyCurse_Off(inst, target)
    target:RemoveTag("warly_vetcurse")
    target.warly_vetcurse = nil

    if target.warly_curse ~= nil then
        target.warly_curse:Cancel()
    end

    target.warly_curse = nil
end

local function ForceWinkyCurse_On(inst, target)
    target:AddTag("winky_vetcurse")
    target.winky_vetcurse = true

    target.winky_curse = target:ListenForEvent("dropitem", function(target)
        target.components.health:DoDelta(-5)
    end)
end

local function ForceWinkyCurse_Off(inst, target)
    target:RemoveTag("winky_vetcurse")
    target.winky_vetcurse = nil

    if target.winky_curse ~= nil then
        target.winky_curse:Cancel()
    end

    target.winky_curse = nil
end

local function ResetSleepyCD(target)
    target.vetcurse_sleepycd = nil
end

local function ForceWickerbottomCurse_On(inst, target)
    target:AddTag("wickerbottom_vetcurse")
    target.wickerbottom_vetcurse = true

    target.wickerbottom_curse = target:DoPeriodicTask(1, function(target)
        if target.vetcurse_sleepiness == nil then
            target.vetcurse_sleepiness = 0
        end
        if target.components.grogginess ~= nil then
            if target.sg:HasStateTag("sleeping") or
                target.sg:HasStateTag("bedroll") or
                target.sg:HasStateTag("tent") or
                target.sg:HasStateTag("waking") or
                target.sg:HasStateTag("knockout") then
                if target.vetcurse_sleepiness > 0 then
                    target.vetcurse_sleepiness = target.vetcurse_sleepiness - ((1 / target.components.grogginess:GetResistance()) * 30)
                elseif target.vetcurse_sleepiness < 0 then
                    target.vetcurse_sleepiness = 0
                end
            else
                if target.vetcurse_sleepiness < 600 then
                    target.vetcurse_sleepiness = target.vetcurse_sleepiness + (1 * target.components.grogginess:GetResistance())
                end

                if target.vetcurse_sleepycd == nil then
                    if target.vetcurse_sleepiness > 480 then
                        target:PushEvent("yawn", { grogginess = 4, knockoutduration = target.vetcurse_sleepiness / 50 })
                    elseif target.vetcurse_sleepiness <= 480 and target.vetcurse_sleepiness > 360 then
                        target:PushEvent("yawn", { grogginess = 2, knockoutduration = 0 })
                    elseif target.vetcurse_sleepiness <= 360 and target.vetcurse_sleepiness > 280 then
                        target:PushEvent("yawn", { grogginess = 0, knockoutduration = 0 })
                    end

                    if target.vetcurse_sleepiness > 280 then
                        target.vetcurse_sleepycd = target:DoTaskInTime(240 / (target.vetcurse_sleepiness / 100), ResetSleepyCD)
                    end
                end
            end

            print(target.vetcurse_sleepiness)
        end
    end)
end

local function ForceWickerbottomCurse_Off(inst, target)
    target:RemoveTag("wickerbottom_vetcurse")
    target.wickerbottom_vetcurse = nil

    if target.wickerbottom_curse ~= nil then
        target.wickerbottom_curse:Cancel()
    end

    if target.vetcurse_sleepycd ~= nil then
        target.vetcurse_sleepycd:Cancel()
    end

    target.vetcurse_sleepycd = nil

    target.wickerbottom_curse = nil
end

local SPAWN_DIST = 30

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function GetSpawnPoint(pt)
    if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
        pt = FindNearbyLand(pt, 1) or pt
    end
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true, true, NoHoles)
    if offset ~= nil then
        offset.x = offset.x + pt.x
        offset.z = offset.z + pt.z
        return offset
    end
end

local function MakeAKrampusForPlayer(player)
    local pt = player:GetPosition()
    local spawn_pt = GetSpawnPoint(pt)
    if spawn_pt ~= nil then
        local kramp = SpawnPrefab("krampus")
        kramp.Physics:Teleport(spawn_pt:Get())
        kramp:FacePoint(pt)
        kramp.spawnedforplayer = player
        kramp:ListenForEvent("onremove", function() kramp.spawnedforplayer = nil end, player)
        return kramp
    end
end

local function ForceWixieCurse_On(inst, target)
    target:AddTag("wixie_vetcurse")
    target.wixie_vetcurse = true

    target.wixie_curse = target:ListenForEvent("killed", function(target, data)
        if data ~= nil and data.victim ~= nil and data.victim.prefab ~= nil then
            local naughtiness = NAUGHTY_VALUE[data.victim.prefab]
            if naughtiness ~= nil then
                if not (data.victim.prefab == "pigman" and
                        data.victim.components.werebeast ~= nil and
                        data.victim.components.werebeast:IsInWereState()) then
                    local naughty_val = FunctionOrValue(naughtiness, target, data)
                    if math.random() > (1 - naughty_val / 50) then
                        MakeAKrampusForPlayer(target)
                    end
                end
            end
        end
    end)
end

local function ForceWixieCurse_Off(inst, target)
    target:RemoveTag("wixie_vetcurse")
    target.wixie_vetcurse = nil

    if target.wixie_curse ~= nil then
        target.wixie_curse:Cancel()
    end

    target.wixie_curse = nil
end

local MUTANT_BIRD_MUST_HAVE = { "bird_mutant" }
local MUTANT_BIRD_MUST_NOT_HAVE = { "INLIMBO" }


local BIRDBLOCKER_TAGS = { "birdblocker" }
local function customcheckfn(pt)
    return #(TheSim:FindEntities(pt.x, 0, pt.z, 4, BIRDBLOCKER_TAGS)) == 0 or false
end

local function SpawnBirds(target, angle, prefab)
    if target and target:IsValid() and not target.components.health:IsDead() then
        local pos = Vector3(target.Transform:GetWorldPosition())
        local bird = SpawnPrefab(prefab)

        local newpos = FindWalkableOffset(pos, angle + (math.random() * PI / 4), 16 + math.random() * 8, 16, nil, nil, customcheckfn, nil, nil)

        if newpos then
            pos = pos + newpos
            pos.y = 15
            bird.Transform:SetPosition(pos.x, pos.y, pos.z)
            bird.components.entitytracker:TrackEntity("swarmTarget", target)
            bird:PushEvent("arrive")

            if prefab == "bird_mutant" then
                bird.components.locomotor.walkspeed = TUNING.MUTANT_BIRD_WALK_SPEED * 3
                bird.components.locomotor.runspeed = TUNING.MUTANT_BIRD_WALK_SPEED * 3
            else
                bird.components.locomotor.walkspeed = TUNING.MUTANT_BIRD_WALK_SPEED * 2
                bird.components.locomotor.runspeed = TUNING.MUTANT_BIRD_WALK_SPEED * 2
            end

            bird:ListenForEvent("isnight", function(bird) bird.components.health:Kill() end)
            bird:ListenForEvent("isday", function(bird) bird.components.health:Kill() end)
        end
    end
end

local function ForceWoodieCurse_On(inst, target)
    target:AddTag("woodie_vetcurse")
    target.woodie_vetcurse = true

    target.woodie_curse = target:DoPeriodicTask(15, function(target)
        if TheWorld.state.isdusk and not target.components.health:IsDead() then
            local x, y, z = target.Transform:GetWorldPosition()

            local ents = TheSim:FindEntities(x, y, z, 30, MUTANT_BIRD_MUST_HAVE, MUTANT_BIRD_MUST_NOT_HAVE)

            if #ents < 12 then
                local currentpos = Vector3(target.Transform:GetWorldPosition())
                local angle = math.random() * 2 * PI

                for i = 1, math.random(2, 4) do
                    target:DoTaskInTime(math.random() * 0.5, function() SpawnBirds(target, angle, "bird_mutant") end)
                end
                for i = 1, math.random(1, 2) do
                    target:DoTaskInTime(math.random() * 0.5, function() SpawnBirds(target, angle, "bird_mutant_spitter") end)
                end
            end
        end
    end)
end

local function ForceWoodieCurse_Off(inst, target)
    target:RemoveTag("woodie_vetcurse")
    target.woodie_vetcurse = nil

    if target.woodie_curse ~= nil then
        target.woodie_curse:Cancel()
    end

    target.woodie_curse = nil
end

local function ForceWolfgangCurse_On(inst, target)
    target:AddTag("wolfgang_vetcurse")

    target.wolfgang_vetcurse = true

    target.components.eater:SetAbsorptionModifiers(0, target.wolfgang_vetcurse and 0 or target.modded_hungerabsorption or 1, 0)

    target.wolfgang_curse = target:ListenForEvent("hungerdelta", function(target, data)
        if target:HasTag("vetcurse") and target.components.hunger ~= nil then
            local hunger_percent = target.components.hunger:GetPercent()
            local key = "Wolfgang_Curse_DebuffKey"

            if hunger_percent > 0.5 then
                if target.components.combat ~= nil then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
                end

                if target.components.locomotor then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(target, key)
                end
            else
                if target.components.combat ~= nil then
                    target.components.combat.externaldamagemultipliers:SetModifier(target, (.5 - hunger_percent))
                end

                if hunger_percent < 0.3 then
                    if target.components.locomotor then
                        target.components.locomotor:SetExternalSpeedMultiplier(target, key, 1 - (.3 - hunger_percent))
                    end
                end
            end
        end
    end)
end

local function ForceWolfgangCurse_Off(inst, target)
    target:RemoveTag("wolfgang_vetcurse")
    target.wolfgang_vetcurse = nil

    target.components.eater:SetAbsorptionModifiers(0, target.wolfgang_vetcurse and 0 or target.modded_hungerabsorption or 1, 0)

    local key = "Wolfgang_Curse_DebuffKey"

    if target.components.combat ~= nil then
        target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    end

    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, key)
    end

    if target.wolfgang_curse ~= nil then
        target.wolfgang_curse:Cancel()
    end

    target.wolfgang_curse = nil
end

local function ForceWandaCurse_On(inst, target)
    target:AddTag("wanda_vetcurse")

    target.wanda_vetcurse = true

    target.wanda_curse = target:ListenForEvent("killed", function(target, data)
        if target:HasTag("vetcurse") then
            if data ~= nil and data.victim ~= nil and data.victim ~= nil then
                if not data.victim:HasTag("shadow_aligned") and not data.victim:HasTag("lunar_aligned") then
                    local sanity = target.components.sanity ~= nil and target.components.sanity:GetPercent()

                    if sanity ~= nil and (1 - sanity) < math.random() then
                        local shadow = math.random() > 0.5 and "crawlingnightmare" or "nightmarebeak"
                        SpawnPrefab(shadow).Transform:SetPosition(data.victim.Transform:GetWorldPosition())
                    end
                end
            end
        end
    end, target)
end

local function ForceWandaCurse_Off(inst, target)
    target:RemoveTag("wanda_vetcurse")
    target.wanda_vetcurse = nil

    if target.wanda_curse ~= nil then
        target.wanda_curse:Cancel()
    end

    target.wanda_curse = nil
end

local function ForceWathgrithrCurse_On(inst, target)
    target:AddTag("wathgrithr_vetcurse")

    target.wathgrithr_vetcurse = true
end

local function ForceWathgrithrCurse_Off(inst, target)
    target:RemoveTag("wathgrithr_vetcurse")
    target.wathgrithr_vetcurse = nil
end

local function ForceWesCurse_On(inst, target)
    target:AddTag("wes_vetcurse")

    target.wes_vetcurse = true
end

local function ForceWesCurse_Off(inst, target)
    target:RemoveTag("wes_vetcurse")
    target.wes_vetcurse = nil
end

local function WendyCurse(player)
    if player.components.health ~= nil and player.components.sanity ~= nil and not player.components.sanity.inducedinsanity and player.components.health:GetPercent() > player.components.sanity:GetPercent() then
        player.components.health:SetPercent(player.components.sanity:GetPercent())
    end
end

local function ForceWendyCurse_On(inst, target)
    target:AddTag("wendy_vetcurse")

    target:ListenForEvent("sanitydelta", WendyCurse, target)
    --target:ListenForEvent("healthdelta", WendyCurse, target)

    target.wendy_vetcurse = true
end

local function ForceWendyCurse_Off(inst, target)
    target:RemoveTag("wendy_vetcurse")

    target:RemoveEventCallback("sanitydelta", WendyCurse, target)
    target:RemoveEventCallback("healthdelta", WendyCurse, target)

    target.wendy_vetcurse = nil
end

local skull =
{
    {
        name = "wilson_vetskull",
        anim = "idle",
        attachfn = ForceWilsonCurse_On,
        detachfn = ForceWilsonCurse_Off,
        description = STRINGS.VETSKULL.WILSON,
        vestiges = 1,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "walter_vetskull",
        anim = "idle",
        attachfn = ForceWalterCurse_On,
        detachfn = ForceWalterCurse_Off,
        description = STRINGS.VETSKULL.WALTER,
        vestiges = 2,
        music = "UMMusic/music/follow_me_woby_flat",
    },
    {
        name = "wortox_vetskull",
        anim = "idle",
        attachfn = ForceWortoxCurse_On,
        detachfn = ForceWortoxCurse_Off,
        description = STRINGS.VETSKULL.WORTOX,
        vestiges = 1,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "maxwell_vetskull",
        anim = "idle",
        attachfn = ForceMaxwellCurse_On,
        detachfn = ForceMaxwellCurse_Off,
        description = STRINGS.VETSKULL.MAXWELL,
        vestiges = 5,
        music = "dontstarve/music/gramaphone_ragtime",
    },
    {
        name = "willow_vetskull",
        anim = "idle",
        attachfn = ForceWillowCurse_On,
        detachfn = ForceWillowCurse_Off,
        description = STRINGS.VETSKULL.WILLOW,
        vestiges = 1,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "warly_vetskull",
        anim = "idle",
        attachfn = ForceWarlyCurse_On,
        detachfn = ForceWarlyCurse_Off,
        description = STRINGS.VETSKULL.WARLY,
        vestiges = 1,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "winky_vetskull",
        anim = "idle",
        attachfn = ForceWinkyCurse_On,
        detachfn = ForceWinkyCurse_Off,
        description = STRINGS.VETSKULL.WINKY,
        vestiges = 4,
        music = "UMMusic/gramaphone_record/winky_theme",
    },
    {
        name = "wickerbottom_vetskull",
        anim = "idle",
        attachfn = ForceWickerbottomCurse_On,
        detachfn = ForceWickerbottomCurse_Off,
        description = STRINGS.VETSKULL.WICKERBOTTOM,
        vestiges = 3,
        music = "dontstarve/music/music_FE_wickerbottom",
    },
    {
        name = "wixie_vetskull",
        anim = "idle",
        attachfn = ForceWixieCurse_On,
        detachfn = ForceWixieCurse_Off,
        description = STRINGS.VETSKULL.WIXIE,
        vestiges = 1,
        music = "UMMusic/music/wixie_the_delinquent",
    },
    {
        name = "woodie_vetskull",
        anim = "idle",
        attachfn = ForceWoodieCurse_On,
        detachfn = ForceWoodieCurse_Off,
        description = STRINGS.VETSKULL.WOODIE,
        vestiges = 1,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "wolfgang_vetskull",
        anim = "idle",
        attachfn = ForceWolfgangCurse_On,
        detachfn = ForceWolfgangCurse_Off,
        description = STRINGS.VETSKULL.WOLFGANG,
        vestiges = 2,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "wanda_vetskull",
        anim = "idle",
        attachfn = ForceWandaCurse_On,
        detachfn = ForceWandaCurse_Off,
        description = STRINGS.VETSKULL.WANDA,
        vestiges = 1,
        music = "dontstarve/music/music_FE_wanda",
    },
    {
        name = "wathgrithr_vetskull",
        anim = "idle",
        attachfn = ForceWathgrithrCurse_On,
        detachfn = ForceWathgrithrCurse_Off,
        description = STRINGS.VETSKULL.WATHGRITHR,
        vestiges = 2,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "wes_vetskull",
        anim = "idle",
        attachfn = ForceWesCurse_On,
        detachfn = ForceWesCurse_Off,
        description = STRINGS.VETSKULL.WES,
        vestiges = 4,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
    {
        name = "wendy_vetskull",
        anim = "idle",
        attachfn = ForceWendyCurse_On,
        detachfn = ForceWendyCurse_Off,
        description = STRINGS.VETSKULL.WENDY,
        vestiges = 4,
        music = "dontstarve/music/music_FE_survivorsguideone",
    },
}

--[[
Wilson ?
Wendy
WX78
Winona
Wurt
Webber
Wathom

]]

local function AttachCurse(inst, target)
    if target.components.combat ~= nil then
        --target.components.combat.externaldamagemultipliers:SetModifier(inst, .75)    Effect Removed
        target.vetcurse = true

        if target.components ~= nil and target.components.oldager ~= nil then
            ForceToTakeMoreTime(target)
        else
            ForceToTakeMoreDamage(target)
        end

        ForceToTakeMoreHunger(target)
        ForceOvertimeFoodEffects(target)
        target:AddTag("vetcurse")

        target:DoTaskInTime(3, function()
            if target.wilson_vetcurse then
                ForceWilsonCurse_On(inst, target)
            end

            if target.walter_vetcurse then
                ForceWalterCurse_On(inst, target)
            end

            if target.wortox_vetcurse then
                ForceWortoxCurse_On(inst, target)
            end

            if target.maxwell_vetcurse then
                ForceMaxwellCurse_On(inst, target)
            end

            if target.willow_vetcurse then
                ForceWillowCurse_On(inst, target)
            end

            if target.warly_vetcurse then
                ForceWarlyCurse_On(inst, target)
            end

            if target.winky_vetcuse then
                ForceWinkyCurse_On(inst, target)
            end

            if target.wickerbottom_vetcurse then
                ForceWickerbottomCurse_On(inst, target)
            end

            if target.wixie_vetcurse then
                ForceWixieCurse_On(inst, target)
            end

            if target.woodie_vetcurse then
                ForceWoodieCurse_On(inst, target)
            end

            if target.wolfgang_vetcurse then
                ForceWolfgangCurse_On(inst, target)
            end

            if target.wanda_vetcurse then
                ForceWandaCurse_On(inst, target)
            end

            if target.wathgrithr_vetcurse then
                ForceWathgrithrCurse_On(inst, target)
            end

            if target.wes_vetcurse then
                ForceWesCurse_On(inst, target)
            end

            if target.wendy_vetcurse then
                ForceWendyCurse_On(inst, target)
            end
        end)

        target:ListenForEvent("respawnfromghost", function()
            target:DoTaskInTime(3, function(target)
                if TUNING.DSTU.VETCURSE ~= "off" then
                    target.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
                end
            end)
        end, target)

        target:ListenForEvent("ms_playerseamlessswaped", function()
            target:DoTaskInTime(3, function(target)
                if TUNING.DSTU.VETCURSE ~= "off" then
                    target.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
                end
            end)
        end, target)
    end
end

local function DetachCurse(inst, target)
    if target.components.combat ~= nil then
        --target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        --target.vetcurse = false

        if target.components ~= nil and target.components.oldager ~= nil then --taking a guess thats what her tag is, I swear, I actually don't know
            ForceToTakeUsualTime(target)
        else
            ForceToTakeUsualDamage(target)
        end

        ForceToTakeUsualHunger(target)
        ForceUsualFoodEffects(target)
        target:RemoveTag("vetcurse")


        for i, v in pairs(skull) do
            if target:HasTag(v.name) then
                v.detachfn(inst, target)
            end
        end
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, prefabs)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        --[[inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)]]

        --target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end


    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        --target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name), priority = priority })
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff.keepondespawn = true


        return inst
    end

    return Prefab("buff_" .. name, fn, nil, prefabs)
end

local BigPopupDialogScreen = require "screens/popupdialog"

local function ToggleCursee(inst)
    local player = inst.Cursee:value()
    if player == ThePlayer then
        local function acceptance()
            TheFrontEnd:PopScreen()
            TheFocalPoint.SoundEmitter:KillSound("skull_music")
        end
        local title = STRINGS.VETSKULL_TITLE
        local bodytext = STRINGS.VETSKULL.DEFAULT .. "\n" .. inst.skulldef_client.description --inst.SkullDescription
        local yes_box = { text = STRINGS.VETS_OK, cb = acceptance }

        local bpds = BigPopupDialogScreen(title, bodytext, { yes_box })
        bpds.title:SetPosition(0, 90, 0)
        bpds.text:SetPosition(0, -15, 0)

        TheFrontEnd:PushScreen(bpds)
        TheFocalPoint.SoundEmitter:PlaySound(inst.skull_music, "skull_music")
    end
end

local function SkullTalk(inst, doer)
    if doer ~= nil and inst.skulldef ~= nil and inst.skulldef.description ~= nil then
        inst.valid_cursee_id = doer.userid

        --inst.SkullDescription:set_local(inst.skulldef.description)
        --inst.SkullDescription:set(inst.skulldef.description)

        inst.Cursee:set_local(doer)
        inst.Cursee:set(doer)


        --[[inst.talknum = 0
		
		for i = 1, 4 do
			inst:DoTaskInTime(3 * (i - 1), function(inst)
				inst.components.talker:Say(inst.skulldef.description[i])
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt")
			end)
		end]]
    end
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("SetCurseedirty", ToggleCursee)
end

local function skull_fn(skull_def)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst:AddTag("vetskull")

    inst.skulldef_client = skull_def
    inst.skull_music = skull_def.music

    inst.Cursee = net_entity(inst.GUID, "SetCursee.plyr", "SetCurseedirty")

    inst:DoTaskInTime(0, RegisterNetListeners)

    inst.AnimState:SetBank("um_vetskull")
    inst.AnimState:SetBuild("um_vetskull")
    inst.AnimState:PlayAnimation(skull_def.name, true)
    inst.AnimState:SetScale(2.5, 2.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("talker")

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "VET_SKULL"

    inst:AddComponent("um_activatable_item")
    inst.components.um_activatable_item.act_fn = SkullTalk

    inst.skulldef = skull_def

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem.atlasname = "images/inventoryimages/"..skull_def.name..".xml"

    return inst
end

local skull_prefabs = {}
for _, v in ipairs(skull) do
    table.insert(skull_prefabs, Prefab(v.name, function() return skull_fn(v) end --[[, assets, prefabs]]))
end

return MakeBuff("vetcurse", AttachCurse, nil, DetachCurse, nil, 1),
    unpack(skull_prefabs)
