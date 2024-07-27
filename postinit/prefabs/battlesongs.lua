local env = env
GLOBAL.setfenv(1, GLOBAL)

--------------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------------

local function AddDurabilityMult(inst, equip, target)
    if equip ~= nil and equip.components.weapon ~= nil and equip.components.finiteuses ~= nil then
        local lunarMult = 1
        if target:HasTag("lunar_improved_songs") then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_DURABILITY_MULT_SINGER end
        equip.components.weapon.attackwearmultipliers:SetModifier(inst, TUNING.BATTLESONG_DURABILITY_MOD * lunarMult)
    end
end

local function RemoveDurabilityMult(inst, equip)
   if equip ~= nil and equip.components.weapon ~= nil and equip.components.finiteuses ~= nil then
        equip.components.weapon.attackwearmultipliers:RemoveModifier(inst)
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
	end

    -- Edge case where the target is not registered as a combat target
    -- If non-valid target is inside wigfrid's current weapon range, disable song effects
    local mustHaveTags = {"structure"}
	local cantHaveTags = {"stageactor"} -- Exclude mannequin
	local mustHaveOneOfTheseTags = {"equipmentmodel"} -- Include punching bag

    local searchradius = 3
    if data.weapon.components.weapon ~= nil and data.weapon.components.weapon.attackrange ~= nil then
        searchradius = data.weapon.components.weapon.attackrange * 2.5
        if searchradius > 7 then searchradius = 7 end -- Don't account for long range weapons as it gets really messy
    end

    local x,y,z = attacker.Transform:GetWorldPosition()

	local ents = TheSim:FindEntities(x, y, z, searchradius, mustHaveTags, cantHaveTags, mustHaveOneOfTheseTags)

    local next = next 
    if next(ents) ~= nil then
        return false
    end

	return true
end

--------------------------------------------------------------------------
-- BATTLESONG FNS
--------------------------------------------------------------------------


local function battlesong_durability_onapply(inst, target)
    if target.components.inventory then
        local equip = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        AddDurabilityMult(inst, equip, target)

        inst:ListenForEvent("equip", function(target, data)
            if data.eslot == EQUIPSLOTS.HANDS then
                AddDurabilityMult(inst, data.item, target)
            end
        end, target)

        inst:ListenForEvent("unequip", function(target, data)
            if data.eslot == EQUIPSLOTS.HANDS then
                RemoveDurabilityMult(inst, data.item, target)
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
                if target:HasTag("battlesinger") then
                    local lunarMult = 1
                    if target:HasTag("lunar_improved_songs") then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_HEALTHGAIN_MULT_SINGER end
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA_SINGER * lunarMult)
                else
                    target.components.health:DoDelta(TUNING.BATTLESONG_HEALTHGAIN_DELTA )
                end
            end
        end, target)
    end
end


local function battlesong_sanitygain_onapply(inst, target)
    if target.components.sanity then
        inst:ListenForEvent("onattackother", function(attacker, data)
            if CheckValidAttackData(attacker, data) then
                if target:HasTag("battlesinger") then
                    local lunarMult = 1
                    if target:HasTag("lunar_improved_songs") then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_SANITYGAIN_MULT_SINGER end
                    target.components.sanity:DoDelta(TUNING.BATTLESONG_SANITYGAIN_DELTA * lunarMult)
                else
                    target.components.sanity:DoDelta(TUNING.BATTLESONG_SANITYGAIN_DELTA)
                end
            end
        end, target)
    end
end

local function battlesong_sanityaura_onapply(inst, target)
    if target.components.sanity ~= nil then
        local lunarMult = 1
        if target:HasTag("lunar_improved_songs") then lunarMult = TUNING.DSTU.BATTLESONG_LUNAR_SANITYAURA_MULT_SINGER end
        target.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.BATTLESONG_NEG_SANITY_AURA_MOD * lunarMult)
    end
end

local function battlesong_sanityaura_ondetach(inst, target)
    if target.components.sanity ~= nil then
        target.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
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
end)

env.AddPrefabPostInit("battlesong_sanitygain", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_sanitygain_onapply
end)

env.AddPrefabPostInit("battlesong_sanityaura", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst.songdata.ONAPPLY = battlesong_sanityaura_onapply
    inst.songdata.ONDETACH = battlesong_sanityaura_ondetach
end)

