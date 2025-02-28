local env = env
GLOBAL.setfenv(1, GLOBAL)

local noskill =
{
	"slingshotammo_scrapfeather",
	"slingshotammo_stinger",
	"slingshotammo_gelblob",
	"slingshotammo_horrorfuel",
	"slingshotammo_purebrilliance",
	"slingshotammo_lunarplanthusk",
	"slingshotammo_gunpowder",
	"slingshotammo_gunpowder",
	"slingshotammo_dreadstone",
}

for i, v in ipairs(noskill) do
	env.AddPrefabPostInit(v, function(inst)
		inst.REQUIRED_SKILL = nil
		
		if not TheWorld.ismastersim then
			return
		end
	end)
end