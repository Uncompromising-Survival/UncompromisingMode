local assets =
{
    Asset("ANIM", "anim/um_antlionstaff.zip"),
    Asset("ANIM", "anim/swap_antlionstaff.zip"),
}

local prefabs =
{
    "stafflight",
    "reticule",
    "sandspike",
}

local SANDSPIKE_MIN = 17
local SANDSPIKE_MAX = 20
local SANDSPIKE_SPREAD_RADIUS = 5
local SANDSPIKE_RADIUS_BONUS = 1
local SANDSPIKE_ANIM_SPEED_MULT = 1.25

local function ConsumeAmmo(inst)
    local ammo_stack = inst.components.container:GetItemInSlot(1)
    local item = inst.components.container:RemoveItem(ammo_stack, false)
    if item ~= nil then
        item:Remove()
    end
end

local function SpawnSandspikes(inst, pos)
    local ground = TheWorld.Map
    for i = 1, math.random(SANDSPIKE_MIN, SANDSPIKE_MAX) do
        inst:DoTaskInTime(math.random() * .5, function()
            if not inst:IsValid() then
                return
            end
            local theta = math.random() * TWOPI
            local radius = math.random() * SANDSPIKE_SPREAD_RADIUS
            local x = pos.x + math.cos(theta) * radius
            local z = pos.z + math.sin(theta) * radius
            local spot = Vector3(x, 0, z)
            if ground:IsPassableAtPoint(x, 0, z) and not ground:IsGroundTargetBlocked(spot) then
                local spike = SpawnPrefab("sandspike")
                spike.Transform:SetPosition(x, 0, z)
                spike.spikeradius = spike.spikeradius + SANDSPIKE_RADIUS_BONUS
                spike.AnimState:SetDeltaTimeMultiplier(SANDSPIKE_ANIM_SPEED_MULT)
            end
        end)
    end
end

local function OnCharged(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre")
end

local function CastSpell(staff, target, pos)
    if staff.components.rechargeable:IsCharged() and not staff.components.container:IsEmpty() then
        local caster = staff.components.inventoryitem.owner
        local targetpos = pos or (target ~= nil and target:GetPosition())

        staff.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", { size = 1 })
        ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, caster, 20)

        ConsumeAmmo(staff)
        SpawnSandspikes(staff, targetpos)

        UMCommonFns.StartRechargeableCooldown(staff, {cooldown = TUNING.DSTU.ANTLIONSTAFF_COOLDOWN, tags = {"um_antlionstaff"}})
    end
end

local function light_reticuletargetfn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local container_params =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 2, 0),
        },
        animbank = "ui_antlionhat_1x1",
        animbuild = "ui_antlionhat_1x1",
        pos = Vector3(0, 40, 0),
        side_align_tip = 160,
    },
    usespecificslotsforitems = true,
    type = "hand_inv",
    excludefromcrafting = true,
}

function container_params.itemtestfn(inst, item, slot)
    return item.prefab == "townportaltalisman"
end

local function onequip(inst, owner)
    if UMCommonFns.VetcurseUnequip(inst, owner, EQUIPSLOTS.HANDS) then return end
    owner.AnimState:OverrideSymbol("swap_object", "swap_antlionstaff", "symbol0")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function staff_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_antlionstaff")
    inst.AnimState:SetBuild("um_antlionstaff")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("nopunch")
    inst:AddTag("donotautopick")

    inst:AddTag("um_antlionstaff")
    inst:AddTag("quickcast")
    inst:AddTag("vetcurse_item")
    inst:AddTag("rechargeable")
    inst:AddTag("inventoryitem")
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.mouseenabled = true
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup(nil, container_params)
        end

        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.DSTU.ANTLIONSTAFF_SHADOW_LEVEL)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(CastSpell)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = false
    inst.components.spellcaster.quickcast = true

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup(nil, container_params)
    inst.components.container:Close()

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_antlionstaff", staff_fn, assets, prefabs)
