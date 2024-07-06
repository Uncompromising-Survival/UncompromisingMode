local assets =
{
    Asset("ANIM", "anim/lighter.zip"),
    Asset("ANIM", "anim/swap_lighter.zip"),
    --Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "lighterfire",
    "channel_absorb_fire_fx",
    "channel_absorb_fire",
    "channel_absorb_smoulder",
    "channel_absorb_embers",
}

-------------------------------------------------------------------------

local TARGET_ONEOF_TAGS = {}
local TARGET_NO_TAGS = { "INLIMBO", "player", "companion", "abigail", "wall", "dead", "bird", "notarget", "noattack", "invisible" }
local ABSORB_RANGE = 16

local function DoAttack(inst, owner)
    local x, y, z = owner.Transform:GetWorldPosition()
    local entities = TheSim:FindEntities(x, 0, z, ABSORB_RANGE, { "_combat", "_health" }, TARGET_NO_TAGS, nil)

    if #entities > 0 then
        for i = 1, 5 do
            local ent = entities[math.random(#entities)]
            if ent ~= nil and ent:IsValid() and not ent:IsInLimbo() and ent.components.combat ~= nil and ent.components.combat:CanBeAttacked(owner) then
                inst:DoTaskInTime(FRAMES * i * 5, function(inst)
                    if not ent.components.health:IsDead() then
                        local pt = inst:GetPosition()
                        local x, y, z = pt.x + math.random(-3, 3), pt.y, pt.z + math.random(-3, 3)

                        inst.fire_fx = SpawnPrefab("moonglow_flame")
                        inst.fire_fx.Transform:SetPosition(pt.x, pt.y, pt.z)
                        inst.fire_fx.entity:AddFollower()
                        inst.fire_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)
                        inst.fire_fx.AnimState:SetFinalOffset(1)

                        inst.SoundEmitter:PlaySound("rifts/lunarthrall_bomb/throw")

                        SpawnPrefab("moonglow_proj_scorch").Transform:SetPosition(x, y, z) --not saving these as variables for memory optimization
                        SpawnPrefab("crab_king_shine").Transform:SetPosition(x, y, z)

                        local projectile = SpawnPrefab("moonglow_proj")
                        projectile.components.projectile.speed = 10
                        projectile.components.projectile:Throw(inst, ent, owner)
                        projectile.components.projectile.homing = false
                        projectile:DoTaskInTime(0.5, function(projectile)
                            projectile.components.projectile.speed = 40
                            local x, y, z = projectile.Transform:GetWorldPosition()
                            projectile.components.projectile:Throw(inst, ent, owner) --need to update speed!!
                            projectile.Transform:SetPosition(x, y, z)                --fix pos after throw
                            projectile.components.projectile.homing = true
                        end)
                        projectile.Transform:SetPosition(x, y, z)
                        projectile.Transform:SetRotation(math.random(360))
                    end
                end)
            end
        end
    end
end

local function OnStartChanneling(inst, user)
    if inst.attack_task then
        inst.attack_task:Cancel()
    end
    inst.attack_task = inst:DoPeriodicTask(1.5, DoAttack, nil, user)

    user.SoundEmitter:PlaySound("meta3/willow_lighter/lighter_absorb_LP", "channel_loop")
end

local function OnStopChanneling(inst, user)
    user.SoundEmitter:KillSound("channel_loop")
    user.SoundEmitter:PlaySound("meta3/willow_lighter/extinguisher_deactivate")

    if inst.attack_task then
        inst.attack_task:Cancel()
        inst.attack_task = nil
    end
end

--------------------------------------------------------------------------

local function onequip(inst, owner)
    inst:AddComponent("channelcastable")
    inst.components.channelcastable:SetOnStartChannelingFn(OnStartChanneling)
    inst.components.channelcastable:SetOnStopChannelingFn(OnStopChanneling)


    inst.components.burnable:Ignite()

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_lighter", inst.GUID, "swap_lighter")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_lighter", "swap_lighter")
    end

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner.SoundEmitter:PlaySound("dontstarve/wilson/lighter_on")
end

local function onunequip(inst, owner)
    inst:DoTaskInTime(0, function(inst)
        inst:RemoveComponent("channelcastable")
    end)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    inst.components.burnable:Extinguish()
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")
end
local function onequiptomodel(inst, owner, from_ground)
    if inst.fires ~= nil then
        for i, fx in ipairs(inst.fires) do
            fx:Remove()
        end
        inst.fires = nil
    end

    inst.components.burnable:Extinguish()
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
    --target may be killed or removed in combat damage phase
end

local function onupdatefueledraining(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    inst.components.fueled.rate =
        owner ~= nil and
        (owner.components.sheltered ~= nil and owner.components.sheltered.sheltered or owner.components.rainimmunity ~= nil) and
        1 or 1 + TUNING.LIGHTER_RAIN_RATE * TheWorld.state.precipitationrate
end

local function onisraining(inst, israining)
    if inst.components.fueled ~= nil then
        if israining then
            inst.components.fueled:SetUpdateFn(onupdatefueledraining)
            onupdatefueledraining(inst)
        else
            inst.components.fueled:SetUpdateFn()
            inst.components.fueled.rate = 1
        end
    end
end

local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        --when we burn out
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                    announce = "ANNOUNCE_TORCH_OUT",
                }
                inst:Remove()
                owner:PushEvent("itemranout", data)
                return
            end
        end
        inst:Remove()
    end
end

local function OnRemoveEntity(inst)

end

local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
end

local tail_length = 5
local tail_speeds = {
    ["tail_5_2"] = .15,
    ["tail_5_3"] = .15,
    ["tail_5_4"] = .2,
    ["tail_5_5"] = .8,
    ["tail_5_6"] = 1,
    ["tail_5_7"] = 1
}
local thin_tail_speeds = { ["tail_5_8"] = 1, ["tail_5_9"] = .5 }

local function CreateTail(is_thin, color)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(color.r, color.g, color.b)
    inst.Light:SetIntensity(0.1)
    inst.Light:SetRadius(1)

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation(weighted_random_choice(thin_tail_speeds))
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetAddColour(color.r, color.g, color.b, 1)
    inst.AnimState:SetMultColour(color.r, color.g, color.b, 1)
    inst.AnimState:SetHue(color.h)

    inst:ListenForEvent("animover", inst.Remove)
    return inst
end

local function CreateThinTail(inst, color)
    local fade_value = not inst.entity:IsVisible() and 0 or inst._fade ~= nil and (tail_length - inst._fade:value() + 1) / tail_length or 1
    if fade_value > 0 then
        local tail_inst = CreateTail(inst.thin_tail_count > 0, color)
        tail_inst.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tail_inst.Transform:SetRotation(inst.Transform:GetRotation())

        if fade_value < 1 then
            tail_inst.AnimState:SetTime(fade_value * tail_inst.AnimState:GetCurrentAnimationLength())
        end
        if inst.thin_tail_count > 0 then
            inst.thin_tail_count = inst.thin_tail_count - 1
        end
    end
end

local function fn_proj()
    local inst = CreateEntity()
    local r, g, b, h = math.random(), math.random(), math.random(), math.random()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(r, g, b)
    inst.Light:SetIntensity(0.1)
    inst.Light:SetRadius(1)

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("attack_3", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("projectile")

    inst.color = { r = r, g = g, b = b, h = h }
    inst.AnimState:SetAddColour(r, g, b, 1)
    inst.AnimState:SetMultColour(r, g, b, 1)
    inst.AnimState:SetHue(h)

    if not TheNet:IsDedicated() then
        inst.thin_tail_count = math.random(8, 16)
        inst:DoPeriodicTask(0, CreateThinTail, nil, { r = r, g = g, b = b, h = h })
    end

    inst._fade = net_tinybyte(inst.GUID, "blowdart_lava2_projectile_explosive._fade")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(30)
    inst.components.projectile:SetRange(20)
    inst.components.projectile:SetOnHitFn(
        function(inst, owner, target)
            local impactfx = SpawnPrefab("hitsparks_piercing_fx")
            impactfx:Setup(owner, target, inst, nil, false, 0.75)

            inst:Remove()
        end
    )

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LIGHTER_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetLaunchOffset(Vector3(-2, 1, 0))

    return inst
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lighter")
    inst.AnimState:SetBuild("lighter")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("lighter.png")

    inst:AddTag("dangerouscooker")
    inst:AddTag("wildfireprotected")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("donotautopick")
    
    MakeInventoryFloatable(inst, "small", 0.05, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LIGHTER_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -----------------------------------
    inst:AddComponent("inventoryitem")
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    -----------------------------------


    ----

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil

    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.LIGHTER_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.fueltype = FUELTYPE.LIGHTER
    inst.components.fueled.accepting = false
    inst.components.fueled:SetTakeFuelFn(ontakefuel)


    inst:WatchWorldState("israining", onisraining)
    onisraining(inst, TheWorld.state.israining)

    MakeHauntableLaunch(inst)

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

local SCORCH_COLOR_FRAMES = 20
local SCORCH_DELAY_FRAMES = 40
local SCORCH_FADE_FRAMES = 15

local function Scorch_OnFadeDirty(inst)
    -- V2C: hack alert: using SetHightlightColour to achieve something like OverrideAddColour
    --     (that function does not exist), because we know this FX can never be highlighted!
    if inst._fade:value() > SCORCH_FADE_FRAMES + SCORCH_DELAY_FRAMES then
        local k = (inst._fade:value() - SCORCH_FADE_FRAMES - SCORCH_DELAY_FRAMES) / SCORCH_COLOR_FRAMES
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour(k, k, k, 0)
        inst.AnimState:SetLightOverride(k)
    elseif inst._fade:value() >= SCORCH_FADE_FRAMES then
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour()
    else
        local k = inst._fade:value() / SCORCH_FADE_FRAMES
        k = k * k
        inst.AnimState:OverrideMultColour(1, 1, 1, k)
        inst.AnimState:SetHighlightColour()
    end
end

local function Scorch_OnUpdateFade(inst)
    if inst._fade:value() > 1 then
        inst._fade:set_local(inst._fade:value() - 1)
        Scorch_OnFadeDirty(inst)
    elseif TheWorld.ismastersim then
        inst:Remove()
    elseif inst._fade:value() > 0 then
        inst._fade:set_local(0)
        inst.AnimState:OverrideMultColour(1, 1, 1, 0)
    end
end

local function fn_scorch()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("burntground")
    inst.AnimState:SetBank("burntground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst._fade = net_byte(inst.GUID, "deerclops_laserscorch._fade", "fadedirty")
    inst._fade:set(SCORCH_COLOR_FRAMES + SCORCH_DELAY_FRAMES + SCORCH_FADE_FRAMES)

    inst:DoPeriodicTask(0, Scorch_OnUpdateFade)
    Scorch_OnFadeDirty(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("fadedirty", Scorch_OnFadeDirty)

        return inst
    end

    inst.Transform:SetRotation(math.random() * 360)
    inst.persists = false

    return inst
end

local function fn_flame()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("lavaarena_player_teleport")
    inst.AnimState:SetBank("lavaarena_player_teleport")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(math.random(), math.random(), math.random(), 1)
    inst.AnimState:SetMultColour(math.random(), math.random(), math.random(), 1)
    inst.AnimState:SetHue(math.random())
    inst.AnimState:SetDeltaTimeMultiplier(2)
    inst.Transform:SetScale(0.25, 0.25, 0.25)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("moonglow", fn, assets, prefabs), Prefab("moonglow_proj", fn_proj, assets, prefabs), Prefab("moonglow_proj_scorch", fn_scorch), Prefab("moonglow_flame", fn_flame)
