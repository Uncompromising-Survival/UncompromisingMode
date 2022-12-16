--[[
Code courtesy of penguin0616. Most (Almost all, actually) belongs to Insight.
Adapted for uncompromising mode. 
]]
local UpvalueHacker = require("tools/upvaluehacker")
local MOCKDRAGONFLY_TIMERNAME = "mockfly_timetoattack"
local function GetMockdragonflyData(self)
	if MOCKDRAGONFLY_TIMERNAME == false then
		return {}
	end

	if not self.inst.updatecomponents[self] then
		return {}
	end

	local time_to_attack
	if CurrentRelease.GreaterOrEqualTo("R15_QOL_WORLDSETTINGS") then
		time_to_attack = TheWorld.components.worldsettingstimer:GetTimeLeft("mockfly_timetoattack")
	else
		time_to_attack = self:OnSave().timetoattack
	end

	local target = UpvalueHacker.GetUpvalue(self.OnUpdate, "_targetplayer")

	if target then
		target = {
			name = target.name,
			userid = target.userid,
			prefab = target.prefab,
		}
	end

	return {
		time_to_attack = time_to_attack,
		target = target
	}
end

local function ProcessInformation(context, time_to_attack, target)
	local time_string = context.time:SimpleProcess(time_to_attack)
	local client_table = target and TheNet:GetClientTableForUser(target.userid)

	if not client_table then
		return time_string
	else
		local target_string = string.format("%s - %s", target.name, target.prefab)
		return string.format(
			"<color=%s>Target: %s</color> -> %s", 
			Color.ToHex(
				client_table.colour
			),
			target_string, 
			time_string
		)
	end
end

local function Describe(self, context)
	local description = nil
	local data = {}

	if self == nil and context.mockdragonfly_data then
		data = context.mockdragonfly_data
	elseif self and context.mockdragonfly_data == nil then
		data = GetMockdragonflyData(self)
	else
		error(string.format("mock_dragonflyspawner.Describe improperly called with self=%s & mockdragonfly_data=%s", tostring(self), tostring(context.mockdragonfly_data)))
	end

	if data.time_to_attack then
		description = ProcessInformation(context, data.time_to_attack, data.target)
	end

	return {
		priority = 10,
		description = description,
		icon = {
			atlas = "images/Dragonfly.xml",
			tex = "Dragonfly.tex",
		},
		worldly = true,
		time_to_attack = data.time_to_attack,
		target_userid = data.target and data.target.userid or nil
	}
end

local function StatusAnnoucementsDescribe(special_data, context)
	if not special_data.time_to_attack then
		return
	end

	local description = nil
	local target = special_data.target_userid and TheNet:GetClientTableForUser(special_data.target_userid)

	if target then
		-- Bearger is targetting someone
		description = Insight.env.ProcessRichTextPlainly(string.format(
			"<prefab=dragonfly> will spawn on %s (<prefab=%s>) in %s.",
			target.name,
			target.prefab,
			context.time:TryStatusAnnouncementsTime(special_data.time_to_attack)
		))
	else
		description = Insight.env.ProcessRichTextPlainly(string.format(
			"<prefab=dragonfly> will attack in %s.",
			context.time:TryStatusAnnouncementsTime(special_data.time_to_attack)
		))
	end

	return {
		description = description,
		append = true
	}
end

return {
	Describe = Describe,
	GetMockdragonflyData = GetMockdragonflyData,
	StatusAnnoucementsDescribe = StatusAnnoucementsDescribe
}
