local assets =
{
    Asset("ANIM", "anim/um_lunartentacle.zip"),
}

SetSharedLootTable( 'um_lunartentacle',
{
    {'monstermeat',   1.0},
    {'monstermeat',   1.0},
    {'tentaclespike', 0.5},
    {'tentaclespots', 0.2},
})

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "prey" }
local function retargetfn(inst)
    if not (inst.components.combat and inst.components.combat.target) then
        return FindEntity(
            inst,
            20,
            function(guy)
                return guy.prefab ~= inst.prefab
                    and guy.entity:IsVisible()
                    and not guy.components.health:IsDead()
                    and (guy.components.combat.target == inst or
                        guy:HasTag("character") or
                        guy:HasTag("monster") or
                        guy:HasTag("animal"))
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS)
    end
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.entity:IsVisible()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and target:IsNear(inst, 28)
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        return
    end

    local current_target = inst.components.combat.target

    if current_target == nil then
        --Don't want to handle initiating attacks here;
        --We only want to handle switching targets.
        return
    elseif current_target == data.attacker then
        --Already targeting our attacker, just update the time
        inst._last_attacker = current_target
        inst._last_attacked_time = GetTime()
        return
    end

    local time = GetTime()
    if inst._last_attacker == current_target and
        inst._last_attacked_time + TUNING.TENTACLE_ATTACK_AGGRO_TIMEOUT >= time then
        --Our target attacked us recently, stay on it!
        return
    end

    --Switch to new target
    inst.components.combat:SetTarget(data.attacker)
    inst._last_attacker = data.attacker
    inst._last_attacked_time = time
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.Transform:SetTwoFaced()
    inst.Physics:SetCylinder(0.25, 2)

    inst.AnimState:SetBank("um_lunartentacle")
    inst.AnimState:SetBuild("um_lunartentacle")
    inst.AnimState:PlayAnimation("idle_retreated")
    inst.scrapbook_anim ="atk_idle"
    --inst.AnimState:SetScale(-1,1)
    
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("WORM_DANGER")
	inst:AddTag("tentacle")
    inst:AddTag("NPCcanaggro")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._last_attacker = nil
    inst._last_attacked_time = nil

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TENTACLE_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetRange(28,3)
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(GetRandomWithVariance(1, 0.5), retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)

    MakeLargeFreezableCharacter(inst)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('um_lunartentacle')

    inst:AddComponent("acidinfusible")
    inst.components.acidinfusible:SetFXLevel(1)
    inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.BERSERKER)

    inst:SetStateGraph("SGum_tentacle_moon")

    inst:ListenForEvent("attacked", OnAttacked)

    --inst.raised = false
    inst.sg:GoToState("idle_ground")

    local scale = 1.25
    inst.Transform:SetScale(scale,scale,scale)

    return inst
end

return Prefab("um_tentacle_moon", fn, assets)