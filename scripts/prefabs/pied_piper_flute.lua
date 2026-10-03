local assets =
{
    Asset("ANIM", "anim/pied_piper_flute.zip"),
}

local function TryAddFollower(leader, follower)
    local buffduration = leader:HasTag("ratwhisperer") and 120 or 30
    if leader.components.leader and follower.components.follower and
        --[[(follower.components.follower.leader and
        follower.components.follower.leader.prefab == "pied_rat" or nil) and]]
        follower:HasTag("raidrat") and (leader:HasTag("ratwhisperer") or leader.components.leader:CountFollowers("raidrat") < 12) then
		follower.components.follower:SetLeader(leader)
		follower:PiedPiperBuff(buffduration)
        --[[leader.components.leader:AddFollower(follower)
        follower.components.follower:AddLoyaltyTime(60 + math.random())]]
    end
end

local function HearHorn(inst, musician, instrument)
    if musician.components.leader and inst.prefab == "um_rat" then
        if inst.components.combat and inst.components.combat:HasTarget() then
            inst.components.combat:SetTarget(nil)
        end
        TryAddFollower(musician, inst)
    end

	if inst.components.farmplanttendable then
		inst.components.farmplanttendable:TendTo(musician)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    
    anim:SetBank("pied_piper_flute")
    anim:SetBuild("pied_piper_flute")
    anim:PlayAnimation("idle")

    inst:AddTag("pied_piper_flute")
    inst:AddTag("tool")

    MakeInventoryFloatable(inst, "med", .25)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local instrument = inst:AddComponent("instrument")
    instrument.range = TUNING.HORN_RANGE
    instrument:SetOnHeardFn(HearHorn)

    local tool = inst:AddComponent("tool")
    tool:SetAction(ACTIONS.PLAY)

    local finiteuses = inst:AddComponent("finiteuses")
    finiteuses:SetMaxUses(3)
    finiteuses:SetUses(3)
    finiteuses:SetOnFinished(inst.Remove)
    finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pied_piper_flute", fn, assets)