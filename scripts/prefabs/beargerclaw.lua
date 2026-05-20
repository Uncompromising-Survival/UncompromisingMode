local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local prefabs =
{
    "stafflight",
    "reticule",
}

local easing = require("easing")

local function charged(inst)
    local fx = SpawnPrefab("dr_warmer_loop")
    
    local owner = inst.components.inventoryitem.owner
    
    if inst.components.equippable:IsEquipped() and owner ~= nil then
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -275, 0)
        fx.Transform:SetScale(1.11, 1.11, 1.11)
    else
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, 2.35, 0)
        fx.Transform:SetScale(1.11, 1.11, 1.11)
    end
end

local function SpawnFx(inst, stage, scale)
    local theta = math.random() * PI * 2
    local num = 7
    local radius = 1.6
    local dtheta = TWOPI / num
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sinkhole_spawn_fx_"..math.random(3)).Transform:SetPosition(x, y, z)
    for i = 1, num do
        local dust = SpawnPrefab("sinkhole_spawn_fx_"..math.random(3))
        dust.Transform:SetPosition(x + math.cos(theta) * radius * (1 + math.random() * .1), 0, z - math.sin(theta) * radius * (1 + math.random() * .1))
        local s = scale + math.random() * .2
        dust.Transform:SetScale(i % 2 == 0 and -s or s, s, s)
        theta = theta + dtheta
    end
    inst.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", { size = math.pow(stage / 3, 2) })
end

local function LaunchSpit(caster, pos)
    local x, y, z = caster.Transform:GetWorldPosition()
    
    local ents = TheSim:FindEntities(x, y, z, 5, {"antlion_sinkhole"})
    local pt = caster:GetPosition()
    local boat = TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z)
    local biggy = #ents > 0
    
    if not boat then
        if caster.SoundEmitter ~= nil then
            caster.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/attack")
        end
    
        for i = 1, biggy and 1 or 4 do 
            local targetpos = pos

            local projectile = SpawnPrefab("beargerclaw_boulder")
            projectile.coolingtime = 8
            projectile.Transform:SetPosition(x, y, z)
            projectile.clawer = caster
            
            targetpos.x = targetpos.x + (biggy and 0 or math.random(-2, 2))
            targetpos.z = targetpos.z + (biggy and 0 or math.random(-2, 2))
            
            local dx = targetpos.x - x
            local dz = targetpos.z - z
            
            local rangesq = dx * dx + dz * dz
            local maxrange = TUNING.FIRE_DETECTOR_RANGE
            
            local speed = easing.linear(rangesq, maxrange, 5, maxrange * maxrange)
            projectile.components.complexprojectile:SetHorizontalSpeed(speed * 1.1)
            projectile.components.complexprojectile:SetGravity(-35)
            projectile.components.complexprojectile:Launch(targetpos, caster, caster)
            projectile.components.complexprojectile:SetLaunchOffset(Vector3(1.5, 1.5, 0))
            projectile.biggy = biggy
        end
        
        if biggy then
            for i, v in pairs(ents) do
                if v ~= nil and i == 1 then
                    ErodeAway(v)
                    SpawnFx(v, 1, .45)
                end
            end
        else
            local beager_sinkhole = SpawnPrefab("beargerclaw_sinkhole")
            beager_sinkhole.Transform:SetPosition(x, 0, z)
            --SpawnFx(beager_sinkhole, 3, .8)
        end
    end
    
    if boat ~= nil then
        boat:PushEvent("spawnnewboatleak", {pt = pt, leak_size = "small_leak", playsoundfx = true})
    else
        SpawnPrefab("groundpound_fx").Transform:SetPosition(x, 0, z)
    end
end

local function createlight(staff, target, pos)
    local caster = staff.components.inventoryitem.owner
    LaunchSpit(caster, pos or target and target:GetPosition())
end

local function light_reticuletargetfn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

--local function Working(owner, data)
    --if owner ~= nil and owner:HasTag("player") and owner.components.hunger then
        --owner.components.hunger:DoDelta(-5)
        --owner.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/chew")
    --end
--end

local function onequip(inst, owner)
    if UMCommonFns.VetcurseUnequip(inst, owner, EQUIPSLOTS.HANDS) then return end
    owner.AnimState:OverrideSymbol("swap_object", "swap_beargerclaw", "swap_shovel")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    --inst:ListenForEvent("working", Working, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    
    --inst:RemoveEventCallback("working", Working, owner)
end

local function staff_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("beargerclaw")
    inst.AnimState:SetBuild("beargerclaw")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("nopunch")
    inst:AddTag("donotautopick")
    
    --Sneak these into pristine state for optimization
    inst:AddTag("beargerclaw")
    inst:AddTag("quickcast")
    inst:AddTag("vetcurse_item")
    inst:AddTag("inventoryitem")
    MakeInventoryFloatable(inst)

    inst.spelltype = "SCIENCE"

    inst.entity:SetPristine()
    
    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DIG)
    
    inst:AddInherentAction(ACTIONS.DIG)
    
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("beargerclaw", staff_fn, assets, prefabs)