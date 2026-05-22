local assets =
{
    Asset("ANIM", "anim/um_fyre_bomb.zip"),
    Asset("ANIM", "anim/swap_um_fyre_bomb.zip"),

    Asset("ANIM", "anim/swap_um_bomb_moon.zip"),
    Asset("ANIM", "anim/um_bomb_moon.zip"),
}

local should_hit = {"_combat", "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable"}
local shouldnt_hit = {"INLIMBO", "notarget", "noattack", "playerghost"}
local ACTIONS_TO_WORK = {
    [ACTIONS.CHOP] = 15,
    [ACTIONS.HAMMER] = 4,
    [ACTIONS.DIG] = 1
}
local function OnHitFyre(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("explosivehit")
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(1.25, 1.25, 1.25)
    fx.persists = false
    fx:DoTaskInTime(1, fx.Remove)
    local ents = TheSim:FindEntities(x, y, z, 3, nil, shouldnt_hit, should_hit)
    if #ents > 0 then
        for i, v in pairs(ents) do
            if (not v:HasTag("player") or v == attacker) then
                if v.components.burnable and v.components.burnable.canlight then
                    v.components.burnable:Ignite(true, inst, attacker)
                end
                if v.components.combat then
                    v.components.combat:GetAttacked(attacker, TUNING.DSTU.PYREBOMB_DAMAGE)
                end
            end
            local workable = v.components.workable
            if workable and not v.components.health and not v:HasTag("NET_workable") then workable:WorkedBy(attacker, ACTIONS_TO_WORK[workable.action] or 3) end
        end
    end
    inst:Remove()
end

local function OnHitMutate(inst, attacker, target)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("um_lunar_explosion")
    fx.AnimState:HideSymbol("fx_icon")
    fx.Transform:SetPosition(x,y,z)
    --fx.Transform:SetScale(1.25, 1.25, 1.25)
    fx.persists = false
    --fx.AnimState:PlayAnimation("impact3_special")
    --fx.hideanim:set(true)
    fx.SoundEmitter:PlaySound("meta4/winona_catapult/lunar_projectile_explode")
    fx:ListenForEvent("animover", fx.Remove)
    
    local ents = TheSim:FindEntities(x, y, z, 5)
    local mutation_count = 0
    local mutation_limit = 12
    if #ents > 0 then
        for i, v in pairs(ents) do
            if (not v:HasTag("player") or v == attacker) then
                local mutated = false
                if v.components.halloweenmoonmutable and mutation_count < mutation_limit then
                    mutated = true
                    mutation_count = mutation_count + 1
                    v.components.halloweenmoonmutable:Mutate()
                end
                if v.components.combat and v.components.health and not v.components.health:IsDead() and not mutated and not inst:HasAnyTag(shouldnt_hit) then
                    local mult = 1
                    if v:HasAnyTag("shadow","shadowcreature","nightmarecreature","shadow_aligned","player_shadow_aligned") then
                        mult = mult * 3 -- AXE Lunar bomb is exceptionally effective against shadow creatures
                    end
                    if v:HasAnyTag("lunar_aligned","player_lunar_aligned") or v.components.halloweenmoonmutable then
                        mult = mult * 0.33 -- AXE Lunar bomb is exceptionally less effective against lunar creatures, or those than can mutate
                    end
                    v.components.combat:GetAttacked(attacker, mult * 150)
                end
                if v.components.sanity then
                    v.components.sanity:DoDelta(50)
                end
            end
        end
    end
    inst:Remove()
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_"..inst.bank, "swap_"..inst.bank)
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
        if not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
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

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true
    inst.components.reticule.validfn = function(inst) return true end
    MakeInventoryFloatable(inst, "med", 0.05, 0.65)
    inst:AddTag("allow_action_on_impassable")

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")
    inst:AddTag("complexprojectile")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.bank = bank

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

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("equippable")
    inst.components.equippable.equipstack = true
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)
    return inst
end

local function fyre_bomb_fn()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = common_fn("um_fyre_bomb", "um_fyre_bomb", "idle", "weapon", true)

    if not TheWorld.ismastersim then
        return inst
    end
 
    inst.components.complexprojectile:SetOnHit(OnHitFyre) 

    return inst
end

local function moon_bomb_fn()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = common_fn("um_bomb_moon", "um_bomb_moon", "idle", "weapon", true)

    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.complexprojectile:SetHorizontalSpeed(25)
    inst.components.complexprojectile:SetOnHit(OnHitMutate)
    inst.components.weapon:SetRange(12, 12)
    inst.components.weapon.toss_range_override = 12 --AXE override the usual toss range, additional code in init_actions passes this value

    return inst
end

local function explosionfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(1, 1, 1)

	inst.entity:SetPristine()

	
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:SetBuild("um_lunar_explosion")
    inst.AnimState:SetBank("um_lunar_explosion")
    inst.AnimState:PlayAnimation("impact3_special")
    inst.Transform:SetScale(1,1,1)
	inst.Light:Enable(true)
    inst:ListenForEvent("animover", function(inst) inst:Remove() end)

    return inst
end

return Prefab("um_fyre_bomb", fyre_bomb_fn, assets),
Prefab("um_bomb_moon", moon_bomb_fn, assets),
Prefab("um_lunar_explosion", explosionfn)
