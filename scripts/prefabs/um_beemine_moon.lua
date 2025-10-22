require "prefabutil"

local function MineRattle(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_rattle")
    inst.rattletask = inst:DoTaskInTime(4 + math.random(), MineRattle)
end

local function StartRattleTask(inst, delay)
    if delay ~= nil then
        if inst.rattletask ~= nil then
            inst.rattletask:Cancel()
        end
        inst.rattletask = inst:DoTaskInTime(delay, MineRattle)
    elseif inst.rattletask == nil then
        inst.rattletask = inst:DoTaskInTime(4 + math.random(), MineRattle)
    end
end

local function StopRattleTask(inst)
    if inst.rattletask ~= nil then
        inst.rattletask:Cancel()
        inst.rattletask = nil
    end
end

local function StartRattling(inst, delay)
    inst.rattling = true
    if not inst:IsAsleep() then
        StartRattleTask(inst, delay)
    else
        inst.nextrattletime = delay ~= nil and GetTime() + delay or nil
    end
end

local function StopRattling(inst)
    inst.rattling = false
    inst.nextrattletime = nil
    StopRattleTask(inst)
end

local function OnEntitySleep(inst)
    if inst.rattling and inst.rattletask ~= nil then
        inst.nextrattletime = GetTime() + GetTaskRemaining(inst.rattletask)
    end
    StopRattleTask(inst)
end

local function OnEntityWake(inst)
    if inst.rattling then
        local t = inst.nextrattletime ~= nil and inst.nextrattletime - GetTime() or -1
        StartRattleTask(inst, t >= 0 and t or .5 + 4.5 * math.random())
    end
    inst.nextrattletime = nil
end

local TARGET_CANT_TAGS = { "insect", "playerghost" }
local TARGET_ONEOF_TAGS = { "character", "animal", "monster" }
local function SpawnBees(inst, target)
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_explo")
    if target == nil or not target:IsValid() then
        target = FindEntity(inst, 25, nil, nil, TARGET_CANT_TAGS, TARGET_ONEOF_TAGS)
    end
    if target ~= nil then
        for i = 1, 2 do
            local bee = SpawnPrefab(inst.beeprefab)
            if bee ~= nil then
                local x, y, z = inst.Transform:GetWorldPosition()
                local dist = math.random()
                local angle = math.random() * TWOPI
                bee.Physics:Teleport(x + dist * math.cos(angle), y, z + dist * math.sin(angle))
                if bee.components.combat ~= nil then
                    bee.components.combat:SetTarget(target)
                end
				bee.components.combat:SetRetargetFunction(3, nil)
				bee.components.combat:SetKeepTargetFunction(function(bee) return true end)
				bee:RemoveComponent("lootdropper")
				bee:AddComponent("lootdropper") -- wipe the lootdropper component
				bee.persists = false -- temp minion, no save/load
				bee:RemoveComponent("workable")
				bee:AddTag("soulless")
				
				bee:DoPeriodicTask(3,function(bee) -- Should I finish myself?
					if bee.components.combat and not bee.components.combat.target then
						bee.components.health:Kill()
					end
				end)
            end
        end
        target:PushEvent("coveredinbees")
    end
end

local function DoDamage(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,2,{"_combat","_health"},{ "FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	for i,v in ipairs(ents) do
		local damage = 75
		if v:HasTag("bee") then
			damage = damage * 0.25
		end
		v.components.combat:GetAttacked(inst,damage)
	end
end


local function OnExplode(inst)
    StopRattling(inst)
    if inst.spawntask ~= nil then -- We've already been told to explode
        return
    end
    inst.components.workable:SetWorkable(false)
    --inst.AnimState:PlayAnimation("explode")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_launch")
    SpawnBees(inst,inst.components.mine:GetTarget())
    SpawnPrefab("bomb_lunarplant_explode_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
	DoDamage(inst)
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("mine")
    inst.persists = false
    inst.Physics:SetActive(false)
    --V2C: mine is lost if save happens during these 9 frames
    --     but better than loading back into an invalid state
	inst:Remove()
end

local function onhammered(inst, worker)
    if inst.components.mine ~= nil then
        inst.components.mine:Explode(worker)
    end
end

local function ondeploy(inst, pt, deployer)
    inst.components.mine:Reset()
    inst.Physics:Stop()
    inst.Physics:Teleport(pt:Get())
end

local function OnReset(inst)
    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem.nobounce = true
    end
    if not inst:IsInLimbo() then
        inst.MiniMapEntity:SetEnabled(true)
    end
    if not (inst.AnimState:IsCurrentAnimation("idle") or inst.AnimState:IsCurrentAnimation("hit")) then
        if not inst:IsAsleep() then
            inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_rattle")
            inst.AnimState:PlayAnimation("reset")
            inst.AnimState:PushAnimation("idle", false)
        else
            inst.AnimState:PlayAnimation("idle")
        end
        StopRattling(inst) --force restart
    end
    StartRattling(inst)
end

local function SetSprung(inst)
    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem.nobounce = true
    end
    if not inst:IsInLimbo() then
        inst.MiniMapEntity:SetEnabled(true)
    end
    StartRattling(inst, 1)
end

local function SetInactive(inst)
    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem.nobounce = false
    end
    inst.MiniMapEntity:SetEnabled(false)
    inst.AnimState:PlayAnimation("inactive")
    StopRattling(inst)
end

local function OnDropped(inst)
    inst.components.mine:Deactivate()
end

local function OnHaunt(inst, haunter)
    if inst.components.mine == nil or inst.components.mine.inactive then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
        Launch(inst, haunter, TUNING.LAUNCH_SPEED_SMALL)
        return true
    elseif inst.components.mine.issprung then
        return false
    elseif math.random() <= TUNING.HAUNT_CHANCE_RARE then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
        inst.components.mine:Explode(nil)
        return true
    elseif inst.rattletask ~= nil then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
        inst.rattletask:Cancel()
        MineRattle(inst)
        return true
    end
    return false
end

local function BeeMine(name, alignment, skin, spawnprefab, isinventory)
    local assets =
    {
        Asset("ANIM", "anim/"..skin..".zip"),
        Asset("SOUND", "sound/bee.fsb"),
    }
    if name ~= "beemine" then
        table.insert(assets, Asset("MINIMAP_IMAGE", "beemine"))
    end

    local prefabs =
    {
        spawnprefab,
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
		inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2)

        inst.MiniMapEntity:SetIcon("um_beemine_moon.tex")

        inst.AnimState:SetBank(skin)
        inst.AnimState:SetBuild(skin)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("mine")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("mine")
        inst.components.mine:SetOnExplodeFn(OnExplode)
        inst.components.mine:SetAlignment(alignment)
        inst.components.mine:SetRadius(TUNING.BEEMINE_RADIUS)
        inst.components.mine:SetOnResetFn(OnReset)
        inst.components.mine:SetOnSprungFn(SetSprung)
        inst.components.mine:SetOnDeactivateFn(SetInactive)

        inst.beeprefab = spawnprefab

        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)

        if isinventory then
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:SetOnPutInInventoryFn(StopRattling)
            inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
            inst.components.inventoryitem:SetSinks(true)

            inst:AddComponent("deployable")
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        end

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnHaunt)

        inst.components.mine:Reset()

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
		
		
		inst.components.inventoryitem.onpickupfn = function(inst, pickupguy, src_pos)
			if pickupguy.components.inventory then
				local invmine = SpawnPrefab("um_beemine_moon_item")
				invmine:DoTaskInTime(0,function(invmine)
					pickupguy.components.inventory:GiveItem(invmine,nil,pickupguy:GetPosition())
				end)
			end
			inst:Remove()
		end
        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

local bomb_assets =
{
    Asset("ANIM", "anim/swap_um_beemine_moon.zip"),

    Asset("IMAGE", "images/map_icons/um_beemine_moon.tex"),
    Asset("ATLAS", "images/map_icons/um_beemine_moon.xml"),
}

local function OnMinePlant(inst, attacker, target)
	local x,y,z = inst.Transform:GetWorldPosition()
	local mines = TheSim:FindEntities(x,y,z,2,{"mine"})
	local mine
	if #mines == 0 then
		mine = SpawnPrefab("um_beemine_moon")
		mine.components.mine:Reset()
		mine.Physics:Stop()
		mine.AnimState:PlayAnimation("plant")
		mine.AnimState:PushAnimation("idle",true)
		
	else
		mine = SpawnPrefab("um_beemine_moon_item")
		mine.AnimState:PlayAnimation("plant_pop",false)
	end
	mine.Transform:SetPosition(x,y,z)
    inst:Remove()
end

local function common_fn(bank, build, anim, tag, isinventoryitem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    if isinventoryitem then
        MakeInventoryPhysics(inst)
    else
        inst.entity:AddPhysics()
        inst.Physics:SetMass(1)
        inst.Physics:SetFriction(0)
        inst.Physics:SetDamping(0)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.Physics:SetCapsule(0.2, 0.2)
        inst.Physics:SetDontRemoveOnSleep(true) -- so the object can land and put out the fire, also an optimization due to how this moves through the world
    end

    if tag ~= nil then
        inst:AddTag(tag)
    end

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")
	inst:AddTag("complexprojectile")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)

    if type(anim) ~= "table" then
        inst.AnimState:PlayAnimation(anim, true)
    elseif #anim == 1 then
        inst.AnimState:PlayAnimation(anim[1], true)
    else
        for i, a in ipairs(anim) do
            if i == 1 then
                inst.AnimState:PlayAnimation(a, false)
            elseif i ~= #anim then
                inst.AnimState:PushAnimation(a, false)
            else
                inst.AnimState:PushAnimation(a, true)
            end
        end
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")


    inst:AddComponent("complexprojectile")

    return inst
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_beemine_moon", "swap_um_beemine_moon")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function bomb_fn()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = common_fn("um_beemine_moon", "um_beemine_moon", "inactive", "weapon", true)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    MakeInventoryFloatable(inst, "med", 0.05, 0.65)



    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnMinePlant)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM
	
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true


    MakeHauntableLaunch(inst)

    return inst
end

return BeeMine("um_beemine_moon", "player", "um_beemine_moon", "um_bee_moon", true),
Prefab("um_beemine_moon_item", bomb_fn, bomb_assets)
