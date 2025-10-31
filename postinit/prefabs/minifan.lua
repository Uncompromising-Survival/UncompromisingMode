--TODO: Hook!
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function onunequip(inst, owner)
    if inst._wheel ~= nil then
        inst._wheel:StartUnequipping(inst)
        inst._wheel = nil
    end

    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
        inst._owner = nil
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner:RemoveTag("minifansuppressor")
	local terrorized = owner.components.terrorized
	if terrorized then
		terrorized.terror_immunity_minifan = 0
	end
end

local function AddTerrorizeImmunity(inst)	
	local terrorized = inst.components.terrorized
	if terrorized then
		terrorized.terror_immunity_minifan = 0.8
	end
end

local function RemoveTerrorizeImmunity(inst)
	local terrorized = inst.components.terrorized
	if terrorized then
		terrorized.terror_immunity_minifan = 0
	end
end

env.AddPrefabPostInit("minifan", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.equippable ~= nil then
        inst.components.equippable:SetOnUnequip(onunequip)
    end

    inst._onlocomote = function(owner)
        if owner.components.locomotor.wantstomoveforward then
            if not inst.components.fueled.consuming then
                inst.components.fueled:StartConsuming()
                inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
                inst.components.heater:SetThermics(false, true)
                inst._wheel:SetSpinning(true)
                owner:AddTag("minifansuppressor")
				AddTerrorizeImmunity(owner)			
            end
        elseif inst.components.fueled.consuming then
            inst.components.fueled:StopConsuming()
            inst.components.insulator:SetInsulation(0)
            inst.components.heater:SetThermics(false, false)
            inst._wheel:SetSpinning(false)
            owner:RemoveTag("minifansuppressor")
			RemoveTerrorizeImmunity(owner)
        end
    end
end)
