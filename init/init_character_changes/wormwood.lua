local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function propegation(inst)
    if inst.components.burnable and not inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
        MakeSmallPropagator(inst)
    else
        inst:DoTaskInTime(5, propegation)
    end
end

local function DefaultIgniteFn(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:StartWildfire()
    end

    --propegation(inst)
end

local WATCH_WORLD_PLANTS_DIST_SQ = 20 * 20
local SANITY_DRAIN_TIME = 5

local function DoKillPlantPenalty(inst, penalty, overtime)
    if overtime then
        table.insert(inst.plantpenalties, { amt = -penalty / SANITY_DRAIN_TIME, t = SANITY_DRAIN_TIME })
    else
        while #inst.plantbonuses > 0 do
            table.remove(inst.plantbonuses)
        end
        inst.components.sanity:DoDelta(-penalty)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_KILLEDPLANT"))
    end
end

local function WatchWorldPlants2(inst)
    if inst._onplantkilled2 == nil then
        inst._onplantkilled2 = function(src, data)
            if data == nil then
                --shouldn't happen
            elseif data.doer == inst then
                DoKillPlantPenalty(inst, data.workaction ~= nil and data.workaction == ACTIONS.DIG and TUNING.SANITY_TINY or 0)
            end
        end
        inst:ListenForEvent("plantkilled", inst._onplantkilled2, TheWorld)
    end
end

local function StopWatchingWorldPlants2(inst)
    if inst._onplantkilled2 ~= nil then
        inst:RemoveEventCallback("plantkilled", inst._onplantkilled2, TheWorld)
        inst._onplantkilled2 = nil
    end
end

local function OnRespawnedFromGhost2(inst)
    WatchWorldPlants2(inst)

    --MakeMediumBurnableCharacter(inst, "torso")
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.burnable:Extinguish()
            MakeSmallPropagator(inst)
        end
    end)
end

local function OnBecameGhost2(inst)
    StopWatchingWorldPlants2(inst)
end

local function OnBurnt(inst)
    --Overriding the OnBurnt function to prevent propegator from sometimes removing, hopefully.
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.burnable:Extinguish()
            MakeSmallPropagator(inst)
        end
    end)
end

local function OnMoistureDelta(inst)
    --Overriding the OnBurnt function to prevent propegator from sometimes removing, hopefully.
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() and inst.components.moisture and
            inst.components.moisture:GetMoisturePercent() >= 0.4 then
            if inst.components.propegator ~= nil then
                inst.components.propagator.acceptsheat = false
            end
        elseif inst.components.health and not inst.components.health:IsDead() then
            if inst.components.propegator ~= nil then
                inst.components.propagator.acceptsheat = true
            end
        end
    end)
end

env.AddPrefabPostInit("wormwood", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onlevelchangedfn = inst.components.bloomness.onlevelchangedfn

    local function UpdateBloomStage(inst, stage)
        local ret = _onlevelchangedfn(inst, stage)
        inst:RemoveTag("beebeacon")
        inst.beebeacon = nil
        return ret
    end

    inst.UpdateBloomStage = UpdateBloomStage
    inst.components.bloomness.onlevelchangedfn = UpdateBloomStage
    inst:RemoveTag("beebeacon")
    inst.beebeacon = nil

    inst:AddTag("hayfever_immune")
end)

if TUNING.DSTU.WORMWOOD_CONFIG_PLANTS then
    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        WatchWorldPlants2(inst)
        inst:ListenForEvent("ms_becameghost", OnBecameGhost2)
    end)
end

if TUNING.DSTU.WORMWOOD_CONFIG_FIRE then
    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end

        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnBurntFn(OnBurnt)
        inst:ListenForEvent("moisturedelta", OnMoistureDelta)
        inst:ListenForEvent("ms_respawnedfromghost", OnRespawnedFromGhost2)
    end)
end

local function TrapsAOE(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y, z, TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE, { "trap" })) do
        if v ~= nil and v.prefab == "trap_bramble" and v.components.mine ~= nil and v.components.mine.issprung then
            v.components.mine:Reset()
        end
    end
end

local function UpdateBloomStageUM(inst, stage) --Checks the bloom stage in a friendly way, no overriding
    --The setters will all check for dirty values, since refreshing bloom
    --stage can potentially get triggered quite often with state changes.
    inst:DoTaskInTime(0, function(inst) --Checking for blooming is hard, so we'll just check for pollentask instead XD
        if inst.pollentask --[[and inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wormwood_bugs")]] then
            inst.traptask = inst:DoPeriodicTask(.5, TrapsAOE)
        elseif inst.traptask then
            inst.traptask:Cancel()
            inst.traptask = nil
        end
    end)
end

if TUNING.DSTU.WORMWOOD_CONFIG_TRAPS then
    env.AddPrefabPostInit("bramblefx_trap", function(inst)
        inst.canhitplayers = false
    end)

    env.AddPrefabPostInit("bramblefx_armor", function(inst)
        inst.canhitplayers = false
    end)

    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        --[[local _UpdateBloomStage = inst.components.bloomness.onlevelchangedfn
        local function NewUpdateBloomStage(inst, stage)
            _UpdateBloomStage(inst, stage)
            UpdateBloomStageUM(inst, stage)
        end
        inst.components.bloomness.onlevelchangedfn = NewUpdateBloomStage]]
    end)
end


if env.GetModConfigData("wormwood_photosynthesis") then

	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Final Built Skilltree ] ---------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------
	
	env.modimport("init/init_character_changes/skilltree_wormwood") -- Import New Wortox Tree

    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end

        inst.UpdatePhotosynthesisState = function(inst, isday)
            --nuhuh
        end

        local _CalcBloomRateFn = inst.components.bloomness.calcratefn

        inst.components.bloomness.calcratefn = function(inst, level, is_blooming, fertilizer)
            if inst.components.skilltreeupdater ~= nil and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis") then
                local season_mult = 1
                if TheWorld.state.season == "summer" or TheWorld.state.season == "spring" then
                    if is_blooming then
                        season_mult = TUNING.WORMWOOD_SPRING_BLOOM_MOD
                    else
                        return TUNING.WORMWOOD_SPRING_BLOOMDRAIN_RATE
                    end
                end
                local rate = (is_blooming and fertilizer > 0) and (season_mult * (1 + fertilizer * TUNING.WORMWOOD_FERTILIZER_RATE_MOD)) or 1
                return rate
            end

            return _CalcBloomRateFn(inst, level, is_blooming, fertilizer)
        end
        -----------------------------------
        local function skilltreemovespeed(inst)
            local stage = inst.components.bloomness:GetLevel()
            local skilltreeupdater = inst.components.skilltreeupdater

            if stage >= 3 and inst._movetreebonus ~= true and ((skilltreeupdater:IsActivated("wormwood_blooming_speed2") and inst.components.health:GetPercent() >= 0.8) or (skilltreeupdater:IsActivated("wormwood_blooming_speed1") and inst.components.health:GetPercent() >= 0.9)) then
                inst._movetreebonus = true
                inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.3
            elseif inst._movetreebonus == true then
                inst._movetreebonus = false
                inst.components.locomotor.runspeed = inst.components.locomotor.runspeed - 0.3
            end
        end

        local function OnHealthDeltaCurse(data)
            local debuffable = inst.components.debuffable
            if inst:HasTag("vetcurse_wormwood") and debuffable and data.amount < 0 then
                local debuffs = debuffable.debuffs
                for i, v in pairs(debuffs) do
                    if string.sub(i, 1, 24) == "healthregenbuff_vetcurse" or i == "confighealbuff" or i == "compostheal_buff" or i == "tillweedsalve_buff" then
                        debuffable:RemoveDebuff(i)
                    end
                end
            end
        end

        local _UpdateBloomStage = inst.components.bloomness.onlevelchangedfn

        inst.components.bloomness.onlevelchangedfn = function(inst, stage) --in case you enter the 3rd stage with enough hp required or you go back to 2nd
            _UpdateBloomStage(inst, stage)
            --print("guh") --no guh
            skilltreemovespeed(inst)
        end

        inst.UpdateBloomStage = inst.components.bloomness.onlevelchangedfn --not sure if this is needed but Wormwood also uses UpdateBloomStage for this too so might as well update this

        inst:ListenForEvent("healthdelta", function(inst, data)
            skilltreemovespeed(inst)
            OnHealthDeltaCurse(data)
        end)
		
		

		local function OnFertilizedWithCompost(inst, value)
			if value > 0 and inst.components.health and not inst.components.health:IsDead() then
				local healing = TUNING.WORMWOOD_COMPOST_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_COMPOST_HEAL_VALUES[1]
				if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
					healing = healing * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
				end
				
				inst:AddDebuff("compostheal_buff", "compostheal_buff", {duration = healing * (TUNING.WORMWOOD_COMPOST_HEALOVERTIME_TICK/TUNING.WORMWOOD_COMPOST_HEALOVERTIME_HEALTH)})
			end
		end
		inst.OnFertilizedWithCompost = OnFertilizedWithCompost
		
		local function OnFertilizedWithManure(inst, value, src)
			if value > 0 and inst.components.bloomness then
				local healing = TUNING.WORMWOOD_MANURE_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_MANURE_HEAL_VALUES[1]
				if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
					healing = healing * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
				end				
				inst.components.health:DoDelta(healing, false, src.prefab)
			end
		end
		inst.OnFertilizedWithManure = OnFertilizedWithManure
		
    end)
end
