local env = env
GLOBAL.setfenv(1, GLOBAL)

local function MayKill(self, amount)
	if self.currenthealth + amount <= 0 then
		return true
	end
end

local function TriggerLLA(self)
	local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local item2
	self:SetCurrentHealth(1)
	if self.inst.components.oldager ~= nil then
		--find a ageless watch
		for k, v in ipairs(self.inst.components.inventory.itemslots) do
			if v.prefab == "pocketwatch_heal" and v.components.rechargeable:IsCharged() then
				item2 = v
				break
			end
		end

		if item2 ~= nil then
			item2.components.pocketwatch.DoCastSpell(item2, self.inst) --if it can be used, use it!
		end
		self.inst.components.oldager:StopDamageOverTime()
		self:DoDelta(10, true, "pocketwatch_heal")--minor heal regardless of charge just so  you don't insta-die
	else
		self:DoDelta(39, false, item)
	end
	if self.inst:HasTag("wathom") then
		self.inst.AnimState:SetBuild("wathom")
	end
	SpawnPrefab("shadow_despawn").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	item:DoTaskInTime(0, function(item) item:Remove() end)
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
		if MayKill(self, amount) and HasLLA(self) then --and not (self.inst:HasTag("deathamp")) then
			TriggerLLA(self)
		else
			_DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
		end
	end
end)
