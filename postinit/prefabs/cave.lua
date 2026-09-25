local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local easing = require("easing")

local function OnNightmarePhaseChanged(inst, phase)
    if phase == "warn" then
        if inst.trepspawners ~= nil then
            local chooseone = #inst.trepspawners > 1 and math.random(1, #inst.trepspawners) or 1

            for i, v in ipairs(inst.trepspawners) do
                if v ~= nil and i == chooseone then
                    v.components.childspawner:AddChildrenInside(1)
                    v.components.childspawner:StartSpawning()
                end
            end
        end
    end
end

local UM_LAVA_WAVE_DATA = { texture = resolvefilepath("images/um_lava_wave.tex"), shader = resolvefilepath("shaders/waves.ksh"), params = { 13.5, 2.5, -1 }, size = { 80, 3.5 }, motion = { 3, 0.5, 0.25 }, radius = 20 }

local UM_FLOODWATER_WAVE_DATA = { texture = resolvefilepath("images/wave.tex"), shader = resolvefilepath("shaders/waves.ksh"), params = { 13.5, 2.5, -1 }, size = { 80, 3.5 }, motion = { 3, 0.5, 0.25 }, radius = 20 }

env.AddPrefabPostInit("cave", function(inst)
    if not TheNet:IsDedicated() then
        --[[if not inst.WaveComponent then
            inst.entity:AddWaveComponent()
        end
        inst.WaveComponent:SetWaveParams(13.5, 2.5, -1)
        inst.WaveComponent:SetWaveSize(80, 3.5)
        inst.WaveComponent:SetWaveTexture("images/wave_shadow.tex")
        inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")

        inst:AddComponent("um_waveswapper")
        inst.components.um_waveswapper:SetTileWaveData(WORLD_TILES.UM_MAGMA_LAVAMOLTEN, UM_LAVA_WAVE_DATA)
        inst.components.um_waveswapper:SetTileWaveData(WORLD_TILES.UM_FLOODWATER_GROTTO, UM_FLOODWATER_WAVE_DATA)]]

        inst:AddComponent("wavemanager")
    end

    if not TheWorld.ismastersim then
        return
    end

    inst.trepspawners = {}

    if TUNING.DSTU.TREPIDATIONS then
        inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
        OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase, true)
    end

    -- quaker stuff
    inst:DoTaskInTime(0, function()
        if inst.net ~= nil then
            inst.net:ListenForEvent("startquake", function(_inst) -- we still want the old world, not network.
                print("starting quake")
                printwrap("magma outcrops", inst.magma_outcrops)
                local count = 0

                if inst.magma_outcrops ~= nil then
                    for k, v in pairs(inst.magma_outcrops) do
                        if v ~= nil and v.StartGrowing ~= nil and v.components.timer ~= nil and not v.components.timer:TimerExists("grow") then
                            count = count + 1
                            print("starting growing")
                            v:DoTaskInTime(math.random(5, 10), function(inst)
                                print("start growing for real")
                                inst:StartGrowing()
                            end)
                        end
                    end
                    print("total count", count)
                else
                    inst.magma_outcrops = {}
                end

                if inst.components.um_magmamanager ~= nil then
                    if count < 10 then
                        print("spawning more")
                        local valid_tiles = inst.components.um_magmamanager.magma_tiles
                        local tries = 0
                        for i = 1, math.random(1, 3) do
                            print("spawn attempt ", tries)
                            tries = tries + 1
                            if tries > 10 then
                                break
                            end

                            local valid = true
                            local point = valid_tiles[math.random(#valid_tiles)]
                            local x, z = point.x, point.z
                            local pt = FindNearbyLand(Vector3(x, 0, z), 20)
                            local nearby_ents = TheSim:FindEntities(x, 0, z, 1, nil, { "FX", "INLIMBO", "DECOR", "NOCLICK", "NOBLOCK" })
                            local S = TheWorld.Map:IsLandTileAtPoint(pt.x + 2, 0, pt.z)
                            local N = TheWorld.Map:IsLandTileAtPoint(pt.x - 2, 0, pt.z)
                            local E = TheWorld.Map:IsLandTileAtPoint(pt.x, 0, pt.z + 2)
                            local W = TheWorld.Map:IsLandTileAtPoint(pt.x, 0, pt.z - 2)


                            if pt.x == 0 and pt.z == 0 or #nearby_ents > 0 or not (S and N and E and W) then
                                valid = false
                            end


                            if valid then
                                inst:DoTaskInTime(math.random(5, 10), function(inst)
                                    local new_outcrop = SpawnPrefab("um_magmastone_outcrop")
                                    new_outcrop.Transform:SetPosition(pt.x, 0, pt.z)
                                    new_outcrop.AnimState:PlayAnimation("outcrop_grow")
                                    new_outcrop.AnimState:PushAnimation("outcrop_idle", true)
                                end)
                            else
                                -- retry.
                                i = i - 1
                            end
                        end
                    end
                end
            end)
        end
    end)
end)


