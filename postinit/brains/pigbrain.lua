local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local PigBrain = require("brains/pigbrain")
--PIGS SHOULDNT BE EATING BUGS OUT OF THE SKY--

local FINDFOOD_CANT_TAGS = {"insect", "flying"}

local _FINDFOOD_CANT_TAGS = UpvalueHacker.GetUpvalue(self.OnStart, "FindFoodAction", "FINDFOOD_CANT_TAGS")

for i, TAG in pairs(FINDFOOD_CANT_TAGS) do
    table.insert(_FINDFOOD_CANT_TAGS, TAG)
end