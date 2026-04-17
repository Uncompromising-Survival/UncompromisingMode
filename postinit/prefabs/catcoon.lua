local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
do
    SetSharedLootTable('catty',
        {
            { 'meat',     1.00 },
            { 'coontail', 1.00 },
        })

    local function OnAttackOther(inst, data)
        if data.target:HasTag("raidrat") and not data.target.components.health:IsDead() then
            data.target.components.health:Kill()
        end
    end

    local function OnAttacked(inst, data)
        local attacker = data and data.attacker
        if attacker and attacker.userid and not table.contains(inst.hitlist, attacker.userid) then
            table.insert(inst.hitlist, attacker.userid)
        end
        if inst.um_counterattack then
            inst.um_counterattack = math.max(inst.um_counterattack - 1, 0)
            if inst.um_counterattack == 0 then
                inst.um_counterattack = 3
                inst:PushEvent("um_counterattack", {target = attacker})
            end
        end
    end

    local _RetargetFn
    local function RetargetFn(inst, ...)
        local ret = _RetargetFn and _RetargetFn(inst, ...)
        return FindEntity(inst, TUNING.CATCOON_TARGET_DIST, function(guy)
                for i, v in ipairs(inst.hitlist) do
                    if guy.userid and v == guy.userid then
                        return inst.components.combat:CanTarget(guy)
                    end
                end
            end) or ret
    end

    local _OnSave
    local function OnSave(inst, data, ...)
        if inst.hitlist then data.hitlist = inst.hitlist end
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.hitlist then
            inst.hitlist = data.hitlist
        else
            inst.hitlist = {}
        end
        return _OnLoad and _OnLoad(inst, data, ...)
    end

    env.AddPrefabPostInit("catcoon", function(inst)
        if not TheWorld.ismastersim then return end

        inst.um_counterattack = 3
        inst.hitlist = {}

        if inst.components.health then
            inst.components.health:SetMaxHealth(TUNING.DSTU.MONSTER_CATCOON_HEALTH_CHANGE)
        end

        if inst.components.lootdropper then
            inst.components.lootdropper:SetChanceLootTable('catty')
        end

        inst.components.combat:SetRange(TUNING.CATCOON_ATTACK_RANGE / 1.5) --Lower the range
        inst.components.combat:SetAttackPeriod(TUNING.CATCOON_ATTACK_PERIOD / 1.5) --Make it attack faster to compensate
        _RetargetFn = inst.components.combat.targetfn
        inst.components.combat:SetRetargetFunction(3, RetargetFn)

        inst:ListenForEvent("onattackother", OnAttackOther)
        inst:ListenForEvent("attacked", OnAttacked)

        _OnSave = inst.OnSave
        inst.OnSave = OnSave
        _OnLoad = inst.OnLoad
        inst.OnLoad = OnLoad
    end)
end

do
    local _OnSpawned
    local function OnSpawned(inst, child, ...)
        if inst.hitlist then child.hitlist = inst.hitlist end
        return _OnSpawned and _OnSpawned(inst, child, ...)
    end

    local _OnChildKilled
    local function OnChildKilled(inst, child, ...)
        if inst.lives_left <= 0 and inst.hitlist then
            inst.hitlist = nil
        else
            if child.hitlist then
                inst.hitlist = child.hitlist
            end
        end
        return _OnChildKilled and _OnChildKilled(inst, child, ...)
    end

    local _OnSave
    local function OnSave(inst, data, ...)
        if inst.hitlist then data.hitlist = inst.hitlist end
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.hitlist then inst.hitlist = data.hitlist end
        return _OnLoad and _OnLoad(inst, data, ...)
    end

    env.AddPrefabPostInit("catcoonden", function(inst)
        if not TheWorld.ismastersim then return end

        inst.hitlist = {}
        if TheWorld.totalcatcoondens then
            TheWorld.totalcatcoondens = TheWorld.totalcatcoondens + 1
        else
            TheWorld.totalcatcoondens = 1
        end

        inst.components.childspawner:SetRegenPeriod(2.5 * TUNING.CATCOONDEN_REGEN_TIME) -- Catcoons are now reasonably common, they don't need a super fast regen time
        _OnSpawned = inst.components.childspawner.onspawned
        inst.components.childspawner:SetSpawnedFn(OnSpawned)
        _OnChildKilled = inst.components.childspawner.onchildkilledfn
        inst.components.childspawner:SetOnChildKilledFn(OnChildKilled)

        _OnSave = inst.OnSave
        inst.OnSave = OnSave
        _OnLoad = inst.OnLoad
        inst.OnLoad = OnLoad
    end)
end