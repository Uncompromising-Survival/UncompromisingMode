local UMUpvalueHacker = GLOBAL.require("tools/um_upvaluehacker")
--PIGS SHOULDNT BE EATING BUGS OUT OF THE SKY--

AddClassPostConstruct("brains/pigbrain", function(self)
    local FINDFOOD_CANT_TAGS = UMUpvalueHacker.GetUpvalue(self.OnStart, "FindFoodAction", "FINDFOOD_CANT_TAGS")
    if FINDFOOD_CANT_TAGS ~= nil then
		table.insert(FINDFOOD_CANT_TAGS, { "insect", "flying" })
	end
end)