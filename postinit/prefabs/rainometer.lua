local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function getrevealtargetpos(inst, doer)
	local tornado = TheWorld:FindFirstEntityWithTag("um_tornado")

	if tornado == nil then
		return false, "MESSAGEBOTTLEMANAGER_NOT_FOUND"
	end
	
	local pos = tornado.Transform:GetPosition()
	local reason = "dunno lmao"
	
	return pos, reason
end

local function CheckForTornadoRevealers(inst)
	if not inst:HasTag("burnt") then
		local x, y, z = inst.Transform:GetWorldPosition()
		local players = FindPlayersInRange(x, y, z, 3)
		
		for i, v in pairs(players) do
			if v ~= nil then
				print(v.prefab)
				if v.um_tornado_revealer_task ~= nil then
					v.um_tornado_revealer_task:Cancel()
				end
				
				v.um_tornado_revealer_task = nil
				
				v.um_tornado_revealer_task = v:DoTaskInTime(2, function()
					v:RemoveTag("um_tornadotracker")
				end)
				
				v:AddTag("um_tornadotracker")
			end
		end
	end
end

env.AddPrefabPostInit("rainometer", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    --inst:ListenForEvent("onbuilt", onbuilt)
    --inst:ListenForEvent("animover", StartCheckRain)
	
	inst:AddComponent("mapspotrevealer")
	inst.components.mapspotrevealer:SetGetTargetFn(getrevealtargetpos)
	--inst.components.mapspotrevealer:SetPreRevealFn(prereveal)
	
    inst:ListenForEvent("burntup", function()
		inst:RemoveComponent("mapspotrevealer")
	end)
	
	inst:DoPeriodicTask(1, CheckForTornadoRevealers)
end)
