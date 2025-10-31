local assets =
{
    Asset("ANIM", "anim/um_gemologygems.zip"),
}
local gems = { "bluegem", "redgem", "purplegem", "orangegem", "yellowgem", "palegem" }


local function OnSave(inst, data)
    if inst.tier then
        data.tier = inst.tier
    end
    return data
end

local function OnLoad(inst, data)
    if data and data.tier then
        inst.tier = data.tier
    end
end

local function GetDisplayName(inst) -- Will be expanded upon to allow the player to see the name, similar to seeds.
    return "Strange Gem"
end

local function fncommon(gem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("um_gemologygems")
    inst.AnimState:SetBuild("um_gemologygems")
    inst.AnimState:PlayAnimation(gem)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --dummy comp for insight.
    inst:AddComponent("gemology_gem")

    inst:AddTag("gemologygem")

    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inventoryitem")

    inst.displaynamefn = GetDisplayName

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function FullReturn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function fnblue1()
    local inst = fncommon("bluegem1")
    return FullReturn(inst)
end
local function fnblue2()
    local inst = fncommon("bluegem2")
    return FullReturn(inst)
end
local function fnred1()
    local inst = fncommon("redgem1")
    return FullReturn(inst)
end
local function fnred2()
    local inst = fncommon("redgem2")
    return FullReturn(inst)
end
local function fnpurple1()
    local inst = fncommon("purplegem1")
    return FullReturn(inst)
end
local function fnpurple2()
    local inst = fncommon("purplegem2")
    return FullReturn(inst)
end
local function fnyellow1()
    local inst = fncommon("yellowgem1")
    return FullReturn(inst)
end
local function fnyellow2()
    local inst = fncommon("yellowgem2")
    return FullReturn(inst)
end
local function fngreen1()
    local inst = fncommon("greengem1")
    return FullReturn(inst)
end
local function fngreen2()
    local inst = fncommon("greengem2")
    return FullReturn(inst)
end
local function fnorange1()
    local inst = fncommon("orangegem1")
    return FullReturn(inst)
end
local function fnorange2()
    local inst = fncommon("orangegem2")
    return FullReturn(inst)
end
local function fnpale1()
    local inst = fncommon("palegem1")
    return FullReturn(inst)
end
local function fnpale2()
    local inst = fncommon("palegem2")
    return FullReturn(inst)
end

-- If any kind soul could convert this into a "for" loop, I'd appreciate it, I couldn't get it to work around the return, would cause a crash.
return Prefab("um_gemologybluegem1", fnblue1, assets),
       Prefab("um_gemologybluegem2", fnblue2),
       Prefab("um_gemologyredgem1", fnred1),
       Prefab("um_gemologyredgem2", fnred2),
       Prefab("um_gemologypurplegem1", fnpurple1),
       Prefab("um_gemologypurplegem2", fnpurple2),
       Prefab("um_gemologyyellowgem1", fnyellow1),
       Prefab("um_gemologyyellowgem2", fnyellow2),
       Prefab("um_gemologygreengem1", fngreen1),
       Prefab("um_gemologygreengem2", fngreen2),
       Prefab("um_gemologyorangegem1", fnorange1),
       Prefab("um_gemologyorangegem2", fnorange2),
       Prefab("um_gemologypalegem1", fnpale1),
       Prefab("um_gemologypalegem2", fnpale2)
