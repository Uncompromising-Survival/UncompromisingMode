local assets =
{
    Asset("ANIM", "anim/um_gemforge.zip"),
}


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)
	-- local minimap = inst.entity:AddMiniMapEntity()
    -- inst.MiniMapEntity:SetIcon("houndious_observious_map.tex")

    inst.AnimState:SetBank("um_gemforge")
    inst.AnimState:SetBuild("um_gemforge")
	inst.AnimState:PlayAnimation("idle",false)

    inst:AddTag("structure")
	
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
   
		
    return inst
end


return Prefab("um_gemologyforge", fn, assets)
