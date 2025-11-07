local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local easing = require("easing")

local function OnNightmarePhaseChanged(inst, phase)
    if phase == "warn" then
        if inst.trepspawners ~= nil then
            local chooseone = #inst.trepspawners > 1 and math.random(1, #inst.trepspawners)
                or 1

            for i, v in ipairs(inst.trepspawners) do
                if v ~= nil and i == chooseone then
                    v.components.childspawner:AddChildrenInside(1)
                    v.components.childspawner:StartSpawning()
                end
            end
        end
    end
end

local UM_LAVA_WAVE_DATA = {
    texture = resolvefilepath("images/um_lava_wave.tex"),
    shader = resolvefilepath("shaders/waves.ksh"),
    params = {13.5, 2.5, -1},
    size = {80, 3.5},
    motion = {3, 0.5, 0.25},
    radius = 20,
}

local UM_FLOODWATER_WAVE_DATA = {
    texture = resolvefilepath("images/wave.tex"),
    shader = resolvefilepath("shaders/waves.ksh"),
    params = {13.5, 2.5, -1},
    size = {80, 3.5},
    motion = {3, 0.5, 0.25},
    radius = 20,
}

env.AddPrefabPostInit("cave", function(inst)

    if not TheNet:IsDedicated() then
        if not inst.WaveComponent then
            inst.entity:AddWaveComponent()
        end
        inst.WaveComponent:SetWaveParams(13.5, 2.5, -1)
        inst.WaveComponent:SetWaveSize(80, 3.5)
        inst.WaveComponent:SetWaveTexture("images/wave_shadow.tex")
        inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")
        
        inst:AddComponent("um_waveswapper")
        inst.components.um_waveswapper:SetTileWaveData(WORLD_TILES.UM_MAGMA_LAVAMOLTEN, UM_LAVA_WAVE_DATA)
        inst.components.um_waveswapper:SetTileWaveData(WORLD_TILES.UM_FLOODWATER, UM_FLOODWATER_WAVE_DATA)
    end

    if not TheWorld.ismastersim then
        return
    end

    inst.trepspawners = {}

    if TUNING.DSTU.TREPIDATIONS then
        inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
        OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase, true)
    end
end)
