local assets =
{
	Asset("ANIM", "anim/shadow_leech.zip"),
}

local prefabs =
{
	"nightmarefuel",
}

local brain = require("brains/um_nightcrawlerbrain")

local sounds =
{
    attack = "UCSounds/um_heckler/hawk",
    attack_grunt = "UCSounds/um_heckler/spit",
    death = "UCSounds/um_heckler/death",
    idle = "dontstarve/sanity/creature1/idle",
    taunt = "UCSounds/um_heckler/taunt",
    appear = "UCSounds/um_heckler/appear",
    disappear = "UCSounds/um_heckler/attacked",
}

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

local function OnSpawnFor(inst, daywalker, delay)
	StartTrackingDaywalker(inst, daywalker)
	inst:ForceFacePoint(daywalker.Transform:GetWorldPosition())
	inst.sg:GoToState("spawn_delay", delay)
end

local function startwiggling(inst, data)
	inst.randomimage = math.random(1, 8)
	
	--inst.components.inventoryitem.atlasname = "images/inventoryimages/nervoustick_"..inst.randomimage..".xml"
	inst.components.inventoryitem:ChangeImageName("nervoustick_"..inst.randomimage.."")
end

local function startdamaging(inst, data)
    inst.owner = inst.components.inventoryitem.owner
	
	if inst.owner ~= nil and inst.owner.components.inventoryitem ~= nil then
		inst.owner = inst.owner.components.inventoryitem.owner
	end
	
    if inst.owner ~= nil then
		if inst.owner.components.health ~= nil and not inst.owner.components.health:IsDead() then
			inst.owner.components.health:DoDelta(-1)
		end
	else
		if inst.task ~= nil then
			inst.task:Cancel()
		end
		inst.task = nil
	end
end

local function topocket(inst, owner)
    --cancelblink(inst)
	if inst.task == nil then
		inst.task = inst:DoPeriodicTask(0.2, startwiggling)
		inst.damagetask = inst:DoPeriodicTask(1, startdamaging)
	end
    --tostore(inst, owner)
end

local function OnFlungFrom(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = inst.Transform:GetRotation() + math.random() * 10 - 5
	inst.Transform:SetRotation(rot + 180) --flung backwards
	rot = rot * DEGREES
	inst.Physics:Teleport(x + math.cos(rot), y, z - math.sin(rot))
	inst.sg:GoToState("flung", 1)
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

local function ItemCheck(inst)
	if inst.components.inventory:IsFull() then
		inst.fat = true
		inst.components.locomotor.runspeed = 3
		inst.Transform:SetScale(0.35, 0.35, 0.35)
	else
		inst.fat = false
		inst.components.locomotor.runspeed = 6
		inst.Transform:SetScale(0.3, 0.3, 0.3)
	end
end

local function CheckLight(inst)
	if inst.components.inventory:IsFull() and not Um_CustomLightCheck(inst, 0.01, .1) then
		if not inst.sg:HasStateTag("death") then
			inst.sg:GoToState("death")
		end
	end
end

local function Retarget(inst)
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

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()
	inst.entity:AddLightWatcher()

	MakeCharacterPhysics(inst, 1, 0.5)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	--inst.Physics:CollidesWith(COLLISION.WORLD)

	inst.AnimState:SetBank("um_nightcrawler")
	inst.AnimState:SetBuild("um_nightcrawler")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	inst.AnimState:UsePointFiltering(true)
	
	inst.Transform:SetScale(0.3, 0.3, 0.3)

	inst.Transform:SetFourFaced()

	inst:AddTag("monster")
    inst:AddTag("hostile")   
    inst:AddTag("swilson") 
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst.HostileToPlayerTest = function() return true end
    inst.sounds = sounds
	inst.fat = false

	inst:AddComponent("entitytracker")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)
	inst.components.health.nofadeout = true

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = 6
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	
	inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 1
	
    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRange(2)
    inst.components.combat:SetRetargetFunction(3, Retarget)
	
	inst:ListenForEvent("itemget", ItemCheck)
	inst:ListenForEvent("itemlose", ItemCheck)

	inst:SetStateGraph("SGum_nightcrawler")
	inst:SetBrain(brain)
	
	inst:DoPeriodicTask(.5, CheckLight)

	return inst
end

return Prefab("um_nightcrawler", fn, assets, prefabs)