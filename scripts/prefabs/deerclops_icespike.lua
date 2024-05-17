local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
local NON_COLLAPSIBLE_TAGS = { "bearger", "bird", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local easing = require("easing")

local function ShatterIce(inst, attacker, target)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 3, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            if v.components.combat ~= nil
                and v.components.health ~= nil
                and not v:HasTag("bearger")
                and not v.components.health:IsDead() then
                if v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, 30)
                end
            end
        end
    end
	
	local boat = TheWorld.Map:GetPlatformAtPoint(x, z)
		
	inst.fx = "groundpound_fx"
	
	if boat then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
		local sinkhole = SpawnPrefab("antlion_sinkhole_boat")
		sinkhole.Transform:SetPosition(x, 0, z)
	elseif inst:IsOnOcean() then
		inst.fx = "splash_green"
	else
		inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
	end
					
	SpawnPrefab(inst.fx).Transform:SetPosition(x, 0, z)
	local ring = SpawnPrefab("deer_ice_circle")
	ring.Transform:SetPosition(x, 0, z)
	ring.Transform:SetScale(0.65, 0.65, 0.65)
	
    inst:Remove()
end

local function oncollide(inst, other)
	local x, y, z = inst.Transform:GetWorldPosition()
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("projectile") or y <= inst:GetPhysicsRadius() + 0.001 then
		inst.big = true
		ShatterIce(inst, other)
	end
end


local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.AnimState:SetBank("deerclops_iceprojectile")
    inst.AnimState:SetBuild("deerclops_iceprojectile")
    inst.AnimState:PlayAnimation("launch_loop")

	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst:SetPhysicsRadiusOverride(2.5)
	--inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)
	
    inst.Physics:SetCollisionCallback(oncollide)
end

local function projectilefn()
    local inst = CreateEntity()
	
    inst:AddTag("projectile")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("deerclops_iceprojectile")
    inst.AnimState:SetBuild("deerclops_iceprojectile")
    inst.AnimState:PlayAnimation("launch_loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-20)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, .1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitInk)
    inst.components.complexprojectile.usehigharc = false

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.owner = inst.clawer

    inst.persists = false

    inst:AddComponent("locomotor")

	inst:DoTaskInTime(5, inst.Remove)

    return inst
end

return Prefab("deerclops_icespike", projectilefn)
