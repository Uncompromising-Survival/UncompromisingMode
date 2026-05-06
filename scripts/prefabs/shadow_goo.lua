
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
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0,z,2)
    local goo_near
    for i,v in ipairs(ents) do
        if v.prefab == "shadow_goo_trail" then
            goo_near = true
        end
    end
    if not goo_near then
        local fx = SpawnPrefab("shadow_goo_trail")
        fx.AnimState:SetMultColour(0,0,0,0.8)

        local x,y,z = inst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x,0,z)
    
        fx.angle = 0
    end
end

local function GooNear(inst)
    return FindEntity(inst,4,function(ent) return ent.prefab == "shadow_goo_trail" end)
end

local function DoSplatFx(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local goo
    if inst.prefab == "shadow_goo" then -- A special different ground anim for our fancy goo
        goo = SpawnPrefab("shadow_puff")
    elseif inst.prefab == "heckler_goo" then
        
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
            local inkable, sanity = other.components.inkable, other.components.sanity
            if inst.prefab == "shadow_goo" and not other:HasTag("shadowdominance") then
                if sanity then
                    if sanity:IsInsane() then
                        if inkable then inkable:Ink() end
                        other.components.combat:GetAttacked(caster, TUNING.WARG_GOO_DAMAGE / 2)
                    else
                        sanity:DoDelta(-5)
                    end
                end
            end
            if inst.prefab == "guardian_goo" then --Guardian goo does the effect even if the player isn't insane, and does meaningful damage.
                if inkable then inkable:Ink() end
                other.components.combat:GetAttacked(caster, 50)
                if sanity then sanity:DoDelta(-5) end
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
    inst.AnimState:SetMultColour(0, 0, 0, .8)
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
    inst.Physics:SetSphere(.25)

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
    inst.AnimState:SetMultColour(0,0,0,0.8)
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

    inst:DoPeriodicTask(.4, function(inst)
        if not GooNear(inst) then
            SpawnHecklerGooTrail(inst)
        end
    end)

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

    inst.AnimState:SetMultColour(0, 0, 0, .8)
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


local function FadeAway(inst,fast)
    inst.fading = true
    inst.AnimState:PlayAnimation("idle", false)
    if fast then
        inst.AnimState:SetDeltaTimeMultiplier(10) -- not the right function call...
    end
    inst:ListenForEvent("animover",function(inst)
        inst:Remove() 
    end)
end

local function RainedOnParade(inst)
    if inst.components.timer and inst.components.timer:GetTimeLeft("fadeout") then
        local time = inst.components.timer:GetTimeLeft("fadeout")/2
        inst.components.timer:SetTimeLeft("fadeout",time)
    else
        if not inst.entity:IsAwake() then
            inst:Remove()
        else
            FadeAway(inst)
        end
    end
end


local function OnUpdate(inst)
    local should_tentacle
    if FindEntity(inst, 3, nil,{"locomotor" },{"flying", "playerghost", "INLIMBO","shadow"}) then
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

local function StopTentacleChecking(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end

    if inst.fading then -- Unloading/loading calls this function, if the goo is on the animation to remove itself, then it should be removed when it unloads
        inst:Remove()
    end
end

local function SetUpTentacleChecking(inst)
    StopTentacleChecking(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local onupdatefn = OnUpdate
    onupdatefn(inst)
    inst.task = inst:DoPeriodicTask(0.25, onupdatefn) -- larger gap in dotaskintime to improve performance
end

local function OnInit(inst)
    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = inst.Transform:GetScale()
    SetUpTentacleChecking(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/honey_drip")

    if not inst.components.timer:TimerExists("fadeout") then
        inst.components.timer:StartTimer("fadeout",60*8*10)
        if TheWorld.state.israining then
            RainedOnParade(inst)
        end
    end
end

-- These are left here incase we need any additional sleep/wake functions
local function EntityWake(inst)
    SetUpTentacleChecking(inst)
end

local function EntitySleep(inst)
    StopTentacleChecking(inst)
end

local function TryRemove(inst)
    if not inst.entity:IsAwake() then
        inst:Remove()
    else
        FadeAway(inst)
    end
end

local function fngoo()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    --inst:AddTag("FX")
    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.AnimState:SetBank("treegrowthsolution")
    inst.AnimState:SetBuild("treegrowthsolution")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:PlayAnimation("pre_idle", false)

    inst.AnimState:SetMultColour(0, 0, 0, .8)

    inst:AddTag("um_washable_goo")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:DoTaskInTime(0, OnInit)

    --[[inst.OnSave = function(inst, data)

    end

    inst.OnLoad = function(inst, data)

    end]]

    inst:ListenForEvent("timerdone",TryRemove)

    inst:ListenForEvent("entitysleep", EntitySleep)
    inst:ListenForEvent("entitywake", EntityWake)

    inst.FadeAway = FadeAway
    inst:WatchWorldState("startrain", RainedOnParade) -- Make it go away quicker...

    inst.persists = true
    inst.OnStartFade = FadeAway

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