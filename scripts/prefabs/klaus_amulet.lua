local assets =
{
    Asset("ANIM", "anim/amulets.zip"),
    Asset("ANIM", "anim/torso_amulets.zip"),
}

local function DoubleSlap(owner, data)
    local target, weapon = data and data.target, data and data.weapon
    local buffaction = owner:GetBufferedAction()
    if buffaction and buffaction.mockattack and owner.sg:HasStateTag("busy") then owner.sg:RemoveStateTag("busy") end
    if (not buffaction or buffaction and not buffaction.mockattack) and not owner.components.rider:IsRiding()
        and weapon and weapon.components.weapon and not (weapon.components.projectile or weapon:HasTag("rangedweapon")) then
        owner:DoTaskInTime(0, function() -- Target can change during this task.
            local act = BufferedAction(owner, target, ACTIONS.ATTACK)
            if target and target:IsValid() and not (target.components.health and target.components.health:IsDead()) and act then
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
    if not owner.components.combat then return end
    if owner.sg.mem.mockattack then
        owner.components.combat.externaldamagemultipliers:SetModifier(owner, .5, "um_mockattack")
    elseif owner.components.combat.externaldamagemultipliers:CalculateModifierFromSource(owner, "um_mockattack") < 1 then
        owner.components.combat.externaldamagemultipliers:RemoveModifier(owner, "um_mockattack")
    end
end

local function onequip_blue(inst, owner)
    if not owner:HasTag("vetcurse") and owner:HasTag("player") then
        inst:DoTaskInTime(0, function(inst, owner)
            local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
            local tool = owner and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.NECK or EQUIPSLOTS.BODY)
            if tool and owner then
                owner.components.inventory:Unequip(EQUIPSLOTS.NECK or EQUIPSLOTS.BODY)
                owner.components.inventory:DropItem(tool)
                owner.components.inventory:GiveItem(inst)
                if owner.components.talker then
                    owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
                end
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")
                if owner.sg then owner.sg:GoToState("hit") end
            end
        end)
    else
        owner.AnimState:OverrideSymbol("swap_body", "torso_amulets_klaus", "redamulet")
        owner:ListenForEvent("onattackother", DoubleSlap)
        owner:ListenForEvent("newstate", AddRemoveDebuff)
    end
end

local function onunequip_blue(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner:RemoveEventCallback("onattackother", DoubleSlap)
    owner:RemoveEventCallback("newstate", AddRemoveDebuff)
    if owner.components.combat and owner.components.combat.externaldamagemultipliers:CalculateModifierFromSource(owner, "um_mockattack") < 1 then
        owner.components.combat.externaldamagemultipliers:RemoveModifier(owner, "um_mockattack")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("amulet_klaus")
    inst.AnimState:SetBuild("amulet_klaus")
    inst.AnimState:PlayAnimation("klausamulet")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    MakeInventoryFloatable(inst, "med", nil, .6)

    inst:AddTag("vetcurse_item")
    inst:AddTag("donotautopick")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY

    inst:AddComponent("inventoryitem")

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

    inst.components.equippable:SetOnEquip(onequip_blue)
    inst.components.equippable:SetOnUnequip(onunequip_blue)

    return inst
end

return Prefab("klaus_amulet", fn, assets)