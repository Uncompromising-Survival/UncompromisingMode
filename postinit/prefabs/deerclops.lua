local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function AuraFreezeEnemies(inst)
    if inst.components.combat.target and not (inst.components.health and inst.components.health:IsDead()) then
        if inst:GetDistanceSqToPoint(inst.components.combat.target:GetPosition()) < 4 then
            inst:PushEvent("start_aurafreeze")
        else
            inst.components.combat:SetRange(TUNING.DEERCLOPS_ATTACK_RANGE * 0.6)
        end
    else
        inst.components.timer:StartTimer("auratime", 15)
    end
end

local function IceyCheck(inst, data)
    if data and data.name == "auratime" and inst.upgrade == "ice_mutation" then
        AuraFreezeEnemies(inst)
    end
end

local function OnNewState(inst, data)
    if not (inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("waking")) then
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(8)
        inst.Light:SetFalloff(3)
        inst.Light:SetColour(0, 0, 1)
        --inst.Light:Enable(true)
    end
end

local function MakeEnrageable(inst)
    inst.upgrade = "enrage_mutation"
    if not inst.components.timer then
        inst:AddComponent("timer")
    end
    if not inst.components.timer:TimerExists("laserbeam_cd") then
        inst.components.timer:StartTimer("laserbeam_cd", TUNING.DEERCLOPS_ATTACK_PERIOD * (math.random(3) - .5))
    end

    inst.Transform:SetScale(1.85, 1.85, 1.85)
    inst.components.combat:SetAttackPeriod(TUNING.DEERCLOPS_ATTACK_PERIOD * 0.9)

    inst.AnimState:SetBuild("deerclops_yule_blue")

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(8)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(0, 0, 1)
    inst.Light:Enable(true)

    inst:ListenForEvent("newstate", OnNewState)
end

local function DisableYule(inst)
    inst.haslaserbeam = false
    inst.AnimState:SetBuild("deerclops_build") -- Override Winter's Feast.
    inst.Light:Enable(false)
end

local function MakeStrong(inst)
    DisableYule(inst)
    inst.upgrade = "strength_mutation"
    inst:DoTaskInTime(0.1, function(inst)
        if not inst.components.timer then
            inst:AddComponent("timer")
        end
    end)
end

local function MakeIcey(inst)
    DisableYule(inst)
    inst.upgrade = "ice_mutation"
    if inst.components.freezable then
        inst:RemoveComponent("freezable")
    end
    inst:DoTaskInTime(0.1, function(inst)
        if not inst.components.timer then
            inst:AddComponent("timer")
        end
        if not inst.components.timer:TimerExists("auratime") then
            inst.components.timer:StartTimer("auratime", 15)
        end
    end)
    inst:ListenForEvent("timerdone", IceyCheck)
end


local function ChooseUpgrades(inst)
    if not inst.upgrade then
        local chance = math.random()
        if chance < 0.33 then
            MakeEnrageable(inst)
        end
        if chance >= 0.33 and chance <= 0.66 then
            MakeStrong(inst)
        end
        if chance > 0.66 then
            MakeIcey(inst)
        end
    else
        if inst.upgrade == "enrage_mutation" then
            MakeEnrageable(inst)
        end
        if inst.upgrade == "strength_mutation" then
            MakeStrong(inst)
        end
        if inst.upgrade == "ice_mutation" then
            MakeIcey(inst)
        end
    end
end

local function oncollapse(inst, other)
    if other:IsValid() and other.components.workable and other.components.workable:CanBeWorked() then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
    end
end

local function oncollide(inst, other)
    if other and other:HasAnyTag("tree", "boulder") and not other:HasTag("giant_tree") and --HasTag implies IsValid
        Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 then
        inst:DoTaskInTime(2 * FRAMES, oncollapse, other)
    end
end

local function DeerclopsClientFunctions(inst)
    if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        inst.entity:AddLight()
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(8)
        inst.Light:SetFalloff(3)
        inst.Light:SetColour(0, 0, 1)
        inst.Light:Enable(false)
    end
end

local function DeerclopsFunctions(inst)
    local _OnHitOther = UpvalueHacker.GetUpvalue(Prefabs.deerclops.fn, "OnHitOther")
    local function OnHitOther(inst, data)
        if inst.sg:HasStateTag("heavyhit") then
            local other = data.target
            if other then
                if not (other.components.health and other.components.health:IsDead()) then
                    if other and other.components.inventory and not other:HasTag("fat_gang") and not other:HasTag("foodknockbackimmune") and not (other.components.rider and other.components.rider:IsRiding()) and
                    --Don't knockback if you wear marble
                    (not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("marble") and not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("knockback_protection")) then
                        other:PushEvent("knockback", {knocker = inst, radius = 150, strengthmult = 1.2})
                    end
                end
            end
        else
            if not inst.sg:HasStateTag("noice") then
                _OnHitOther(inst, data)
            end
        end
    end

    if _OnHitOther then
        inst:RemoveEventCallback("onhitother", _OnHitOther)
        inst:ListenForEvent("onhitother", OnHitOther)
    end

    inst.Physics:SetCollisionCallback(oncollide)

    local _OnSave = inst.OnSave
    local _OnLoad = inst.OnLoad

    local function OnSave(inst, data)
        data.upgrade = inst.upgrade
        if inst.components.health then
            data.healthUM = inst.components.health.currenthealth
        end
        return _OnSave(inst, data)
    end

    local function OnLoad(inst, data)
        if data then
            if not data.upgrade then
                ChooseUpgrades(inst)
            else
                if data.upgrade == "enrage_mutation" then
                    MakeEnrageable(inst)
                end
                if data.upgrade == "strength_mutation" then
                    MakeStrong(inst)
                end
                if data.upgrade == "ice_mutation" then
                    MakeIcey(inst)
                end
            end
            if data.healthUM then
                inst.components.health.currenthealth = data.healthUM
            end
        end
        return _OnLoad(inst, data)
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    if inst.components.freezable then
        inst:RemoveComponent("freezable")
    end

    inst.count = 0

    local groundpounder = inst:AddComponent("groundpounder")
    groundpounder.destroyer = true
    groundpounder.damageRings = 2
    groundpounder.destructionRings = 2
    groundpounder.platformPushingRings = 2
    groundpounder.numRings = 3
    inst:AddTag("deergemresistance")

    inst.MakeEnrageable = MakeEnrageable
    inst.MakeIcey = MakeIcey
    inst.MakeStrong = MakeStrong

    inst:DoTaskInTime(0.1, ChooseUpgrades) --Incase we need to specify an upgrade because this deerclops despawned.
end

env.AddPrefabPostInit("deerclops", function(inst)
    DeerclopsClientFunctions(inst)

    if not TheWorld.ismastersim then
        return
    end

    DeerclopsFunctions(inst)
end)