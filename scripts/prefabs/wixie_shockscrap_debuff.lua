local AURA_EXCLUDE_TAGS = { "noclaustrophobia", "rabbit", "playerghost", "abigail", "companion", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "invisible" }

if not TheNet:GetPVPEnabled() then
    table.insert(AURA_EXCLUDE_TAGS, "player")
end

local function OnTick(inst, target, data)
	if target:IsValid() and target.components.combat ~= nil then
		local lightning_strike = SpawnPrefab("electric_explosion")
		lightning_strike.entity:SetParent(target.entity)
		lightning_strike.Transform:SetScale(0.6, 0.6, 0.6)
		
		target.components.combat:GetAttacked(inst, 20, inst, "electric")
		
		local x2, y2, z2 = target.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x2, y2, z2, 10, { "_combat" }, AURA_EXCLUDE_TAGS)
	
		for i, v in ipairs(ents) do
			if v ~= target and (v:HasTag("bird_mutant") or not v:HasTag("bird")) then
				if not (v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")) then
					local rubberband = SpawnPrefab("slingshotammo_scrapfeather_rebound")
					rubberband.Transform:SetPosition(target.Transform:GetWorldPosition())
					rubberband.components.projectile:Throw(inst, v, inst)
					rubberband.components.projectile:SetHoming(true)
				end
			end
		end
	end
end

local function OnAttached(inst, target, followsymbol, followoffset, data)
    inst.entity:SetParent(target.entity)
	
	if target.components.combat ~= nil and target.components.combat.hiteffectsymbol ~= nil and target.components.combat.hiteffectsymbol ~= "marker" then
		inst.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
	elseif target:HasTag("smallcreature") then
		inst.Transform:SetPosition(0, .5, 0)
	elseif target:HasTag("epic") then
		inst.Transform:SetPosition(0, 2.5, 0)
	else
		inst.Transform:SetPosition(0, 1.5, 0)
	end
	
	local duration = data ~= nil and data.powerlevel * 6 or 3
    inst.components.timer:StartTimer("buffover", duration + 1)

    inst.task = inst:DoPeriodicTask(3, OnTick, nil, target, data)
	
	inst:DoPeriodicTask(1, function()
		if target ~= nil then
			local sparkfx = SpawnPrefab("electricchargedfx")
			sparkfx.entity:SetParent(target.entity)
			sparkfx.Transform:SetPosition(0, 2, 0)
		end
	end)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
		inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target, followsymbol, followoffset, data)
	local duration = data ~= nil and data.powerlevel * 3 or 3

    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", duration)
end

local function buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() and target.components.combat ~= nil then
		target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
	end
	
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
	
    inst.AnimState:SetBank("slingshotammo")
    inst.AnimState:SetBuild("slingshotammo")
    inst.AnimState:PlayAnimation("spin_loop", false)
	inst.AnimState:OverrideSymbol("rock", "slingshotammo", "scrapfeather")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.persists = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("wixie_shockscrap_debuff", fn)