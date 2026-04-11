
local projectile_assets =
{
    Asset("ANIM", "anim/warg_gingerbread_bomb.zip"),
    Asset("ANIM", "anim/goo_icing.zip"),
}

local projectile_prefabs =
{
    "icing_splat_fx",
    "icing_splash_fx_full",
    "icing_splash_fx_med",
    "icing_splash_fx_low",
    "icing_splash_fx_melted",
}

local splashfxlist =
{
    "icing_splash_fx_full",
    "icing_splash_fx_med",
    "icing_splash_fx_low",
    "icing_splash_fx_melted",
}

local AURA_EXCLUDE_TAGS = { "shadow", "shadowminion", "INLIMBO", "notarget", "noattack", "flight"}


local function SpawnHecklerGooTrail(inst,despawn_on_day)
    
    local fx = SpawnPrefab("shadow_goo_trail")
    fx.AnimState:SetMultColour(0,0,0,0.8)
    local variation = math.random(-2,2)
    local angle = 0
    local x,y,z = inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x + 2 * math.cos(angle) + variation * math.cos(angle + 3.14 / 2), 0,
        z + 2 * math.sin(angle) + variation * math.sin(angle + 3.14 / 2))
    if despawn_on_day then
        fx:SetVariation(math.random(1, 7), GetRandomMinMax(1, 1.3), TUNING.TOTAL_DAY_TIME*10)
        fx:WatchWorldState("cycles", function()     
            fx:Remove()
        end)    
    elseif TheWorld.state.israining then
        fx:SetVariation(math.random(1, 7), GetRandomMinMax(1, 1.3), 3) -- If raining, almost immediately remove
    else
        fx:SetVariation(math.random(1, 7), GetRandomMinMax(1, 1.3), TUNING.TOTAL_DAY_TIME*10)
    end
    fx.angle = angle
end

local function GooNear(inst)
    return FindEntity(inst,4,function(ent) return ent.prefab == "shadow_goo_trail" end)
end

local function DoSplatFx(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local goo
    if inst.prefab == "shadow_goo" then -- A special different ground anim for our fancy goo
        goo = SpawnPrefab("shadow_puff")
    elseif inst.prefab == "heckler_goo" and not GooNear(inst) then
        
        --SpawnPrefab("um_shadow_miasma_cloud").Transform:SetPosition(tx, 0, ty)
        SpawnHecklerGooTrail(inst,true)
    elseif inst.organ then
        goo = SpawnPrefab("minotaur_organ")
    elseif not GooNear(inst) then
        SpawnHecklerGooTrail(inst)
    end
    
    if goo ~= nil then
        goo.Transform:SetPosition(x, 0, z)
    end
end

local function doprojectilehit(inst, other)
    DoSplatFx(inst)
    local caster = inst._caster ~= nil and inst._caster:IsValid() and inst._caster or nil
    local x,y,z = inst.Transform:GetWorldPosition()
    local others = TheSim:FindEntities(x, y, z, 1.5, {"_combat", "_health", "player"}, {"INLIMBO", "shadow", "minotaur"}) --I messed around with the funni goo, its range is actually a bit small, so I bumped it up a tad.
    for i,other in ipairs(others) do
        if other and other ~= caster and not other.components.health:IsDead() then
            if inst.prefab == "shadow_goo" and not other:HasTag("shadowdominance") then
                if other.components.sanity and other.components.sanity:IsInsane() then
                    if other.components.inkable then
                        other.components.inkable:Ink()
                    end
                    other.components.combat:GetAttacked(caster, TUNING.WARG_GOO_DAMAGE / 2)
                elseif other.components.sanity and not other:HasTag("shadowdominance") then
                    other.components.sanity:DoDelta(-5)
                end
            end
            if inst.prefab == "guardian_goo" then --Guardian goo does the effect even if the player isn't insane, and does meaningful damage.
                if other.components.inkable then
                    other.components.inkable:Ink()
                end
                other.components.combat:GetAttacked(caster, 50)
                if other.components.sanity then
                    other.components.sanity:DoDelta(-5)
                end
            end
        end
    end
    inst:Remove()
end

local function TestProjectileLand(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if y <= inst:GetPhysicsRadius() + 0.05 then
        doprojectilehit(inst)
        inst:Remove()
    end
end

local function oncollide(inst, other)
    if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasAnyTag("shadow", "minotaur") then
        doprojectilehit(inst, other)
    end
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function mainprojectilefn(anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(anim)
    inst.AnimState:SetBuild(anim)
    inst.AnimState:PushAnimation("spin_loop", true)
    inst.AnimState:SetMultColour(0, 0, 0, 0.4)
    inst.AnimState:UsePointFiltering(true)
    
    inst.Physics:SetMass(10)
    inst.Physics:SetFriction(.1)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetSphere(0.25)
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end    
    
    inst.Physics:SetCollisionCallback(oncollide)

    inst.persists = false
    inst:AddComponent("locomotor")

    inst:DoPeriodicTask(0, TestProjectileLand)

    return inst
end

local function shadow_goofn(inst)
    return mainprojectilefn("warg_gingerbread_bomb")
end

local function guardian_goo()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("projectile")
    inst:AddTag("weapon")

    inst.AnimState:SetBank("squid_watershoot")
    inst.AnimState:SetBuild("squid_watershoot")
    inst.AnimState:PlayAnimation("spin_loop",true)
    inst:AddComponent("locomotor")
    inst.AnimState:SetMultColour(1, 1, 1, .5)
    inst.AnimState:UsePointFiltering(true)

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(40)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 0, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(doprojectilehit)
    inst.tentacle = false
    inst.organ = false
    inst:Hide()
    inst:DoTaskInTime(.2, function(inst) inst:Show() end)    
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(20, 10)

    inst:DoPeriodicTask(.1, SpawnHecklerGooTrail)

    return inst
end

local function guardiansplat()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
    inst:AddTag("FX")
    
    inst.AnimState:SetMultColour(1, 1, 1, .5)
    inst.Transform:SetScale(.7, .7, .7)
    inst.AnimState:SetBank("guardian_splat")
    inst.AnimState:SetBuild("guardian_splat")
    inst.AnimState:PlayAnimation("land")
    inst.AnimState:PushAnimation("go away", false) --crap, forgot the "_" will fix later :sleep:
    inst.AnimState:UsePointFiltering(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:ListenForEvent("animqueueover",function(inst) inst:Remove() end)

    return inst
end
--- From Honey_trail

local function OnUpdate(inst, x, y, z, rad)
    local should_tentacle
    for i, v in ipairs(TheSim:FindEntities(x, y, z, rad, { "locomotor" }, { "flying", "playerghost", "INLIMBO","shadow"})) do
        should_tentacle = true
    end
    if should_tentacle and not FindEntity(inst, 3, function(ent) return ent.prefab == "bigshadowtentacle" end) then
        local tent = SpawnPrefab("bigshadowtentacle")
        tent.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tent:PushEvent("arrive")
    end
end

local function OnIsFadingDirty(inst)
    if inst._isfading:value() then
        inst.task:Cancel()
    end
end

local function OnStartFade(inst)
    inst.AnimState:PlayAnimation(inst.trailname.."_pst")
    inst._isfading:set(true)
    inst.task:Cancel()
end

local function OnAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation(inst.trailname.."_pre") then
        inst.AnimState:PlayAnimation(inst.trailname)
        inst:DoTaskInTime(inst.duration, OnStartFade)
    elseif inst.AnimState:IsCurrentAnimation(inst.trailname.."_pst") then
        inst:Remove()
    end
end

local function OnInit(inst, scale)
    local x, y, z = inst.Transform:GetWorldPosition()
    if scale == nil then
        scale = inst.Transform:GetScale()
    end
    inst.task:Cancel()
    local onupdatefn = OnUpdate
    inst.task = inst:DoPeriodicTask(0.25, onupdatefn, nil, x, y, z, scale) -- larger gap in dotaskintime to improve performance
    onupdatefn(inst, x, y, z, scale)
    inst:AddComponent("unevenground") -- unevenground will handle the slowing
    inst.components.unevenground.radius = scale
end

local function SetVariation(inst, rand, scale, duration)
    if inst.trailname == nil then
        inst.Transform:SetScale(scale, scale, scale)

        inst.trailname = "trail"..tostring(rand)
        inst.duration = duration
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/honey_drip")
        inst.AnimState:PlayAnimation(inst.trailname.."_pre")
        inst:ListenForEvent("animover", OnAnimOver)

        OnInit(inst, scale)
    end
end

local function fngoo()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    --inst:AddTag("FX")
    inst.AnimState:SetBank("honey_trail")
    inst.AnimState:SetBuild("honey_trail")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst._isfading = net_bool(inst.GUID, "honey_trail._isfading", "isfadingdirty")

    inst:AddTag("um_washable_goo")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("isfadingdirty", OnIsFadingDirty)
        inst.task = inst:DoPeriodicTask(0, OnInit)

        return inst
    end

    inst.SetVariation = SetVariation    
    inst.persists = true
    inst.OnStartFade = OnStartFade
    
    inst.task = inst:DoTaskInTime(0, function(inst)
        if inst.trailname ~= nil then
            OnInit(inst)
        end
    end)

    inst.OnSave = function(inst, data)
        data.trailname = inst.trailname
        data.duration = inst.duration
        data.scale = inst.Transform:GetScale()
    end
        
    inst.OnLoad = function(inst, data)
        if data ~= nil then
            if data.scale ~= nil then
                inst.Transform:SetScale(data.scale, data.scale, data.scale)
            end

            inst.trailname = data.trailname
            inst.duration = data.duration or TUNING.TOTAL_DAY_TIME

            if inst.trailname ~= nil then
                inst.AnimState:PlayAnimation(inst.trailname)
                inst:ListenForEvent("animover", OnAnimOver)
                inst.task = inst:DoPeriodicTask(0.25, OnUpdate, nil,
                inst.Transform:GetWorldPosition(), data.scale or 1)
            else
                inst:Remove()
            end
        end
    end

    inst:DoTaskInTime(0, function(inst)
        if inst:IsValid() then
            inst.AnimState:SetMultColour(0,0,0,0.8)
        end
    end)    

    return inst
end

return Prefab("shadow_goo", shadow_goofn, projectile_assets, projectile_prefabs),
    Prefab("heckler_goo", guardian_goo),
    Prefab("guardian_goo", guardian_goo),
    Prefab("guardian_splat", guardiansplat),
    Prefab("shadow_goo_trail", fngoo)