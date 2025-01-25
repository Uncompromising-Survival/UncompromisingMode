local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
--PIGS SHOULDNT BE EATING BUGS OUT OF THE SKY--

AddClassPostConstruct("brains/pigbrain", function(self)
    local FINDFOOD_CANT_TAGS = UpvalueHacker.GetUpvalue(self.OnStart, "FindFoodAction", "FINDFOOD_CANT_TAGS")
    if FINDFOOD_CANT_TAGS then
		table.insert(FINDFOOD_CANT_TAGS, "insect")
		table.insert(FINDFOOD_CANT_TAGS, "flying")
	end
	UpvalueHacker.SetUpvalue(self.OnStart, FINDFOOD_CANT_TAGS, "FindFoodAction", "FINDFOOD_CANT_TAGS")
end)