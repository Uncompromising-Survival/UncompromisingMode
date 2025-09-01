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
    end
end

local function onunequip_blue(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner:RemoveEventCallback("onattackother", DoubleSlap)
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