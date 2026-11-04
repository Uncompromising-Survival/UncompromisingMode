local assets =
{
    Asset("MINIMAP_IMAGE", "whitespider_den"),
}

local prefabs =
{
    "spider_dropper",
}

local function TrySpawnCocoon(x, z, tries)
    local xi = x + math.random(-8, 8)
    local zi = z + math.random(-8, 8)
    tries = tries - 1
    if #TheSim:FindEntities(xi, 0, zi, 1.5, {"webbedcreature"}) == 0 and
        #TheSim:FindEntities(xi, 0, zi, 3, {"webbedcreature"}) < 2 and
        #TheSim:FindEntities(xi, 0, zi, 8, {"webbedcreature"}) < 6 then
        local cocoon = SpawnPrefab("webbedcreature")
        cocoon.Transform:SetPosition(xi, 0, zi)
    elseif tries > 0 then
        TrySpawnCocoon(x, z, tries)
    end
end

local blacklisted_coocoons = { "krampus", "walrus", "grassgator" }
local function RerollCocoons(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local existing_cocoons = TheSim:FindEntities(x, y, z, 30, {"webbedcreature"})
    local widowweb = TheSim:FindFirstEntityWithTag("widowweb")

    if widowweb then
        for k, v in ipairs(existing_cocoons) do
            if table.contains(blacklisted_coocoons, v.cocoon_creature) --[[or table.contains(UMWebbedCreatureUtil.COCOON_CHARACTERS, v.cocoon_creature)]] then
            else
                v:Remove()
                TrySpawnCocoon(x, z, 5)
            end
        end
    end
end

local function OnKilled(inst)
    inst.components.timer:StartTimer("regen_widow", TUNING.DRAGONFLY_RESPAWN_TIME)
    if inst.components.timer:TimerExists("reroll_cocoons") then
        inst.components.timer:StopTimer("reroll_cocoons")
    end
end

local function OnGoHome(inst)
    if inst.components.timer:TimerExists("reroll_cocoons") then
        inst.components.timer:ResumeTimer("reroll_cocoons")
    else
        inst.components.timer:StartTimer("reroll_cocoons", TUNING.TOTAL_DAY_TIME * 5)
    end
end

local function GenerateNewWidow(inst)
    inst.components.childspawner:AddChildrenInside(1)
    --inst.components.childspawner:StartSpawning()
    if not inst.components.timer:TimerExists("reroll_cocoons") then
        inst.components.timer:StartTimer("reroll_cocoons", TUNING.TOTAL_DAY_TIME * 5)
    end
end

local function ontimerdone(inst, data)
    if data.name == "regen_widow" then
        GenerateNewWidow(inst)
    end
    if data.name == "reroll_cocoons" then
        RerollCocoons(inst)
        if not inst.components.timer:TimerExists("reroll_cocoons") then
            inst.components.timer:StartTimer("reroll_cocoons", TUNING.TOTAL_DAY_TIME * 5)
        end
    end
end

local function SpawnInvestigators(inst, target)
    local childspawner = target and inst.components.childspawner
    local spider = childspawner and childspawner:SpawnChild()
    if spider then
        if inst.components.timer:TimerExists("reroll_cocoons") then
            inst.components.timer:PauseTimer("reroll_cocoons")
        end
        spider.sg:GoToState("fall")
        spider.components.combat:SuggestTarget(target)
        local x, y, z = inst.Transform:GetWorldPosition()
        for i = 1, 4 do
            SpawnPrefab("oceantree_leaf_fx_fall").Transform:SetPosition(x + math.random(-8, 8), 0, z + math.random(-8, 8))
        end
    end
end

local function OnLoad(inst, data)
    local timer = inst.components.timer
    if not timer:TimerExists("regen_widow") and not timer:TimerExists("reroll_cocoons") then
        timer:StartTimer("reroll_cocoons", TUNING.TOTAL_DAY_TIME * 5)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("widowweb")

    inst.scrapbook_inspectonseen = true
    inst.scrapbook_proxy = "webbedcreature"

    if not TheNet:IsDedicated() then
        inst:AddComponent("pointofinterest")
        inst.components.pointofinterest:SetHeight(0)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SpawnInvestigators = SpawnInvestigators

    local childspawner = inst:AddComponent("childspawner")
    childspawner.childname = "hoodedwidow"
    childspawner:SetMaxChildren(1)
    childspawner:SetSpawnPeriod(TUNING.DRAGONFLY_SPAWN_TIME, 0)
    childspawner:SetOnChildKilledFn(OnKilled)
    childspawner:SetGoHomeFn(OnGoHome)
    childspawner:StopRegen()

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.OnLoad = OnLoad

    return inst
end

return Prefab("widowweb", fn, assets, prefabs)
