local assets =
{
    Asset("ANIM", "anim/amulets.zip"),
    Asset("ANIM", "anim/torso_amulets.zip"),
}

local function DoubleSlap(owner, data)
    local target, weapon = data and data.target, data and data.weapon
    local buffaction = owner:GetBufferedAction()
    if buffaction and buffaction.mockattack and owner.sg:HasStateTag("busy") then owner.sg:RemoveStateTag("busy") end
    if (not buffaction or not buffaction.mockattack) and not owner.components.rider:IsRiding()
        and (not weapon or weapon.components.weapon and not (weapon.components.projectile or weapon:HasTag("rangedweapon"))) then
        owner:DoTaskInTime(0, function() -- Target can change during this task.
            local act = BufferedAction(owner, target, ACTIONS.ATTACK)
            if act and target and target:IsValid() and not (target.components.health and target.components.health:IsDead()) then
                act.mockattack = true
                if owner.sg:HasStateTag("attack") then owner.sg:RemoveStateTag("attack") end
                owner.components.combat:ResetCooldown()
                owner:PushBufferedAction(act)
                if not owner.sg:HasStateTag("busy") then owner.sg:AddStateTag("busy") end
            end
        end)
    end
end

local function AddRemoveDebuff(owner)
    local combat = owner.components.combat
    if not combat then return end
    local buffaction = owner:GetBufferedAction()
    if buffaction and buffaction.mockattack then
        combat.externaldamagemultipliers:SetModifier(owner, TUNING.DSTU.KLAUS_AMULET_SECOND_HIT_DAMAGE_MULT, "um_mockattack")
    elseif combat.externaldamagemultipliers:CalculateModifierFromSource(owner, "um_mockattack") < 1 then
        combat.externaldamagemultipliers:RemoveModifier(owner, "um_mockattack")
    end
end

local function onequip_blue(inst, owner)
	inst:DoTaskInTime(0, function(inst)
		if UMCommonFns.VetcurseUnequip(inst, owner, EQUIPSLOTS.NECK or EQUIPSLOTS.BODY) then return end
	end)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets_klaus", "redamulet")
    owner:ListenForEvent("onattackother", DoubleSlap)
    owner:ListenForEvent("newstate", AddRemoveDebuff)
end

local function onunequip_blue(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner:RemoveEventCallback("onattackother", DoubleSlap)
    owner:RemoveEventCallback("newstate", AddRemoveDebuff)
    local combat = owner.components.combat
    if combat and combat.externaldamagemultipliers:CalculateModifierFromSource(owner, "um_mockattack") < 1 then
        combat.externaldamagemultipliers:RemoveModifier(owner, "um_mockattack")
    end
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local network = inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    anim:SetBank("amulet_klaus")
    anim:SetBuild("amulet_klaus")
    anim:PlayAnimation("klausamulet")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    MakeInventoryFloatable(inst, "med", nil, .6)

    inst:AddTag("vetcurse_item")
    inst:AddTag("donotautopick")
    inst:AddTag("hide_percentage")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    local equippable = inst:AddComponent("equippable")
    equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
    equippable:SetOnEquip(onequip_blue)
    equippable:SetOnUnequip(onunequip_blue)

    local armor = inst:AddComponent("armor")
    armor:InitIndestructible(TUNING.DSTU.KLAUS_AMULET_ABSORPTION)

    local shadowlevel = inst:AddComponent("shadowlevel")
    shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

    return inst
end

return Prefab("klaus_amulet", fn, assets)