local wes_must_live_tag = {"player", "companion", "shadowminion", "shadowcreature", "brightmare", "mosquito", "buzzard", "abigail"}
local wes_must_live_prefab = {
    shadowtentacle = true,
}

AddPrefabPostInitAny(function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

    if inst:HasAnyTag(wes_must_live_tag) or wes_must_live_prefab[inst.prefab] then
        return inst
    end

    if inst.components and inst.components.combat then
        local damage = inst.components.combat.defaultdamage and inst.components.combat.defaultdamage > 0
        local target = inst.components.combat.targetfn
        if damage or target then
            inst:AddTag("wesmustdie")
        end
    end
end)

local they_must_die = {"player", "companion", "structure", "wall"}

local function IgnoreMe(entity, taglist)
    return entity:HasAnyTag(taglist)
end

local they_love_me = {"tentacle", "tentacle_pillar_arm", "eyeplant", "bigshadowtentacle"}

local midrange_list = {"catcoon"}

local hate = 16
local love = 4
local midrange = 12

local function HatefulBounty(inst, target)
    if target.prefab and not table.contains(they_love_me, target.prefab) and not table.contains(midrange_list, target.prefab) then
        target.components.combat:SetTarget(inst)
    end
end

local function LovableBounty(inst, target)
    if target.prefab and table.contains(they_love_me, target.prefab) then
        target.components.combat:SetTarget(inst)
    end
end

local function MidrangeBounty(inst, target)
    if target.prefab and table.contains(midrange_list, target.prefab) then
        target.components.combat:SetTarget(inst)
    end
end

local function BountyOnYourHead(inst, range, BountyFn)
    if not inst or not inst.Transform or not inst:HasTag("vetcurse") then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, range, {"wesmustdie"}, {"player", "INLIMBO"})
    for i, target in ipairs(targets) do
        if target and target.components.combat and target.components.combat:CanTarget(inst) then
            local target_is_a_follower = false
            local leader = nil

            if target.components.follower then
                leader = target.components.follower.leader
            end

            if leader and leader:HasAnyTag("player", "bell") then
                target_is_a_follower = true
            end

            local what_my_target_is_targeting = target.components.combat.target
            local they_die_not_me = what_my_target_is_targeting and IgnoreMe(what_my_target_is_targeting, they_must_die)

            local my_target_is_targeting_followers = false
            if what_my_target_is_targeting and what_my_target_is_targeting.components.follower then
                local him = what_my_target_is_targeting.components.follower.leader
                if him and him:HasAnyTag("player", "bell") then
                    my_target_is_targeting_followers = true
                end
            end

            if not they_die_not_me and not my_target_is_targeting_followers and not target_is_a_follower then
                BountyFn(inst, target)
            end
        end
    end
end

AddPrefabPostInit("wes", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:AddTag("the_mime")
    inst:DoPeriodicTask(0, BountyOnYourHead, nil, hate, HatefulBounty)
    inst:DoPeriodicTask(0, BountyOnYourHead, nil, love, LovableBounty)
    inst:DoPeriodicTask(0, BountyOnYourHead, nil, midrange, MidrangeBounty)
end)

for _, bat in pairs({"bat", "vampirebat"}) do
    AddPrefabPostInit(bat, function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return inst
        end

        local _keeptargetfn = inst.components.combat.keeptargetfn
        local function KeepTarget(inst, target)
            if target:HasTag("the_mime") then
                return true
            end
            return _keeptargetfn(inst, target)
        end

        inst.components.combat:SetKeepTargetFunction(KeepTarget)

        local _targetfn = inst.components.combat.targetfn
        local function Retarget(inst)
            if inst.components.combat and inst.components.combat.target and not inst.components.combat.target:HasTag("the_mime") then
                return
            end
            return _targetfn(inst)
        end

        inst.components.combat:SetRetargetFunction(3, Retarget)
    end)
end