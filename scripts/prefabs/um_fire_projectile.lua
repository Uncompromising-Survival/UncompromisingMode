local LIGHT_COLOUR = RGB(255, 255, 192)
local firelevels =
{
	{anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.1},
	{anim="level2", sound="dontstarve/common/campfire", radius=3, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.3},
	{anim="level3", sound="dontstarve/common/campfire", radius=4, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.6},
	{anim="level4", sound="dontstarve/common/campfire", radius=5, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=1},
}

local function Shrink(inst)
	inst.scale = inst.scale - .015
	inst.components.propagator.heatoutput = 12 - (6 - 6 * inst.scale)
	inst.components.propagator.propagaterange = inst.proprange - (1 - .5 * inst.scale)
	inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
	if inst.scale < 0 then
		inst:Remove()
	end
end

local function BurnSurroundings(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local burnables = TheSim:FindEntities(x, 0, z, inst.scale * 2, nil, inst.dont_hit_tags) -- There isn't a way to search for entities tagged as burnable.... (there is no burnable tag)
	local damage = inst.damage or 1
	for i,v in ipairs(burnables) do
		if v.components.burnable then
			v.components.burnable:Ignite()
		end
		if v.components.health then
			v.components.health:DoFireDamage(inst.damage, inst.damager, true)
		end
		if v.components.combat and inst.damager then
			v.components.combat:SuggestTarget(inst.damager)
		end
		if v.prefab == "snowpile" then
			SpawnPrefab("splash_snow_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
			v:Remove()
		end
	end
end


local function BeginScaleDown(inst)
	inst:DoTaskInTime(inst.time,function(inst)
		inst.Physics:SetMotorVel(0, 0, 0)
		inst:DoPeriodicTask(FRAMES, Shrink)
	end)	
end

local function Grow(inst)
	inst.scale = inst.scale + .03
	inst.components.propagator.heatoutput = 12 - (6 - 6 * inst.scale)
	inst.components.propagator.propagaterange = inst.proprange - (1 - .5 * inst.scale)
	inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
	if inst.scale > inst.scalemax then
		inst.growing:Cancel()
		inst.growing = nil
		BeginScaleDown(inst)
	end
end


local function BeginScaleUp(inst,time)
	inst.scale = inst.scale/6
	inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
	inst.growing = inst:DoPeriodicTask(FRAMES,Grow)
end

local function Shoot(inst)
	local speed = inst.speed or 10
	if not inst.time then
		inst.time = .01
	end
	local time_to_extinguish = inst.totaltime or 6
	inst.Physics:SetMotorVel(speed, 0, 0)
	MakeLargePropagator(inst)
	inst.components.propagator.heatoutput = 12
	inst.proprange = inst.components.propagator.propagaterange
    MakeLargeBurnable(inst, time_to_extinguish)
	inst.components.burnable:SetOnIgniteFn(nil)
    inst.components.burnable:SetOnExtinguishFn(inst.Remove)
	inst.components.burnable.fxdata[1].prefab = "character_fire"
    inst.components.burnable:Ignite()
	if not inst.scale then
		inst.scale = 1
	end
	inst.scalemax = inst.scale
	BeginScaleUp(inst)
	inst:DoPeriodicTask(FRAMES, BurnSurroundings)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fire")
    inst.AnimState:SetBuild("fire")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)

    inst:AddTag("FX")
	MakeInventoryPhysics(inst)

	
    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetMass(1)
    inst.Physics:SetDamping(.1)	
	inst.Physics:SetFriction(.3)
	inst.Physics:SetRestitution(.5)
	inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
	inst.Physics:SetCollisionMask(
		COLLISION.WORLD,
		COLLISION.OBSTACLES,
		COLLISION.SMALLOBSTACLES
	)
	
	inst:DoTaskInTime(0, Shoot)
	inst.dont_hit_tags = {"INLIMBO"} -- When adding more tags elsewhere do this when creating this prefab, please. inst.dont_hit_tags = JoinArrays(inst.dont_hit_tags, yourtablehere)

    return inst
end

return Prefab("um_fire_projectile", fn)