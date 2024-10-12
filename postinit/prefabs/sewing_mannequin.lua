local env = env
GLOBAL.setfenv(1, GLOBAL)



env.AddPrefabPostInit("sewing_mannequin", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	local _OnActivate = inst.components.activatable.OnActivate
	
	local function FindMushroomHat(inst)
		local helm = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		if helm and (helm.prefab == "blue_mushroomhat" or helm.prefab == "red_mushroomhat" or helm.prefab == "green_mushroomhat") and helm.bonded then
			return helm
		end
	end
	
	local function has_any_equipment(inst)
		return inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil
			or inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) ~= nil
			or inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) ~= nil
	end

	local function CanSwap(inst, doer)
		-- We can perform a swap if either of our head/body slots are filled,
		-- or either of the doer's are filled.
		return has_any_equipment(inst)
			or (doer.components.inventory ~= nil and has_any_equipment(doer))
	end

	local function become_inactive(inst)
		inst.components.activatable.inactive = true
	end
	
	local function OnActivate(inst, doer)
		if FindMushroomHat(doer) then
			inst:DoTaskInTime(5*FRAMES, become_inactive)

			if CanSwap(inst, doer) then
				local handswap_success = inst.components.inventory:SwapEquipment(doer, EQUIPSLOTS.HANDS)
				local bodyswap_success = inst.components.inventory:SwapEquipment(doer, EQUIPSLOTS.BODY)

				if (handswap_success or bodyswap_success) then
					inst.AnimState:PlayAnimation("swap")
					inst.SoundEmitter:PlaySound("stageplay_set/mannequin/swap")
					inst.AnimState:PushAnimation("idle", false)

					return true
				else
					return false, "MANNEQUIN_EQUIPSWAPFAILED"
				end
			else
				-- This should be exceedingly rare because we shouldn't have been activatable
				-- if we didn't have anything to swap.
				return false
			end
		else
			_OnActivate(inst, doer)
		end
	end
	
	inst.components.activatable.OnActivate = OnActivate
end)