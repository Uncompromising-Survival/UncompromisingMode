local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("lighter", function(inst)
	if not TheWorld.ismastersim then return end

	local function StopSmog(inst)
		if inst.smog_task then
			inst.smog_task:Cancel()
			inst.smog_task = nil
		end
	end

	local function HookChanneling(inst)
		local channel = inst.components.channelcastable
		if channel == nil or inst.smog_channel == channel then return end

		inst.smog_channel = channel

		local _onstart = channel.onstartchannelingfn
		local _onstop = channel.onstopchannelingfn

		channel:SetOnStartChannelingFn(function(inst, user)
			_onstart(inst, user)
			StopSmog(inst)

			inst.smog_task = inst:DoPeriodicTask(0.3, function(inst)
				if not user:IsValid() then
					StopSmog(inst)
					return
				end

				local x, y, z = user.Transform:GetWorldPosition()
				local smog = TheSim:FindEntities(x, y, z, 12, { "smog" }, { "INLIMBO" })

				for _, v in ipairs(smog) do
					v:Remove()
					user.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
				end
			end)
		end)

		channel:SetOnStopChannelingFn(function(inst, user)
			StopSmog(inst)
			_onstop(inst, user)
		end)
	end

	local _onskillrefresh = inst._onskillrefresh

	inst._onskillrefresh = function(owner)
		_onskillrefresh(owner)
		HookChanneling(inst)
		if inst.components.channelcastable == nil then
			StopSmog(inst)
			inst.smog_channel = nil
		end
	end

	local equippable = inst.components.equippable
	local _onequip = equippable.onequipfn
	local _onunequip = equippable.onunequipfn

	equippable:SetOnEquip(function(inst, owner, ...)
		_onequip(inst, owner, ...)
		HookChanneling(inst)
	end)

	equippable:SetOnUnequip(function(inst, owner, ...)
		StopSmog(inst)
		_onunequip(inst, owner, ...)
		inst.smog_channel = nil
	end)

	inst:ListenForEvent("onremove", StopSmog)
end)
