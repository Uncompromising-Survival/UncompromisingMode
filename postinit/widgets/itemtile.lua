local env = env
GLOBAL.setfenv(1, GLOBAL)
local UIAnim = require "widgets/uianim"
-----------------------------------------------------------------
local Text = require "widgets/text"
require("constants")

local ItemTile = require('widgets/itemtile')
local _SetPercent = ItemTile.SetPercent

function ItemTile:SetPercent(percent, ...)
	_SetPercent(self, percent, ...)

	if percent ~= nil and self.percent ~= nil and self.inst:HasTag("overchargeable") then
		if percent > 1 then
			self.percent:SetColour({ 1, 1, 0, 1 })
		elseif percent > 0.99 and percent < 1 then --exactly at 1 just to reset it but not to break the coloured percent mod
			self.percent:SetColour({ 1, 1, 1, 1 })
		end
	end
end
