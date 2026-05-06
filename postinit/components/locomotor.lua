local env = env
--local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

GLOBAL.setfenv(1, GLOBAL)
local no_nettle = { "PyreToxinImmune", "plantkin", "shadowcreature", "flying", "FX", "INLIMBO", "invisible", "notarget", "noattack", "playerghost", "smog", "wall" }

env.AddComponentPostInit("locomotor", function(self)
	local _OnUpdate = self.OnUpdate
	function self:OnUpdate(dt, arrive_check_only)
		local inst = self.inst
		-- Fire Nettles effect moving
		if not inst:HasAnyTag(no_nettle) and inst.sg and inst.sg:HasStateTag("moving") and not inst.nettlebump_cd then
			local nettle = FindEntity(inst,2,nil,{"PyreNettle"})
			if nettle and nettle.pyrenettle_bumped then
				nettle.pyrenettle_bumped(nettle,inst)
				inst.nettlebump_cd = inst:DoTaskInTime(1,function(inst) -- short CD
					inst.nettlebump_cd:Cancel()
					inst.nettlebump_cd = nil
				end)
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

local function RYNOTWO(self)
	if self.ismastersim then
		local _GetSpeedMultiplier = self.GetSpeedMultiplier
		function self:GetSpeedMultiplier(...)
			local mult = _GetSpeedMultiplier(self, ...)
			local inst = self.inst
			local inv = inst.components.inventory
			if inv then
				local hat = inv:GetEquippedItem(EQUIPSLOTS.HEAD)
				if hat and hat.prefab == "gore_horn_hat" and inst.runspeed ~= nil then
					if mult < inst.runspeed then
						mult = inst.runspeed
					end
				end
			end
		return mult
		end
	end
end

env.AddComponentPostInit("locomotor", RYNOTWO)
