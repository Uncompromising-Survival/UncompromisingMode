local assets =
{
    Asset("ANIM", "anim/um_reeds_lunar.zip"),
    --Asset("MINIMAP_IMAGE", "driftwood_small1"),
}


SetSharedLootTable( 'um_reeds_lunar',
{
    {'cutreeds',           1.0},
    {'cutreeds',           1.0},
    {'cutgrass',           1.0},
    {'cutgrass',           1.0},
})

local function on_chop(inst, chopper, remaining_chops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("turnoftides/common/together/driftwood/chop")
    end

    if remaining_chops > 0 then
        inst.AnimState:PlayAnimation("chop")
		inst.AnimState:PushAnimation("idle")
    end
end

local function RemoveWorkable(inst)
	inst:RemoveComponent("workable")
	inst.AnimState:PushAnimation("idle_chopped",true)
end


local function on_chopped_down(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/appear_wood")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble",nil,.4)

	inst.AnimState:PlayAnimation("fall")
	
	
	inst.components.lootdropper:DropLoot()
	inst.components.timer:StartTimer("regrow",5*60*8)
	
	RemoveWorkable(inst)
end

local function AddWorkable(inst,regrow)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.CHOP)

    -- Enable the two types of driftwood to be tuned separately.
    local work_amount = 4
    inst.components.workable:SetWorkLeft(work_amount)

    inst.components.workable:SetOnWorkCallback(on_chop)
    inst.components.workable:SetOnFinishCallback(on_chopped_down)
	if regrow then
		inst.AnimState:PlayAnimation("regrow")
	end
    inst.AnimState:PushAnimation("idle",true)
end



local function Regrow(inst)
	AddWorkable(inst,true)
end

local function on_burnt(inst)
	inst.components.lootdropper:SpawnLootPrefab("ash")
    inst:Remove()
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- All driftwood trees are sharing a single minimap icon, since they're functionally the same.
    -- inst.MiniMapEntity:SetIcon("driftwood_small1.png")
    -- inst.MiniMapEntity:SetPriority(-1)

    inst:AddTag("plant")

    inst.AnimState:SetBank("um_reeds_lunar")
    inst.AnimState:SetBuild("um_reeds_lunar")
	inst:AddComponent("umripples")
    inst.components.umripples.xscale = 1.2
    inst.components.umripples.yscale = 1.2
    inst.components.umripples.zscale = 1.2
	--inst.components.um_ripples.vert_offset = 0.1
	--inst.components.um_ripples.should_parent_effect = true
	
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end


    MakeMediumBurnable(inst)
    inst.components.burnable:SetOnBurntFn(on_burnt)
    MakeMediumPropagator(inst)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("um_reeds_lunar")



    MakeHauntableWorkAndIgnite(inst)

    local color = 0.7 + math.random() * 0.3
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("inspectable")
	
	inst:DoTaskInTime(0,function(inst)
		if inst.components.timer:TimerExists("regrow") then
			RemoveWorkable(inst)
		else
			AddWorkable(inst)
		end
	end)


	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone",Regrow)
    MakeSnowCovered(inst)

	return inst
end

return Prefab("um_reeds_lunar", fn, assets)
