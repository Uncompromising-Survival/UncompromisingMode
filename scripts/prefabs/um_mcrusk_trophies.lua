local assets =
{
    Asset("ANIM", "anim/um_mcrusk_trophies.zip"),
}

local prefabs_normal =
{
}


local types = {"ground","barrel","shelf"}
local groundtype = {"beefalo","greatworm"}

local function PlayAnimation(inst)
    local animname
    if inst.type == 1 then
        animname = groundtype[inst.groundtype]
    end
    if inst.type == 2 then
        animname = "barrel_"..inst.barreltype1.."_"..inst.barreltype2
    end
    if inst.type == 3 then
        animname = "shelf_"..inst.shelftype1.."_"..inst.shelftype2
    end  
    inst.AnimState:PlayAnimation(animname,false)
    print(animname)
end

local nameoverrides = {"UM_MCRUSK_TROPHIES_GROUND","UM_MCRUSK_TROPHIES_BARREL","UM_MCRUSK_TROPHIES_SHELF"}

local function RollRandomAnimations(inst)
    if not inst.type then
        inst.type = math.random(1,3)
    end
    if inst.type == 1 then
        if not inst.groundtype then
            inst.groundtype = math.random(1,2)
        end
    end
    if inst.type == 2 then
        if not inst.barreltype1 then
            inst.barreltype1 = math.random(1,2)
            inst.barreltype2 = math.random(1,4)
        end
    end
    if inst.type == 3 then
        if not inst.shelftype1 then
            inst.shelftype1 = math.random(1,15)
            inst.shelftype2 = math.random(1,3)
        end
    end
    inst.components.named.possiblenames = {STRINGS.NAMES[nameoverrides[inst.type]]}
    inst.components.named:PickNewName()
    PlayAnimation(inst)
end

local function OnSave(inst)
    local data = {}
    if inst.type then
        data.type = inst.type
    end
    if inst.groundtype then
        data.groundtype = inst.groundtype
    end
    if inst.barreltype1 then
        data.barreltype1 = inst.barreltype1
        data.barreltype2 = inst.barreltype2
    end
    if inst.shelftype1 then
        data.shelftype1 = inst.shelftype1
        data.shelftype2 = inst.shelftype2
    end
    return data
end

local function OnLoad(inst, data)
    if data then
        if data.type then
            inst.type = data.type
        end
        if data.groundtype then
            inst.groundtype = data.groundtype
        end
        if data.barreltype1 then
            inst.barreltype1 = data.barreltype1
            inst.barreltype2 = data.barreltype2
        end
        if data.shelftype1 then
            inst.shelftype1 = data.shelftype1
            inst.shelftype2 = data.shelftype2
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBuild("um_mcrusk_trophies")
    inst.AnimState:SetBank("um_mcrusk_trophies")

    --inst.MiniMapEntity:SetIcon("um_mcrusk_trophy.tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0,RollRandomAnimations)

    inst:AddComponent("inspectable")
    inst:AddComponent("named")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab( "um_mcrusk_trophies", fn, assets, prefabs_normal )
