local assets =
{
    Asset("ANIM", "anim/slingshot.zip"),
}

local prefabs =
{
    "slingshotammo_rock_proj",
}

local easing = require("easing")

local PROJECTILE_DELAY = 2 * FRAMES

local function onremove(inst)
    if inst._wheel ~= nil then
        inst._wheel:Remove()
        inst._wheel = nil
    end
end

local function OnProjectileLaunched(inst, attacker, target)
    if inst.components.container ~= nil then
        local ammo_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(ammo_stack, false)
        if item ~= nil then
            if item == ammo_stack then
                item:PushEvent("ammounloaded", {slingshot = inst})
            end
            item:Remove()
        end
    end
end

local function OnAmmoLoaded(inst, data)
    if inst.components.weapon ~= nil then
        if data ~= nil and data.item ~= nil then
            inst.components.weapon:SetProjectile(data.item.prefab.."_proj")
            data.item:PushEvent("ammoloaded", {slingshot = inst})
        end
    end
end

local function OnAmmoUnloaded(inst, data)
    if inst.components.weapon ~= nil then
        inst.components.weapon:SetProjectile(nil)
        if data ~= nil and data.prev_item ~= nil then
            data.prev_item:PushEvent("ammounloaded", {slingshot = inst})
        end
    end
end

local floater_swap_data = {sym_build = "swap_slingshot"}

local function ReticuleTargetFn(inst)
    return Vector3(inst.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then 
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        local dist = inst:GetDistanceSqToPoint(mousepos.x, 0, mousepos.z)
        inst.components.reticule.fadealpha = dist / 100
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function LaunchSpit(inst, caster, target, shadow)
    if caster ~= nil then
        local x, y, z = caster.Transform:GetWorldPosition()
        local ammo = shadow ~= nil and "slingshotammo_shadow_proj_secondary" or inst.components.weapon.projectile.."_secondary"
        if ammo ~= nil then
            local targetpos = target:GetPosition()
            targetpos.y = 0.5
            local projectile = SpawnPrefab(ammo)
            local complexprojectile = projectile.components.complexprojectile
            projectile.Transform:SetPosition(x, y, z)
            projectile.powerlevel = inst.powerlevel
            if complexprojectile ~= nil then
                local theta = caster.Transform:GetRotation()
                theta = theta*DEGREES
                local dx = targetpos.x - x
                local dz = targetpos.z - z
                --local rangesq = (dx * dx + dz * dz) / 1.2
                local rangesq = dx * dx + dz * dz
                local maxrange = TUNING.FIRE_DETECTOR_RANGE * 2
                --local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
                local speed = easing.linear(rangesq, maxrange, 1, maxrange * maxrange)
                projectile.caster = caster
                complexprojectile.usehigharc = true
                complexprojectile:SetHorizontalSpeed(speed)
                complexprojectile:SetGravity(-45)
                complexprojectile:Launch(targetpos, caster, caster)
                complexprojectile:SetLaunchOffset(Vector3(1.5, 1.5, 0))
            else
                local projectile_comp = projectile.components.projectile
                if ammo == "slingshotammo_moonglass_proj_secondary" then
                    projectile_comp:SetSpeed(10 + 10 * projectile.powerlevel)
                else
                    projectile_comp:SetSpeed(10 + 10 * projectile.powerlevel)
                end
                projectile_comp:Throw(caster, target, caster)
            end
            projectile.planar_ammo = true
            local fx = SpawnPrefab("slingshot_planar_fx_lunar")
            fx.entity:SetParent(projectile.entity)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(projectile.GUID, "rock", 0, 0, 0)
        end
    end
end

local function getspawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0.5, z1 + .15 * (z2 - z1)
end

local function UnloadAmmo(inst)
    if inst.components.container ~= nil then
        local ammo_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(ammo_stack, false)
        if item ~= nil then
            if item == ammo_stack then
                item:PushEvent("ammounloaded", {slingshot = inst})
            end
            item:Remove()
        end
    end
end

local function OnStartChanneling(inst, user)
    user.SoundEmitter:PlaySound("UCSounds/um_windturbine/slow_spin", "twirl")
    user.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_verylow")
    inst.powerlevel = 1
    inst.sling_charge_task = inst:DoPeriodicTask(.3, function()
        if inst.powerlevel < 2 then
            inst.powerlevel = inst.powerlevel + .25
            if inst.powerlevel == 2 then
                user.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_high")
                user.SoundEmitter:PlaySound("UCSounds/um_windturbine/fast_spin", "twirl")
            elseif inst.powerlevel >= 1.5 then
                user.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_med")
                user.SoundEmitter:PlaySound("UCSounds/um_windturbine/med_spin", "twirl")
            else
                user.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_low")
            end
        end
    end)
    if inst._wheel ~= nil then
        inst._wheel:SetSpinning(true)
    end
end

local function OnStopChanneling(inst, user)
    if inst.sling_charge_task ~= nil then
        inst.sling_charge_task:Cancel()
        inst.sling_charge_task = nil
    end
    inst.powerlevel = 1
    if inst._wheel ~= nil then
        inst._wheel:SetSpinning(false)
    end
    user.SoundEmitter:KillSound("twirl")
end

local function createlight(inst, user)
    --print("wixie should be shooting right now")
    if inst.components.equippable.isequipped then
        user.SoundEmitter:KillSound("twirl")
        inst._wheel:SetSpinning(false)
        local ammo = inst.components.weapon.projectile and inst.components.weapon.projectile.."_secondary"
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.wixiepointx ~= nil then
            if ammo ~= nil then
                inst.SoundEmitter:PlaySound("rifts/lunarthrall/attack")
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_small")
                if ammo == "slingshotammo_shadow_proj_secondary" then
                    local xmod = owner.wixiepointx
                    local zmod = owner.wixiepointz
                    local pattern = false
                    if math.random() > 0.5 then
                        pattern = true
                    end
                    for i = 1, 2 * inst.powerlevel + 1 do
                        inst:DoTaskInTime(0.03 * i, function()
                            local caster = inst.components.inventoryitem.owner
                            local spittarget = SpawnPrefab("slingshot_target")
                            local multipl = (pattern and -100 or 100) / (inst.powerlevel * 2)
                            local maxangle = multipl / 2
                            local varangle = maxangle - multipl
                            maxangle = maxangle - (varangle / 2)
                            local theta = (inst:GetAngleToPoint(owner.wixiepointx, 0.5, owner.wixiepointz) + (maxangle + (varangle * (i-1)))) * DEGREES
                            xmod = owner.wixiepointx + 15 * math.cos(theta)
                            zmod = owner.wixiepointz - 15 * math.sin(theta)
                            spittarget.Transform:SetPosition(xmod, 0.5, zmod)
                            LaunchSpit(inst, caster, spittarget, true)
                            spittarget:DoTaskInTime(.1, spittarget.Remove)
                        end)
                    end
                else
                    local caster = inst.components.inventoryitem.owner
                    local spittarget = SpawnPrefab("slingshot_target")
                    --local pos = TheInput:GetWorldPosition()
                    spittarget.Transform:SetPosition(owner.wixiepointx, 0.5, owner.wixiepointz)
                    LaunchSpit(inst, caster, spittarget)
                    spittarget:DoTaskInTime(0, spittarget.Remove)
                end
                UnloadAmmo(inst)
            end
        end
    end
end

local function CanChannel(doer, target, pos)
    return doer:HasTag("troublemaker")
end

local function ForceChannel(inst, target, pos)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        if owner.components.channelcaster:IsChanneling() then
            createlight(inst, owner)
            owner.components.channelcaster:StopChanneling(inst)
        else
            owner.components.channelcaster:StartChanneling(inst)
        end
    end
end

local function AddChannelCastable(inst)
    if inst.components.channelcastable then return end
    local channelcastable = inst:AddComponent("channelcastable")
    channelcastable:SetStrafing(false)
    channelcastable:SetOnStartChannelingFn(OnStartChanneling)
    channelcastable:SetOnStopChannelingFn(OnStopChanneling)
end

local function OnEquip(inst, owner)
    AddChannelCastable(inst)
    owner.AnimState:OverrideSymbol("swap_object", "swap_minifan", "swap_minifan")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst._wheel ~= nil then
        inst._wheel:Remove()
    end
    inst._wheel = SpawnPrefab("fan_wheel")
    inst._wheel.entity:SetParent(owner.entity)
    inst._wheel:ListenForEvent("onremove", onremove, inst)

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function OnUnequip(inst, owner)
    owner.SoundEmitter:KillSound("twirl")

    if inst._wheel ~= nil then
        inst._wheel:StartUnequipping(inst)
        inst._wheel = nil
    end

    if inst._owner ~= nil then
        inst._owner = nil
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("minifan")
    inst.AnimState:SetBuild("minifan")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("rangedweapon")
    inst:AddTag("wixie_weapon")
    inst:AddTag("slingshot_claire")
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("veryquickcast")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("donotautopick")
    --inst.projectiledelay = PROJECTILE_DELAY

    MakeInventoryFloatable(inst, "med", 0.075, {0.5, 0.4, 0.5}, true, -7, floater_swap_data)

    inst.spelltype = "WIXIE_SLING"

    local reticule = inst:AddComponent("reticule")
    reticule.reticuleprefab = "wixie_reticuleline"
    reticule.pingprefab = "reticulelongping"
    --reticule.reticuleprefab = "reticuleline2"
    --reticule.pingprefab = "reticulelineping"
    reticule.targetfn = ReticuleTargetFn
    reticule.mousetargetfn = ReticuleMouseTargetFn
    reticule.updatepositionfn = ReticuleUpdatePositionFn
    reticule.validcolour = { 1, 1, 1, 1 }
    reticule.invalidcolour = { .5, 0, 0, 1 }
    reticule.ease = true
    reticule.mouseenabled = true
    reticule.ispassableatallpoints = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst) 
            if inst.replica.container ~= nil then
                inst.replica.container:WidgetSetup("slingshot") 
            end
        end
        return inst
    end

    inst.powerlevel = 1

    inst:AddComponent("inspectable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem.atlasname = "images/inventoryimages/slingshot_claire.xml"

    local equippable = inst:AddComponent("equippable")
    equippable.restrictedtag = "troublemaker"
    equippable:SetOnEquip(OnEquip)
    equippable:SetOnUnequip(OnUnequip)

    local weapon = inst:AddComponent("weapon")
    weapon:SetDamage(10)
    weapon:SetRange(0.5)
    weapon:SetOnProjectileLaunched(OnProjectileLaunched)
    weapon:SetProjectile(nil)
    weapon:SetProjectileOffset(1)

    local spellcaster = inst:AddComponent("spellcaster")
    spellcaster:SetSpellFn(ForceChannel)
    spellcaster:SetCanCastFn(CanChannel)
    spellcaster.veryquickcast = true
    spellcaster.canuseontargets = true
    spellcaster.canuseondead = true
    spellcaster.canuseonpoint = true
    spellcaster.canuseonpoint_water = true
    spellcaster.canusefrominventory = false

    local container = inst:AddComponent("container")
    container:WidgetSetup("slingshot")
    container.canbeopened = false
    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("slingshot_claire", fn, assets, prefabs)
