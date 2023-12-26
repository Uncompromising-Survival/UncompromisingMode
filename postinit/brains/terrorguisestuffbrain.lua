local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local panzies = {
	"spiderbrain",
	"pigbrain",
	"rabbitbrain",
	"frogbrain",
	"batbrain",
	"beebrain",
	"butterflybrain",
	"babybeefalobrain",
	"beefalobrain",
	"beardbunnymanbrain",
	"chesterbrain",
	"birchnutdrakebrain",
	"bird_mutant_brain",
	"bishopbrain",
	"knightbrain",
	"rookbrain",
	"catcoonbrain",
	"carratbrain",
	"centipedebrain",
	"crabkingclawbrain",
	"cookiecutterbrain",
	"deerbrain",
	"eyeofterror_minibrain",
	"friendlyfruitflybrain",
	"fruitdragonbrain",
	"fruitflybrain",
	"gnarwailbrain",
	"grassgatorbrain",
	"grassgekkobrain",
	"hermitcrabbrain",
	"houndbrain",
	"killerbeebrain",
	"koalefantbrain",
	"krampusbrain",
	"lavaebrain",
	"lightcrabbrain",
	"lightflierbrain",
	"lightninggoatbrain",
	"mandrakebrain",
	"mermbrain",
	"mermguardbrain",
	"molebatbrain",
	"molebrain",
	"monkeybrain",
	--"moonbeastbrain",
	"moonbutterflybrain",
	"mosquitobrain",
	"mosslingbrain",
	"mushgnomebrain",
	"oceanfishbrain",
	"penguinbrain",
	"perdbrain",
	"pigelitebrain",
	"pigguardbrain",
	"powdermonkeybrain",
	"primematebrain",
	"rabbitbrain",
	"rockybrain",
	"sharkbrain",
	"slurperbrain",
	"slurtlebrain",
	"slurtlesnailbrain",
	"smallbirdbrain",
	"spatbrain",
	"spider_waterbrain",
	"sporebrain", --It's scaring the spores!
	-- "squidbrain", --Squids aren't scared of squids
	--"stagehandbrain",
	"tallbirdbrain",
	"ticoonbrain",
	"walrusbrain",
	"werepigbrain",
	"wobsterbrain",
	"wobsterlandbrain",
	"wormbrain",
	"wx78_scannerbrain",


}

local RUN_AWAY_PARAMS =
{
    tags = { "_combat", "_health","reallyfrickinscary"},
    notags = { "EPIC" },
}
local function Attacking(inst)
	return inst.sg:HasStateTag("attack")
end

local function Taunting(inst)
	return inst.sg:HasStateTag("taunting")
end

local function BecomeTerrified(self)
	require "behaviours/runaway"
    local runaway = WhileNode(function() return not Attacking(self.inst) and not Taunting(self.inst) end, "AmIBusyAttacking", RunAway(self.inst, RUN_AWAY_PARAMS, 8, 12))
    table.insert(self.bt.root.children, 1, runaway)
end

for i,v in ipairs(panzies) do
	env.AddBrainPostInit(v, BecomeTerrified)
end