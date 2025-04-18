require "prefabutil"

local function onfinished_normal(inst)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
        if inst.components.finiteuses:GetUses() > 0 and inst.traptype then
            local trapprefab = SpawnPrefab("um_bear_trap_equippable_"..inst.traptype)
            if trapprefab then
                local pos = inst.latchedtarget ~= nil and inst.latchedtarget:IsValid() and inst.latchedtarget or inst
                trapprefab.Transform:SetPosition(pos.Transform:GetWorldPosition())
                trapprefab.components.finiteuses:SetUses(inst.components.finiteuses:GetUses())
                trapprefab.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
                trapprefab.AnimState:PlayAnimation("hit")
            end
            inst:Remove()
            return
        end
    end

    for _, tag in pairs({"notarget", "noattack"}) do
        inst:AddTag(tag)
    end

    if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

    if inst.deathtask then
        inst.deathtask:Cancel()
        inst.deathtask = nil
    end

    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("mine")

    inst:AddTag("NOCLICK")

    inst.persists = false
    inst.Physics:SetActive(false)

    if not (inst.Snapped or inst.AnimState:IsCurrentAnimation("hit")) then
        inst.AnimState:PlayAnimation("activate")
    end
    inst.AnimState:PushAnimation("death", false)

    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:DoTaskInTime(3, inst.Remove)

    if inst.latchedtarget and inst.latchedtarget:IsValid() then
        local pos = Vector3(inst.latchedtarget.Transform:GetWorldPosition())
        if inst.latchedtarget.components.locomotor then
            inst.latchedtarget.components.locomotor:RemoveExternalSpeedMultiplier(inst.latchedtarget, inst.prefab)
            if inst.latchedtarget._bear_trap_speedmulttask then
                inst.latchedtarget._bear_trap_speedmulttask:Cancel()
                inst.latchedtarget._bear_trap_speedmulttask = nil
            end
        end
        inst.latchedtarget:RemoveChild(inst)
        inst.Physics:Teleport(pos.x, pos.y, pos.z)
    end
end

local function debuffremoval(inst)
    if inst.latchedtarget and inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst.latchedtarget, "um_bear_trap")
        if inst._bear_trap_speedmulttask then
            inst._bear_trap_speedmulttask:Cancel()
            inst._bear_trap_speedmulttask = nil
        end
    end
end

local function OnExplode(inst, target)
    if not target or not target:IsValid() then
        onfinished_normal(inst)
    else
        if not inst.deathtask then
            inst.deathtask = inst:DoTaskInTime(30, onfinished_normal)
        end

        inst.Snapped = true
        inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_trigger")
        -- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_sharp")

        inst.AnimState:PlayAnimation("activate")
        if target.SoundEmitter then
            target.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_trigger")
        end

        if inst.deathtask then
            inst.deathtask:Cancel()
            inst.deathtask = nil
        end

        target.components.combat:GetAttacked(target.components.combat and target.components.combat.target or inst, TUNING.TRAP_TEETH_DAMAGE * (inst.traptype == "gold" and 1.5 or 1))

        inst.latchedtarget = target

        inst.AnimState:SetFinalOffset(1)
        inst.Physics:Teleport(0, 0, 0)
        target:AddChild(inst)
        -- inst.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol or "body", 0, --[[-50]]0, 0)

        if target.components.health and target.components.health:IsDead() then
            inst.components.health:Kill()
        else
            local debuffkey = inst.prefab

            inst:ListenForEvent("death", function(player) onfinished_normal(inst) end, target)
            inst:ListenForEvent("onremoved", function(player) onfinished_normal(inst) end, target)
            if target.components.locomotor then
                target.components.locomotor:SetExternalSpeedMultiplier(target, debuffkey, inst.traptype and 0.5 + 0.15 or 0.7)
                target._bear_trap_speedmulttask = target:DoTaskInTime(10, function(i)
                    i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                    i._bear_trap_speedmulttask = nil
                end)

                local function RemoveSpeed(inst)
                    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, debuffkey)
                    if inst._bear_trap_speedmulttask then
                        inst._bear_trap_speedmulttask:Cancel()
                        inst._bear_trap_speedmulttask = nil
                    end
                end

                target:ListenForEvent("onremoved", RemoveSpeed, inst)
            end
            inst:DoTaskInTime(10, function(inst) inst.components.health:Kill() end)

            inst.persists = false
        end

        inst:RemoveComponent("inventoryitem")
        inst:RemoveComponent("mine")
    end
end

local function OnReset(inst)
    inst.Snapped = false

    inst.Physics:ClearCollisionMask()
    -- inst:SetPhysicsRadiusOverride(3)
    inst.Physics:CollidesWith(COLLISION.WORLD)

    if inst.components.inventoryitem then
        inst.components.inventoryitem.nobounce = true
    end

    if not inst.AnimState:IsCurrentAnimation("idle") then
        inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_reset")
        inst.AnimState:PlayAnimation("land")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function SetSprung(inst)
    if inst.components.inventoryitem then
        inst.components.inventoryitem.nobounce = true
    end
    if not inst:IsInLimbo() then end
    inst.AnimState:PlayAnimation("idle_active")
end

local function SetInactive(inst)
    if inst.components.inventoryitem then
        inst.components.inventoryitem.nobounce = false
    end
    inst.AnimState:PlayAnimation("idle")
end

local function OnDropped(inst)
    inst.components.mine:Reset()
    inst.SoundEmitter:PlaySound("dontstarve/common/trap_teeth_reset")
end

local function ondeploy(inst, pt, deployer)
    inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_blunt")
    inst.components.mine:Reset()
    inst.Physics:Stop()
    inst.Physics:Teleport(pt:Get())
end

local function OnHaunt(inst, haunter)
    if inst.components.mine and not inst.components.mine.issprung then
        OnExplode(inst, nil)
        return true
    elseif not inst.components.mine or inst.components.mine.inactive then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
        Launch(inst, haunter, TUNING.LAUNCH_SPEED_SMALL)
        return true
    elseif not inst.components.mine.issprung then
        return false
    elseif math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        inst.components.mine:Reset()
        return true
    end
    return false
end


local function BecomeItem(inst)
    local jaw = SpawnPrefab("snappy_jaw")
    jaw.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --jaw.AnimState:PlayAnimation("become_item", false)
    jaw.AnimState:PlayAnimation("item",true)
    inst:Remove()
end

local function AlmostBecomeItem(inst)
    inst.um_dropping_bear_trap = true
    for _, tag in pairs({"notarget", "noattack"}) do
        inst:AddTag(tag)
    end
    inst:RemoveComponent("mine")
    inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
    inst.AnimState:PlayAnimation("become_item", false)
    inst:ListenForEvent("animover", BecomeItem)
end

local function OnAttacked(inst, worker)
    if not (inst.components.health and inst.components.health:IsDead() or inst.um_dropping_bear_trap) then
        if inst.Snapped then
            inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_dull")
            inst.AnimState:PlayAnimation("hit")
        else
            if inst.prefab == "um_bear_trap_old" then
                AlmostBecomeItem(inst)
            else
                OnExplode(inst, nil)
            end
        end
    end
end

local function calculate_mine_test_time()
    return TUNING.STARFISH_TRAP_TIMING.BASE + (math.random() * TUNING.STARFISH_TRAP_TIMING.VARIANCE)
end

local function CommonMine(inst, alignment, reset)
    local mine = inst:AddComponent("mine")
    mine:SetRadius(TUNING.TRAP_TEETH_RADIUS * 1.3)
    mine:SetAlignment(alignment)
    mine:SetOnExplodeFn(OnExplode)
    mine:SetOnResetFn(OnReset)
    mine:SetOnSprungFn(SetSprung)
    mine:SetOnDeactivateFn(SetInactive)
    mine:SetTestTimeFn(calculate_mine_test_time)
    if reset then
        mine:Reset()
    end
end

local function common_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("soulless")
    inst:AddTag("noember")
    inst:AddTag("houndfriend")
    inst:AddTag("trap")
    inst:AddTag("bear_trap")
    inst:AddTag("smallcreature")
    inst:AddTag("mech")
    inst:AddTag("noclaustrophobia")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(8)
    inst.components.finiteuses:SetUses(8)

    inst.latchedtarget = nil
    inst.Snapped = false

    inst:AddComponent("inspectable")

    -- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_blunt")
    -- was causing a mem leak on the beta :/

    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    CommonMine(inst, "bear_trap_immune", true)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WALRUS_HEALTH)
    inst:ListenForEvent("death", onfinished_normal)

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.deathtask = inst:DoTaskInTime(30, onfinished_normal)

    return inst
end

local function old_fn(build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap_old")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("soulless")
    inst:AddTag("houndfriend")
    inst:AddTag("trap")
    inst:AddTag("bear_trap")
    inst:AddTag("smallcreature")
    inst:AddTag("mech")
    inst:AddTag("noclaustrophobia")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.latchedtarget = nil
    inst.Snapped = false

    inst:AddComponent("inspectable")

    -- inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_blunt")

    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    CommonMine(inst, "bear_trap_immune", true)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WALRUS_HEALTH)
    inst:ListenForEvent("death", onfinished_normal)

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    -- inst.deathtask = inst:DoTaskInTime(30, onfinished_normal) don't die

    return inst
end

local function OnHitInk(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()

    inst.trap = SpawnPrefab("um_bear_trap")
    inst.trap.Transform:SetPosition(x, 0, z)

    if inst.components.finiteuses and inst.trap.components.finiteuses then
        inst.components.finiteuses:SetUses(inst.components.finiteuses:GetUses())
    end

    inst:Remove()
end

local function OnHitTarget(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()

    inst.trap = SpawnPrefab("um_bear_trap")
    inst.trap.Transform:SetPosition(x, 0, z)
    if target then inst.trap.components.mine:Explode(target) end

    if inst.components.finiteuses and inst.trap.components.finiteuses then
        inst.components.finiteuses:SetUses(inst.components.finiteuses:GetUses())
    end

    inst:Remove()
end

local function oncollide(inst, other)
    local x, y, z = inst.Transform:GetWorldPosition()
    if other and not other:HasTag("walrus") and not other:HasTag("hound") and
        other:IsValid() and other:HasTag("_combat") then
        OnHitTarget(inst, other)
    elseif y <= inst:GetPhysicsRadius() + 0.001 then
        OnHitInk(inst, other)
    end
end

local function onthrown_player(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    -- inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst:SetPhysicsRadiusOverride(3)
    inst.Physics:CollidesWith(COLLISION.WORLD)
    -- inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)

    inst.Physics:SetCollisionCallback(oncollide)
end

local function projectilefn()
    local inst = CreateEntity()

    inst:AddTag("bear_trap")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap")
    inst.AnimState:PushAnimation("idle", false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHitInk)
    inst.components.complexprojectile:SetOnLaunch(onthrown_player)
    inst.components.complexprojectile:SetHorizontalSpeed(30)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(2, 2, 0))
    inst.components.complexprojectile.usehigharc = false

    inst.persists = false

    inst:AddComponent("locomotor")

    -- inst:DoTaskInTime(0.1, function(inst) inst:DoPeriodicTask(0, TestProjectileLand) end)

    return inst
end

local function SpawnNearVacantSpot(x, y, z)
    local spots = TheSim:FindEntities(x, y, z, 14, { "walrus_trap_spot" })
    local spotfound = false
    for i, v in ipairs(spots) do
        if spotfound == false then
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            if #TheSim:FindEntities(x1, y1, z1, 2, { "bear_trap" }) == 0 then
                spotfound = true
                local trap = SpawnPrefab("um_bear_trap_old")
                local offset1, offset2
                if math.random() > 0.5 then
                    offset1 = math.random(25, 50) / 100
                else
                    offset1 = -math.random(25, 50) / 100
                end
                if math.random() > 0.5 then
                    offset2 = math.random(25, 50) / 100
                else
                    offset2 = -math.random(25, 50) / 100
                end
                trap.Transform:SetPosition(x1 + offset1, y1, z1 + offset2)
            end
        end
    end
end

local function VacantSpotNearby(x, y, z)
    local spots = TheSim:FindEntities(x, y, z, 14, { "walrus_trap_spot" })
    local spotfound = false
    for i, v in ipairs(spots) do
        local x1, y1, z1 = v.Transform:GetWorldPosition()
        if #TheSim:FindEntities(x1, y1, z1, 2, { "bear_trap" }) == 0 then
            spotfound = true
        end
    end

    if spotfound then return true end
end

local function DoSpawnTrap(x, y, z)
    if VacantSpotNearby(x, y, z) then -- For spawning behind certain prefabs
        SpawnNearVacantSpot(x, y, z)
    end
    local xi = x + math.random(-7, 7)
    local zi = z + math.random(-7, 7) -- Prevent traps from being placed inside things. Add more things to list as you please
    if TheWorld.Map:IsAboveGroundAtPoint(xi, 0, zi) and
        #TheSim:FindEntities(xi, y, zi, 1.5, { "giant_tree" }) and
        #TheSim:FindEntities(xi, y, zi, 1.5, { "bear_trap" }) == 0 and
        #TheSim:FindEntities(xi, y, zi, 5, { "bear_trap" }) < 2 then
        local trap = SpawnPrefab("um_bear_trap_old")
        trap.Transform:SetPosition(xi, y, zi)
    end
end

local function Spawntrap(inst)
    -- TheNet:Announce("spawntrap")
    if TheWorld.state.iswinter then
        local x, y, z = inst.Transform:GetWorldPosition() -- If the area is heavily lived in, bear traps will become a nuisance rather than a danger, know when to stop.
        if #TheSim:FindEntities(x, y, z, 10, { "bear_trap" }) < 7 and
            #TheSim:FindEntities(x, y, z, 30, { "structure" }, { "webbedcreature" }) <
            20 and #TheSim:FindEntities(x, y, z, 40, { "player" }) == 0 then
            DoSpawnTrap(x, y, z)
        end
        inst.components.timer:StartTimer("spawntrap", 600 + math.random(0, 300))
    end
end

local function ghost_walrusfn() -- ghost walrus
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end
    inst:AddTag("ghost_walrus")
    inst:AddTag("CLASSIFIED")

    inst:AddComponent("timer")
    if not inst.components.timer:TimerExists("spawntrap") and
        TheWorld.state.iswinter then
        inst.components.timer:StartTimer("spawntrap", 600 + math.random(0, 300)) -- ghost walrus leaves bear traps in the player's fridge
    end

    inst:WatchWorldState("iswinter", function(inst)
        if TheWorld.state.iswinter then
            if not inst.components.timer:TimerExists("spawntrap") and
                TheWorld.state.iswinter then
                inst.components.timer:StartTimer("spawntrap", 600 + math.random(0, 300)) -- ghost walrus leaves bear traps in the player's fridge
            end
        end
    end)
    if TUNING.DSTU.GHOSTWALRUS == "enabled" then
        inst:ListenForEvent("timerdone", Spawntrap)
    end
    return inst
end

local function OnHitInk(inst, target)
    inst:RemoveTag("NOCLICK")
    inst:RemoveTag("projectile")

    if inst.components.mine then
        local x, y, z = inst.Transform:GetWorldPosition()

        MakeInventoryPhysics(inst)

        inst.components.mine:Reset()

        inst.Transform:SetPosition(x, y, z)
        -- inst.trap = SpawnPrefab("um_bear_trap")
        -- inst.trap.Transform:SetPosition(x, 0, z)

        -- inst:Remove()
    end
end

local function OnHitTarget_player(inst, target)
    inst:RemoveTag("NOCLICK")
    inst:RemoveTag("projectile")

    if inst.components.mine then
        local x, y, z = inst.Transform:GetWorldPosition()

        MakeInventoryPhysics(inst)

        inst.components.mine:Reset()

        inst.Transform:SetPosition(x, y, z)
        -- inst.trap = SpawnPrefab("um_bear_trap")
        -- inst.trap.Transform:SetPosition(x, 0, z)
        if target then
            -- inst.trap.components.mine:Explode(target)
            inst.components.mine:Explode(target)
        end

        -- inst:Remove()
    end
end

local function oncollide_player(inst, other)
    local x, y, z = inst.Transform:GetWorldPosition()

    if other and not other:HasTag("player") and
        not other:HasTag("notraptrigger") and not other:HasTag("player") and
        not other:HasTag("flying") and not other:HasTag("ghost") and
        not other:HasTag("playerghost") and not other:HasTag("spawnprotection") and
        other:IsValid() and other:HasTag("_combat") then
        OnHitTarget_player(inst, other)
    elseif y <= inst:GetPhysicsRadius() + 0.001 then
        OnHitInk(inst, other)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_beartrap_" .. inst.traptype, "swap_um_beartrap")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onthrown_player(inst)
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")

    inst.persists = false

    inst.AnimState:SetBank("um_bear_trap")
    -- inst.AnimState:SetBuild("um_bear_trap")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    -- inst:SetPhysicsRadiusOverride(3)
    -- inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)

    inst.Physics:SetCollisionCallback(oncollide_player)
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    -- Attack range is 8, leave room for error
    -- Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and
            not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function equiptoothfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    MakeInventoryPhysics(inst)

    -- projectile (from complexprojectile component) added to pristine state for optimization

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap_tooth")
    inst.AnimState:PlayAnimation("idle_active")

    inst:AddTag("weapon")
    inst:AddTag("soulless")
    inst:AddTag("trap")
    inst:AddTag("bear_trap")
    inst:AddTag("smallcreature")
    inst:AddTag("mech")
    inst:AddTag("noclaustrophobia")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst, "med", 0.05, 0.65)

    inst.entity:SetPristine()

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(6)
    inst.components.finiteuses:SetUses(6)

    inst.latchedtarget = nil
    inst.Snapped = false

    inst:AddComponent("locomotor")

    CommonMine(inst, "player")

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(2, 2, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown_player)
    inst.components.complexprojectile:SetOnHit(OnHitInk)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(20, 0.5)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/um_bear_trap_equippable_tooth.xml"

    inst:AddComponent("inspectable")

    inst.traptype = "tooth"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("health")
    inst.components.health.canmurder = false
    inst.components.health:SetMaxHealth(TUNING.WALRUS_HEALTH / 2)
    inst:ListenForEvent("death", onfinished_normal)

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    MakeHauntableLaunch(inst)

    return inst
end

local function equipgoldfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    MakeInventoryPhysics(inst)

    -- projectile (from complexprojectile component) added to pristine state for optimization

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap_gold")
    inst.AnimState:PlayAnimation("idle_active")

    inst:AddTag("weapon")
    inst:AddTag("soulless")
    inst:AddTag("trap")
    inst:AddTag("bear_trap")
    inst:AddTag("smallcreature")
    inst:AddTag("mech")
    inst:AddTag("noclaustrophobia")
    inst:AddTag("donotautopick")
    MakeInventoryFloatable(inst, "med", 0.05, 0.65)

    inst.entity:SetPristine()

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(8)
    inst.components.finiteuses:SetUses(8)

    inst:AddComponent("bloomer")
    inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", 1)

    inst.latchedtarget = nil
    inst.Snapped = false

    inst:AddComponent("locomotor")

    CommonMine(inst, "player")

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(2, 2, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown_player)
    inst.components.complexprojectile:SetOnHit(OnHitInk)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(20, 0.5)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/um_bear_trap_equippable_gold.xml"

    inst:AddComponent("inspectable")

    inst.traptype = "gold"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("health")
    inst.components.health.canmurder = false
    inst.components.health:SetMaxHealth(TUNING.WALRUS_HEALTH / 1.5)
    inst:ListenForEvent("death", onfinished_normal)

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_bear_trap", common_fn), Prefab("um_bear_trap_old", old_fn),
    MakePlacer("um_bear_trap_placer", "trap_teeth", "trap_teeth", "idle"),
    Prefab("um_bear_trap_projectile", projectilefn),
    Prefab("ghost_walrus", ghost_walrusfn),
    Prefab("um_bear_trap_equippable_tooth", equiptoothfn),
    Prefab("um_bear_trap_equippable_gold", equipgoldfn)