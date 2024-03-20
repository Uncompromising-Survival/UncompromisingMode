local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function CheckDeathForVetDrop(inst)
	if TUNING.DSTU.VETCURSE ~= "off" then
		inst.components.vetcurselootdropper.loot = "um_fuelweaver_soul"
	end
end

env.AddPrefabPostInit("stalker_atrium", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    local _GetBattleCryString = inst.components.combat.GetBattleCryString

    local function AtriumBattleCry(combat, target)
        local strtbl =
            target ~= nil and
            target:HasTag("wathom") and
            "STALKER_ATRIUM_WATHOM_BATTLECRY" or
            _GetBattleCryString(combat, target)
        return strtbl, math.random(#STRINGS[strtbl])
    end
    
    inst.components.combat.GetBattleCryString = AtriumBattleCry
	
    if TUNING.DSTU.VETCURSE ~= "off" then
		inst:AddComponent("vetcurselootdropper")
	end

	inst:ListenForEvent("death", CheckDeathForVetDrop)
end)