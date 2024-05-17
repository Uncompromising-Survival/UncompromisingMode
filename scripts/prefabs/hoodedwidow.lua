local brain = require "brains/hoodedwidowbrain"

local loot =
{
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "silk",
    "silk",
    "silk",
    "silk",
	"widowsgrasp",
	"widowshead",
	"silksack",
}


local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "structure", "bird", "snapdragon" }
local RETARGET_ONE_OF_TAGS = { "player" }
local function Retarget(inst)
    if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() and not inst.sg:HasStateTag("attack") then
        local newtarget = FindEntity(inst, 9, 
            function(guy)
                return inst.components.combat:CanTarget(guy)
					--distsq(spx, spz, dx, dz) >= (TUNING.DRAGONFLY_RESET_DIST*12) 
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
			RETARGET_ONE_OF_TAGS
        )

        if newtarget ~= nil then
            inst.components.combat:SetTarget(newtarget)
        end
    end
end

local function CalcSanityAura(inst, observer)
    return observer:HasTag("spiderwhisperer") and -TUNING.SANITYAURA_HUGE*1.25 or -TUNING.SANITYAURA_HUGE
end

local function OnAttacked(inst, data)
    if data.attacker and not inst.sg:HasStateTag("attack")then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function DoDespawn(inst)
    --Schedule new spawn time
    --Called at the time the hooded widow actually leaves the world.
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    if home ~= nil then
        home.components.childspawner:GoHome(inst)
        --home.components.childspawner:StartSpawning()
		inst:AddTag("home")
    else
        inst:Remove() --Hooded Widow was probably debug spawned in?
    end
	
end

local function OnLoad(inst)
	inst.investigated = false
end

local function ShouldDodge(inst)
	--TheNet:Announce("Redefining")
	local x,y,z = inst.Transform:GetWorldPosition() --This is actually a fallback incase widow somehow doesn't have a target when attempting to do a special (her abilities really depend on her having a target)
	if inst.components.combat and inst.components.combat.target then
		x,y,z = inst.components.combat.target.Transform:GetWorldPosition()
	end
	local mindist = 99999
	local xtest,ztest,xnew,znew
	xnew = x --Fallback if somehow xnew and znew aren't redefined in the loop below (they should be)
	znew = z
	for i = 1,8 do
		xtest = x + 10*math.cos(3.14*i/4+0.01*math.random(-50,50))
		ztest = z + 10*math.sin(3.14*i/4+0.01*math.random(-50,50))
		--SpawnPrefab("maxwell_smoke").Transform:SetPosition(xtest,y,ztest) --For testing which points widow will dodge to with visuals
		if mindist > inst:GetDistanceSqToPoint(xtest,y,ztest) and TheWorld.Map:IsAboveGroundAtPoint(xtest,y,ztest) and #TheSim:FindEntities(xtest,y,ztest,3,{"giant_tree"}) == 0 then --We're looking for the dodge position closest to widow
			mindist = inst:GetDistanceSqToPoint(xtest,y,ztest)
			xnew = xtest
			znew = ztest
		end
	end
    inst._dodgedest = Vector3(xnew,y,znew)
	if inst.components.combat.target then
		inst._enemypos = inst.components.combat.target:GetPosition()
	end
end

local function TryPowerMove(inst)
	ShouldDodge(inst) --Timer's up, lets get a position to dodge to
end


local function Reset(inst)
    inst.reset = true
end

local function OnKilledOther(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:TryRetarget()
	end
	if inst.investigatedtask ~= nil then
		inst.investigatedtask:Cancel()
		inst.investigatedtask = nil
	end
	inst.investigated = nil
	inst.investigatedtask = inst:DoTaskInTime(5, function(inst) inst.investigated = true end)
end

local function EpicsCheck(inst)  --Widow will not tolerate being bullied by epics, you go fight them yourself!
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 20, { "epic" }, { "hoodedwidow","leif" } )
	
	if inst.components.homeseeker ~= nil and inst.components.homeseeker.home and inst:GetDistanceSqToInst(inst.components.homeseeker.home) > TUNING.DRAGONFLY_RESET_DIST*20 then
		inst.bullier = true
	end
	
	for i, v in pairs(ents) do
		if v ~= nil and v.components.combat ~= nil and v.components.combat.target ~= nil and v.components.combat.target == inst then
			inst.bullier = true
		end
	end
end

local function OnHitOther(inst, data)
	local other = data.target
	local blocked = false
	if data.target and data.target.sg and data.target.sg:HasStateTag("shell") then
		blocked = true
	end
	if other and not other:HasTag("webbedcreature") and blocked == false then
		if not inst.combosucceed then
			--TheNet:SystemMessage("Combo Succeed!")
			inst.combosucceed = true
		end
		if inst.combo ~= 1 or inst.docombo then
			inst.combo = inst.combo/10
		end
	end
	inst.armorcrunch = nil
	if other ~= nil and other.components.inventory ~= nil and blocked == false then -- Armor Crunch  (no inst.armorcrunch conditional)
		local helm = other.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		local chest = other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
		local hand = other.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if helm ~= nil and helm.components.armor ~= nil then
			helm.components.armor:TakeDamage(33)
		end
		if chest ~= nil and chest.components.armor ~= nil then
			chest.components.armor:TakeDamage(33)
		end
		if hand ~= nil and hand.components.armor ~= nil then
			hand.components.armor:TakeDamage(33)
		end
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, 1)

    inst.DynamicShadow:SetSize(7, 3)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("epic")
    inst:AddTag("largecreature")
    inst:AddTag("hoodedwidow")
    --inst:AddTag("spiderqueen")  --She left this faction
    --inst:AddTag("spider")

    inst.AnimState:SetBank("widow")
    inst.AnimState:SetBuild("widow1")
    inst.AnimState:PlayAnimation("idle", true)
	inst.Transform:SetScale(1.5,1.5,1.5)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	--inst.should_go_tired = false
			
    inst:SetStateGraph("SGhoodedwidow")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("drownable")

    ---------------------
    MakeLargeBurnableCharacter(inst, "body")
    MakeLargeFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DSTU.WIDOW_HEALTH)
    inst:AddComponent("healthtrigger")
    --inst.components.healthtrigger:AddTrigger(0.5, function(inst)
		--inst.should_go_tired = true
	--end)
    ------------------
    inst:AddComponent("knownlocations")
    inst:AddComponent("combat")
	inst.components.combat.battlecryenabled = false -- We want to taunt in only specific instances
    inst.components.combat:SetRange(TUNING.SPIDERQUEEN_ATTACKRANGE)
	
    if inst.components.combat ~= nil then
		local function queensstuff(ent)
			if ent ~= nil and not ent:HasTag("queensstuff") then -- fix to friendly AOE: refer for later AOE mobs -Axe
				return true
			end
		end
        inst.components.combat:SetAreaDamage(TUNING.SPIDERQUEEN_ATTACKRANGE, 1, queensstuff) -- you can edit these values to your liking -Axe
    end
    inst.components.combat:SetDefaultDamage(160)
	inst.components.combat.customdamagemultfn = function(inst,target) 
		if target:HasTag("player") then 
			return 0.5 
		else 
			return 1
		end
	end
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, Retarget)
	inst:AddComponent("groundpounder")
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.platformPushingRings = 2
    inst.components.groundpounder.numRings = 3

    ------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    ------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor.walkspeed = 3
	inst.components.locomotor.runspeed = 3

    ------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!

    ------------------

	inst:AddComponent("vetcurselootdropper")
	inst.components.vetcurselootdropper.loot = "um_hoodedwidow_soul"
	
    ------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("leader")

    MakeHauntableGoToState(inst, "poop", TUNING.HAUNT_CHANCE_OCCASIONAL, TUNING.HAUNT_COOLDOWN_MEDIUM, TUNING.HAUNT_CHANCE_LARGE)
	inst:AddComponent("groundpounder")
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 0
    inst.components.groundpounder.destructionRings = 2
    inst.components.groundpounder.platformPushingRings = 2
    inst.components.groundpounder.numRings = 3
    ------------------
	inst.investigated = false
	inst.Reset = Reset
    inst.DoDespawn = DoDespawn
    inst:SetBrain(brain)
	inst.OnLoad = OnLoad
    inst:ListenForEvent("attacked", OnAttacked)
	inst.combo = 1
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", TryPowerMove)
	inst.components.timer:StartTimer("pounce",10+math.random(-3,1))
	inst.components.timer:StartTimer("mortar",20+math.random(-1,5))
	inst:DoPeriodicTask(3, EpicsCheck)
	inst.ShouldDodge = ShouldDodge
	inst.combosucceed = true
	inst.docombo = false
	
	inst.turn_speed = 0
	inst.turns = 0
	inst.chargespeed = 7/3
	
	inst:ListenForEvent("killed", OnKilledOther)
	inst:ListenForEvent("onhitother", OnHitOther)

	--inst.go_up_fucking_tree = true
	
    return inst
end
return Prefab("hoodedwidow", fn)
