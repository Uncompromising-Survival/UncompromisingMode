local assets =
{
    Asset("ANIM", "anim/um_buttercup.zip"),
}

local prefabs =
{
    "petals",
    "flower_evil",
    "flower_withered",
    "small_puff",
    "charlierose",
}

local function ToggleRose(inst, toggle)
    if toggle and inst.rose or not toggle and not inst.rose then return end
    local anim = inst.AnimState
    if toggle then
        anim:SetBank("flowers")
        anim:SetBuild("flowers")
        anim:PlayAnimation("rose")
        inst:AddTag("thorny")
        inst._isrose:set(true)
        inst:OnIsRoseDirty()
        inst.rose = true
    else
        anim:SetBank("um_buttercup")
        anim:SetBuild("um_buttercup")
        anim:PlayAnimation("idle")
        inst:RemoveTag("thorny")
        inst._isrose:set(false)
        inst:OnIsRoseDirty()
        inst.rose = nil
    end
end

local function onsave(inst, data)
    data.rose = inst.rose or nil
end

local function onload(inst, data)
    ToggleRose(inst, data.rose)
end

local function onpickedfn(inst, picker)
    local pos = inst:GetPosition()

    if picker then
        if picker.components.sanity and not picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(TUNING.SANITY_SMALL)
        end

        if inst.rose and picker.components.combat
            and not (picker.components.inventory and picker.components.inventory:EquipHasTag("bramble_resistant")) and not picker:HasTag("shadowminion") then
            picker.components.combat:GetAttacked(inst, TUNING.ROSE_DAMAGE)
            picker:PushEvent("thorns")
        end
    end

    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos }) --this event is pushed in other places too
end

local function GetStatus(inst)
    return inst.rose and "ROSE" or "FLOWER"
end

local FINDLIGHT_MUST_TAGS = {"daylight", "lightsource"}
local function DieInDarkness(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, TUNING.DAYLIGHT_SEARCH_RANGE, FINDLIGHT_MUST_TAGS)
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
        inst:DoTaskInTime(5 + math.random() * 5, DieInDarkness)
    end
end

local function OnIsRoseDirty(inst)
    inst.scrapbook_proxy = inst._isrose:value() and "flower_rose" or nil
end

local function CanResidueBeSpawnedBy(inst, doer)
    local skilltreeupdater = doer and doer.components.skilltreeupdater or nil
    return skilltreeupdater and skilltreeupdater:IsActivated("winona_charlie_2") or false
end

local function OnResidueCreated(inst, owner, residue)
    if not inst._isrose:value() then
        ToggleRose(inst, true)
        SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function OnResidueActivated(inst, doer)
    if inst._isrose:value() and doer and doer.components.inventory then
        local rose = SpawnPrefab("charlierose")
        doer.components.inventory:GiveItem(rose, nil, inst:GetPosition())
        if doer.SoundEmitter then
            doer.SoundEmitter:PlaySound("meta4/charlie_residue/rose_activate")
        end
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local network = inst.entity:AddNetwork()

    anim:SetBank("um_buttercup")
    anim:SetBuild("um_buttercup")
    anim:SetRayTestOnBB(true)
    anim:PlayAnimation("idle")

    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.LESS] / 2)

    inst:AddTag("flower")
    inst:AddTag("cattoy")

    inst.OnIsRoseDirty = OnIsRoseDirty

    inst._isrose = net_bool(inst.GUID, "flower._isrose", "isrosedirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("isrosedirty", inst.OnIsRoseDirty)
        return inst
    end

    local inspectable = inst:AddComponent("inspectable")
    inspectable.nameoverride = "FLOWER"
    inspectable.getstatus = GetStatus

    local sanityaura = inst:AddComponent("sanityaura")
    sanityaura.aura = TUNING.DAPPERNESS_TINY

    local pickable = inst:AddComponent("pickable")
    pickable.picksound = "dontstarve/wilson/pickup_plants"
    pickable:SetUp("petals", 10)
    pickable.onpickedfn = onpickedfn
    pickable.remove_when_picked = true
    pickable.quickpick = true
    pickable.wildfirestarter = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    local halloweenmoonmutable = inst:AddComponent("halloweenmoonmutable")
    halloweenmoonmutable:SetPrefabMutated("moonbutterfly_sapling")

    local roseinspectable = inst:AddComponent("roseinspectable")
    roseinspectable:SetCanResidueBeSpawnedBy(CanResidueBeSpawnedBy)
    roseinspectable:SetOnResidueCreated(OnResidueCreated)
    roseinspectable:SetOnResidueActivated(OnResidueActivated)
    roseinspectable:SetForcedInduceCooldownOnActivate(true)

    if TheWorld:HasTag("cave") then
        inst:WatchWorldState("iscaveday", OnIsCaveDay)
    end

    MakeHauntableChangePrefab(inst, "flower_evil")

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("um_buttercup", fn, assets, prefabs)