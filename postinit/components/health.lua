local env = env
GLOBAL.setfenv(1, GLOBAL)

local function MayKill(self, amount)
	if self.currenthealth + amount <= 0 then
		return true
	end
end

local function GetSLEEPED(inst, revived)
    if inst ~= revived and
        (TheNet:GetPVPEnabled() or not inst:HasTag("player")) and
        not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) and
        not (inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck()) and
        not (inst.components.fossilizable ~= nil and inst.components.fossilizable:IsFossilized()) then
        local mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
        if mount ~= nil then
            mount:PushEvent("ridersleep", { sleepiness = 10, sleeptime = TUNING.PANFLUTE_SLEEPTIME })
        end
		if inst.components.sleeper ~= nil then
            inst.components.sleeper:AddSleepiness(10, TUNING.PANFLUTE_SLEEPTIME)
        elseif inst.components.grogginess ~= nil then
            inst.components.grogginess:AddGrogginess(10, TUNING.PANFLUTE_SLEEPTIME)
        else
            inst:PushEvent("knockedout")
        end
    end
end

local function FindSleepoPeepo(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,7,{"_combat","_health"})
	if ents then
		for i,v in ipairs(ents) do
			if v.components.health and not v.components.health:IsDead() then
				GetSLEEPED(v,inst)
			end
		end
	end
end

local function TriggerLLA(self)
	local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local item2
	FindSleepoPeepo(self.inst)
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
	SpawnPrefab("slingshotammo_hitfx_gold").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	SpawnPrefab("shadow_despawn").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
	self:SetInvincible(true)
	if self.inst.components.sanity then
		self.inst.components.sanity:DoDelta(-50)
	end
	self.inst:DoTaskInTime(1,function(inst) if inst.components.health then inst.components.health:SetInvincible(false) end end)
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
