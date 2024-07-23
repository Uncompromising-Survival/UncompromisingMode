--[[
	THANK YOU ADM!!!
--]]

local HF_AMBIENT_SOUND =
{
	[WORLD_TILES.HOODEDFOREST] = {sound = "dontstarve/AMB/meadow", wintersound = "dontstarve/AMB/meadow_winter", springsound = "dontstarve/AMB/meadow", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},--springsound = "dontstarve_DLC001/spring/springmeadowAMB", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},
	--[WORLD_TILES.ANCIENTHOODEDFOREST] = {sound = "dontstarve/AMB/meadow", wintersound = "dontstarve/AMB/meadow_winter", springsound = "dontstarve/AMB/meadow", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},--springsound = "dontstarve_DLC001/spring/springmeadowAMB", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},
    --[WORLD_TILES.UM_FLOODWATER] = {sound = "dontstarve/AMB/caves/void", wintersound = "dontstarve/AMB/caves/void", springsound = "dontstarve/AMB/caves/void", summersound = "dontstarve/AMB/caves/void", rainsound = "dontstarve/AMB/caves/void"},
	--[WORLD_TILES.BOILINGFIELDS] = {sound = "dontstarve/AMB/meadow", wintersound = "dontstarve/AMB/meadow_winter", springsound = "dontstarve/AMB/meadow", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},--springsound = "dontstarve_DLC001/spring/springmeadowAMB", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},
	--[WORLD_TILES.CRACKEDBASALT] = {sound = "dontstarve/AMB/meadow", wintersound = "dontstarve/AMB/meadow_winter", springsound = "dontstarve/AMB/meadow", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},--springsound = "dontstarve_DLC001/spring/springmeadowAMB", summersound = "dontstarve_DLC001/AMB/meadow_summer", rainsound = "dontstarve/AMB/meadow_rain"},
	--[WORLD_TILES.UM_MAGMA] = {sound = "dontstarve/AMB/caves/void", wintersound = "dontstarve/AMB/caves/void", springsound = "dontstarve/AMB/caves/void", summersound = "dontstarve/AMB/caves/void", rainsound = "dontstarve/AMB/caves/void"},
	--[WORLD_TILES.UM_GRASSMAGMA] = {sound = "dontstarve/AMB/caves/void", wintersound = "dontstarve/AMB/caves/void", springsound = "dontstarve/AMB/caves/void", summersound = "dontstarve/AMB/caves/void", rainsound = "dontstarve/AMB/caves/void"},
	--[WORLD_TILES.UM_FLOORTOX] = {sound = "dontstarve/AMB/caves/void", wintersound = "dontstarve/AMB/caves/void", springsound = "dontstarve/AMB/caves/void", summersound = "dontstarve/AMB/caves/void", rainsound = "dontstarve/AMB/caves/void"},
}

local function SoundUpvalue(fn, upvalue_name)
	i = 1
	while true do
	local val, v = GLOBAL.debug.getupvalue(fn, i)
	if not val then break end
		if val == upvalue_name then 
			return v, i
		end
		i = i + 1
	end
end

AddComponentPostInit("ambientsound", function(self)

	local AMBIENT_SOUNDS, SOUND = SoundUpvalue(self.OnUpdate, "AMBIENT_SOUNDS")
	if SOUND then
		for k, v in pairs(HF_AMBIENT_SOUND) do
			AMBIENT_SOUNDS[k] = HF_AMBIENT_SOUND[k]
		end
	end
	
end)