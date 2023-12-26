local assets =
{
	Asset("ANIM", "anim/shadow_leech.zip"),
}

local prefabs =
{
	"nightmarefuel",
}

local brain = require("brains/nightcrawlerbrain")

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

local function OnSpawnFor(inst, daywalker, delay)
	StartTrackingDaywalker(inst, daywalker)
	inst:ForceFacePoint(daywalker.Transform:GetWorldPosition())
	inst.sg:GoToState("spawn_delay", delay)
end

local function startwiggling(inst, data)
	inst.randomimage = math.random(1, 8)
	
	inst.components.inventoryitem.atlasname = "images/inventoryimages/nervoustick_"..inst.randomimage..".xml"
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

	inst:AddTag("monster")
    inst:AddTag("hostile")   
    inst:AddTag("swilson") 
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")

	inst.AnimState:SetBank("shadow_leech")
	inst.AnimState:SetBuild("shadow_leech")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	inst.AnimState:UsePointFiltering(true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

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
	inst.components.locomotor.runspeed = TUNING.SHADOW_LEECH_RUNSPEED + 2
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetAttackPeriod(5)
    inst.components.combat:SetRange(6, 3)
	
    inst:AddComponent("thief")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false
	--inst.components.inventoryitem.cangoincontainer = true
	inst.components.inventoryitem:SetSinks(false)
	
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", OnFlungFrom)
	
	inst:WatchWorldState("isday", function() 
		--inst:Remove()
	end)
	
	inst:WatchWorldState("iscaveday", function() 
		--inst:Remove()
	end)

	inst:SetStateGraph("SGnightcrawler")
	inst:SetBrain(brain)

	inst.ToggleBrain = ToggleBrain
	inst.OnSpawnFor = OnSpawnFor
	--inst.OnFlungFrom = OnFlungFrom
	inst.Invade = Invade

	return inst
end

return Prefab("um_nightcrawler", fn, assets, prefabs)