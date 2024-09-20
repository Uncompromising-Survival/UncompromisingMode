local ink_assets =
{
    Asset("ANIM", "anim/squid_watershoot.zip"),
}

local ink_prefabs =
{
    "ink_splash",
    "ink_puddle_land",
    "ink_puddle_water",
}

local function oncollide(inst, other)
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("player") then
		if other.components.burnable ~= nil then
			other.components.burnable:Ignite()
		end
	end
end

local function onthrown_eye(inst)

    inst:AddTag("NOCLICK")
    inst.persists = false
	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCapsule(1.5, 1.5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
end

local function no(inst)
	if target ~= nil and target:IsValid() then
        if target.components.burnable ~= nil then
			target.components.burnable:Ignite()
		end
    end
end

local function shrinktask_mini(inst)
	inst.components.sizetweener:StartTween(0.1, 1, inst.Remove)
end

local function grow_mini(inst, time, startsize, endsize)
	inst.Transform:SetScale(0.1, 0.1, 0.1)
	inst.components.sizetweener:StartTween(0.9, 1 + math.random(), shrinktask_mini)
end

local AURA_EXCLUDE_TAGS = { "playerghost", "abigail", "companion", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "invisible" }

local function Burn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, nil, AURA_EXCLUDE_TAGS)
	
	for i, v in ipairs(ents) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo() then
            if v:IsValid() and not v:IsInLimbo() then
                if v.components.fueled == nil and
                    v.components.burnable ~= nil and
                    not v.components.burnable:IsBurning() and
                    not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end

                if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
                    v.components.combat:GetAttacked(inst, 1, inst.attacker)
                end
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
	
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fire_large_character")
    inst.AnimState:SetBuild("fire_large_character")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)
    inst.AnimState:PlayAnimation("loop_large", true)
	
    inst:AddTag("NOCLICK")
    inst:AddTag("blunt")
    inst:AddTag("weapon")
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.attacker = nil
	
	inst:AddComponent("sizetweener")
	inst.grow_mini = grow_mini
	inst:grow_mini()

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetHorizontalSpeed(15)
    inst.components.linearprojectile:SetGravity(-0.1)
    inst.components.linearprojectile:SetLaunchOffset(Vector3(2, 1, 0))
    inst.components.linearprojectile:SetOnLaunch(onthrown_eye)
    inst.components.linearprojectile:SetOnHit(no)
    inst.components.linearprojectile.usehigharc = false
	
    --inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstSmall")
    inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
	inst.SoundEmitter:PlaySound("dontstarve/common/campfire", "fire")

    inst.persists = false

    inst:AddComponent("locomotor")
	inst:DoTaskInTime(.5, Burn)

	inst:DoTaskInTime(5, inst.Remove)

    return inst
end

return Prefab("flamethrower_projectile", fn, ink_assets, ink_prefabs)