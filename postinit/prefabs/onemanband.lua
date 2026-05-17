local env = env
GLOBAL.setfenv(1, GLOBAL)

TUNING.DSTU.ONEMANBAND_HOUSE_TAGS = { "pig_house" }
TUNING.DSTU.ONEMANBAND_DRAINPERFOLLOWERMULT = 0.25
TUNING.DSTU.ONEMANBAND_PERISHTIME = 480 -- 1 day = 480

local function CalcDapperness(inst, owner)
    local numfollowers = owner.components.leader ~= nil and owner.components.leader:CountFollowers() or 0
    local numpets = owner.components.petleash ~= nil and owner.components.petleash:GetNumPets() or 0
    return -TUNING.DAPPERNESS_SMALL - math.max(0, numfollowers - numpets) * TUNING.SANITYAURA_SMALL * TUNING.DSTU.ONEMANBAND_DRAINPERFOLLOWERMULT
end

local function LeaveHouse(house)
	--print(house, "is occupied: ", house.components.spawner:IsOccupied())
	if house.components.spawner and house.components.spawner:IsOccupied() then
		house.components.spawner:ReleaseChild()
	end
end

local function KnockHouse(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ONEMANBAND_RANGE, TUNING.DSTU.ONEMANBAND_HOUSE_TAGS)) do
		if v.components.spawner ~= nil then
			LeaveHouse(v)
		end
	end
end

env.AddPrefabPostInit("onemanband", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.house_task = nil

	local _onequipfn = inst.components.equippable.onequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
        _onequipfn(inst, owner)
        if inst.house_task == nil then
            inst.house_task = inst:DoPeriodicTask(1,function() KnockHouse(inst) end)
        end
    end)

    local _onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        _onunequipfn(inst, owner)
        if inst.house_task then
            inst.house_task:Cancel()
			inst.house_task = nil
        end
    end)

	if inst.components.equippable then
		inst.components.equippable.dapperfn = CalcDapperness
	end

	if inst.components.fueled then
		inst.components.fueled:InitializeFuelLevel(TUNING.DSTU.ONEMANBAND_PERISHTIME)
	end
end)

env.AddPrefabPostInit("rabbithouse", function(inst)
	inst:AddTag("pig_house")
end)