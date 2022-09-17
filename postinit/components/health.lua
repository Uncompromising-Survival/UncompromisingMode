local env = env
GLOBAL.setfenv(1, GLOBAL)

local function MayKill(self,amount)
	if self.currenthealth + amount <= 0 then
		return true
	end
end

local function TriggerLLA(self)
	local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	self:SetCurrentHealth(1)
	self:DoDelta(39,false,item)
    SpawnPrefab("shadow_despawn").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	item:DoTaskInTime(0,function(item) item:Remove() end)
end

local function HasLLA(self)
	if self.inst.components.inventory then
		local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
		if item and item.prefab == "amulet" then
			return true
		end
	end
end

env.AddComponentPostInit("health", function(self)
    if not TheWorld.ismastersim then return end

    local _DoDelta = self.DoDelta
	--(self:HasTag("wathom") and self:HasTag("amped")
    function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		if MayKill(self,amount) and HasLLA(self) and not (self.inst:HasTag("wathom") and self.inst:HasTag("amped")) then
			TriggerLLA(self)
		else
			_DoDelta(self,amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		end
    end
end)