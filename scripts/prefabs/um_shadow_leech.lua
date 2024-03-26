local assets =
{
	Asset("ANIM", "anim/shadow_leech.zip"),
}

local prefabs =
{
	"nightmarefuel",
}

local brain = require("brains/um_shadow_leechbrain")

local LOOT = { "nightmarefuel" }

local function CalcSanityAura(inst, observer)
	return -TUNING.SANITYAURA_MED
end

local function ToggleBrain(inst, enable)
	if enable then
		inst:SetBrain(brain)
		if inst.brain == nil and not inst:IsAsleep() then
			inst:RestartBrain()
		end
	else
		inst:SetBrain(nil)
	end
end

local function StartTrackingDaywalker(inst, daywalker)
	inst.components.entitytracker:TrackEntity("daywalker", daywalker)
	if daywalker.StartTrackingLeech ~= nil then
		daywalker:StartTrackingLeech(inst)
	end
end

local function OnFlungFrom(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	if inst.owner ~= nil then
		x, y, z = inst.owner.Transform:GetWorldPosition()
		inst:RemoveEventCallback("locomote", inst._onlocomote, inst.owner)
	end
	
	inst.owner = nil
	inst:Show()
	
	if inst.leechfx ~= nil then
		inst.leechfx:Remove()
		inst.leechfx = nil
	end
	
	if inst.damagetask ~= nil then
		inst.damagetask:Cancel()
		inst.damagetask = nil
	end
	
	local rot = inst.Transform:GetRotation() + math.random() * 10 - 5
	inst.Transform:SetRotation(rot + 180) --flung backwards
	rot = rot * DEGREES
	inst.Physics:Teleport(x + math.cos(rot), y, z - math.sin(rot))
	inst.sg:GoToState("flung", 1)
end

local function startdamaging(inst, data)
	if inst.owner ~= nil and inst.owner.components.inventoryitem ~= nil then
		inst.owner = inst.owner.components.inventoryitem.owner
	end
	
    if inst.owner ~= nil then
		if inst.owner.components.health ~= nil and not inst.owner.components.health:IsDead() then
			inst.owner.components.health:DoDelta(-1)
			
			if inst.owner.components.grogginess ~= nil then
				if (inst.owner.components.grogginess.grog_amount + .2) >= inst.owner.components.grogginess:GetResistance() then
					inst.owner.components.grogginess:MaximizeGrogginess()
				else
					inst.owner.components.grogginess:AddGrogginess(.2, 1)
				end
			end
			
			if inst.owner.components.grogginess ~= nil and inst.owner.components.grogginess:IsKnockedOut() then
				inst.OnFlungFrom(inst)
			end
		else
			inst.OnFlungFrom(inst)
		end
	else
		inst.OnFlungFrom(inst)
		if inst.task ~= nil then
			inst.task:Cancel()
		end
		
		inst.task = nil
	end
end

local function StartLeeching(inst, owner)
	if owner ~= nil then
		inst.owner = owner
		
		inst:Hide()
		
		inst.leechfx = SpawnPrefab("um_shadow_leech_fx")
		inst.leechfx.entity:AddFollower()
		inst.leechfx.components.highlightchild:SetOwner(owner)
		inst.leechfx.Follower:FollowSymbol(owner.GUID, "swap_hat", 0 + math.random(-70, 70), 0 + math.random(-70, 70), 0)
		inst.leechfx.Transform:SetRotation(math.random(360))
			
		inst:ListenForEvent("locomote", inst._onlocomote, inst.owner)
				
		if inst.damagetask == nil then
			inst.damagetask = inst:DoPeriodicTask(1, startdamaging)
		end
	else
		inst.OnFlungFrom(inst)
	end
end

local function retargetfn(inst)
	local target = 
	FindEntity(
				inst,
                15,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                { "player" },
                { "playerghost" }
            )
        or FindEntity(
				inst,
                30,
                function(guy)
                    return inst.components.combat:CanTarget(guy) and not guy:IsInLight()
                end,
                { "player" },
                { "playerghost" }
            )
        or nil
	
	return target
end

local function Invade(inst, target)
	if target ~= nil and target:HasTag("player") and target.components.inventory ~= nil then
		if target.components.inventory:IsFull() then
			inst.components.thief:StealItem(target)
		end
		--inst.components.inventoryitem.canbepickedup = true
		inst.components.combat:ShareTarget(target, 30, ShareTargetFn, 1)
		
		target.components.inventory:GiveItem(inst)
	end
end

local function toground(inst)
	if inst.damagetask ~= nil then
		inst.damagetask:Cancel()
		inst.damagetask = nil
	end
	
	if inst.task ~= nil then
		inst.task:Cancel()
		inst.task = nil
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 0.9)
	inst.Physics:ClearCollisionMask()
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.WORLD)

	inst.Transform:SetSixFaced()
	inst.Transform:SetScale(0.5, 0.5, 0.5)

	inst:AddTag("monster")
    inst:AddTag("hostile")   
    inst:AddTag("swilson") 
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")
	inst:AddTag("um_shadow_leech")

	inst.AnimState:SetBank("shadow_leech")
	inst.AnimState:SetBuild("shadow_leech_nt")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	inst.AnimState:UsePointFiltering(true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.wiggle_count = 0

	inst:AddComponent("entitytracker")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.SHADOW_LEECH_HEALTH)
	inst.components.health.nofadeout = true
	inst.components.health.canmurder = false

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(LOOT)

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.SHADOW_LEECH_RUNSPEED * 3
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetAttackPeriod(5)
    inst.components.combat:SetRange(3, 3)
	
    inst:AddComponent("thief")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false
	--inst.components.inventoryitem.cangoincontainer = true
	inst.components.inventoryitem:SetSinks(false)

	inst:SetStateGraph("SGum_shadow_leech")
	inst:SetBrain(brain)

	inst.ToggleBrain = ToggleBrain
	inst.StartLeeching = StartLeeching
	inst.OnFlungFrom = OnFlungFrom
	inst.Invade = Invade
	
    inst._onlocomote = function(owner)
		inst.wiggle_count = inst.wiggle_count + 1
				
		if inst.wiggle_count >= 150 then
			inst.wiggle_count = 0
			inst.OnFlungFrom(inst)
		end
    end

	return inst
end

local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst.Transform:SetSixFaced()
	inst.Transform:SetScale(0.8, 0.8, 0.8)

	inst:AddTag("FX")

	inst.AnimState:SetBank("shadow_leech")
	inst.AnimState:SetBuild("shadow_leech_nt")
	inst.AnimState:PlayAnimation("attach_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	inst.AnimState:UsePointFiltering(true)
	
	inst:AddComponent("highlightchild")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.SoundEmitter:PlaySound("daywalker/leech/suck", "suckloop")
	inst.persists = false

	return inst
end

return Prefab("um_shadow_leech", fn, assets, prefabs),
		Prefab("um_shadow_leech_fx", fxfn, assets, prefabs)