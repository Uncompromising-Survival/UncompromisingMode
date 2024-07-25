--currently only used for IA, but if we ever need more advanced mod checks, put 'em here!


local env = env
GLOBAL.setfenv(1, GLOBAL)

--improved check for IA, instead of just checking for the mod, it checks for the world tags *and* the mod.
--returns true if IA.

function TestForIA()
    if TheWorld ~= nil and (TheWorld:HasTag("island") or TheWorld:HasTag("volcano")) then
       
        return true
    else
       
        return false
    end
end

function Um_CustomLightCheck(inst, dark_val, light_val)
	if inst ~= nil then
		local lightThresh = light_val or 0.1
		local darkThresh = dark_val or 0.05
		local inLight = false

		local x, y, z = inst.Transform:GetWorldPosition()
		local light = TheSim:GetLightAtPoint(x, y, z, lightThresh)
		local inlight = light >= darkThresh
		local miasma = TheSim:FindEntities(x, y, z, 3, nil, { "miasma" })
		
		return inlight or miasma ~= nil and #miasma > 0
		--[[local move_to_light = inLight == false and light >= lightThresh

		if move_to_light or (inLight ~= false and light <= darkThresh) then
			inLight = move_to_light
		end
		if inLight then
			print("I'm in the light!"..light)
		else
			print("I'm NOT in the light!"..light)
		end
			
		return inLight ~= false]]
	end
end

env.AddPrefabPostInit("wonderwhy", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("ignores_healthregen")
end)