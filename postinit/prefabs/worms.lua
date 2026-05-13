local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

-- Instead of postinit-ing hounded and forcing an areaaware check from the player end, it is less convoluted to just place a check on the end of the worm prefabs for the area they're in only when they spawn	
local worms = {"worm","viperworm","shockworm"}
for i,v in ipairs(worms) do
	env.AddPrefabPostInit(v, function (inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:DoTaskInTime(0,function(inst) -- Needs a delay for OnLoad to be called
			if not inst.checked_area_worm then
				inst:AddComponent("areaaware")
				inst:DoTaskInTime(0.1,function(inst) -- Needs a delay for areaaware to init, cannot be 0
					if inst.components.areaaware:CurrentlyInTag("eels_only") and inst.prefab ~= "shockworm" then
						SpawnPrefab("shockworm").Transform:SetPosition(inst.Transform:GetWorldPosition())
						inst:Remove()
					end
					if inst.components.areaaware:CurrentlyInTag("vipers_only") and inst.prefab ~= "viperworm" then
						SpawnPrefab("viperworm").Transform:SetPosition(inst.Transform:GetWorldPosition())
						inst:Remove()
					end
				end)
				--inst:RemoveComponent("areaaware") --AXE This causes a vanilla crash, they call self:StopUpdating at line 17 of areaaware component, but this is nil.
				inst.checked_area_worm = true
			end
		end)
		local old_OnSave = inst.OnSave
		inst.OnSave = function(inst, data, ...)
			if inst.checked_area_worm then
				data.checked_area_worm = inst.checked_area_worm
			end

			if old_OnSave ~= nil then
				return old_OnSave(inst, data, ...)
			end
		end

		local old_OnLoad = inst.OnLoad
		inst.OnLoad = function(inst, data, ...)
			if data ~= nil and data.checked_area_worm ~= nil then
				inst.checked_area_worm = data.checked_area_worm
			end

			if old_OnLoad ~= nil then
				return old_OnLoad(inst, data, ...)
			end
		end
	end)
end