local assets =
{
    Asset("ANIM", "anim/um_canopeer.zip"),
    Asset("ANIM", "anim/um_canopeervine.zip"),
    Asset("ANIM", "anim/um_hoodedvine.zip"),
}

local prefabs = {
    "um_canopeer",
    "um_canopeervine",
    "um_canopeervine_fx"
}

local animtype = {"generic","science","alchemy"}
local notags = { "FX", "NOCLICK", "INLIMBO", "wall", "structure", "aquatic","plantcreature","plantkin"}
local function retargetfn(inst)
    local dist = 16
    return FindEntity(inst, dist, function(guy)
        return inst.components.combat:CanTarget(guy)
    end, nil, notags)
end

local function keeptargetfn(inst, target)
    return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    if data and data.attacker and data.attacker:IsValid() then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function DoSpecialAreaAttack(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,4,{"_combat","_health"},UMCommonFns.GHOSTLIKE_TAGS)
    for i,v in ipairs(ents) do
        if v:IsValid() and not v.prefab == inst.prefab then
            v.components.combat:GetAttacked(inst,40)
        end
    end
end

local ROLL_SS_SPEED = 0.1
local ROLL_SS_SCALE = 0.1
local function screenshake(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, ROLL_SS_SPEED, ROLL_SS_SCALE, inst, 40)
end

local function OnDeathPre(inst)    
    local ring = SpawnPrefab("groundpoundring_fx")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
    ring.Transform:SetScale(.5, .5, .5)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
    inst:DoTaskInTime(2*FRAMES,DoSpecialAreaAttack)

    screenshake(inst)

    if #inst.child_vines > 0 then
        for i,v in ipairs(inst.child_vines) do
            if v.decide_to_attack then
                v.decide_to_attack:Cancel()
                v.decide_to_attack = nil
            end
            if v:HasTag("INLIMBO") then
                v.sg:GoToState("leave_up")
            elseif v.components.health and not v.components.health:IsDead() then
                v.components.health:Kill()
            end
        end
    end

    if #inst.vineFX > 0 then
        for i,v in ipairs(inst.vineFX) do
            v:Remove()
        end       
    end
end

local function TryFindThicketForAphids(inst)
    local player = FindEntity(inst,24,function(guy)
        return guy:HasTag("player")
    end)
    local hooded_fern = FindEntity(inst,24,function(guy)
        return guy.prefab == "hooded_fern" and guy.components.pickable and guy.components.pickable:CanBePicked()
    end)
    if player and hooded_fern then
        hooded_fern.BeginAphidStorm(hooded_fern,player)
    end
end

local function OnDeath(inst)
    local rubble = SpawnPrefab("um_hooded_rubble")
    rubble.Transform:SetPosition(inst.Transform:GetWorldPosition())
    rubble.style = inst.type + 8 -- Rubble loot is shifted by 8 to the canopeer types
    rubble.Transform:SetRotation(inst.Transform:GetRotation())
    rubble.SetAnimations(rubble,rubble.style)
    TryFindThicketForAphids(inst)
    inst:Remove()
end

local function OnSave(inst)
    local data = {}
    data.type = inst.type
    return data
end

local function OnLoad(inst,data)
    if data then
        if data.type then
            inst.type = data.type
        end
    end
end

local function Init(inst)
    if not inst.type then
        inst.type = math.random(1,3)
    end
    inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_idle")
    inst:SetStateGraph("SGum_canopeer") -- Needs to be done after inst.type and inst.animtype is set

end

local function TossVine(inst,target)
    if target and target.components.health and not target.components.health:IsDead() and
        inst and inst.components.health and not inst.components.health:IsDead() then -- Check the condition of both the canopeer and the thing it's sending this particular vine to attack
        local x,y,z = target.Transform:GetWorldPosition()
        local offset = FindWalkableOffset(Vector3(x, y, z), math.random() * PI2, 4 + math.random() * 4, 12 + math.random() * 4)
        if offset then
            local vine = SpawnPrefab("um_canopeervine")
            vine.Transform:SetPosition(x+offset.x,0,z+offset.z)
            vine.components.combat:SetTarget(target)

            vine.canopeer = inst
            table.insert(inst.child_vines,vine)
        end
    end
end

local function FindAltTarget(inst,target)
    if target:HasTag("player") then
        local player = FindEntity(inst,24,function(ent)  
            if ent ~= target and ent:HasTag("player") then
                return true
            end
        end)
        return player 
    else
        local creature = FindEntity(inst,24,function(ent)  
            if ent ~= target and ent.prefab == target.prefab and not target:HasAnyTag(notags) then
                return true
            end
        end)
        return creature 
    end
end

local function CancelVineTossing(inst)
    if inst.VineCheck then
        inst.VineCheck:Cancel()
        inst.VineCheck = nil
    end
end

local function TossVines(inst)
    if not inst.sg:HasAnyStateTag("frozen","thawing") then
        local vines = math.random(3,5)
        local target = inst.components.combat and inst.components.combat.target

        if target and target:IsValid() and target:GetDistanceSqToInst(inst) < 24^2 then
            for i = 1,math.random(1,2) do
                TossVine(inst,target)
                vines = vines - 1
            end
        else
            inst.components.combat.target = nil
            CancelVineTossing(inst)
        end

        -- Throw additional vines
        if target then
            while vines > 0 do
                local alttarget = FindAltTarget(inst,target)
                if alttarget and math.random() > 0.33 then
                    inst:DoTaskInTime(math.random(20,30)/10,function(inst) TossVine(inst,alttarget) end)
                else
                    inst:DoTaskInTime(math.random(20,30)/10,function(inst) TossVine(inst,target) end)
                    if not alttarget then
                        vines = vines - 2
                    end
                end
                vines = vines - 1
            end
        end
    end
end

local function RemoveVineChild(inst,vine)
    for i,v in ipairs(inst.child_vines) do
        if v == vine then
            table.remove(inst.child_vines,i)
        end
    end
end

local function BeginThrowingOutVines(inst)
    if not inst.VineCheck then
        TossVines(inst)
        inst.VineCheck = inst:DoPeriodicTask(10,TossVines)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, 1)
    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("um_canopeer")
    inst.AnimState:SetBuild("um_canopeer")
    --inst.AnimState:PlayAnimation("idle")

    inst:AddTag("plantcreature")
    inst:AddTag("plantkin")
    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(900)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "fire"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    --inst.components.combat:SetDefaultDamage(10)
    --inst.components.combat:SetAttackPeriod(GetRandomMinMax(1, 3))
    --inst.components.combat:SetRange(5, 2)
    --inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
    
    

    inst:ListenForEvent("attacked", OnAttacked)
    inst.DoDeath = OnDeath
    inst.DoPreDeath = OnDeathPre
    MakeMediumBurnableCharacter(inst, "fire")
    MakeMediumFreezableCharacter(inst, "fire")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("plantmeat", 1)
    inst.components.lootdropper:AddRandomLoot("rope", 3)
    inst.components.lootdropper:AddRandomLoot("twigs", 6)
    inst.components.lootdropper.numrandomloot = 5
    inst.components.lootdropper.y_offset = 3

    inst.animtype = animtype
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    inst:DoTaskInTime(0,Init)
    
    inst:ListenForEvent("newcombattarget", BeginThrowingOutVines)

    inst.OnEntitySleep = CancelVineTossing

    inst.child_vines = {}
    inst.vineFX = {}
    return inst
end

local function ShuffleToTarget(inst) 
    if inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) > 0.5^2 then
        inst:ForceFacePoint(inst.components.combat.target:GetPosition())
        inst.components.locomotor:RunForward()
    else
        inst.components.locomotor:StopMoving()
    end
end    

local function AssessVine(inst)
    if inst.components.combat and inst.components.combat.target then
        if inst:GetDistanceSqToInst(inst.components.combat.target) < 1 then
            inst.sg:GoToState("attack")
        end
    else
        inst.sg:GoToState("leave_up")
    end
end

local function DoVineAreaAttack(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,inst.components.combat.attackrange,{"_combat","_health"},UMCommonFns.GHOSTLIKE_TAGS)
    for i,v in ipairs(ents) do
        if v:IsValid() and not (v.prefab == inst.prefab or v.prefab == "um_canopeer") then
            v.components.combat:GetAttacked(inst,20)
        end
    end
end

local function SendHealthLossToCanopeer(inst)
    if inst.canopeer and inst.canopeer.components.health and not inst.canopeer.components.health:IsDead() and inst.canopeer.components.combat then
        inst.canopeer.components.combat:GetAttacked(TheWorld,100)
    end
end

local function TellCanopeerToRemoveMe(inst)
    if inst.canopeer then
        RemoveVineChild(inst.canopeer,inst)
    end
end

local function TimeOut(inst)
    inst.sg:GoToState("leave_up")
end

local function fnvine()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    MakeCharacterPhysics(inst, 10, 1)
    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetNoFaced()

    inst.AnimState:SetBank("um_canopeervine")
    inst.AnimState:SetBuild("um_canopeervine")
    inst.AnimState:PlayAnimation("appear_pre",false)

    inst:AddTag("plantcreature")
    inst:AddTag("plantkin")
    inst:AddTag("briar_plants")
    
    MakeFlyingCharacterPhysics(inst, 1, .5)
    RemovePhysicsColliders(inst) -- Should not be able to have contact

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "fire"
    inst.components.combat:SetRange(1.5,1.5) 



    inst:SetStateGraph("SGum_canopeervine")

    MakeSmallBurnableCharacter(inst, "fire")
    MakeSmallFreezableCharacter(inst, "fire")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("rope", 1)
    inst.components.lootdropper:AddRandomLoot("twigs", 3)
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.y_offset = 2
    inst.persists = false

    -- Has to become able to be attacked after attacking itself
    inst:AddTag("INLIMBO") 
    inst.components.health.invincible = true

    inst.ShuffleToTarget = ShuffleToTarget

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = 7 -- Should be very fast

    inst.DoVineAreaAttack = DoVineAreaAttack
    inst.SendHealthLossToCanopeer = SendHealthLossToCanopeer
    inst.decide_to_attack = inst:DoPeriodicTask(4,AssessVine)

    if math.random() > 0.5 then -- flip some canopeers
        inst.AnimState:SetScale(-1,1)
    end
    local scale = math.random(80,120)/100
    inst.Transform:SetScale(scale,scale,scale)

    inst:ListenForEvent("onremove",TellCanopeerToRemoveMe)
    inst:DoTaskInTime(20,TimeOut)


    return inst

end

local fx_list = {"longvine0","longvine1","longvine2","shortvine0","shortvine1"}

local function fnvineFX()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeCharacterPhysics(inst, 10, 1)
    inst.Transform:SetNoFaced()

    inst.AnimState:SetBank("um_hoodedvine")
    inst.AnimState:SetBuild("um_hoodedvine")
    inst.AnimState:PlayAnimation(fx_list[math.random(1,#fx_list)],false)

    inst:AddTag("plantcreature")
    inst:AddTag("plantkin")

    MakeFlyingCharacterPhysics(inst, 1, .5)
    RemovePhysicsColliders(inst) -- Should not be able to have contact

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    if math.random() > 0.5 then -- flip some canopeers
        inst.AnimState:SetScale(-1,1)
    end
    local scale = math.random(80,120)/100
    inst.Transform:SetScale(scale,scale,scale)

    inst.persists = false

    return inst
end

return Prefab("um_canopeer", fn, assets,prefabs),
Prefab("um_canopeervine", fnvine, assets,prefabs),
Prefab("um_canopeervine_fx",fnvineFX,assets,prefabs)