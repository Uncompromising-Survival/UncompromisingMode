local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local mermhouses = {
    "mermhouse",
    "mermhouse_crafted"
}

local function StartSpawning_Winter(inst)
    if TheWorld.state.iswinter and inst.components.childspawner and not inst.components.childspawner.spawning and not inst:HasTag("burnt") then
        inst.components.childspawner:StartSpawning()
    end
end

local function StopSpawning(inst)
    if inst.components.childspawner and not inst:HasTag("burnt") then
        inst.components.childspawner:StopSpawning()
    end
end

local function OnIsDay_Winter(inst, isday)
    if isday then
        StopSpawning(inst)
    elseif not inst:HasTag("burnt") then
        if TheWorld.state.iswinter then
            inst.components.childspawner:ReleaseAllChildren()
        end
        StartSpawning_Winter(inst)
    end
end

local function ToggleWinterTuning_UM(inst, iswinter)
    if not inst.components.childspawner then return end

    inst.components.childspawner:SetRegenPeriod(inst.um_base_regen_time * (iswinter and 2 or 1))
end

for i, v in ipairs(mermhouses) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        --[[if inst.components.childspawner ~= nil then
			local _OldOnGoHome = inst.components.childspawner.ongohome
		
			inst.components.childspawner:SetGoHomeFn(function(inst, child)
				_OldOnGoHome(inst, child)
				
				if TheWorld.state.iswinter then
					StartSpawning_Winter(inst, child)
				end
			end)
		end]]

        inst.um_base_regen_time = v == "mermhouse_crafted" and TUNING.MERMHOUSE_REGEN_TIME / 2 or TUNING.MERMHOUSE_REGEN_TIME

        inst:WatchWorldState("isday", OnIsDay_Winter)

        StartSpawning_Winter(inst)

        inst:WatchWorldState("iswinter", ToggleWinterTuning_UM)
        ToggleWinterTuning_UM(inst, TheWorld.state.iswinter)
    end)
end

env.AddPrefabPostInit("mermwatchtower", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.um_base_regen_time = TUNING.MERMWATCHTOWER_REGEN_TIME * 8

    inst:WatchWorldState("iswinter", ToggleWinterTuning_UM)
    ToggleWinterTuning_UM(inst, TheWorld.state.iswinter)
end)