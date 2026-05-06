-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------


local function smallfury_attach(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:SetModifier(inst, 0.05)
    end
end

local function smallfury_detatch(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
end

local function medfury_attach(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:SetModifier(inst, 0.1)
    end
end

local function medfury_detatch(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
end

local function largefury_attach(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:SetModifier(inst, 0.25)
    end
end

local function largefury_detatch(inst, target)
    if target.components.health ~= nil then
        target.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
end

local function OffCoolDown(target)
    target._cdtask = nil
end

local combat_health = {"_health","_combat"}
local arc_player = {"player","arcgrounded"}

local function FindEnemiesNearbyAndShockThem(attacker,target,ShockAGAIN)
	local x,y,z = target.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,4,combat_health,arc_player)
	for i,v in ipairs(ents) do
		if not v.components.health:IsDead() then
			local dist = math.sqrt(target:GetDistanceSqToInst(v))
			v:DoTaskInTime(dist/5,function(v)
				if v.components.health and not v.components.health:IsDead() and not v:HasTag("arcgrounded") then -- we check these again because they could have already died or been shocked once
					local mult = 2-dist
					mult = math.clamp(mult,0.1,1.25)

					local damage = 51*mult
					v.components.combat:GetAttacked(attacker, damage, nil, "electric")
					v:AddTag("arcgrounded")
					ShockAGAIN(attacker,v,ShockAGAIN)
					SpawnPrefab("electricchargedfx").Transform:SetPosition(v.Transform:GetWorldPosition())
					v:DoTaskInTime(3,function(v) v:RemoveTag("arcgrounded") end)
				end
			end)
		end
	end
end

local function taser_onblockedorattacked(owner, data) -- Modified WX78 function
	local attacker = data.attacker
    if (data ~= nil and attacker ~= nil and not data.redirected) and owner._cdtask == nil then
		if owner.um_electric_retaliate_damage == 10 then
			owner._cdtask = owner:DoTaskInTime(0.3, OffCoolDown)
		end
        if attacker.components.combat ~= nil
                and (attacker.components.health ~= nil and not attacker.components.health:IsDead())
                and (attacker.components.inventory == nil or not attacker.components.inventory:IsInsulated())
                and (data.weapon == nil or 
                        (data.weapon.components.projectile == nil
                        and (data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil))
                ) then

            SpawnPrefab("electrichitsparks"):AlignToTarget(attacker, owner, true)

            local damage_mult = 1
            if not IsEntityElectricImmune(attacker) then
				damage_mult = TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * attacker:GetWetMultiplier()
            end

			attacker:PushEvent("electrocute", { attacker = owner, stimuli = "electric" })
            attacker.components.combat:GetAttacked(owner, damage_mult * owner.um_electric_retaliate_damage, nil, "electric")
			
			
			if owner.um_electric_retaliate_damage == 51 then -- only zaspberry parfait number
				if attacker:IsValid() then
					FindEnemiesNearbyAndShockThem(owner,attacker,FindEnemiesNearbyAndShockThem)
				end
				-- Dont allow arcing back upon oneself
				attacker:AddTag("arcgrounded")
				attacker:DoTaskInTime(3,function(attacker) attacker:RemoveTag("arcgrounded") end)
			end
        end
    end
end

local function attachretaliationdamage(inst, owner)
	if inst.prefab == "buff_electricretaliation" then
		owner.um_electric_retaliate_damage = 51
	elseif inst.prefab == "buff_electricretaliationmedium" then
		owner.um_electric_retaliate_damage = 34
	else
		owner.um_electric_retaliate_damage = 10 -- would like to pass this to the function above if possible
	end

	
    owner:ListenForEvent("attacked", taser_onblockedorattacked, owner)
	
    SpawnPrefab("electricchargedfx"):SetTarget(owner)
end

local function electric_extend(inst, target)
    SpawnPrefab("electricchargedfx"):SetTarget(target)
end

local function removeretaliationdamageretaliationdamage(inst, target)
    target:RemoveEventCallback("attacked", taser_onblockedorattacked, target)
end

local function OnHitOtherBoomberry(inst, data)
    local other, damage = data.target, data.damage
    if other and damage and not other.um_boomberry_exploded then
        local x, y, z = other.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 2, { "_health", "_combat" }, { "player", "companion", "INLIMBO", "flight", "invisible", "notarget", "noattack", "wall" })
        local damage = damage * .75
        if other.SoundEmitter then other.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap") end
        for i, v in ipairs(ents) do
            local leader = v.components.follower and v.components.follower.leader
            local itemleader = leader and leader.components.inventoryitem and leader.components.inventoryitem:GetGrandOwner()
            if not v.components.health:IsDead() and v.components.combat:CanBeAttacked() and (not leader or itemleader and not itemleader:HasTag("player") or not leader.components.inventoryitem and not leader:HasTag("player"))
                and v ~= inst and v ~= other then
                local damageredirecttarget = v.components.combat.redirectdamagefn ~= nil and v.components.combat.redirectdamagefn(v, inst, damage) or nil
                v.um_boomberry_exploded = true
                if damageredirecttarget then --Fix by Discord user mlz2023_34253
                    damageredirecttarget.um_boomberry_exploded = true
                    damageredirecttarget:DoTaskInTime(.3, function() damageredirecttarget.um_boomberry_exploded = nil end)
                end
                v.components.combat:GetAttacked(inst, damage)
                v:DoTaskInTime(.3, function(v) v.um_boomberry_exploded = nil end)
            end
        end
        SpawnPrefab("blueberryexplosion").Transform:SetPosition(other.Transform:GetWorldPosition())
        local puddle = SpawnPrefab("blueberrypuddle")
        puddle.Transform:SetPosition(other.Transform:GetWorldPosition())
        if inst:HasTag("player") then puddle.playermade = true end
    end
end

local function attachboomberry(inst, target)
    target:ListenForEvent("onhitother", OnHitOtherBoomberry, target)
end

local function removeboomberry(inst, target)
    target:RemoveEventCallback("onhitother", OnHitOtherBoomberry, target)
end

local function OnHitOtherFreeze(inst, data)
    local other = data.target
    if other ~= nil then
        if not (other.components.health ~= nil and other.components.health:IsDead()) then
            if other.components.freezable ~= nil then
                other.components.freezable:AddColdness(1)
            end
        end
        if other.components.freezable ~= nil then
            other.components.freezable:SpawnShatterFX()
        end
    end
end

local function attachfrozenness(inst, target)
    target:ListenForEvent("onhitother", OnHitOtherFreeze, target)
end

local function removefrozenness(inst, target)
    target:RemoveEventCallback("onhitother", OnHitOtherFreeze, target)
end

local function californiaking_attach(inst, target)
    target:DoTaskInTime(4, function(target)
        if not target:HasTag("californiaking") then
            target:AddTag("californiaking")
        end
    end)
end

local function californiaking_extend(inst, target)
    --SpawnPrefab("electricchargedfx"):SetTarget(target)
end

local function californiaking_detach(inst, target)
    if target:HasTag("californiaking") then
        target:RemoveTag("californiaking")
    end
end

local function kbimmune_attach(inst, target)
    target:DoTaskInTime(4, function(target)
        if not target:HasTag("foodknockbackimmune") then
            target:AddTag("foodknockbackimmune")
        end
    end)
end

local function kbimmune_extend(inst, target)
    --SpawnPrefab("electricchargedfx"):SetTarget(target)
end

local function kbimmune_detach(inst, target)
    if target:HasTag("foodknockbackimmune") then
        target:RemoveTag("foodknockbackimmune")
    end
end

local function largehungerslow_attach(inst, target)
    target.components.hunger.burnratemodifiers:SetModifier(inst, .5)
end

local function largehungerslow_extend(inst, target)
    target.components.hunger.burnratemodifiers:RemoveModifier(inst)
    target.components.hunger.burnratemodifiers:SetModifier(inst, .5)
end

local function largehungerslow_detach(inst, target)
    target.components.hunger.burnratemodifiers:RemoveModifier(inst)
end

local function stantonslumber_attach(inst, target)
    local stanton = FindEntity(target, 20, nil, { "stanton" })
    if stanton ~= nil then
        if stanton.contestent == target then
            if target.stantonslumberstack == nil then
                target.stantonslumberstack = 0
            else
                if target.components.debuffable ~= nil and target.components.debuffable:HasDebuff("buff_sleepresistance") then
                    target.stantonslumberstack = target.stantonslumberstack + 0.05
                else
                    target.stantonslumberstack = target.stantonslumberstack + 0.1
                end
            end
            if math.random() < target.stantonslumberstack then
                if target.components.grogginess ~= nil then
                    target.components.grogginess:AddGrogginess(34, 5)
                    local stanton = FindEntity(target, 10, nil, { "stanton" })
                    if stanton ~= nil then
                        stanton:AddTag("won")
                    end
                    target:DoTaskInTime(4, function(target)
                        target.components.grogginess:SubtractGrogginess(-30)
                        target.components.grogginess:ComeTo()
                    end)
                end
            else
                if target.components.grogginess ~= nil and target.components.grogginess.grog_amount == 0 then
                    target.components.grogginess:AddGrogginess(1, 1)
                end
            end
        else
            stanton.TellThemRules(stanton)
            if target.components.health ~= nil then
                target.components.health:DoDelta(-20)
            end
        end
    else
        local stanton = TheSim:FindFirstEntityWithTag("stanton")
        if stanton ~= nil then
            stanton.TellThemRules(stanton)
        end
        target.components.health:DoDelta(-20)
    end
end

local function stantonslumber_detach(inst, target)
    target.stantonslumberstack = nil
end

local function hypercourage_attach(inst, target)
    target.components.sanity.neg_aura_modifiers:SetModifier(inst, 0)
end

local function hypercourage_extend(inst, target)

end

local function hypercourage_detach(inst, target)
    target.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
end

local function stantonslumber_detach(inst, target)
    target.stantonslumberstack = nil
end

local function smallcourage_attach(inst, target)
    target.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.5)
end

local function smallcourage_extend(inst, target)

end

local function smallcourage_detach(inst, target)
    target.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
end

local function OnTickAmuse(inst, target)
    if target.components.sanity ~= nil and not target:HasTag("playerghost") then
        local amount = 0
        if inst.tier ~= nil then
            amount = inst.tier
        end
        target.components.sanity:DoDelta(amount, nil, "amusementcorn")
    end
end

local function OnAmuseAttach(inst, target)
    if target.tempamusetier ~= nil then
        inst.tier = target.tempamusetier + 1
    end
    inst.task = inst:DoPeriodicTask(1, OnTickAmuse, nil, target)
end

local function OnAmuseDone(inst, data)
    if inst.tier ~= nil then
        inst.tier = nil
    end
    inst.task:Cancel()
end

local function OnAmuseExtended(inst, target)
    if inst.tier ~= nil then
        inst.tier = nil
    end
    inst.task:Cancel()
    if target.tempamusetier ~= nil then
        inst.tier = target.tempamusetier + 1
    end
    inst.task = inst:DoPeriodicTask(1, OnTickAmuse, nil, target)
end
-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local electricnames = {"electricretaliation","electricretaliationlesser","electricretaliationmedium"}
local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, nospeech)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        if not nospeech then
			local announcename = name
			if table.contains(electricnames,name) then
				announcename = "electricretaliation"
			end
            target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_" .. string.upper(announcename), priority = priority })
        end
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)
        if not nospeech then
			local announcename = name
			if table.contains(electricnames,name) then
				announcename = "electricretaliation"
			end
            target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_" .. string.upper(announcename), priority = priority })
        end
        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end
        if not nospeech then
			local announcename = name
			if table.contains(electricnames,name) then
				announcename = "electricretaliation"
			end
            target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_" .. string.upper(announcename), priority = priority })
        end
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
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab("buff_" .. name, fn, nil)
end

return MakeBuff("electricretaliation", attachretaliationdamage, electric_extend, removeretaliationdamageretaliationdamage, 12*60, 2, { "electrichitsparks", "electricchargedfx" }),
	MakeBuff("electricretaliationmedium", attachretaliationdamage, electric_extend, removeretaliationdamageretaliationdamage, 4*60, 2, { "electrichitsparks", "electricchargedfx" }),
	MakeBuff("electricretaliationlesser", attachretaliationdamage, electric_extend, removeretaliationdamageretaliationdamage, 60, 2, { "electrichitsparks", "electricchargedfx" }),
    MakeBuff("boomberryattacks", attachboomberry, nil, removeboomberry, TUNING.BUFF_ELECTRICATTACK_DURATION, 2),
    MakeBuff("frozenfury", attachfrozenness, nil, removefrozenness, TUNING.BUFF_ELECTRICATTACK_DURATION, 2),
    MakeBuff("knockbackimmune", kbimmune_attach, kbimmune_extend, kbimmune_detach, TUNING.BUFF_ATTACK_DURATION, 2),
    MakeBuff("californiaking", californiaking_attach, californiaking_extend, californiaking_detach, TUNING.BUFF_ATTACK_DURATION * 8, 2),
    MakeBuff("largehungerslow", largehungerslow_attach, largehungerslow_extend, largehungerslow_detach, TUNING.BUFF_ATTACK_DURATION * 8, 2),
    MakeBuff("stantonslumber", stantonslumber_attach, stantonslumber_attach, stantonslumber_detach, TUNING.BUFF_ATTACK_DURATION, 2, true),
    MakeBuff("hypercourage", hypercourage_attach, hypercourage_extend, hypercourage_detach, 30, 2, true),
    MakeBuff("amusementcorn", OnAmuseAttach, OnAmuseExtended, OnAmuseDone, 15, 2, true),
    MakeBuff("smallcourage", smallcourage_attach, smallcourage_extend, smallcourage_detach, 8 * 60, 2, true),
    MakeBuff("furious1", smallfury_attach, nil, smallfury_detatch, 5, true, true),
    MakeBuff("furious2", medfury_attach, nil, medfury_detatch, 5, true, true),
    MakeBuff("furious3", largefury_attach, nil, largefury_detatch, 5, true, true)
