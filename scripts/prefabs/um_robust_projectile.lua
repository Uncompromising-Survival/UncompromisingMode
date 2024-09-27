
--------------------------------------------------------------------------------------------------------------------
-- Wiltfly Flame Unique Code
local function WiltflyFlame_OnCollide(inst, other)
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("player") then
		if other.components.burnable ~= nil then
			other.components.burnable:Ignite()
		end
	end
end

local WiltflyFlame_AURA_EXCLUDE_TAGS = { "playerghost", "abigail", "companion", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "invisible" }
local function WiltflyFlame_Burn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 1.5, nil, WiltflyFlame_AURA_EXCLUDE_TAGS)
	
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

local function WiltflyFlame_shrinktask_mini(inst) inst.components.sizetweener:StartTween(inst.finishsize, inst.endperiod, inst.Remove) end

local function WiltflyFlame_grow_mini(inst) inst.components.sizetweener:StartTween(inst.endsize, inst.period, WiltflyFlame_shrinktask_mini) end

--------------------------------------------------------------------------------------------


local function GeneralLaunch(inst,dest,speed) -- From projectile
    local direction = dest - inst:GetPosition()
    direction:Normalize()
    local angle = math.acos(direction:Dot(Vector3(1, 0, 0))) / DEGREES
    inst.Transform:SetRotation(angle)
    inst:FacePoint(dest)
	
	
	inst.Physics:SetMotorVel(speed, 0, 0)
end

local function WiltflyFlame_Init(inst)

	-- Animations
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fire_large_character")
    inst.AnimState:SetBuild("fire_large_character")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)
    inst.AnimState:PlayAnimation("loop_large", true)

	-- Physics
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCapsule(1.5, 1.5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES) -- Flames stop around structures, walls can be used to redirect flames
	-- Collision Call
	inst:ListenForEvent("on_collide", WiltflyFlame_OnCollide)
 	
	-- Sounds
	inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
	inst.SoundEmitter:PlaySound("dontstarve/common/campfire", "fire")
	
	-- Damaging Effect
	inst:DoPeriodicTask(FRAMES, WiltflyFlame_Burn)

	
	-- Timed Removal
	inst:DoTaskInTime(5, inst.Remove)
		
	-- Tween Settings
	inst.startsize = 0.8 -- How big the fire begins
	inst.endsize = 1 -- How big fire gets
	inst.finishsize = 0.1 -- How big the fire ends
	
	inst.period = 2 -- time before shrinking
	inst.endperiod = 0.5 -- time taken to shrink
	
	inst.Transform:SetScale(inst.startsize, inst.startsize, inst.startsize)
	
	inst:AddComponent("sizetweener")
	inst.WiltflyFlame_grow_mini = WiltflyFlame_grow_mini
	inst:DoTaskInTime(0,function(inst) inst:WiltflyFlame_grow_mini() end)
end


--------------------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
	

	
    inst:AddTag("NOCLICK")
    inst:AddTag("blunt")
    inst:AddTag("weapon")
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.attacker = nil
	
	inst:AddTag("NOCLICK")
    inst.persists = false	
	
	
	
	inst.WiltflyFlame_Init = WiltflyFlame_Init
	inst.GeneralLaunch = GeneralLaunch
	
	inst.WiltflyFlame_Init(inst)
	
	-- test launch
	local dest = inst:GetPosition() + Vector3(1,0,0)
	GeneralLaunch(inst,dest,15)
	
    
	
    return inst
end

return Prefab("um_robust_projectile", fn)