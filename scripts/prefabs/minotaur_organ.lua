local assets =
{
    Asset("ANIM", "anim/minotaur_organ.zip"),
}

local function TellMinotaurImDead(inst)
	if inst.minotaur then
		inst.minotaur:DoTaskInTime(0,function(minotaur) minotaur:OrganUpdate(minotaur) end)
	end
end

local function OnKilled(inst)
	inst.AnimState:PlayAnimation("death")
	inst:ListenForEvent("animover",TellMinotaurImDead)
end

local function AnimNext(inst)
	if inst.components.health and not inst.components.health:IsDead() then
		if FindEntity(inst,4,nil,{"player"},{"playerghost"}) and not inst:HasTag("forcefield") then
			inst.AnimState:PlayAnimation("beat_danger",false)
		else
			if (FindEntity(inst,10,nil,{"player"},{"playerghost"}) and not inst:HasTag("forcefield")) or (FindEntity(inst,4,nil,{"player"},{"playerghost"}) and inst:HasTag("forcefield")) then
				inst.AnimState:PlayAnimation("beat_faster",false)
			else
				inst.AnimState:PlayAnimation("beat",false)
			end
		end
	end
end


local function DeactivateShield(inst)
	inst.Physics:ClearCollisionMask()
	inst.Physics:Stop()
	inst.Physics:CollidesWith(COLLISION.WORLD)
    if inst:HasTag("forcefield") then
		inst:RemoveTag("forcefield")
        if inst._fx ~= nil then
            inst._fx:kill_fx()
            inst._fx = nil
        end
        if inst._unshieldtask ~= nil then
			inst._unshieldtask:Cancel()
		end
    end
end

local function ActivateShield(inst)
	if TheSim:FindFirstEntityWithTag("minotaur") and not inst.minotaur then --Updating it this way till we get a fix
		local minotaur = TheSim:FindFirstEntityWithTag("minotaur")
		inst.minotaur = minotaur
		minotaur:OrganUpdate(minotaur)
	elseif inst.minotaur then
		minotaur:OrganUpdate(minotaur)
	end
end

local function oncollide(inst, other)
	if other:HasTag("minotaur") and (Vector3(other.Physics:GetVelocity()):LengthSq() > 42) then
		other:DoTaskInTime(2*FRAMES,function(other) other.sg:GoToState("stun") end) --We want AG to stun here, so you can attack the organ without being harrased.
		inst:DoTaskInTime(2 * FRAMES, DeactivateShield)
	end
end

local function organfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("minotaur_organ")
    inst.AnimState:SetBuild("minotaur_organ")
    inst.AnimState:PlayAnimation("enter",false)
	inst.AnimState:PushAnimation("beat",false)
	

	inst:AddTag("minotaur_organ")
	inst:AddTag("monster") --We want it to be easy to hit this thing.
	
	MakeCharacterPhysics(inst, 99999, 0.5) --Cannot be pushed by the player, but the AG will be able to remove the shield.
	
    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)
	
	inst:AddComponent("combat")
	inst:ListenForEvent("death", OnKilled) --Forces the death animation as soon as the organ is killed.
	inst:ListenForEvent("animqueueover",AnimNext) --Dynamically changes heartbeat based on how close players are and wether or not the organ has a shield.
	inst:DoTaskInTime(1,ActivateShield)
	inst.DeactivateShield = DeactivateShield
	
	inst.Physics:SetCollisionCallback(oncollide) -- Easier to do collision from this end
	return inst
end


return Prefab("minotaur_organ", organfn, assets)