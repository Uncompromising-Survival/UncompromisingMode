local assets =
{
    Asset("ANIM", "anim/um_antlionstaff.zip"),
    Asset("ANIM", "anim/swap_antlionstaff.zip"),
}

local prefabs =
{
    "reticule",
    "sandspike",
    "sandblock",
}

local SANDSPIKE_MIN = 17
local SANDSPIKE_MAX = 20
local SANDSPIKE_SPREAD_RADIUS = 5
local SANDSPIKE_RADIUS_BONUS = 1.15

local SANDCASTLE_COUNT = 7
local SANDCASTLE_ARC_RADIUS = 6.5
local SANDCASTLE_ARC_SWEEP = PI * .65

local SHIELD_CANDIDATE_TAGS = { "epic", "player" }

local function ShouldShield(entity, caster)
    if entity.components.health == nil or entity.components.combat == nil then
        return false
    end
    if entity:HasTag("player") then
        return entity ~= caster
    end
    return entity.components.locomotor == nil
end

local function ShieldEntity(entity)
    if (entity._um_antlionstaff_shieldcount or 0) <= 0 then
        entity._um_antlionstaff_shieldcount = 0
        entity._um_antlionstaff_wasinvincible = entity.components.health:IsInvincible()
        entity.components.health:SetInvincible(true)
    end
    entity._um_antlionstaff_shieldcount = entity._um_antlionstaff_shieldcount + 1
end

local function UnshieldEntity(entity)
    if not entity:IsValid() or entity._um_antlionstaff_shieldcount == nil then
        return
    end

    entity._um_antlionstaff_shieldcount = entity._um_antlionstaff_shieldcount - 1
    if entity._um_antlionstaff_shieldcount > 0 or entity.components.health == nil then
        return
    end
    entity.components.health:SetInvincible(entity._um_antlionstaff_wasinvincible)
end

local function MakeObstacleSafe(obstacle, caster)
    local x, _, z = obstacle.Transform:GetWorldPosition()
    local nearby = TheSim:FindEntities(x, 0, z, 3, nil, nil, SHIELD_CANDIDATE_TAGS)
    if #nearby == 0 then
        return
    end

    local shielded = {}
    for _, entity in ipairs(nearby) do
        if entity:HasTag("epic") then
            obstacle.Physics:SetCollisionGroup(COLLISION.SMALLOBSTACLES)
        end
        if ShouldShield(entity, caster) then
            ShieldEntity(entity)
            table.insert(shielded, entity)
        end
    end

    if #shielded == 0 then
        return
    end

    local task
    task = obstacle:DoPeriodicTask(FRAMES, function()
        if obstacle:IsValid() and not obstacle.Physics:IsActive() then
            return
        end
        task:Cancel()
        for _, entity in ipairs(shielded) do
            UnshieldEntity(entity)
        end
    end)
end

local function ConsumeAmmo(inst)
    local ammo_stack = inst.components.container:GetItemInSlot(1)
    local item = inst.components.container:RemoveItem(ammo_stack, false)
    if item ~= nil then
        item:Remove()
    end
end

local function TrySpawnObstacle(prefabname, x, z, caster, onspawned)
    local ground = TheWorld.Map
    local spot = Vector3(x, 0, z)
    if not (ground:IsPassableAtPoint(x, 0, z) and not ground:IsGroundTargetBlocked(spot)) then
        return
    end

    local obstacle = SpawnPrefab(prefabname)
    obstacle.Transform:SetPosition(x, 0, z)
    MakeObstacleSafe(obstacle, caster)
    if onspawned ~= nil then
        onspawned(obstacle)
    end
end

local function SpawnSandspikes(inst, caster, pos)
    for i = 1, math.random(SANDSPIKE_MIN, SANDSPIKE_MAX) do
        inst:DoTaskInTime(math.random() * .5, function()
            if not inst:IsValid() then
                return
            end
            local theta = math.random() * TWOPI
            local radius = math.random() * SANDSPIKE_SPREAD_RADIUS
            local x = pos.x + math.cos(theta) * radius
            local z = pos.z + math.sin(theta) * radius
            TrySpawnObstacle("sandspike", x, z, caster, function(spike)
                spike.spikeradius = spike.spikeradius + SANDSPIKE_RADIUS_BONUS
            end)
        end)
    end
end

local function SpawnSandcastles(inst, caster, pos)
    local cx, _, cz = caster.Transform:GetWorldPosition()
    local dx, dz = pos.x - cx, pos.z - cz
    local dist = math.sqrt(dx * dx + dz * dz)
    if dist < 1 then
        return
    end

    local facing_angle = math.atan2(dz, dx)
    local start_angle = facing_angle - SANDCASTLE_ARC_SWEEP / 2
    local center_x = pos.x - math.cos(facing_angle) * SANDCASTLE_ARC_RADIUS
    local center_z = pos.z - math.sin(facing_angle) * SANDCASTLE_ARC_RADIUS

    for i = 1, SANDCASTLE_COUNT do
        local t = (i - 1) / (SANDCASTLE_COUNT - 1)
        local angle = start_angle + t * SANDCASTLE_ARC_SWEEP
        local x = center_x + math.cos(angle) * SANDCASTLE_ARC_RADIUS
        local z = center_z + math.sin(angle) * SANDCASTLE_ARC_RADIUS

        inst:DoTaskInTime(t * .5, function()
            if not inst:IsValid() then
                return
            end
            TrySpawnObstacle("sandblock", x, z, caster)
        end)
    end
end

local function OnCharged(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/cast_pre")
end

local function SetSpellMode(inst, defensive)
    if inst.defensivemode == defensive then
        return
    end

    inst.defensivemode = defensive
    if defensive then
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/block")
    else
        for i = 1, 4 do
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/break")
        end
    end
end

local function SelectMode(inst, defensive)
    if inst:IsValid() then
        SendModRPCToServer(GetModRPC("UncompromisingSurvival", "SetAntStaffMode"), inst, defensive)
    end
end

local GetSpellwheelItems

local function OnSelectMode(inst, defensive)
    inst.defensivemode = defensive
    inst.components.spellbook:SetItems(GetSpellwheelItems(inst))
    SelectMode(inst, defensive)
end

local SPELLWHEEL_ICON_SCALE = .6
local SPELLWHEEL_ICON_RADIUS = 50

function GetSpellwheelItems(inst)
    local items =
    {
        {
            atlas = "images/antstaff_icon1.xml",
            normal = "antstaff_icon1.tex",
            widget_scale = SPELLWHEEL_ICON_SCALE,
            hit_radius = SPELLWHEEL_ICON_RADIUS,
            label = "Spike Ambush",
            execute = function(inst) OnSelectMode(inst, false) end,
        },
        {
            atlas = "images/antstaff_icon2.xml",
            normal = "antstaff_icon2.tex",
            widget_scale = SPELLWHEEL_ICON_SCALE,
            hit_radius = SPELLWHEEL_ICON_RADIUS,
            label = "Castle Bastion",
            execute = function(inst) OnSelectMode(inst, true) end,
        },
    }

    if inst.defensivemode then
        items[2].atlas = "images/antstaff_icon2b.xml"
        items[2].normal = "antstaff_icon2b.tex"
    else
        items[1].atlas = "images/antstaff_icon1b.xml"
        items[1].normal = "antstaff_icon1b.tex"
    end

    return items
end

local function CastSpell(staff, target, pos)
    if not staff.components.rechargeable:IsCharged() or staff.components.container:IsEmpty() then
        return
    end

    local caster = staff.components.inventoryitem.owner
    local targetpos = pos or (target ~= nil and target:GetPosition())

    staff.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", { size = 1 })
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .02, .2, caster, 20)

    ConsumeAmmo(staff)

    if staff.defensivemode then
        SpawnSandcastles(staff, caster, targetpos)
    else
        SpawnSandspikes(staff, caster, targetpos)
    end

    UMCommonFns.StartRechargeableCooldown(staff, {cooldown = TUNING.DSTU.ANTLIONSTAFF_COOLDOWN, tags = {"um_antlionstaff"}})
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
        slotbg =
        {
            { image = "townportaltalisman_slot.tex", atlas = "images/townportaltalisman_slot.xml" },
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
    inst.components.container:Open(owner)
    owner:AddTag("um_antlionstaff_spellbook_user")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.components.container:Close()
    owner:RemoveTag("um_antlionstaff_spellbook_user")
end

local function onsave(inst, data)
    data.defensivemode = inst.defensivemode
end

local function onload(inst, data)
    if data ~= nil and data.defensivemode ~= nil then
        inst.defensivemode = data.defensivemode
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
    inst:AddTag("weapon")
    inst:AddTag("inventoryitem")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.mouseenabled = true
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    inst:AddComponent("spellbook")
    inst.components.spellbook:SetItems(GetSpellwheelItems(inst))
    inst.components.spellbook:SetRequiredTag("um_antlionstaff_spellbook_user")

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup(nil, container_params)
        end

        if ThePlayer ~= nil then
            inst:ListenForEvent("unequip", function(player, data)
                if data.item == inst and ThePlayer.components.playercontroller ~= nil then
                    ThePlayer.components.playercontroller:RefreshReticule()
                end
            end, ThePlayer)
        end

        return inst
    end

    inst.defensivemode = false

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.DSTU.ANTLIONSTAFF_SHADOW_LEVEL)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.DSTU.ANTLIONSTAFF_DAMAGE)

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

    inst.um_setspellmode = SetSpellMode

    inst:AddComponent("container")
    inst.components.container:WidgetSetup(nil, container_params)
    inst.components.container:Close()

    MakeHauntableLaunch(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("um_antlionstaff", staff_fn, assets, prefabs)