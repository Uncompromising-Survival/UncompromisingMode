local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function OnHitOtherBurn(inst, data)
    local other = data.target
    if other and not (other.components.health and other.components.health:IsDead()) then
		if other.components.rideable ~= nil and other.components.rideable:IsBeingRidden() then
			local rider = other.components.rideable:GetRider()
			if rider ~= nil and rider.components.health ~= nil and not rider.components.health:IsDead() and rider.components.burnable ~= nil then
				rider.components.burnable:Ignite(true, inst, inst)
			end
			return
		end
		
		if other.components.burnable ~= nil then
			other.components.burnable:Ignite(true, inst, inst)
		end	
    end
end

env.AddPrefabPostInit("firehound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if TUNING.DSTU.FIREBITEHOUNDS then
        if inst.components.combat then
            inst:ListenForEvent("onhitother", OnHitOtherBurn)
        end
    end
end)

env.AddPrefabPostInit("magmahound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.combat then
        inst:ListenForEvent("onhitother", OnHitOtherBurn)
    end
end)
