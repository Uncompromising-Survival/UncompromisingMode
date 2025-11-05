local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function PocketsForDays(inst)
	if not TheWorld.ismastersim then
		return
	end

	local function OnContainerChanged(inst)
		if inst.components.container:IsEmpty() then
			inst.components.inventoryitem.cangoincontainer = true
		else
			inst.components.inventoryitem.cangoincontainer = false
		end
	end

	inst:ListenForEvent("itemget", OnContainerChanged)
	inst:ListenForEvent("itemlose", OnContainerChanged)
	inst:DoTaskInTime(0, function() OnContainerChanged(inst) end)
end

env.AddPrefabPostInitAny(function(inst)
	if inst:HasTag("backpack") and inst.components.container and inst.components.inventoryitem then
		PocketsForDays(inst)
		inst:AddTag("pocketbackpack")		
		if inst.components.burnable ~= nil and inst.components.fuel == nil then
			inst:AddComponent("fuel")
			inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
		end	
	end
end)
