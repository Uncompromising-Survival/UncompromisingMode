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
local SANDSPIKE_DAMAGE_MULT = .35

local SANDCASTLE_COUNT = 7
local SANDCASTLE_ARC_RADIUS = 6.5
local SANDCASTLE_ARC_SWEEP = PI * .65
local SANDCASTLE_RADIUS = 1

local KILLRISK_TAGS = { "epic" }
local NOSPAWN_CHECK_RADIUS = 2.5
local SHIELD_CANDIDATE_TAGS = { "player" }
local SHIELD_SEARCH_RADIUS = 3

local SAFE_MASK = COLLISION.WORLD
local SAFE_GROUP = COLLISION.SANITY

local BLOCK_OVERLAP_CHECK_RADIUS = 10
local OVERLAP_TRIGGER_BUFFER = .3

local function ShouldSkipSpawn(entity)
    return entity.components.health ~= nil
        and entity.components.combat ~= nil
        and entity.components.locomotor == nil
end

local function ShouldShield(entity, caster)
    return entity.components.health ~= nil
        and entity.components.combat ~= nil
        and entity ~= caster
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

local function WouldLoseCollision(x, z, radius)
    local nearby = TheSim:FindEntities(x, 0, z, BLOCK_OVERLAP_CHECK_RADIUS)
    for _, entity in ipairs(nearby) do
        if entity.Physics ~= nil and entity.components.locomotor ~= nil and not entity:HasTag("groundspike") then
            local ex, _, ez = entity.Transform:GetWorldPosition()
            local dx, dz = ex - x, ez - z
            local mindist = radius + entity:GetPhysicsRadius(0) + OVERLAP_TRIGGER_BUFFER
            if dx * dx + dz * dz < mindist * mindist then
                return true
            end
        end
    end
    return false
end

local function MakeObstacleSafe(obstacle, caster)
    if obstacle.animname ~= "block" then
        local function KeepSafe()
            obstacle.Physics:SetCollisionMask(SAFE_MASK)
            obstacle.Physics:SetCollisionGroup(SAFE_GROUP)
        end
        KeepSafe()
        obstacle:ListenForEvent("animover", KeepSafe)
    end

    local x, _, z = obstacle.Transform:GetWorldPosition()
    local nearby = TheSim:FindEntities(x, 0, z, SHIELD_SEARCH_RADIUS, nil, nil, SHIELD_CANDIDATE_TAGS)
    local shielded = {}
    for _, entity in ipairs(nearby) do
        if ShouldShield(entity, caster) then
            ShieldEntity(entity)
            shielded[entity] = true
        end
    end

    if next(shielded) == nil then
        return
    end

    local unshieldonce
    unshieldonce = function()
        for entity in pairs(shielded) do
            UnshieldEntity(entity)
        end
        shielded = {}
    end

    local function ondamageimminent()
        obstacle:RemoveEventCallback("animover", ondamageimminent)
        obstacle:DoTaskInTime(3 * FRAMES, unshieldonce)
    end
    obstacle:ListenForEvent("animover", ondamageimminent)
    obstacle:ListenForEvent("onremove", unshieldonce)
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

    local nearby = TheSim:FindEntities(x, 0, z, NOSPAWN_CHECK_RADIUS, nil, nil, KILLRISK_TAGS)
    for _, entity in ipairs(nearby) do
        if ShouldSkipSpawn(entity) then
            return
        end
    end

    if prefabname == "sandblock" and WouldLoseCollision(x, z, SANDCASTLE_RADIUS) then
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
                spike.components.combat:SetDefaultDamage(spike.components.combat.defaultdamage * SANDSPIKE_DAMAGE_MULT)
            end)
        end)
    end
end

local function SpawnSandcastles(inst, caster, pos)
    local cx, _, cz = caster.Transform:GetWorldPosition()
    local dx, dz = pos.x - cx, pos.z - cz

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
            TrySpawnObstacle("sandblock", x, z, caster, function(block)
                block.spikeradius = SANDCASTLE_RADIUS
            end)
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
local SPELLWHEEL_RADIUS = 120
local SPELLWHEEL_FOCUS_RADIUS = 123

GetSpellwheelItems = function(inst)
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

    local cd = TUNING.DSTU.ANTLIONSTAFF_SPIKE_COOLDOWN
    if staff.defensivemode then
        cd = TUNING.DSTU.ANTLIONSTAFF_BLOCK_COOLDOWN
        SpawnSandcastles(staff, caster, targetpos)
    else
        SpawnSandspikes(staff, caster, targetpos)
    end

    UMCommonFns.StartRechargeableCooldown(staff, {cooldown = cd, tags = {"um_antlionstaff"}})
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

local function CanCastFn(inst)
    return true
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

    inst:AddTag("um_antlionstaff")
    inst:AddTag("um_killreticuleonequipchange")
    inst:AddTag("quickcast")
    inst:AddTag("vetcurse_item")
    inst:AddTag("rechargeable")
    inst:AddTag("weapon")
    inst:AddTag("shadowlevel")
    inst:AddTag("donotautopick")

    local reticule = inst:AddComponent("reticule")
    reticule.targetfn = light_reticuletargetfn
    reticule.mouseenabled = true
    reticule.ease = true
    reticule.ispassableatallpoints = true

    local spellbook = inst:AddComponent("spellbook")
    spellbook:SetItems(GetSpellwheelItems(inst))
    spellbook:SetRequiredTag("um_antlionstaff_spellbook_user")
    spellbook:SetRadius(SPELLWHEEL_RADIUS)
    spellbook:SetFocusRadius(SPELLWHEEL_FOCUS_RADIUS)

    inst.um_cancastontarget = UMCommonFns.DefaultCanCastOnTarget

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("um_antlionstaff")
        end

        return inst
    end

    inst.defensivemode = false

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    local equippable = inst:AddComponent("equippable")
    equippable:SetOnEquip(onequip)
    equippable:SetOnUnequip(onunequip)

    local shadowlevel = inst:AddComponent("shadowlevel")
    shadowlevel:SetDefaultLevel(TUNING.DSTU.ANTLIONSTAFF_SHADOW_LEVEL)

    local weapon = inst:AddComponent("weapon")
    weapon:SetDamage(TUNING.DSTU.ANTLIONSTAFF_DAMAGE)

    local spellcaster = inst:AddComponent("spellcaster")
    spellcaster:SetSpellFn(CastSpell)
    spellcaster:SetCanCastFn(CanCastFn)
    spellcaster.canuseontargets = true
    spellcaster.canuseondead = true
    spellcaster.canuseonpoint = true
    spellcaster.canuseonpoint_water = false
    spellcaster.quickcast = true

    local rechargeable = inst:AddComponent("rechargeable")
    rechargeable:SetOnChargedFn(OnCharged)

    inst.um_setspellmode = SetSpellMode

    local container = inst:AddComponent("container")
    container:WidgetSetup("um_antlionstaff")
    container.canbeopened = false

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_antlionstaff", staff_fn, assets, prefabs)