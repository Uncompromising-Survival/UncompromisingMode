local assets = {
    Asset("ANIM", "anim/rock_lichen.zip"),
	Asset("IMAGE", "images/map_icons/rock_lichen.tex"),
	Asset("ATLAS", "images/map_icons/rock_lichen.xml"),
}

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

	inst:DoTaskInTime(0,function(inst) -- Leave this in for rest of closed beta, then remove this file
		SpawnPrefab("um_spongeplant").Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst:Remove()
	end)
	
    return inst
end

return Prefab("rock_lichen", fn, assets)