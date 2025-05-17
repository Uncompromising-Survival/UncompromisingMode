local assets =
{
    Asset("ANIM", "anim/snaildrakebucket.zip"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_empty.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_empty.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_lava_low.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_lava_low.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_lava_med.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_lava_med.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_lava_full.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_lava_full.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_water_low.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_water_low.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_water_med.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_water_med.tex"),
    
    Asset("ATLAS", "images/inventoryimages/snaildrakebucket_water_full.xml"),
    Asset("IMAGE", "images/inventoryimages/snaildrakebucket_water_full.tex"),
    
}

local function UpdateInvAndAnim(inst,name)
    inst.components.inventoryitem.atlasname = resolvefilepath("images/inventoryimages/snaildrakebucket_"..name..".xml")
    inst.components.inventoryitem:ChangeImageName("snaildrakebucket_"..name)
    inst.AnimState:PlayAnimation(name)
end

local function ChangeSprite(inst)
    local name
    if inst.uses == 0 then
        name = "empty"
        UpdateInvAndAnim(inst,name)
    elseif inst.uses == 1 then
        name = inst.contains.."_low"
        UpdateInvAndAnim(inst,name)
    elseif inst.uses == 2 then
        name = inst.contains.."_med"
        UpdateInvAndAnim(inst,name)
    elseif inst.uses == 3 then
        name = inst.contains.."_full"
        UpdateInvAndAnim(inst,name)
    end    
end

local ignoretags = { "FX", "DECOR", "INLIMBO", "burnt" }

local function SpreadProtectionAtPoint(x, y, z, dist) -- This is taken from WateryProtection because including that component tries to allow a "water" action on farms, this should not be the case... (This is the simplest way to circumvent)
    local ents = TheSim:FindEntities(x, y, z, dist, nil, ignoretags)
    for i, v in ipairs(ents) do
        if v.components.burnable ~= nil then
            if v.components.witherable ~= nil then
                v.components.witherable:Protect(TUNING.WATERINGCAN_PROTECTION_TIME)
            end
            if v.components.burnable:IsBurning() or v.components.burnable:IsSmoldering() then
                v.components.burnable:Extinguish(true, TUNING.WATERINGCAN_EXTINGUISH_HEAT_PERCENT)
            end

        end
        if v.components.temperature ~= nil then
            v.components.temperature:SetTemperature(v.components.temperature:GetCurrent() - TUNING.WATERINGCAN_TEMP_REDUCTION/10)
        end
        if v.components.moisture ~= nil then
            local waterproofness = v.components.moisture:GetWaterproofness()
            v.components.moisture:DoDelta(10 * (1 - waterproofness))
        elseif v.components.inventoryitem ~= nil then
            v.components.inventoryitem:AddMoisture(10)
        end
    end

    -- Goo
    local ents = TheSim:FindEntities(x, y, z, 2*dist, {"um_washable_goo"})
    for i, v in ipairs(ents) do
        if v.prefab == "ratpoison" then
            v:Remove()
        elseif not (v.isfading and v._isfading:value()) then
            v.OnStartFade(v)
        end
    end



    if TheWorld.components.farming_manager ~= nil then
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z, 100)
    end
    for _x = -4,4 do
        for _z = -4,4 do
            if TheWorld.components.farming_manager ~= nil then
                TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x+_x, y, z+_z, 100)
            end
        end
    end
end

local function ondeploy(inst, pt, deployer)
    local effect
    if inst.contains == "lava" then
        effect = SpawnPrefab("snaildrake_magma_sludge")
    elseif inst.contains == "water" then
        effect = SpawnPrefab("mudpuddle_splash")
        SpreadProtectionAtPoint(pt.x,pt.y,pt.z,4)
        effect.Transform:SetScale(2,1,2)
    end
    if effect then
        effect.Transform:SetPosition(pt.x,pt.y,pt.z)
    end
    
    inst.uses = inst.uses - 1
    if inst.uses == 0 then
        inst.components.fueled:StopConsuming()
        inst:RemoveComponent("deployable")
    end
    ChangeSprite(inst)
end


local function CanDeploy(inst, pt, mouseover, deployer, rot)
    return true
end

local function EnableDeploy(inst)
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable.keep_in_inventory_on_deploy = true
    inst.components.deployable.mode = DEPLOYMODE.ANYWHERE
    --inst._custom_candeploy_fn = CanDeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
end

local function FillWater(inst)
    if TheWorld.state.iswinter then
        inst.components.fueled.rate = 20
    else
        inst.components.fueled.rate = 1
    end
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/small")
    inst.contains = "water"
end

local function FillLava(inst)
    inst.components.fueled.rate = 5
    inst.contains = "lava"
end

local function OnFill(inst, from_object)
    inst.uses = 3
    inst.components.fueled:StartConsuming()
     
    if not inst.components.deployable then
        EnableDeploy(inst)
    end
    if from_object and from_object:HasTag("lava") then
        FillLava(inst)
    else
        FillWater(inst)
    end
    ChangeSprite(inst)
    return true
end

local function OnSave(inst, data)
    data.uses = inst.uses
    if inst.contains then
        data.contains = inst.contains
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.uses ~= nil and data.uses > 0 then
        inst.uses = data.uses
        EnableDeploy(inst)
    end
    if data and data.contains then
        inst.contains = data.contains
    end
    ChangeSprite(inst)
end

local function ExplodeContents(inst)
    if inst.contains and inst.uses ~= 0 then
        if inst.contains == "water" and TheWorld.state.iswinter then
            SpawnPrefab("ice").Transform:SetPosition(inst.Transform:GetWorldPosition())
        elseif inst.contains == "lava" then
            SpawnPrefab("snaildrake_magma_sludge").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
    inst.components.lootdropper:DropLoot()
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_pot")
    inst:Remove()
end

local function EvaluateFueledRate(inst,iswinter)
    if inst.contains and inst.contains == "water" and inst.uses ~= 0 then
        if iswinter then
            inst.components.fueled.rate = 20
        else
            inst.components.fueled.rate = 1
        end
    end
end

local function getstatus(inst)
    if inst.contains and inst.uses ~= 0 then
        if inst.contains == "water" then
            return "WATER"
        elseif inst.contains == "lava" then
            return "LAVA"
        end
    else
        return "GENERIC"
    end
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("snaildrakebucket")
    inst.AnimState:SetBuild("snaildrakebucket")
    inst.AnimState:PlayAnimation("empty")



    inst:AddTag("usedeploystring")
    inst:AddTag("um_bucket")
    
    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = resolvefilepath("images/inventoryimages/snaildrakebucket_empty.xml")
    inst.components.inventoryitem:ChangeImageName("snaildrakebucket_empty")
    
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("singingshell")

    
    inst:AddComponent("fillable")
    inst.components.fillable.overrideonfillfn = OnFill
    inst.components.fillable.showoceanaction = true
    inst.components.fillable.acceptsoceanwater = false
    inst.components.fillable.oceanwatererrorreason = "UNSUITABLE_FOR_PLANTS"

    
    inst.uses = 0 -- Not using finiteuses because we'll be using durability for the shell itself, the image will change to represent how much liquid is in it.
    
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(8*60*70) -- Standard rate is a whole year
    inst.components.fueled:SetDepletedFn(ExplodeContents)
    inst.components.fueled.no_sewing = true
    
    inst:WatchWorldState("iswinter", EvaluateFueledRate) -- Dynamic fuel consumption rate for shell w/ water in it during winter

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
        
    MakeHauntableLaunch(inst)
    --------------------------------------------------------------

    return inst
end

return Prefab("snaildrakebucket", fn, assets),
MakePlacer("snaildrakebucket_placer", nil, nil, nil)