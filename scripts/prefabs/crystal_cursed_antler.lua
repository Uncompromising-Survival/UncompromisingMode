local assets =
{
    Asset("ANIM", "anim/crystal_cursed_antler.zip"),
    Asset("ANIM", "anim/swap_crystal_cursed_antler.zip"),
}

local function charged(inst)
    local fx = SpawnPrefab("dr_warm_loop_1")

    local owner = inst.components.inventoryitem.owner

    if inst.components.equippable:IsEquipped() and owner ~= nil then
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -275, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    else
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, 2.35, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    end
end

local function OnCharged(inst)
    local fx = SpawnPrefab("dr_warm_loop_1")

    local owner = inst.components.inventoryitem.owner

    if inst.components.equippable:IsEquipped() and owner ~= nil then
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -275, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    else
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, 2.35, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    end
    inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/charge")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/taunt_howl", nil, .4)
end

local function onequip(inst, owner)
    if UMCommonFns.VetcurseUnequip(inst, owner, EQUIPSLOTS.HANDS) then return end
    owner.AnimState:OverrideSymbol("swap_object", "swap_crystal_cursed_antler", "swap_crystal_cursed_antler")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onattack(inst, attacker, target)
    if target and target:IsValid() and attacker and attacker:IsValid() and inst.components.rechargeable:IsCharged() then
        local x1, y1, z1 = inst.Transform:GetWorldPosition()


        local owner = inst.components.inventoryitem:GetGrandOwner()

        for i, v in pairs(TheSim:FindEntities(x1, y1, z1, 8, {"cursedantler"})) do
            if v ~= inst then
                local vowner = v.components.inventoryitem:GetGrandOwner()
                if vowner and (vowner == owner or not vowner:HasTag("player")) or vowner == nil then
                    v.components.rechargeable:Discharge(5)
                end
            end
        end

        inst.components.rechargeable:Discharge(5)

        if inst.components.planardamage then
            inst.components.planardamage:SetBaseDamage(17)
        end

        local x, y, z = target.Transform:GetWorldPosition()
        local ice_circle = SpawnPrefab("antler_ice_circle")
        ice_circle.Transform:SetPosition(x, y, z)
        ice_circle.caster = attacker

        for i = 1, 4 do
            local icefx = SpawnPrefab("icespike_fx_" .. i)
            icefx.Transform:SetPosition(x + math.random(-1.5, 1.5), 0, z + math.random(-1.5, 1.5))
        end

        if target.components.freezable and not target.components.freezable:IsFrozen() then
            target.components.freezable:AddColdness(1)
            target.components.freezable:SpawnShatterFX()
        end

        local ents = TheSim:FindEntities(x, y, z, 2.5, nil, {"INLIMBO", "player", "companion", "abigail", "shadowminion"})
        for i, v in ipairs(ents) do
            if v ~= inst and v ~= target and v:IsValid() and not v:IsInLimbo() then
                if v.components.combat and not (v.components.health and v.components.health:IsDead())
                    and attacker.components.combat:CanTarget(v) and not attacker.components.combat:IsAlly(v) then
                    v.components.combat:GetAttacked(attacker, 34, inst, nil, {planar = 17})

                    if v.components.freezable and not v.components.freezable:IsFrozen() then
                        v.components.freezable:AddColdness(.5)
                        v.components.freezable:SpawnShatterFX()
                    end
                end
            end
        end
    end
end

local function GetAntlerDamage(inst, attacker, target)
    if inst.components.planardamage and inst.components.rechargeable and inst.components.rechargeable:IsCharged() then
        inst.components.planardamage:SetBaseDamage(116)
    end
    return 34
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("crystal_cursed_antler")
    inst.AnimState:SetBuild("crystal_cursed_antler")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cursedantler")
    inst:AddTag("vetcurse_item")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst, "med", 0.2, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(GetAntlerDamage)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(17)


    inst:AddComponent("inventoryitem")

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    MakeHauntableLaunch(inst)

    return inst
end

local no_slow = { "INLIMBO", "notarget", "playerghost", "wall", "shadow", "shadowchesspiece", "trap", "companion", "abigail", "shadowminion", "player" }

local function OnUpdateIceCircle(inst)
    local debuffkey = inst.prefab
    local caster = inst.caster and inst.caster:IsValid() and inst.caster or nil
    local castercombat = caster ~= nil and caster.components.combat or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, { "_combat" }, no_slow)
    for i, v in ipairs(ents) do
        if v ~= caster and v.entity:IsVisible()
            and not (v.components.health and v.components.health:IsDead())
            and not (castercombat and castercombat:IsAlly(v)) then
            if v.components.locomotor and not v:HasTag("flying") and not v:HasTag("flight") then
                v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, 0.5)
                v.um_ice_circle = v:DoPeriodicTask(1, function(guy)
                    if not FindEntity(guy, 3, function(ent) return ent.prefab == "antler_ice_circle" end) then
                        guy.components.locomotor:RemoveExternalSpeedMultiplier(guy, debuffkey)
                        if guy.um_ice_circle then
                            guy.um_ice_circle:Cancel()
                            guy.um_ice_circle = nil
                        end
                    end
                end)
            end

            if v.components.freezable ~= nil and not v.components.freezable:IsFrozen()
                and v.components.freezable.coldness < v.components.freezable:ResolveResistance() * (inst.freezelimit or 1) then
                v.components.freezable:AddColdness(.1, 1, inst.freezelimit ~= nil)
            end
        end
    end
end

local function antler_ice_circle_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("deer_ice_circle")
    inst.AnimState:SetBuild("deer_ice_circle")
    inst.AnimState:PlayAnimation("impact")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(1.0, 1.0)
    inst.persists = false
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.freezelimit = 0.7

    inst.Transform:SetRotation(math.random() * 360)

    inst:DoTaskInTime(8, function(inst)
        inst.AnimState:PlayAnimation("pst")
        inst:ListenForEvent("animover", inst.Remove)
    end)

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(OnUpdateIceCircle)

    return inst
end

return Prefab("crystal_cursed_antler", fn, assets),
    Prefab("antler_ice_circle", antler_ice_circle_fn, assets)
