local assets =
{
    Asset("ANIM", "anim/magnerang.zip"),
    Asset("ANIM", "anim/swap_magnerang.zip"),
    Asset("ANIM", "anim/swap_blowdart_pipe.zip"),
}

local _turnoffstring = ACTIONS.TURNOFF.strfn

ACTIONS.TURNOFF.strfn = function(act)
    local tar = act.target
    return tar ~= nil and tar:HasTag("harpoonreel") and "HARPOON" or _turnoffstring(act)
end

local prefabs =
{
    "impact",
}

local prefabs_yellow =
{
    "impact",
    "electrichitsparks",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_magnerang", "swap_boomerang")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnFinished(inst)
    if inst.components.inventoryitem then
        inst.components.inventoryitem.canbepickedup = false
    end
    inst.AnimState:PlayAnimation("used")
    inst:ListenForEvent("animover", inst.Remove)
end

local function OnDropped(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
    inst:PushEvent("on_landed")
end

local function ClearThrownPos(inst)
    if inst.thrownpos then
        inst.thrownpos = nil
    end
end

local function OnHit(inst, owner, target)
    if not inst.reel then
        local impactfx = SpawnPrefab("impact")
        if impactfx and target.components.combat then
            local follower = impactfx.entity:AddFollower()
            follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
            if owner and owner:IsValid() then
                impactfx:FacePoint(owner.Transform:GetWorldPosition())
            end
        end
        local p = inst.thrownpos or owner:GetPosition()
        if p then
            local ground = TheWorld.Map:IsPassableAtPoint(p.x, p.y, p.z)
            local boat = TheWorld.Map:GetPlatformAtPoint(p.x, p.z)
            if ground or boat then
                local reel = SpawnPrefab("um_magnerangreel")
                if inst.components.finiteuses and inst.components.finiteuses.current then
                    reel.uses = inst.components.finiteuses.current
                end
                reel.Transform:SetPosition(p.x, p.y, p.z)
                reel.target = target
                reel.AnimState:PlayAnimation(boat and "place_boat" or "place")
            end
        end
        inst:Remove()
    else
        local x, y, z = target.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, 1.5, z)
        if inst.components.finiteuses and inst.components.finiteuses.current <= 0 then
            OnFinished(inst)
        else
            OnDropped(inst)
        end
        ClearThrownPos(inst)
        inst.reel.AnimState:PlayAnimation("break")
        inst.reel:ListenForEvent("animover", inst.Remove)
        inst.reel = nil
    end
end

local function OnThrown(inst, owner, target)
    if target ~= owner then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
    end
    if not inst.thrownpos then
        inst.thrownpos = owner:GetPosition()
    end
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.pushlandedevents = false
end

local function OnCaught(inst, catcher)
    if catcher and catcher.components.inventory and catcher.components.inventory.isopen then
        if inst.components.equippable and not catcher.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
            catcher.components.inventory:Equip(inst)
        else
            catcher.components.inventory:GiveItem(inst)
        end
        catcher:PushEvent("catch")
    end
    ClearThrownPos(inst)
end

local function OnMiss(inst, owner, target)
    OnDropped(inst)
    inst.components.projectile:Stop()
    inst.Physics:Stop()
    ClearThrownPos(inst)
    if inst.reel then
        inst.reel.AnimState:PlayAnimation("break")
        inst.reel:ListenForEvent("animover", inst.Remove)
    end
end

local function fncommon()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("boomerang")
    inst.AnimState:SetBuild("magnerang")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("thrown")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    MakeInventoryFloatable(inst, "small", 0.05, { 0.75, 0.5, 0.75 })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(34)
    inst.components.weapon:SetRange(TUNING.BOOMERANG_DISTANCE, TUNING.BOOMERANG_DISTANCE + 2)
    -------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(10)
    inst.components.projectile:SetCanCatch(true)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile:SetOnCaughtFn(OnCaught)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.BOOMERANG_USES * 1.5)
    inst.components.finiteuses:SetUses(TUNING.BOOMERANG_USES * 1.5)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    MakeHauntableLaunch(inst)

    return inst
end

local function OnCooldown(inst)
    inst._cdtask = nil
end

local function CooldownSound(inst)
    inst._soundcd = nil
end

local function Vac(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.magnet_damage < 200 and inst and inst:IsValid() and inst.target and inst.target:IsValid() and not inst.target:HasTag("INLIMBO") then
        local px, py, pz = inst.target.Transform:GetWorldPosition()

        local distmult = (inst:GetDistanceSqToInst(inst.target) / 200)
        local tuningmultiplier = inst.target:HasTag("epic") and 1.5 or 1.25
        --TheNet:Announce(inst.magnet_damage)

        if inst.hitfx then
            if inst.magnet_damage <= 50 and inst.soundlevel == nil then
                inst.soundlevel = 50
                inst.hitfx.SoundEmitter:PlaySound("UCSounds/magnerang/slow_pull", "pull")
            elseif inst.magnet_damage <= 100 and inst.magnet_damage > 50 and inst.soundlevel == 50 then
                inst.soundlevel = 100
                inst.hitfx.SoundEmitter:KillSound("pull")
                inst.hitfx.SoundEmitter:PlaySound("UCSounds/magnerang/mid_pull", "pull")
            elseif inst.magnet_damage <= 150 and inst.magnet_damage > 100 and inst.soundlevel == 100 then
                inst.soundlevel = 150
                inst.hitfx.SoundEmitter:KillSound("pull")
                inst.hitfx.SoundEmitter:PlaySound("UCSounds/magnerang/high_pull", "pull")
            elseif inst.magnet_damage > 150 and inst.soundlevel == 150 then
                inst.soundlevel = 200
                inst.hitfx.SoundEmitter:KillSound("pull")
                inst.hitfx.SoundEmitter:PlaySound("UCSounds/magnerang/veryhigh_pull", "pull")
            end
        end

        if distmult >= 0.15 then
            local platform = inst:GetCurrentPlatform()

            if platform and platform:IsValid() then
                tuningmultiplier = 0.5
                if not inst._cdtask then
                    inst._cdtask = inst:DoTaskInTime(.5, OnCooldown)

                    local row_dir_x, row_dir_z = VecUtil_Normalize(px - x, pz - z)

                    local boat_physics = platform.components.boatphysics

                    boat_physics:ApplyForce(row_dir_x, row_dir_z, .35 * distmult)
                end
            end

            if inst.target.components.locomotor then
                local rad = math.rad(inst.target:GetAngleToPoint(x, y, z))
                local velx = math.cos(rad) --* 4.5
                local velz = -math.sin(rad) --* 4.5

                local locationmodifier = platform and 0.5 or 1.5

                local dx, dy, dz = px + (((FRAMES * 4) * velx) * locationmodifier) * distmult, 0, pz + (((FRAMES * 4) * velz) * locationmodifier) * distmult

                local ground = TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
                local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
                if dx and (ground or boat or inst.target.components.locomotor:CanPathfindOnWater()) then
                    inst.target.Physics:Teleport(dx, py, dz)
                end
            end
        end

        inst.magnet_damage = inst.magnet_damage + (distmult * tuningmultiplier)
    else
        if inst.hitfx then
            inst.hitfx.SoundEmitter:KillSound("twirl")
        end

        inst:KillRopes()
    end
end

local function Link(inst, option)
    if inst.target then
        if option == "link" then
            if inst.target.magnerang then --If there's already a magnerang, replace it with this new one.
                inst.target.magnerang:KillRopes(inst.target.magnerang)
            end
            inst.target.magnerang = inst
        end
        if option == "remove" then
            inst.target.magnerang = nil
        end
    end
end

local function KillRopes(inst)
    if inst.killedropes then return end
    inst.killedropes = true

    inst.SoundEmitter:PlaySound("UCSounds/harpoon/break")

    inst:AddTag("NOCLICK")

    inst.components.updatelooper:RemoveOnUpdateFn(Vac)

    if inst.hitfx then
        inst.hitfx:Remove()
    end

    if inst.target and inst.target:IsValid() and not inst.target:HasTag("INLIMBO") then
        local x, y, z = inst.target.Transform:GetWorldPosition()
        local proj = SpawnPrefab("um_magnerang")
        if x then
            proj.Transform:SetPosition(x, 1.5, z)
            proj.components.projectile:Throw(inst, inst)
            if inst.target.components and inst.target.components.combat and inst.uses then --Pass the uses from the magnerang
                if proj.components.finiteuses then
                    proj.components.finiteuses.current = inst.uses
                end
            end
            proj.reel = inst
        else
            proj.Transform:SetPosition(inst.Transform:GetWorldPosition())
            proj.components.projectile:Throw(inst, inst)
            proj.reel = inst
        end
        Link(inst, "remove")
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        local magnerang = SpawnPrefab("um_magnerang")
        if magnerang.components.finiteuses and inst.uses then
            magnerang.components.finiteuses.current = inst.uses
            if magnerang.components.finiteuses.current <= 0 then
                OnFinished(magnerang)
            end
        end
        magnerang.Transform:SetPosition(x, 0, z)
        inst.AnimState:PlayAnimation("break")
        inst:ListenForEvent("animover", inst.Remove)
    end
end

local function InitializeRope(inst)
    if inst.target and inst.target:IsValid() then
        Link(inst, "link")

        local x, y, z = inst.target.Transform:GetWorldPosition()

        local hitfx = SpawnPrefab("um_magneranghitfx")
        hitfx.Transform:SetPosition(x, y, z)

        inst.hitfx = hitfx

        if hitfx then
            if inst.target.components.combat then
                local follower = hitfx.entity:AddFollower()
                hitfx.entity:SetParent(inst.target.entity)
                follower:FollowSymbol(inst.target.GUID, inst.target.components.combat.hiteffectsymbol, 0, 0, 0)
            else
                hitfx.Transform:SetPosition(x, 1.5, z)
            end
        end
    end
end

local function DoPuff(inst, channeler)
    inst.SoundEmitter:PlaySound("UCSounds/harpoon/reel")
    inst.AnimState:PlayAnimation("reel")

    inst.components.activatable.inactive = true

    if inst.power > 15 then
        inst.power = inst.power - 15
    end
end

local function OnStopChanneling(inst)
    inst.channeler = nil
end

local function GetVerb(inst)
    return "HARPOON"
end

local function reel()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("harpoonreel")

    inst.AnimState:SetBank("um_magnerang_reel")
    inst.AnimState:SetBuild("um_magnerang_reel")
    inst.AnimState:PlayAnimation("place", false)

    MakeSnowCoveredPristine(inst)

    inst.GetActivateVerb = GetVerb

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.magnet_damage = 0

    inst.target = nil

    inst:AddComponent("inspectable")

    --[[inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = DoPuff
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true]]

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = KillRopes
    inst.components.machine.turnofffn = KillRopes
    inst.components.machine.cooldowntime = 0.5
    inst.components.machine.ison = true

    inst:DoTaskInTime(0, InitializeRope)

    inst.KillRopes = KillRopes

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(Vac)
    
    inst:DoTaskInTime(0, function() inst.SoundEmitter:PlaySound("monkeyisland/autopilot/magnet_lp_start") end)

    inst:DoTaskInTime(60, KillRopes)

    inst.persists = false

    return inst
end

local function fnhit()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_magneranghitfx")
    inst.AnimState:SetBuild("um_magneranghitfx")
    inst.AnimState:PlayAnimation("idle")
    inst.Transform:SetEightFaced()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end
-------------------------------------------------------------------------------
return Prefab("um_magnerang", fncommon, assets, prefabs),
    Prefab("um_magnerangreel", reel, assets, prefabs),
    Prefab("um_magneranghitfx", fnhit, assets, prefabs)