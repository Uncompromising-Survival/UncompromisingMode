local assets =
{
    Asset("ANIM", "anim/pied_piper_flute.zip"),
}

local function TryAddFollower(leader, follower)
    local buffduration = leader:HasTag("ratwhisperer") and 120 or 30
    if leader.components.leader and
        follower.components.follower and
        --[[(follower.components.follower.leader and
        follower.components.follower.leader.prefab == "pied_rat" or nil) and]]
        follower:HasTag("raidrat") and
        (leader:HasTag("ratwhisperer") or leader.components.leader:CountFollowers("raidrat") < 12) then
		follower.components.follower:SetLeader(leader)
		follower:PiedPiperBuff(buffduration)
        follower:RemoveTag("hostile")
        --[[leader.components.leader:AddFollower(follower)
        follower.components.follower:AddLoyaltyTime(60 + math.random())]]
        if follower.components.combat ~= nil and follower.components.combat:TargetIs(leader) then
            follower.components.combat:SetTarget(nil)
        end
        if not leader:HasTag("ratwhisperer") and follower.components.inventory and follower:HasTag("carrying") and follower._item then
            follower.components.inventory:DropEverything()
            follower:RemoveTag("carrying")
            follower._item:Remove()
            follower._item = nil
        end
    end
end

local function HearHorn(inst, musician, instrument)
    if musician.components.leader ~= nil and
        inst.prefab == "uncompromising_rat" then
        if inst.components.combat ~= nil and inst.components.combat:HasTarget() then
            inst.components.combat:GiveUp()
        end
        TryAddFollower(musician, inst)
    end

	if inst.components.farmplanttendable ~= nil then
		inst.components.farmplanttendable:TendTo(musician)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("pied_piper_flute")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")
    inst:AddTag("donotautopick")
    
    inst.AnimState:SetBank("pied_piper_flute")
    inst.AnimState:SetBuild("pied_piper_flute")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.25)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("instrument")
    inst.components.instrument.range = TUNING.HORN_RANGE
    inst.components.instrument:SetOnHeardFn(HearHorn)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(3)
    inst.components.finiteuses:SetUses(3)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pied_piper_flute", fn, assets)
