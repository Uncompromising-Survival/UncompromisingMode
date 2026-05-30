local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
SetSharedLootTable( 'batty',
{
    {'batwing',    0.15},
    {'guano',      0.15},
    {'monstersmallmeat',0.10},
})

env.AddPrefabPostInit("bat", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SetChanceLootTable('batty')
	end

	local _OnLoad = inst.OnLoad
	local _OnSave = inst.OnSave

	local function OnLoad(inst,data)
		if data then
			if data.um_guano_rain_temporary then
				inst.um_guano_rain_temporary = true
			end
		end
		if _OnLoad then
			_OnLoad(inst,data)
		end
	end

	local function OnSave(inst)
		local data 
		if _OnSave then
			data = _OnSave(inst) 
		else
			data = {}
		end
		data.um_guano_rain_temporary = true
		return data
	end

	inst.OnLoad = OnLoad
	inst.OnSave = OnSave
end)
