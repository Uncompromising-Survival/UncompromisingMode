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
        local health, lootdropper, combat = inst.components.health, inst.components.lootdropper, inst.components.combat

        inst.um_counterattack = 3
        inst.hitlist = {}

        if health then
            health:SetMaxHealth(TUNING.DSTU.MONSTER_CATCOON_HEALTH_CHANGE)
        end

        if lootdropper then
            lootdropper:SetChanceLootTable('catty')
        end

        if combat then
            combat:SetRange(TUNING.CATCOON_ATTACK_RANGE / 1.5) --Lower the range
            combat:SetAttackPeriod(TUNING.CATCOON_ATTACK_PERIOD / 1.5) --Make it attack faster to compensate
            if not _RetargetFn then
                _RetargetFn = combat.targetfn
            end
            combat:SetRetargetFunction(3, RetargetFn)
        end

        inst:ListenForEvent("onattackother", OnAttackOther)
        inst:ListenForEvent("attacked", OnAttacked)

        if not _OnSave then
            _OnSave = inst.OnSave
        end
        inst.OnSave = OnSave
        if not _OnLoad then
            _OnLoad = inst.OnLoad
        end
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
        if not _OnSpawned then
            _OnSpawned = inst.components.childspawner.onspawned
        end
        inst.components.childspawner:SetSpawnedFn(OnSpawned)
        if not _OnChildKilled then
            _OnChildKilled = inst.components.childspawner.onchildkilledfn
        end
        inst.components.childspawner:SetOnChildKilledFn(OnChildKilled)

        if not _OnSave then
            _OnSave = inst.OnSave
        end
        inst.OnSave = OnSave
        if not _OnLoad then
            _OnLoad = inst.OnLoad
        end
        inst.OnLoad = OnLoad
    end)
end