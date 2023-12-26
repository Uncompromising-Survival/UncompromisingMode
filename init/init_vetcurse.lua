local require = GLOBAL.require

AddPlayerPostInit(function(inst)

	if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
	
	local _OldOnSave = inst.OnSave
	local _OldOnLoad = inst.OnLoad

	local function OnSave(inst, data, ...)
		if inst.vetcurse ~= nil then
			data.vetscurse = inst.vetcurse
		end
		
		if inst.walter_vetcurse ~= nil then
			data.walter_vetcurse = inst.walter_vetcurse
		end
		
		if inst.wortox_vetcurse ~= nil then
			data.wortox_vetcurse = inst.wortox_vetcurse
		end
		
		if inst.maxwell_vetcurse ~= nil then
			data.maxwell_vetcurse = inst.maxwell_vetcurse
		end
			
		if inst.willow_vetcurse ~= nil then
			data.willow_vetcurse = inst.willow_vetcurse
		end
			
		if inst.warly_vetcurse ~= nil then
			data.warly_vetcurse = inst.warly_vetcurse
		end
			
		if inst.winky_vetcurse ~= nil then
			data.winky_vetcurse = inst.winky_vetcurse
		end
			
		if inst.vetcurse_sleepiness ~= nil then
			data.vetcurse_sleepiness = inst.vetcurse_sleepiness
		end
			
		if inst.wickerbottom_vetcurse ~= nil then
			data.wickerbottom_vetcurse = inst.wickerbottom_vetcurse
		end
			
		if inst.wixie_vetcurse ~= nil then
			data.wixie_vetcurse = inst.wixie_vetcurse
		end
			
		if inst.woodie_vetcurse ~= nil then
			data.woodie_vetcurse = inst.woode_vetcurse
		end
		
		return _OldOnSave(inst, data, ...)
	end

	local function OnLoad(inst, data, ...)
		if data ~= nil then
			if data.walter_vetcurse ~= nil then
				inst.walter_vetcurse = data.walter_vetcurse
			end
			
			if data.wortox_vetcurse then
				inst.wortox_vetcurse = data.wortox_vetcurse
			end
			
			if data.maxwell_vetcurse then
				inst.maxwell_vetcurse = data.maxwell_vetcurse
			end
			
			if data.willow_vetcurse then
				inst.willow_vetcurse = data.willow_vetcurse
			end
			
			if data.warly_vetcurse then
				inst.warly_vetcurse = data.warly_vetcurse
			end
			
			if data.winky_vetcurse then
				inst.winky_vetcurse = data.winky_vetcurse
			end
			
			if data.vetcurse_sleepiness then
				inst.vetcurse_sleepiness = data.vetcurse_sleepiness
			end
			
			if data.wickerbottom_vetcurse then
				inst.wickerbottom_vetcurse = data.wickerbottom_vetcurse
			end
			
			if data.wixie_vetcurse then
				inst.wixie_vetcurse = data.wixie_vetcurse
			end
			
			if data.woodie_vetcurse then
				inst.woodie_vetcurse = data.woode_vetcurse
			end
		
			if data.vetscurse then
				inst:ListenForEvent("respawnfromghost", function()
					inst:DoTaskInTime(3, function(inst) 
						
						inst.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
					end)
				end, inst)
				
				inst:ListenForEvent("ms_playerseamlessswaped", function()
					inst:DoTaskInTime(3, function(inst) 
						
						inst.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
					end)
				end, inst)
			end
		end
	
		return _OldOnLoad(inst, data, ...)
	end
	
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
end)