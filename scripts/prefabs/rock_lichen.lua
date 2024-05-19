local assets = {
    Asset("ANIM", "anim/rock_lichen.zip"),
	Asset("IMAGE", "images/map_icons/rock_lichen.tex"),
	Asset("ATLAS", "images/map_icons/rock_lichen.xml"),
}

SetSharedLootTable( 'rock_lichen', {
    {'marble', 1.00},
    {'marble', 1.00},
})

local function makeemptyfn(inst)
    if not POPULATING and (
        inst.AnimState:IsCurrentAnimation("idle_dead")) then
        inst.AnimState:PlayAnimation("dead_to_empty")
        inst.AnimState:PushAnimation("empty", false)
    else
        inst.AnimState:PlayAnimation("empty")
    end
    inst.components.workable:SetWorkable(true)
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING then
        inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
        inst.AnimState:PushAnimation("idle_dead", false)
    else
        inst.AnimState:PlayAnimation("idle_dead")
    end
    inst.components.workable:SetWorkable(true)
end

local function getstatus(inst)
    return ((inst.components.pickable and not inst.components.pickable:CanBePicked())) and "PICKED"
end

local function onpickedfn(inst, picker)
    if inst.components.pickable then
        inst.components.workable:SetWorkable(true)

        inst.AnimState:PlayAnimation("lichenmost_picked")

        if inst.components.pickable:IsBarren() then
            inst.AnimState:PushAnimation("idle_dead")
        else
            inst.AnimState:PushAnimation("idle")
        end
    end
end

local function getregentimefn(inst)
    return TUNING.LIMPET_REGROW_TIME
end

local function pickanim(inst)
    if inst.components.pickable then
        if inst.components.pickable:CanBePicked() then
            return "lichenmost"
        else
            if inst.components.pickable:IsBarren() then
                return "idle_dead"
            else
                return "idle"
            end
        end
    end

    return "idle"
end

local function makefullfn(inst)
    inst.components.workable:SetWorkable(false)
    inst.AnimState:PlayAnimation(pickanim(inst))
end

local function onworked(inst, worker, workleft)
    local pt = Point(inst.Transform:GetWorldPosition())
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(pt)
        if inst.components.pickable:CanBePicked() then
			inst.components.lootdropper:SpawnLootPrefab("lichen", pt)
        end
        inst:Remove()
    else
        if workleft < 2*TUNING.ROCKS_MINE*(1/3) then
            inst.AnimState:PlayAnimation("low")
            inst.components.pickable.paused = true
        elseif workleft < 2*TUNING.ROCKS_MINE*(2/3) then
            inst.AnimState:PlayAnimation("med")
            inst.components.pickable.paused = true
		else
            inst.AnimState:PlayAnimation("idle")
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("rock_lichen.tex")
	
    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("rock_lichen")
    inst.AnimState:SetBuild("rock_lichen")
    inst.AnimState:PlayAnimation("lichenmost", false)

    --witherable (from witherable component) added to pristine state for optimization
    inst:AddTag("lichen")  -- for horticulture book
    --inst:AddTag("witherable") no withering lichen
    inst:AddTag("dont_auto_mine") --stop those nasty shadowminions

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    MakeHauntableWork(inst)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_lichen"
    inst.components.pickable:SetUp("cutlichen", 10*8*60)
    inst.components.pickable.getregentimefn = getregentimefn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makebarrenfn = makebarrenfn
    inst.components.pickable.makefullfn = makefullfn

    --inst.components.pickable.ontransplantfn = ontransplantfn

    -- local variance = math.random() * 4 - 2
    -- inst.makewitherabletask = inst:DoTaskInTime(TUNING.WITHER_BUFFER_TIME + variance, function(inst)
        -- inst:AddComponent("witherable")
    -- end)



    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('rock_lichen')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(2*TUNING.ROCKS_MINE)
    inst.components.workable:SetOnWorkCallback(onworked)

    inst.components.workable:SetWorkable(false)

    return inst
end

return Prefab("rock_lichen", fn, assets)