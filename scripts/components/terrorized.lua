local function onimmunity(self, terror_immunity)
	self.inst.terror_immunity:set(terror_immunity)
end

local function isnightterror(self, nightterror)
	self.inst.nightterror:set(nightterror)
end

local function EquipChanged(inst)
	local self = inst.components.terrorized
	self:SetNewClothingResistance(self)
end

local function PostInitSanity(self,inst)
	local sanity = inst.components.sanity
	if sanity then -- if for some reason a particular character has no sanity....
		if sanity.custom_rate_fn then
			self._sanity_custom_rate_fn = sanity.custom_rate_fn
		end
	end
	local function NewSanityDrain(inst, dt)
		local self = inst.components.terrorized
		local terrorrate = 0
		local original_custom = 0
		if self._sanity_custom_rate_fn then
			original_custom = self._sanity_custom_rate_fn(inst,dt)
		end
		if self.nightterror == 0 then
			local age = inst.components.age and inst.components.age:GetAgeInDays() or 210
			local resistance = 1
			if self.terror_immunity_clothing == 1 and self.terror_immunity_minifan == 1 then
				resistance = 0 -- Fully resistant
			elseif self.terror_immunity_clothing == 1 or self.terror_immunity_minifan == 1 then
				resistance = 0.1 -- (90% resist
			end
			terrorrate = (TUNING.SANITY_NIGHT_DARK/50)*(39+math.clamp(age,1,210))*resistance -- starts out negative
		end
		return terrorrate+original_custom
	end

	sanity.custom_rate_fn = NewSanityDrain
	
end


-- This component manages occult sanity drain/ night terror sanity drain
local Terrorized = Class(function(self, inst)
    self.inst = inst
	
	self.terror_immunity = 0
	self.terror_immunity_clothing = 0
	self.terror_immunity_minifan = 0
	
	
	inst:ListenForEvent("equip", EquipChanged)
	inst:ListenForEvent("unequip", EquipChanged)

	inst:StartUpdatingComponent(self)	
	
	
	if TheWorld.components.um_nightterrors and TheWorld.components.um_nightterrors.ongoing then
		self.nightterror = 0
	else
		self.nightterror = 1
	end
	
	inst:DoTaskInTime(0,function(inst) PostInitSanity(self,inst) end)
	
	
end,
nil,
{
	terror_immunity = onimmunity,
	nightterror = isnightterror,
})


function Terrorized:SetNewClothingResistance() -- Will need to change this call whenever we have more varied ways of getting immunity
	local inst = self.inst
	local resistance = 0
	local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab
	if hat then
		if hat == "gasmask" or hat == "plaguemask" or hat == "pyremask" then
			resistance = 0.9
		end
	end
	if resistance > 0 then
		self.terror_immunity_clothing = 1
	else
		self.terror_immunity_clothing = 0
	end
end


function Terrorized:OnUpdate() -- Trying to do this this way to update the replica without needing to grab the player's inventory at all times
	local inst = self.inst
	if inst.components.health and not inst.components.health:IsDead() and not inst:HasTag("playerghost") then
		self.terror_immunity = self.terror_immunity_minifan + self.terror_immunity_clothing
	else
		self.terror_immunity = 1 -- dead get a free pass
	end
	
	
	
end



return Terrorized
