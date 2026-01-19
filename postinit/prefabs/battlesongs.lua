local env = env
GLOBAL.setfenv(1, GLOBAL)

--------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------
local melodist_must_tags = {"player", "lunarmelodist"}
local melodist_no_tags = { "ghost", "playerghost", "INLIMBO" }

local function IsNearLunarMelodist(target)
    if target:HasTag("lunarmelodist") then
        return true
    end

    local lunarmelodist = FindEntity(target, (TUNING.BATTLESONG_ATTACH_RADIUS + 1), nil, melodist_must_tags, melodist_no_tags, nil)
    return lunarmelodist ~= nil and true or false
end

local function AddDurabilityMult(inst, equip, target)
    if equip ~= nil and equip.components.weapon ~= nil then 
        -- Check for armor component to account for the shields which do not have finiteuses 
        if  equip.components.finiteuses ~= nil or equip.components.armor ~= nil then 
            --local lunarMult = 1
            --if IsNearLunarMelodist(target) then 
                --lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_DURABILITY_MULT_SINGER 
            --end
            --equip.components.weapon.attackwearmultipliers:SetModifier(inst, TUNING.BATTLESONG_DURABILITY_MOD * lunarMult)
            equip.components.weapon.attackwearmultipliers:SetModifier(inst, TUNING.BATTLESONG_DURABILITY_MOD) 
        end
    end
end

local function RemoveDurabilityMult(inst, equip)
   if equip ~= nil then
        if equip.components.weapon ~= nil and (equip.components.finiteuses ~= nil or equip.components.armor ~= nil) then
            equip.components.weapon.attackwearmultipliers:RemoveModifier(inst)
        end 
    end
end

local function AddDurabilityMultArmor(inst, equip, target)
    if equip ~= nil and equip.components.armor ~= nil then

            equip.components.armor.conditionlossmultipliers:SetModifier(inst, TUNING.DSTU.BATTLESONG_LUNAR_DURABILITY_MOD_ARMOR)
    end
end

local function RemoveDurabilityMultArmor(inst, equip)
   if equip ~= nil and equip.components.armor ~= nil then
        equip.components.armor.conditionlossmultipliers:RemoveModifier(inst)
    end
end

local function CheckValidAttackData(attacker, data)
    if attacker and attacker.components.combat and attacker.components.combat.target then
        local target = attacker.components.combat.target
        -- combat.target does not account for punching bag

        -- Most passive mobs don't have a default damage set, so it defaults to 0
        if target.components.combat ~= nil and target.components.combat.defaultdamage <= 0 then
            return false
        end

        -- Additional checks for entities that manage to pass the damage check
        if target:HasTag("eyeturret") then -- Houndious
            return false
        end
    end

	if data then
		if data.projectile and data.projectile.components.projectile and data.projectile.components.projectile:IsBounced() then
			--bounced projectiles don't count
			return false
		elseif data.weapon and data.weapon.components.inventoryitem == nil then
			--fake "weapons" used for detached aoe dmg don't count (e.g. flamethrower_fx)
			return false
		end
        
        -- Edge case where the target is not registered as a combat target
        -- If non-valid target is inside wigfrid's current weapon range, disable song effects
        local mustHaveTags = {"structure"}
        local cantHaveTags = {"stageactor"} -- Exclude mannequin
        local mustHaveOneOfTheseTags = {"equipmentmodel"} -- Include punching bag

        local searchradius = 3
        if data.weapon and data.weapon.components.weapon and data.weapon.components.weapon.attackrange ~= nil then
            searchradius = data.weapon.components.weapon.attackrange * 2.5
            if searchradius > 7 then searchradius = 7 end -- Don't account for long range weapons as it gets really messy
        end

        local x,y,z = attacker.Transform:GetWorldPosition()

        local ents = TheSim:FindEntities(x, y, z, searchradius, mustHaveTags, cantHaveTags, mustHaveOneOfTheseTags)

        local next = next 
        if next(ents) ~= nil then
            return false
        end
        
	end

	return true
end

--------------------------------------------------------------------------
-- BATTLESONG FNS
--------------------------------------------------------------------------


local function battlesong_durability_onapply(inst, target)
    if target.components.inventory then
        local repairarmor = IsNearLunarMelodist(target)

        if repairarmor then
            for slot, item in pairs(target.components.inventory.equipslots) do
                if item ~= nil then
                    AddDurabilityMult(inst, item, target)
                    AddDurabilityMultArmor(inst, item, target)
                end
            end
        else
            local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            AddDurabilityMult(inst, equip, target)
        end

        inst:ListenForEvent("equip", function(target, data)
            if repairarmor then
                AddDurabilityMult(inst, data.item, target)
                AddDurabilityMultArmor(inst, data.item, target)
            elseif data.eslot == EQUIPSLOTS.HANDS then
                AddDurabilityMult(inst, data.item, target)
            end
        end, target)

        inst:ListenForEvent("unequip", function(target, data)
            if repairarmor then
                RemoveDurabilityMult(inst, data.item)
                RemoveDurabilityMultArmor(inst, data.item)
            elseif data.eslot == EQUIPSLOTS.HANDS then
                RemoveDurabilityMult(inst, data.item)
            end
        end, target)
    end
end

local function battlesong_durability_ondetach(inst, target)
    if target.components.inventory then
        local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        RemoveDurabilityMult(inst, equip)
    end
end

local function battlesong_healthgain_onapply(inst, target)
    if target.components.health then
        inst:ListenForEvent("onattackother", function(attacker, data)
            if CheckValidAttackData(attacker, data) then
                --[[
                if target:HasTag("battlesinger") then
                    local lunarMult = 1
                    if IsNearLunarMelodist(target) then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_HEALTHGAIN_MULT_SINGER end
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA_SINGER * lunarMult)
                else
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA )
                end
                target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA )]]
                if target:HasTag("battlesinger") then
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA_SINGER)
                else
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA)
                end
            end
        end, target)

        if IsNearLunarMelodist(target) and inst.battlesong_healthgain_task == nil then
            inst.battlesong_healthgain_task = inst:DoPeriodicTask(TUNING.DSTU.BATTLESONG_LUNAR_REGEN_PERIOD, function()
                target.components.health:DoDelta(TUNING.DSTU.BATTLESONG_LUNAR_REGEN_AMOUNT_HEALTH)
            end)
        end
    end
end


local function battlesong_healthgain_ondetach(inst, target)
    if inst.battlesong_healthgain_task ~= nil then
        inst.battlesong_healthgain_task:Cancel()
        inst.battlesong_healthgain_task = nil
    end
end


local function battlesong_sanitygain_onapply(inst, target)
    if target.components.sanity then
        inst:ListenForEvent("onattackother", function(attacker, data)
            if CheckValidAttackData(attacker, data) then
                --[[
                if target:HasTag("battlesinger") then
                    local lunarMult = 1
                    if IsNearLunarMelodist(target) then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_SANITYGAIN_MULT_SINGER end
                    target.components.sanity:DoDelta(TUNING.BATTLESONG_SANITYGAIN_DELTA * lunarMult)
                else
                    target.components.sanity:DoDelta(TUNING.BATTLESONG_SANITYGAIN_DELTA)
                end]]
                target.components.sanity:DoDelta(TUNING.BATTLESONG_SANITYGAIN_DELTA)
            end
        end, target)

        if IsNearLunarMelodist(target) and inst.battlesong_sanitygain_task == nil then
            inst.battlesong_sanitygain_task = inst:DoPeriodicTask(TUNING.DSTU.BATTLESONG_LUNAR_REGEN_PERIOD, function()
                target.components.sanity:DoDelta(TUNING.DSTU.BATTLESONG_LUNAR_REGEN_AMOUNT_SANITY)
            end)
        end
    end
end

local function battlesong_sanitygain_ondetach(inst, target)
    if inst.battlesong_sanitygain_task ~= nil then
        inst.battlesong_sanitygain_task:Cancel()
        inst.battlesong_sanitygain_task = nil
    end
end

local function battlesong_sanityaura_onapply(inst, target)
    if target.components.sanity ~= nil then
        local lunarMult = 1
        if IsNearLunarMelodist(target) then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_SANITYAURA_MULT_SINGER end
        target.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.BATTLESONG_NEG_SANITY_AURA_MOD * lunarMult)
    end
end

local function battlesong_sanityaura_ondetach(inst, target)
    if target.components.sanity ~= nil then
        target.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
    end
end

local function battlesong_lunaraligned_onapply(inst, target)
    local defense = TUNING.BATTLESONG_LUNARALIGNED_LUNAR_RESIST
    local attack = TUNING.BATTLESONG_LUNARALIGNED_VS_SHADOW_BONUS
    if IsNearLunarMelodist(target) then
        defense = TUNING.DSTU.BATTLESONG_LUNAR_LUNARALIGNED_LUNAR_RESIST
        attack = TUNING.DSTU.BATTLESONG_LUNAR_LUNARALIGNED_VS_SHADOW_BONUS
    end

    if target.components.damagetyperesist ~= nil then
        target.components.damagetyperesist:AddResist("lunar_aligned", inst, defense, "battlesong_lunaraligned")
    end

    if target.components.damagetypebonus ~= nil then
        target.components.damagetypebonus:AddBonus("shadow_aligned", inst, attack, "battlesong_lunaraligned")
    end
end

local function battlesong_shadowaligned_onapply(inst, target)
    local defense = TUNING.BATTLESONG_SHADOWALIGNED_SHADOW_RESIST
    local attack = TUNING.BATTLESONG_SHADOWALIGNED_VS_LUNAR_BONUS
    if IsNearLunarMelodist(target) then
        defense = TUNING.DSTU.BATTLESONG_LUNAR_SHADOWALIGNED_SHADOW_RESIST
        attack = TUNING.DSTU.BATTLESONG_LUNAR_SHADOWALIGNED_VS_LUNAR_BONUS
    end

    if target.components.damagetyperesist ~= nil then
        target.components.damagetyperesist:AddResist("shadow_aligned", inst, defense, "battlesong_shadowaligned")
    end

    if target.components.damagetypebonus ~= nil then
        target.components.damagetypebonus:AddBonus("lunar_aligned", inst, attack, "battlesong_shadowaligned")
    end
end

--------------------------------------------------------------------------
-- PREFAB POSTINITS
--------------------------------------------------------------------------

env.AddPrefabPostInit("battlesong_durability", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_durability_onapply
    inst.songdata.ONDETACH = battlesong_durability_ondetach
end)

env.AddPrefabPostInit("battlesong_healthgain", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_healthgain_onapply
    inst.songdata.ONDETACH = battlesong_healthgain_ondetach
end)

env.AddPrefabPostInit("battlesong_sanitygain", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_sanitygain_onapply
    inst.songdata.ONDETACH = battlesong_sanitygain_ondetach

end)

env.AddPrefabPostInit("battlesong_sanityaura", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_sanityaura_onapply
    inst.songdata.ONDETACH = battlesong_sanityaura_ondetach
end)

env.AddPrefabPostInit("battlesong_lunaraligned", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_lunaraligned_onapply
end)

env.AddPrefabPostInit("battlesong_shadowaligned", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_shadowaligned_onapply
end)


