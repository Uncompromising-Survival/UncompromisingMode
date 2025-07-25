require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/um_ribopodden.zip"),
    Asset("IMAGE", "images/map_icons/um_ribopodden.tex"),
    Asset("ATLAS", "images/map_icons/um_ribopodden.xml"),
}

local prefabs_normal =
{
}



local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    if data ~= nil then

    end
end

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.FROG_POND_SPAWN_TIME, TUNING.FROG_POND_REGEN_TIME)
end

local function commonfn(pondtype)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBuild("um_ribopodden")
    inst.AnimState:SetBank("um_ribopodden")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("um_ribopodden.tex")

    -- From watersource component
    inst:AddTag("birdblocker")


	inst:SetDeploySmartRadius(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("childspawner")

    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)


    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function ReturnChildren(inst)
    for k, child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.homeseeker ~= nil then
            child.components.homeseeker:GoHome()
        end
        child:PushEvent("gohome")
    end
end

local function OnInit(inst)
    inst.components.childspawner:StartSpawning()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("build",false)
	inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_place")
	--the global animover handler will restart the check task
end
	
local function onhammered(inst, worker)
    if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("rock")
    inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hammer")
	inst.AnimState:PushAnimation("idle")
end

local function den()
    local inst = commonfn("")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.childspawner:SetSpawnPeriod(TUNING.FROG_POND_SPAWN_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.FROG_POND_REGEN_TIME)
	

	inst.components.childspawner:SetMaxChildren(3)


    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childname = "um_ribopod"

    inst.dayspawn = true
    inst.task = inst:DoTaskInTime(0, OnInit)

    inst.OnPreLoad = OnPreLoad
	
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

	
	inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab( "um_ribopodden", den, assets, prefabs_normal ),
    MakePlacer("um_ribopodden_placer", "um_ribopodden", "um_ribopodden", "idle")
