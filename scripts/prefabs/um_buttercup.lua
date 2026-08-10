local assets =
{
    Asset("ANIM", "anim/um_buttercup.zip"),
}

local prefabs =
{
    "petals",
    "flower_evil",
    "flower_withered",
}

local function onpickedfn(inst, picker)
    local pos = inst:GetPosition()

    if picker ~= nil and picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
        picker.components.sanity:DoDelta(TUNING.SANITY_SMALL)
    end

    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos })
end

local FINDLIGHT_MUST_TAGS = { "daylight", "lightsource" }
local function DieInDarkness(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0,z, TUNING.DAYLIGHT_SEARCH_RANGE, FINDLIGHT_MUST_TAGS)
    for i,v in ipairs(ents) do
        local lightrad = v.Light:GetCalculatedRadius() * .7
        if v:GetDistanceSqToPoint(x,y,z) < lightrad * lightrad then
            return
        end
    end
    inst:Remove()
    SpawnPrefab("flower_withered").Transform:SetPosition(x,y,z)
end

local function OnIsCaveDay(inst, isday)
    if isday then
        inst:DoTaskInTime(5.0 + math.random()*5.0, DieInDarkness)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_buttercup")
    inst.AnimState:SetBuild("um_buttercup")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:PlayAnimation("idle")

    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2)

    inst:AddTag("flower")
    inst:AddTag("cattoy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "FLOWER"

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true
    inst.components.pickable.wildfirestarter = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    if TheWorld:HasTag("cave") then
        inst:WatchWorldState("iscaveday", OnIsCaveDay)
    end

    MakeHauntableChangePrefab(inst, "flower_evil")

    return inst
end

return Prefab("um_buttercup", fn, assets, prefabs)