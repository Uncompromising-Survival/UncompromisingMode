local WixiePiano = require("screens/WixiePiano")

local assets = {
    Asset("ANIM", "anim/wixie_piano.zip")
}

local function OnPianoedDirty(inst)
    if inst.Pianoed:value() == ThePlayer then
        TheFrontEnd:PushScreen(WixiePiano())
    end
end

local function OnActivate(inst, doer)
    inst.valid_cursee_id = doer.userid
    inst.Pianoed:set_local(doer)
    inst.Pianoed:set(doer)
    inst.components.activatable.inactive = true
end

local function SetupPianoedDirty(inst)
    inst:ListenForEvent("SetPianoeDirty", OnPianoedDirty)
end

local function piano1(inst)
    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/dissappear")
    local card = SpawnPrefab("wixie_piano_card")
    card.Transform:SetPosition(inst.Transform:GetWorldPosition())
    card.name = "Dulce Vetus Melodias"
    Launch2(card, inst, 2, 0, 1, 0.5)
end

local function piano2(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_pulled")
    local charles = TheSim:FindFirstEntityWithTag("puzzle_charles")
    charles.final_code_ready = true
    TheNet:SystemMessage("Music is in the air...")
    SpawnPrefab("statue_transition").Transform:SetPosition(inst:GetPosition():Get())
    SpawnPrefab("statue_transition_2").Transform:SetPosition(inst:GetPosition():Get())
end

local function piano3(inst)
    inst.SoundEmitter:PlaySound("dontstarve/maxwell/breakchains")
    local card = SpawnPrefab("wixie_piano_card")
    card.Transform:SetPosition(inst.Transform:GetWorldPosition())
    card.name = "Umbra magi"
    Launch2(card, inst, 2, 0, 1, 0.5)
end

local function fn(v12)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("wixie_piano")
    inst.AnimState:SetBank("wixie_piano")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Pianoed = net_entity(inst.GUID, "Pianoed.wixie_piano", "SetPianoeDirty")

    inst:DoTaskInTime(0, SetupPianoedDirty)

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("wixie_piano")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true
    inst.components.activatable.standingaction = true

    inst:AddComponent("inspectable")

    inst:ListenForEvent("pianopuzzlecomplete_1", piano1)
    inst:ListenForEvent("pianopuzzlecomplete_2", piano2)
    inst:ListenForEvent("pianopuzzlecomplete_3", piano3)

    return inst
end

local function getdesc(inst, viewer)
    return inst.name
end

local function pianocardfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.75)

    inst.AnimState:SetBank("mapscroll")
    inst.AnimState:SetBuild("mapscroll")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("irreplacable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getspecialdescription = getdesc

    inst:AddComponent("named")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    inst.persists = false

    return inst
end

return Prefab("wixie_piano", fn, assets), Prefab("wixie_piano_card", pianocardfn)