local UM_Ripplespawner = Class(function(self, inst)
    self.inst = inst
    self.range = 3
end)

local function CheckLeftPond(ent,self)
	if self.inst:GetDistanceSqToInst(ent) > self.range^2 then
		if not (ent.components.inventory and ent.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) and ent.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab == "purpleamulet") then
			ent.components.sanity:SetInducedInsanity(ent, false)
            if ent:HasTag("fuelfarming") then
                ent:RemoveTag("fuelfarming")
            end
		end 
		ent.um_pond_induced_insanity:Cancel()
		ent.um_pond_induced_insanity = nil
	end
end


function UM_Ripplespawner:spawnripple(inst)
	if inst ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		
		local _map = TheWorld.Map
		local current_tile = _map:GetTileAtPoint(x, y, z)
		if current_tile == WORLD_TILES.UM_FLOODWATER or self.inst.prefab == "um_hotspring" then
			if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
				inst.components.burnable:Extinguish()
			elseif inst.sg and inst.sg:HasStateTag("moving") then
				local splash = SpawnPrefab("weregoose_splash")
				
				splash.Transform:SetPosition(x,y,z)
				
				if not inst:HasTag("largecreature") then
					if inst:HasTag("isinventoryitem") then
						splash.Transform:SetScale(0.65,0.65,0.65)
					else    
						splash.Transform:SetScale(0.75,0.75,0.75)
					end
				end
				if self.inst:HasTag("pond_inducedinsanity") then
					--splash.AnimState:SetMultColour(0,0,0,1)
				end
				if inst.components.moisture ~= nil then
					local waterproofness = inst.components.inventory and math.min(inst.components.inventory:GetWaterproofness(),1) or 0
					inst.components.moisture:DoDelta(10 * (1 - waterproofness), true)
				end
			end    
			
			local x,y,z = inst.Transform:GetWorldPosition()
			local ripple = SpawnPrefab("weregoose_ripple1")
			
			if math.random() > 0.5 then
				ripple = SpawnPrefab("weregoose_ripple2")
			end
			
			ripple.Transform:SetPosition(x,y,z)
			
			if not inst:HasTag("largecreature") then
				if inst:HasTag("isinventoryitem") then
					ripple.Transform:SetScale(0.85,0.85,0.85)
				end
			else
				ripple.Transform:SetScale(1.2,1.2,1.2)
			end
			
			if ripple.AnimState ~= nil then
				ripple.AnimState:SetOceanBlendParams(.2)
			end
			if self.inst:HasTag("pond_inducedinsanity") then
				--ripple.AnimState:SetMultColour(0,0,0,1)
			end
			
			if self.inst.prefab == "um_hotspring" then
				if inst.components.temperature then
					inst.components.temperature:DoDelta(0.3)
				end
				local waterproofness = inst.components.inventory and math.min(inst.components.inventory:GetWaterproofness(),1) or 0
				if self.inst.components.timer:TimerExists("bubbly") and waterproofness < 1 then
					inst.components.health:DeltaPenalty(-0.005)
				end
			end
			
			
			if math.random () < 0.5 and  self.inst.prefab == "um_hotspring" then
				local bubble = SpawnPrefab("crab_king_bubble"..tostring(math.random(1,3)))
				bubble.Transform:SetPosition(x,y,z)
			
				if not inst:HasTag("largecreature") then
					if inst:HasTag("isinventoryitem") then
						bubble.Transform:SetScale(0.85,0.85,0.85)
					end
				else
					bubble.Transform:SetScale(1.2,1.2,1.2)
				end
			end
			
			if inst.components.moisture ~= nil then
				inst:AddTag("um_waterfall_moisture_override")
					
				if inst:IsValid() and self.inst ~= nil and self.inst:IsValid() and inst:GetDistanceSqToInst(self.inst) <= 6 and self.inst.prefab ~= "um_hotspring" then
					inst:AddTag("um_waterfall_bonus")
					local headsplash = SpawnPrefab("splash")
					headsplash.entity:SetParent(inst.entity)
					headsplash.entity:AddFollower():FollowSymbol(inst.GUID, "swap_hat", 0, -2, 0)
				else
					inst:RemoveTag("um_waterfall_bonus")
				end
					
				if inst.um_waterfall_task ~= nil then
					inst.um_waterfall_task:Cancel()
					inst.um_waterfall_task = nil
				end
					
				inst.um_waterfall_task = inst:DoTaskInTime(.4, function(inst)
					inst:RemoveTag("um_waterfall_moisture_override")
					inst:RemoveTag("um_waterfall_bonus")
					
					if inst.um_waterfall_task ~= nil then
						inst.um_waterfall_task:Cancel()
						inst.um_waterfall_task = nil
					end
				end)
			end
		end
	end
	
	inst.um_rippletask = nil 
end

function UM_Ripplespawner:OnEntitySleep()
	self.inst:StopUpdatingComponent(self)
end

function UM_Ripplespawner:OnEntityWake()
	self.inst:StartUpdatingComponent(self)
end

function UM_Ripplespawner:OnUpdate(dt)
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local ents = {}
    
    if self.range > 0 then
        ents = TheSim:FindEntities(x,y,z, self.range, nil,{"flying","INLIMBO", "shadowcreature"}, {"monster","animal","character","isinventoryitem","tree","structure", "_burnable"})
    end

    for i, ent in ipairs(ents) do
		if ent.um_rippletask == nil then
			ent.um_rippletask = ent:DoTaskInTime(ent.components.locomotor ~= nil and (1.8 / ent.components.locomotor:GetRunSpeed()) or .3,
				function(ent)  
					if not ent:HasTag("flying") or ent:HasTag("ghostplayer") then
						self:spawnripple(ent) 
					end 
				end)
		end
		if self.inst:HasTag("pond_inducedinsanity") and not ent.um_pond_induced_insanity and ent.components.sanity then
			ent.components.sanity:SetInducedInsanity(ent, true)
			if not ent:HasTag("fuelfarming") then
                ent:AddTag("fuelfarming")
            end			
			ent.um_pond_induced_insanity = ent:DoPeriodicTask(FRAMES, CheckLeftPond, nil, self)
		end
		-- if not ent.water_goo and not ent:HasTag("flying") or ent:HasTag("playerghost") then -- They didn't like the water goo, so commented out
			-- ent.water_goo = SpawnPrefab("um_waterfollow")
			-- ent.water_goo:SetupBlob(ent, ent)	
			-- ent.water_goo.stay = true
		-- elseif ent.water_goo then -- still nearby, keep the goo
			-- ent.water_goo.stay = true
		-- end
    end
end

function UM_Ripplespawner:SetRange(newrange)
    self.range = newrange
end

return UM_Ripplespawner
