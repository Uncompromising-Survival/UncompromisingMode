local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function PocketsForDays(inst)
	if not TheWorld.ismastersim then
		return
	end

	local function UpdateContainerState(inst)
		if inst.components.container ~= nil and inst.components.inventoryitem ~= nil then
			local empty = inst.components.container:IsEmpty()
			inst.components.inventoryitem.cangoincontainer = empty
		end
	end

	local function OnContainerChanged(inst)
		inst:DoTaskInTime(0, UpdateContainerState)
	end

	inst:ListenForEvent("itemget", OnContainerChanged)
	inst:ListenForEvent("itemlose", OnContainerChanged)

	inst:DoTaskInTime(0, UpdateContainerState)

	if inst.components.container ~= nil then
		local _OnLoad = inst.components.container.OnLoad
		inst.components.container.OnLoad = function(self, data, ...)
			if _OnLoad ~= nil then
				_OnLoad(self, data, ...)
			end
			UpdateContainerState(self.inst)
		end
	end
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
