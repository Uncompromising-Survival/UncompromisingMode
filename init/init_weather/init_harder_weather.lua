----------------------------------------------------------------------------------------------------------
-- Remove thermal stone sewing
-- Relevant: heatrock.lua
----------------------------------------------------------------------------------------------------------
--[[
local function DoSewing(self, target, doer)
    if self ~= nil and self.inst ~= nil then
        local _OldDoSewing = self.DoSewing
        
        self.DoSewing = function(self, target, doer)
            if target ~= nil and not target:HasTag("heatrock") then --<< Check for thermal
                _OldDoSewing(self, target, doer)
            end
        end
    end
end
AddComponentPostInit("sewing", DoSewing)
--TODO thermal stone stacking
--]]
-------------Torches only smolder objects now---------------
local _OldLightAction = GLOBAL.ACTIONS.LIGHT.fn
if TUNING.DSTU.WINTER_BURNING and not GLOBAL:TestForIA() then
	GLOBAL.ACTIONS.LIGHT.fn = function(act)
    	if act.invobject ~= nil and act.invobject.components.lighter ~= nil then
			if GLOBAL.TheWorld.state.season == "winter" and not act.doer:HasTag("pyromaniac") and act.target.components.burnable then
				if act.invobject.components.fueled then
					act.invobject.components.fueled:DoDelta(-5, act.doer) --Hornet: Made it take fuel away because.... The snow and cold takes some of the fire? probably will change
				end
				act.target.components.burnable:StartWildfire()
				return true
			else
				return _OldLightAction(act)
			end
		end
	end
end

local env = env
GLOBAL.setfenv(1, GLOBAL)

local function GenerateBiomes()
	if TheWorld.state.isspring then
		TheWorld.components.um_areahandler:FullGenerate()
	end
end

local function GenerateInactiveBiomes()
	if TheWorld.components.um_areahandler ~= nil then
		TheWorld.components.um_areahandler:GenerateInactiveBiomes()
	end
end

-----------------------------------------------------------------
env.AddPrefabPostInit("cave", function(inst)
    if not TheWorld.ismastersim then
        return
    end
	inst:DoTaskInTime(0, function(inst)
    	if TUNING.DSTU.CAVECLOPS then
    		inst:AddComponent("cavedeerclopsspawner")
		end
    	inst:AddComponent("randomnighteventscaves")
		inst:AddComponent("ratacombs_junk_manager")
	end)
end)

env.AddPrefabPostInit("forest", function(inst)
    if not TheWorld.ismastersim then
        return
    end

	if not TUNING.DSTU.ISLAND_ADVENTURES then
		inst:RemoveComponent("deerclopsspawner")
		inst:AddComponent("uncompromising_deerclopsspawner")

		inst:AddComponent("toadrain")
		--inst:AddComponent("hayfever_tracker")
		inst:AddComponent("firefallwarning")
		inst:AddComponent("pollenmitedenspawner")
		inst:AddComponent("randomnightevents")
		inst:AddComponent("um_areahandler")
		
		if TUNING.DSTU.SPAWNMOTHERGOOSE then
			inst:AddComponent("gmoosespawner")
		end
		
		if TUNING.DSTU.SPAWNWILTINGFLY then
			inst:AddComponent("mock_dragonflyspawner")
		end
		
		inst:WatchWorldState("isspring", GenerateBiomes)
		inst:WatchWorldState("issummer", GenerateInactiveBiomes)

		inst:DoTaskInTime(0.1, GenerateInactiveBiomes)

		if TUNING.DSTU.SNOWSTORMS then
			inst:AddComponent("snowstorminitiator")
		end
	end
end)