local env = env
--local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

GLOBAL.setfenv(1, GLOBAL)
------------------------Fire spread is less efficient in winter-----------------------------------------
local flood_equipment_verylow = {"trunkvest_summer","reflectivevest"}
local flood_equipment_low = {"armor_reed_um"}
local flood_equipment_med = {"raincoat"}
local flood_equipment_high = {"armor_sharksuit_um"}

local function CheckClothing(inst,table_check)
	local body
	if inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
		body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab
	end
	return (body and table.contains(table_check, body))
end

local function AdjustSpeed(inst)
	local mod = 0.5 -- Nothing
	if CheckClothing(inst,flood_equipment_high) then
		mod = 1.2 -- Shark Vest
	elseif CheckClothing(inst,flood_equipment_med) then
		mod = 1 -- Rain Coat
	elseif CheckClothing(inst,flood_equipment_low) then
		mod = 0.75 -- Reed Suit
	elseif CheckClothing(inst,flood_equipment_verylow) then
		mod = 0.6 -- Oddballs, like summer vest
	end
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "um_floodedwater", mod)
end

local function SplashEffect(inst)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	elseif inst.sg and inst.sg:HasStateTag("moving") then
		local splash = SpawnPrefab("weregoose_splash")
		local x,y,z = inst.Transform:GetWorldPosition()
		splash.Transform:SetPosition(x,y,z)
		
		if not inst:HasTag("largecreature") then
			if inst:HasTag("isinventoryitem") then
				splash.Transform:SetScale(0.65,0.65,0.65)
			else    
				splash.Transform:SetScale(0.75,0.75,0.75)
			end
		end
		if inst.components.moisture ~= nil then
			local mod = 0 -- nothing
			if CheckClothing(inst,flood_equipment_high) or CheckClothing(inst,flood_equipment_med) then
				mod = 1 -- Rain coat, shark suit (full immunity)
			elseif CheckClothing(inst,flood_equipment_low) then
				mod = 0.75 -- Reed Suit only gain 5% of 10
			elseif CheckClothing(inst,flood_equipment_verylow) then
				mod = 0.5 -- Summer Vest
			end
	
			inst.components.moisture:DoDelta(10 * (1 - mod), true) -- 10 per second
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
	local self = inst.components.locomotor
	if not (self._externalspeedmultipliers and self._externalspeedmultipliers[inst] and self._externalspeedmultipliers[inst].multipliers["um_floodedwater"]) then
		AdjustSpeed(inst)
		inst:ListenForEvent("equip",AdjustSpeed)		
		inst:ListenForEvent("unequip",AdjustSpeed)-- may fire twice, but that shouldn't matter, it's not doing a huge amount of computational work		
	end		
end

local function RobustFloodCheck(inst) -- For players, check to see if they're on the edge of a tile, you can walk on the "Void" to avoid the effects of the tile you're standing on, similar to spider webbings
	for i = -1,0,1 do
		for j = -1,0,1 do
			local x,y,z = inst.Transform:GetWorldPosition()
			local current_tile = TheWorld.Map:GetTileAtPoint(x+i,y,z+i)
			if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
				return true
			end
		end

	end
end

env.AddComponentPostInit("locomotor", function(self)
   
	local _OnUpdate = self.OnUpdate
	function self:OnUpdate(dt, arrive_check_only)
		local inst = self.inst
		if not inst.um_just_splashed and not inst:HasAnyTag("flying","shadow","worm","playerghost","brightmare","brightmare_gestalt") then -- do not do the lookup if you just splashed
			if inst:HasTag("player") then
				if RobustFloodCheck(inst) then
					SplashEffect(inst)
					inst.um_just_splashed = inst:DoTaskInTime(0.33,function(inst) -- Give a rest between splashes
						inst.um_just_splashed:Cancel()
						inst.um_just_splashed = nil
					end)
				elseif self._externalspeedmultipliers and self._externalspeedmultipliers[inst] and self._externalspeedmultipliers[inst].multipliers["um_floodedwater"] then
					self.inst:RemoveEventCallback("equip",AdjustSpeed)
					self.inst:RemoveEventCallback("unequip",AdjustSpeed)
					self:RemoveExternalSpeedMultiplier(inst, "um_floodedwater")
				end								
			else
				local current_tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())
				if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO then
					SplashEffect(inst)
					inst.um_just_splashed = inst:DoTaskInTime(0.33,function(inst) -- Give a rest between splashes
						inst.um_just_splashed:Cancel()
						inst.um_just_splashed = nil
					end)
				elseif self._externalspeedmultipliers and self._externalspeedmultipliers[inst] and self._externalspeedmultipliers[inst].multipliers["um_floodedwater"] then
					self.inst:RemoveEventCallback("equip",AdjustSpeed)
					self.inst:RemoveEventCallback("unequip",AdjustSpeed)
					self:RemoveExternalSpeedMultiplier(inst, "um_floodedwater")
				end				
			end
		end
		return _OnUpdate(self,dt,arrive_check_only)
	end
		
end)



local function MakeLeafyHatAmazing(self)
	if self.ismastersim then
		local _GetSpeedMultiplier = self.GetSpeedMultiplier
		function self:GetSpeedMultiplier()
			local mult = _GetSpeedMultiplier(self)
			local hat = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab 
			if hat and hat == "um_hat_leafwing" and mult < 1.15 then
				mult = 1.15
			end
			return mult
		end
	end
end

env.AddComponentPostInit("locomotor", MakeLeafyHatAmazing)